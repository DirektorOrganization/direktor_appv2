import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      'agreements=${snapshot?.agreements.length ?? 0}',
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
    final catalogs = await _loadCatalogs(db, currentProjectId);
    final front = catalogs.fronts.firstWhere((item) => item.id == draft.frontId);
    final phase = catalogs.phases.firstWhere((item) => item.id == draft.phaseId);
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
    final offlineMode = await _loadSetting(db, 'offline_mode');
    final remoteSyncEnabled = await _loadSetting(db, 'remote_sync_enabled');
    final currentProjectId = await _loadCurrentProjectId(db);
    final lastSyncAt = _parseDateTime(await _loadSetting(db, 'last_sync_at'));
    final hasNetwork = await _syncApiClient.hasInternet();
    return AppPreferences(
      keepSignedIn: keepSignedIn != '0',
      isOfflineMode: offlineMode == '1',
      isOfflineForced: !hasNetwork,
      hasNetwork: hasNetwork,
      apiConfigured: _syncApiClient.isConfigured,
      remoteSyncEnabled: remoteSyncEnabled != '0',
      currentProjectId: currentProjectId,
      lastSyncAt: lastSyncAt,
      lastDailyFullSyncBusinessDate: await _loadSetting(db, 'last_daily_full_sync_business_date'),
    );
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

  Future<void> _clearLocalDataForFreshUser(Database db) async {
    await db.transaction((txn) async {
      for (final table in [
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
    final restrictionsRows = await db.query(
      'anares_restriction',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
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

    debugPrint(
      '[AppRepository] snapshot project=$projectId '
      'catalogFronts=${catalogs.fronts.length} catalogPhases=${catalogs.phases.length} '
      'catalogAreas=${catalogs.areas.length} restrictions=${restrictions.length} '
      'meetings=${meetings.length} agreements=${agreements.length}',
    );

    return ProjectSnapshot(
      summary: summary,
      restrictions: restrictions,
      completedRestrictions: completed,
      meetingSummary: meetingSummary,
      meetings: meetings,
      agreements: agreements,
      catalogs: catalogs,
    );
  }

  Future<RestrictionCatalogs> _loadCatalogs(Database db, int projectId) async {
    final fronts = await db.query('anares_front', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'codAnaResFrente ASC');
    final phases = await db.query('anares_phase', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'codAnaResFase ASC');
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
        fronts.map((row) => CatalogOption(id: '${row['codAnaResFrente']}', label: (row['desAnaResFrente'] as String?) ?? '')).toList(),
      ),
      phases: _distinctCatalogOptions(
        phases.map((row) => CatalogOption(id: '${row['codAnaResFase']}', label: (row['desAnaResFase'] as String?) ?? '', colorHex: row['bgColor'] as String?)).toList(),
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
      where: projectId == null ? null : 'codProyecto = ?',
      whereArgs: projectId == null ? null : [projectId],
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
          'payload_json': jsonEncode(payload),
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
      'payload_json': jsonEncode(payload),
      'status': 'pending',
      'retry_count': 0,
      'created_at': now,
      'updated_at': now,
    });
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
      'comments=${_asMapList(result.payload['comments']).length}',
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

    if (scope == 'full') {
      final anares = _asMap(payload['anares']);
      final actreu = _asMap(payload['actreu']);
      final catalogs = _asMap(payload['catalogs']);

      await _applyAreaMembers(
        txn,
        _asMapList(anares.isNotEmpty ? anares['areas'] : catalogs['areas']),
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
    }

    await _applyRestrictions(txn, _asMapList(payload['restrictions']));
    await _applyMeetings(txn, _asMapList(payload['meetings']));
    await _applyAgreements(txn, _asMapList(payload['agreements']));
    await _applyComments(txn, _asMapList(payload['comments']));
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
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping front $id because project $projectId is missing locally');
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
          'codAnaRes': _asInt(row['codAnaRes'] ?? row['codAnares']),
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
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping phase $id because project $projectId is missing locally');
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
          'codAnaResFrente': _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']),
          'codProyecto': projectId,
          'codAnaRes': _asInt(row['codAnaRes'] ?? row['codAnares']),
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
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint('[AppRepository] skipping restriction $id because project $projectId is missing locally');
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
          'codAnaRes': _asInt(row['codAnaRes'] ?? row['codAnares']),
          'codAnaResFrente': _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']),
          'codAnaResFase': _asInt(row['codAnaResFase'] ?? row['codAnaresFase']),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}




