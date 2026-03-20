import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

import 'local/app_database.dart';
import 'models/app_models.dart';
import 'remote/auth_api_client.dart';
import 'remote/sync_api_client.dart';

class AppRepository {
  AppRepository({AppDatabase? database, SyncApiClient? syncApiClient, AuthApiClient? authApiClient})
      : _database = database ?? AppDatabase.instance,
        _syncApiClient = syncApiClient ?? SyncApiClient(),
        _authApiClient = authApiClient ?? AuthApiClient();

  final AppDatabase _database;
  final SyncApiClient _syncApiClient;
  final AuthApiClient _authApiClient;

  static const String _locationPermissionRequestedKey = 'location_permission_requested';
  static const String _locationPermissionStatusKey = 'location_permission_status';
  static const String _locationPermissionRequestedAtKey = 'location_permission_requested_at';
  static const String _deviceLinkedKey = 'device_linked';
  static const String _deviceBindingIdKey = 'device_binding_id';
  static const String _deviceBindingLabelKey = 'device_binding_label';
  static const String _deviceBindingLinkedAtKey = 'device_binding_linked_at';

  Future<AppBootstrapData> bootstrap() async {
    final db = await _database.database;
    await _refreshDerivedState(db);

    final session = await _loadSession(db);
    final preferences = await _loadPreferences(db);
    final user = session == null ? null : await _loadUser(db, session.userId);
    final projects = await _loadProjects(db);
    final currentProjectId = preferences.currentProjectId ?? (projects.isEmpty ? null : projects.first.id);
    final currentProject = projects.where((project) => project.id == currentProjectId).firstOrNull;
    final snapshot = currentProject == null ? null : await _loadProjectSnapshot(db, currentProject.id);
    final syncQueue = await _loadSyncQueue(db);
    final syncOverview = SyncOverview(
      pendingCount: syncQueue.where((item) => item.status == 'pending').length,
      failedCount: syncQueue.where((item) => item.status == 'failed').length,
      lastSyncAt: preferences.lastSyncAt,
      lastDailyFullSyncBusinessDate: preferences.lastDailyFullSyncBusinessDate,
      isOfflineMode: preferences.isOfflineMode,
      isOfflineForced: preferences.isOfflineForced,
      hasNetwork: preferences.hasNetwork,
      apiConfigured: preferences.apiConfigured,
      remoteSyncEnabled: preferences.remoteSyncEnabled,
      lastError: syncQueue.where((item) => item.errorMessage != null && item.errorMessage!.isNotEmpty).map((item) => item.errorMessage!).lastOrNull,
    );

    debugPrint(
      '[AppRepository] bootstrap session=${session?.userId} currentProject=$currentProjectId '
      'projects=${projects.length} restrictions=${snapshot?.restrictions.length ?? 0} '
      'completed=${snapshot?.completedRestrictions.length ?? 0} meetings=${snapshot?.meetings.length ?? 0} '
      'agreements=${snapshot?.agreements.length ?? 0} milestones=${snapshot?.milestones.length ?? 0}',
    );

    return AppBootstrapData(
      session: session,
      user: user,
      projects: projects,
      currentProject: currentProject,
      snapshot: snapshot,
      preferences: preferences,
      syncQueue: syncQueue,
      syncOverview: syncOverview,
    );
  }

  Future<AppBootstrapData> login({
    required String userOrEmail,
    required String password,
    required bool keepSignedIn,
  }) async {
    var db = await _database.database;
    final preferences = await _loadPreferences(db);
    final canTryRemoteLogin = _authApiClient.isConfigured && !preferences.isOfflineMode;
    if (canTryRemoteLogin) {
      try {
        debugPrint('[AppRepository] trying remote login for $userOrEmail');
        final remote = await _authApiClient.login(
          userOrEmail: userOrEmail,
          password: password,
          keepSignedIn: keepSignedIn,
        );
        final remoteUserId = _asInt(remote.user['id']);
        final shouldResetLocalData = await _shouldResetLocalDataForRemoteLogin(
          db,
          remoteUserId: remoteUserId,
        );
        if (shouldResetLocalData) {
          await _database.resetDatabase();
          db = await _database.database;
          await _clearLocalDataForFreshUser(db);
        }
        await _persistRemoteLogin(
          db,
          remote,
          password: password,
          keepSignedIn: keepSignedIn,
        );
        debugPrint('[AppRepository] remote login success userId=$remoteUserId');
        return bootstrap();
      } catch (error, stackTrace) {
        debugPrint('[AppRepository] remote login failed: $error');
        debugPrintStack(stackTrace: stackTrace, label: '[AppRepository] remote login stack');
        if (!preferences.isOfflineEffective) {
          rethrow;
        }
      }
    }

    if (!preferences.isOfflineEffective) {
      throw Exception('No hay backend de autenticacion disponible.');
    }

    // Fallback local solo para operacion offline.
    return _loginLocal(
      db,
      userOrEmail: userOrEmail,
      password: password,
      keepSignedIn: keepSignedIn,
    );
  }

  Future<AppBootstrapData> _loginLocal(
    Database db, {
    required String userOrEmail,
    required String password,
    required bool keepSignedIn,
  }) async {
    try {
      final credentials = await db.query(
        'auth_user',
        where: '(email = ? OR name = ?) AND password = ?',
        whereArgs: [userOrEmail, userOrEmail, password],
        limit: 1,
      );

      if (credentials.isEmpty) {
        throw Exception('Credenciales invalidas');
      }

      final userId = credentials.first['id'] as int;
      final now = DateTime.now().toIso8601String();
      await db.delete('auth_session');
      await db.insert('auth_session', {
        'user_id': userId,
        'token': 'local-token',
        'refresh_token': 'local-refresh',
        'is_active': 1,
        'last_login_at': now,
        'updated_at': now,
      });
      await _saveSetting(db, 'keep_signed_in', keepSignedIn ? '1' : '0');
      return bootstrap();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final db = await _database.database;
    await db.delete('auth_session');
    await _saveSetting(db, 'session_company_id', null);
  }

  Future<AppBootstrapData> changeProject(int projectId) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    await db.update('projects_project', {'is_last_selected': 0});
    await db.update(
      'projects_project',
      {'is_last_selected': 1, 'updated_at': now},
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );
    await _saveSetting(db, 'current_project_id', '$projectId');
    return bootstrap();
  }

  Future<AppBootstrapData> updateRestrictionStatus({required int restrictionId, required String statusCode}) async {
    final db = await _database.database;
    final statusRow = await db.query(
      'anares_status',
      where: 'codEstado = ?',
      whereArgs: [statusCode],
      limit: 1,
    );
    final restriction = await db.query(
      'anares_restriction',
      columns: ['codProyecto'],
      where: 'codAnaResActividad = ?',
      whereArgs: [restrictionId],
      limit: 1,
    );
    if (restriction.isEmpty || statusRow.isEmpty) return bootstrap();
    final projectId = restriction.first['codProyecto'] as int;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'anares_restriction',
      {
        'codEstadoActividad': statusCode,
        'desEstadoActividad': statusRow.first['desEstado'],
        'colorEstado': statusRow.first['iconColor'],
        'sync_status': 'pending',
        'dayFechaModificacion': now,
        'updated_at': now,
        ..._statusFlagsFromCatalogRow(statusRow.first),
      },
      where: 'codAnaResActividad = ?',
      whereArgs: [restrictionId],
    );
    await _enqueueSync(
      db,
      entityType: 'restriction',
      entityId: '$restrictionId',
      operationType: 'update',
      payload: await _buildRestrictionSyncPayload(db, restrictionId),
    );
    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> saveRestriction(RestrictionDraft draft) async {
    final db = await _database.database;
    final currentProjectId = await _loadCurrentProjectId(db) ?? 101;
    final now = DateTime.now().toIso8601String();
    final codAnaRes = await _requireRestrictionScope(db, currentProjectId);
    final catalogs = await _loadCatalogs(db, currentProjectId);
    final front = catalogs.fronts.firstWhere((item) => item.id == draft.frontId);
    final phase = catalogs.phases.firstWhere((item) => item.id == draft.phaseId && item.parentId == draft.frontId);
    final type = catalogs.types.firstWhere((item) => item.id == draft.typeId);
    final responsible = catalogs.responsibles.firstWhere((item) => item.id == draft.responsibleId);
    final status = catalogs.statuses.firstWhere((item) => item.id == draft.statusCode);
    final statusRow = await db.query(
      'anares_status',
      where: 'codEstado = ?',
      whereArgs: [draft.statusCode],
      limit: 1,
    );
    final flags = statusRow.isNotEmpty
        ? _statusFlagsFromCatalogRow(statusRow.first)
        : _statusFlagsFromStatusCode(draft.statusCode, statusLabel: status.label);
    final areaSelection = catalogs.areas.firstWhere((item) => item.id == draft.areaCode);
    final resolvedArea = await _resolveRestrictionAreaSelection(
      db,
      selectedArea: areaSelection,
      projectId: currentProjectId,
      nowIso: now,
    );

    if (draft.id == null) {
      final nextId = await _nextRestrictionId(db);
      await db.insert('anares_restriction', {
        'codAnaResActividad': nextId,
        'codProyecto': currentProjectId,
        'codAnaRes': codAnaRes,
        'codAnaResFrente': int.tryParse(draft.frontId),
        'codAnaResFase': int.tryParse(draft.phaseId),
        'desFrente': front.label,
        'desFase': phase.label,
        'desActividad': draft.activity,
        'desRestriccion': draft.description,
        'codTipoRestriccion': int.tryParse(draft.typeId),
        'desTipoRestriccion': type.label,
        'dayFechaRequerida': _formatDate(draft.requiredDate),
        'idUsuarioResponsable': int.tryParse(draft.responsibleId),
        'desResponsable': responsible.label,
        'codEstadoActividad': draft.statusCode,
        'desEstadoActividad': status.label,
        'colorEstado': status.colorHex,
        'codAnaresArea': resolvedArea.codAnaresArea.toString(),
        'codUsuarioSolicitante': '7',
        'desSolicitante': 'Diego Warthon',
        'priority_order': _priorityOrder(draft.statusCode),
        'sync_status': 'pending',
        'dayFechaCreacion': now,
        'dayFechaModificacion': now,
        'updated_at': now,
        ...flags,
      });
      await _enqueueSync(
        db,
        entityType: 'restriction',
        entityId: '$nextId',
        operationType: 'create',
        payload: await _buildRestrictionSyncPayload(db, nextId),
      );
    } else {
      await db.update(
        'anares_restriction',
        {
          'codAnaRes': codAnaRes,
          'codAnaResFrente': int.tryParse(draft.frontId),
          'codAnaResFase': int.tryParse(draft.phaseId),
          'desFrente': front.label,
          'desFase': phase.label,
          'desActividad': draft.activity,
          'desRestriccion': draft.description,
          'codTipoRestriccion': int.tryParse(draft.typeId),
          'desTipoRestriccion': type.label,
          'dayFechaRequerida': _formatDate(draft.requiredDate),
          'idUsuarioResponsable': int.tryParse(draft.responsibleId),
          'desResponsable': responsible.label,
          'codEstadoActividad': draft.statusCode,
          'desEstadoActividad': status.label,
          'colorEstado': status.colorHex,
          'codAnaresArea': resolvedArea.codAnaresArea.toString(),
          'priority_order': _priorityOrder(draft.statusCode),
          'sync_status': 'pending',
          'dayFechaModificacion': now,
          'updated_at': now,
          ...flags,
        },
        where: 'codAnaResActividad = ?',
        whereArgs: [draft.id],
      );
      await _enqueueSync(
        db,
        entityType: 'restriction',
        entityId: '${draft.id}',
        operationType: 'update',
        payload: await _buildRestrictionSyncPayload(db, draft.id!),
      );
    }

    await _refreshDerivedState(db, projectId: currentProjectId);
    return bootstrap();
  }

  Future<String> createRestrictionFront({
    required int projectId,
    required String name,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    final codAnaRes = await _requireRestrictionScope(db, projectId);
    final nextId = await _nextRestrictionFrontId(db);
    final normalizedName = name.trim();

    await db.insert('anares_front', {
      'codAnaResFrente': nextId,
      'codProyecto': projectId,
      'codAnaRes': codAnaRes,
      'desAnaResFrente': normalizedName,
      'updated_at': now,
    });

    await _enqueueSync(
      db,
      entityType: 'analysis_front',
      entityId: '$nextId',
      operationType: 'create',
      payload: await _buildRestrictionFrontSyncPayload(db, nextId),
    );

    return '$nextId';
  }

  Future<String> createRestrictionPhase({
    required int projectId,
    required String frontId,
    required String name,
  }) async {
    final db = await _database.database;
    final frontRows = await db.query(
      'anares_front',
      where: 'codAnaResFrente = ? AND codProyecto = ?',
      whereArgs: [int.parse(frontId), projectId],
      limit: 1,
    );
    if (frontRows.isEmpty) {
      throw Exception('No se encontro el frente seleccionado para crear la fase.');
    }

    final now = DateTime.now().toIso8601String();
    final nextId = await _nextRestrictionPhaseId(db);
    final normalizedName = name.trim();
    final frontRow = frontRows.first;

    await db.insert('anares_phase', {
      'codAnaResFase': nextId,
      'codAnaResFrente': int.parse(frontId),
      'codProyecto': projectId,
      'codAnaRes': _asInt(frontRow['codAnaRes']),
      'desAnaResFase': normalizedName,
      'bgColor': '#0A66B7',
      'updated_at': now,
    });

    await _enqueueSync(
      db,
      entityType: 'analysis_phase',
      entityId: '$nextId',
      operationType: 'create',
      payload: await _buildRestrictionPhaseSyncPayload(db, nextId),
    );

    return '$nextId';
  }

  Future<AppBootstrapData> deleteRestriction(int restrictionId) async {
    final db = await _database.database;
    final rows = await db.query(
      'anares_restriction',
      columns: ['codProyecto'],
      where: 'codAnaResActividad = ?',
      whereArgs: [restrictionId],
      limit: 1,
    );
    if (rows.isEmpty) return bootstrap();

    final projectId = rows.first['codProyecto'] as int;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'anares_restriction',
      {
        'codEstadoActividad': '99',
        'desEstadoActividad': 'Eliminado',
        'colorEstado': '#98A3B3',
        'is_completed': 0,
        'is_overdue': 0,
        'is_due_today': 0,
        'is_pending': 0,
        'is_in_progress': 0,
        'priority_order': 99,
        'sync_status': 'pending',
        'dayFechaModificacion': now,
        'updated_at': now,
      },
      where: 'codAnaResActividad = ?',
      whereArgs: [restrictionId],
    );

    final payload = await _buildRestrictionSyncPayload(db, restrictionId);
    payload['deleted'] = true;

    await _enqueueSync(
      db,
      entityType: 'restriction',
      entityId: '$restrictionId',
      operationType: 'delete',
      payload: payload,
    );
    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> updateAgreementStatus({required int agreementId, required String statusCode}) async {
    final db = await _database.database;
    final agreementRows = await db.query(
      'meetings_agreement',
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (agreementRows.isEmpty) return bootstrap();

    final row = agreementRows.first;
    final projectId = row['codProyecto'] as int;
    final dueDate = _parseDate(row['dayFechaAcuerdo'] as String?);
    final now = DateTime.now().toIso8601String();
    final isCompleted = statusCode == 'completed';
    final isPending = statusCode == 'pending';
    final isOverdue = !isCompleted && dueDate != null && _isPastDate(dueDate);
    final statusLabel = _agreementStatusLabel(statusCode, isOverdue: isOverdue);
    final groupLabel = isCompleted ? 'Completado' : (isOverdue ? 'Vencido' : 'Pendiente');
    final color = isCompleted ? '#1B8E5A' : (isOverdue ? '#D64545' : '#F0A11E');

    await db.update(
      'meetings_agreement',
      {
        'codEstado': statusCode,
        'desEstado': statusLabel,
        'desGrupoAcuerdo': groupLabel,
        'desColorGrupoAcuerdo': color,
        'is_overdue': isOverdue ? 1 : 0,
        'is_pending': isPending ? 1 : 0,
        'is_completed': isCompleted ? 1 : 0,
        'updated_at': now,
      },
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
    );
    await _enqueueSync(
      db,
      entityType: 'agreement',
      entityId: '$agreementId',
      operationType: 'update',
      payload: {'codActReuAcuerdos': agreementId, 'codEstado': statusCode},
    );
    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> saveMilestone(MilestoneDraft draft) async {
    final db = await _database.database;
    final currentProjectId = await _loadCurrentProjectId(db) ?? 101;
    final now = DateTime.now().toIso8601String();
    final scope = await _ensureMilestoneScope(db, currentProjectId, now);

    if (draft.id == null) {
      final nextId = await _nextMilestoneId(db);
      final currentCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM conhit_detallehitos WHERE codProyecto = ?', [currentProjectId]),
          ) ??
          0;
      await db.insert('conhit_detallehitos', {
        'codConHitDetalleHitos': nextId,
        'codConHit': scope.controlId,
        'codProyecto': currentProjectId,
        'codConHitGeneral': scope.generalId,
        'NumOrden': currentCount + 1,
        'desDescripcion': draft.description,
        'codTipoHito': int.tryParse(draft.typeCode),
        'codTipoClasificacion': int.tryParse(draft.classificationCode),
        'numplazo': draft.targetDate.difference(draft.contractualDate).inDays,
        'porPenalidad': draft.isPenalizable ? draft.penaltyPercent : 0.0,
        'dayFechaContractual': _formatDate(draft.contractualDate),
        'dayFechaMeta': _formatDate(draft.targetDate),
        'numCantAmpContractual': 0,
        'numCantAmpMeta': 0,
        'dayFechaReal': draft.actualDate == null ? null : _formatDate(draft.actualDate!),
        'desLinkDocuCierre': null,
        'codEstadoContractual': 1,
        'codEstadoInternos': 1,
        'mntPealidad': 0.0,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'mobile',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'mobile',
        'dayFechaContractualAmp': null,
        'dayFechaMetaAmp': null,
        'sync_status': 'pending',
        'updated_at': now,
      });
      await _recalculateMilestoneDerivedFields(db, nextId);
      await _enqueueSync(
        db,
        entityType: 'milestone',
        entityId: '$nextId',
        operationType: 'create',
        payload: await _buildMilestoneSyncPayload(db, nextId),
      );
    } else {
      await db.update(
        'conhit_detallehitos',
        {
          'desDescripcion': draft.description,
          'codTipoHito': int.tryParse(draft.typeCode),
          'codTipoClasificacion': int.tryParse(draft.classificationCode),
          'numplazo': draft.targetDate.difference(draft.contractualDate).inDays,
          'porPenalidad': draft.isPenalizable ? draft.penaltyPercent : 0.0,
          'dayFechaContractual': _formatDate(draft.contractualDate),
          'dayFechaMeta': _formatDate(draft.targetDate),
          'dayFechaReal': draft.actualDate == null ? null : _formatDate(draft.actualDate!),
          'dayFechaModificacion': now,
          'desUsuarioModificacion': 'mobile',
          'sync_status': 'pending',
          'updated_at': now,
        },
        where: 'codConHitDetalleHitos = ?',
        whereArgs: [draft.id],
      );
      await _recalculateMilestoneDerivedFields(db, draft.id!);
      await _enqueueSync(
        db,
        entityType: 'milestone',
        entityId: '${draft.id}',
        operationType: 'update',
        payload: await _buildMilestoneSyncPayload(db, draft.id!),
      );
    }

    return bootstrap();
  }

  Future<AppBootstrapData> saveMilestoneGeneral(MilestoneGeneralDraft draft) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    final scope = await _ensureMilestoneScope(db, draft.projectId, now);
    final generalId = draft.generalId == 0 ? scope.generalId : draft.generalId;
    final controlId = draft.controlId == 0 ? scope.controlId : draft.controlId;
    final startDate = draft.startDate == null ? null : _formatDate(draft.startDate!);

    await db.update(
      'conhit_general',
      {
        'codConHit': controlId,
        'codProyecto': draft.projectId,
        'numDiasPlazoTotal': draft.totalDays,
        'numDias': draft.totalDays,
        'mntTotal': draft.totalAmount,
        'dayFechaInicioContractual': startDate,
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'mobile',
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: 'codConHitGeneral = ?',
      whereArgs: [generalId],
    );

    await _enqueueSync(
      db,
      entityType: 'milestone_general',
      entityId: '$generalId',
      operationType: 'update',
      payload: {
        'codConHitGeneral': generalId,
        'codConHit': controlId,
        'codProyecto': draft.projectId,
        'numDiasPlazoTotal': draft.totalDays,
        'numDias': draft.totalDays,
        'mntTotal': draft.totalAmount,
        'dayFechaInicioContractual': startDate,
      },
    );

    await _refreshDerivedState(db, projectId: draft.projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> saveMilestoneExtension(MilestoneExtensionDraft draft) async {
    final db = await _database.database;
    final milestoneRows = await db.query(
      'conhit_detallehitos',
      columns: [
        'codProyecto',
        'dayFechaMeta',
        'dayFechaMetaAmp',
        'dayFechaContractual',
        'dayFechaContractualAmp',
        'numCantAmpContractual',
        'numCantAmpMeta',
      ],
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [draft.milestoneId],
      limit: 1,
    );
    if (milestoneRows.isEmpty) return bootstrap();

    final row = milestoneRows.first;
    final projectId = row['codProyecto'] as int;
    final now = DateTime.now().toIso8601String();
    final nextId = await _nextMilestoneExtensionId(db);
    final previousTargetDate =
        _parseDate(row['dayFechaMetaAmp'] as String?) ??
        _parseDate(row['dayFechaMeta'] as String?) ??
        DateTime.now();
    await db.insert('conthit_detallehitosamp', {
      'codConHitDetalleHitosAmp': nextId,
      'codConHitDetalleHitos': draft.milestoneId,
      'desMotivo': draft.justification,
      'dayFechaMeta': draft.newTargetDate == null ? null : _formatDate(draft.newTargetDate!),
      'dayFechaContractual': draft.newContractualDate == null ? null : _formatDate(draft.newContractualDate!),
      'desLinklDocuAmp': draft.supportDocument,
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'mobile',
      'dayFechaModificacion': now,
      'desUsuarioModificacion': 'mobile',
      'desTipoFecha': draft.dateType,
      'sync_status': 'pending',
      'updated_at': now,
    });

    int? createdDocumentId;
    if (draft.supportDocument.trim().isNotEmpty) {
      createdDocumentId = await _nextMilestoneDocumentId(db);
      final normalizedPath = draft.supportDocument.trim();
      final normalizedName = _extractFileName(normalizedPath, fallback: 'Documento $createdDocumentId');
      await db.insert('conhit_archivosfechareal', {
        'codConhitArchivosFechaReal': createdDocumentId,
        'codConHitDetalleHitos': draft.milestoneId,
        'desNombreArchivo': normalizedName,
        'desRutaArchivo': normalizedPath,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'mobile',
        'dayFechaModificacion': now,
        'desUsuarioModifcacion': 'mobile',
        'sync_status': 'pending',
        'updated_at': now,
      });
    }

    await db.update(
      'conhit_detallehitos',
      {
        'dayFechaContractualAmp': draft.newContractualDate == null ? null : _formatDate(draft.newContractualDate!),
        'dayFechaMetaAmp': draft.newTargetDate == null ? null : _formatDate(draft.newTargetDate!),
        'numCantAmpContractual': (row['numCantAmpContractual'] as int? ?? 0) + (draft.newContractualDate == null ? 0 : 1),
        'numCantAmpMeta': (row['numCantAmpMeta'] as int? ?? 0) + (draft.newTargetDate == null ? 0 : 1),
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'mobile',
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [draft.milestoneId],
    );
    await _recalculateMilestoneDerivedFields(db, draft.milestoneId);

    await _enqueueSync(
      db,
      entityType: 'milestone_extension',
      entityId: '$nextId',
      operationType: 'create',
      payload: await _buildMilestoneExtensionSyncPayload(db, nextId, previousTargetDate: previousTargetDate),
    );
    if (createdDocumentId != null) {
      await _enqueueSync(
        db,
        entityType: 'milestone_document',
        entityId: '$createdDocumentId',
        operationType: 'create',
        payload: await _buildMilestoneDocumentSyncPayload(db, createdDocumentId),
      );
    }
    await _enqueueSync(
      db,
      entityType: 'milestone',
      entityId: '${draft.milestoneId}',
      operationType: 'update',
      payload: await _buildMilestoneSyncPayload(db, draft.milestoneId),
    );

    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> saveMilestoneDocument(MilestoneDocumentDraft draft) async {
    final db = await _database.database;
    final milestoneRows = await db.query(
      'conhit_detallehitos',
      columns: ['codProyecto'],
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [draft.milestoneId],
      limit: 1,
    );
    if (milestoneRows.isEmpty) return bootstrap();

    final projectId = milestoneRows.first['codProyecto'] as int;
    final now = DateTime.now().toIso8601String();
    final documentId = await _nextMilestoneDocumentId(db);
    final normalizedName = draft.name.trim().isEmpty ? 'Documento $documentId' : draft.name.trim();
    final normalizedPath = draft.path.trim().isEmpty ? 'local://documentos/$documentId' : draft.path.trim();

    await db.insert('conhit_archivosfechareal', {
      'codConhitArchivosFechaReal': documentId,
      'codConHitDetalleHitos': draft.milestoneId,
      'desNombreArchivo': normalizedName,
      'desRutaArchivo': normalizedPath,
      'dayFechaCreacion': now,
      'desUsuarioCreacion': 'mobile',
      'dayFechaModificacion': now,
      'desUsuarioModifcacion': 'mobile',
      'sync_status': 'pending',
      'updated_at': now,
    });

    await _enqueueSync(
      db,
      entityType: 'milestone_document',
      entityId: '$documentId',
      operationType: 'create',
      payload: await _buildMilestoneDocumentSyncPayload(db, documentId),
    );

    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> deleteMilestoneDocument(int documentId) async {
    final db = await _database.database;
    final rows = await db.query(
      'conhit_archivosfechareal',
      where: 'codConhitArchivosFechaReal = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    if (rows.isEmpty) return bootstrap();

    final payload = Map<String, Object?>.from(rows.first)..remove('sync_status');
    final milestoneId = _asInt(rows.first['codConHitDetalleHitos']);
    final milestoneRows = milestoneId == null
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_detallehitos',
            columns: ['codProyecto'],
            where: 'codConHitDetalleHitos = ?',
            whereArgs: [milestoneId],
            limit: 1,
          );

    await db.delete(
      'conhit_archivosfechareal',
      where: 'codConhitArchivosFechaReal = ?',
      whereArgs: [documentId],
    );

    await _enqueueSync(
      db,
      entityType: 'milestone_document',
      entityId: '$documentId',
      operationType: 'delete',
      payload: payload,
    );

    final projectId = milestoneRows.isEmpty ? null : milestoneRows.first['codProyecto'] as int;
    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> deleteMilestone(int milestoneId) async {
    final db = await _database.database;
    final rows = await db.query(
      'conhit_detallehitos',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
      limit: 1,
    );
    if (rows.isEmpty) return bootstrap();

    final payload = Map<String, Object?>.from(rows.first)
      ..remove('sync_status')
      ..['deleted'] = true;
    final projectId = _asInt(rows.first['codProyecto']);

    await db.delete(
      'conhit_detallehitos',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );

    await _enqueueSync(
      db,
      entityType: 'milestone',
      entityId: '$milestoneId',
      operationType: 'delete',
      payload: payload,
    );

    await _refreshDerivedState(db, projectId: projectId);
    return bootstrap();
  }

  Future<AppBootstrapData> setOfflineMode(bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, 'offline_mode', enabled ? '1' : '0');
    return bootstrap();
  }

  Future<AppBootstrapData> setRemoteSyncEnabled(bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, 'remote_sync_enabled', enabled ? '1' : '0');
    return bootstrap();
  }

  Future<AppBootstrapData> setDarkMode(bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, 'dark_mode', enabled ? '1' : '0');
    return bootstrap();
  }

  Future<AppBootstrapData> syncPendingChanges() async {
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    await _ensureRemoteSyncAllowed(preferences);

    final queue = await db.query('sync_queue', where: "status IN ('pending', 'failed')", orderBy: 'created_at ASC, id ASC');
    if (queue.isEmpty) {
      return bootstrap();
    }

    final session = await _loadSession(db);
    if (session == null || !session.isActive) {
      return bootstrap();
    }

    final user = await _loadUser(db, session.userId);
    await _pushQueue(
      db,
      queue: queue,
      userId: session.userId,
      authToken: session.token,
      companyId: await _resolvePushCompanyId(db, fallback: user?.company),
    );

    return bootstrap();
  }

  Future<AppBootstrapData> syncOperationalData() async {
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    await _ensureRemoteSyncAllowed(preferences);
    final session = await _loadSession(db);
    if (session == null || !session.isActive) {
      throw Exception('No hay una sesion activa para sincronizacion operativa.');
    }

    final userId = session.userId;
    final user = await _loadUser(db, userId);

      await _pullRemoteData(
        db,
        userId: userId,
        scope: 'operational',
        businessDate: _currentBusinessDateKey(),
        since: preferences.lastSyncAt?.toIso8601String(),
        authToken: session.token,
        companyId: await _resolvePullCompanyId(db, fallback: user?.company),
      );

    return bootstrap();
  }

  Future<AppBootstrapData> syncFullData({bool markDailyFullSync = false}) async {
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    final queue = await db.query('sync_queue', where: "status IN ('pending', 'failed')", orderBy: 'created_at ASC, id ASC');
    final session = await _loadSession(db);
    if (session == null || !session.isActive) {
      throw Exception('No hay una sesion activa para sincronizacion total.');
    }

    final userId = session.userId;
    final user = await _loadUser(db, userId);
    await _ensureRemoteSyncAllowed(preferences);

    if (queue.isNotEmpty) {
      await _pushQueue(
        db,
        queue: queue,
        userId: userId,
        authToken: session.token,
        companyId: await _resolvePushCompanyId(db, fallback: user?.company),
      );
    }

    await _pullRemoteData(
      db,
      userId: userId,
      scope: 'full',
      businessDate: _currentBusinessDateKey(),
      since: null,
      authToken: session.token,
      companyId: await _resolvePullCompanyId(db, fallback: user?.company),
      markDailyFullSync: markDailyFullSync,
    );

    return bootstrap();
  }

  Future<UserSession?> _loadSession(Database db) async {
    final rows = await db.query('auth_session', where: 'is_active = 1', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    final keepSetting = await _loadSetting(db, 'keep_signed_in');
    final row = rows.first;
    return UserSession(
      userId: row['user_id'] as int,
      token: (row['token'] as String?) ?? '',
      keepSignedIn: keepSetting != '0',
      isActive: (row['is_active'] as int? ?? 0) == 1,
    );
  }

  Future<UserProfile?> _loadUser(Database db, int userId) async {
    final rows = await db.query('auth_user', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserProfile(
      id: row['id'] as int,
      name: (row['name'] as String?) ?? '',
      lastName: (row['lastname'] as String?) ?? '',
      email: (row['email'] as String?) ?? '',
      role: 'Supervisor de obra',
      password: row['password'] as String?,
      phone: row['celular'] as String?,
      company: row['nombreempresa'] as String?,
    );
  }

  Future<List<ProjectRecord>> _loadProjects(Database db) async {
    final rows = await db.query('projects_project', orderBy: 'is_last_selected DESC, codProyecto ASC');
    return rows
        .map(
          (row) => ProjectRecord(
            id: row['codProyecto'] as int,
            name: (row['desNombreProyecto'] as String?) ?? '',
            company: (row['desEmpresa'] as String?) ?? (row['des_Empresa'] as String?) ?? '',
            address: (row['desDireccion'] as String?) ?? '',
            roleLabel: 'Supervisor de obra',
            isLastSelected: (row['is_last_selected'] as int? ?? 0) == 1,
          ),
        )
        .toList();
  }

  Future<AppPreferences> _loadPreferences(Database db) async {
    final keepSignedIn = await _loadSetting(db, 'keep_signed_in');
    final darkMode = await _loadSetting(db, 'dark_mode');
    final offlineMode = await _loadSetting(db, 'offline_mode');
    final remoteSyncEnabled = await _loadSetting(db, 'remote_sync_enabled');
    final currentProjectId = await _loadCurrentProjectId(db);
    final lastSyncAt = _parseDateTime(await _loadSetting(db, 'last_sync_at'));
    final hasNetwork = await _syncApiClient.hasInternet();
    return AppPreferences(
      keepSignedIn: keepSignedIn != '0',
      isDarkMode: darkMode == '1',
      isOfflineMode: offlineMode == '1',
      isOfflineForced: !hasNetwork,
      hasNetwork: hasNetwork,
      apiConfigured: _syncApiClient.isConfigured,
      remoteSyncEnabled: remoteSyncEnabled != '0',
      isDeviceLinked: (await _loadSetting(db, _deviceLinkedKey)) == '1',
      linkedDeviceId: await _loadSetting(db, _deviceBindingIdKey),
      linkedDeviceLabel: await _loadSetting(db, _deviceBindingLabelKey),
      deviceLinkedAt: _parseDateTime(await _loadSetting(db, _deviceBindingLinkedAtKey)),
      currentProjectId: currentProjectId,
      lastSyncAt: lastSyncAt,
      lastDailyFullSyncBusinessDate: await _loadSetting(db, 'last_daily_full_sync_business_date'),
    );
  }

  Future<DeviceBindingState> getDeviceBindingState() async {
    final db = await _database.database;
    final linked = await _loadSetting(db, _deviceLinkedKey);
    final id = await _loadSetting(db, _deviceBindingIdKey);
    final label = await _loadSetting(db, _deviceBindingLabelKey);
    final linkedAt = _parseDateTime(await _loadSetting(db, _deviceBindingLinkedAtKey));
    return DeviceBindingState(
      isLinked: linked == '1' && (id?.isNotEmpty ?? false),
      deviceId: id,
      deviceLabel: label,
      linkedAt: linkedAt,
    );
  }

  Future<AppBootstrapData> linkCurrentDevice({required int? userId}) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    final existingId = await _loadSetting(db, _deviceBindingIdKey);
    final existingLabel = await _loadSetting(db, _deviceBindingLabelKey);
    final deviceId = (existingId != null && existingId.isNotEmpty) ? existingId : _generateDeviceBindingId(userId: userId);
    final deviceLabel = (existingLabel != null && existingLabel.isNotEmpty)
        ? existingLabel
        : _buildDeviceBindingLabel(userId: userId, deviceId: deviceId);

    await _saveSetting(db, _deviceLinkedKey, '1');
    await _saveSetting(db, _deviceBindingIdKey, deviceId);
    await _saveSetting(db, _deviceBindingLabelKey, deviceLabel);
    await _saveSetting(db, _deviceBindingLinkedAtKey, now);
    await _enqueueSync(
      db,
      entityType: 'device_binding',
      entityId: deviceId,
      operationType: 'create',
      payload: {
        'userId': userId,
        'deviceId': deviceId,
        'deviceLabel': deviceLabel,
        'linkedAt': now,
        'isLinked': true,
      },
    );
    return bootstrap();
  }

  Future<AppBootstrapData> unlinkCurrentDevice() async {
    final db = await _database.database;
    final existingId = await _loadSetting(db, _deviceBindingIdKey);
    final existingLabel = await _loadSetting(db, _deviceBindingLabelKey);
    final linkedAt = await _loadSetting(db, _deviceBindingLinkedAtKey);
    final session = await _loadSession(db);
    await _saveSetting(db, _deviceLinkedKey, '0');
    await _saveSetting(db, _deviceBindingIdKey, null);
    await _saveSetting(db, _deviceBindingLabelKey, null);
    await _saveSetting(db, _deviceBindingLinkedAtKey, null);
    if (existingId != null && existingId.isNotEmpty) {
      await _enqueueSync(
        db,
        entityType: 'device_binding',
        entityId: existingId,
        operationType: 'delete',
        payload: {
          'userId': session?.userId,
          'deviceId': existingId,
          'deviceLabel': existingLabel,
          'linkedAt': linkedAt,
          'isLinked': false,
          'deleted': true,
        },
      );
    }
    return bootstrap();
  }

  Future<String?> buildAttendanceQrPayload({
    required int? userId,
    required String? userEmail,
  }) async {
    final state = await getDeviceBindingState();
    if (!state.isLinked || state.deviceId == null) {
      return null;
    }

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(seconds: 45));
    return jsonEncode({
      'type': 'attendance_identity',
      'userId': userId,
      'email': userEmail,
      'deviceId': state.deviceId,
      'deviceLabel': state.deviceLabel,
      'issuedAt': now.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'nonce': _buildQrNonce(userId: userId, deviceId: state.deviceId!, issuedAt: now),
    });
  }

  Future<List<SyncQueueRecord>> _loadSyncQueue(Database db) async {
    final rows = await db.query('sync_queue', orderBy: 'status ASC, created_at DESC');
    return rows
        .map(
          (row) => SyncQueueRecord(
            id: row['id'] as int,
            entityType: (row['entity_type'] as String?) ?? '',
            entityId: (row['entity_id'] as String?) ?? '',
            operationType: (row['operation_type'] as String?) ?? '',
            status: (row['status'] as String?) ?? 'pending',
            retryCount: (row['retry_count'] as int?) ?? 0,
            errorMessage: row['error_message'] as String?,
            createdAt: _parseDateTime(row['created_at'] as String?),
            updatedAt: _parseDateTime(row['updated_at'] as String?),
          ),
        )
        .toList();
  }

  Future<int?> _loadCurrentProjectId(Database db) async {
    final value = await _loadSetting(db, 'current_project_id');
    return int.tryParse(value ?? '');
  }

  Future<Object?> _resolvePushCompanyId(Database db, {String? fallback}) async {
    final currentProjectId = await _loadCurrentProjectId(db);
    if (currentProjectId != null) {
      final rows = await db.query(
        'projects_project',
        columns: ['codEmpresa'],
        where: 'codProyecto = ?',
        whereArgs: [currentProjectId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final companyId = _asInt(rows.first['codEmpresa']);
        if (companyId != null) {
          return companyId;
        }
      }
    }

    final fallbackInt = int.tryParse((fallback ?? '').trim());
    if (fallbackInt != null) {
      return fallbackInt;
    }

    return fallback;
  }

  Future<String?> _resolvePullCompanyId(Database db, {String? fallback}) async {
    final stored = (await _loadSetting(db, 'session_company_id'))?.trim();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    final normalizedFallback = fallback?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      return normalizedFallback;
    }

    return null;
  }

  Future<int> _nextSyncQueueId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM sync_queue WHERE id = ? LIMIT 1', [candidate]),
      );
      if (existing == null) {
        return candidate;
      }
      candidate++;
    }
  }

  Future<int> _nextRestrictionId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM anares_restriction WHERE codAnaResActividad = ? LIMIT 1', [candidate]),
      );
      if (existing == null) {
        return candidate;
      }
      candidate++;
    }
  }

  Future<int> _nextRestrictionFrontId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM anares_front WHERE codAnaResFrente = ? LIMIT 1', [candidate]),
      );
      if (existing == null) {
        return candidate;
      }
      candidate++;
    }
  }

  Future<int> _nextRestrictionPhaseId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM anares_phase WHERE codAnaResFase = ? LIMIT 1', [candidate]),
      );
      if (existing == null) {
        return candidate;
      }
      candidate++;
    }
  }

  Future<int> _nextMilestoneControlId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM conhit_controlhitos WHERE codConHit = ? LIMIT 1', [candidate]),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneGeneralId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM conhit_general WHERE codConHitGeneral = ? LIMIT 1', [candidate]),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM conhit_detallehitos WHERE codConHitDetalleHitos = ? LIMIT 1', [candidate]),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneExtensionId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM conthit_detallehitosamp WHERE codConHitDetalleHitosAmp = ? LIMIT 1', [candidate]),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneDocumentId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM conhit_archivosfechareal WHERE codConhitArchivosFechaReal = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  String _extractFileName(String value, {required String fallback}) {
    final normalized = value.trim();
    if (normalized.isEmpty) return fallback;
    final segments = normalized.split(RegExp(r'[\\/]'));
    final last = segments.isEmpty ? normalized : segments.last.trim();
    return last.isEmpty ? fallback : last;
  }

  Future<void> _normalizePendingSyncQueueIds(Database db) async {
    final rows = await db.query(
      'sync_queue',
      columns: ['id'],
      where: "status IN ('pending', 'failed') AND id < 1000000000000",
      orderBy: 'id ASC',
    );
    for (final row in rows) {
      final currentId = _asInt(row['id']);
      if (currentId == null) continue;
      final newId = await _nextSyncQueueId(db);
      await db.update(
        'sync_queue',
        {'id': newId},
        where: 'id = ?',
        whereArgs: [currentId],
      );
    }
  }

  Future<String?> _loadSetting(Database db, String key) async {
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<bool> _shouldResetLocalDataForRemoteLogin(
    Database db, {
    required int? remoteUserId,
  }) async {
    if (remoteUserId == null) {
      return true;
    }

    final session = await _loadSession(db);
    if (session == null) {
      return true;
    }

    return session.userId != remoteUserId;
  }

  Future<void> _saveSetting(Database db, String key, String? value) async {
    await db.insert(
      'app_settings',
      {'key': key, 'value': value, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> ensureLocationConsentRequested() async {
    final db = await _database.database;
    final alreadyRequested = await _loadSetting(db, _locationPermissionRequestedKey);
    if (alreadyRequested == '1') {
      return;
    }

    final requestedAt = DateTime.now().toIso8601String();
    await _saveSetting(db, _locationPermissionRequestedKey, '1');
    await _saveSetting(db, _locationPermissionRequestedAtKey, requestedAt);

    final permission = await Geolocator.requestPermission();
    await _saveSetting(db, _locationPermissionStatusKey, permission.name);
  }

  Future<LocationAccessState> getLocationAccessState() async {
    final db = await _database.database;
    final requested = await _loadSetting(db, _locationPermissionRequestedKey);
    final permission = await Geolocator.checkPermission();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    await _saveSetting(db, _locationPermissionStatusKey, permission.name);
    return LocationAccessState(
      permissionStatus: permission.name,
      serviceEnabled: serviceEnabled,
      hasRequestedConsent: requested == '1',
    );
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openLocationAppSettings() {
    return Geolocator.openAppSettings();
  }

  String _generateDeviceBindingId({required int? userId}) {
    final random = Random.secure();
    final suffix = List.generate(6, (_) => random.nextInt(16).toRadixString(16)).join().toUpperCase();
    final userPart = userId?.toString() ?? 'anon';
    return 'DIR-$userPart-${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  String _buildDeviceBindingLabel({
    required int? userId,
    required String deviceId,
  }) {
    final shortId = deviceId.length <= 8 ? deviceId : deviceId.substring(deviceId.length - 8);
    return 'Dispositivo ${userId ?? '-'} · $shortId';
  }

  String _buildQrNonce({
    required int? userId,
    required String deviceId,
    required DateTime issuedAt,
  }) {
    final random = Random.secure();
    final salt = List.generate(4, (_) => random.nextInt(16).toRadixString(16)).join().toUpperCase();
    return '${userId ?? '0'}-${issuedAt.millisecondsSinceEpoch}-${deviceId.hashCode.abs()}-$salt';
  }

  Future<_MilestoneScope> _ensureMilestoneScope(Database db, int projectId, String nowIso) async {
    final controlRows = await db.query(
      'conhit_controlhitos',
      columns: ['codConHit'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codConHit DESC',
      limit: 1,
    );
    if (controlRows.isNotEmpty) {
      final controlId = controlRows.first['codConHit'] as int;
      final generalRows = await db.query(
        'conhit_general',
        columns: ['codConHitGeneral'],
        where: 'codProyecto = ? AND codConHit = ?',
        whereArgs: [projectId, controlId],
        orderBy: 'codConHitGeneral DESC',
        limit: 1,
      );
      if (generalRows.isNotEmpty) {
        return _MilestoneScope(
          controlId: controlId,
          generalId: generalRows.first['codConHitGeneral'] as int,
        );
      }
    }

    final generalOnlyRows = await db.query(
      'conhit_general',
      columns: ['codConHit', 'codConHitGeneral'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codConHitGeneral DESC',
      limit: 1,
    );
    if (generalOnlyRows.isNotEmpty) {
      return _MilestoneScope(
        controlId: generalOnlyRows.first['codConHit'] as int,
        generalId: generalOnlyRows.first['codConHitGeneral'] as int,
      );
    }

    final controlId = await _nextMilestoneControlId(db);
    final generalId = await _nextMilestoneGeneralId(db);
    await db.insert('conhit_controlhitos', {
      'codConHit': controlId,
      'codEstado': 1,
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': 'mobile',
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': 'mobile',
      'codProyecto': projectId,
      'sync_status': 'pending',
      'updated_at': nowIso,
    });
    await db.insert('conhit_general', {
      'codConHitGeneral': generalId,
      'codConHit': controlId,
      'codProyecto': projectId,
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': 'mobile',
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': 'mobile',
      'numDiasPlazoTotal': 0,
      'mntTotal': 0.0,
      'numDias': 0,
      'codEstado': 1,
      'dayFechaInicioContractual': nowIso.split('T').first,
      'sync_status': 'pending',
      'updated_at': nowIso,
    });
    await _enqueueSync(
      db,
      entityType: 'milestone_control',
      entityId: '$controlId',
      operationType: 'create',
      payload: {
        'codConHit': controlId,
        'codProyecto': projectId,
        'codEstado': 1,
        'dayFechaCreacion': nowIso,
      },
    );
    await _enqueueSync(
      db,
      entityType: 'milestone_general',
      entityId: '$generalId',
      operationType: 'create',
      payload: {
        'codConHitGeneral': generalId,
        'codConHit': controlId,
        'codProyecto': projectId,
        'numDiasPlazoTotal': 0,
        'mntTotal': 0.0,
        'dayFechaInicioContractual': nowIso.split('T').first,
      },
    );
    return _MilestoneScope(controlId: controlId, generalId: generalId);
  }

  Future<_ResolvedRestrictionArea> _resolveRestrictionAreaSelection(
    Database db, {
    required CatalogOption selectedArea,
    required int projectId,
    required String nowIso,
  }) async {
    if (_isAnalysisAreaOption(selectedArea.id)) {
      final codAnaresArea = _parseAnalysisAreaOptionId(selectedArea.id);
      final rows = await db.query(
        'anares_area',
        columns: ['is_codAnaresAreaLocal'],
        where: 'codAnaresArea = ?',
        whereArgs: [codAnaresArea],
        limit: 1,
      );
      final isLocal = rows.isNotEmpty && (rows.first['is_codAnaresAreaLocal'] as int? ?? 0) == 1;
      return _ResolvedRestrictionArea(
        codAnaresArea: codAnaresArea,
        isLocal: isLocal,
      );
    }

    final baseAreaCode = _parseGeneralAreaOptionId(selectedArea.id);
    final existing = await db.query(
      'anares_area',
      columns: ['codAnaresArea', 'is_codAnaresAreaLocal'],
      where: 'codProyecto = ? AND codArea = ?',
      whereArgs: [projectId, baseAreaCode],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return _ResolvedRestrictionArea(
        codAnaresArea: existing.first['codAnaresArea'] as int,
        isLocal: (existing.first['is_codAnaresAreaLocal'] as int? ?? 0) == 1,
      );
    }

    final companyRows = await db.query(
      'projects_project',
      columns: ['codEmpresa'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    final newAnalysisAreaId = DateTime.now().microsecondsSinceEpoch;
    await db.insert('anares_area', {
      'codAnaresArea': newAnalysisAreaId,
      'codProyecto': projectId,
      'codArea': baseAreaCode,
      'desArea': selectedArea.label,
      'cod_Empresa': companyRows.isEmpty ? null : _asInt(companyRows.first['codEmpresa']),
      'bgColor': selectedArea.colorHex ?? '#FFFFFF',
      'updated_at': nowIso,
      'is_codAnaresAreaLocal': 1,
    });
    await _enqueueSync(
      db,
      entityType: 'analysis_area',
      entityId: '$newAnalysisAreaId',
      operationType: 'create',
      payload: await _buildAnalysisAreaSyncPayload(db, newAnalysisAreaId),
    );

    return _ResolvedRestrictionArea(
      codAnaresArea: newAnalysisAreaId,
      isLocal: true,
    );
  }

  Future<int> _requireRestrictionScope(Database db, int projectId) async {
    final existingRows = await db.query(
      'anares_analysis',
      columns: ['codAnaRes'],
      where: 'codProyecto = ? AND IFNULL(codEstado, 0) = 0',
      whereArgs: [projectId],
      orderBy: 'codAnaRes DESC',
      limit: 1,
    );
    if (existingRows.isNotEmpty) {
      return existingRows.first['codAnaRes'] as int;
    }
    throw Exception('El proyecto no tiene un analisis de restricciones activo. Sincroniza primero el proyecto.');
  }

  Future<Map<String, Object?>> _buildRestrictionSyncPayload(Database db, int restrictionId) async {
    final rows = await db.query(
      'anares_restriction',
      where: 'codAnaResActividad = ?',
      whereArgs: [restrictionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codAnaResActividad': restrictionId};
    }

    final row = Map<String, Object?>.from(rows.first);
    row.remove('sync_status');
    return row;
  }

  Future<Map<String, Object?>> _buildRestrictionFrontSyncPayload(Database db, int frontId) async {
    final rows = await db.query(
      'anares_front',
      where: 'codAnaResFrente = ?',
      whereArgs: [frontId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codAnaResFrente': frontId};
    }

    final row = Map<String, Object?>.from(rows.first);
    row.remove('sync_status');
    return row;
  }

  Future<Map<String, Object?>> _buildRestrictionPhaseSyncPayload(Database db, int phaseId) async {
    final rows = await db.query(
      'anares_phase',
      where: 'codAnaResFase = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codAnaResFase': phaseId};
    }

    final row = Map<String, Object?>.from(rows.first);
    row.remove('sync_status');
    return row;
  }

  Future<Map<String, Object?>> _buildAnalysisAreaSyncPayload(Database db, int analysisAreaId) async {
    final rows = await db.query(
      'anares_area',
      where: 'codAnaresArea = ?',
      whereArgs: [analysisAreaId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codAnaresArea': analysisAreaId};
    }

    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildMilestoneSyncPayload(Database db, int milestoneId) async {
    final rows = await db.query(
      'conhit_detallehitos',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codConHitDetalleHitos': milestoneId};
    }

    final row = Map<String, Object?>.from(rows.first);
    row.remove('sync_status');
    return row;
  }

  Future<Map<String, Object?>> _buildMilestoneExtensionSyncPayload(
    Database db,
    int extensionId, {
    required DateTime previousTargetDate,
  }) async {
    final rows = await db.query(
      'conthit_detallehitosamp',
      where: 'codConHitDetalleHitosAmp = ?',
      whereArgs: [extensionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codConHitDetalleHitosAmp': extensionId};
    }

    final row = Map<String, Object?>.from(rows.first);
    row['previousTargetDate'] = _formatDate(previousTargetDate);
    row.remove('sync_status');
    return row;
  }

  Future<Map<String, Object?>> _buildMilestoneDocumentSyncPayload(Database db, int documentId) async {
    final rows = await db.query(
      'conhit_archivosfechareal',
      where: 'codConhitArchivosFechaReal = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codConhitArchivosFechaReal': documentId};
    }

    final row = Map<String, Object?>.from(rows.first);
    row.remove('sync_status');
    return row;
  }

  Future<void> _clearLocalDataForFreshUser(Database db) async {
    await db.transaction((txn) async {
      for (final table in [
        'anares_analysis',
        'conhit_archivosfechareal',
        'conthit_detallehitosamp',
        'conhit_documentos',
        'conhit_integrantes',
        'conhit_detallehitos',
        'conhit_general',
        'conhit_controlhitos',
        'meetings_comment',
        'meetings_participant',
        'meetings_agreement',
        'meetings_meeting',
        'meetings_summary',
        'anares_restriction',
        'anares_summary',
        'anares_front',
        'anares_phase',
        'anares_area',
        'anares_type',
        'anares_status',
        'projects_member',
        'projects_area_member',
        'projects_project',
        'sync_queue',
        'sync_log',
        'auth_session',
        'auth_user',
        'app_settings',
      ]) {
        await txn.delete(table);
      }
    });
  }

  Future<void> _persistRemoteLogin(
    Database db,
    AuthLoginResult remote, {
    required String password,
    required bool keepSignedIn,
  }) async {
    final now = DateTime.now().toIso8601String();
    final userId = _asInt(remote.user['id']);
    if (userId == null) {
      throw Exception('Auth login remoto no devolvio id de usuario.');
    }
    final firstProjectId = remote.projects.isEmpty ? null : _asInt(remote.projects.first['codProyecto']);

    await db.transaction((txn) async {
      await txn.insert(
        'auth_user',
        {
          'id': userId,
          'name': remote.user['name'],
          'lastname': remote.user['lastname'],
          'email': remote.user['email'],
          'password': password,
          'celular': remote.user['celular'],
          'nombreempresa': remote.user['companyId'],
          'codCargo': _asInt(remote.user['codCargo']),
          'updated_at': _asString(remote.user['updated_at']) ?? now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('auth_session');
      await txn.insert('auth_session', {
        'user_id': userId,
        'token': remote.token,
        'refresh_token': remote.refreshToken,
        'is_active': 1,
        'last_login_at': now,
        'updated_at': now,
      });

      if (remote.projects.isNotEmpty) {
        await _applyProjects(txn, remote.projects);
        if (firstProjectId != null) {
          await txn.update('projects_project', {'is_last_selected': 0});
          await txn.update(
            'projects_project',
            {'is_last_selected': 1, 'updated_at': now},
            where: 'codProyecto = ?',
            whereArgs: [firstProjectId],
          );
        }
      }
    });

    await _saveSetting(db, 'keep_signed_in', keepSignedIn ? '1' : '0');
    await _saveSetting(db, 'session_company_id', remote.user['companyId']?.toString());
    if (firstProjectId != null) {
      await _saveSetting(db, 'current_project_id', '$firstProjectId');
    }
  }

  Future<ProjectSnapshot> _loadProjectSnapshot(Database db, int projectId) async {
    final catalogs = await _loadCatalogs(db, projectId);
    final activeRestrictionModuleId = await _loadActiveRestrictionModuleId(db, projectId);
    final restrictionsRows = await db.query(
      'anares_restriction',
      where: activeRestrictionModuleId == null
          ? 'codProyecto = ? AND IFNULL(codEstadoActividad, \'\') != ?'
          : 'codProyecto = ? AND codAnaRes = ? AND IFNULL(codEstadoActividad, \'\') != ?',
      whereArgs: activeRestrictionModuleId == null ? [projectId, '99'] : [projectId, activeRestrictionModuleId, '99'],
      orderBy: 'priority_order ASC, dayFechaRequerida ASC',
    );
    final restrictions = restrictionsRows.map((row) => _mapRestriction(row, catalogs.areas)).toList();
    final completed = restrictions.where((item) => item.isCompleted).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final summaryRows = await db.query('anares_summary', where: 'codProyecto = ?', whereArgs: [projectId], limit: 1);
    final summary = summaryRows.isEmpty
        ? const RestrictionSummary(total: 0, completed: 0, overdue: 0, inProgress: 0, pending: 0, compliancePercent: 0)
        : RestrictionSummary(
            total: summaryRows.first['totalRestrictions'] as int? ?? 0,
            completed: summaryRows.first['completedCount'] as int? ?? 0,
            overdue: summaryRows.first['overdueCount'] as int? ?? 0,
            inProgress: summaryRows.first['inProgressCount'] as int? ?? 0,
            pending: summaryRows.first['pendingCount'] as int? ?? 0,
            compliancePercent: (summaryRows.first['compliancePercent'] as num?)?.toDouble() ?? 0,
          );

    final meetingSummaryRows = await db.query('meetings_summary', where: 'codProyecto = ?', whereArgs: [projectId], limit: 1);
    final meetingSummary = meetingSummaryRows.isEmpty
        ? const MeetingSummaryRecord(overdueAgreements: 0, pendingAgreements: 0, nextMeetingDate: null)
        : MeetingSummaryRecord(
            overdueAgreements: meetingSummaryRows.first['overdueAgreementsCount'] as int? ?? 0,
            pendingAgreements: meetingSummaryRows.first['pendingAgreementsCount'] as int? ?? 0,
            nextMeetingDate: _parseDate(meetingSummaryRows.first['nextMeetingDate'] as String?),
          );

    final meetingRows = await db.query('meetings_meeting', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'dayFechaReunion ASC');
    final meetings = meetingRows
        .map(
          (row) => MeetingRecord(
            id: row['codActReuReuniones'] as int,
            projectId: row['codProyecto'] as int,
            title: (row['desNombre'] as String?) ?? '',
            category: (row['desCategoria'] as String?) ?? '',
            subCategory: (row['desSubCategoria'] as String?) ?? '',
            meetingDate: _parseDate(row['dayFechaReunion'] as String?) ?? DateTime.now(),
            status: (row['desEstado'] as String?) ?? '',
          ),
        )
        .toList();

    final agreementRows = await db.query('meetings_agreement', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'is_overdue DESC, is_pending DESC, codActReuAcuerdos ASC');
    final agreements = agreementRows
        .map(
          (row) => MeetingAgreementRecord(
            id: row['codActReuAcuerdos'] as int,
            meetingId: row['codActReuReuniones'] as int,
            projectId: row['codProyecto'] as int,
            description: (row['desAcuerdo'] as String?) ?? '',
            responsible: (row['desResponsable'] as String?) ?? '',
            status: _normalizeStoredStatus(_asString(row['codEstado']) ?? 'pending'),
            dueDate: _parseDate(row['dayFechaAcuerdo'] as String?),
            isOverdue: (row['is_overdue'] as int? ?? 0) == 1,
            isPending: (row['is_pending'] as int? ?? 0) == 1,
            isCompleted: (row['is_completed'] as int? ?? 0) == 1,
          ),
        )
        .toList();

    final milestoneControlRows = await db.query(
      'conhit_controlhitos',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codConHit DESC',
      limit: 1,
    );
    final milestoneControlId = milestoneControlRows.isEmpty ? null : _asInt(milestoneControlRows.first['codConHit']);
    final milestoneGeneralRows = milestoneControlId == null
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_general',
            where: 'codProyecto = ? AND codConHit = ?',
            whereArgs: [projectId, milestoneControlId],
            orderBy: 'codConHitGeneral DESC',
            limit: 1,
          );
    final milestoneGeneralId = milestoneGeneralRows.isEmpty ? null : _asInt(milestoneGeneralRows.first['codConHitGeneral']);
    final milestoneRows = (milestoneControlId == null || milestoneGeneralId == null)
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_detallehitos',
            where: 'codProyecto = ? AND codConHit = ? AND codConHitGeneral = ?',
            whereArgs: [projectId, milestoneControlId, milestoneGeneralId],
            orderBy: 'NumOrden ASC, codConHitDetalleHitos ASC',
          );
    final milestoneTypeRows = await db.query('conhit_tipohito', orderBy: 'orden ASC, codTipoHito ASC');
    final milestoneClassificationRows = await db.query('conhit_tipoclasificacion', orderBy: 'orden ASC, codTipoClasificacion ASC');
    final milestoneIds = milestoneRows.map((row) => _asInt(row['codConHitDetalleHitos'])).whereType<int>().toSet();
    final extensionRows = await db.query('conthit_detallehitosamp', orderBy: 'dayFechaCreacion ASC, codConHitDetalleHitosAmp ASC');
    final fileRows = await db.query('conhit_archivosfechareal', orderBy: 'dayFechaCreacion DESC, codConhitArchivosFechaReal DESC');
    final milestoneTypeLabels = <int, String>{
      for (final row in milestoneTypeRows)
        if (_asInt(row['codTipoHito']) != null) _asInt(row['codTipoHito'])!: (row['desTipoHito'] as String?) ?? '',
    };
    final milestoneClassificationLabels = <int, String>{
      for (final row in milestoneClassificationRows)
        if (_asInt(row['codTipoClasificacion']) != null)
          _asInt(row['codTipoClasificacion'])!: (row['desTipoClasificacion'] as String?) ?? '',
    };
    final milestoneTypes = milestoneTypeRows
        .map(
          (row) => MilestoneLookupOption(
            code: (_asInt(row['codTipoHito']) ?? 0).toString(),
            label: ((row['desTipoHito'] as String?) ?? 'Hito').trim(),
            order: _asInt(row['orden']),
          ),
        )
        .toList();
    final milestoneClassifications = milestoneClassificationRows
        .map(
          (row) => MilestoneLookupOption(
            code: (_asInt(row['codTipoClasificacion']) ?? 0).toString(),
            label: ((row['desTipoClasificacion'] as String?) ?? 'General').trim(),
            order: _asInt(row['orden']),
          ),
        )
        .toList();
    final milestoneDocumentsById = <int, List<MilestoneDocumentRecord>>{};
    for (final row in fileRows) {
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      final documentId = _asInt(row['codConhitArchivosFechaReal']);
      if (milestoneId == null || documentId == null || !milestoneIds.contains(milestoneId)) continue;
      milestoneDocumentsById.putIfAbsent(milestoneId, () => []).add(
            MilestoneDocumentRecord(
              id: documentId,
              milestoneId: milestoneId,
              name: (row['desNombreArchivo'] as String?) ?? 'Documento',
              path: (row['desRutaArchivo'] as String?) ?? '',
              uploadedAt: _parseDateTime(row['dayFechaCreacion'] as String?),
              uploadedBy: (row['desUsuarioCreacion'] as String?) ?? '',
            ),
          );
    }
    final milestoneExtensionsById = <int, List<MilestoneExtensionRecord>>{};
    final previousTargetByMilestone = <int, DateTime>{
      for (final row in milestoneRows)
        if (_asInt(row['codConHitDetalleHitos']) != null)
          _asInt(row['codConHitDetalleHitos'])!: _parseDate(row['dayFechaMeta'] as String?) ?? DateTime.now(),
    };
    for (final row in extensionRows) {
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      final extensionId = _asInt(row['codConHitDetalleHitosAmp']);
      if (milestoneId == null || extensionId == null || !milestoneIds.contains(milestoneId)) continue;
      final previousTargetDate = previousTargetByMilestone[milestoneId] ?? DateTime.now();
      final newTargetDate = _parseDate(row['dayFechaMeta'] as String?) ?? previousTargetDate;
      milestoneExtensionsById.putIfAbsent(milestoneId, () => []).add(
            MilestoneExtensionRecord(
              id: extensionId,
              milestoneId: milestoneId,
              justification: (row['desMotivo'] as String?) ?? '',
              previousTargetDate: previousTargetDate,
              newTargetDate: newTargetDate,
              newContractualDate: _parseDate(row['dayFechaContractual'] as String?),
              requestedAt: _parseDateTime(row['dayFechaCreacion'] as String?),
              createdBy: (row['desUsuarioCreacion'] as String?) ?? '',
              supportDocument: (row['desLinklDocuAmp'] as String?) ?? '',
              dateType: (row['desTipoFecha'] as String?) ?? 'both',
            ),
          );
      previousTargetByMilestone[milestoneId] = newTargetDate;
    }
    final milestones = milestoneRows
        .map(
          (row) => _mapMilestone(
            row,
            documents: milestoneDocumentsById[_asInt(row['codConHitDetalleHitos']) ?? -1] ?? const [],
            extensions: milestoneExtensionsById[_asInt(row['codConHitDetalleHitos']) ?? -1] ?? const [],
            typeLabel: milestoneTypeLabels[_asInt(row['codTipoHito'])],
            classificationLabel: milestoneClassificationLabels[_asInt(row['codTipoClasificacion'])],
          ),
        )
        .toList();
    final milestoneGeneral = milestoneGeneralRows.isEmpty ? null : _mapMilestoneGeneral(milestoneGeneralRows.first);
    final milestoneSummary = _buildMilestoneSummary(milestones);

    debugPrint(
      '[AppRepository] snapshot project=$projectId '
      'catalogFronts=${catalogs.fronts.length} catalogPhases=${catalogs.phases.length} '
      'catalogAreas=${catalogs.areas.length} restrictions=${restrictions.length} '
      'meetings=${meetings.length} agreements=${agreements.length} milestones=${milestones.length}',
    );

    return ProjectSnapshot(
      summary: summary,
      restrictions: restrictions,
      completedRestrictions: completed,
      meetingSummary: meetingSummary,
      meetings: meetings,
      agreements: agreements,
      catalogs: catalogs,
      milestoneTypes: milestoneTypes,
      milestoneClassifications: milestoneClassifications,
      milestoneGeneral: milestoneGeneral,
      milestoneSummary: milestoneSummary,
      milestones: milestones,
    );
  }

  Future<RestrictionCatalogs> _loadCatalogs(Database db, int projectId) async {
    final activeRestrictionModuleId = await _loadActiveRestrictionModuleId(db, projectId);
    final fronts = await db.query(
      'anares_front',
      where: activeRestrictionModuleId == null ? 'codProyecto = ?' : 'codProyecto = ? AND codAnaRes = ?',
      whereArgs: activeRestrictionModuleId == null ? [projectId] : [projectId, activeRestrictionModuleId],
      orderBy: 'codAnaResFrente ASC',
    );
    final phases = await db.query(
      'anares_phase',
      where: activeRestrictionModuleId == null ? 'codProyecto = ?' : 'codProyecto = ? AND codAnaRes = ?',
      whereArgs: activeRestrictionModuleId == null ? [projectId] : [projectId, activeRestrictionModuleId],
      orderBy: 'codAnaResFrente ASC, codAnaResFase ASC',
    );
    final projectAreas = await db.query('anares_area', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'desArea COLLATE NOCASE ASC, codAnaresArea ASC');
    final generalAreas = await db.query('projects_area_member', orderBy: 'desArea COLLATE NOCASE ASC, codArea ASC');
    final types = await db.query('anares_type', orderBy: 'codTipoRestriccion ASC');
    final responsibles = await db.query('projects_member', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'codProyIntegrante ASC');
    final statuses = await db.query('anares_status', orderBy: 'codElementoControl ASC, codEstado ASC');
    final projectAreaCodes = projectAreas.map((row) => _asInt(row['codArea'])).whereType<int>().toSet();
    final areaOptions = <CatalogOption>[
      ...projectAreas.map(
        (row) => CatalogOption(
          id: _analysisAreaOptionId(_asInt(row['codAnaresArea'])!),
          label: (row['desArea'] as String?) ?? '',
          colorHex: row['bgColor'] as String? ?? '#FFFFFF',
          referenceId: _asString(row['codArea']),
          projectId: _asInt(row['codProyecto']),
          isLocal: (row['is_codAnaresAreaLocal'] as int? ?? 0) == 1,
        ),
      ),
      ...generalAreas
          .where((row) => !projectAreaCodes.contains(_asInt(row['codArea'])))
          .map(
            (row) => CatalogOption(
              id: _generalAreaOptionId(_asInt(row['codArea'])!),
              label: (row['desArea'] as String?) ?? '',
              referenceId: _asString(row['codArea']),
              colorHex: '#FFFFFF',
            ),
          ),
    ];

    return RestrictionCatalogs(
      fronts: _distinctCatalogOptions(
        fronts
            .map(
              (row) => CatalogOption(
                id: '${row['codAnaResFrente']}',
                label: (row['desAnaResFrente'] as String?) ?? '',
                referenceId: _asString(row['codAnaRes']),
              ),
            )
            .toList(),
      ),
      phases: _distinctCatalogOptions(
        phases
            .map(
              (row) => CatalogOption(
                id: '${row['codAnaResFase']}',
                label: (row['desAnaResFase'] as String?) ?? '',
                colorHex: row['bgColor'] as String?,
                parentId: _asString(row['codAnaResFrente']),
                referenceId: _asString(row['codAnaRes']),
              ),
            )
            .toList(),
      ),
      areas: _distinctCatalogOptions(areaOptions),
      types: _distinctCatalogOptions(
        types.map((row) => CatalogOption(id: '${row['codTipoRestriccion']}', label: (row['desTipoRestriccion'] as String?) ?? '')).toList(),
      ),
      responsibles: _distinctCatalogOptions(
        responsibles.map((row) {
          final email = row['desCorreo'] as String?;
          final rawName = email == null ? 'Integrante' : email.split('@').first.replaceAll('.', ' ');
          return CatalogOption(id: '${row['codProyIntegrante']}', label: _capitalizeWords(rawName));
        }).toList(),
      ),
      statuses: _distinctCatalogOptions(
        statuses.map((row) => CatalogOption(id: (row['codEstado'] as String?) ?? '', label: (row['desEstado'] as String?) ?? '', colorHex: row['iconColor'] as String?)).toList(),
      ),
    );
  }

  List<CatalogOption> _distinctCatalogOptions(List<CatalogOption> options) {
    final seen = <String>{};
    final result = <CatalogOption>[];
    for (final option in options) {
      if (option.id.isEmpty || seen.contains(option.id)) {
        continue;
      }
      seen.add(option.id);
      result.add(option);
    }
    return result;
  }

  String _analysisAreaOptionId(int codAnaresArea) => 'anares:$codAnaresArea';

  String _generalAreaOptionId(int codArea) => 'general:$codArea';

  bool _isAnalysisAreaOption(String value) => value.startsWith('anares:');

  int _parseAnalysisAreaOptionId(String value) => int.parse(value.split(':').last);

  int _parseGeneralAreaOptionId(String value) => int.parse(value.split(':').last);

  RestrictionRecord _mapRestriction(Map<String, Object?> row, List<CatalogOption> areas) {
    final areaCode = row['codAnaresArea']?.toString();
    final areaLabel = areas.firstWhere(
      (item) => item.id == _analysisAreaOptionId(int.tryParse(areaCode ?? '') ?? -1),
      orElse: () => const CatalogOption(id: '', label: ''),
    ).label;
    final requiredDate = _parseDate(row['dayFechaRequerida'] as String?) ?? DateTime.now();
    final conciliatedDate = _parseDate(row['dayFechaConciliada'] as String?);
    final rawStatusCode = (row['codEstadoActividad'] as String?) ?? '';
    final statusLabel = (row['desEstadoActividad'] as String?) ?? 'Pendiente';
    final statusKind = _restrictionStatusKind(rawStatusCode, statusLabel: statusLabel);
    final derivedOverdue = statusKind != 'completed' && _isPastDate(requiredDate);
    final derivedDueToday = statusKind != 'completed' && _isToday(requiredDate);

    return RestrictionRecord(
      id: row['codAnaResActividad'] as int,
      projectId: row['codProyecto'] as int,
      frontId: row['codAnaResFrente'] as int?,
      phaseId: row['codAnaResFase'] as int?,
      areaCode: areaCode,
      front: (row['desFrente'] as String?) ?? '',
      phase: (row['desFase'] as String?) ?? '',
      area: areaLabel,
      activity: (row['desActividad'] as String?) ?? '',
      description: (row['desRestriccion'] as String?) ?? '',
      typeId: row['codTipoRestriccion'] as int?,
      type: (row['desTipoRestriccion'] as String?) ?? '',
      requiredDate: requiredDate,
      conciliatedDate: conciliatedDate,
      responsibleId: row['idUsuarioResponsable'] as int?,
      responsible: (row['desResponsable'] as String?) ?? '',
      statusCode: rawStatusCode,
      statusLabel: statusLabel,
      statusColor: (row['colorEstado'] as String?) ?? '#98A3B3',
      requester: (row['desSolicitante'] as String?) ?? '',
      isCompleted: statusKind == 'completed',
      isOverdue: derivedOverdue,
      isDueToday: derivedDueToday,
      isPending: statusKind == 'pending',
      isInProgress: statusKind == 'in_progress',
      priorityOrder: derivedOverdue ? 1 : ((row['priority_order'] as int?) ?? _priorityOrder(statusKind)),
      syncStatus: (row['sync_status'] as String?) ?? 'synced',
      updatedAt: _parseDateTime(row['dayFechaModificacion'] as String?) ?? DateTime.now(),
    );
  }

  MilestoneGeneralRecord _mapMilestoneGeneral(Map<String, Object?> row) {
    return MilestoneGeneralRecord(
      projectId: row['codProyecto'] as int,
      controlId: row['codConHit'] as int,
      generalId: row['codConHitGeneral'] as int,
      startDate: _parseDate(row['dayFechaInicioContractual'] as String?),
      totalDays: row['numDiasPlazoTotal'] as int? ?? row['numDias'] as int? ?? 0,
      totalAmount: _asDouble(row['mntTotal']),
      statusCode: _asString(row['codEstado']) ?? '1',
    );
  }

  MilestoneRecord _mapMilestone(
    Map<String, Object?> row, {
    required List<MilestoneDocumentRecord> documents,
    required List<MilestoneExtensionRecord> extensions,
    String? typeLabel,
    String? classificationLabel,
  }) {
    final contractualDate = _parseDate(row['dayFechaContractual'] as String?) ?? DateTime.now();
    final targetDate = _parseDate(row['dayFechaMeta'] as String?) ?? contractualDate;
    final id = row['codConHitDetalleHitos'] as int;
    final order = row['NumOrden'] as int? ?? 0;
    return MilestoneRecord(
      id: id,
      controlId: row['codConHit'] as int? ?? 0,
      generalId: row['codConHitGeneral'] as int? ?? 0,
      projectId: row['codProyecto'] as int? ?? 0,
      code: 'HT-${order.toString().padLeft(3, '0')}',
      order: order,
      description: (row['desDescripcion'] as String?) ?? '',
      typeCode: _asInt(row['codTipoHito']),
      typeLabel: (typeLabel == null || typeLabel.isEmpty) ? _milestoneTypeLabel(_asInt(row['codTipoHito'])) : typeLabel,
      classificationCode: _asInt(row['codTipoClasificacion']),
      classificationLabel: (classificationLabel == null || classificationLabel.isEmpty)
          ? _milestoneClassificationLabel(_asInt(row['codTipoClasificacion']))
          : classificationLabel,
      days: _asInt(row['numplazo']),
      isPenalizable: _asDouble(row['porPenalidad']) > 0,
      penaltyPercent: _asDouble(row['porPenalidad']),
      contractualDate: contractualDate,
      targetDate: targetDate,
      actualDate: _parseDate(row['dayFechaReal'] as String?),
      contractualExtensionCount: row['numCantAmpContractual'] as int? ?? 0,
      targetExtensionCount: row['numCantAmpMeta'] as int? ?? 0,
      contractualStatusCode: _asString(row['codEstadoContractual']) ?? '',
      internalStatusCode: _asString(row['codEstadoInternos']) ?? '1',
      penaltyAmount: _asDouble(row['mntPealidad']),
      createdAt: _parseDateTime(row['dayFechaCreacion'] as String?),
      modifiedAt: _parseDateTime(row['dayFechaModificacion'] as String?),
      extendedContractualDate: _parseDate(row['dayFechaContractualAmp'] as String?),
      extendedTargetDate: _parseDate(row['dayFechaMetaAmp'] as String?),
      syncStatus: (row['sync_status'] as String?) ?? 'synced',
      documents: documents,
      extensions: extensions,
    );
  }

  MilestoneDashboardSummary _buildMilestoneSummary(List<MilestoneRecord> records) {
    final completed = records.where((item) => item.isCompleted).length;
    final inProgress = records.where((item) => item.isInProgress).length;
    final delayed = records.where((item) => item.isDelayed).length;
    final activeDelay = records.where((item) => item.delayDays > 0 && !item.isCompleted).length;
    final compliance = records.isEmpty ? 0.0 : completed / records.length;
    final accumulatedPenalty = records.where((item) => item.isCompleted && item.delayDays > 0).fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final potentialPenalty = records.where((item) => !item.isCompleted).fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final activeExtensions = records.fold<int>(0, (sum, item) => sum + item.extensionCount);

    return MilestoneDashboardSummary(
      compliance: compliance,
      completedCount: completed,
      inProgressCount: inProgress,
      delayedCount: delayed,
      activeDelayCount: activeDelay,
      accumulatedPenalty: accumulatedPenalty,
      potentialPenalty: potentialPenalty,
      activeExtensions: activeExtensions,
    );
  }

  Future<void> _recalculateMilestoneDerivedFields(Database db, int milestoneId) async {
    final rows = await db.query(
      'conhit_detallehitos',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final row = rows.first;
    final generalId = _asInt(row['codConHitGeneral']);
    final generalRows = generalId == null
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_general',
            columns: ['mntTotal'],
            where: 'codConHitGeneral = ?',
            whereArgs: [generalId],
            limit: 1,
          );
    final totalAmount = generalRows.isEmpty ? 0.0 : _asDouble(generalRows.first['mntTotal']);
    final derived = _calculateMilestoneDerivedData(row, totalAmount: totalAmount);

    await db.update(
      'conhit_detallehitos',
      {
        'codEstadoContractual': derived.contractualStatusCode,
        'codEstadoInternos': derived.internalStatusCode,
        'mntPealidad': derived.penaltyAmount,
      },
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );
  }

  _MilestoneDerivedData _calculateMilestoneDerivedData(Map<String, Object?> row, {required double totalAmount}) {
    final today = _parseDateOnly(DateTime.now());

    final contractualBase = _parseDateOnly(row['dayFechaContractual']);
    final contractualAmp = _parseDateOnly(row['dayFechaContractualAmp']);
    final contractualDate = contractualAmp ?? contractualBase;
    final targetBase = _parseDateOnly(row['dayFechaMeta']);
    final targetAmp = _parseDateOnly(row['dayFechaMetaAmp']);
    final targetDate = targetAmp ?? targetBase;
    final realDate = _parseDateOnly(row['dayFechaReal']);
    final penaltyPercent = _asDouble(row['porPenalidad']);

    int? contractualCounter;
    int? contractualStatusCode;
    if (contractualDate != null) {
      final referenceDate = realDate ?? today;
      if (referenceDate != null) {
        contractualCounter = contractualDate.difference(referenceDate).inDays.round();
        contractualStatusCode = realDate != null ? 3 : (contractualCounter < 0 ? 2 : 1);
      }
    }

    int? internalCounter;
    int? internalStatusCode;
    if (targetDate != null) {
      final referenceDate = realDate ?? today;
      if (referenceDate != null) {
        internalCounter = targetDate.difference(referenceDate).inDays.round();
        internalStatusCode = realDate != null ? 3 : (internalCounter < 0 ? 2 : 1);
      }
    }

    var penaltyAmount = 0.0;
    if (contractualCounter != null &&
        contractualCounter != 0 &&
        totalAmount != 0 &&
        penaltyPercent != 0.0 &&
        (contractualStatusCode == 2 || contractualStatusCode == 3) &&
        row['dayFechaContractual'] != null) {
      penaltyAmount = (contractualCounter * totalAmount * penaltyPercent).abs();
    }

    return _MilestoneDerivedData(
      contractualStatusCode: contractualStatusCode,
      internalStatusCode: internalStatusCode,
      penaltyAmount: penaltyAmount,
    );
  }

  Future<void> _refreshDerivedState(Database db, {int? projectId}) async {
    await _refreshRestrictionDerivedFlags(db, projectId: projectId);
    if (projectId != null) {
      await _database.refreshProjectSummary(db, projectId);
      await _database.refreshMeetingSummary(db, projectId);
      return;
    }

    final projectRows = await db.query('projects_project', columns: ['codProyecto']);
    for (final row in projectRows) {
      final currentProjectId = row['codProyecto'] as int;
      await _database.refreshProjectSummary(db, currentProjectId);
      await _database.refreshMeetingSummary(db, currentProjectId);
    }
  }

  Future<void> _refreshRestrictionDerivedFlags(Database db, {int? projectId}) async {
    final rows = await db.query(
      'anares_restriction',
      columns: ['codAnaResActividad', 'codEstadoActividad', 'desEstadoActividad', 'dayFechaRequerida'],
      where: projectId == null ? "IFNULL(codEstadoActividad, '') != ?" : "codProyecto = ? AND IFNULL(codEstadoActividad, '') != ?",
      whereArgs: projectId == null ? ['99'] : [projectId, '99'],
    );
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final id = row['codAnaResActividad'] as int;
      final statusCode = (row['codEstadoActividad'] as String?) ?? '';
      final statusLabel = (row['desEstadoActividad'] as String?) ?? '';
      final statusKind = _restrictionStatusKind(statusCode, statusLabel: statusLabel);
      final requiredDate = _parseDate(row['dayFechaRequerida'] as String?);
      final completed = statusKind == 'completed';
      final overdue = !completed && requiredDate != null && _isPastDate(requiredDate);
      final dueToday = !completed && requiredDate != null && _isToday(requiredDate);
      await db.update(
        'anares_restriction',
        {
          'is_completed': completed ? 1 : 0,
          'is_overdue': overdue ? 1 : 0,
          'is_due_today': dueToday ? 1 : 0,
          'is_pending': statusKind == 'pending' ? 1 : 0,
          'is_in_progress': statusKind == 'in_progress' ? 1 : 0,
          'priority_order': overdue ? 1 : _priorityOrder(statusKind),
          'updated_at': now,
        },
        where: 'codAnaResActividad = ?',
        whereArgs: [id],
      );
    }

    final agreementRows = await db.query(
      'meetings_agreement',
      columns: ['codActReuAcuerdos', 'codEstado', 'dayFechaAcuerdo'],
      where: projectId == null ? null : 'codProyecto = ?',
      whereArgs: projectId == null ? null : [projectId],
    );
    for (final row in agreementRows) {
      final id = row['codActReuAcuerdos'] as int;
      final statusCode = _normalizeStoredStatus(_asString(row['codEstado']) ?? 'pending');
      final dueDate = _parseDate(row['dayFechaAcuerdo'] as String?);
      final completed = statusCode == 'completed';
      final pending = statusCode == 'pending';
      final overdue = !completed && dueDate != null && _isPastDate(dueDate);
      await db.update(
        'meetings_agreement',
        {
          'desEstado': _agreementStatusLabel(statusCode, isOverdue: overdue),
          'desGrupoAcuerdo': completed ? 'Completado' : (overdue ? 'Vencido' : 'Pendiente'),
          'desColorGrupoAcuerdo': completed ? '#1B8E5A' : (overdue ? '#D64545' : '#F0A11E'),
          'is_overdue': overdue ? 1 : 0,
          'is_pending': pending ? 1 : 0,
          'is_completed': completed ? 1 : 0,
          'updated_at': now,
        },
        where: 'codActReuAcuerdos = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> _enqueueSync(
    Database db, {
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, Object?> payload,
  }) async {
    final enrichedPayload = await _attachGeolocationMetadata(db, payload);
    final now = DateTime.now().toIso8601String();
    final existing = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND status IN (?, ?)',
      whereArgs: [entityType, entityId, 'pending', 'failed'],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final current = existing.first;
      final currentOperation = (current['operation_type'] as String?) ?? operationType;
      final mergedOperation = currentOperation == 'create' ? 'create' : operationType;
      await db.update(
        'sync_queue',
        {
          'operation_type': mergedOperation,
          'payload_json': jsonEncode(enrichedPayload),
          'status': 'pending',
          'error_message': null,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [current['id']],
      );
      return;
    }

    await db.insert('sync_queue', {
      'id': await _nextSyncQueueId(db),
      'entity_type': entityType,
      'entity_id': entityId,
      'operation_type': operationType,
      'payload_json': jsonEncode(enrichedPayload),
      'status': 'pending',
      'retry_count': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<Map<String, Object?>> _attachGeolocationMetadata(
    Database db,
    Map<String, Object?> payload,
  ) async {
    final enriched = Map<String, Object?>.from(payload);
    enriched['geolocation'] = await _buildGeolocationPayload(db);
    return enriched;
  }

  Future<Map<String, Object?>> _buildGeolocationPayload(Database db) async {
    final capturedAt = DateTime.now().toIso8601String();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    await _saveSetting(db, _locationPermissionStatusKey, permission.name);

    if (!serviceEnabled) {
      return {
        'permissionStatus': permission.name,
        'serviceEnabled': false,
        'capturedAt': capturedAt,
        'latitude': null,
        'longitude': null,
        'accuracy': null,
      };
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return {
        'permissionStatus': permission.name,
        'serviceEnabled': true,
        'capturedAt': capturedAt,
        'latitude': null,
        'longitude': null,
        'accuracy': null,
      };
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      final position =
          lastKnown ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );

      return {
        'permissionStatus': permission.name,
        'serviceEnabled': true,
        'capturedAt': capturedAt,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (_) {
      return {
        'permissionStatus': permission.name,
        'serviceEnabled': true,
        'capturedAt': capturedAt,
        'latitude': null,
        'longitude': null,
        'accuracy': null,
      };
    }
  }

  bool shouldRunDailyFullSync(AppPreferences preferences, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (current.hour < 6) {
      return false;
    }
    final currentBusinessDate = _currentBusinessDateKey(now: current);
    return preferences.lastDailyFullSyncBusinessDate != currentBusinessDate;
  }

  bool shouldRunOperationalSync(AppPreferences preferences, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (current.hour < 6 || current.hour >= 19) {
      return false;
    }
    final lastSyncAt = preferences.lastSyncAt;
    if (lastSyncAt == null) {
      return true;
    }
    return current.difference(lastSyncAt).inMinutes >= 30;
  }

  Future<void> _ensureRemoteSyncAllowed(AppPreferences preferences) async {
    if (preferences.isOfflineEffective) {
      throw Exception('La app esta en modo offline. Desactiva el modo offline para sincronizar.');
    }
    if (!preferences.remoteSyncEnabled) {
      throw Exception('La sincronizacion remota esta deshabilitada.');
    }
    if (!preferences.apiConfigured) {
      throw Exception('No se configuro DIREKTOR_API_BASE_URL.');
    }
  }

  Future<void> _pushQueue(
    Database db, {
    required List<Map<String, Object?>> queue,
    required int userId,
    String? authToken,
    Object? companyId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _normalizePendingSyncQueueIds(db);
    final effectiveQueue = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
    final items = <Map<String, Object?>>[];
    for (final row in effectiveQueue) {
      final queueId = row['id'];
      final entityType = row['entity_type'] as String? ?? '';
      final entityId = row['entity_id'] as String? ?? '';
      final rawOperationType = row['operation_type'] as String? ?? '';
      final operationType =
          entityType == 'restriction' && rawOperationType == 'status_update' ? 'update' : rawOperationType;
      final payloadJson = row['payload_json'] as String? ?? '{}';

      items.add({
        'queueId': queueId,
        'entityType': entityType,
        'entityId': entityId,
        'operationType': operationType,
        'payload': payloadJson,
      });
    }

    debugPrint(
      '[AppRepository] push queue userId=$userId companyId=$companyId items=${items.length} '
      'types=${items.map((item) => '${item['entityType']}:${item['operationType']}').join(', ')}',
    );
    if (items.isNotEmpty) {
      debugPrint('[AppRepository] push first payload=${jsonEncode(items.first)}');
    }

    try {
      await _syncApiClient.pushInbox(
        userId: userId,
        authToken: authToken,
        companyId: companyId,
        items: items,
      );

      for (final row in effectiveQueue) {
        final queueId = row['id'] as int;
        final entityType = row['entity_type'] as String? ?? '';
        final entityId = row['entity_id'] as String? ?? '';
        await db.update(
          'sync_queue',
          {
            'status': 'synced',
            'error_message': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [queueId],
        );
        if (entityType == 'restriction') {
          await db.update(
            'anares_restriction',
            {'sync_status': 'synced', 'updated_at': now},
            where: 'codAnaResActividad = ?',
            whereArgs: [int.tryParse(entityId)],
          );
        }
        await db.insert('sync_log', {
          'entity_type': entityType,
          'entity_id': entityId,
          'action': row['operation_type'] as String? ?? 'sync',
          'result': 'success',
          'message': 'Enviado correctamente a sync_inbox',
          'created_at': now,
        });
      }
    } catch (error) {
      for (final row in effectiveQueue) {
        final retryCount = (row['retry_count'] as int? ?? 0) + 1;
        await db.update(
          'sync_queue',
          {
            'status': 'failed',
            'retry_count': retryCount,
            'error_message': error.toString(),
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        await db.insert('sync_log', {
          'entity_type': row['entity_type'] as String? ?? '',
          'entity_id': row['entity_id'] as String? ?? '',
          'action': row['operation_type'] as String? ?? 'sync',
          'result': 'failed',
          'message': error.toString(),
          'created_at': now,
        });
      }
      rethrow;
    }
  }

  Future<void> _pullRemoteData(
    Database db, {
    required int userId,
    required String scope,
    required String businessDate,
    required String? since,
    String? authToken,
    String? companyId,
    bool markDailyFullSync = false,
  }) async {
    final result = await _syncApiClient.pullData(
      userId: userId,
      scope: scope,
      businessDate: businessDate,
      since: since,
      authToken: authToken,
      companyId: companyId,
    );

    debugPrint(
      '[AppRepository] pull scope=$scope userId=$userId companyId=$companyId '
      'projects=${_asMapList(result.payload['projects']).length} '
      'restrictions=${_asMapList(result.payload['restrictions']).length} '
      'meetings=${_asMapList(result.payload['meetings']).length} '
      'agreements=${_asMapList(result.payload['agreements']).length} '
      'comments=${_asMapList(result.payload['comments']).length} '
      'milestones=${_asMapList(result.payload['milestones']).length}',
    );

    final anares = _asMap(result.payload['anares']);
    final actreu = _asMap(result.payload['actreu']);
    if (scope == 'full') {
      debugPrint(
        '[AppRepository] pull masters '
        'areas=${_asMapList(anares['areas']).length} '
        'analysisAreas=${_asMapList(anares['analysisAreas']).length} '
        'fronts=${_asMapList(anares['fronts']).length} '
        'phases=${_asMapList(anares['phases']).length} '
        'types=${_asMapList(anares['types']).length} '
        'statuses=${_asMapList(anares['statuses']).length} '
        'members=${_asMapList(anares['members']).length} '
        'participants=${_asMapList(actreu['participants']).length}',
      );
    }

    if (scope == 'operational' && await _containsNewProjects(db, result.payload)) {
      await _pullRemoteData(
        db,
        userId: userId,
        scope: 'full',
        businessDate: businessDate,
        since: null,
        authToken: authToken,
        companyId: companyId,
      );
      return;
    }

    await db.transaction((txn) async {
      await _applyPullPayload(txn, result.payload, scope: scope);
    });

    final now = DateTime.now().toIso8601String();
    await _saveSetting(db, 'last_sync_at', now);
    final version = result.payload['version']?.toString();
    if (version != null && version.isNotEmpty) {
      await _saveSetting(db, 'last_sync_version', version);
    }
    if (scope == 'full' && markDailyFullSync) {
      await _saveSetting(db, 'last_daily_full_sync_business_date', businessDate);
    }
    await _refreshDerivedState(db);
    await _logTableCounts(db, label: 'after_pull_$scope');
    await db.insert('sync_log', {
      'entity_type': 'system',
      'entity_id': businessDate,
      'action': scope == 'full' ? 'full_pull' : 'operational_pull',
      'result': 'success',
      'message': scope == 'full' ? 'Descarga total completada.' : 'Descarga operativa completada.',
      'created_at': now,
    });
  }

  Future<void> _applyPullPayload(DatabaseExecutor txn, Map<String, dynamic> payload, {required String scope}) async {
    await _applyProjects(txn, _asMapList(payload['projects']));
    final conthit = _asMap(payload['conthit']);
    final legacyConhit = _asMap(payload['conhit']);
    final legacyControlHitos = _asMap(payload['controlHitos']);
    List<Map<String, dynamic>> controlHitosRows(String key) {
      final rowsFromConthit = _asMapList(conthit[key]);
      if (rowsFromConthit.isNotEmpty) return rowsFromConthit;
      final rowsFromLegacyConhit = _asMapList(legacyConhit[key]);
      if (rowsFromLegacyConhit.isNotEmpty) return rowsFromLegacyConhit;
      final rowsFromLegacyControlHitos = _asMapList(legacyControlHitos[key]);
      if (rowsFromLegacyControlHitos.isNotEmpty) return rowsFromLegacyControlHitos;
      return _asMapList(payload[key]);
    }

    if (scope == 'full') {
      final anares = _asMap(payload['anares']);
      final actreu = _asMap(payload['actreu']);
      final catalogs = _asMap(payload['catalogs']);

      await _applyAreaMembers(
        txn,
        _asMapList(anares.isNotEmpty ? anares['areas'] : catalogs['areas']),
      );
      await _applyRestrictionModules(
        txn,
        _asMapList(anares.isNotEmpty ? anares['analysis'] : payload['analysisRestrictions']),
      );
      await _applyAnalysisAreas(
        txn,
        _asMapList(anares.isNotEmpty ? anares['analysisAreas'] : catalogs['analysisAreas']),
      );
      await _applyTypes(
        txn,
        _asMapList(anares.isNotEmpty ? anares['types'] : catalogs['types']),
      );
      await _applyStatuses(
        txn,
        _asMapList(anares.isNotEmpty ? anares['statuses'] : catalogs['statuses']),
      );
      await _applyMembers(
        txn,
        _asMapList(anares.isNotEmpty ? anares['members'] : catalogs['members']),
      );
      await _applyFronts(
        txn,
        _asMapList(anares.isNotEmpty ? anares['fronts'] : catalogs['fronts']),
      );
      await _applyPhases(
        txn,
        _asMapList(anares.isNotEmpty ? anares['phases'] : catalogs['phases']),
      );
      await _applyParticipants(
        txn,
        _asMapList(actreu.isNotEmpty ? actreu['participants'] : payload['participants']),
      );
      await _applyMilestoneTypes(txn, controlHitosRows('milestoneTypes'));
      await _applyMilestoneClassifications(txn, controlHitosRows('milestoneClassifications'));
      await _applyMilestoneInternalStatuses(txn, controlHitosRows('milestoneStatusesInterno'));
      await _applyMilestoneContractualStatuses(txn, controlHitosRows('milestoneStatusesContractual'));
    }

    await _applyRestrictions(txn, _asMapList(payload['restrictions']));
    await _applyMeetings(txn, _asMapList(payload['meetings']));
    await _applyAgreements(txn, _asMapList(payload['agreements']));
    await _applyComments(txn, _asMapList(payload['comments']));
    await _applyMilestoneControls(txn, controlHitosRows('milestoneControls'));
    await _applyMilestoneGenerals(txn, controlHitosRows('milestoneGenerals'));
    await _applyMilestones(txn, controlHitosRows('milestones'));
    await _applyMilestoneDocuments(txn, controlHitosRows('milestoneDocuments'));
    await _applyMilestoneExtensions(txn, controlHitosRows('milestoneExtensions'));
  }

  Future<void> _logTableCounts(Database db, {required String label}) async {
    final projects = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM projects_project')) ?? 0;
    final restrictions = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM anares_restriction')) ?? 0;
    final meetings = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM meetings_meeting')) ?? 0;
    final agreements = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM meetings_agreement')) ?? 0;
    final comments = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM meetings_comment')) ?? 0;
    final projectAreas = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM anares_area')) ?? 0;
    final generalAreas = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM projects_area_member')) ?? 0;
    final currentProject = await _loadCurrentProjectId(db);

    debugPrint(
      '[AppRepository] $label currentProject=$currentProject '
      'projects=$projects restrictions=$restrictions meetings=$meetings '
      'agreements=$agreements comments=$comments anaresArea=$projectAreas generalAreas=$generalAreas',
    );
  }

  Future<bool> _containsNewProjects(Database db, Map<String, dynamic> payload) async {
    final remoteProjects = _asMapList(payload['projects']);
    if (remoteProjects.isEmpty) {
      return false;
    }

    final localProjectRows = await db.query('projects_project', columns: ['codProyecto']);
    final localIds = localProjectRows.map((row) => row['codProyecto']).whereType<int>().toSet();

    for (final project in remoteProjects) {
      final remoteId = _asInt(project['codProyecto']);
      if (remoteId != null && !localIds.contains(remoteId)) {
        return true;
      }
    }

    return false;
  }

  Future<void> _applyProjects(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codProyecto']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('projects_project', where: 'codProyecto = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'projects_project',
        {
          'codProyecto': id,
          'desNombreProyecto': row['desNombreProyecto'],
          'codEstado': _asInt(row['codEstado']),
          'codEmpresa': _asInt(row['codEmpresa'] ?? row['cod_Empresa']),
          'desEmpresa': row['desEmpresa'] ?? row['des_Empresa'],
          'codTipoProyecto': _asInt(row['codTipoProyecto']),
          'desTipoProyecto': row['desTipoProyecto'],
          'codMoneda': _asInt(row['codMoneda']),
          'desMoneda': row['desMoneda'],
          'desSimboloMoneda': row['desSimboloMoneda'],
          'codUbigeo': _asInt(row['codUbigeo']),
          'desUbigeo': row['desUbigeo'],
          'desDireccion': row['desDireccion'],
          'dayFechaInicio': row['dayFechaInicio'],
          'is_last_selected': _asBoolInt(row['is_last_selected']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMembers(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codProyIntegrante']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping member $id because project $projectId is missing locally');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('projects_member', where: 'codProyIntegrante = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'projects_member',
        {
          'codProyIntegrante': id,
          'codProyecto': _asInt(row['codProyecto']),
          'user_id': _asInt(row['user_id']),
          'codArea': _asInt(row['codArea']),
          'desArea': row['desArea'],
          'codRolIntegrante': _asInt(row['codRolIntegrante']),
          'desRolIntegrante': row['desRolIntegrante'],
          'codEstadoInvitacion': row['codEstadoInvitacion'],
          'desCorreo': row['desCorreo'],
          'numCelular': row['numCelular'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAreaMembers(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codArea']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('projects_area_member', where: 'codArea = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'projects_area_member',
        {
          'codArea': id,
          'desArea': row['desArea'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyRestrictionModules(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaRes']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping restriction module $id because project $projectId is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'analysis_module', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'analysis_module', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row) || (_asInt(row['codEstado']) ?? 0) != 0) {
        await txn.delete('anares_analysis', where: 'codAnaRes = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_analysis',
        {
          'codAnaRes': id,
          'codProyecto': projectId,
          'codEstado': _asInt(row['codEstado']),
          'dayFechaCreacion': row['dayFechaCreacion'],
          'desUsuarioCreacion': row['desUsuarioCreacion'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAnalysisAreas(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaresArea']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping analysis area $id because project $projectId is missing locally');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('anares_area', where: 'codAnaresArea = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_area',
        {
          'codAnaresArea': id,
          'codProyecto': projectId,
          'codArea': _asInt(row['codArea']),
          'desArea': row['desArea'],
          'cod_Empresa': _asInt(row['cod_Empresa'] ?? row['codEmpresa']),
          'bgColor': row['bgColor'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
          'is_codAnaresAreaLocal': _asBoolInt(row['is_codAnaresAreaLocal']),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyFronts(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final codAnaRes = _asInt(row['codAnaRes'] ?? row['codAnares']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping front $id because project $projectId is missing locally');
        continue;
      }
      if (codAnaRes != null && !await _restrictionModuleExists(txn, codAnaRes)) {
        debugPrint('[AppRepository] skipping front $id because analysis module $codAnaRes is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'analysis_front', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'analysis_front', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('anares_front', where: 'codAnaResFrente = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_front',
        {
          'codAnaResFrente': id,
          'codProyecto': projectId,
          'codAnaRes': codAnaRes,
          'desAnaResFrente': row['desAnaResFrente'] ?? row['desAnaresFrente'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyPhases(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResFase'] ?? row['codAnaresFase']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final frontId = _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']);
      final codAnaRes = _asInt(row['codAnaRes'] ?? row['codAnares']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping phase $id because project $projectId is missing locally');
        continue;
      }
      if (frontId != null && !await _frontExists(txn, frontId)) {
        debugPrint('[AppRepository] skipping phase $id because front $frontId is missing locally');
        continue;
      }
      if (codAnaRes != null && !await _restrictionModuleExists(txn, codAnaRes)) {
        debugPrint('[AppRepository] skipping phase $id because analysis module $codAnaRes is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'analysis_phase', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'analysis_phase', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('anares_phase', where: 'codAnaResFase = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_phase',
        {
          'codAnaResFase': id,
          'codAnaResFrente': frontId,
          'codProyecto': projectId,
          'codAnaRes': codAnaRes,
          'desAnaResFase': row['desAnaResFase'] ?? row['desAnaresFase'],
          'bgColor': row['bgColor'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyTypes(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codTipoRestriccion'] ?? row['codTipoRestricciones']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('anares_type', where: 'codTipoRestriccion = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_type',
        {
          'codTipoRestriccion': id,
          'desTipoRestriccion': row['desTipoRestriccion'] ?? row['desTipoRestricciones'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyStatuses(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asString(row['codEstado']);
      if (id == null || id.isEmpty) continue;
      if (_isDeleted(row)) {
        await txn.delete('anares_status', where: 'codEstado = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_status',
        {
          'codEstado': id,
          'desEstado': row['desEstado'],
          'iconColor': row['iconColor'],
          'codModulo': _asInt(row['codModulo']),
          'codElementoControl': _asInt(row['codElementoControl']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyRestrictions(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResActividad']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final codAnaRes = _asInt(row['codAnaRes'] ?? row['codAnares']);
      final frontId = _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']);
      final phaseId = _asInt(row['codAnaResFase'] ?? row['codAnaresFase']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping restriction $id because project $projectId is missing locally');
        continue;
      }
      if (codAnaRes != null && !await _restrictionModuleExists(txn, codAnaRes)) {
        debugPrint('[AppRepository] skipping restriction $id because analysis module $codAnaRes is missing locally');
        continue;
      }
      if (frontId != null && !await _frontExists(txn, frontId)) {
        debugPrint('[AppRepository] skipping restriction $id because front $frontId is missing locally');
        continue;
      }
      if (phaseId != null && !await _phaseExists(txn, phaseId)) {
        debugPrint('[AppRepository] skipping restriction $id because phase $phaseId is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'restriction', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'restriction', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('anares_restriction', where: 'codAnaResActividad = ?', whereArgs: [id]);
        continue;
      }

      final statusCode = _asString(row['codEstadoActividad']) ?? '';
      await txn.insert(
        'anares_restriction',
        {
          'codAnaResActividad': id,
          'codProyecto': projectId,
          'codAnaRes': codAnaRes,
          'codAnaResFrente': frontId,
          'codAnaResFase': phaseId,
          'desFrente': row['desFrente'],
          'desFase': row['desFase'],
          'desActividad': row['desActividad'],
          'desRestriccion': row['desRestriccion'],
          'codTipoRestriccion': _asInt(row['codTipoRestriccion']),
          'desTipoRestriccion': row['desTipoRestriccion'],
          'dayFechaRequerida': row['dayFechaRequerida'],
          'dayFechaConciliada': row['dayFechaConciliada'],
          'dayFechaLevantamiento': row['dayFechaLevantamiento'],
          'idUsuarioResponsable': _asInt(row['idUsuarioResponsable']),
          'desResponsable': row['desResponsable'],
          'codEstadoActividad': statusCode,
          'desEstadoActividad': row['desEstadoActividad'],
          'colorEstado': row['colorEstado'],
          'codAnaresArea': _asString(row['codAnaresArea']),
          'codUsuarioSolicitante': _asString(row['codUsuarioSolicitante']),
          'desSolicitante': row['desSolicitante'],
          'is_completed': _asBoolInt(row['is_completed']),
          'is_overdue': _asBoolInt(row['is_overdue']),
          'is_due_today': _asBoolInt(row['is_due_today']),
          'is_pending': _asBoolInt(row['is_pending']),
          'is_in_progress': _asBoolInt(row['is_in_progress']),
          'priority_order': _asInt(row['priority_order']) ?? _priorityOrder(_restrictionStatusKind(statusCode, statusLabel: _asString(row['desEstadoActividad']) ?? '')),
          'dayFechaCreacion': row['dayFechaCreacion'],
          'dayFechaModificacion': row['dayFechaModificacion'],
          'sync_status': 'synced',
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMeetings(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuReuniones']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping meeting $id because project $projectId is missing locally');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('meetings_meeting', where: 'codActReuReuniones = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'meetings_meeting',
        {
          'codActReuReuniones': id,
          'codProyecto': projectId,
          'codActReu': _asInt(row['codActReu']),
          'codActReuCategoria': _asInt(row['codActReuCategoria']),
          'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
          'desCategoria': row['desCategoria'] ?? row['desNombreCategoria'],
          'desSubCategoria': row['desSubCategoria'] ?? row['desNombreSubCategoria'],
          'desNombre': row['desNombre'],
          'dayFechaReunion': row['dayFechaReunion'],
          'dayFechaCierre': row['dayFechaCierre'],
          'horHoraInicio': row['horHoraInicio'],
          'horHoraFin': row['horHoraFin'],
          'codEstado': row['codEstado'],
          'desEstado': row['desEstado'],
          'desLinkActaReunion': row['desLinkActaReunion'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyParticipants(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuParticipante']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping participant $id because project $projectId is missing locally');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('meetings_participant', where: 'codActReuParticipante = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'meetings_participant',
        {
          'codActReuParticipante': id,
          'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
          'codProyecto': projectId,
          'idUsuarioParticipante': _asInt(row['idUsuarioParticipante']),
          'codProyIntegrante': _asInt(row['codProyIntegrante']),
          'desNombre': row['desNombre'],
          'desCorreoElectronico': row['desCorreoElectronico'],
          'codArea': _asString(row['codArea']),
          'flgParticipanteInvitado': _asBoolInt(row['flgParticipanteInvitado']),
          'codEstado': _asInt(row['codEstado']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAgreements(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuAcuerdos']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping agreement $id because project $projectId is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'agreement', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'agreement', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('meetings_agreement', where: 'codActReuAcuerdos = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'meetings_agreement',
        {
          'codActReuAcuerdos': id,
          'codActReuReuniones': _asInt(row['codActReuReuniones']),
          'codProyecto': projectId,
          'desAcuerdo': row['desAcuerdo'],
          'dayFechaAcuerdo': row['dayFechaAcuerdo'],
          'dayFechaAplazo': row['dayFechaAplazo'],
          'dayFechaLevantamiento': row['dayFechaLevantamiento'],
          'numAplazos': _asInt(row['numAplazos']),
          'idUsuarioResponsable': _asInt(row['idUsuarioResponsable']),
          'desResponsable': row['desResponsable'],
          'codEstado': _normalizeStoredStatus(_asString(row['codEstado']) ?? 'pending'),
          'desEstado': row['desEstado'],
          'codGrupoAcuerdo': _asInt(row['codGrupoAcuerdo']),
          'desGrupoAcuerdo': row['desGrupoAcuerdo'],
          'desColorGrupoAcuerdo': row['desColorGrupoAcuerdo'],
          'is_overdue': _asBoolInt(row['is_overdue']),
          'is_pending': _asBoolInt(row['is_pending']),
          'is_completed': _asBoolInt(row['is_completed']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyComments(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codComentario']);
      if (id == null) continue;
      final agreementId = _asInt(row['codActReuAcuerdos']);
      if (agreementId != null && !await _agreementExists(txn, agreementId)) {
        debugPrint('[AppRepository] skipping comment $id because agreement $agreementId is missing locally');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('meetings_comment', where: 'codComentario = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'meetings_comment',
        {
          'codComentario': id,
          'codActReuAcuerdos': _asInt(row['codActReuAcuerdos']),
          'codComentarioPadre': _asInt(row['codComentarioPadre']),
          'idUsuario': _asInt(row['idUsuario']),
          'desMensaje': row['desMensaje'],
          'dayFechaComentario': row['dayFechaComentario'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneTypes(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    if (rows.isNotEmpty) {
      final validIds = rows.map((row) => _asInt(row['codTipoHito'])).whereType<int>().toList();
      if (validIds.isEmpty) {
        await txn.delete('conhit_tipohito');
      } else {
        final placeholders = List.filled(validIds.length, '?').join(', ');
        await txn.delete('conhit_tipohito', where: 'codTipoHito NOT IN ($placeholders)', whereArgs: validIds);
      }
    }
    for (final row in rows) {
      final id = _asInt(row['codTipoHito']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('conhit_tipohito', where: 'codTipoHito = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_tipohito',
        {
          'codTipoHito': id,
          'desTipoHito': row['desTipoHito'] ?? 'Hito',
          'orden': _asInt(row['orden']),
          'codEstado': _asInt(row['codEstado']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneClassifications(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    if (rows.isNotEmpty) {
      final validIds = rows.map((row) => _asInt(row['codTipoClasificacion'])).whereType<int>().toList();
      if (validIds.isEmpty) {
        await txn.delete('conhit_tipoclasificacion');
      } else {
        final placeholders = List.filled(validIds.length, '?').join(', ');
        await txn.delete('conhit_tipoclasificacion', where: 'codTipoClasificacion NOT IN ($placeholders)', whereArgs: validIds);
      }
    }
    for (final row in rows) {
      final id = _asInt(row['codTipoClasificacion']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('conhit_tipoclasificacion', where: 'codTipoClasificacion = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_tipoclasificacion',
        {
          'codTipoClasificacion': id,
          'desTipoClasificacion': row['desTipoClasificacion'] ?? 'General',
          'orden': _asInt(row['orden']),
          'codEstado': _asInt(row['codEstado']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneInternalStatuses(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asString(row['codEstado']);
      if (id == null || id.isEmpty) continue;
      if (_isDeleted(row)) {
        await txn.delete('conhit_statusinterno', where: 'codEstado = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_statusinterno',
        {
          'codEstado': id,
          'desEstado': row['desEstado'] ?? '',
          'desColor': row['desColor'],
          'desIcono': row['desIcono'],
          'orden': _asInt(row['orden']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneContractualStatuses(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asString(row['codEstado']);
      if (id == null || id.isEmpty) continue;
      if (_isDeleted(row)) {
        await txn.delete('conhit_statuscontractual', where: 'codEstado = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_statuscontractual',
        {
          'codEstado': id,
          'desEstado': row['desEstado'] ?? '',
          'desColor': row['desColor'],
          'desIcono': row['desIcono'],
          'orden': _asInt(row['orden']),
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneControls(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codConHit']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping milestone control $id because project $projectId is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'milestone_control', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'milestone_control', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('conhit_controlhitos', where: 'codConHit = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_controlhitos',
        {
          'codConHit': id,
          'codEstado': _asInt(row['codEstado']),
          'dayFechaCreacion': row['dayFechaCreacion'],
          'desUsuarioCreacion': row['desUsuarioCreacion'],
          'dayFechaModificacion': row['dayFechaModificacion'],
          'desUsuarioModificacion': row['desUsuarioModificacion'],
          'codProyecto': projectId,
          'sync_status': 'synced',
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneGenerals(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codConHitGeneral']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final controlId = await _resolveMilestoneControlId(
        txn,
        requestedControlId: _asInt(row['codConHit']),
        projectId: projectId,
      );
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping milestone general $id because project $projectId is missing locally');
        continue;
      }
      if (controlId == null) {
        debugPrint('[AppRepository] skipping milestone general $id because project $projectId has no control locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'milestone_general', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'milestone_general', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('conhit_general', where: 'codConHitGeneral = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_general',
        {
          'codConHitGeneral': id,
          'codConHit': controlId,
          'codProyecto': projectId,
          'dayFechaCreacion': row['dayFechaCreacion'],
          'desUsuarioCreacion': row['desUsuarioCreacion'],
          'dayFechaModificacion': row['dayFechaModificacion'],
          'desUsuarioModificacion': row['desUsuarioModificacion'],
          'numDiasPlazoTotal': _asInt(row['numDiasPlazoTotal']),
          'mntTotal': _asDouble(row['mntTotal']),
          'numDias': _asInt(row['numDias']),
          'codEstado': _asInt(row['codEstado']),
          'dayFechaInicioContractual': row['dayFechaInicioContractual'],
          'sync_status': 'synced',
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestones(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codConHitDetalleHitos']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final controlId = await _resolveMilestoneControlId(
        txn,
        requestedControlId: _asInt(row['codConHit']),
        projectId: projectId,
      );
      final requestedGeneralId = _asInt(row['codConHitGeneral']);
      final generalId = await _resolveMilestoneGeneralId(
        txn,
        requestedGeneralId: requestedGeneralId,
        controlId: controlId,
        projectId: projectId,
      );
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping milestone $id because project $projectId is missing locally');
        continue;
      }
      if (controlId == null) {
        debugPrint('[AppRepository] skipping milestone $id because project $projectId has no control locally');
        continue;
      }
      if (generalId == null) {
        debugPrint(
          '[AppRepository] skipping milestone $id because project $projectId has no general locally '
          'for control $controlId (requestedGeneralId=$requestedGeneralId)',
        );
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'milestone', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'milestone', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('conhit_detallehitos', where: 'codConHitDetalleHitos = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_detallehitos',
        {
          'codConHitDetalleHitos': id,
          'codConHit': controlId,
          'codProyecto': projectId,
          'codConHitGeneral': generalId,
          'NumOrden': _asInt(row['NumOrden']),
          'desDescripcion': row['desDescripcion'],
          'codTipoHito': _asInt(row['codTipoHito']),
          'codTipoClasificacion': _asInt(row['codTipoClasificacion']),
          'numplazo': _asInt(row['numplazo']),
          'porPenalidad': _asDouble(row['porPenalidad']),
          'dayFechaContractual': row['dayFechaContractual'],
          'dayFechaMeta': row['dayFechaMeta'],
          'numCantAmpContractual': _asInt(row['numCantAmpContractual']),
          'numCantAmpMeta': _asInt(row['numCantAmpMeta']),
          'dayFechaReal': row['dayFechaReal'],
          'desLinkDocuCierre': row['desLinkDocuCierre'],
          'codEstadoContractual': _asInt(row['codEstadoContractual']),
          'codEstadoInternos': _asString(row['codEstadoInternos']),
          'mntPealidad': _asDouble(row['mntPealidad']),
          'dayFechaCreacion': row['dayFechaCreacion'],
          'desUsuarioCreacion': row['desUsuarioCreacion'],
          'dayFechaModificacion': row['dayFechaModificacion'],
          'desUsuarioModificacion': row['desUsuarioModificacion'],
          'dayFechaContractualAmp': row['dayFechaContractualAmp'],
          'dayFechaMetaAmp': row['dayFechaMetaAmp'],
          'sync_status': 'synced',
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneDocuments(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codConhitArchivosFechaReal'] ?? row['codConhitDocumentos']);
      if (id == null) continue;
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      if (milestoneId != null && !await _milestoneExists(txn, milestoneId)) {
        debugPrint('[AppRepository] skipping milestone document $id because milestone $milestoneId is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'milestone_document', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'milestone_document', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('conhit_archivosfechareal', where: 'codConhitArchivosFechaReal = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conhit_archivosfechareal',
        {
          'codConhitArchivosFechaReal': id,
          'codConHitDetalleHitos': milestoneId,
          'desNombreArchivo': row['desNombreArchivo'],
          'desRutaArchivo': row['desRutaArchivo'] ?? '',
          'dayFechaCreacion': row['dayFechaCreacion'],
          'desUsuarioCreacion': row['desUsuarioCreacion'],
          'dayFechaModificacion': row['dayFechaModificacion'],
          'desUsuarioModifcacion': row['desUsuarioModifcacion'] ?? row['desUsuarioModificacion'],
          'sync_status': 'synced',
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyMilestoneExtensions(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codConHitDetalleHitosAmp']);
      if (id == null) continue;
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      if (milestoneId != null && !await _milestoneExists(txn, milestoneId)) {
        debugPrint('[AppRepository] skipping milestone extension $id because milestone $milestoneId is missing locally');
        continue;
      }
      if (await _hasPendingQueueItem(txn, entityType: 'milestone_extension', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'milestone_extension', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('conthit_detallehitosamp', where: 'codConHitDetalleHitosAmp = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'conthit_detallehitosamp',
        {
          'codConHitDetalleHitosAmp': id,
          'codConHitDetalleHitos': milestoneId,
          'desMotivo': row['desMotivo'],
          'dayFechaMeta': row['dayFechaMeta'],
          'dayFechaContractual': row['dayFechaContractual'],
          'desLinklDocuAmp': row['desLinklDocuAmp'],
          'dayFechaCreacion': row['dayFechaCreacion'],
          'desUsuarioCreacion': row['desUsuarioCreacion'],
          'dayFechaModificacion': row['dayFechaModificacion'],
          'desUsuarioModificacion': row['desUsuarioModificacion'],
          'desTipoFecha': row['desTipoFecha'],
          'sync_status': 'synced',
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<bool> _hasPendingQueueItem(
    DatabaseExecutor txn, {
    required String entityType,
    required String entityId,
  }) async {
    final rows = await txn.query(
      'sync_queue',
      columns: ['id'],
      where: 'entity_type = ? AND entity_id = ? AND status IN (?, ?)',
      whereArgs: [entityType, entityId, 'pending', 'failed'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _projectExists(DatabaseExecutor txn, int projectId) async {
    final rows = await txn.query(
      'projects_project',
      columns: ['codProyecto'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _agreementExists(DatabaseExecutor txn, int agreementId) async {
    final rows = await txn.query(
      'meetings_agreement',
      columns: ['codActReuAcuerdos'],
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _restrictionModuleExists(DatabaseExecutor txn, int codAnaRes) async {
    final rows = await txn.query(
      'anares_analysis',
      columns: ['codAnaRes'],
      where: 'codAnaRes = ?',
      whereArgs: [codAnaRes],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _frontExists(DatabaseExecutor txn, int frontId) async {
    final rows = await txn.query(
      'anares_front',
      columns: ['codAnaResFrente'],
      where: 'codAnaResFrente = ?',
      whereArgs: [frontId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _phaseExists(DatabaseExecutor txn, int phaseId) async {
    final rows = await txn.query(
      'anares_phase',
      columns: ['codAnaResFase'],
      where: 'codAnaResFase = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int?> _loadActiveRestrictionModuleId(Database db, int projectId) async {
    final rows = await db.query(
      'anares_analysis',
      columns: ['codAnaRes'],
      where: 'codProyecto = ? AND IFNULL(codEstado, 0) = 0',
      whereArgs: [projectId],
      orderBy: 'codAnaRes DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _asInt(rows.first['codAnaRes']);
  }

  Future<bool> _milestoneControlExists(DatabaseExecutor txn, int controlId) async {
    final rows = await txn.query(
      'conhit_controlhitos',
      columns: ['codConHit'],
      where: 'codConHit = ?',
      whereArgs: [controlId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _milestoneGeneralExists(DatabaseExecutor txn, int generalId) async {
    final rows = await txn.query(
      'conhit_general',
      columns: ['codConHitGeneral'],
      where: 'codConHitGeneral = ?',
      whereArgs: [generalId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _milestoneExists(DatabaseExecutor txn, int milestoneId) async {
    final rows = await txn.query(
      'conhit_detallehitos',
      columns: ['codConHitDetalleHitos'],
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int?> _resolveMilestoneGeneralId(
    DatabaseExecutor txn, {
    required int? requestedGeneralId,
    required int? controlId,
    required int? projectId,
  }) async {
    if (requestedGeneralId != null && await _milestoneGeneralExists(txn, requestedGeneralId)) {
      return requestedGeneralId;
    }
    if (projectId == null || controlId == null) {
      return requestedGeneralId;
    }
    final rows = await txn.query(
      'conhit_general',
      columns: ['codConHitGeneral'],
      where: 'codConHit = ? AND codProyecto = ?',
      whereArgs: [controlId, projectId],
      orderBy: 'codConHitGeneral DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return requestedGeneralId;
    }
    return _asInt(rows.first['codConHitGeneral']);
  }

  Future<int?> _resolveMilestoneControlId(
    DatabaseExecutor txn, {
    required int? requestedControlId,
    required int? projectId,
  }) async {
    if (requestedControlId != null && await _milestoneControlExists(txn, requestedControlId)) {
      return requestedControlId;
    }
    if (projectId == null) {
      return requestedControlId;
    }

    final rows = await txn.query(
      'conhit_controlhitos',
      columns: ['codConHit'],
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codConHit DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return requestedControlId;
    }
    return _asInt(rows.first['codConHit']);
  }

  Future<void> _writeConflictLog(
    DatabaseExecutor txn, {
    required String entityType,
    required String entityId,
    required String message,
  }) async {
    await txn.insert('sync_log', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': 'pull_conflict',
      'result': 'skipped',
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, item) => MapEntry('$key', item));
    return const {};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((row) => row.map((key, item) => MapEntry('$key', item))).toList();
  }

  bool _isDeleted(Map<String, dynamic> row) {
    final value = row['deleted'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final text = '$value';
    return text.isEmpty ? null : text;
  }

  int _asBoolInt(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value == 0 ? 0 : 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return 1;
      if (normalized == 'false' || normalized == '0') return 0;
    }
    return 0;
  }

  Map<String, Object?> _statusFlagsFromCatalogRow(Map<String, Object?> row) {
    final controlOrder = _asInt(row['codElementoControl']);
    final statusLabel = _asString(row['desEstado']) ?? '';
    if (controlOrder != null) {
      switch (controlOrder) {
        case 3:
          return _statusFlagsFromKind('completed');
        case 2:
          return _statusFlagsFromKind('in_progress');
        default:
          return _statusFlagsFromKind('pending');
      }
    }
    return _statusFlagsFromStatusCode(_asString(row['codEstado']) ?? '', statusLabel: statusLabel);
  }

  Map<String, Object?> _statusFlagsFromStatusCode(String statusCode, {String statusLabel = ''}) {
    return _statusFlagsFromKind(_restrictionStatusKind(statusCode, statusLabel: statusLabel));
  }

  Map<String, Object?> _statusFlagsFromKind(String statusKind) {
    return {
      'is_completed': statusKind == 'completed' ? 1 : 0,
      'is_overdue': 0,
      'is_due_today': 0,
      'is_pending': statusKind == 'pending' ? 1 : 0,
      'is_in_progress': statusKind == 'in_progress' ? 1 : 0,
    };
  }

  int _priorityOrder(String statusCode) {
    switch (statusCode) {
      case 'in_progress':
        return 2;
      case 'pending':
        return 3;
      case 'completed':
        return 5;
      default:
        return 9;
    }
  }

  String _restrictionStatusKind(String statusCode, {String statusLabel = ''}) {
    switch (statusCode) {
      case '1':
      case 'pending':
        return 'pending';
      case '2':
      case 'in_progress':
        return 'in_progress';
      case '3':
      case 'completed':
        return 'completed';
    }

    final normalizedLabel = statusLabel.trim().toLowerCase();
    if (normalizedLabel.contains('complet')) return 'completed';
    if (normalizedLabel.contains('proceso') || normalizedLabel.contains('progress')) return 'in_progress';
    return 'pending';
  }

  String _normalizeStoredStatus(String statusCode) {
    switch (statusCode) {
      case '1':
        return 'pending';
      case '2':
        return 'in_progress';
      case '3':
        return 'completed';
      case 'overdue':
        return 'pending';
      default:
        return statusCode;
    }
  }

  String _agreementStatusLabel(String statusCode, {required bool isOverdue}) {
    if (statusCode == 'completed') return 'Completado';
    if (isOverdue) return 'Vencido';
    return 'Pendiente';
  }

  String _milestoneTypeLabel(int? code) {
    return '';
  }

  String _milestoneClassificationLabel(int? code) {
    return '';
  }

  bool _isPastDate(DateTime value) {
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final target = DateTime(value.year, value.month, value.day);
    return current.isAfter(target);
  }

  bool _isToday(DateTime value) {
    final today = DateTime.now();
    return value.year == today.year && value.month == today.month && value.day == today.day;
  }

  DateTime? _parseDateOnly(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day, 12);
    }

    final parsed = _parseDate(value.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day, 12);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _currentBusinessDateKey({DateTime? now}) {
    final current = now ?? DateTime.now();
    final anchor = current.hour >= 6 ? current : current.subtract(const Duration(days: 1));
    final month = anchor.month.toString().padLeft(2, '0');
    final day = anchor.day.toString().padLeft(2, '0');
    return '${anchor.year}-$month-$day';
  }

  String _capitalizeWords(String value) {
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _ResolvedRestrictionArea {
  const _ResolvedRestrictionArea({
    required this.codAnaresArea,
    required this.isLocal,
  });

  final int codAnaresArea;
  final bool isLocal;
}

class _MilestoneDerivedData {
  const _MilestoneDerivedData({
    required this.contractualStatusCode,
    required this.internalStatusCode,
    required this.penaltyAmount,
  });

  final int? contractualStatusCode;
  final int? internalStatusCode;
  final double penaltyAmount;
}

class _MilestoneScope {
  const _MilestoneScope({
    required this.controlId,
    required this.generalId,
  });

  final int controlId;
  final int generalId;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}




