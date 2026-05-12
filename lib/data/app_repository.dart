import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../app/insights/insight_rules.dart';
import '../app/core/app_clock.dart';
import '../app/sync/sync_rules.dart';
import 'local/app_database.dart';
import 'models/app_models.dart';
import 'remote/avagra_api_client.dart';
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
    AvagraApiClient? avagraApiClient,
    AuthApiClient? authApiClient,
  }) : _database = database ?? AppDatabase.instance,
        _syncApiClient = syncApiClient ?? SyncApiClient(),
        _avagraApiClient = avagraApiClient ?? AvagraApiClient(),
        _authApiClient = authApiClient ?? AuthApiClient();

  final AppDatabase _database;
  final SyncApiClient _syncApiClient;
  final AvagraApiClient _avagraApiClient;
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
  static const String _remoteSyncLockTokenKey = 'remote_sync_lock_token';
  static const String _remoteSyncLockUntilKey = 'remote_sync_lock_until';
  static const Duration _remoteSyncLockTimeout = Duration(minutes: 10);
  static const int _phase3PendingStatusCode = 12;
  static const int _phase3CompletedStatusCode = 11;
  static const int _phase3ApprovedStatusCode = 14;
  static const int _phase3LocalSectorCode = -999;
  static const int _phase3LocalActivityCode = -999;
  static const bool _traceActreuGroupResolution = true;
  final Set<int> _pendingPhase1PositionPhaseIds = <int>{};
  final Map<int, Map<int, _AvagraPhase1PositionSnapshot>>
  _pendingPhase1PositionBaselineByPhaseId =
      <int, Map<int, _AvagraPhase1PositionSnapshot>>{};
  final Map<int, int?> _pendingPhase2CellBaselineById = <int, int?>{};
  final Map<int, int?> _pendingPhase3CellBaselineById = <int, int?>{};
  final Map<String, int> _localIdCursorByTable = <String, int>{};

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
    final backgroundSyncInProgress =
        (await _loadSetting(db, 'background_sync_in_progress')) == '1';
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
      isSyncing: backgroundSyncInProgress,
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
      'updated_at': _toLimaIso8601String(DateTime.now()),
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
      final now = _toLimaIso8601String(DateTime.now());
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
    final now = _toLimaIso8601String(DateTime.now());
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
    final now = _toLimaIso8601String(DateTime.now());

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
    final now = _toLimaIso8601String(DateTime.now());
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
    final now = _toLimaIso8601String(DateTime.now());
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

    final now = _toLimaIso8601String(DateTime.now());
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
    final now = _toLimaIso8601String(DateTime.now());
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
    final now = _toLimaIso8601String(DateTime.now());
    final scope = await _ensureMilestoneScope(db, currentProjectId, now);

    if (draft.id == null) {
      final nextId = await _nextMilestoneId(db);
      final currentCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM conhit_detallehitos '
              'WHERE codProyecto = ? AND IFNULL(codEstado, 1) = 1',
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
        'codEstado': 1,
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
    final now = _toLimaIso8601String(DateTime.now());
    final scope = await _ensureMilestoneScope(db, draft.projectId, now);
    final generalId = draft.generalId == 0 ? scope.generalId : draft.generalId;
    final controlId = draft.controlId == 0 ? scope.controlId : draft.controlId;
    final currentRows = await db.query(
      'conhit_general',
      columns: [
        'dayFechaInicioContractual',
        'mntTotal',
        'flgAplicaHitoGeneral',
      ],
      where: 'codConHitGeneral = ?',
      whereArgs: [generalId],
      limit: 1,
    );
    final previousStartDate = currentRows.isEmpty
        ? null
        : _parseDate(currentRows.first['dayFechaInicioContractual'] as String?);
    final previousTotalAmount = currentRows.isEmpty
        ? 0.0
        : _asDouble(currentRows.first['mntTotal']);
    final previousAppliesToGeneral =
        currentRows.isNotEmpty &&
        _asBoolInt(currentRows.first['flgAplicaHitoGeneral']) == 1;
    final startDate = draft.startDate == null
        ? null
        : _formatDate(draft.startDate!);

    await db.update(
      'conhit_general',
      {
        'codConHit': controlId,
        'codProyecto': draft.projectId,
        'numDiasPlazoTotal': draft.totalDays,
        'numDias': draft.controversyDays,
        'mntTotal': draft.totalAmount,
        'dayFechaInicioContractual': startDate,
        'flgAplicaHitoGeneral': draft.appliesToGeneral ? 1 : 0,
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
        'numDias': draft.controversyDays,
        'mntTotal': draft.totalAmount,
        'dayFechaInicioContractual': startDate,
        'flgAplicaHitoGeneral': draft.appliesToGeneral ? 1 : 0,
      },
    );

    await _recalculateAllMilestonesFromGeneral(
      db,
      projectId: draft.projectId,
      previousStartDate: previousStartDate,
      newStartDate: draft.startDate,
      previousTotalAmount: previousTotalAmount,
      newTotalAmount: draft.totalAmount,
      previousAppliesToGeneral: previousAppliesToGeneral,
      newAppliesToGeneral: draft.appliesToGeneral,
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
    final now = _toLimaIso8601String(DateTime.now());
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
    final now = _toLimaIso8601String(DateTime.now());
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

    final now = _toLimaIso8601String(DateTime.now());
    final projectId = _asInt(rows.first['codProyecto']);

    await db.update(
      'conhit_detallehitos',
      {
        'codEstado': -1,
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'mobile',
        'sync_status': 'pending',
        'updated_at': now,
      },
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );
    final payload = await _buildMilestoneSyncPayload(db, milestoneId);
    payload['deleted'] = true;

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

  Future<AppBootstrapData> avanceGraficoEnsureDemoData({
    required int projectId,
  }) async {
    final db = await _database.database;
    final now = _toLimaIso8601String(DateTime.now());

    var moduleId = _asInt(
      (await db.query(
        'avagra_avancegrafico',
        columns: ['codAvaGrafico'],
        where: 'codProyecto = ?',
        whereArgs: [projectId],
        orderBy: 'codAvaGrafico DESC',
        limit: 1,
      )).firstOrNull?['codAvaGrafico'],
    );

    if (moduleId == null || moduleId <= 0) {
      moduleId = await _nextAvagraLocalId(
        db,
        'avagra_avancegrafico',
        'codAvaGrafico',
      );
      await db.insert('avagra_avancegrafico', {
        'codAvaGrafico': moduleId,
        'codProyecto': projectId,
        'codEstado': 1,
        'dayFechaCreacion': now,
        'desUsuarioCreacion': 'mobile',
        'vistaSeleccionada': 0,
      });
      await _enqueueSync(
        db,
        entityType: 'avagra_avancegrafico',
        entityId: '$moduleId',
        operationType: 'create',
        payload: await _buildAvagraMasterSyncPayload(db, moduleId),
      );
    }

    final phase1Row = (await db.query(
      'avagra_faseuno',
      columns: ['codFaseUno'],
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      orderBy: 'codFaseUno DESC',
      limit: 1,
    )).firstOrNull;
    if (phase1Row == null) {
      final phase1Id = await _nextAvagraLocalId(
        db,
        'avagra_faseuno',
        'codFaseUno',
      );
      await db.insert('avagra_faseuno', {
        'codFaseUno': phase1Id,
        'codProyecto': projectId,
        'codAvaGrafico': moduleId,
        'DesFaseUno': 'Configuracion base de Fase 1',
        'Comentarios': 'Creado automaticamente desde movil.',
        'desResOrdenTipoLados': '1-4-2-3',
        'CodForma': 2,
        'CodSentido': 1,
        'flgNivelesGlobales': 0,
        'numNivelesGlobales': 0,
        'dayFechaCreacion': now,
        'codUsuarioCreacion': 'mobile',
        'dayFechaModificacion': now,
        'desUsuarioModificacion': 'mobile',
        'auto_generate_pdf_enabled': 0,
        'auto_generate_pdf_iso_day': 5,
        'auto_generate_pdf_hours': '18:00',
      });
      await _enqueueSync(
        db,
        entityType: 'avagra_faseuno',
        entityId: '$phase1Id',
        operationType: 'create',
        payload: await _buildAvagraPhase1SyncPayload(db, phase1Id),
      );
    }

    final phase2Row = (await db.query(
      'avagra_fasedos',
      columns: ['codFaseDos'],
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      orderBy: 'codFaseDos DESC',
      limit: 1,
    )).firstOrNull;
    if (phase2Row == null) {
      final phase2Id = await _nextAvagraLocalId(
        db,
        'avagra_fasedos',
        'codFaseDos',
      );
      await db.insert('avagra_fasedos', {
        'codFaseDos': phase2Id,
        'codProyecto': projectId,
        'codAvaGrafico': moduleId,
        'desFaseDos': 'Matriz inicial de Fase 2',
        'desComentarios': 'Creado automaticamente desde movil.',
        'flgPisosUniformes': 0,
        'numPisosUniformes': 0,
        'dayFechaCreacion': now,
        'dayFechaModificacion': now,
        'auto_generate_pdf_enabled': 0,
        'auto_generate_pdf_iso_day': 5,
        'auto_generate_pdf_hours': '18:00',
      });
      await _enqueueSync(
        db,
        entityType: 'avagra_fasedos',
        entityId: '$phase2Id',
        operationType: 'create',
        payload: await _buildAvagraPhase2SyncPayload(db, phase2Id),
      );
    }

    final phase3Row = (await db.query(
      'avagra_fasetres',
      columns: ['codFaseTres'],
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      orderBy: 'codFaseTres DESC',
      limit: 1,
    )).firstOrNull;
    if (phase3Row == null) {
      final phase3Id = await _nextAvagraLocalId(
        db,
        'avagra_fasetres',
        'codFaseTres',
      );
      await db.insert('avagra_fasetres', {
        'codFaseTres': phase3Id,
        'codProyecto': projectId,
        'codAvaGrafico': moduleId,
        'desFaseTres': 'Detalle inicial de Fase 3',
        'desComentarios': 'Creado automaticamente desde movil.',
        'numPisos': 0,
        'numSectores': 0,
        'numActividades': 0,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
      await _enqueueSync(
        db,
        entityType: 'avagra_fasetres',
        entityId: '$phase3Id',
        operationType: 'create',
        payload: await _buildAvagraPhase3SyncPayload(db, phase3Id),
      );
    }

    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoAddPhase1Section({
    required int projectId,
    required String name,
    required String abbreviation,
    required int sideCode,
    required int levels,
    required int bays,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || levels <= 0 || bays <= 0) {
      return bootstrap();
    }
    final db = await _database.database;
    final ctx = await _ensureAvagraPhase1Context(db, projectId);
    final now = _toLimaIso8601String(DateTime.now());
    final phaseRows = await db.query(
      'avagra_faseuno',
      columns: ['flgNivelesGlobales', 'numNivelesGlobales'],
      where: 'codFaseUno = ?',
      whereArgs: [ctx.phase1Id],
      limit: 1,
    );
    final phase = phaseRows.firstOrNull;
    final effectiveLevels =
        _coerceToBool(phase?['flgNivelesGlobales']) &&
            (_asInt(phase?['numNivelesGlobales']) ?? 0) > 0
        ? (_asInt(phase?['numNivelesGlobales']) ?? levels)
        : levels;
    final trimmedAbbreviation = abbreviation.trim().isEmpty
        ? trimmedName
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .map((word) => word.trim()[0].toUpperCase())
              .join()
        : abbreviation.trim();
    final existingRows = await db.query(
      'avagra_secciones',
      columns: ['codSecciones', 'numNiveles', 'numPanios', 'codEstado'],
      where:
          'codFaseUno = ? AND codProyecto = ? AND codAvaGrafico = ? AND CodTipoLado = ?',
      whereArgs: [ctx.phase1Id, ctx.projectId, ctx.moduleId, sideCode],
      orderBy:
          'CASE WHEN IFNULL(codEstado, 1) = -1 THEN 0 ELSE 1 END, codSecciones ASC',
      limit: 1,
    );
    final sectionExists = existingRows.isNotEmpty;
    final sectionId = sectionExists
        ? (_asInt(existingRows.first['codSecciones']) ?? 0)
        : await _nextAvagraLocalId(db, 'avagra_secciones', 'codSecciones');
    if (sectionId <= 0) {
      return bootstrap();
    }
    if (sectionExists) {
      await db.update(
        'avagra_secciones',
        {
          'desSecciones': trimmedName,
          'desAbrev': trimmedAbbreviation,
          'numNiveles': effectiveLevels,
          'numPanios': bays,
          'numOrdenTipoLado': await _nextAvagraSideOrder(
            db,
            phase1Id: ctx.phase1Id,
            projectId: ctx.projectId,
            moduleId: ctx.moduleId,
            sideCode: sideCode,
          ),
          'codEstado': 1,
          'codUsuarioModificacion': 'mobile',
          'dayFechaModificacion': now,
        },
        where: 'codSecciones = ?',
        whereArgs: [sectionId],
      );
    } else {
      await db.insert('avagra_secciones', {
        'codSecciones': sectionId,
        'desSecciones': trimmedName,
        'desAbrev': trimmedAbbreviation,
        'numNiveles': effectiveLevels,
        'numPanios': bays,
        'numOrdenTipoLado': await _nextAvagraSideOrder(
          db,
          phase1Id: ctx.phase1Id,
          projectId: ctx.projectId,
          moduleId: ctx.moduleId,
          sideCode: sideCode,
        ),
        'CodTipoLado': sideCode,
        'codFaseUno': ctx.phase1Id,
        'codProyecto': ctx.projectId,
        'codAvaGrafico': ctx.moduleId,
        'codEstado': 1,
        'codUsuarioCreacion': 'mobile',
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': now,
      });
    }
    final syncMutation = await _syncAvagraPhase1SectionPositions(
      db,
      sectionId: sectionId,
      abbreviation: trimmedAbbreviation,
      levels: effectiveLevels,
      bays: bays,
      nowIso: now,
    );
    final renumberedIds = await _renumberAvagraPhase1Positions(
      db,
      phase1Id: ctx.phase1Id,
      projectId: ctx.projectId,
      moduleId: ctx.moduleId,
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_secciones',
      entityId: '$sectionId',
      operationType: sectionExists ? 'update' : 'create',
      payload: await _buildAvagraSectionSyncPayload(db, sectionId),
    );
    final touchedPositionIds = <int>{
      ...syncMutation.changedIds,
      ...renumberedIds,
    };
    if (touchedPositionIds.isNotEmpty) {
      await _enqueueAvagraPhase1PositionEvents(
        db,
        positionIds: touchedPositionIds,
        createIds: syncMutation.createdIds,
      );
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase1Section({
    required int sectionId,
  }) async {
    final db = await _database.database;
    final sectionRows = await db.query(
      'avagra_secciones',
      columns: ['codFaseUno', 'codProyecto', 'codAvaGrafico'],
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
      limit: 1,
    );
    final section = sectionRows.firstOrNull;
    if (section == null) {
      return bootstrap();
    }
    final phase1Id = _asInt(section['codFaseUno']) ?? 0;
    final projectId = _asInt(section['codProyecto']) ?? 0;
    final moduleId = _asInt(section['codAvaGrafico']) ?? 0;
    final now = _toLimaIso8601String(DateTime.now());

    final sectionPositionRows = await db.query(
      'avagra_posiciones',
      columns: ['codPosition', 'codEstado', 'desNumeracion'],
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
    );
    final sectionChangedPositionIds = <int>{};
    for (final row in sectionPositionRows) {
      final positionId = _asInt(row['codPosition']);
      if (positionId == null) continue;
      final statusCode = _asInt(row['codEstado']);
      final numeration = row['desNumeracion'] as String?;
      if (statusCode != -1 || (numeration != null && numeration.isNotEmpty)) {
        sectionChangedPositionIds.add(positionId);
      }
    }

    await db.update(
      'avagra_secciones',
      {
        'codEstado': -1,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': now,
      },
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
    );
    await db.update(
      'avagra_posiciones',
      {
        'codEstado': -1,
        'desNumeracion': null,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': now,
      },
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
    );

    await _enqueueSync(
      db,
      entityType: 'avagra_secciones',
      entityId: '$sectionId',
      operationType: 'update',
      payload: await _buildAvagraSectionSyncPayload(db, sectionId),
    );
    if (sectionChangedPositionIds.isNotEmpty) {
      await _enqueueAvagraPhase1PositionEvents(
        db,
        positionIds: sectionChangedPositionIds,
        createIds: const <int>{},
      );
    }
    if (phase1Id > 0 && projectId > 0 && moduleId > 0) {
      final renumberedIds = await _renumberAvagraPhase1Positions(
        db,
        phase1Id: phase1Id,
        projectId: projectId,
        moduleId: moduleId,
      );
      final otherRenumberedIds = renumberedIds
          .where((id) => !sectionChangedPositionIds.contains(id))
          .toSet();
      if (otherRenumberedIds.isNotEmpty) {
        await _enqueueAvagraPhase1PositionEvents(
          db,
          positionIds: otherRenumberedIds,
          createIds: const <int>{},
        );
      }
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1Section({
    required int sectionId,
    required String name,
    required String abbreviation,
    required int levels,
    required int bays,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || levels <= 0 || bays <= 0) {
      return bootstrap();
    }
    final db = await _database.database;
    final sectionRows = await db.query(
      'avagra_secciones',
      columns: [
        'codFaseUno',
        'codProyecto',
        'codAvaGrafico',
        'numNiveles',
        'numPanios',
      ],
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
      limit: 1,
    );
    if (sectionRows.isEmpty) {
      return bootstrap();
    }
    final section = sectionRows.first;
    final phase1Id = _asInt(section['codFaseUno']) ?? 0;
    final projectId = _asInt(section['codProyecto']) ?? 0;
    final moduleId = _asInt(section['codAvaGrafico']) ?? 0;
    final phaseRows = await db.query(
      'avagra_faseuno',
      columns: ['flgNivelesGlobales', 'numNivelesGlobales'],
      where: 'codFaseUno = ?',
      whereArgs: [phase1Id],
      limit: 1,
    );
    final phase = phaseRows.firstOrNull;
    final effectiveLevels =
        _coerceToBool(phase?['flgNivelesGlobales']) &&
            (_asInt(phase?['numNivelesGlobales']) ?? 0) > 0
        ? (_asInt(phase?['numNivelesGlobales']) ?? levels)
        : levels;
    final previousLevels = _asInt(section['numNiveles']) ?? 0;
    final previousBays = _asInt(section['numPanios']) ?? 0;
    final now = _toLimaIso8601String(DateTime.now());
    final trimmedAbbreviation = abbreviation.trim().isEmpty
        ? trimmedName
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .map((word) => word.trim()[0].toUpperCase())
              .join()
        : abbreviation.trim();
    await db.update(
      'avagra_secciones',
      {
        'desSecciones': trimmedName,
        'desAbrev': trimmedAbbreviation,
        'numNiveles': effectiveLevels,
        'numPanios': bays,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': now,
      },
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
    );
    var syncMutation = const _AvagraPhase1PositionMutation.empty();
    if (previousLevels != effectiveLevels || previousBays != bays) {
      syncMutation = await _syncAvagraPhase1SectionPositions(
        db,
        sectionId: sectionId,
        abbreviation: trimmedAbbreviation,
        levels: effectiveLevels,
        bays: bays,
        nowIso: now,
      );
    }
    final renumberedIds = await _renumberAvagraPhase1Positions(
      db,
      phase1Id: phase1Id,
      projectId: projectId,
      moduleId: moduleId,
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_secciones',
      entityId: '$sectionId',
      operationType: 'update',
      payload: await _buildAvagraSectionSyncPayload(db, sectionId),
    );
    final touchedPositionIds = <int>{
      ...syncMutation.changedIds,
      ...renumberedIds,
    };
    if (touchedPositionIds.isNotEmpty) {
      await _enqueueAvagraPhase1PositionEvents(
        db,
        positionIds: touchedPositionIds,
        createIds: syncMutation.createdIds,
      );
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoCyclePhase1PositionStatus({
    required int positionId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'avagra_posiciones',
      columns: ['codEstado', 'codSecciones', 'numNivel'],
      where: 'codPosition = ?',
      whereArgs: [positionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return bootstrap();
    }
    final phase1StateCodes = await _loadPhase1PositionStateCodes(db);
    final current =
        _asInt(rows.first['codEstado']) ??
        (phase1StateCodes['pendiente'] ?? 17);
    final cycle = _buildPhase1CycleOrder(phase1StateCodes);
    final index = cycle.indexOf(current);
    final next = cycle[(index + 1) % cycle.length];
    return _applyPhase1PositionStatus(
      db,
      positionId: positionId,
      newStatusCode: next,
      existingRow: rows.first,
      phase1StateCodes: phase1StateCodes,
    );
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1PositionStatus({
    required int positionId,
    required int newStatusCode,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'avagra_posiciones',
      columns: ['codEstado', 'codSecciones', 'numNivel'],
      where: 'codPosition = ?',
      whereArgs: [positionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return bootstrap();
    }
    return _applyPhase1PositionStatus(
      db,
      positionId: positionId,
      newStatusCode: newStatusCode,
      existingRow: rows.first,
      phase1StateCodes: await _loadPhase1PositionStateCodes(db),
    );
  }

  Future<AppBootstrapData> _applyPhase1PositionStatus(
    Database db, {
    required int positionId,
    required int newStatusCode,
    required Map<String, Object?> existingRow,
    required Map<String, int> phase1StateCodes,
  }) async {
    final current = _asInt(existingRow['codEstado']);
    if (current == newStatusCode) {
      return bootstrap();
    }
    final noAplicaCode = phase1StateCodes['no_aplica'] ?? 1;
    final sectionId = _asInt(existingRow['codSecciones']) ?? 0;
    final affectedLevel = _asInt(existingRow['numNivel']);
    final affectedLevels = (affectedLevel != null && affectedLevel > 0)
        ? <int>{affectedLevel}
        : null;
    _AvagraPhase1Context? phase1Context;
    int? affectedFromSectionOrder;
    if (sectionId > 0) {
      final sectionRows = await db.query(
        'avagra_secciones',
        columns: [
          'codFaseUno',
          'codProyecto',
          'codAvaGrafico',
          'numOrdenTipoLado',
        ],
        where: 'codSecciones = ?',
        whereArgs: [sectionId],
        limit: 1,
      );
      if (sectionRows.isNotEmpty) {
        final section = sectionRows.first;
        final phase1Id = _asInt(section['codFaseUno']) ?? 0;
        final projectId = _asInt(section['codProyecto']) ?? 0;
        final moduleId = _asInt(section['codAvaGrafico']) ?? 0;
        final sectionOrder = _asInt(section['numOrdenTipoLado']);
        if (sectionOrder != null && sectionOrder > 0) {
          affectedFromSectionOrder = sectionOrder;
        }
        if (phase1Id > 0 && projectId > 0 && moduleId > 0) {
          phase1Context = _AvagraPhase1Context(
            projectId: projectId,
            moduleId: moduleId,
            phase1Id: phase1Id,
          );
          if (!_pendingPhase1PositionBaselineByPhaseId.containsKey(phase1Id)) {
            _pendingPhase1PositionBaselineByPhaseId[phase1Id] =
                await _loadAvagraPhase1PositionSnapshot(
                  db,
                  phase1Id: phase1Id,
                  projectId: projectId,
                  moduleId: moduleId,
                );
          }
        }
      }
    }
    final now = _toLimaIso8601String(DateTime.now());
    final updateData = <String, Object?>{
      'codEstado': newStatusCode,
      'dayFechaModificacion': now,
      'codUsuarioModificacion': 'mobile',
    };
    if (newStatusCode == noAplicaCode) {
      updateData['desNumeracion'] = null;
    }
    await db.update(
      'avagra_posiciones',
      updateData,
      where: 'codPosition = ?',
      whereArgs: [positionId],
    );
    if (phase1Context != null) {
      await _renumberAvagraPhase1Positions(
        db,
        phase1Id: phase1Context.phase1Id,
        projectId: phase1Context.projectId,
        moduleId: phase1Context.moduleId,
        affectedLevels: affectedLevels,
        fromSectionOrder: affectedFromSectionOrder,
      );
      _pendingPhase1PositionPhaseIds.add(phase1Context.phase1Id);
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1Shape({
    required int phaseId,
    required int codForma,
  }) async {
    return avanceGraficoUpdatePhase1Settings(
      phaseId: phaseId,
      codForma: codForma,
    );
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1Direction({
    required int phaseId,
    required int codSentido,
  }) async {
    return avanceGraficoUpdatePhase1Settings(
      phaseId: phaseId,
      codSentido: codSentido,
    );
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1GlobalLevelsFlag({
    required int phaseId,
    required bool enabled,
    int? levelsCount,
  }) async {
    return avanceGraficoUpdatePhase1Settings(
      phaseId: phaseId,
      globalLevelsEnabled: enabled,
      globalLevelsCount: levelsCount,
    );
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1Settings({
    required int phaseId,
    int? codForma,
    int? codSentido,
    bool? globalLevelsEnabled,
    int? globalLevelsCount,
  }) async {
    final db = await _database.database;
    final phaseRows = await db.query(
      'avagra_faseuno',
      columns: [
        'codProyecto',
        'codAvaGrafico',
        'flgNivelesGlobales',
        'numNivelesGlobales',
      ],
      where: 'codFaseUno = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    final phase = phaseRows.firstOrNull;
    if (phase == null) {
      return bootstrap();
    }
    final projectId = _asInt(phase['codProyecto']) ?? 0;
    final moduleId = _asInt(phase['codAvaGrafico']) ?? 0;
    final updates = <String, Object?>{};
    if (codForma != null) updates['CodForma'] = codForma;
    if (codSentido != null) updates['CodSentido'] = codSentido;
    if (globalLevelsEnabled != null) {
      updates['flgNivelesGlobales'] = globalLevelsEnabled ? 1 : 0;
      if (!globalLevelsEnabled) {
        updates['numNivelesGlobales'] = globalLevelsCount ?? 0;
      }
    }
    if (globalLevelsCount != null) {
      updates['numNivelesGlobales'] = globalLevelsCount;
    }
    final shouldApplyGlobalLevels =
        (updates['flgNivelesGlobales'] as int? ??
            (_coerceToBool(phase['flgNivelesGlobales']) ? 1 : 0)) ==
        1;
    final appliedGlobalLevels =
        _asInt(updates['numNivelesGlobales']) ??
        (globalLevelsCount ?? (_asInt(phase['numNivelesGlobales']) ?? 0));
    final touchedSections = <int>{};
    final changedPositionIds = <int>{};
    final createdPositionIds = <int>{};
    if (shouldApplyGlobalLevels && appliedGlobalLevels > 0) {
      final nowIso = _toLimaIso8601String(DateTime.now());
      final sectionRows = await db.query(
        'avagra_secciones',
        columns: ['codSecciones', 'numPanios', 'desAbrev', 'numNiveles'],
        where: 'codFaseUno = ? AND codProyecto = ? AND codAvaGrafico = ?',
        whereArgs: [phaseId, projectId, moduleId],
      );
      for (final row in sectionRows) {
        final sectionId = _asInt(row['codSecciones']);
        if (sectionId == null) continue;
        final bays = _asInt(row['numPanios']) ?? 0;
        final oldLevels = _asInt(row['numNiveles']) ?? 0;
        if (bays <= 0) continue;
        if (oldLevels != appliedGlobalLevels) {
          await db.update(
            'avagra_secciones',
            {
              'numNiveles': appliedGlobalLevels,
              'codUsuarioModificacion': 'mobile',
              'dayFechaModificacion': nowIso,
            },
            where: 'codSecciones = ?',
            whereArgs: [sectionId],
          );
          touchedSections.add(sectionId);
        }
        final syncMutation = await _syncAvagraPhase1SectionPositions(
          db,
          sectionId: sectionId,
          abbreviation: (row['desAbrev'] as String?) ?? '',
          levels: appliedGlobalLevels,
          bays: bays,
          nowIso: nowIso,
        );
        changedPositionIds.addAll(syncMutation.changedIds);
        createdPositionIds.addAll(syncMutation.createdIds);
      }
    }
    updates['dayFechaModificacion'] = _toLimaIso8601String(DateTime.now());
    await db.update(
      'avagra_faseuno',
      updates,
      where: 'codFaseUno = ?',
      whereArgs: [phaseId],
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_faseuno',
      entityId: '$phaseId',
      operationType: 'update',
      payload: await _buildAvagraPhase1SyncPayload(db, phaseId),
    );
    for (final sectionId in touchedSections) {
      await _enqueueSync(
        db,
        entityType: 'avagra_secciones',
        entityId: '$sectionId',
        operationType: 'update',
        payload: await _buildAvagraSectionSyncPayload(db, sectionId),
      );
    }
    if (changedPositionIds.isNotEmpty) {
      final renumberedIds = await _renumberAvagraPhase1Positions(
        db,
        phase1Id: phaseId,
        projectId: projectId,
        moduleId: moduleId,
      );
      changedPositionIds.addAll(renumberedIds);
      await _enqueueAvagraPhase1PositionEvents(
        db,
        positionIds: changedPositionIds,
        createIds: createdPositionIds,
      );
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase1SectionOrder({
    required int phaseId,
    required List<int> sideOrder,
  }) async {
    final db = await _database.database;
    const validSides = [1, 2, 3, 4];
    if (sideOrder.length != 4 || !sideOrder.every(validSides.contains)) {
      return bootstrap();
    }
    final orderMap = <int, int>{};
    for (var i = 0; i < sideOrder.length; i++) {
      orderMap[sideOrder[i]] = i + 1;
    }
    if (orderMap.length != 4) {
      return bootstrap();
    }
    final phaseRows = await db.query(
      'avagra_faseuno',
      columns: ['codProyecto', 'codAvaGrafico'],
      where: 'codFaseUno = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    final phase = phaseRows.firstOrNull;
    final projectId = _asInt(phase?['codProyecto']) ?? 0;
    final moduleId = _asInt(phase?['codAvaGrafico']) ?? 0;
    final now = _toLimaIso8601String(DateTime.now());
    final serializedOrder = sideOrder.join('-');
    for (final entry in orderMap.entries) {
      await db.rawUpdate(
        '''
        UPDATE avagra_secciones
        SET numOrdenTipoLado = ?,
            codUsuarioModificacion = ?,
            dayFechaModificacion = ?
        WHERE codFaseUno = ? AND CodTipoLado = ?
        ''',
        [entry.value, 'mobile', now, phaseId, entry.key],
      );
    }
    await db.update(
      'avagra_faseuno',
      {'desResOrdenTipoLados': serializedOrder, 'dayFechaModificacion': now},
      where: 'codFaseUno = ?',
      whereArgs: [phaseId],
    );
    final renumberedPositionIds = phase != null
        ? await _renumberAvagraPhase1Positions(
            db,
            phase1Id: phaseId,
            projectId: projectId,
            moduleId: moduleId,
          )
        : <int>{};
    final sectionRows = await db.query(
      'avagra_secciones',
      columns: ['codSecciones'],
      where: 'codFaseUno = ?',
      whereArgs: [phaseId],
    );
    for (final row in sectionRows) {
      final sectionId = _asInt(row['codSecciones']);
      if (sectionId == null) continue;
      await _enqueueSync(
        db,
        entityType: 'avagra_secciones',
        entityId: '$sectionId',
        operationType: 'update',
        payload: await _buildAvagraSectionSyncPayload(db, sectionId),
      );
    }
    await _enqueueSync(
      db,
      entityType: 'avagra_faseuno',
      entityId: '$phaseId',
      operationType: 'update',
      payload: await _buildAvagraPhase1SyncPayload(db, phaseId),
    );
    if (projectId > 0 && moduleId > 0 && renumberedPositionIds.isNotEmpty) {
      await _enqueueAvagraPhase1PositionEvents(
        db,
        positionIds: renumberedPositionIds,
        createIds: const <int>{},
      );
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoFlushPhase1PositionEvents() async {
    if (_pendingPhase1PositionPhaseIds.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    final pendingPhaseIds = _pendingPhase1PositionPhaseIds.toList();
    _pendingPhase1PositionPhaseIds.clear();
    final changedIds = <int>{};
    for (final phase1Id in pendingPhaseIds) {
      final baseline =
          _pendingPhase1PositionBaselineByPhaseId.remove(phase1Id) ??
          const <int, _AvagraPhase1PositionSnapshot>{};
      if (baseline.isEmpty) continue;
      final phaseRows = await db.query(
        'avagra_faseuno',
        columns: ['codProyecto', 'codAvaGrafico'],
        where: 'codFaseUno = ?',
        whereArgs: [phase1Id],
        limit: 1,
      );
      if (phaseRows.isEmpty) continue;
      final phase = phaseRows.first;
      final projectId = _asInt(phase['codProyecto']) ?? 0;
      final moduleId = _asInt(phase['codAvaGrafico']) ?? 0;
      final current = await _loadAvagraPhase1PositionSnapshot(
        db,
        phase1Id: phase1Id,
        projectId: projectId,
        moduleId: moduleId,
      );
      changedIds.addAll(
        _collectChangedAvagraPhase1PositionIds(
          baseline: baseline,
          current: current,
        ),
      );
    }
    if (changedIds.isNotEmpty) {
      await _enqueueAvagraPhase1PositionEvents(
        db,
        positionIds: changedIds,
        createIds: const <int>{},
      );
    }
    return bootstrap();
  }

  Future<void> avanceGraficoClearPendingPhase1PositionEvents() async {
    _pendingPhase1PositionPhaseIds.clear();
    _pendingPhase1PositionBaselineByPhaseId.clear();
  }

  // â”€â”€ Fase 2 operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<AppBootstrapData> avanceGraficoAddPhase2Activity({
    required int phaseId,
    required String name,
    required String abbreviation,
    required int floors,
    required int basements,
    required int sectors,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || floors < 1 || basements < 0 || sectors < 1) {
      return bootstrap();
    }
    final db = await _database.database;
    final now = _toLimaIso8601String(DateTime.now());
    final phaseRow = (await db.query(
      'avagra_fasedos',
      columns: [
        'codProyecto',
        'codAvaGrafico',
        'flgPisosUniformes',
        'numPisosUniformes',
      ],
      where: 'codFaseDos = ?',
      whereArgs: [phaseId],
      limit: 1,
    )).firstOrNull;
    final projectId = _asInt(phaseRow?['codProyecto']) ?? 0;
    final moduleId = _asInt(phaseRow?['codAvaGrafico']) ?? 0;
    if (projectId <= 0 || moduleId <= 0) {
      return bootstrap();
    }
    final uniformEnabled = _coerceToBool(phaseRow?['flgPisosUniformes']);
    final uniformCount = _asInt(phaseRow?['numPisosUniformes']) ?? 0;
    final resolvedFloors = uniformEnabled && uniformCount > 0
        ? uniformCount
        : floors;
    final resolvedAbbreviation = abbreviation.trim().isEmpty
        ? trimmedName
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .map((word) => word.trim()[0].toUpperCase())
              .join()
        : abbreviation.trim();
    final pendingCode = await _resolveAvagraStateCode(
      db,
      phaseKey: 'FaseDos_Cuadros',
      label: 'Pendiente',
      fallback: 4,
    );
    final activityId = await _nextAvagraLocalId(
      db,
      'avagra_actividades',
      'codActividades',
    );

    await db.insert('avagra_actividades', {
      'codActividades': activityId,
      'codProyecto': projectId,
      'codAvaGrafico': moduleId,
      'codFaseDos': phaseId,
      'desActividades': trimmedName,
      'desAbrev': resolvedAbbreviation,
      'numPisos': resolvedFloors,
      'sotanos': basements,
      'numSectores': sectors,
      'codUsuarioCreacion': 'mobile',
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 'mobile',
      'dayFechaModificacion': now,
    });
    await _enqueueSync(
      db,
      entityType: 'avagra_actividades',
      entityId: '$activityId',
      operationType: 'create',
      payload: await _buildAvagraPhase2ActivitySyncPayload(db, activityId),
    );

    var order = 0;
    final floorAxis = <int>[
      for (var floor = resolvedFloors; floor >= 1; floor--) floor,
      for (var basement = 1; basement <= basements; basement++) -basement,
    ];
    final createdCellIds = <int>{};
    for (final floor in floorAxis) {
      for (var sector = 1; sector <= sectors; sector++) {
        final cellId = await _nextAvagraLocalId(
          db,
          'avagra_cuadros',
          'codCuadros',
        );
        await db.insert('avagra_cuadros', {
          'codCuadros': cellId,
          'codActividades': activityId,
          'numOrden': ++order,
          'numPiso': floor,
          'numSector': sector,
          'codUsuarioCreacion': 'mobile',
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 'mobile',
          'dayFechaModificacion': now,
          'codEstado': pendingCode,
        });
        createdCellIds.add(cellId);
      }
    }
    await _enqueueAvagraPhase2CellEvents(
      db,
      cellIds: createdCellIds,
      createIds: createdCellIds,
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase2Activity({
    required int activityId,
    required String name,
    required String abbreviation,
    required int floors,
    required int basements,
    required int sectors,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || floors < 1 || basements < 0 || sectors < 1) {
      return bootstrap();
    }
    final db = await _database.database;
    final activityRows = await db.query(
      'avagra_actividades',
      columns: ['codFaseDos', 'numPisos', 'sotanos', 'numSectores'],
      where: 'codActividades = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    if (activityRows.isEmpty) {
      return bootstrap();
    }
    final activity = activityRows.first;
    final phaseId = _asInt(activity['codFaseDos']) ?? 0;
    if (phaseId <= 0) {
      return bootstrap();
    }
    final resolvedFloors = floors;
    final resolvedAbbreviation = abbreviation.trim().isEmpty
        ? trimmedName
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .map((word) => word.trim()[0].toUpperCase())
              .join()
        : abbreviation.trim();
    final previousFloors = _asInt(activity['numPisos']) ?? 0;
    final previousBasements = _asInt(activity['sotanos']) ?? 0;
    final previousSectors = _asInt(activity['numSectores']) ?? 0;
    final dimensionsChanged =
        previousFloors != resolvedFloors ||
        previousBasements != basements ||
        previousSectors != sectors;
    final now = _toLimaIso8601String(DateTime.now());

    await db.update(
      'avagra_actividades',
      {
        'desActividades': trimmedName,
        'desAbrev': resolvedAbbreviation,
        'numPisos': resolvedFloors,
        'sotanos': basements,
        'numSectores': sectors,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': now,
      },
      where: 'codActividades = ?',
      whereArgs: [activityId],
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_actividades',
      entityId: '$activityId',
      operationType: 'update',
      payload: await _buildAvagraPhase2ActivitySyncPayload(db, activityId),
    );
    if (dimensionsChanged) {
      final mutation = await _syncAvagraPhase2ActivityCells(
        db,
        activityId: activityId,
        floors: resolvedFloors,
        basements: basements,
        sectors: sectors,
        nowIso: now,
      );
      if (mutation.createdIds.isNotEmpty) {
        await _enqueueAvagraPhase2CellEvents(
          db,
          cellIds: mutation.createdIds,
          createIds: mutation.createdIds,
        );
      }
      for (final deletedPayload in mutation.deletedPayloads) {
        final cellId = _asInt(deletedPayload['codCuadros']);
        if (cellId == null) {
          continue;
        }
        _pendingPhase2CellBaselineById.remove(cellId);
        await _enqueueSync(
          db,
          entityType: 'avagra_cuadros',
          entityId: '$cellId',
          operationType: 'delete',
          payload: deletedPayload,
        );
      }
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase2Activity({
    required int activityId,
  }) async {
    final db = await _database.database;
    final activityRows = await db.query(
      'avagra_actividades',
      where: 'codActividades = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    if (activityRows.isEmpty) {
      return bootstrap();
    }
    final activityPayload = Map<String, Object?>.from(activityRows.first);
    final cellRows = await db.query(
      'avagra_cuadros',
      where: 'codActividades = ?',
      whereArgs: [activityId],
    );
    final cellPayloads = cellRows
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
    await db.delete(
      'avagra_cuadros',
      where: 'codActividades = ?',
      whereArgs: [activityId],
    );
    await db.delete(
      'avagra_actividades',
      where: 'codActividades = ?',
      whereArgs: [activityId],
    );
    for (final payload in cellPayloads) {
      final cellId = _asInt(payload['codCuadros']);
      if (cellId == null) {
        continue;
      }
      _pendingPhase2CellBaselineById.remove(cellId);
      await _enqueueSync(
        db,
        entityType: 'avagra_cuadros',
        entityId: '$cellId',
        operationType: 'delete',
        payload: payload,
      );
    }
    await _enqueueSync(
      db,
      entityType: 'avagra_actividades',
      entityId: '$activityId',
      operationType: 'delete',
      payload: activityPayload,
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase2UniformFloors({
    required int phaseId,
    required bool enabled,
    required int count,
  }) async {
    final db = await _database.database;
    final safeCount = count < 1 ? 1 : count;
    final phaseRowsById = await db.query(
      'avagra_fasedos',
      columns: ['codProyecto', 'codAvaGrafico'],
      where: 'codFaseDos = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    var projectId = _asInt(phaseRowsById.firstOrNull?['codProyecto']) ?? 0;
    var moduleId = _asInt(phaseRowsById.firstOrNull?['codAvaGrafico']) ?? 0;
    if (projectId <= 0 || moduleId <= 0) {
      final currentProjectId = await _loadCurrentProjectId(db);
      if (currentProjectId != null) {
        final masterRows = await db.query(
          'avagra_avancegrafico',
          columns: ['codAvaGrafico'],
          where: 'codProyecto = ?',
          whereArgs: [currentProjectId],
          limit: 1,
        );
        final resolvedModuleId = _asInt(
          masterRows.firstOrNull?['codAvaGrafico'],
        );
        if (resolvedModuleId != null && resolvedModuleId > 0) {
          projectId = currentProjectId;
          moduleId = resolvedModuleId;
        }
      }
    }
    if (projectId <= 0 || moduleId <= 0) {
      return bootstrap();
    }
    final targetRows = await db.query(
      'avagra_fasedos',
      columns: ['codFaseDos'],
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      orderBy: 'codFaseDos DESC',
    );
    if (targetRows.isEmpty) {
      return bootstrap();
    }
    final now = _toLimaIso8601String(DateTime.now());
    await db.update(
      'avagra_fasedos',
      {
        'flgPisosUniformes': enabled ? 1 : 0,
        'numPisosUniformes': safeCount,
        'dayFechaModificacion': now,
      },
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
    );
    for (final row in targetRows) {
      final targetPhaseId = _asInt(row['codFaseDos']);
      if (targetPhaseId == null) {
        continue;
      }
      await _enqueueSync(
        db,
        entityType: 'avagra_fasedos',
        entityId: '$targetPhaseId',
        operationType: 'update',
        payload: await _buildAvagraPhase2SyncPayload(db, targetPhaseId),
      );
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoCyclePhase2CellState({
    required int cellId,
  }) async {
    final db = await _database.database;
    final cycleRows = await db.query(
      'avagra_estados',
      columns: ['codEstado'],
      where: 'desFase = ?',
      whereArgs: ['FaseDos_Cuadros'],
      orderBy: 'codEstado ASC',
    );
    final cycle = cycleRows
        .map((row) => _asInt(row['codEstado']))
        .whereType<int>()
        .toList();
    if (cycle.isEmpty) {
      return bootstrap();
    }
    final rows = await db.query(
      'avagra_cuadros',
      columns: ['codEstado'],
      where: 'codCuadros = ?',
      whereArgs: [cellId],
      limit: 1,
    );
    if (rows.isEmpty) return bootstrap();
    final current = _asInt(rows.first['codEstado']) ?? cycle.first;
    final index = cycle.indexOf(current);
    final next = index < 0 ? cycle.first : cycle[(index + 1) % cycle.length];
    if (next == current) {
      return bootstrap();
    }
    await db.update(
      'avagra_cuadros',
      {
        'codEstado': next,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
      },
      where: 'codCuadros = ?',
      whereArgs: [cellId],
    );
    _pendingPhase2CellBaselineById.remove(cellId);
    await _enqueueAvagraPhase2CellEvents(
      db,
      cellIds: [cellId],
      createIds: const <int>{},
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase2CellState({
    required int cellId,
    required int newStatusCode,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'avagra_cuadros',
      columns: ['codEstado'],
      where: 'codCuadros = ?',
      whereArgs: [cellId],
      limit: 1,
    );
    if (rows.isEmpty) return bootstrap();
    final current = _asInt(rows.first['codEstado']);
    if (current == newStatusCode) {
      return bootstrap();
    }
    await db.update(
      'avagra_cuadros',
      {
        'codEstado': newStatusCode,
        'codUsuarioModificacion': 'mobile',
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
      },
      where: 'codCuadros = ?',
      whereArgs: [cellId],
    );
    _pendingPhase2CellBaselineById.remove(cellId);
    await _enqueueAvagraPhase2CellEvents(
      db,
      cellIds: [cellId],
      createIds: const <int>{},
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoFlushPhase2CellEvents() async {
    if (_pendingPhase2CellBaselineById.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    final pending = Map<int, int?>.from(_pendingPhase2CellBaselineById);
    _pendingPhase2CellBaselineById.clear();
    final changedIds = <int>{};

    for (final entry in pending.entries) {
      final rows = await db.query(
        'avagra_cuadros',
        columns: ['codEstado'],
        where: 'codCuadros = ?',
        whereArgs: [entry.key],
        limit: 1,
      );
      if (rows.isEmpty) {
        continue;
      }
      if (_asInt(rows.first['codEstado']) != entry.value) {
        changedIds.add(entry.key);
      }
    }

    if (changedIds.isNotEmpty) {
      await _enqueueAvagraPhase2CellEvents(
        db,
        cellIds: changedIds,
        createIds: const <int>{},
      );
    }
    return bootstrap();
  }

  Future<void> avanceGraficoClearPendingPhase2CellEvents() async {
    _pendingPhase2CellBaselineById.clear();
  }

  // --- Phase 3 CRUD -----------------------------------------------------------
  Future<AppBootstrapData> avanceGraficoUpdatePhase3CellState({
    required int cellId,
    required int newStatusCode,
  }) async {
    final db = await _database.database;
    final now = _toLimaIso8601String(DateTime.now());
    final cellRows = await db.query(
      'avagra_actividadxsectorxpisos',
      columns: ['codSectorxPiso', 'codEstado'],
      where: 'codActividadxSectorxPiso = ?',
      whereArgs: [cellId],
      limit: 1,
    );
    final currentRow = cellRows.firstOrNull;
    if (currentRow == null) {
      return bootstrap();
    }
    if (!_pendingPhase3CellBaselineById.containsKey(cellId)) {
      _pendingPhase3CellBaselineById[cellId] = _asInt(currentRow['codEstado']);
    }
    final sectorFloorId = _asInt(currentRow['codSectorxPiso']);
    await db.update(
      'avagra_actividadxsectorxpisos',
      {'codEstado': newStatusCode, 'dayFechaModificacion': now},
      where: 'codActividadxSectorxPiso = ?',
      whereArgs: [cellId],
    );
    if (sectorFloorId != null) {
      await _recalculatePhase3SectorProgress(db, sectorFloorId);
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoFlushPhase3CellEvents() async {
    if (_pendingPhase3CellBaselineById.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    final pending = Map<int, int?>.from(_pendingPhase3CellBaselineById);
    _pendingPhase3CellBaselineById.clear();
    final changedIds = <int>{};

    for (final entry in pending.entries) {
      final rows = await db.query(
        'avagra_actividadxsectorxpisos',
        columns: ['codEstado'],
        where: 'codActividadxSectorxPiso = ?',
        whereArgs: [entry.key],
        limit: 1,
      );
      if (rows.isEmpty) {
        continue;
      }
      if (_asInt(rows.first['codEstado']) != entry.value) {
        changedIds.add(entry.key);
      }
    }

    if (changedIds.isNotEmpty) {
      await _enqueueAvagraPhase3CellEvents(
        db,
        cellIds: changedIds,
        createIds: const <int>{},
      );
    }
    return bootstrap();
  }

  Future<void> avanceGraficoClearPendingPhase3CellEvents() async {
    _pendingPhase3CellBaselineById.clear();
  }

  Future<AppBootstrapData> avanceGraficoInitializePhase3Config({
    required int phaseId,
  }) async {
    final db = await _database.database;
    await _assertPhase3NotInitialized(db, phaseId);
    final phaseRows = await db.query(
      'avagra_fasetres',
      columns: ['codProyecto', 'codAvaGrafico'],
      where: 'codFaseTres = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    final phase = phaseRows.firstOrNull;
    if (phase == null) {
      throw Exception('No se encontro la fase 3 seleccionada.');
    }

    final projectId = _asInt(phase['codProyecto']) ?? 0;
    final moduleId = _asInt(phase['codAvaGrafico']) ?? 0;

    final floorCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_pisos
            WHERE codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ?
            ''',
            [phaseId, projectId, moduleId],
          ),
        ) ??
        0;
    final sectorCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_sectores
            WHERE codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ?
              AND codSector != ?
            ''',
            [phaseId, projectId, moduleId, _phase3LocalSectorCode],
          ),
        ) ??
        0;
    final activityCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_actividad
            WHERE codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ?
              AND codActividad != ?
            ''',
            [phaseId, projectId, moduleId, _phase3LocalActivityCode],
          ),
        ) ??
        0;

    if (floorCount <= 0) {
      throw Exception('Configura al menos un piso para inicializar Fase 3.');
    }
    if (sectorCount <= 0) {
      throw Exception(
        'Configura al menos un sector global para inicializar Fase 3.',
      );
    }
    if (activityCount <= 0) {
      throw Exception(
        'Configura al menos una actividad global para inicializar Fase 3.',
      );
    }

    await db.update(
      'avagra_fasetres',
      {
        'numPisos': floorCount,
        'numSectores': sectorCount,
        'numActividades': activityCount,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
      },
      where: 'codFaseTres = ?',
      whereArgs: [phaseId],
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_fasetres',
      entityId: '$phaseId',
      operationType: 'update',
      payload: await _buildAvagraPhase3SyncPayload(db, phaseId),
    );
    await _enqueuePhase3GlobalConfigCreateEvents(
      db,
      phaseId: phaseId,
      projectId: projectId,
      moduleId: moduleId,
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoAddPhase3Floor({
    required int phaseId,
    required int projectId,
    required int moduleId,
    required String name,
    required String abbreviation,
    required int order,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    await _assertPhase3NotInitialized(db, phaseId);
    final now = _toLimaIso8601String(DateTime.now());

    final pisoId = await _nextAvagraLocalId(db, 'avagra_pisos', 'codPiso');
    await db.insert('avagra_pisos', {
      'codPiso': pisoId,
      'codFaseTres': phaseId,
      'codProyecto': projectId,
      'codAvaGrafico': moduleId,
      'desAbrev': abbreviation.trim(),
      'desNombre': trimmedName,
      'numOrden': order,
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    });

    // Create sectoresxpisos for each existing sector in this fasetres
    final sectorRows = await db.query(
      'avagra_sectores',
      where:
          'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ? AND codSector != ?',
      whereArgs: [phaseId, projectId, moduleId, _phase3LocalSectorCode],
      orderBy: 'codSector ASC',
    );
    for (final s in sectorRows) {
      final sxpId = await _nextAvagraLocalId(
        db,
        'avagra_sectoresxpisos',
        'codSectorxPiso',
      );
      await db.insert('avagra_sectoresxpisos', {
        'codSectorxPiso': sxpId,
        'codPiso': pisoId,
        'codSector': s['codSector'],
        'desNombre': s['desNombre'] ?? '',
        'desAbrev': s['desAbrev'] ?? '',
        'desDescripcion': s['desDescripcion'] ?? '',
        'codEstado': _phase3PendingStatusCode,
        'numPorcentajeCompletados': 0.0,
        'numPorcentajeAprobadosCalidad': 0.0,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
    }

    // Create actividadxpisos and cells for each existing activity in this fasetres
    final actRows = await db.query(
      'avagra_actividad',
      where:
          'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ? AND codActividad != ?',
      whereArgs: [phaseId, projectId, moduleId, _phase3LocalActivityCode],
      orderBy: 'codActividad ASC',
    );
    var orden = 1;
    for (final a in actRows) {
      final axpId = await _nextAvagraLocalId(
        db,
        'avagra_actividadxpisos',
        'codActividadxPiso',
      );
      await db.insert('avagra_actividadxpisos', {
        'codActividadxPiso': axpId,
        'codActividad': a['codActividad'],
        'codPiso': pisoId,
        'desAbrev': a['desDescripcion'] ?? a['desNombre'],
        'desDescripcion': a['desNombre'] ?? '',
        'codEstado': _phase3PendingStatusCode,
        'numOrden': orden++,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
      // Re-query the sectoresxpisos we just created for this floor
      final newSxpRows = await db.query(
        'avagra_sectoresxpisos',
        columns: ['codSectorxPiso'],
        where: 'codPiso = ?',
        whereArgs: [pisoId],
      );
      for (final sxp in newSxpRows) {
        final cellId = await _nextAvagraLocalId(
          db,
          'avagra_actividadxsectorxpisos',
          'codActividadxSectorxPiso',
        );
        await db.insert('avagra_actividadxsectorxpisos', {
          'codActividadxSectorxPiso': cellId,
          'codActividadxPiso': axpId,
          'codSectorxPiso': sxp['codSectorxPiso'],
          'codEstado': _phase3PendingStatusCode,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
        });
      }
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase3Floor({
    required int floorId,
  }) async {
    final db = await _database.database;
    final floorRows = await db.query(
      'avagra_pisos',
      columns: ['codFaseTres'],
      where: 'codPiso = ?',
      whereArgs: [floorId],
      limit: 1,
    );
    final phaseId = _asInt(floorRows.firstOrNull?['codFaseTres']);
    if (phaseId == null) {
      return bootstrap();
    }
    await _assertPhase3NotInitialized(db, phaseId);
    // Get all actividadxpisos for this floor
    final axpRows = await db.query(
      'avagra_actividadxpisos',
      columns: ['codActividadxPiso'],
      where: 'codPiso = ?',
      whereArgs: [floorId],
    );
    final sxpRows = await db.query(
      'avagra_sectoresxpisos',
      columns: ['codSectorxPiso'],
      where: 'codPiso = ?',
      whereArgs: [floorId],
    );
    for (final axp in axpRows) {
      await db.delete(
        'avagra_actividadxsectorxpisos',
        where: 'codActividadxPiso = ?',
        whereArgs: [axp['codActividadxPiso']],
      );
    }
    for (final sxp in sxpRows) {
      await db.delete(
        'avagra_actividadxsectorxpisos',
        where: 'codSectorxPiso = ?',
        whereArgs: [sxp['codSectorxPiso']],
      );
    }
    await db.delete(
      'avagra_actividadxpisos',
      where: 'codPiso = ?',
      whereArgs: [floorId],
    );
    await db.delete(
      'avagra_sectoresxpisos',
      where: 'codPiso = ?',
      whereArgs: [floorId],
    );
    await db.delete('avagra_pisos', where: 'codPiso = ?', whereArgs: [floorId]);
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoAddPhase3Sector({
    required int phaseId,
    required int projectId,
    required int moduleId,
    required String name,
    required String abbreviation,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    await _assertPhase3NotInitialized(db, phaseId);
    final now = _toLimaIso8601String(DateTime.now());

    final sectorId = await _nextAvagraLocalId(
      db,
      'avagra_sectores',
      'codSector',
    );
    await db.insert('avagra_sectores', {
      'codSector': sectorId,
      'codFaseTres': phaseId,
      'codProyecto': projectId,
      'codAvaGrafico': moduleId,
      'desNombre': trimmedName,
      'desAbrev': abbreviation.trim(),
      'desDescripcion': '',
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    });

    // For each floor in this fasetres, create sectoresxpisos + cells per existing activity
    final floorRows = await db.query(
      'avagra_pisos',
      where: 'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [phaseId, projectId, moduleId],
      orderBy: 'numOrden ASC',
    );
    for (final floor in floorRows) {
      final pisoId = _asInt(floor['codPiso'])!;
      final sxpId = await _nextAvagraLocalId(
        db,
        'avagra_sectoresxpisos',
        'codSectorxPiso',
      );
      await db.insert('avagra_sectoresxpisos', {
        'codSectorxPiso': sxpId,
        'codPiso': pisoId,
        'codSector': sectorId,
        'desNombre': trimmedName,
        'desAbrev': abbreviation.trim(),
        'desDescripcion': '',
        'codEstado': _phase3PendingStatusCode,
        'numPorcentajeCompletados': 0.0,
        'numPorcentajeAprobadosCalidad': 0.0,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
      // Create cells for each existing actividadxpiso in this floor
      final axpRows = await db.query(
        'avagra_actividadxpisos',
        columns: ['codActividadxPiso'],
        where: 'codPiso = ?',
        whereArgs: [pisoId],
      );
      for (final axp in axpRows) {
        final cellId = await _nextAvagraLocalId(
          db,
          'avagra_actividadxsectorxpisos',
          'codActividadxSectorxPiso',
        );
        await db.insert('avagra_actividadxsectorxpisos', {
          'codActividadxSectorxPiso': cellId,
          'codActividadxPiso': axp['codActividadxPiso'],
          'codSectorxPiso': sxpId,
          'codEstado': _phase3PendingStatusCode,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
        });
      }
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase3Sector({
    required int sectorId,
  }) async {
    final db = await _database.database;
    if (sectorId == _phase3LocalSectorCode) {
      throw Exception(
        'El sector local (-999) solo se puede eliminar desde su piso.',
      );
    }
    final sectorRows = await db.query(
      'avagra_sectores',
      columns: ['codFaseTres'],
      where: 'codSector = ?',
      whereArgs: [sectorId],
      limit: 1,
    );
    final phaseId = _asInt(sectorRows.firstOrNull?['codFaseTres']);
    if (phaseId == null) {
      return bootstrap();
    }
    await _assertPhase3NotInitialized(db, phaseId);
    final sxpRows = await db.query(
      'avagra_sectoresxpisos',
      columns: ['codSectorxPiso'],
      where: 'codSector = ?',
      whereArgs: [sectorId],
    );
    for (final sxp in sxpRows) {
      await db.delete(
        'avagra_actividadxsectorxpisos',
        where: 'codSectorxPiso = ?',
        whereArgs: [sxp['codSectorxPiso']],
      );
    }
    await db.delete(
      'avagra_sectoresxpisos',
      where: 'codSector = ?',
      whereArgs: [sectorId],
    );
    await db.delete(
      'avagra_sectores',
      where: 'codSector = ?',
      whereArgs: [sectorId],
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoAddPhase3Activity({
    required int phaseId,
    required int projectId,
    required int moduleId,
    required String name,
    required String abbreviation,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final trimmedAbbreviation = abbreviation.trim().isEmpty
        ? trimmedName
              .split(' ')
              .where((word) => word.trim().isNotEmpty)
              .map((word) => word.trim()[0].toUpperCase())
              .join()
        : abbreviation.trim();
    final db = await _database.database;
    await _assertPhase3NotInitialized(db, phaseId);
    final now = _toLimaIso8601String(DateTime.now());

    final actId = await _nextAvagraLocalId(
      db,
      'avagra_actividad',
      'codActividad',
    );
    await db.insert('avagra_actividad', {
      'codActividad': actId,
      'codFaseTres': phaseId,
      'codProyecto': projectId,
      'codAvaGrafico': moduleId,
      'desNombre': trimmedName,
      'desDescripcion': trimmedAbbreviation,
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    });

    final floorRows = await db.query(
      'avagra_pisos',
      where: 'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [phaseId, projectId, moduleId],
      orderBy: 'numOrden ASC',
    );
    var orden = 1;
    for (final floor in floorRows) {
      final pisoId = _asInt(floor['codPiso'])!;
      final axpId = await _nextAvagraLocalId(
        db,
        'avagra_actividadxpisos',
        'codActividadxPiso',
      );
      await db.insert('avagra_actividadxpisos', {
        'codActividadxPiso': axpId,
        'codActividad': actId,
        'codPiso': pisoId,
        'desAbrev': trimmedAbbreviation,
        'desDescripcion': trimmedName,
        'codEstado': _phase3PendingStatusCode,
        'numOrden': orden++,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
      final sxpRows = await db.query(
        'avagra_sectoresxpisos',
        columns: ['codSectorxPiso'],
        where: 'codPiso = ?',
        whereArgs: [pisoId],
      );
      for (final sxp in sxpRows) {
        final cellId = await _nextAvagraLocalId(
          db,
          'avagra_actividadxsectorxpisos',
          'codActividadxSectorxPiso',
        );
        await db.insert('avagra_actividadxsectorxpisos', {
          'codActividadxSectorxPiso': cellId,
          'codActividadxPiso': axpId,
          'codSectorxPiso': sxp['codSectorxPiso'],
          'codEstado': _phase3PendingStatusCode,
          'codUsuarioCreacion': 7,
          'dayFechaCreacion': now,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': now,
        });
      }
    }
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoAddPhase3SectorToFloor({
    required int pisoId,
    required int phaseId,
    required int projectId,
    required int moduleId,
    required String name,
    required String abbreviation,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    await _assertPhase3Initialized(db, phaseId);
    final now = _toLimaIso8601String(DateTime.now());
    await _ensurePhase3LocalPivotTemplates(db, now);
    final alreadyExists =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_sectoresxpisos
            WHERE codPiso = ? AND LOWER(TRIM(COALESCE(desNombre,''))) = LOWER(TRIM(?))
            ''',
            [pisoId, trimmedName],
          ),
        ) ??
        0;
    if (alreadyExists > 0) {
      throw Exception(
        'Ya existe un sector con ese nombre en el piso seleccionado.',
      );
    }
    final pisoRows = await db.query(
      'avagra_pisos',
      columns: ['codFaseTres', 'codProyecto', 'codAvaGrafico'],
      where: 'codPiso = ?',
      whereArgs: [pisoId],
      limit: 1,
    );
    if (pisoRows.isEmpty) {
      return bootstrap();
    }
    final piso = pisoRows.first;
    if ((_asInt(piso['codFaseTres']) ?? 0) != phaseId ||
        (_asInt(piso['codProyecto']) ?? 0) != projectId ||
        (_asInt(piso['codAvaGrafico']) ?? 0) != moduleId) {
      throw Exception('El piso seleccionado no pertenece a la Fase 3 actual.');
    }
    final sxpId = await _nextAvagraLocalId(
      db,
      'avagra_sectoresxpisos',
      'codSectorxPiso',
    );
    await db.insert('avagra_sectoresxpisos', {
      'codSectorxPiso': sxpId,
      'codPiso': pisoId,
      'codSector': _phase3LocalSectorCode,
      'desNombre': trimmedName,
      'desAbrev': abbreviation.trim(),
      'desDescripcion': '',
      'codEstado': _phase3PendingStatusCode,
      'numPorcentajeCompletados': 0.0,
      'numPorcentajeAprobadosCalidad': 0.0,
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    });
    final axpRows = await db.query(
      'avagra_actividadxpisos',
      columns: ['codActividadxPiso'],
      where: 'codPiso = ?',
      whereArgs: [pisoId],
    );
    final createdCellIds = <int>{};
    for (final axp in axpRows) {
      final createdCellId = await _nextAvagraLocalId(
        db,
        'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso',
      );
      createdCellIds.add(createdCellId);
      await db.insert('avagra_actividadxsectorxpisos', {
        'codActividadxSectorxPiso': createdCellId,
        'codActividadxPiso': axp['codActividadxPiso'],
        'codSectorxPiso': sxpId,
        'codEstado': _phase3PendingStatusCode,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
    }
    await _recalculatePhase3SectorProgress(db, sxpId);
    await _enqueueSync(
      db,
      entityType: 'avagra_sectoresxpisos',
      entityId: '$sxpId',
      operationType: 'create',
      payload: await _buildAvagraPhase3SectorFloorSyncPayload(db, sxpId),
    );
    await _enqueueAvagraPhase3CellEvents(
      db,
      cellIds: createdCellIds,
      createIds: createdCellIds,
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoAddPhase3ActivityToFloor({
    required int pisoId,
    required int phaseId,
    required int projectId,
    required int moduleId,
    required String name,
    required String abbreviation,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    await _assertPhase3Initialized(db, phaseId);
    final now = _toLimaIso8601String(DateTime.now());
    await _ensurePhase3LocalPivotTemplates(db, now);
    final pisoRows = await db.query(
      'avagra_pisos',
      columns: ['codFaseTres', 'codProyecto', 'codAvaGrafico'],
      where: 'codPiso = ?',
      whereArgs: [pisoId],
      limit: 1,
    );
    final piso = pisoRows.firstOrNull;
    if (piso == null) {
      return bootstrap();
    }
    if ((_asInt(piso['codFaseTres']) ?? 0) != phaseId ||
        (_asInt(piso['codProyecto']) ?? 0) != projectId ||
        (_asInt(piso['codAvaGrafico']) ?? 0) != moduleId) {
      throw Exception('El piso seleccionado no pertenece a la Fase 3 actual.');
    }
    final existsInFloor =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_actividadxpisos
            WHERE codPiso = ? AND LOWER(TRIM(COALESCE(desDescripcion,''))) = LOWER(TRIM(?))
            ''',
            [pisoId, trimmedName],
          ),
        ) ??
        0;
    if (existsInFloor > 0) {
      throw Exception(
        'Ya existe una actividad con ese nombre en el piso seleccionado.',
      );
    }
    final axpId = await _nextAvagraLocalId(
      db,
      'avagra_actividadxpisos',
      'codActividadxPiso',
    );
    final orderRow = await db.rawQuery(
      'SELECT COALESCE(MAX(numOrden),0)+1 AS nxt FROM avagra_actividadxpisos WHERE codPiso = ?',
      [pisoId],
    );
    final orden = _asInt(orderRow.first['nxt']) ?? 1;
    await db.insert('avagra_actividadxpisos', {
      'codActividadxPiso': axpId,
      'codActividad': _phase3LocalActivityCode,
      'codPiso': pisoId,
      'desAbrev': abbreviation.trim(),
      'desDescripcion': trimmedName,
      'codEstado': _phase3PendingStatusCode,
      'numOrden': orden,
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    });
    final sxpRows = await db.query(
      'avagra_sectoresxpisos',
      columns: ['codSectorxPiso'],
      where: 'codPiso = ?',
      whereArgs: [pisoId],
    );
    final affectedSectorIds = <int>{};
    final createdCellIds = <int>{};
    for (final sxp in sxpRows) {
      final sectorFloorId = _asInt(sxp['codSectorxPiso']);
      if (sectorFloorId != null) {
        affectedSectorIds.add(sectorFloorId);
      }
      final createdCellId = await _nextAvagraLocalId(
        db,
        'avagra_actividadxsectorxpisos',
        'codActividadxSectorxPiso',
      );
      createdCellIds.add(createdCellId);
      await db.insert('avagra_actividadxsectorxpisos', {
        'codActividadxSectorxPiso': createdCellId,
        'codActividadxPiso': axpId,
        'codSectorxPiso': sxp['codSectorxPiso'],
        'codEstado': _phase3PendingStatusCode,
        'codUsuarioCreacion': 7,
        'dayFechaCreacion': now,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      });
    }
    for (final sectorFloorId in affectedSectorIds) {
      await _recalculatePhase3SectorProgress(db, sectorFloorId);
    }
    await _enqueueSync(
      db,
      entityType: 'avagra_actividadxpisos',
      entityId: '$axpId',
      operationType: 'create',
      payload: await _buildAvagraPhase3ActivityFloorSyncPayload(db, axpId),
    );
    await _enqueueAvagraPhase3CellEvents(
      db,
      cellIds: createdCellIds,
      createIds: createdCellIds,
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase3Activity({
    required int activityId,
  }) async {
    final db = await _database.database;
    if (activityId == _phase3LocalActivityCode) {
      throw Exception(
        'La actividad local (-999) solo se puede eliminar desde su piso.',
      );
    }
    final activityRows = await db.query(
      'avagra_actividad',
      columns: ['codFaseTres'],
      where: 'codActividad = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    final phaseId = _asInt(activityRows.firstOrNull?['codFaseTres']);
    if (phaseId == null) {
      return bootstrap();
    }
    await _assertPhase3NotInitialized(db, phaseId);
    final axpRows = await db.query(
      'avagra_actividadxpisos',
      columns: ['codActividadxPiso'],
      where: 'codActividad = ?',
      whereArgs: [activityId],
    );
    for (final axp in axpRows) {
      await db.delete(
        'avagra_actividadxsectorxpisos',
        where: 'codActividadxPiso = ?',
        whereArgs: [axp['codActividadxPiso']],
      );
    }
    await db.delete(
      'avagra_actividadxpisos',
      where: 'codActividad = ?',
      whereArgs: [activityId],
    );
    await db.delete(
      'avagra_actividad',
      where: 'codActividad = ?',
      whereArgs: [activityId],
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase3SectorOnFloor({
    required int sectorFloorId,
    required String name,
    required String abbreviation,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    final rows = await db.query(
      'avagra_sectoresxpisos',
      columns: ['codSector', 'codPiso'],
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return bootstrap();
    final baseCode = _asInt(row['codSector']) ?? 0;
    if (baseCode != _phase3LocalSectorCode) {
      throw Exception(
        'Solo se pueden editar sectores locales creados por piso.',
      );
    }
    final pisoId = _asInt(row['codPiso']) ?? 0;
    final phaseId = await _resolvePhase3IdByFloor(db, pisoId);
    if (phaseId == null) return bootstrap();
    await _assertPhase3Initialized(db, phaseId);

    await db.update(
      'avagra_sectoresxpisos',
      {
        'desNombre': trimmedName,
        'desAbrev': abbreviation.trim(),
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
      },
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_sectoresxpisos',
      entityId: '$sectorFloorId',
      operationType: 'update',
      payload: await _buildAvagraPhase3SectorFloorSyncPayload(
        db,
        sectorFloorId,
      ),
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase3SectorPlanPosition({
    required int sectorFloorId,
    required double xNorm,
    required double yNorm,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'avagra_sectoresxpisos',
      columns: ['codPiso'],
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return bootstrap();

    final clampedX = xNorm.clamp(0.0, 1.0).toDouble();
    final clampedY = yNorm.clamp(0.0, 1.0).toDouble();
    final now = _toLimaIso8601String(DateTime.now());
    final positionJson = jsonEncode(<String, double>{
      'x': clampedX,
      'y': clampedY,
    });

    await db.update(
      'avagra_sectoresxpisos',
      {
        'jsonPosicionamientoPlano': positionJson,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': now,
      },
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_sectoresxpisos',
      entityId: '$sectorFloorId',
      operationType: 'update',
      payload: await _buildAvagraPhase3SectorFloorSyncPayload(
        db,
        sectorFloorId,
      ),
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDownloadPhase3FloorPlan({
    required int floorId,
  }) async {
    final db = await _database.database;
    final floorRows = await db.query(
      'avagra_pisos',
      where: 'codPiso = ?',
      whereArgs: [floorId],
      limit: 1,
    );
    final floorRow = floorRows.firstOrNull;
    if (floorRow == null) return bootstrap();

    final projectId = _asInt(floorRow['codProyecto']) ?? 0;
    final moduleId = _asInt(floorRow['codAvaGrafico']) ?? 0;
    final existingPlanName = (floorRow['desNombrePlano'] as String?)?.trim();

    final session = await _loadSession(db);
    final result = await _avagraApiClient.downloadPhase3FloorPlan(
      floorId: floorId,
      authToken: session?.token,
    );
    if (result.bytes.isEmpty) {
      throw Exception('La descarga de plano devolvio un archivo vacio.');
    }

    var planName = (result.fileName ?? existingPlanName ?? '').trim();
    if (planName.isEmpty) {
      final ext = _extensionFromContentType(result.contentType) ?? 'webp';
      planName = 'piso_$floorId.$ext';
    } else if (!planName.contains('.')) {
      final ext = _extensionFromContentType(result.contentType) ?? 'webp';
      planName = '$planName.$ext';
    }

    final planPath = await _savePhase3PlanBytes(
      projectId: projectId,
      moduleId: moduleId,
      floorId: floorId,
      planName: planName,
      bytes: result.bytes,
    );
    debugPrint(
      '[AppRepository] plano F3 descargado piso=$floorId path=$planPath',
    );

    if (existingPlanName != planName) {
      await db.update(
        'avagra_pisos',
        {
          'desNombrePlano': planName,
          'codUsuarioModificacion': 7,
          'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
        },
        where: 'codPiso = ?',
        whereArgs: [floorId],
      );
    }

    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUploadPhase3FloorPlan({
    required int floorId,
    required String filePath,
  }) async {
    final db = await _database.database;
    final floorRows = await db.query(
      'avagra_pisos',
      where: 'codPiso = ?',
      whereArgs: [floorId],
      limit: 1,
    );
    final floorRow = floorRows.firstOrNull;
    if (floorRow == null) return bootstrap();
    final projectId = _asInt(floorRow['codProyecto']) ?? 0;
    final moduleId = _asInt(floorRow['codAvaGrafico']) ?? 0;

    final session = await _loadSession(db);
    if (session == null || !session.isActive) {
      throw Exception('Necesitas una sesion activa para subir el plano.');
    }

    final upload = await _avagraApiClient.uploadPhase3FloorPlan(
      floorId: floorId,
      filePath: filePath,
      authToken: session.token,
    );
    if (!upload.success) {
      throw Exception(upload.message ?? 'No se pudo subir el plano.');
    }

    var planName = (upload.planName ?? '').trim();
    if (planName.isEmpty) {
      planName = p.basename(filePath);
    }
    final planLink = (upload.planLink ?? '').trim();
    await db.update(
      'avagra_pisos',
      {
        'desNombrePlano': planName,
        'desLinkPlano': planLink.isEmpty ? null : planLink,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
      },
      where: 'codPiso = ?',
      whereArgs: [floorId],
    );

    try {
      final downloaded = await _avagraApiClient.downloadPhase3FloorPlan(
        floorId: floorId,
        authToken: session.token,
      );
      if (downloaded.bytes.isNotEmpty) {
        final downloadedName = (downloaded.fileName ?? '').trim();
        final effectiveName = downloadedName.isNotEmpty
            ? downloadedName
            : planName;
        await _savePhase3PlanBytes(
          projectId: projectId,
          moduleId: moduleId,
          floorId: floorId,
          planName: effectiveName,
          bytes: downloaded.bytes,
        );
        if (effectiveName != planName) {
          await db.update(
            'avagra_pisos',
            {
              'desNombrePlano': effectiveName,
              'codUsuarioModificacion': 7,
              'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
            },
            where: 'codPiso = ?',
            whereArgs: [floorId],
          );
        }
      }
    } catch (error) {
      debugPrint(
        '[AppRepository] fallo descarga posterior a upload, se usara local: $error',
      );
      await _copyPhase3PlanLocalFile(
        projectId: projectId,
        moduleId: moduleId,
        floorId: floorId,
        planName: planName,
        sourceFilePath: filePath,
      );
    }

    await _enqueueSync(
      db,
      entityType: 'avagra_pisos',
      entityId: '$floorId',
      operationType: 'update',
      payload: await _buildAvagraPhase3FloorSyncPayload(db, floorId),
    );

    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase3SectorFromFloor({
    required int sectorFloorId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'avagra_sectoresxpisos',
      columns: ['codSector', 'codPiso'],
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return bootstrap();
    final baseCode = _asInt(row['codSector']) ?? 0;
    if (baseCode != _phase3LocalSectorCode) {
      throw Exception(
        'Solo se pueden eliminar sectores locales creados por piso.',
      );
    }
    final pisoId = _asInt(row['codPiso']) ?? 0;
    final phaseId = await _resolvePhase3IdByFloor(db, pisoId);
    if (phaseId == null) return bootstrap();
    await _assertPhase3Initialized(db, phaseId);

    final sectorPayloadRows = await db.query(
      'avagra_sectoresxpisos',
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
      limit: 1,
    );
    final sectorPayload = sectorPayloadRows.firstOrNull == null
        ? <String, Object?>{'codSectorxPiso': sectorFloorId}
        : Map<String, Object?>.from(sectorPayloadRows.first);
    final cellRows = await db.query(
      'avagra_actividadxsectorxpisos',
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
    final cellPayloads = cellRows
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);

    await db.delete(
      'avagra_actividadxsectorxpisos',
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
    await db.delete(
      'avagra_sectoresxpisos',
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
    for (final payload in cellPayloads) {
      final cellId = _asInt(payload['codActividadxSectorxPiso']);
      if (cellId == null) {
        continue;
      }
      _pendingPhase3CellBaselineById.remove(cellId);
      await _enqueueSync(
        db,
        entityType: 'avagra_actividadxsectorxpisos',
        entityId: '$cellId',
        operationType: 'delete',
        payload: payload,
      );
    }
    await _enqueueSync(
      db,
      entityType: 'avagra_sectoresxpisos',
      entityId: '$sectorFloorId',
      operationType: 'delete',
      payload: sectorPayload,
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoUpdatePhase3ActivityOnFloor({
    required int activityFloorId,
    required String name,
    required String abbreviation,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return bootstrap();
    }
    final db = await _database.database;
    final rows = await db.query(
      'avagra_actividadxpisos',
      columns: ['codActividad', 'codPiso'],
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return bootstrap();
    final baseCode = _asInt(row['codActividad']) ?? 0;
    if (baseCode != _phase3LocalActivityCode) {
      throw Exception(
        'Solo se pueden editar actividades locales creadas por piso.',
      );
    }
    final pisoId = _asInt(row['codPiso']) ?? 0;
    final phaseId = await _resolvePhase3IdByFloor(db, pisoId);
    if (phaseId == null) return bootstrap();
    await _assertPhase3Initialized(db, phaseId);

    final duplicated =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_actividadxpisos
            WHERE codPiso = ? AND codActividadxPiso != ?
              AND LOWER(TRIM(COALESCE(desDescripcion,''))) = LOWER(TRIM(?))
            ''',
            [pisoId, activityFloorId, trimmedName],
          ),
        ) ??
        0;
    if (duplicated > 0) {
      throw Exception('Ya existe una actividad con ese nombre en este piso.');
    }

    await db.update(
      'avagra_actividadxpisos',
      {
        'desAbrev': abbreviation.trim(),
        'desDescripcion': trimmedName,
        'codUsuarioModificacion': 7,
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
      },
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
    );
    await _enqueueSync(
      db,
      entityType: 'avagra_actividadxpisos',
      entityId: '$activityFloorId',
      operationType: 'update',
      payload: await _buildAvagraPhase3ActivityFloorSyncPayload(
        db,
        activityFloorId,
      ),
    );
    return bootstrap();
  }

  Future<AppBootstrapData> avanceGraficoDeletePhase3ActivityFromFloor({
    required int activityFloorId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'avagra_actividadxpisos',
      columns: ['codActividad', 'codPiso', 'numOrden'],
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return bootstrap();
    final baseCode = _asInt(row['codActividad']) ?? 0;
    if (baseCode != _phase3LocalActivityCode) {
      throw Exception(
        'Solo se pueden eliminar actividades locales creadas por piso.',
      );
    }
    final pisoId = _asInt(row['codPiso']) ?? 0;
    final currentOrder = _asInt(row['numOrden']) ?? 0;
    final phaseId = await _resolvePhase3IdByFloor(db, pisoId);
    if (phaseId == null) return bootstrap();
    await _assertPhase3Initialized(db, phaseId);

    final detailRows = await db.query(
      'avagra_actividadxsectorxpisos',
      columns: ['codActividadxSectorxPiso', 'codSectorxPiso'],
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
    );
    final detailPayloads = await db.query(
      'avagra_actividadxsectorxpisos',
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
    );
    final activityPayloadRows = await db.query(
      'avagra_actividadxpisos',
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
      limit: 1,
    );
    final activityPayload = activityPayloadRows.firstOrNull == null
        ? <String, Object?>{'codActividadxPiso': activityFloorId}
        : Map<String, Object?>.from(activityPayloadRows.first);
    final affectedSectorIds = detailRows
        .map((row) => _asInt(row['codSectorxPiso']))
        .whereType<int>()
        .toSet();

    await db.delete(
      'avagra_actividadxsectorxpisos',
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
    );
    await db.delete(
      'avagra_actividadxpisos',
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
    );
    if (currentOrder > 0) {
      await db.rawUpdate(
        '''
        UPDATE avagra_actividadxpisos
        SET numOrden = numOrden - 1,
            dayFechaModificacion = ?,
            codUsuarioModificacion = ?
        WHERE codPiso = ? AND numOrden > ?
        ''',
        [_toLimaIso8601String(DateTime.now()), 7, pisoId, currentOrder],
      );
    }
    for (final sectorFloorId in affectedSectorIds) {
      await _recalculatePhase3SectorProgress(db, sectorFloorId);
    }
    for (final payload in detailPayloads) {
      final cellId = _asInt(payload['codActividadxSectorxPiso']);
      if (cellId == null) {
        continue;
      }
      _pendingPhase3CellBaselineById.remove(cellId);
      await _enqueueSync(
        db,
        entityType: 'avagra_actividadxsectorxpisos',
        entityId: '$cellId',
        operationType: 'delete',
        payload: Map<String, Object?>.from(payload),
      );
    }
    await _enqueueSync(
      db,
      entityType: 'avagra_actividadxpisos',
      entityId: '$activityFloorId',
      operationType: 'delete',
      payload: activityPayload,
    );
    return bootstrap();
  }

  Future<int?> _resolvePhase3IdByFloor(Database db, int pisoId) async {
    final rows = await db.query(
      'avagra_pisos',
      columns: ['codFaseTres'],
      where: 'codPiso = ?',
      whereArgs: [pisoId],
      limit: 1,
    );
    return _asInt(rows.firstOrNull?['codFaseTres']);
  }

  Future<void> _assertPhase3NotInitialized(Database db, int phaseId) async {
    if (await _isPhase3Initialized(db, phaseId)) {
      throw Exception(
        'La configuracion global de Fase 3 ya fue inicializada y no se puede modificar.',
      );
    }
  }

  Future<void> _assertPhase3Initialized(Database db, int phaseId) async {
    if (!await _isPhase3Initialized(db, phaseId)) {
      throw Exception('Primero debes inicializar la configuracion de Fase 3.');
    }
  }

  String? _extensionFromContentType(String? contentType) {
    final normalized = (contentType ?? '').toLowerCase();
    if (normalized.contains('image/webp')) return 'webp';
    if (normalized.contains('image/png')) return 'png';
    if (normalized.contains('image/jpeg')) return 'jpg';
    if (normalized.contains('image/gif')) return 'gif';
    if (normalized.contains('image/svg')) return 'svg';
    return null;
  }

  String _sanitizePlanFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_').trim();
    return sanitized.isEmpty ? 'plano.webp' : sanitized;
  }

  Future<String> _phase3PlanDirectory({
    required int projectId,
    required int moduleId,
  }) async {
    final dbPath = await getDatabasesPath();
    final root = Directory(p.join(p.dirname(dbPath), 'avagra_phase3_planos'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    final moduleFolder = Directory(
      p.join(root.path, '${projectId}_$moduleId'),
    );
    if (!await moduleFolder.exists()) {
      await moduleFolder.create(recursive: true);
    }
    return moduleFolder.path;
  }

  Future<String> _savePhase3PlanBytes({
    required int projectId,
    required int moduleId,
    required int floorId,
    required String planName,
    required List<int> bytes,
  }) async {
    final dir = await _phase3PlanDirectory(
      projectId: projectId,
      moduleId: moduleId,
    );
    final cleanName = _sanitizePlanFileName(planName);
    final target = File(p.join(dir, '${floorId}_$cleanName'));
    await target.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<String> _copyPhase3PlanLocalFile({
    required int projectId,
    required int moduleId,
    required int floorId,
    required String planName,
    required String sourceFilePath,
  }) async {
    final source = File(sourceFilePath);
    if (!await source.exists()) {
      throw Exception(
        'No se encontro el archivo para copiar plano local: $sourceFilePath',
      );
    }
    final bytes = await source.readAsBytes();
    return _savePhase3PlanBytes(
      projectId: projectId,
      moduleId: moduleId,
      floorId: floorId,
      planName: planName,
      bytes: bytes,
    );
  }

  Future<String?> _resolvePhase3PlanLocalPath({
    required int projectId,
    required int moduleId,
    required int floorId,
    required String? planName,
  }) async {
    final trimmedName = (planName ?? '').trim();
    if (trimmedName.isEmpty) return null;
    final dir = await _phase3PlanDirectory(
      projectId: projectId,
      moduleId: moduleId,
    );
    final candidate = File(
      p.join(dir, '${floorId}_${_sanitizePlanFileName(trimmedName)}'),
    );
    if (await candidate.exists()) {
      return candidate.path;
    }
    return null;
  }

  Future<bool> _isPhase3Initialized(Database db, int phaseId) async {
    final rows = await db.query(
      'avagra_fasetres',
      columns: ['numPisos', 'numSectores', 'numActividades'],
      where: 'codFaseTres = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    final row = rows.firstOrNull;
    if (row == null) return false;
    final floors = _asInt(row['numPisos']) ?? 0;
    final sectors = _asInt(row['numSectores']) ?? 0;
    final activities = _asInt(row['numActividades']) ?? 0;
    return floors > 0 && sectors > 0 && activities > 0;
  }

  Future<void> _ensurePhase3LocalPivotTemplates(Database db, String now) async {
    await db.insert('avagra_sectores', {
      'codSector': _phase3LocalSectorCode,
      'desNombre': 'SECTOR_POR_PISO',
      'desDescripcion': 'Plantilla local para sectores por piso',
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('avagra_actividad', {
      'codActividad': _phase3LocalActivityCode,
      'desNombre': 'ACTIVIDAD_POR_PISO',
      'desDescripcion': 'Plantilla local para actividades por piso',
      'codUsuarioCreacion': 7,
      'dayFechaCreacion': now,
      'codUsuarioModificacion': 7,
      'dayFechaModificacion': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _recalculatePhase3SectorProgress(
    Database db,
    int sectorFloorId,
  ) async {
    final rows = await db.query(
      'avagra_actividadxsectorxpisos',
      columns: ['codEstado'],
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
    if (rows.isEmpty) {
      await db.update(
        'avagra_sectoresxpisos',
        {
          'numPorcentajeCompletados': 0.0,
          'numPorcentajeAprobadosCalidad': 0.0,
          'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
          'codUsuarioModificacion': 7,
        },
        where: 'codSectorxPiso = ?',
        whereArgs: [sectorFloorId],
      );
      return;
    }
    final total = rows.length;
    final completed = rows
        .where(
          (row) =>
              (_asInt(row['codEstado']) ?? 0) == _phase3CompletedStatusCode,
        )
        .length;
    final approved = rows
        .where(
          (row) => (_asInt(row['codEstado']) ?? 0) == _phase3ApprovedStatusCode,
        )
        .length;
    final completedPct = total == 0 ? 0.0 : (completed * 100 / total);
    final approvedPct = total == 0 ? 0.0 : (approved * 100 / total);
    await db.update(
      'avagra_sectoresxpisos',
      {
        'numPorcentajeCompletados': completedPct,
        'numPorcentajeAprobadosCalidad': approvedPct,
        'dayFechaModificacion': _toLimaIso8601String(DateTime.now()),
        'codUsuarioModificacion': 7,
      },
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
    );
  }

  Future<AppBootstrapData> syncPendingChanges() async {
    return syncPendingChangesWithLock();
  }

  Future<AppBootstrapData> syncPendingChangesWithLock({
    int lockAttempts = 4,
    Duration lockRetryDelay = const Duration(milliseconds: 600),
    bool failIfBusy = false,
  }) async {
    final db = await _database.database;
    final lockToken = await _acquireRemoteSyncLockWithRetry(
      db,
      attempts: lockAttempts,
      retryDelay: lockRetryDelay,
    );
    if (lockToken == null) {
      if (failIfBusy) {
        throw Exception('Ya hay una sincronizacion en curso. Intenta nuevamente en unos segundos.');
      }
      debugPrint('[AppRepository][sync][lock] skip push busy');
      return bootstrap();
    }
    try {
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
    } finally {
      await _releaseRemoteSyncLock(db, lockToken);
    }
  }

  Future<AppBootstrapData> syncOperationalData({
    int lockAttempts = 4,
    Duration lockRetryDelay = const Duration(milliseconds: 600),
    bool failIfBusy = false,
  }) async {
    final db = await _database.database;
    final lockToken = await _acquireRemoteSyncLockWithRetry(
      db,
      attempts: lockAttempts,
      retryDelay: lockRetryDelay,
    );
    if (lockToken == null) {
      if (failIfBusy) {
        throw Exception('Ya hay una sincronizacion en curso. Intenta nuevamente en unos segundos.');
      }
      debugPrint('[AppRepository][sync][lock] skip operational busy');
      return bootstrap();
    }
    try {
      final preferences = await _loadPreferences(db);
      await _ensureRemoteSyncAllowed(preferences);
      await _normalizeActreuAgreementStatusesForSync(db);
      final session = await _loadSession(db);
      if (session == null || !session.isActive) {
        throw Exception(
          'No hay una sesion activa para sincronizacion operativa.',
        );
      }

      // â”€â”€ Snapshot pre-pull para detecciÃ³n de cambios â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final restrictionSnap = await _snapshotRestrictionStatuses(db);
      final agreementSnap = await _snapshotAgreementStatuses(db);

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
        since: _buildOperationalSinceCursor(preferences.lastSyncAt),
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

      // â”€â”€ Detectar cambios post-pull â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final changeEvents = await _detectSyncChanges(
        db,
        restrictionSnap: restrictionSnap,
        agreementSnap: agreementSnap,
      );

      final data = await bootstrap();
      return AppBootstrapData(
        session: data.session,
        user: data.user,
        projects: data.projects,
        currentProject: data.currentProject,
        snapshot: data.snapshot,
        preferences: data.preferences,
        syncQueue: data.syncQueue,
        syncOverview: data.syncOverview,
        indicatorPrefs: data.indicatorPrefs,
        syncChangeEvents: changeEvents,
      );
    } finally {
      await _releaseRemoteSyncLock(db, lockToken);
    }
  }

  // â”€â”€ Helpers: snapshot + diff â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<int, String>> _snapshotRestrictionStatuses(Database db) async {
    final rows = await db.query(
      'anares_restriction',
      columns: ['codAnaResActividad', 'codEstadoActividad'],
    );
    final map = <int, String>{};
    for (final r in rows) {
      final id = _asInt(r['codAnaResActividad']);
      if (id != null) map[id] = (r['codEstadoActividad'] as String?) ?? '';
    }
    return map;
  }

  Future<Map<int, int>> _snapshotAgreementStatuses(Database db) async {
    final rows = await db.query(
      'actreu_acuerdos',
      columns: ['codActReuAcuerdos', 'codEstado'],
      where: 'IFNULL(deleted, 0) = 0',
    );
    final map = <int, int>{};
    for (final r in rows) {
      final id = _asInt(r['codActReuAcuerdos']);
      if (id != null) map[id] = _asInt(r['codEstado']) ?? 0;
    }
    return map;
  }

  Future<List<SyncChangeEvent>> _detectSyncChanges(
    Database db, {
    required Map<int, String> restrictionSnap,
    required Map<int, int> agreementSnap,
  }) async {
    final events = <SyncChangeEvent>[];

    // â€” Restricciones â€”
    final rRows = await db.query(
      'anares_restriction',
      columns: ['codAnaResActividad', 'codEstadoActividad', 'desActividad'],
    );
    for (final r in rRows) {
      final id = _asInt(r['codAnaResActividad']);
      if (id == null) continue;
      final newStatus = (r['codEstadoActividad'] as String?) ?? '';
      final oldStatus = restrictionSnap[id];
      if (oldStatus != null && oldStatus.isNotEmpty && oldStatus != newStatus) {
        events.add(
          SyncChangeEvent(
            module: 'restrictions',
            entityId: id,
            description: (r['desActividad'] as String?) ?? 'RestricciÃ³n #$id',
            oldStatus: _restrictionStatusLabel(oldStatus),
            newStatus: _restrictionStatusLabel(newStatus),
          ),
        );
      }
    }

    // â€” Acuerdos â€”
    final aRows = await db.query(
      'actreu_acuerdos',
      columns: ['codActReuAcuerdos', 'codEstado', 'desAcuerdo'],
      where: 'IFNULL(deleted, 0) = 0',
    );
    for (final r in aRows) {
      final id = _asInt(r['codActReuAcuerdos']);
      if (id == null) continue;
      final newStatus = _asInt(r['codEstado']) ?? 0;
      final oldStatus = agreementSnap[id];
      if (oldStatus != null && oldStatus != newStatus) {
        events.add(
          SyncChangeEvent(
            module: 'actreu',
            entityId: id,
            description: (r['desAcuerdo'] as String?) ?? 'Acuerdo #$id',
            oldStatus: _agreementStatusLabel(oldStatus),
            newStatus: _agreementStatusLabel(newStatus),
          ),
        );
      }
    }

    return events;
  }

  String _restrictionStatusLabel(String code) {
    switch (code) {
      case '1':
        return 'Pendiente';
      case '2':
        return 'En proceso';
      case '3':
        return 'Completado';
      case '99':
        return 'Eliminado';
      default:
        return code.isNotEmpty ? code : 'Desconocido';
    }
  }

  String _agreementStatusLabel(int code) {
    switch (code) {
      case 1:
        return 'Pendiente';
      case 2:
        return 'Aplazado';
      case 3:
        return 'Cerrado';
      case 4:
        return 'Vencido';
      case 5:
        return 'Aplazado vencido';
      case 6:
        return 'Informativo';
      default:
        return 'Estado $code';
    }
  }

  Future<AppBootstrapData> syncFullData({
    bool markDailyFullSync = false,
    int lockAttempts = 4,
    Duration lockRetryDelay = const Duration(milliseconds: 600),
    bool failIfBusy = false,
  }) async {
    final db = await _database.database;
    final lockToken = await _acquireRemoteSyncLockWithRetry(
      db,
      attempts: lockAttempts,
      retryDelay: lockRetryDelay,
    );
    if (lockToken == null) {
      if (failIfBusy) {
        throw Exception('Ya hay una sincronizacion en curso. Intenta nuevamente en unos segundos.');
      }
      debugPrint('[AppRepository][sync][lock] skip full busy');
      return bootstrap();
    }
    try {
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
    } finally {
      await _releaseRemoteSyncLock(db, lockToken);
    }
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
    // Solo proyectos activos: codEstado = 0 (activo), distinto de 0 = inactivo
    final rows = await db.query(
      'projects_project',
      where: 'codEstado IS NULL OR codEstado = 0',
      orderBy: 'is_last_selected DESC, codProyecto ASC',
    );

    // Estado del mÃ³dulo de restricciones por proyecto:
    // anares_analysis.codEstado = 0 â†’ activo/abierto, != 0 â†’ cerrado
    final analysisRows = await db.query(
      'anares_analysis',
      columns: ['codProyecto', 'codEstado'],
    );
    final restrictionsOpen = <int>{};
    for (final a in analysisRows) {
      final pid = a['codProyecto'] as int;
      final estado = a['codEstado'] as int? ?? 0;
      if (estado == 0) {
        restrictionsOpen.add(pid);
      }
    }

    return rows.map((row) {
      final id = row['codProyecto'] as int;
      return ProjectRecord(
        id: id,
        name: (row['desNombreProyecto'] as String?) ?? '',
        company:
            (row['desEmpresa'] as String?) ??
            (row['des_Empresa'] as String?) ??
            '',
        address: (row['desDireccion'] as String?) ?? '',
        roleLabel: 'Supervisor de obra',
        isLastSelected: (row['is_last_selected'] as int? ?? 0) == 1,
        restrictionsEnabled: restrictionsOpen.contains(id),
      );
    }).toList();
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
      notificationsEnabled:
          (await _loadSetting(db, 'notifications_enabled')) != '0',
      notificationsRestrictionsEnabled:
          (await _loadSetting(db, 'notifications_module_restrictions')) != '0',
      notificationsActreuEnabled:
          (await _loadSetting(db, 'notifications_module_actreu')) != '0',
      indicatorsEnabled: (await _loadSetting(db, 'indicators_enabled')) != '0',
      indicatorsRestrictionsEnabled:
          (await _loadSetting(db, 'indicators_module_restrictions')) != '0',
      indicatorsMilestonesEnabled:
          (await _loadSetting(db, 'indicators_module_hitos')) != '0',
      indicatorsActreuEnabled:
          (await _loadSetting(db, 'indicators_module_actreu')) != '0',
    );
  }

  Future<void> saveNotificationPref(String key, bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, key, enabled ? '1' : '0');
  }

  Future<void> setBackgroundSyncInProgress(bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, 'background_sync_in_progress', enabled ? '1' : '0');
  }

  Future<void> saveIndicatorsEnabled(bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, 'indicators_enabled', enabled ? '1' : '0');
  }

  Future<void> saveIndicatorsModulePref(String key, bool enabled) async {
    final db = await _database.database;
    await _saveSetting(db, key, enabled ? '1' : '0');
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
    final now = _toLimaIso8601String(DateTime.now());
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

  Future<String?> _loadSetting(DatabaseExecutor db, String key) async {
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

  Future<void> _saveSetting(
    DatabaseExecutor db,
    String key,
    String? value,
  ) async {
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': _toLimaIso8601String(DateTime.now()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> _tryAcquireRemoteSyncLock(Database db) async {
    final token =
        '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    final nowUtc = DateTime.now().toUtc();
    final lockUntil = _toLimaIso8601String(nowUtc.add(_remoteSyncLockTimeout));
    var acquired = false;

    await db.transaction((txn) async {
      final lockUntilRaw = await _loadSetting(txn, _remoteSyncLockUntilKey);
      final currentLockUntil = _parseDateTime(lockUntilRaw);
      if (currentLockUntil != null && currentLockUntil.isAfter(nowUtc)) {
        return;
      }

      await _saveSetting(txn, _remoteSyncLockTokenKey, token);
      await _saveSetting(txn, _remoteSyncLockUntilKey, lockUntil);
      acquired = true;
    });

    return acquired ? token : null;
  }

  Future<String?> _acquireRemoteSyncLockWithRetry(
    Database db, {
    int attempts = 1,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    final safeAttempts = attempts < 1 ? 1 : attempts;
    for (var i = 0; i < safeAttempts; i++) {
      final token = await _tryAcquireRemoteSyncLock(db);
      if (token != null) {
        return token;
      }
      if (i + 1 < safeAttempts) {
        await Future<void>.delayed(retryDelay);
      }
    }
    return null;
  }

  Future<void> _releaseRemoteSyncLock(Database db, String? token) async {
    if (token == null) return;

    await db.transaction((txn) async {
      final currentToken = await _loadSetting(txn, _remoteSyncLockTokenKey);
      if (currentToken != token) {
        return;
      }

      await _saveSetting(txn, _remoteSyncLockTokenKey, null);
      await _saveSetting(txn, _remoteSyncLockUntilKey, null);
    });
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

    final requestedAt = _toLimaIso8601String(DateTime.now());
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
    return 'Dispositivo ${userId ?? '-'} Â· $shortId';
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

  Future<Map<String, Object?>> _buildAvagraPhase1SyncPayload(
    Database db,
    int phaseId,
  ) async {
    final rows = await db.query(
      'avagra_faseuno',
      where: 'codFaseUno = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codFaseUno': phaseId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraMasterSyncPayload(
    Database db,
    int moduleId,
  ) async {
    final rows = await db.query(
      'avagra_avancegrafico',
      where: 'codAvaGrafico = ?',
      whereArgs: [moduleId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codAvaGrafico': moduleId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraSectionSyncPayload(
    Database db,
    int sectionId,
  ) async {
    final rows = await db.query(
      'avagra_secciones',
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codSecciones': sectionId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPositionSyncPayload(
    Database db,
    int positionId,
  ) async {
    final rows = await db.query(
      'avagra_posiciones',
      where: 'codPosition = ?',
      whereArgs: [positionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codPosition': positionId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase2SyncPayload(
    Database db,
    int phaseId,
  ) async {
    final rows = await db.query(
      'avagra_fasedos',
      where: 'codFaseDos = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codFaseDos': phaseId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase2ActivitySyncPayload(
    Database db,
    int activityId,
  ) async {
    final rows = await db.query(
      'avagra_actividades',
      where: 'codActividades = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActividades': activityId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase2CellSyncPayload(
    Database db,
    int cellId,
  ) async {
    final rows = await db.query(
      'avagra_cuadros',
      where: 'codCuadros = ?',
      whereArgs: [cellId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codCuadros': cellId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3SyncPayload(
    Database db,
    int phaseId,
  ) async {
    final rows = await db.query(
      'avagra_fasetres',
      where: 'codFaseTres = ?',
      whereArgs: [phaseId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codFaseTres': phaseId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3FloorSyncPayload(
    Database db,
    int floorId,
  ) async {
    final rows = await db.query(
      'avagra_pisos',
      where: 'codPiso = ?',
      whereArgs: [floorId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codPiso': floorId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3SectorSyncPayload(
    Database db,
    int sectorId,
  ) async {
    final rows = await db.query(
      'avagra_sectores',
      where: 'codSector = ?',
      whereArgs: [sectorId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codSector': sectorId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3ActivitySyncPayload(
    Database db,
    int activityId,
  ) async {
    final rows = await db.query(
      'avagra_actividad',
      where: 'codActividad = ?',
      whereArgs: [activityId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActividad': activityId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3SectorFloorSyncPayload(
    Database db,
    int sectorFloorId,
  ) async {
    final rows = await db.query(
      'avagra_sectoresxpisos',
      where: 'codSectorxPiso = ?',
      whereArgs: [sectorFloorId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codSectorxPiso': sectorFloorId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3ActivityFloorSyncPayload(
    Database db,
    int activityFloorId,
  ) async {
    final rows = await db.query(
      'avagra_actividadxpisos',
      where: 'codActividadxPiso = ?',
      whereArgs: [activityFloorId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActividadxPiso': activityFloorId};
    }
    return Map<String, Object?>.from(rows.first);
  }

  Future<Map<String, Object?>> _buildAvagraPhase3CellSyncPayload(
    Database db,
    int cellId,
  ) async {
    final rows = await db.query(
      'avagra_actividadxsectorxpisos',
      where: 'codActividadxSectorxPiso = ?',
      whereArgs: [cellId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {'codActividadxSectorxPiso': cellId};
    }
    return Map<String, Object?>.from(rows.first);
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
    final now = _toLimaIso8601String(DateTime.now());
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
    final restrictionsRows = await db.query(
      'anares_restriction',
      where: '''
          codProyecto = ?
          AND IFNULL(codEstadoActividad, '') != ?
          AND EXISTS (
            SELECT 1
            FROM projects_project p
            WHERE p.codProyecto = anares_restriction.codProyecto
              AND IFNULL(p.codEstado, 0) = 0
          )
          AND (
            NOT EXISTS (
              SELECT 1
              FROM anares_analysis a0
              WHERE a0.codProyecto = anares_restriction.codProyecto
                AND IFNULL(a0.codEstado, 0) = 0
            )
            OR EXISTS (
              SELECT 1
              FROM anares_analysis a
              WHERE a.codProyecto = anares_restriction.codProyecto
                AND a.codAnaRes = anares_restriction.codAnaRes
                AND IFNULL(a.codEstado, 0) = 0
            )
          )
          ''',
      whereArgs: [projectId, '99'],
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
            where:
                'codProyecto = ? AND codConHit = ? AND codConHitGeneral = ? '
                'AND IFNULL(codEstado, 1) = 1',
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
          !milestoneIds.contains(milestoneId)) {
        continue;
      }
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
          !milestoneIds.contains(milestoneId)) {
        continue;
      }
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
    final avanceGraficoData = await _loadAvanceGraficoData(db, projectId);

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
      avanceGraficoData: avanceGraficoData,
    );
  }

  Future<AvanceGraficoData?> _loadAvanceGraficoData(
    Database db,
    int projectId,
  ) async {
    final masterRows = await db.query(
      'avagra_avancegrafico',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
      orderBy: 'codProyecto ASC, codAvaGrafico ASC',
      limit: 1,
    );
    final effectiveMasterRows = masterRows.isEmpty
        ? await db.query(
            'avagra_avancegrafico',
            orderBy: 'codProyecto ASC, codAvaGrafico ASC',
            limit: 1,
          )
        : masterRows;
    if (effectiveMasterRows.isEmpty) {
      return _buildFallbackAvanceGraficoData(projectId);
    }

    final master = effectiveMasterRows.first;
    final moduleId = _asInt(master['codAvaGrafico']) ?? 0;
    final sourceProjectId = _asInt(master['codProyecto']) ?? projectId;
    final selectedView = _asInt(master['vistaSeleccionada']) ?? 0;
    final totalMembers =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM projects_member WHERE codProyecto = ?',
            [sourceProjectId],
          ),
        ) ??
        0;
    final enabledMembers =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM avagra_integrantes
            WHERE codProyecto = ? AND codAvaGrafico = ? AND IFNULL(codEstado, 0) = 1
            ''',
            [sourceProjectId, moduleId],
          ),
        ) ??
        0;

    final stateRows = await db.query(
      'avagra_estados',
      orderBy: 'codEstado ASC',
    );
    final states = stateRows
        .map(
          (row) => AvanceGraficoStateCatalog(
            code: _asInt(row['codEstado']) ?? 0,
            label: (row['desEstado'] as String?) ?? '',
            phaseKey: (row['desFase'] as String?) ?? '',
            colorHex: (row['codColor'] as String?) ?? '#94A3B8',
            colorName: (row['desColor'] as String?) ?? '',
          ),
        )
        .toList();
    final statesByCode = {for (final state in states) state.code: state};

    final phase1 = await _loadAvanceGraficoPhase1(
      db,
      projectId: sourceProjectId,
      moduleId: moduleId,
      statesByCode: statesByCode,
    );
    final phase2 = await _loadAvanceGraficoPhase2(
      db,
      projectId: sourceProjectId,
      moduleId: moduleId,
      statesByCode: statesByCode,
    );
    final phase3 = await _loadAvanceGraficoPhase3(
      db,
      projectId: sourceProjectId,
      moduleId: moduleId,
      statesByCode: statesByCode,
    );

    if (phase1 == null && phase2 == null && phase3 == null) {
      return _buildFallbackAvanceGraficoData(projectId);
    }

    return AvanceGraficoData(
      summary: AvanceGraficoSummary(
        projectId: projectId,
        moduleId: moduleId,
        isActive: (_asInt(master['codEstado']) ?? 1) == 1,
        selectedView: selectedView,
        enabledMembers: enabledMembers,
        totalMembers: totalMembers,
        phase1Completion: phase1 == null
            ? 0
            : _safeRatio(phase1.completedPositions, phase1.totalPositions),
        phase2Completion: phase2 == null
            ? 0
            : _safeRatio(
                selectedView == 1
                    ? phase2.approvedCount
                    : phase2.completedCount,
                phase2.totalCells,
              ),
        phase3Completion: phase3 == null
            ? 0
            : _safeRatio(
                selectedView == 1
                    ? phase3.approvedCount
                    : phase3.completedCount,
                phase3.totalCells,
              ),
      ),
      states: states,
      phase1: phase1,
      phase2: phase2,
      phase3: phase3,
    );
  }

  AvanceGraficoData _buildFallbackAvanceGraficoData(int projectId) {
    return AvanceGraficoData(
      summary: AvanceGraficoSummary(
        projectId: projectId,
        moduleId: 0,
        isActive: false,
        selectedView: 0,
        enabledMembers: 0,
        totalMembers: 0,
        phase1Completion: 0,
        phase2Completion: 0,
        phase3Completion: 0,
      ),
      states: const [],
      phase1: null,
      phase2: null,
      phase3: null,
    );
  }

  Future<AvanceGraficoPhase1Data?> _loadAvanceGraficoPhase1(
    Database db, {
    required int projectId,
    required int moduleId,
    required Map<int, AvanceGraficoStateCatalog> statesByCode,
  }) async {
    final phaseRows = await db.query(
      'avagra_faseuno',
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      limit: 1,
    );
    if (phaseRows.isEmpty) return null;
    final phase = phaseRows.first;
    final phaseId = _asInt(phase['codFaseUno']) ?? 0;
    final phase1States = statesByCode.values
        .where((state) => state.phaseKey == 'FaseUno_Posiciones')
        .toList(growable: false);
    int codeFor(String label, int fallback) {
      final normalized = label.trim().toLowerCase();
      for (final state in phase1States) {
        if (state.label.trim().toLowerCase() == normalized) {
          return state.code;
        }
      }
      return fallback;
    }

    final pendingCode = codeFor('Pendiente', 17);
    final completedCode = codeFor('Completado', 2);
    final scheduledCode = codeFor('Programado Sem. Actual', 18);
    final notApplicableCode = codeFor('No Aplica', 1);

    final shapeLabel = await _lookupSingleLabel(
      db,
      table: 'avagra_forma',
      idColumn: 'CodForma',
      labelColumn: 'DesForma',
      id: _asInt(phase['CodForma']),
    );
    final directionLabel = await _lookupSingleLabel(
      db,
      table: 'avagra_sentidohorario',
      idColumn: 'CodSentido',
      labelColumn: 'DesSentido',
      id: _asInt(phase['CodSentido']),
    );

    final documentCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_faseunodocumentos
            WHERE codProyecto = ? AND codAvaGrafico = ? AND codFaseUno = ?
            ''',
            [projectId, moduleId, phaseId],
          ),
        ) ??
        0;

    final sectionRows = await db.rawQuery(
      '''
      SELECT s.*, tl.DesLado AS desLado
      FROM avagra_secciones s
      LEFT JOIN avagra_tipolado tl ON tl.CodTipoLado = s.CodTipoLado
      WHERE s.codProyecto = ? AND s.codAvaGrafico = ? AND s.codFaseUno = ?
        AND (s.codEstado IS NULL OR s.codEstado != -1)
      ORDER BY IFNULL(s.numOrdenTipoLado, 99), IFNULL(s.CodTipoLado, 99), s.codSecciones
      ''',
      [projectId, moduleId, phaseId],
    );
    final positionRows = await db.rawQuery(
      '''
      SELECT p.*, s.codSecciones
      FROM avagra_posiciones p
      INNER JOIN avagra_secciones s ON s.codSecciones = p.codSecciones
      WHERE s.codProyecto = ? AND s.codAvaGrafico = ? AND s.codFaseUno = ?
        AND (p.codEstado IS NULL OR p.codEstado != -1)
      ORDER BY s.codSecciones, p.numNivel ASC, p.numPanio ASC
      ''',
      [projectId, moduleId, phaseId],
    );
    final positionsBySection = <int, List<Map<String, Object?>>>{};
    for (final row in positionRows) {
      final sectionId = _asInt(row['codSecciones']);
      if (sectionId == null) continue;
      positionsBySection.putIfAbsent(sectionId, () => []).add(row);
    }

    var totalPositions = 0;
    var completedPositions = 0;
    var scheduledPositions = 0;
    var notApplicablePositions = 0;

    final sections = sectionRows.map((row) {
      final sectionId = _asInt(row['codSecciones']) ?? 0;
      final sectionPositions = positionsBySection[sectionId] ?? const [];
      final cells = sectionPositions.map((cellRow) {
        final statusCode = _asInt(cellRow['codEstado']) ?? pendingCode;
        final status = statesByCode[statusCode];
        final level = _asInt(cellRow['numNivel']) ?? 0;
        final bay = _asInt(cellRow['numPanio']) ?? 0;
        final numerationRaw = (cellRow['desNumeracion'] as String?)?.trim();
        if (statusCode == completedCode) completedPositions++;
        if (statusCode == scheduledCode) scheduledPositions++;
        if (statusCode == notApplicableCode) {
          notApplicablePositions++;
        } else {
          totalPositions++;
        }
        return AvanceGraficoPhase1Cell(
          id: _asInt(cellRow['codPosition']) ?? 0,
          level: level,
          bay: bay,
          statusCode: statusCode,
          statusLabel: status?.label ?? 'Pendiente',
          colorHex: status?.colorHex ?? '#BEBEB9',
          numeration: numerationRaw,
        );
      }).toList();
      final sectionValidCount = cells
          .where((item) => item.statusCode != notApplicableCode)
          .length;
      final sectionCompletedCount = cells
          .where((item) => item.statusCode == completedCode)
          .length;
      return AvanceGraficoPhase1Section(
        id: sectionId,
        name: (row['desSecciones'] as String?) ?? '',
        abbreviation: (row['desAbrev'] as String?) ?? '',
        sideLabel: (row['desLado'] as String?) ?? 'Seccion',
        sideCode: _asInt(row['CodTipoLado']) ?? 1,
        levels: _asInt(row['numNiveles']) ?? 0,
        bays: _asInt(row['numPanios']) ?? 0,
        completedCount: sectionCompletedCount,
        totalCount: sectionValidCount,
        cells: cells,
      );
    }).toList();

    final shapeCode = _asInt(phase['CodForma']) ?? 2;
    final directionCode = _asInt(phase['CodSentido']) ?? 1;

    return AvanceGraficoPhase1Data(
      phaseId: phaseId,
      title: (phase['DesFaseUno'] as String?) ?? 'Fase 1',
      comments: (phase['Comentarios'] as String?) ?? '',
      shapeLabel: shapeLabel ?? 'Sin definir',
      shapeCode: shapeCode,
      directionLabel: directionLabel ?? 'Sin definir',
      directionCode: directionCode,
      globalLevelsEnabled: _coerceToBool(phase['flgNivelesGlobales']),
      globalLevelsCount: _asInt(phase['numNivelesGlobales']) ?? 0,
      documentsCount: documentCount,
      totalPositions: totalPositions,
      completedPositions: completedPositions,
      scheduledPositions: scheduledPositions,
      notApplicablePositions: notApplicablePositions,
      sections: sections,
    );
  }

  Future<AvanceGraficoPhase2Data?> _loadAvanceGraficoPhase2(
    Database db, {
    required int projectId,
    required int moduleId,
    required Map<int, AvanceGraficoStateCatalog> statesByCode,
  }) async {
    final phaseRows = await db.query(
      'avagra_fasedos',
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      orderBy: 'codFaseDos DESC',
      limit: 1,
    );
    if (phaseRows.isEmpty) return null;
    final phase = phaseRows.first;
    final phaseId = _asInt(phase['codFaseDos']) ?? 0;
    final phase2States = statesByCode.values
        .where((state) => state.phaseKey == 'FaseDos_Cuadros')
        .toList(growable: false);
    int codeFor(String label, int fallback) {
      final normalized = label.trim().toLowerCase();
      for (final state in phase2States) {
        if (state.label.trim().toLowerCase() == normalized) {
          return state.code;
        }
      }
      return fallback;
    }

    final pendingCode = codeFor('Pendiente', 4);
    final inProgressCode = codeFor('En proceso', 5);
    final completedCode = codeFor('Completado', 6);
    final approvedCode = codeFor('Aprobado por Calidad', 7);
    final scheduledCode = codeFor('Programado Sem. Actual', 8);
    final notApplicableCode = codeFor('No Aplica', 19);

    final documentCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*) FROM avagra_fotos
            WHERE codProyecto = ? AND codAvaGrafico = ? AND codFaseDos = ?
            ''',
            [projectId, moduleId, phaseId],
          ),
        ) ??
        0;

    final activityRows = await db.query(
      'avagra_actividades',
      where: 'codProyecto = ? AND codAvaGrafico = ? AND codFaseDos = ?',
      whereArgs: [projectId, moduleId, phaseId],
      orderBy: 'codActividades ASC',
    );
    final cuadrosRows = await db.rawQuery(
      '''
      SELECT c.*, a.codProyecto
      FROM avagra_cuadros c
      INNER JOIN avagra_actividades a ON a.codActividades = c.codActividades
      WHERE a.codProyecto = ? AND a.codAvaGrafico = ? AND a.codFaseDos = ?
      ORDER BY a.codActividades, c.numPiso DESC, c.numSector ASC
      ''',
      [projectId, moduleId, phaseId],
    );
    final cellsByActivity = <int, List<Map<String, Object?>>>{};
    for (final row in cuadrosRows) {
      final activityId = _asInt(row['codActividades']);
      if (activityId == null) continue;
      cellsByActivity.putIfAbsent(activityId, () => []).add(row);
    }

    var totalCells = 0;
    var completedCount = 0;
    var approvedCount = 0;
    var inProgressCount = 0;
    var pendingCount = 0;

    final activities = activityRows.map((row) {
      final activityId = _asInt(row['codActividades']) ?? 0;
      final activityCells = cellsByActivity[activityId] ?? const [];
      var activityTotal = 0;
      var activityPending = 0;
      var activityInProgress = 0;
      var activityScheduled = 0;
      var activityCompleted = 0;
      var activityApproved = 0;
      var activityNoAplica = 0;
      final cells = activityCells.map((cellRow) {
        final statusCode = _asInt(cellRow['codEstado']) ?? pendingCode;
        final status = statesByCode[statusCode];
        if (statusCode == notApplicableCode) {
          activityNoAplica++;
        } else {
          activityTotal++;
          totalCells++;
        }
        if (statusCode == pendingCode) {
          activityPending++;
          pendingCount++;
        } else if (statusCode == inProgressCode) {
          activityInProgress++;
          inProgressCount++;
        } else if (statusCode == scheduledCode) {
          activityScheduled++;
        } else if (statusCode == completedCode) {
          activityCompleted++;
          completedCount++;
        } else if (statusCode == approvedCode) {
          activityApproved++;
          approvedCount++;
        }
        return AvanceGraficoPhase2Cell(
          id: _asInt(cellRow['codCuadros']) ?? 0,
          floor: _asInt(cellRow['numPiso']) ?? 0,
          sector: _asInt(cellRow['numSector']) ?? 0,
          statusCode: statusCode,
          statusLabel: status?.label ?? 'Pendiente',
          colorHex: status?.colorHex ?? '#BEBEB9',
        );
      }).toList();
      return AvanceGraficoPhase2Activity(
        id: activityId,
        name: (row['desActividades'] as String?) ?? '',
        abbreviation: (row['desAbrev'] as String?) ?? '',
        floors: _asInt(row['numPisos']) ?? 0,
        basements: _asInt(row['sotanos']) ?? 0,
        sectors: _asInt(row['numSectores']) ?? 0,
        totalCells: activityTotal,
        pendingCount: activityPending,
        inProgressCount: activityInProgress,
        scheduledCount: activityScheduled,
        completedCount: activityCompleted,
        approvedCount: activityApproved,
        notApplicableCount: activityNoAplica,
        cells: cells,
      );
    }).toList();

    return AvanceGraficoPhase2Data(
      phaseId: phaseId,
      title: (phase['desFaseDos'] as String?) ?? 'Fase 2',
      comments: (phase['desComentarios'] as String?) ?? '',
      uniformFloorsEnabled: _coerceToBool(phase['flgPisosUniformes']),
      uniformFloorsCount: _asInt(phase['numPisosUniformes']) ?? 0,
      documentsCount: documentCount,
      totalCells: totalCells,
      completedCount: completedCount,
      approvedCount: approvedCount,
      inProgressCount: inProgressCount,
      pendingCount: pendingCount,
      activities: activities,
    );
  }

  Future<AvanceGraficoPhase3Data?> _loadAvanceGraficoPhase3(
    Database db, {
    required int projectId,
    required int moduleId,
    required Map<int, AvanceGraficoStateCatalog> statesByCode,
  }) async {
    final phaseRows = await db.query(
      'avagra_fasetres',
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      limit: 1,
    );
    if (phaseRows.isEmpty) return null;
    final phase = phaseRows.first;
    final phaseId = _asInt(phase['codFaseTres']) ?? 0;
    final phase3States = statesByCode.values
        .where((state) => state.phaseKey == 'FaseTres_ActividadesXSectores')
        .toList(growable: false);
    int codeFor(String label, int fallback) {
      final normalized = label.trim().toLowerCase();
      for (final state in phase3States) {
        if (state.label.trim().toLowerCase() == normalized) {
          return state.code;
        }
      }
      return fallback;
    }

    final pendingCode = codeFor('Pendiente', _phase3PendingStatusCode);
    final inProgressCode = codeFor('En proceso', 13);
    final completedCode = codeFor('Completado', _phase3CompletedStatusCode);
    final approvedCode = codeFor(
      'Aprobado por Calidad',
      _phase3ApprovedStatusCode,
    );
    final notApplicableCode = codeFor('No Aplica', 16);

    final floorRows = await db.query(
      'avagra_pisos',
      where: 'codProyecto = ? AND codAvaGrafico = ? AND codFaseTres = ?',
      whereArgs: [projectId, moduleId, phaseId],
      orderBy: 'numOrden ASC',
    );
    final globalSectorRows = await db.query(
      'avagra_sectores',
      where:
          'codProyecto = ? AND codAvaGrafico = ? AND codFaseTres = ? AND codSector != ?',
      whereArgs: [projectId, moduleId, phaseId, _phase3LocalSectorCode],
      orderBy: 'codSector ASC',
    );
    final globalActivityRows = await db.query(
      'avagra_actividad',
      where:
          'codProyecto = ? AND codAvaGrafico = ? AND codFaseTres = ? AND codActividad != ?',
      whereArgs: [projectId, moduleId, phaseId, _phase3LocalActivityCode],
      orderBy: 'codActividad ASC',
    );
    final sectorRows = await db.rawQuery(
      '''
      SELECT sxp.*, s.desNombre AS sectorBaseNombre, s.desAbrev AS sectorBaseAbrev, s.desDescripcion AS sectorBaseDescripcion
      FROM avagra_sectoresxpisos sxp
      INNER JOIN avagra_pisos p ON p.codPiso = sxp.codPiso
      LEFT JOIN avagra_sectores s ON s.codSector = sxp.codSector
      WHERE p.codProyecto = ? AND p.codAvaGrafico = ? AND p.codFaseTres = ?
      ORDER BY p.numOrden ASC, sxp.codSectorxPiso ASC
      ''',
      [projectId, moduleId, phaseId],
    );
    final activityFloorRows = await db.rawQuery(
      '''
      SELECT axp.*, a.desNombre
      FROM avagra_actividadxpisos axp
      INNER JOIN avagra_pisos p ON p.codPiso = axp.codPiso
      LEFT JOIN avagra_actividad a ON a.codActividad = axp.codActividad
      WHERE p.codProyecto = ? AND p.codAvaGrafico = ? AND p.codFaseTres = ?
      ORDER BY p.numOrden ASC, axp.numOrden ASC
      ''',
      [projectId, moduleId, phaseId],
    );
    final detailRows = await db.rawQuery(
      '''
      SELECT axsp.*, axp.codPiso
      FROM avagra_actividadxsectorxpisos axsp
      INNER JOIN avagra_actividadxpisos axp ON axp.codActividadxPiso = axsp.codActividadxPiso
      INNER JOIN avagra_pisos p ON p.codPiso = axp.codPiso
      WHERE p.codProyecto = ? AND p.codAvaGrafico = ? AND p.codFaseTres = ?
      ORDER BY p.numOrden ASC, axsp.codActividadxSectorxPiso ASC
      ''',
      [projectId, moduleId, phaseId],
    );

    final sectorsByFloor = <int, List<Map<String, Object?>>>{};
    for (final row in sectorRows) {
      final floorId = _asInt(row['codPiso']);
      if (floorId == null) continue;
      sectorsByFloor.putIfAbsent(floorId, () => []).add(row);
    }
    final activitiesByFloor = <int, List<Map<String, Object?>>>{};
    for (final row in activityFloorRows) {
      final floorId = _asInt(row['codPiso']);
      if (floorId == null) continue;
      activitiesByFloor.putIfAbsent(floorId, () => []).add(row);
    }
    final detailByFloor = <int, List<Map<String, Object?>>>{};
    for (final row in detailRows) {
      final floorId = _asInt(row['codPiso']);
      if (floorId == null) continue;
      detailByFloor.putIfAbsent(floorId, () => []).add(row);
    }

    var totalCells = 0;
    var completedCount = 0;
    var approvedCount = 0;
    var inProgressCount = 0;
    var pendingCount = 0;

    final floors = <AvanceGraficoPhase3Floor>[];
    for (final row in floorRows) {
      final floorId = _asInt(row['codPiso']) ?? 0;
      final floorSectorRows = sectorsByFloor[floorId] ?? const [];
      final floorDetailRows = detailByFloor[floorId] ?? const [];
      var floorTotal = 0;
      var floorCompleted = 0;
      var floorApproved = 0;
      var floorInProgress = 0;
      var floorPending = 0;

      for (final detailRow in floorDetailRows) {
        final statusCode = _asInt(detailRow['codEstado']) ?? pendingCode;
        if (statusCode == notApplicableCode) continue;
        floorTotal++;
        totalCells++;
        if (statusCode == pendingCode) {
          floorPending++;
          pendingCount++;
        } else if (statusCode == inProgressCode) {
          floorInProgress++;
          inProgressCount++;
        } else if (statusCode == completedCode) {
          floorCompleted++;
          completedCount++;
        } else if (statusCode == approvedCode) {
          floorApproved++;
          approvedCount++;
        }
      }

      final sectors = floorSectorRows.map((sectorRow) {
        final stateCode = _asInt(sectorRow['codEstado']) ?? pendingCode;
        final state = statesByCode[stateCode];
        return AvanceGraficoPhase3SectorProgress(
          id: _asInt(sectorRow['codSectorxPiso']) ?? 0,
          baseId: _asInt(sectorRow['codSector']) ?? 0,
          name:
              (sectorRow['desNombre'] as String?) ??
              (sectorRow['sectorBaseNombre'] as String?) ??
              'Sector',
          description:
              (sectorRow['desAbrev'] as String?) ??
              (sectorRow['sectorBaseAbrev'] as String?) ??
              (sectorRow['desDescripcion'] as String?) ??
              (sectorRow['sectorBaseDescripcion'] as String?) ??
              '',
          stateLabel: state?.label ?? 'Pendiente',
          completedPercent:
              (_asDouble(sectorRow['numPorcentajeCompletados']) / 100).clamp(
                0,
                1,
              ),
          approvedPercent:
              (_asDouble(sectorRow['numPorcentajeAprobadosCalidad']) / 100)
                  .clamp(0, 1),
          planPositionJson: sectorRow['jsonPosicionamientoPlano'] as String?,
        );
      }).toList();

      // Build activity rows with cells keyed by sectorFloorId
      final floorActivityRows = (activitiesByFloor[floorId] ?? const []).map((
        axpRow,
      ) {
        final axpId = _asInt(axpRow['codActividadxPiso']) ?? 0;
        final cells = floorDetailRows
            .where((d) => _asInt(d['codActividadxPiso']) == axpId)
            .map(
              (d) => AvanceGraficoPhase3Cell(
                id: _asInt(d['codActividadxSectorxPiso']) ?? 0,
                activityFloorId: axpId,
                sectorFloorId: _asInt(d['codSectorxPiso']) ?? 0,
                statusCode: _asInt(d['codEstado']) ?? pendingCode,
              ),
            )
            .toList();
        return AvanceGraficoPhase3ActivityRow(
          id: axpId,
          activityId: _asInt(axpRow['codActividad']) ?? 0,
          name:
              (axpRow['desDescripcion'] as String?) ??
              (axpRow['desNombre'] as String?) ??
              'Actividad',
          abbreviation: (axpRow['desAbrev'] as String?) ?? '',
          order: _asInt(axpRow['numOrden']) ?? 0,
          cells: cells,
        );
      }).toList();

      final planName = row['desNombrePlano'] as String?;
      final planLink = row['desLinkPlano'] as String?;
      final planLocalPath = await _resolvePhase3PlanLocalPath(
        projectId: projectId,
        moduleId: moduleId,
        floorId: floorId,
        planName: planName,
      );

      floors.add(
        AvanceGraficoPhase3Floor(
        id: floorId,
        name: (row['desNombre'] as String?) ?? 'Piso',
        abbreviation: (row['desAbrev'] as String?) ?? '',
        order: _asInt(row['numOrden']) ?? 0,
        planLink: planLink,
        planName: planName,
        planLocalPath: planLocalPath,
        activitiesCount: (activitiesByFloor[floorId] ?? const []).length,
        totalCells: floorTotal,
        completedCount: floorCompleted,
        approvedCount: floorApproved,
        inProgressCount: floorInProgress,
        pendingCount: floorPending,
        sectors: sectors,
        activityRows: floorActivityRows,
      ),
      );
    }

    final globalSectors = globalSectorRows
        .map(
          (row) => AvanceGraficoPhase3GlobalSector(
            id: _asInt(row['codSector']) ?? 0,
            name: (row['desNombre'] as String?) ?? '',
            description:
                (row['desAbrev'] as String?) ??
                (row['desDescripcion'] as String?) ??
                '',
          ),
        )
        .where((sector) => sector.id != 0)
        .toList(growable: false);
    final globalActivities = globalActivityRows
        .map((row) {
          final id = _asInt(row['codActividad']) ?? 0;
          final name = (row['desNombre'] as String?) ?? '';
          final rawAbbreviation = ((row['desDescripcion'] as String?) ?? '')
              .trim();
          final abbreviation = rawAbbreviation.isNotEmpty
              ? rawAbbreviation
              : name
                    .split(' ')
                    .where((word) => word.trim().isNotEmpty)
                    .map((word) => word.trim()[0].toUpperCase())
                    .join();
          return AvanceGraficoPhase3GlobalActivity(
            id: id,
            name: name,
            abbreviation: abbreviation,
          );
        })
        .where((activity) => activity.id != 0)
        .toList(growable: false);
    final uniqueSectorIds = globalSectors.length;
    final uniqueActivityIds = globalActivities.length;
    final configuredFloorCount = _asInt(phase['numPisos']) ?? floorRows.length;
    final configuredSectorCount =
        _asInt(phase['numSectores']) ?? uniqueSectorIds;
    final configuredActivityCount =
        _asInt(phase['numActividades']) ?? uniqueActivityIds;
    final isInitialized =
        configuredFloorCount > 0 &&
        configuredSectorCount > 0 &&
        configuredActivityCount > 0;

    return AvanceGraficoPhase3Data(
      phaseId: phaseId,
      projectId: projectId,
      moduleId: moduleId,
      isInitialized: isInitialized,
      title: (phase['desFaseTres'] as String?) ?? 'Fase 3',
      comments: (phase['desComentarios'] as String?) ?? '',
      floorCount: configuredFloorCount,
      sectorCount: configuredSectorCount,
      activityCount: configuredActivityCount,
      totalCells: totalCells,
      completedCount: completedCount,
      approvedCount: approvedCount,
      inProgressCount: inProgressCount,
      pendingCount: pendingCount,
      globalSectors: globalSectors,
      globalActivities: globalActivities,
      floors: floors,
    );
  }

  Future<String?> _lookupSingleLabel(
    Database db, {
    required String table,
    required String idColumn,
    required String labelColumn,
    required int? id,
  }) async {
    if (id == null) return null;
    final rows = await db.query(
      table,
      columns: [labelColumn],
      where: '$idColumn = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first[labelColumn] as String?;
  }

  bool _coerceToBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is Uint8List && value.isNotEmpty) return value.first == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  double _safeRatio(int numerator, int denominator) {
    if (denominator <= 0) return 0;
    return numerator / denominator;
  }

  Future<_AvagraPhase1Context> _ensureAvagraPhase1Context(
    Database db,
    int preferredProjectId,
  ) async {
    final masterRows = await db.query(
      'avagra_avancegrafico',
      where: 'codProyecto = ?',
      whereArgs: [preferredProjectId],
      limit: 1,
    );
    if (masterRows.isEmpty) {
      throw StateError(
        'No existe cabecera de Avance Grafico para el proyecto. Ejecuta sync pull.',
      );
    }
    final refreshedMasterRows = await db.query(
      'avagra_avancegrafico',
      where: 'codProyecto = ?',
      whereArgs: [preferredProjectId],
      limit: 1,
    );
    if (refreshedMasterRows.isEmpty) {
      throw StateError('No se pudo preparar Avance Grafico para el proyecto');
    }
    final master = refreshedMasterRows.first;
    final projectId = _asInt(master['codProyecto']) ?? preferredProjectId;
    final moduleId = _asInt(master['codAvaGrafico']) ?? 0;

    final phaseRows = await db.query(
      'avagra_faseuno',
      columns: ['codFaseUno'],
      where: 'codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [projectId, moduleId],
      limit: 1,
    );
    if (phaseRows.isNotEmpty) {
      return _AvagraPhase1Context(
        projectId: projectId,
        moduleId: moduleId,
        phase1Id: _asInt(phaseRows.first['codFaseUno']) ?? 0,
      );
    }

    final phase1Id = await _nextAvagraId(db, 'avagra_faseuno', 'codFaseUno');
    final now = _toLimaIso8601String(DateTime.now());
    await db.insert('avagra_faseuno', {
      'codFaseUno': phase1Id,
      'codProyecto': projectId,
      'codAvaGrafico': moduleId,
      'DesFaseUno': 'Configuracion base de Fase 1',
      'Comentarios': 'Creado automaticamente desde movil.',
      'desResOrdenTipoLados': '1-4-2-3',
      'CodForma': 2,
      'CodSentido': 1,
      'dayFechaCreacion': now,
      'codUsuarioCreacion': 'mobile',
      'dayFechaModificacion': now,
      'desUsuarioModificacion': 'mobile',
      'flgNivelesGlobales': 0,
      'numNivelesGlobales': 0,
      'auto_generate_pdf_enabled': 0,
      'auto_generate_pdf_iso_day': 5,
      'auto_generate_pdf_hours': '18:00',
    });
    return _AvagraPhase1Context(
      projectId: projectId,
      moduleId: moduleId,
      phase1Id: phase1Id,
    );
  }

  Future<int> _nextAvagraId(Database db, String table, String idColumn) async {
    final row = (await db.rawQuery(
      'SELECT MAX($idColumn) AS max_id FROM $table',
    )).first;
    return (_asInt(row['max_id']) ?? 0) + 1;
  }

  Future<int> _nextAvagraLocalId(
    Database db,
    String table,
    String idColumn,
  ) async {
    final cursorKey = '$table.$idColumn';
    var candidate =
        _localIdCursorByTable[cursorKey] ??
        DateTime.now().microsecondsSinceEpoch;
    while (true) {
      final exists = Sqflite.firstIntValue(
        await db.rawQuery('SELECT 1 FROM $table WHERE $idColumn = ? LIMIT 1', [
          candidate,
        ]),
      );
      if (exists == null) {
        _localIdCursorByTable[cursorKey] = candidate + 1;
        return candidate;
      }
      candidate++;
    }
  }

  int _defaultAvagraSideOrder(int sideCode) {
    switch (sideCode) {
      case 1:
        return 1; // Superior
      case 4:
        return 2; // Derecha
      case 2:
        return 3; // Inferior
      case 3:
        return 4; // Izquierda
      default:
        return 99;
    }
  }

  Future<int> _nextAvagraSideOrder(
    Database db, {
    required int phase1Id,
    required int projectId,
    required int moduleId,
    required int sideCode,
  }) async {
    final rows = await db.query(
      'avagra_secciones',
      columns: ['CodTipoLado', 'numOrdenTipoLado'],
      where: 'codFaseUno = ? AND codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [phase1Id, projectId, moduleId],
    );
    final sameSideOrder = rows
        .where((r) => _asInt(r['CodTipoLado']) == sideCode)
        .map((r) => _asInt(r['numOrdenTipoLado']) ?? 0)
        .where((value) => value > 0)
        .firstOrNull;
    if (sameSideOrder != null) {
      return sameSideOrder;
    }
    final used = rows
        .map((r) => _asInt(r['numOrdenTipoLado']) ?? 0)
        .where((value) => value > 0)
        .toSet();
    final preferred = _defaultAvagraSideOrder(sideCode);
    if (!used.contains(preferred)) {
      return preferred;
    }
    for (var order = 1; order <= 4; order++) {
      if (!used.contains(order)) {
        return order;
      }
    }
    return preferred;
  }

  Future<int> _resolveAvagraStateCode(
    Database db, {
    required String phaseKey,
    required String label,
    required int fallback,
  }) async {
    final rows = await db.query(
      'avagra_estados',
      columns: ['codEstado'],
      where: "desFase = ? AND LOWER(IFNULL(desEstado, '')) = LOWER(?)",
      whereArgs: [phaseKey, label],
      limit: 1,
    );
    if (rows.isEmpty) {
      return fallback;
    }
    return _asInt(rows.first['codEstado']) ?? fallback;
  }

  String _normalizeAvagraStateLabel(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<Map<String, int>> _loadPhase1PositionStateCodes(Database db) async {
    final rows = await db.query(
      'avagra_estados',
      columns: ['codEstado', 'desEstado'],
      where: 'desFase = ?',
      whereArgs: ['FaseUno_Posiciones'],
      orderBy: 'codEstado ASC',
    );
    final mapped = <String, int>{};
    for (final row in rows) {
      final code = _asInt(row['codEstado']);
      final rawLabel = (row['desEstado'] as String?) ?? '';
      if (code == null) continue;
      mapped[_normalizeAvagraStateLabel(rawLabel)] = code;
    }
    final noAplica = mapped['no aplica'] ?? 1;
    final completado = mapped['completado'] ?? 2;
    final pendiente = mapped['pendiente'] ?? 17;
    final programado = mapped['programado sem. actual'] ?? 18;
    return <String, int>{
      'no_aplica': noAplica,
      'completado': completado,
      'pendiente': pendiente,
      'programado': programado,
    };
  }

  List<int> _buildPhase1CycleOrder(Map<String, int> stateCodes) {
    final ordered = <int>[
      stateCodes['no_aplica'] ?? 1,
      stateCodes['completado'] ?? 2,
      stateCodes['pendiente'] ?? 17,
      stateCodes['programado'] ?? 18,
    ];
    return ordered.toSet().toList(growable: false);
  }

  Future<_AvagraPhase1PositionMutation> _syncAvagraPhase1SectionPositions(
    Database db, {
    required int sectionId,
    required String abbreviation,
    required int levels,
    required int bays,
    required String nowIso,
  }) async {
    final phase1StateCodes = await _loadPhase1PositionStateCodes(db);
    final pendingCode = phase1StateCodes['pendiente'] ?? 17;
    final changedIds = <int>{};
    final createdIds = <int>{};

    final disableRows = await db.query(
      'avagra_posiciones',
      columns: ['codPosition'],
      where:
          'codSecciones = ? AND (numNivel > ? OR numPanio > ?) AND (codEstado IS NULL OR codEstado != -1)',
      whereArgs: [sectionId, levels, bays],
    );
    changedIds.addAll(
      disableRows.map((row) => _asInt(row['codPosition'])).whereType<int>(),
    );
    await db.rawUpdate(
      '''
      UPDATE avagra_posiciones
      SET desNumeracion = NULL,
          codEstado = -1,
          codUsuarioModificacion = ?,
          dayFechaModificacion = ?
      WHERE codSecciones = ?
        AND (numNivel > ? OR numPanio > ?)
      ''',
      ['mobile', nowIso, sectionId, levels, bays],
    );

    final reenableRows = await db.query(
      'avagra_posiciones',
      columns: ['codPosition'],
      where:
          'codSecciones = ? AND numNivel <= ? AND numPanio <= ? AND (codEstado = -1 OR codEstado IS NULL)',
      whereArgs: [sectionId, levels, bays],
    );
    changedIds.addAll(
      reenableRows.map((row) => _asInt(row['codPosition'])).whereType<int>(),
    );
    await db.rawUpdate(
      '''
      UPDATE avagra_posiciones
      SET codEstado = ?,
          codUsuarioModificacion = ?,
          dayFechaModificacion = ?
      WHERE codSecciones = ?
        AND numNivel <= ?
        AND numPanio <= ?
        AND (codEstado = -1 OR codEstado IS NULL)
      ''',
      [pendingCode, 'mobile', nowIso, sectionId, levels, bays],
    );

    final existingRows = await db.query(
      'avagra_posiciones',
      columns: ['numNivel', 'numPanio'],
      where: 'codSecciones = ?',
      whereArgs: [sectionId],
    );
    final existingByGrid = <String, bool>{};
    for (final row in existingRows) {
      final level = _asInt(row['numNivel']);
      final bay = _asInt(row['numPanio']);
      if (level == null || bay == null) continue;
      existingByGrid['$level:$bay'] = true;
    }
    for (var level = 1; level <= levels; level++) {
      for (var bay = 1; bay <= bays; bay++) {
        if (existingByGrid['$level:$bay'] == true) continue;
        final nextId = await _nextAvagraLocalId(
          db,
          'avagra_posiciones',
          'codPosition',
        );
        await db.insert('avagra_posiciones', {
          'codPosition': nextId,
          'codSecciones': sectionId,
          'desNumeracion': null,
          'numNivel': level,
          'numPanio': bay,
          'desPosicion': 'Posicion $level.$bay',
          'desAbrev': '$abbreviation$bay',
          'codEstado': pendingCode,
          'codUsuarioCreacion': 'mobile',
          'dayFechaCreacion': nowIso,
          'codUsuarioModificacion': 'mobile',
          'dayFechaModificacion': nowIso,
        });
        createdIds.add(nextId);
        changedIds.add(nextId);
      }
    }
    return _AvagraPhase1PositionMutation(
      changedIds: changedIds,
      createdIds: createdIds,
    );
  }

  Future<void> _enqueueAvagraPhase1PositionEvents(
    Database db, {
    required Iterable<int> positionIds,
    required Set<int> createIds,
  }) async {
    final uniqueIds = positionIds.toSet();
    for (final positionId in uniqueIds) {
      await _enqueueSync(
        db,
        entityType: 'avagra_posiciones',
        entityId: '$positionId',
        operationType: createIds.contains(positionId) ? 'create' : 'update',
        payload: await _buildAvagraPositionSyncPayload(db, positionId),
      );
    }
  }

  Future<Map<int, _AvagraPhase1PositionSnapshot>>
  _loadAvagraPhase1PositionSnapshot(
    Database db, {
    required int phase1Id,
    required int projectId,
    required int moduleId,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT p.codPosition, p.codEstado, p.desNumeracion
      FROM avagra_posiciones p
      INNER JOIN avagra_secciones s ON s.codSecciones = p.codSecciones
      WHERE s.codFaseUno = ? AND s.codProyecto = ? AND s.codAvaGrafico = ?
      ''',
      [phase1Id, projectId, moduleId],
    );
    final snapshot = <int, _AvagraPhase1PositionSnapshot>{};
    for (final row in rows) {
      final positionId = _asInt(row['codPosition']);
      if (positionId == null) continue;
      snapshot[positionId] = _AvagraPhase1PositionSnapshot(
        statusCode: _asInt(row['codEstado']),
        numeration: row['desNumeracion'] as String?,
      );
    }
    return snapshot;
  }

  Set<int> _collectChangedAvagraPhase1PositionIds({
    required Map<int, _AvagraPhase1PositionSnapshot> baseline,
    required Map<int, _AvagraPhase1PositionSnapshot> current,
  }) {
    final changedIds = <int>{};
    for (final entry in current.entries) {
      final baselineSnapshot = baseline[entry.key];
      if (baselineSnapshot == null || baselineSnapshot != entry.value) {
        changedIds.add(entry.key);
      }
    }
    return changedIds;
  }

  Future<Set<int>> _renumberAvagraPhase1Positions(
    Database db, {
    required int phase1Id,
    required int projectId,
    required int moduleId,
    Set<int>? affectedLevels,
    int? fromSectionOrder,
  }) async {
    if (phase1Id <= 0 || projectId <= 0 || moduleId <= 0) {
      return <int>{};
    }
    final phase1StateCodes = await _loadPhase1PositionStateCodes(db);
    final noAplicaCode = phase1StateCodes['no_aplica'] ?? 1;
    final changedIds = <int>{};
    final targetLevels = affectedLevels?.where((level) => level > 0).toSet();

    final sectionRows = await db.rawQuery(
      '''
      SELECT codSecciones,
             IFNULL(numOrdenTipoLado, 999) AS sectionOrder,
             IFNULL(codEstado, 1) AS sectionState
      FROM avagra_secciones
      WHERE codFaseUno = ? AND codProyecto = ? AND codAvaGrafico = ?
      ORDER BY IFNULL(numOrdenTipoLado, 999) ASC, codSecciones ASC
      ''',
      [phase1Id, projectId, moduleId],
    );

    final updates = <Map<String, Object?>>[];
    final offsetsByLevel = <int, int>{};
    for (final section in sectionRows) {
      final sectionId = _asInt(section['codSecciones']);
      final sectionOrder = _asInt(section['sectionOrder']) ?? 999;
      final sectionState = _asInt(section['sectionState']) ?? 1;
      if (sectionId == null || sectionState == -1) continue;
      final shouldUpdateSection =
          fromSectionOrder == null || sectionOrder >= fromSectionOrder;

      final rows = await db.query(
        'avagra_posiciones',
        columns: [
          'codPosition',
          'numNivel',
          'numPanio',
          'codEstado',
          'desNumeracion',
        ],
        where: 'codSecciones = ?',
        whereArgs: [sectionId],
      );
      if (rows.isEmpty) continue;

      final levelsToProcess = <int>{};
      for (final row in rows) {
        final level = _asInt(row['numNivel']);
        if (level == null || level <= 0) continue;
        if (targetLevels == null || targetLevels.contains(level)) {
          levelsToProcess.add(level);
        }
      }

      final sortedLevels = levelsToProcess.toList()..sort();
      for (final level in sortedLevels) {
        final levelRows = rows
            .where((row) {
              final rowLevel = _asInt(row['numNivel']) ?? 0;
              return rowLevel == level;
            })
            .toList(growable: false);
        if (levelRows.isEmpty) {
          continue;
        }
        final sortedLevelRows = [...levelRows]
          ..sort((a, b) {
            final bayA = _asInt(a['numPanio']) ?? 0;
            final bayB = _asInt(b['numPanio']) ?? 0;
            return bayA.compareTo(bayB);
          });

        var offset = offsetsByLevel[level] ?? 0;
        for (final row in sortedLevelRows) {
          final positionId = _asInt(row['codPosition']);
          final status = _asInt(row['codEstado']);
          if (positionId == null) {
            continue;
          }
          String? nextNumeration;
          if (status != null && status != -1 && status != noAplicaCode) {
            offset++;
            nextNumeration = '$level.$offset';
          }
          if (!shouldUpdateSection) {
            continue;
          }
          final currentNumeration = row['desNumeracion'] as String?;
          if (currentNumeration == nextNumeration) {
            continue;
          }
          changedIds.add(positionId);
          updates.add({'positionId': positionId, 'numeration': nextNumeration});
        }
        offsetsByLevel[level] = offset;
      }
    }

    if (updates.isNotEmpty) {
      final batch = db.batch();
      for (final item in updates) {
        batch.update(
          'avagra_posiciones',
          {'desNumeracion': item['numeration']},
          where: 'codPosition = ?',
          whereArgs: [item['positionId']],
        );
      }
      await batch.commit(noResult: true);
    }
    return changedIds;
  }

  Future<void> _enqueueAvagraPhase2CellEvents(
    Database db, {
    required Iterable<int> cellIds,
    required Set<int> createIds,
  }) async {
    final uniqueIds = cellIds.toSet();
    for (final cellId in uniqueIds) {
      await _enqueueSync(
        db,
        entityType: 'avagra_cuadros',
        entityId: '$cellId',
        operationType: createIds.contains(cellId) ? 'create' : 'update',
        payload: await _buildAvagraPhase2CellSyncPayload(db, cellId),
      );
    }
  }

  Future<void> _enqueueAvagraPhase3CellEvents(
    Database db, {
    required Iterable<int> cellIds,
    required Set<int> createIds,
  }) async {
    final uniqueIds = cellIds.toSet();
    for (final cellId in uniqueIds) {
      await _enqueueSync(
        db,
        entityType: 'avagra_actividadxsectorxpisos',
        entityId: '$cellId',
        operationType: createIds.contains(cellId) ? 'create' : 'update',
        payload: await _buildAvagraPhase3CellSyncPayload(db, cellId),
      );
    }
  }

  Future<void> _enqueuePhase3GlobalConfigCreateEvents(
    Database db, {
    required int phaseId,
    required int projectId,
    required int moduleId,
  }) async {
    final floorRows = await db.query(
      'avagra_pisos',
      columns: ['codPiso'],
      where: 'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ?',
      whereArgs: [phaseId, projectId, moduleId],
      orderBy: 'numOrden ASC, codPiso ASC',
    );
    final sectorRows = await db.query(
      'avagra_sectores',
      columns: ['codSector'],
      where:
          'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ? AND codSector != ?',
      whereArgs: [phaseId, projectId, moduleId, _phase3LocalSectorCode],
      orderBy: 'codSector ASC',
    );
    final activityRows = await db.query(
      'avagra_actividad',
      columns: ['codActividad'],
      where:
          'codFaseTres = ? AND codProyecto = ? AND codAvaGrafico = ? AND codActividad != ?',
      whereArgs: [phaseId, projectId, moduleId, _phase3LocalActivityCode],
      orderBy: 'codActividad ASC',
    );
    final sectorFloorRows = await db.rawQuery(
      '''
      SELECT sxp.codSectorxPiso
      FROM avagra_sectoresxpisos sxp
      INNER JOIN avagra_pisos p ON p.codPiso = sxp.codPiso
      WHERE p.codFaseTres = ? AND p.codProyecto = ? AND p.codAvaGrafico = ?
        AND sxp.codSector != ?
      ORDER BY p.numOrden ASC, sxp.codSectorxPiso ASC
      ''',
      [phaseId, projectId, moduleId, _phase3LocalSectorCode],
    );
    final activityFloorRows = await db.rawQuery(
      '''
      SELECT axp.codActividadxPiso
      FROM avagra_actividadxpisos axp
      INNER JOIN avagra_pisos p ON p.codPiso = axp.codPiso
      WHERE p.codFaseTres = ? AND p.codProyecto = ? AND p.codAvaGrafico = ?
        AND axp.codActividad != ?
      ORDER BY p.numOrden ASC, axp.numOrden ASC, axp.codActividadxPiso ASC
      ''',
      [phaseId, projectId, moduleId, _phase3LocalActivityCode],
    );
    final cellRows = await db.rawQuery(
      '''
      SELECT axsp.codActividadxSectorxPiso
      FROM avagra_actividadxsectorxpisos axsp
      INNER JOIN avagra_actividadxpisos axp ON axp.codActividadxPiso = axsp.codActividadxPiso
      INNER JOIN avagra_sectoresxpisos sxp ON sxp.codSectorxPiso = axsp.codSectorxPiso
      INNER JOIN avagra_pisos p ON p.codPiso = axp.codPiso
      WHERE p.codFaseTres = ? AND p.codProyecto = ? AND p.codAvaGrafico = ?
        AND axp.codActividad != ?
        AND sxp.codSector != ?
      ORDER BY p.numOrden ASC, axsp.codActividadxSectorxPiso ASC
      ''',
      [
        phaseId,
        projectId,
        moduleId,
        _phase3LocalActivityCode,
        _phase3LocalSectorCode,
      ],
    );

    for (final row in floorRows) {
      final floorId = _asInt(row['codPiso']);
      if (floorId == null) continue;
      await _enqueueSync(
        db,
        entityType: 'avagra_pisos',
        entityId: '$floorId',
        operationType: 'create',
        payload: await _buildAvagraPhase3FloorSyncPayload(db, floorId),
      );
    }

    for (final row in sectorRows) {
      final sectorId = _asInt(row['codSector']);
      if (sectorId == null) continue;
      await _enqueueSync(
        db,
        entityType: 'avagra_sectores',
        entityId: '$sectorId',
        operationType: 'create',
        payload: await _buildAvagraPhase3SectorSyncPayload(db, sectorId),
      );
    }

    for (final row in activityRows) {
      final activityId = _asInt(row['codActividad']);
      if (activityId == null) continue;
      await _enqueueSync(
        db,
        entityType: 'avagra_actividad',
        entityId: '$activityId',
        operationType: 'create',
        payload: await _buildAvagraPhase3ActivitySyncPayload(db, activityId),
      );
    }

    for (final row in sectorFloorRows) {
      final sectorFloorId = _asInt(row['codSectorxPiso']);
      if (sectorFloorId == null) continue;
      await _enqueueSync(
        db,
        entityType: 'avagra_sectoresxpisos',
        entityId: '$sectorFloorId',
        operationType: 'create',
        payload: await _buildAvagraPhase3SectorFloorSyncPayload(
          db,
          sectorFloorId,
        ),
      );
    }

    for (final row in activityFloorRows) {
      final activityFloorId = _asInt(row['codActividadxPiso']);
      if (activityFloorId == null) continue;
      await _enqueueSync(
        db,
        entityType: 'avagra_actividadxpisos',
        entityId: '$activityFloorId',
        operationType: 'create',
        payload: await _buildAvagraPhase3ActivityFloorSyncPayload(
          db,
          activityFloorId,
        ),
      );
    }

    final cellIds = cellRows
        .map((row) => _asInt(row['codActividadxSectorxPiso']))
        .whereType<int>()
        .toSet();
    await _enqueueAvagraPhase3CellEvents(
      db,
      cellIds: cellIds,
      createIds: cellIds,
    );
  }

  Future<_AvagraPhase2CellMutation> _syncAvagraPhase2ActivityCells(
    Database db, {
    required int activityId,
    required int floors,
    required int basements,
    required int sectors,
    required String nowIso,
  }) async {
    final pendingCode = await _resolveAvagraStateCode(
      db,
      phaseKey: 'FaseDos_Cuadros',
      label: 'Pendiente',
      fallback: 4,
    );
    final existingRows = await db.query(
      'avagra_cuadros',
      where: 'codActividades = ?',
      whereArgs: [activityId],
    );
    final existingByKey = <String, Map<String, Object?>>{};
    for (final row in existingRows) {
      final floor = _asInt(row['numPiso']);
      final sector = _asInt(row['numSector']);
      if (floor == null || sector == null) continue;
      existingByKey['$floor:$sector'] = row;
    }
    final floorAxis = <int>[
      for (var floor = floors; floor >= 1; floor--) floor,
      for (var basement = 1; basement <= basements; basement++) -basement,
    ];
    final desiredKeys = <String>{};
    for (final floor in floorAxis) {
      for (var sector = 1; sector <= sectors; sector++) {
        desiredKeys.add('$floor:$sector');
      }
    }
    final deletedPayloads = <Map<String, Object?>>[];
    for (final entry in existingByKey.entries) {
      if (!desiredKeys.contains(entry.key)) {
        deletedPayloads.add(Map<String, Object?>.from(entry.value));
      }
    }
    if (deletedPayloads.isNotEmpty) {
      final deleteBatch = db.batch();
      for (final payload in deletedPayloads) {
        final cellId = _asInt(payload['codCuadros']);
        if (cellId == null) continue;
        deleteBatch.delete(
          'avagra_cuadros',
          where: 'codCuadros = ?',
          whereArgs: [cellId],
        );
      }
      await deleteBatch.commit(noResult: true);
    }
    final createdIds = <int>{};
    var order = 0;
    final upsertBatch = db.batch();
    for (final floor in floorAxis) {
      for (var sector = 1; sector <= sectors; sector++) {
        order++;
        final existing = existingByKey['$floor:$sector'];
        if (existing == null) {
          final cellId = await _nextAvagraLocalId(
            db,
            'avagra_cuadros',
            'codCuadros',
          );
          createdIds.add(cellId);
          upsertBatch.insert('avagra_cuadros', {
            'codCuadros': cellId,
            'codActividades': activityId,
            'numOrden': order,
            'numPiso': floor,
            'numSector': sector,
            'codUsuarioCreacion': 'mobile',
            'dayFechaCreacion': nowIso,
            'codUsuarioModificacion': 'mobile',
            'dayFechaModificacion': nowIso,
            'codEstado': pendingCode,
          });
        } else {
          final cellId = _asInt(existing['codCuadros']);
          if (cellId == null) continue;
          upsertBatch.update(
            'avagra_cuadros',
            {
              'numOrden': order,
              'codUsuarioModificacion': 'mobile',
              'dayFechaModificacion': nowIso,
            },
            where: 'codCuadros = ?',
            whereArgs: [cellId],
          );
        }
      }
    }
    await upsertBatch.commit(noResult: true);
    return _AvagraPhase2CellMutation(
      createdIds: createdIds,
      deletedPayloads: deletedPayloads,
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

  Future<List<InsightRuleConfigRecord>> loadInsightRuleConfigs({
    required int userId,
    required ModuleInsightModule module,
  }) async {
    final db = await _database.database;
    return _loadInsightRuleConfigsImpl(
      this,
      db,
      userId: userId,
      module: module,
    );
  }

  Future<void> saveInsightRuleConfig({
    required int userId,
    required ModuleInsightModule module,
    required String ruleKey,
    required bool isEnabled,
    required Map<String, int> thresholds,
  }) async {
    final db = await _database.database;
    await _saveInsightRuleConfigImpl(
      this,
      db,
      userId: userId,
      module: module,
      ruleKey: ruleKey,
      isEnabled: isEnabled,
      thresholds: thresholds,
    );
    await _recalculateModuleInsights(db);
  }

  /// Saves multiple rule configs sequentially then recalculates insights.
  Future<void> saveInsightRuleConfigBatch({
    required int userId,
    required List<InsightRuleConfigRecord> records,
  }) async {
    final db = await _database.database;
    for (final r in records) {
      await _saveInsightRuleConfigImpl(
        this,
        db,
        userId: userId,
        module: r.module,
        ruleKey: r.ruleKey,
        isEnabled: r.isEnabled,
        thresholds: r.thresholds,
      );
    }
    await _recalculateModuleInsights(db);
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
    final fronts = await db.query(
      'anares_front',
      where: '''
          codProyecto = ?
          AND EXISTS (
            SELECT 1
            FROM projects_project p
            WHERE p.codProyecto = anares_front.codProyecto
              AND IFNULL(p.codEstado, 0) = 0
          )
          AND (
            NOT EXISTS (
              SELECT 1
              FROM anares_analysis a0
              WHERE a0.codProyecto = anares_front.codProyecto
                AND IFNULL(a0.codEstado, 0) = 0
            )
            OR EXISTS (
              SELECT 1
              FROM anares_analysis a
              WHERE a.codProyecto = anares_front.codProyecto
                AND a.codAnaRes = anares_front.codAnaRes
                AND IFNULL(a.codEstado, 0) = 0
            )
          )
          ''',
      whereArgs: [projectId],
      orderBy: 'codAnaResFrente ASC',
    );
    final phases = await db.query(
      'anares_phase',
      where: '''
          codProyecto = ?
          AND EXISTS (
            SELECT 1
            FROM projects_project p
            WHERE p.codProyecto = anares_phase.codProyecto
              AND IFNULL(p.codEstado, 0) = 0
          )
          AND (
            NOT EXISTS (
              SELECT 1
              FROM anares_analysis a0
              WHERE a0.codProyecto = anares_phase.codProyecto
                AND IFNULL(a0.codEstado, 0) = 0
            )
            OR EXISTS (
              SELECT 1
              FROM anares_analysis a
              WHERE a.codProyecto = anares_phase.codProyecto
                AND a.codAnaRes = anares_phase.codAnaRes
                AND IFNULL(a.codEstado, 0) = 0
            )
          )
          ''',
      whereArgs: [projectId],
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
    // Fecha de referencia para vencimiento: conciliada si existe, sino requerida
    final refDate = conciliatedDate ?? requiredDate;
    final rawStatusCode = (row['codEstadoActividad'] as String?) ?? '';
    final statusLabel = (row['desEstadoActividad'] as String?) ?? 'Pendiente';
    final statusKind = _restrictionStatusKind(
      rawStatusCode,
      statusLabel: statusLabel,
    );
    final isCompleted = statusKind == 'completed';
    final derivedOverdue = !isCompleted && _isPastDate(refDate);
    final derivedDueToday =
        !isCompleted && !derivedOverdue && _isToday(refDate);

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
      isCompleted: isCompleted,
      isOverdue: derivedOverdue,
      isDueToday: derivedDueToday,
      // Pendiente/En curso excluyen a los vencidos
      isPending: statusKind == 'pending' && !derivedOverdue,
      isInProgress: statusKind == 'in_progress' && !derivedOverdue,
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
      totalDays: row['numDiasPlazoTotal'] as int? ?? 0,
      totalAmount: _asDouble(row['mntTotal']),
      controversyDays: row['numDias'] as int? ?? 0,
      statusCode: _asString(row['codEstado']) ?? '1',
      appliesToGeneral: (row['flgAplicaHitoGeneral'] as int? ?? 0) == 1,
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
        .where((item) => item.isPenalizable && item.classificationCode == 2)
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

  Future<bool> _recalculateMilestoneDerivedFields(
    Database db,
    int milestoneId, {
    bool markAsDirty = false,
  }) async {
    final rows = await db.query(
      'conhit_detallehitos',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final row = rows.first;
    final generalId = _asInt(row['codConHitGeneral']);
    final generalRows = generalId == null
        ? const <Map<String, Object?>>[]
        : await db.query(
            'conhit_general',
            columns: [
              'mntTotal',
              'dayFechaInicioContractual',
              'flgAplicaHitoGeneral',
            ],
            where: 'codConHitGeneral = ?',
            whereArgs: [generalId],
            limit: 1,
          );
    final generalIsActive =
        generalRows.isNotEmpty &&
        (generalRows.first['flgAplicaHitoGeneral'] as int? ?? 0) == 1;
    if (!generalIsActive) {
      return false;
    }
    final startDate = generalRows.isEmpty
        ? null
        : _parseDate(generalRows.first['dayFechaInicioContractual'] as String?);
    final totalAmount =
        generalIsActive && _asInt(row['codTipoClasificacion']) == 2
        ? (generalRows.isEmpty ? 0.0 : _asDouble(generalRows.first['mntTotal']))
        : 0.0;
    final derived = _calculateMilestoneDerivedData(
      row,
      totalAmount: totalAmount,
    );
    final contractualDate =
        _parseDate(row['dayFechaContractualAmp'] as String?) ??
        _parseDate(row['dayFechaContractual'] as String?);
    final updates = <String, Object?>{
      'codEstadoContractual': derived.contractualStatusCode,
      'codEstadoInternos': derived.internalStatusCode,
      'mntPealidad': derived.penaltyAmount,
    };
    if (markAsDirty) {
      final now = _toLimaIso8601String(DateTime.now());
      updates['dayFechaModificacion'] = now;
      updates['desUsuarioModificacion'] = 'mobile';
      updates['sync_status'] = 'pending';
      updates['updated_at'] = now;
    }
    if (generalIsActive) {
      updates['numplazo'] = startDate != null && contractualDate != null
          ? contractualDate.difference(startDate).inDays
          : null;
    }

    await db.update(
      'conhit_detallehitos',
      updates,
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );
    return true;
  }

  Future<void> _recalculateAllMilestonesFromGeneral(
    Database db, {
    required int projectId,
    required DateTime? previousStartDate,
    DateTime? newStartDate,
    required double previousTotalAmount,
    required double newTotalAmount,
    required bool previousAppliesToGeneral,
    required bool newAppliesToGeneral,
  }) async {
    final startDateChanged =
        _formatDateOrNull(previousStartDate) != _formatDateOrNull(newStartDate);
    final totalAmountChanged = previousTotalAmount != newTotalAmount;
    final appliesChanged = previousAppliesToGeneral != newAppliesToGeneral;
    if (!startDateChanged && !totalAmountChanged && !appliesChanged) return;
    if (!newAppliesToGeneral) return;

    final milestoneRows = await db.query(
      'conhit_detallehitos',
      columns: ['codConHitDetalleHitos', 'codTipoClasificacion'],
      where: 'codProyecto = ? AND IFNULL(codEstado, 1) = 1',
      whereArgs: [projectId],
    );

    final onlyPenaltyAmountChanged =
        totalAmountChanged && !startDateChanged && !appliesChanged;

    for (final row in milestoneRows) {
      final milestoneId = row['codConHitDetalleHitos'] as int?;
      if (milestoneId == null) {
        continue;
      }
      if (onlyPenaltyAmountChanged &&
          _asInt(row['codTipoClasificacion']) != 2) {
        continue;
      }
      final recalculated = await _recalculateMilestoneDerivedFields(
        db,
        milestoneId,
        markAsDirty: true,
      );
      if (!recalculated) {
        continue;
      }
      await _enqueueSync(
        db,
        entityType: 'milestone',
        entityId: '$milestoneId',
        operationType: 'update',
        payload: await _buildMilestoneSyncPayload(db, milestoneId),
      );
    }
  }

  String? _formatDateOrNull(DateTime? value) {
    if (value == null) return null;
    return _formatDate(value);
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
    final now = _toLimaIso8601String(DateTime.now());
    for (final row in rows) {
      final id = row['codAnaResActividad'] as int;
      final statusCode = (row['codEstadoActividad'] as String?) ?? '';
      final statusLabel = (row['desEstadoActividad'] as String?) ?? '';
      final statusKind = _restrictionStatusKind(
        statusCode,
        statusLabel: statusLabel,
      );
      final requiredDate = _parseDate(row['dayFechaRequerida'] as String?);
      final conciliatedDate = _parseDate(row['dayFechaConciliada'] as String?);
      // Fecha de referencia: conciliada si existe, sino requerida
      final refDate = conciliatedDate ?? requiredDate;
      final completed = statusKind == 'completed';
      final overdue = !completed && refDate != null && _isPastDate(refDate);
      final dueToday =
          !completed && !overdue && refDate != null && _isToday(refDate);
      await db.update(
        'anares_restriction',
        {
          'is_completed': completed ? 1 : 0,
          'is_overdue': overdue ? 1 : 0,
          'is_due_today': dueToday ? 1 : 0,
          // Pendiente/En curso excluyen a los vencidos
          'is_pending': (statusKind == 'pending' && !overdue) ? 1 : 0,
          'is_in_progress': (statusKind == 'in_progress' && !overdue) ? 1 : 0,
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
    final now = _toLimaIso8601String(DateTime.now());
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
    // ConvenciÃ³n:
    // 1 => el registro tiene linaje local (naciÃ³/depende de algo aÃºn no sincronizado).
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
    final capturedAt = _toLimaIso8601String(DateTime.now());
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

class _AvagraPhase1Context {
  const _AvagraPhase1Context({
    required this.projectId,
    required this.moduleId,
    required this.phase1Id,
  });

  final int projectId;
  final int moduleId;
  final int phase1Id;
}

class _AvagraPhase1PositionMutation {
  const _AvagraPhase1PositionMutation({
    required this.changedIds,
    required this.createdIds,
  });

  const _AvagraPhase1PositionMutation.empty()
    : changedIds = const <int>{},
      createdIds = const <int>{};

  final Set<int> changedIds;
  final Set<int> createdIds;
}

class _AvagraPhase1PositionSnapshot {
  const _AvagraPhase1PositionSnapshot({
    required this.statusCode,
    required this.numeration,
  });

  final int? statusCode;
  final String? numeration;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AvagraPhase1PositionSnapshot &&
        other.statusCode == statusCode &&
        other.numeration == numeration;
  }

  @override
  int get hashCode => Object.hash(statusCode, numeration);
}

class _AvagraPhase2CellMutation {
  const _AvagraPhase2CellMutation({
    required this.createdIds,
    required this.deletedPayloads,
  });

  final Set<int> createdIds;
  final List<Map<String, Object?>> deletedPayloads;
}
