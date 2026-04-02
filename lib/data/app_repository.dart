import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

import '../app/insights/insight_rules.dart';
import '../app/sync/sync_rules.dart';
import 'local/app_database.dart';
import 'models/app_models.dart';
import 'remote/auth_api_client.dart';
import 'remote/sync_api_client.dart';

part 'app_repository_insights.dart';
part 'app_repository_actreu_ops.dart';
part 'app_repository_sync.dart';
part 'app_repository_utils.dart';
part 'app_repository_actreu_read.dart';
part 'app_repository_apply.dart';

class AppRepository {
  AppRepository({
    AppDatabase? database,
    SyncApiClient? syncApiClient,
    AuthApiClient? authApiClient,
  }) : _database = database ?? AppDatabase.instance,
       _syncApiClient = syncApiClient ?? SyncApiClient(),
       _authApiClient = authApiClient ?? AuthApiClient();

  final AppDatabase _database;
  final SyncApiClient _syncApiClient;
  final AuthApiClient _authApiClient;

  static const String _locationPermissionRequestedKey =
      'location_permission_requested';
  static const String _locationPermissionStatusKey =
      'location_permission_status';
  static const String _locationPermissionRequestedAtKey =
      'location_permission_requested_at';
  static const String _deviceLinkedKey = 'device_linked';
  static const String _deviceBindingIdKey = 'device_binding_id';
  static const String _deviceBindingLabelKey = 'device_binding_label';
  static const String _deviceBindingLinkedAtKey = 'device_binding_linked_at';
  static const bool _traceActreuGroupResolution = true;

  Future<AppBootstrapData> bootstrap() async {
    final db = await _database.database;
    await _refreshDerivedState(db);

    final session = await _loadSession(db);
    final preferences = await _loadPreferences(db);
    final user = session == null ? null : await _loadUser(db, session.userId);
    final projects = await _loadProjects(db);
    final currentProjectId =
        preferences.currentProjectId ??
        (projects.isEmpty ? null : projects.first.id);
    final currentProject = projects
        .where((project) => project.id == currentProjectId)
        .firstOrNull;
    final snapshot = currentProject == null
        ? null
        : await _loadProjectSnapshot(db, currentProject.id);
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
      lastError: syncQueue
          .where(
            (item) =>
                item.errorMessage != null && item.errorMessage!.isNotEmpty,
          )
          .map((item) => item.errorMessage!)
          .lastOrNull,
    );

    debugPrint(
      '[AppRepository] bootstrap session=${session?.userId} currentProject=$currentProjectId '
      'projects=${projects.length} restrictions=${snapshot?.restrictions.length ?? 0} '
      'completed=${snapshot?.completedRestrictions.length ?? 0} '
      'milestones=${snapshot?.milestones.length ?? 0}',
    );

    final indicatorPrefs = session == null
        ? const <HubIndicatorPref>[]
        : await loadIndicatorPrefs(session.userId);

    return AppBootstrapData(
      session: session,
      user: user,
      projects: projects,
      currentProject: currentProject,
      snapshot: snapshot,
      preferences: preferences,
      syncQueue: syncQueue,
      syncOverview: syncOverview,
      indicatorPrefs: indicatorPrefs,
    );
  }

  Future<List<HubIndicatorPref>> loadIndicatorPrefs(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'hub_indicator_prefs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sort_order ASC',
    );
    return rows
        .map(
          (row) => HubIndicatorPref(
            key: (row['indicator_key'] as String?) ?? '',
            userId: (row['user_id'] as int?) ?? userId,
            isEnabled: ((row['is_enabled'] as int?) ?? 1) == 1,
            displayType: (row['display_type'] as String?) ?? 'card',
            customParam: row['custom_param'] as String?,
            sortOrder: (row['sort_order'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<void> saveIndicatorPref(HubIndicatorPref pref) async {
    final db = await _database.database;
    await db.insert('hub_indicator_prefs', {
      'indicator_key': pref.key,
      'user_id': pref.userId,
      'is_enabled': pref.isEnabled ? 1 : 0,
      'display_type': pref.displayType,
      'custom_param': pref.customParam,
      'sort_order': pref.sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppBootstrapData> login({
    required String userOrEmail,
    required String password,
    required bool keepSignedIn,
  }) async {
    var db = await _database.database;
    final preferences = await _loadPreferences(db);
    final canTryRemoteLogin =
        _authApiClient.isConfigured && !preferences.isOfflineMode;
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
        debugPrintStack(
          stackTrace: stackTrace,
          label: '[AppRepository] remote login stack',
        );
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

  Future<AppBootstrapData> updateRestrictionStatus({
    required int restrictionId,
    required String statusCode,
  }) async {
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
    final front = catalogs.fronts.firstWhere(
      (item) => item.id == draft.frontId,
    );
    final phase = catalogs.phases.firstWhere(
      (item) => item.id == draft.phaseId && item.parentId == draft.frontId,
    );
    final type = catalogs.types.firstWhere((item) => item.id == draft.typeId);
    final responsible = catalogs.responsibles.firstWhere(
      (item) => item.id == draft.responsibleId,
    );
    final status = catalogs.statuses.firstWhere(
      (item) => item.id == draft.statusCode,
    );
    final statusRow = await db.query(
      'anares_status',
      where: 'codEstado = ?',
      whereArgs: [draft.statusCode],
      limit: 1,
    );
    final flags = statusRow.isNotEmpty
        ? _statusFlagsFromCatalogRow(statusRow.first)
        : _statusFlagsFromStatusCode(
            draft.statusCode,
            statusLabel: status.label,
          );
    final areaSelection = catalogs.areas.firstWhere(
      (item) => item.id == draft.areaCode,
    );
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
      throw Exception(
        'No se encontro el frente seleccionado para crear la fase.',
      );
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

  Future<AppBootstrapData> saveMilestone(MilestoneDraft draft) async {
    final db = await _database.database;
    final currentProjectId = await _loadCurrentProjectId(db) ?? 101;
    final now = DateTime.now().toIso8601String();
    final scope = await _ensureMilestoneScope(db, currentProjectId, now);

    if (draft.id == null) {
      final nextId = await _nextMilestoneId(db);
      final currentCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM conhit_detallehitos WHERE codProyecto = ?',
              [currentProjectId],
            ),
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
        'dayFechaReal': draft.actualDate == null
            ? null
            : _formatDate(draft.actualDate!),
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
          'dayFechaReal': draft.actualDate == null
              ? null
              : _formatDate(draft.actualDate!),
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

  Future<AppBootstrapData> saveMilestoneGeneral(
    MilestoneGeneralDraft draft,
  ) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    final scope = await _ensureMilestoneScope(db, draft.projectId, now);
    final generalId = draft.generalId == 0 ? scope.generalId : draft.generalId;
    final controlId = draft.controlId == 0 ? scope.controlId : draft.controlId;
    final startDate = draft.startDate == null
        ? null
        : _formatDate(draft.startDate!);

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

  Future<AppBootstrapData> saveMilestoneExtension(
    MilestoneExtensionDraft draft,
  ) async {
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
      'dayFechaMeta': draft.newTargetDate == null
          ? null
          : _formatDate(draft.newTargetDate!),
      'dayFechaContractual': draft.newContractualDate == null
          ? null
          : _formatDate(draft.newContractualDate!),
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
      final normalizedName = _extractFileName(
        normalizedPath,
        fallback: 'Documento $createdDocumentId',
      );
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
        'dayFechaContractualAmp': draft.newContractualDate == null
            ? null
            : _formatDate(draft.newContractualDate!),
        'dayFechaMetaAmp': draft.newTargetDate == null
            ? null
            : _formatDate(draft.newTargetDate!),
        'numCantAmpContractual':
            (row['numCantAmpContractual'] as int? ?? 0) +
            (draft.newContractualDate == null ? 0 : 1),
        'numCantAmpMeta':
            (row['numCantAmpMeta'] as int? ?? 0) +
            (draft.newTargetDate == null ? 0 : 1),
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
      payload: await _buildMilestoneExtensionSyncPayload(
        db,
        nextId,
        previousTargetDate: previousTargetDate,
      ),
    );
    if (createdDocumentId != null) {
      await _enqueueSync(
        db,
        entityType: 'milestone_document',
        entityId: '$createdDocumentId',
        operationType: 'create',
        payload: await _buildMilestoneDocumentSyncPayload(
          db,
          createdDocumentId,
        ),
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

  Future<AppBootstrapData> saveMilestoneDocument(
    MilestoneDocumentDraft draft,
  ) async {
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
    final normalizedName = draft.name.trim().isEmpty
        ? 'Documento $documentId'
        : draft.name.trim();
    final normalizedPath = draft.path.trim().isEmpty
        ? 'local://documentos/$documentId'
        : draft.path.trim();

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

    final payload = Map<String, Object?>.from(rows.first)
      ..remove('sync_status');
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

    final projectId = milestoneRows.isEmpty
        ? null
        : milestoneRows.first['codProyecto'] as int;
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
    await _normalizeActreuAgreementStatusesForSync(db);

    final queue = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
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
    await _normalizeActreuAgreementStatusesForSync(db);
    final session = await _loadSession(db);
    if (session == null || !session.isActive) {
      throw Exception(
        'No hay una sesion activa para sincronizacion operativa.',
      );
    }

    final userId = session.userId;
    final user = await _loadUser(db, userId);
    final queueBeforePull = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
    if (queueBeforePull.isNotEmpty) {
      await _pushQueue(
        db,
        queue: queueBeforePull,
        userId: userId,
        authToken: session.token,
        companyId: await _resolvePushCompanyId(db, fallback: user?.company),
      );
    }

    await _pullRemoteData(
      db,
      userId: userId,
      scope: 'operational',
      businessDate: _currentBusinessDateKey(),
      since: preferences.lastSyncAt?.toIso8601String(),
      authToken: session.token,
      companyId: await _resolvePullCompanyId(db, fallback: user?.company),
    );
    await _normalizeActreuAgreementStatusesForSync(db);
    final queueAfterPull = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
    if (queueAfterPull.isNotEmpty) {
      await _pushQueue(
        db,
        queue: queueAfterPull,
        userId: userId,
        authToken: session.token,
        companyId: await _resolvePushCompanyId(db, fallback: user?.company),
      );
    }

    return bootstrap();
  }

  Future<AppBootstrapData> syncFullData({
    bool markDailyFullSync = false,
  }) async {
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    await _normalizeActreuAgreementStatusesForSync(db);
    final queue = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
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
    await _normalizeActreuAgreementStatusesForSync(db);
    await _recalculateModuleInsights(db);
    final queueAfterPull = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
    if (queueAfterPull.isNotEmpty) {
      await _pushQueue(
        db,
        queue: queueAfterPull,
        userId: userId,
        authToken: session.token,
        companyId: await _resolvePushCompanyId(db, fallback: user?.company),
      );
    }

    return bootstrap();
  }

  Future<UserSession?> _loadSession(Database db) async {
    final rows = await db.query(
      'auth_session',
      where: 'is_active = 1',
      orderBy: 'id DESC',
      limit: 1,
    );
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
    final rows = await db.query(
      'auth_user',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
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
      hubStyle: row['hub_style'] as String?,
    );
  }

  Future<void> saveHubStyle(int userId, String? style) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'auth_user',
      {'hub_style': style},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<ProjectRecord>> _loadProjects(Database db) async {
    final rows = await db.query(
      'projects_project',
      orderBy: 'is_last_selected DESC, codProyecto ASC',
    );
    return rows
        .map(
          (row) => ProjectRecord(
            id: row['codProyecto'] as int,
            name: (row['desNombreProyecto'] as String?) ?? '',
            company:
                (row['desEmpresa'] as String?) ??
                (row['des_Empresa'] as String?) ??
                '',
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
      deviceLinkedAt: _parseDateTime(
        await _loadSetting(db, _deviceBindingLinkedAtKey),
      ),
      currentProjectId: currentProjectId,
      lastSyncAt: lastSyncAt,
      lastDailyFullSyncBusinessDate: await _loadSetting(
        db,
        'last_daily_full_sync_business_date',
      ),
    );
  }

  Future<DeviceBindingState> getDeviceBindingState() async {
    final db = await _database.database;
    final linked = await _loadSetting(db, _deviceLinkedKey);
    final id = await _loadSetting(db, _deviceBindingIdKey);
    final label = await _loadSetting(db, _deviceBindingLabelKey);
    final linkedAt = _parseDateTime(
      await _loadSetting(db, _deviceBindingLinkedAtKey),
    );
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
    final deviceId = (existingId != null && existingId.isNotEmpty)
        ? existingId
        : _generateDeviceBindingId(userId: userId);
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
      'nonce': _buildQrNonce(
        userId: userId,
        deviceId: state.deviceId!,
        issuedAt: now,
      ),
    });
  }

  Future<List<SyncQueueRecord>> _loadSyncQueue(Database db) async {
    final rows = await db.query(
      'sync_queue',
      orderBy: 'status ASC, created_at DESC',
    );
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
        await db.rawQuery('SELECT 1 FROM sync_queue WHERE id = ? LIMIT 1', [
          candidate,
        ]),
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
        await db.rawQuery(
          'SELECT 1 FROM anares_restriction WHERE codAnaResActividad = ? LIMIT 1',
          [candidate],
        ),
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
        await db.rawQuery(
          'SELECT 1 FROM anares_front WHERE codAnaResFrente = ? LIMIT 1',
          [candidate],
        ),
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
        await db.rawQuery(
          'SELECT 1 FROM anares_phase WHERE codAnaResFase = ? LIMIT 1',
          [candidate],
        ),
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
        await db.rawQuery(
          'SELECT 1 FROM conhit_controlhitos WHERE codConHit = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneGeneralId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM conhit_general WHERE codConHitGeneral = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM conhit_detallehitos WHERE codConHitDetalleHitos = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextMilestoneExtensionId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM conthit_detallehitosamp WHERE codConHitDetalleHitosAmp = ? LIMIT 1',
          [candidate],
        ),
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

  Future<int> _nextActreuSessionId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_reuniones WHERE codActReuReuniones = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuActaId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_actareuniones WHERE codActReu = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuCategoryId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_categoria WHERE codActReuCategoria = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuSubcategoryId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_subcategoria WHERE codActReuSubCategoria = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuParticipantId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_participantes WHERE codActReuParticipante = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuAttendanceId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_asistencias WHERE codActReuAsistencia = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuAgreementId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_acuerdos WHERE codActReuAcuerdos = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuAgreementPhotoId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_acuerdosfoto WHERE codActReuAcuerdosFoto = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuGroupId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_grupoacuerdo WHERE codActReuGrupoAcuerdo = ? LIMIT 1',
          [candidate],
        ),
      );
      if (existing == null) return candidate;
      candidate++;
    }
  }

  Future<int> _nextActreuCommentId(Database db) async {
    var candidate = DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final existing = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT 1 FROM actreu_comentarios_acuerdo WHERE codComentario = ? LIMIT 1',
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
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
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
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> ensureLocationConsentRequested() async {
    final db = await _database.database;
    final alreadyRequested = await _loadSetting(
      db,
      _locationPermissionRequestedKey,
    );
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
    final suffix = List.generate(
      6,
      (_) => random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();
    final userPart = userId?.toString() ?? 'anon';
    return 'DIR-$userPart-${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  String _buildDeviceBindingLabel({
    required int? userId,
    required String deviceId,
  }) {
    final shortId = deviceId.length <= 8
        ? deviceId
        : deviceId.substring(deviceId.length - 8);
    return 'Dispositivo ${userId ?? '-'} Ãƒâ€šÃ‚Â· $shortId';
  }

  String _buildQrNonce({
    required int? userId,
    required String deviceId,
    required DateTime issuedAt,
  }) {
    final random = Random.secure();
    final salt = List.generate(
      4,
      (_) => random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();
    return '${userId ?? '0'}-${issuedAt.millisecondsSinceEpoch}-${deviceId.hashCode.abs()}-$salt';
  }

  Future<_MilestoneScope> _ensureMilestoneScope(
    Database db,
    int projectId,
    String nowIso,
  ) async {
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
      final isLocal =
          rows.isNotEmpty &&
          (rows.first['is_codAnaresAreaLocal'] as int? ?? 0) == 1;
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
      'cod_Empresa': companyRows.isEmpty
          ? null
          : _asInt(companyRows.first['codEmpresa']),
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
    throw Exception(
      'El proyecto no tiene un analisis de restricciones activo. Sincroniza primero el proyecto.',
    );
  }

  Future<Map<String, Object?>> _buildRestrictionSyncPayload(
    Database db,
    int restrictionId,
  ) async {
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

  Future<Map<String, Object?>> _buildRestrictionFrontSyncPayload(
    Database db,
    int frontId,
  ) async {
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

  Future<Map<String, Object?>> _buildRestrictionPhaseSyncPayload(
    Database db,
    int phaseId,
  ) async {
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

  Future<Map<String, Object?>> _buildAnalysisAreaSyncPayload(
    Database db,
    int analysisAreaId,
  ) async {
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

  Future<Map<String, Object?>> _buildMilestoneSyncPayload(
    Database db,
    int milestoneId,
  ) async {
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

  Future<Map<String, Object?>> _buildMilestoneDocumentSyncPayload(
    Database db,
    int documentId,
  ) async {
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

  Future<Map<String, Object?>> _buildActreuActaSyncPayload(
    Database db,
    int actaId,
  ) async {
    final rows = await db.query(
      'actreu_actareuniones',
      where: 'codActReu = ?',
      whereArgs: [actaId],
      limit: 1,
    );
    if (rows.isEmpty) return {'codActReu': actaId};
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuCategoriaSyncPayload(
    Database db,
    int categoryId,
  ) async {
    final rows = await db.query(
      'actreu_categoria',
      where: 'codActReuCategoria = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return {'codActReuCategoria': categoryId};
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuSubcategoriaSyncPayload(
    Database db,
    int subcategoryId,
  ) async {
    final rows = await db.query(
      'actreu_subcategoria',
      where: 'codActReuSubCategoria = ?',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    if (rows.isEmpty) return {'codActReuSubCategoria': subcategoryId};
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuIntegranteSyncPayload(
    Database db, {
    required int projectId,
    required int actaId,
    required int memberId,
  }) async {
    final rows = await db.query(
      'actreu_integrantes',
      where: 'codProyecto = ? AND codActReu = ? AND codProyIntegrante = ?',
      whereArgs: [projectId, actaId, memberId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {
        'codProyecto': projectId,
        'codActReu': actaId,
        'codProyIntegrante': memberId,
      };
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuSessionSyncPayload(
    Database db,
    int sessionId,
  ) async {
    final rows = await db.query(
      'actreu_reuniones',
      where: 'codActReuReuniones = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActReuReuniones': sessionId};
    }

    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuSessionDeleteSyncPayload(
    Database db,
    int sessionId,
  ) async {
    final rows = await db.query(
      'actreu_reuniones',
      columns: ['codActReuReuniones', 'codActReuSubCategoria'],
      where: 'codActReuReuniones = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActReuReuniones': sessionId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuParticipantSyncPayload(
    Database db,
    int participantId,
  ) async {
    final rows = await db.query(
      'actreu_participantes',
      where: 'codActReuParticipante = ?',
      whereArgs: [participantId],
      limit: 1,
    );
    if (rows.isEmpty) return {'codActReuParticipante': participantId};
    final row = Map<String, Object?>.from(rows.first);
    // Para create/update de participantes no enviamos estos campos.
    row.remove('codProyecto');
    row.remove('codActReuCategoria');
    return row;
  }

  Future<Map<String, Object?>> _buildActreuParticipantDeleteSyncPayload(
    Database db,
    int participantId,
  ) async {
    final rows = await db.query(
      'actreu_participantes',
      columns: ['codActReuParticipante', 'codActReuSubCategoria'],
      where: 'codActReuParticipante = ?',
      whereArgs: [participantId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActReuParticipante': participantId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuAttendanceSyncPayload(
    Database db,
    int attendanceId,
  ) async {
    final rows = await db.query(
      'actreu_asistencias',
      where: 'codActReuAsistencia = ?',
      whereArgs: [attendanceId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActReuAsistencia': attendanceId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuCommentSyncPayload(
    Database db,
    int commentId,
  ) async {
    final rows = await db.query(
      'actreu_comentarios_acuerdo',
      where: 'codComentario = ?',
      whereArgs: [commentId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codComentario': commentId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuAgreementSyncPayload(
    Database db,
    int agreementId,
  ) async {
    final rows = await db.query(
      'actreu_acuerdos',
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActReuAcuerdos': agreementId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildActreuAgreementDeleteSyncPayload(
    Database db,
    int agreementId,
  ) async {
    final rows = await db.query(
      'actreu_acuerdos',
      columns: [
        'codActReuAcuerdos',
        'codActReuReuniones',
        'codActReuSubCategoria',
      ],
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActReuAcuerdos': agreementId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<int?> _loadCurrentUserId(Database db) async {
    final session = await _loadSession(db);
    return session?.userId;
  }

  Future<String> _resolveCurrentActorName(Database db) async {
    final session = await _loadSession(db);
    if (session == null) return 'mobile';
    final user = await _loadUser(db, session.userId);
    return user?.email ?? user?.name ?? 'mobile';
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
        'actreu_asistencias',
        'actreu_comentarios_acuerdo',
        'actreu_acuerdosfoto',
        'actreu_acuerdos',
        'actreu_grupoacuerdo',
        'actreu_participantes',
        'actreu_integrantes',
        'actreu_reuniones',
        'actreu_subcategoria',
        'actreu_categoria',
        'actreu_actareuniones',
        'actreu_summary',
        'actreu_status_acuerdos',
        'actreu_status_reuniones',
        'actreu_status_subcategoria',
        'actreu_status_categoria',
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
    final firstProjectId = remote.projects.isEmpty
        ? null
        : _asInt(remote.projects.first['codProyecto']);

    await db.transaction((txn) async {
      await txn.insert('auth_user', {
        'id': userId,
        'name': remote.user['name'],
        'lastname': remote.user['lastname'],
        'email': remote.user['email'],
        'password': password,
        'celular': remote.user['celular'],
        'nombreempresa': remote.user['companyId'],
        'codCargo': _asInt(remote.user['codCargo']),
        'updated_at': _asString(remote.user['updated_at']) ?? now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

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
    await _saveSetting(
      db,
      'session_company_id',
      remote.user['companyId']?.toString(),
    );
    if (firstProjectId != null) {
      await _saveSetting(db, 'current_project_id', '$firstProjectId');
    }
  }

  Future<ProjectSnapshot> _loadProjectSnapshot(
    Database db,
    int projectId,
  ) async {
    final catalogs = await _loadCatalogs(db, projectId);
    final activeRestrictionModuleId = await _loadActiveRestrictionModuleId(
      db,
      projectId,
    );
    final restrictionsRows = await db.query(
      'anares_restriction',
      where: activeRestrictionModuleId == null
          ? 'codProyecto = ? AND IFNULL(codEstadoActividad, \'\') != ?'
          : 'codProyecto = ? AND codAnaRes = ? AND IFNULL(codEstadoActividad, \'\') != ?',
      whereArgs: activeRestrictionModuleId == null
          ? [projectId, '99']
          : [projectId, activeRestrictionModuleId, '99'],
      orderBy: 'priority_order ASC, dayFechaRequerida ASC',
    );
    final restrictions = restrictionsRows
        .map((row) => _mapRestriction(row, catalogs.areas))
        .toList();
    final completed = restrictions.where((item) => item.isCompleted).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final summaryRows = await db.query(
      'anares_summary',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    final summary = summaryRows.isEmpty
        ? const RestrictionSummary(
            total: 0,
            completed: 0,
            overdue: 0,
            inProgress: 0,
            pending: 0,
            compliancePercent: 0,
          )
        : RestrictionSummary(
            total: summaryRows.first['totalRestrictions'] as int? ?? 0,
            completed: summaryRows.first['completedCount'] as int? ?? 0,
            overdue: summaryRows.first['overdueCount'] as int? ?? 0,
            inProgress: summaryRows.first['inProgressCount'] as int? ?? 0,
            pending: summaryRows.first['pendingCount'] as int? ?? 0,
            compliancePercent:
                (summaryRows.first['compliancePercent'] as num?)?.toDouble() ??
                0,
          );

    final milestoneControlRows = await db.query(
      'conhit_controlhitos',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codConHit DESC',
      limit: 1,
    );
    final milestoneControlId = milestoneControlRows.isEmpty
        ? null
        : _asInt(milestoneControlRows.first['codConHit']);
    final milestoneGeneralRows = milestoneControlId == null
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_general',
            where: 'codProyecto = ? AND codConHit = ?',
            whereArgs: [projectId, milestoneControlId],
            orderBy: 'codConHitGeneral DESC',
            limit: 1,
          );
    final milestoneGeneralId = milestoneGeneralRows.isEmpty
        ? null
        : _asInt(milestoneGeneralRows.first['codConHitGeneral']);
    final milestoneRows =
        (milestoneControlId == null || milestoneGeneralId == null)
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_detallehitos',
            where: 'codProyecto = ? AND codConHit = ? AND codConHitGeneral = ?',
            whereArgs: [projectId, milestoneControlId, milestoneGeneralId],
            orderBy: 'NumOrden ASC, codConHitDetalleHitos ASC',
          );
    final milestoneTypeRows = await db.query(
      'conhit_tipohito',
      orderBy: 'orden ASC, codTipoHito ASC',
    );
    final milestoneClassificationRows = await db.query(
      'conhit_tipoclasificacion',
      orderBy: 'orden ASC, codTipoClasificacion ASC',
    );
    final milestoneIds = milestoneRows
        .map((row) => _asInt(row['codConHitDetalleHitos']))
        .whereType<int>()
        .toSet();
    final extensionRows = await db.query(
      'conthit_detallehitosamp',
      orderBy: 'dayFechaCreacion ASC, codConHitDetalleHitosAmp ASC',
    );
    final fileRows = await db.query(
      'conhit_archivosfechareal',
      orderBy: 'dayFechaCreacion DESC, codConhitArchivosFechaReal DESC',
    );
    final milestoneTypeLabels = <int, String>{
      for (final row in milestoneTypeRows)
        if (_asInt(row['codTipoHito']) != null)
          _asInt(row['codTipoHito'])!: (row['desTipoHito'] as String?) ?? '',
    };
    final milestoneClassificationLabels = <int, String>{
      for (final row in milestoneClassificationRows)
        if (_asInt(row['codTipoClasificacion']) != null)
          _asInt(row['codTipoClasificacion'])!:
              (row['desTipoClasificacion'] as String?) ?? '',
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
            label: ((row['desTipoClasificacion'] as String?) ?? 'General')
                .trim(),
            order: _asInt(row['orden']),
          ),
        )
        .toList();
    final milestoneDocumentsById = <int, List<MilestoneDocumentRecord>>{};
    for (final row in fileRows) {
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      final documentId = _asInt(row['codConhitArchivosFechaReal']);
      if (milestoneId == null ||
          documentId == null ||
          !milestoneIds.contains(milestoneId))
        continue;
      milestoneDocumentsById
          .putIfAbsent(milestoneId, () => [])
          .add(
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
          _asInt(row['codConHitDetalleHitos'])!:
              _parseDate(row['dayFechaMeta'] as String?) ?? DateTime.now(),
    };
    for (final row in extensionRows) {
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      final extensionId = _asInt(row['codConHitDetalleHitosAmp']);
      if (milestoneId == null ||
          extensionId == null ||
          !milestoneIds.contains(milestoneId))
        continue;
      final previousTargetDate =
          previousTargetByMilestone[milestoneId] ?? DateTime.now();
      final newTargetDate =
          _parseDate(row['dayFechaMeta'] as String?) ?? previousTargetDate;
      milestoneExtensionsById
          .putIfAbsent(milestoneId, () => [])
          .add(
            MilestoneExtensionRecord(
              id: extensionId,
              milestoneId: milestoneId,
              justification: (row['desMotivo'] as String?) ?? '',
              previousTargetDate: previousTargetDate,
              newTargetDate: newTargetDate,
              newContractualDate: _parseDate(
                row['dayFechaContractual'] as String?,
              ),
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
            documents:
                milestoneDocumentsById[_asInt(row['codConHitDetalleHitos']) ??
                    -1] ??
                const [],
            extensions:
                milestoneExtensionsById[_asInt(row['codConHitDetalleHitos']) ??
                    -1] ??
                const [],
            typeLabel: milestoneTypeLabels[_asInt(row['codTipoHito'])],
            classificationLabel:
                milestoneClassificationLabels[_asInt(
                  row['codTipoClasificacion'],
                )],
          ),
        )
        .toList();
    final milestoneGeneral = milestoneGeneralRows.isEmpty
        ? null
        : _mapMilestoneGeneral(milestoneGeneralRows.first);
    final milestoneSummary = _buildMilestoneSummary(milestones);
    final restrictionInsights = await _loadModuleInsightsForProject(
      db,
      projectId: projectId,
      module: ModuleInsightModule.restrictions,
    );
    final actaReunionesInsights = await _loadModuleInsightsForProject(
      db,
      projectId: projectId,
      module: ModuleInsightModule.actaReuniones,
    );

    final actreuSummaryRows = await db.query(
      'actreu_summary',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    final actreuSummary = actreuSummaryRows.isEmpty
        ? null
        : ActreuSummaryRecord(
            projectId: projectId,
            totalSessions:
                (actreuSummaryRows.first['totalSessions'] as int?) ?? 0,
            scheduledSessions:
                (actreuSummaryRows.first['scheduledSessions'] as int?) ?? 0,
            activeSessions:
                (actreuSummaryRows.first['activeSessions'] as int?) ?? 0,
            overdueAgreements:
                (actreuSummaryRows.first['overdueAgreements'] as int?) ?? 0,
            pendingAgreements:
                (actreuSummaryRows.first['pendingAgreements'] as int?) ?? 0,
            informativeAgreements:
                (actreuSummaryRows.first['informativeAgreements'] as int?) ?? 0,
            categoriesCount:
                (actreuSummaryRows.first['categoriesCount'] as int?) ?? 0,
            subcategoriesCount:
                (actreuSummaryRows.first['subcategoriesCount'] as int?) ?? 0,
            compliancePercent:
                (actreuSummaryRows.first['compliancePercent'] as num?)
                    ?.toDouble() ??
                0,
            updatedAt: _parseDateTime(
              actreuSummaryRows.first['updated_at'] as String?,
            ),
          );

    debugPrint(
      '[AppRepository] snapshot project=$projectId '
      'catalogFronts=${catalogs.fronts.length} catalogPhases=${catalogs.phases.length} '
      'catalogAreas=${catalogs.areas.length} restrictions=${restrictions.length} '
      'milestones=${milestones.length}',
    );

    return ProjectSnapshot(
      summary: summary,
      restrictions: restrictions,
      completedRestrictions: completed,
      catalogs: catalogs,
      milestoneTypes: milestoneTypes,
      milestoneClassifications: milestoneClassifications,
      milestoneGeneral: milestoneGeneral,
      milestoneSummary: milestoneSummary,
      milestones: milestones,
      restrictionInsights: restrictionInsights,
      actaReunionesInsights: actaReunionesInsights,
      actreuSummary: actreuSummary,
    );
  }

  Future<AppBootstrapData> setModuleInsightResolved({
    required int projectId,
    required ModuleInsightModule module,
    required String insightKey,
    required bool resolved,
  }) async {
    return _setModuleInsightResolvedImpl(
      this,
      projectId: projectId,
      module: module,
      insightKey: insightKey,
      resolved: resolved,
    );
  }

  Future<List<ModuleInsightRecord>> _loadModuleInsightsForProject(
    Database db, {
    required int projectId,
    required ModuleInsightModule module,
  }) async {
    return _loadModuleInsightsForProjectImpl(
      this,
      db,
      projectId: projectId,
      module: module,
    );
  }

  Future<void> _recalculateModuleInsights(Database db) async {
    return _recalculateModuleInsightsImpl(this, db);
  }

  String _moduleInsightModuleToDb(ModuleInsightModule module) {
    switch (module) {
      case ModuleInsightModule.restrictions:
        return 'restrictions';
      case ModuleInsightModule.actaReuniones:
        return 'acta_reuniones';
    }
  }

  ModuleInsightModule _moduleInsightModuleFromDb(String value) {
    switch (value) {
      case 'acta_reuniones':
        return ModuleInsightModule.actaReuniones;
      case 'restrictions':
      default:
        return ModuleInsightModule.restrictions;
    }
  }

  String _moduleInsightSeverityToDb(ModuleInsightSeverity severity) {
    switch (severity) {
      case ModuleInsightSeverity.warning:
        return 'warning';
      case ModuleInsightSeverity.critical:
        return 'critical';
    }
  }

  ModuleInsightSeverity _moduleInsightSeverityFromDb(String value) {
    switch (value) {
      case 'critical':
        return ModuleInsightSeverity.critical;
      case 'warning':
      default:
        return ModuleInsightSeverity.warning;
    }
  }

  Future<RestrictionCatalogs> _loadCatalogs(Database db, int projectId) async {
    final activeRestrictionModuleId = await _loadActiveRestrictionModuleId(
      db,
      projectId,
    );
    final fronts = await db.query(
      'anares_front',
      where: activeRestrictionModuleId == null
          ? 'codProyecto = ?'
          : 'codProyecto = ? AND codAnaRes = ?',
      whereArgs: activeRestrictionModuleId == null
          ? [projectId]
          : [projectId, activeRestrictionModuleId],
      orderBy: 'codAnaResFrente ASC',
    );
    final phases = await db.query(
      'anares_phase',
      where: activeRestrictionModuleId == null
          ? 'codProyecto = ?'
          : 'codProyecto = ? AND codAnaRes = ?',
      whereArgs: activeRestrictionModuleId == null
          ? [projectId]
          : [projectId, activeRestrictionModuleId],
      orderBy: 'codAnaResFrente ASC, codAnaResFase ASC',
    );
    final projectAreas = await db.query(
      'anares_area',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'desArea COLLATE NOCASE ASC, codAnaresArea ASC',
    );
    final generalAreas = await db.query(
      'projects_area_member',
      orderBy: 'desArea COLLATE NOCASE ASC, codArea ASC',
    );
    final types = await db.query(
      'anares_type',
      orderBy: 'codTipoRestriccion ASC',
    );
    final responsibles = await db.query(
      'projects_member',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codProyIntegrante ASC',
    );
    final statuses = await db.query(
      'anares_status',
      orderBy: 'codElementoControl ASC, codEstado ASC',
    );
    final projectAreaCodes = projectAreas
        .map((row) => _asInt(row['codArea']))
        .whereType<int>()
        .toSet();
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
        types
            .map(
              (row) => CatalogOption(
                id: '${row['codTipoRestriccion']}',
                label: (row['desTipoRestriccion'] as String?) ?? '',
              ),
            )
            .toList(),
      ),
      responsibles: _distinctCatalogOptions(
        responsibles.map((row) {
          final email = row['desCorreo'] as String?;
          final rawName = email == null
              ? 'Integrante'
              : email.split('@').first.replaceAll('.', ' ');
          return CatalogOption(
            id: '${row['codProyIntegrante']}',
            label: _capitalizeWords(rawName),
          );
        }).toList(),
      ),
      statuses: _distinctCatalogOptions(
        statuses
            .map(
              (row) => CatalogOption(
                id: (row['codEstado'] as String?) ?? '',
                label: (row['desEstado'] as String?) ?? '',
                colorHex: row['iconColor'] as String?,
              ),
            )
            .toList(),
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

  int _parseAnalysisAreaOptionId(String value) =>
      int.parse(value.split(':').last);

  int _parseGeneralAreaOptionId(String value) =>
      int.parse(value.split(':').last);

  RestrictionRecord _mapRestriction(
    Map<String, Object?> row,
    List<CatalogOption> areas,
  ) {
    final areaCode = row['codAnaresArea']?.toString();
    final areaLabel = areas
        .firstWhere(
          (item) =>
              item.id ==
              _analysisAreaOptionId(int.tryParse(areaCode ?? '') ?? -1),
          orElse: () => const CatalogOption(id: '', label: ''),
        )
        .label;
    final requiredDate =
        _parseDate(row['dayFechaRequerida'] as String?) ?? DateTime.now();
    final conciliatedDate = _parseDate(row['dayFechaConciliada'] as String?);
    final rawStatusCode = (row['codEstadoActividad'] as String?) ?? '';
    final statusLabel = (row['desEstadoActividad'] as String?) ?? 'Pendiente';
    final statusKind = _restrictionStatusKind(
      rawStatusCode,
      statusLabel: statusLabel,
    );
    final derivedOverdue =
        statusKind != 'completed' && _isPastDate(requiredDate);
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
      priorityOrder: derivedOverdue
          ? 1
          : ((row['priority_order'] as int?) ?? _priorityOrder(statusKind)),
      syncStatus: (row['sync_status'] as String?) ?? 'synced',
      updatedAt:
          _parseDateTime(row['dayFechaModificacion'] as String?) ??
          DateTime.now(),
    );
  }

  MilestoneGeneralRecord _mapMilestoneGeneral(Map<String, Object?> row) {
    return MilestoneGeneralRecord(
      projectId: row['codProyecto'] as int,
      controlId: row['codConHit'] as int,
      generalId: row['codConHitGeneral'] as int,
      startDate: _parseDate(row['dayFechaInicioContractual'] as String?),
      totalDays:
          row['numDiasPlazoTotal'] as int? ?? row['numDias'] as int? ?? 0,
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
    final contractualDate =
        _parseDate(row['dayFechaContractual'] as String?) ?? DateTime.now();
    final targetDate =
        _parseDate(row['dayFechaMeta'] as String?) ?? contractualDate;
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
      typeLabel: (typeLabel == null || typeLabel.isEmpty)
          ? _milestoneTypeLabel(_asInt(row['codTipoHito']))
          : typeLabel,
      classificationCode: _asInt(row['codTipoClasificacion']),
      classificationLabel:
          (classificationLabel == null || classificationLabel.isEmpty)
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
      extendedContractualDate: _parseDate(
        row['dayFechaContractualAmp'] as String?,
      ),
      extendedTargetDate: _parseDate(row['dayFechaMetaAmp'] as String?),
      syncStatus: (row['sync_status'] as String?) ?? 'synced',
      documents: documents,
      extensions: extensions,
    );
  }

  MilestoneDashboardSummary _buildMilestoneSummary(
    List<MilestoneRecord> records,
  ) {
    final completed = records.where((item) => item.isCompleted).length;
    final inProgress = records.where((item) => item.isInProgress).length;
    final delayed = records.where((item) => item.isDelayed).length;
    final activeDelay = records
        .where((item) => item.delayDays > 0 && !item.isCompleted)
        .length;
    final compliance = records.isEmpty ? 0.0 : completed / records.length;
    final accumulatedPenalty = records
        .where((item) => item.isCompleted && item.delayDays > 0)
        .fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final potentialPenalty = records
        .where((item) => !item.isCompleted)
        .fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final activeExtensions = records.fold<int>(
      0,
      (sum, item) => sum + item.extensionCount,
    );

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

  Future<void> _recalculateMilestoneDerivedFields(
    Database db,
    int milestoneId,
  ) async {
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
    final totalAmount = generalRows.isEmpty
        ? 0.0
        : _asDouble(generalRows.first['mntTotal']);
    final derived = _calculateMilestoneDerivedData(
      row,
      totalAmount: totalAmount,
    );

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

  _MilestoneDerivedData _calculateMilestoneDerivedData(
    Map<String, Object?> row, {
    required double totalAmount,
  }) {
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
        contractualCounter = contractualDate
            .difference(referenceDate)
            .inDays
            .round();
        contractualStatusCode = realDate != null
            ? 3
            : (contractualCounter < 0 ? 2 : 1);
      }
    }

    int? internalCounter;
    int? internalStatusCode;
    if (targetDate != null) {
      final referenceDate = realDate ?? today;
      if (referenceDate != null) {
        internalCounter = targetDate.difference(referenceDate).inDays.round();
        internalStatusCode = realDate != null
            ? 3
            : (internalCounter < 0 ? 2 : 1);
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
      return;
    }

    final projectRows = await db.query(
      'projects_project',
      columns: ['codProyecto'],
    );
    for (final row in projectRows) {
      final currentProjectId = row['codProyecto'] as int;
      await _database.refreshProjectSummary(db, currentProjectId);
    }
  }

  Future<void> _refreshRestrictionDerivedFlags(
    Database db, {
    int? projectId,
  }) async {
    final rows = await db.query(
      'anares_restriction',
      columns: [
        'codAnaResActividad',
        'codEstadoActividad',
        'desEstadoActividad',
        'dayFechaRequerida',
      ],
      where: projectId == null
          ? "IFNULL(codEstadoActividad, '') != ?"
          : "codProyecto = ? AND IFNULL(codEstadoActividad, '') != ?",
      whereArgs: projectId == null ? ['99'] : [projectId, '99'],
    );
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final id = row['codAnaResActividad'] as int;
      final statusCode = (row['codEstadoActividad'] as String?) ?? '';
      final statusLabel = (row['desEstadoActividad'] as String?) ?? '';
      final statusKind = _restrictionStatusKind(
        statusCode,
        statusLabel: statusLabel,
      );
      final requiredDate = _parseDate(row['dayFechaRequerida'] as String?);
      final completed = statusKind == 'completed';
      final overdue =
          !completed && requiredDate != null && _isPastDate(requiredDate);
      final dueToday =
          !completed && requiredDate != null && _isToday(requiredDate);
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
  }

  Future<void> _enqueueSync(
    Database db, {
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, Object?> payload,
    int? isFromRemoteTable,
  }) async {
    final payloadWithFlags = Map<String, Object?>.from(payload);
    if (operationType == 'create') {
      payloadWithFlags['isNew'] = 1;
    }
    if (isFromRemoteTable != null) {
      payloadWithFlags['isFromRemoteTable'] = isFromRemoteTable;
    }
    final enrichedPayload = await _attachGeolocationMetadata(
      db,
      payloadWithFlags,
    );
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
      final currentOperation =
          (current['operation_type'] as String?) ?? operationType;
      if (currentOperation == 'create' && operationType == 'delete') {
        // create + delete antes de sincronizar => no-op (se elimina de cola).
        await db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [current['id']],
        );
        return;
      }
      final mergedOperation =
          currentOperation == 'create' && operationType != 'delete'
          ? 'create'
          : operationType;
      Map<String, Object?> mergedPayload = Map<String, Object?>.from(
        enrichedPayload,
      );
      if (mergedOperation == 'create') {
        final currentPayloadJson = current['payload_json'] as String? ?? '{}';
        final decodedCurrent = jsonDecode(currentPayloadJson);
        final currentPayload = decodedCurrent is Map<String, dynamic>
            ? Map<String, Object?>.from(decodedCurrent)
            : <String, Object?>{};
        mergedPayload = {...currentPayload, ...enrichedPayload};
        mergedPayload['isNew'] = 1;
      }
      await db.update(
        'sync_queue',
        {
          'operation_type': mergedOperation,
          'payload_json': jsonEncode(mergedPayload),
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

  Future<bool> _hasPendingCreateSyncEvent(
    Database db, {
    required String entityType,
    required String entityId,
  }) async {
    final existing = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT 1
        FROM sync_queue
        WHERE entity_type = ?
          AND entity_id = ?
          AND operation_type = 'create'
          AND status IN ('pending', 'failed')
        LIMIT 1
        ''',
        [entityType, entityId],
      ),
    );
    return existing != null;
  }

  Future<int> _resolveActreuLocalLineageFlag(
    Database db, {
    required String entityType,
    required String entityId,
    required String operationType,
    List<(String, String)> parentRefs = const [],
  }) async {
    // ConvenciÃƒÆ’Ã‚Â³n:
    // 1 => el registro tiene linaje local (naciÃƒÆ’Ã‚Â³/depende de algo aÃƒÆ’Ã‚Âºn no sincronizado).
    // 0 => linaje remoto (base ya existente en backend).
    if (operationType == 'create') {
      if (parentRefs.isEmpty) return 1;
      for (final (parentType, parentId) in parentRefs) {
        if (await _hasPendingCreateSyncEvent(
          db,
          entityType: parentType,
          entityId: parentId,
        )) {
          return 1;
        }
      }
      return 0;
    }

    if (await _hasPendingCreateSyncEvent(
      db,
      entityType: entityType,
      entityId: entityId,
    )) {
      return 1;
    }
    for (final (parentType, parentId) in parentRefs) {
      if (await _hasPendingCreateSyncEvent(
        db,
        entityType: parentType,
        entityId: parentId,
      )) {
        return 1;
      }
    }
    return 0;
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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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
}
