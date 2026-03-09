import 'dart:convert';

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
    final user = await _loadUser(db, session?.userId ?? 7);
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
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    if (!preferences.isOfflineEffective && _authApiClient.isConfigured) {
      final remote = await _authApiClient.login(
        userOrEmail: userOrEmail,
        password: password,
        keepSignedIn: keepSignedIn,
      );
      await _persistRemoteLogin(
        db,
        remote,
        password: password,
        keepSignedIn: keepSignedIn,
      );
      return bootstrap();
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
        ..._statusFlags(statusCode),
      },
      where: 'codAnaResActividad = ?',
      whereArgs: [restrictionId],
    );
    await _enqueueSync(
      db,
      entityType: 'restriction',
      entityId: '$restrictionId',
      operationType: 'status_update',
      payload: {'codAnaResActividad': restrictionId, 'codEstadoActividad': statusCode},
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
    final flags = _statusFlags(draft.statusCode);

    if (draft.id == null) {
      final nextId = (Sqflite.firstIntValue(await db.rawQuery('SELECT MAX(codAnaResActividad) FROM anares_restriction')) ?? 400) + 1;
      await db.insert('anares_restriction', {
        'codAnaResActividad': nextId,
        'codProyecto': currentProjectId,
        'codAnaResFrente': int.tryParse(draft.frontId),
        'codAnaResFase': int.tryParse(draft.phaseId),
        'codArea': draft.areaCode,
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
        payload: {'codAnaResActividad': nextId},
      );
    } else {
      await db.update(
        'anares_restriction',
        {
          'codAnaResFrente': int.tryParse(draft.frontId),
          'codAnaResFase': int.tryParse(draft.phaseId),
          'codArea': draft.areaCode,
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
        payload: {'codAnaResActividad': draft.id},
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
    return syncOperationalData();
  }

  Future<AppBootstrapData> syncOperationalData() async {
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    await _ensureRemoteSyncAllowed(preferences);

    final queue = await db.query('sync_queue', where: "status IN ('pending', 'failed')", orderBy: 'created_at ASC, id ASC');
    final userId = (await _loadSession(db))?.userId ?? 7;

    if (queue.isNotEmpty) {
      await _pushQueue(db, queue: queue, userId: userId);
    }

    await _pullRemoteData(
      db,
      userId: userId,
      scope: 'operational',
      businessDate: _currentBusinessDateKey(),
      since: preferences.lastSyncAt?.toIso8601String(),
    );

    return bootstrap();
  }

  Future<AppBootstrapData> syncFullData({bool markDailyFullSync = false}) async {
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    final queue = await db.query('sync_queue', where: "status IN ('pending', 'failed')", orderBy: 'created_at ASC, id ASC');
    final userId = (await _loadSession(db))?.userId ?? 7;
    await _ensureRemoteSyncAllowed(preferences);

    if (queue.isNotEmpty) {
      await _pushQueue(db, queue: queue, userId: userId);
    }

    await _pullRemoteData(
      db,
      userId: userId,
      scope: 'full',
      businessDate: _currentBusinessDateKey(),
      since: null,
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
            company: (row['desEmpresa'] as String?) ?? '',
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

  Future<String?> _loadSetting(Database db, String key) async {
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _saveSetting(Database db, String key, String? value) async {
    await db.insert(
      'app_settings',
      {'key': key, 'value': value, 'updated_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
          'nombreempresa': remote.user['nombreempresa'],
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
            status: (row['codEstado'] as String?) ?? 'pending',
            dueDate: _parseDate(row['dayFechaAcuerdo'] as String?),
            isOverdue: (row['is_overdue'] as int? ?? 0) == 1,
            isPending: (row['is_pending'] as int? ?? 0) == 1,
            isCompleted: (row['is_completed'] as int? ?? 0) == 1,
          ),
        )
        .toList();

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
    final areas = await db.query('projects_area_member', orderBy: 'codArea ASC');
    final types = await db.query('anares_type', orderBy: 'codTipoRestriccion ASC');
    final responsibles = await db.query('projects_member', where: 'codProyecto = ?', whereArgs: [projectId], orderBy: 'codProyIntegrante ASC');
    final statuses = await db.query('anares_status', where: 'codEstado IN (?, ?, ?)', whereArgs: ['pending', 'in_progress', 'completed'], orderBy: 'codElementoControl ASC');

    return RestrictionCatalogs(
      fronts: fronts.map((row) => CatalogOption(id: '${row['codAnaResFrente']}', label: (row['desAnaResFrente'] as String?) ?? '')).toList(),
      phases: phases.map((row) => CatalogOption(id: '${row['codAnaResFase']}', label: (row['desAnaResFase'] as String?) ?? '', colorHex: row['bgColor'] as String?)).toList(),
      areas: areas.map((row) => CatalogOption(id: '${row['codArea']}', label: (row['desArea'] as String?) ?? '')).toList(),
      types: types.map((row) => CatalogOption(id: '${row['codTipoRestriccion']}', label: (row['desTipoRestriccion'] as String?) ?? '')).toList(),
      responsibles: responsibles.map((row) {
        final email = row['desCorreo'] as String?;
        final rawName = email == null ? 'Integrante' : email.split('@').first.replaceAll('.', ' ');
        return CatalogOption(id: '${row['user_id']}', label: _capitalizeWords(rawName));
      }).toList(),
      statuses: statuses.map((row) => CatalogOption(id: (row['codEstado'] as String?) ?? '', label: _normalizeStatusLabel((row['desEstado'] as String?) ?? ''), colorHex: row['iconColor'] as String?)).toList(),
    );
  }

  RestrictionRecord _mapRestriction(Map<String, Object?> row, List<CatalogOption> areas) {
    final areaCode = row['codArea']?.toString();
    final areaLabel = areas.firstWhere((item) => item.id == areaCode, orElse: () => const CatalogOption(id: '', label: '')).label;
    final requiredDate = _parseDate(row['dayFechaRequerida'] as String?) ?? DateTime.now();
    final normalizedStatus = _normalizeStoredStatus((row['codEstadoActividad'] as String?) ?? 'pending');
    final derivedOverdue = normalizedStatus != 'completed' && _isPastDate(requiredDate);
    final derivedDueToday = normalizedStatus != 'completed' && _isToday(requiredDate);

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
      statusCode: normalizedStatus,
      statusLabel: _normalizeStatusLabel((row['desEstadoActividad'] as String?) ?? 'Pendiente'),
      statusColor: (row['colorEstado'] as String?) ?? '#98A3B3',
      requester: (row['desSolicitante'] as String?) ?? '',
      isCompleted: normalizedStatus == 'completed',
      isOverdue: derivedOverdue,
      isDueToday: derivedDueToday,
      isPending: normalizedStatus == 'pending',
      isInProgress: normalizedStatus == 'in_progress',
      priorityOrder: derivedOverdue ? 1 : ((row['priority_order'] as int?) ?? _priorityOrder(normalizedStatus)),
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
      columns: ['codAnaResActividad', 'codEstadoActividad', 'dayFechaRequerida'],
      where: projectId == null ? null : 'codProyecto = ?',
      whereArgs: projectId == null ? null : [projectId],
    );
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final id = row['codAnaResActividad'] as int;
      final statusCode = _normalizeStoredStatus((row['codEstadoActividad'] as String?) ?? 'pending');
      final requiredDate = _parseDate(row['dayFechaRequerida'] as String?);
      final completed = statusCode == 'completed';
      final overdue = !completed && requiredDate != null && _isPastDate(requiredDate);
      final dueToday = !completed && requiredDate != null && _isToday(requiredDate);
      await db.update(
        'anares_restriction',
        {
          'is_completed': completed ? 1 : 0,
          'is_overdue': overdue ? 1 : 0,
          'is_due_today': dueToday ? 1 : 0,
          'is_pending': statusCode == 'pending' ? 1 : 0,
          'is_in_progress': statusCode == 'in_progress' ? 1 : 0,
          'priority_order': overdue ? 1 : _priorityOrder(statusCode),
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
      final statusCode = (row['codEstado'] as String?) ?? 'pending';
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
    final currentBusinessDate = _currentBusinessDateKey(now: now);
    return preferences.lastDailyFullSyncBusinessDate != currentBusinessDate;
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
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      await _syncApiClient.pushInbox(
        userId: userId,
        items: queue
            .map(
              (row) => {
                'queueId': row['id'],
                'entityType': row['entity_type'],
                'entityId': row['entity_id'],
                'operationType': row['operation_type'],
                'payload': row['payload_json'],
              },
            )
            .toList(),
      );

      for (final row in queue) {
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
      for (final row in queue) {
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
    bool markDailyFullSync = false,
  }) async {
    final result = await _syncApiClient.pullData(
      userId: userId,
      scope: scope,
      businessDate: businessDate,
      since: since,
    );

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
    if (scope == 'full') {
      await _applyProjects(txn, _asMapList(payload['projects']));
      final catalogs = _asMap(payload['catalogs']);
      await _applyAreaMembers(txn, _asMapList(catalogs['areas']));
      await _applyAnalysisAreas(txn, _asMapList(catalogs['analysisAreas']));
      await _applyTypes(txn, _asMapList(catalogs['types']));
      await _applyStatuses(txn, _asMapList(catalogs['statuses']));
      await _applyMembers(txn, _asMapList(catalogs['members']));
      await _applyFronts(txn, _asMapList(catalogs['fronts']));
      await _applyPhases(txn, _asMapList(catalogs['phases']));
    }

    await _applyRestrictions(txn, _asMapList(payload['restrictions']));
    await _applyMeetings(txn, _asMapList(payload['meetings']));
    await _applyParticipants(txn, _asMapList(payload['participants']));
    await _applyAgreements(txn, _asMapList(payload['agreements']));
    await _applyComments(txn, _asMapList(payload['comments']));
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
          'codEmpresa': _asInt(row['codEmpresa']),
          'desEmpresa': row['desEmpresa'],
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
          'cod_Empresa': _asInt(row['cod_Empresa'] ?? row['codEmpresa']),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAnalysisAreas(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaresArea']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('anares_area', where: 'codAnaresArea = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_area',
        {
          'codAnaresArea': id,
          'codProyecto': _asInt(row['codProyecto']),
          'codArea': _asInt(row['codArea']),
          'desArea': row['desArea'],
          'bgColor': row['bgColor'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyFronts(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResFrente']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('anares_front', where: 'codAnaResFrente = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_front',
        {
          'codAnaResFrente': id,
          'codProyecto': _asInt(row['codProyecto']),
          'codAnaRes': _asInt(row['codAnaRes']),
          'desAnaResFrente': row['desAnaResFrente'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyPhases(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResFase']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('anares_phase', where: 'codAnaResFase = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_phase',
        {
          'codAnaResFase': id,
          'codAnaResFrente': _asInt(row['codAnaResFrente']),
          'codProyecto': _asInt(row['codProyecto']),
          'codAnaRes': _asInt(row['codAnaRes']),
          'desAnaResFase': row['desAnaResFase'],
          'bgColor': row['bgColor'],
          'updated_at': _asString(row['updated_at']) ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyTypes(DatabaseExecutor txn, List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final id = _asInt(row['codTipoRestriccion']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete('anares_type', where: 'codTipoRestriccion = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'anares_type',
        {
          'codTipoRestriccion': id,
          'desTipoRestriccion': row['desTipoRestriccion'],
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
      if (await _hasPendingQueueItem(txn, entityType: 'restriction', entityId: '$id')) {
        await _writeConflictLog(txn, entityType: 'restriction', entityId: '$id', message: 'Se conservo el cambio local pendiente frente al pull remoto.');
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete('anares_restriction', where: 'codAnaResActividad = ?', whereArgs: [id]);
        continue;
      }

      final statusCode = _normalizeStoredStatus(_asString(row['codEstadoActividad']) ?? 'pending');
      await txn.insert(
        'anares_restriction',
        {
          'codAnaResActividad': id,
          'codProyecto': _asInt(row['codProyecto']),
          'codAnaRes': _asInt(row['codAnaRes']),
          'codAnaResFrente': _asInt(row['codAnaResFrente']),
          'codAnaResFase': _asInt(row['codAnaResFase']),
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
          'codArea': _asString(row['codArea']),
          'codUsuarioSolicitante': _asString(row['codUsuarioSolicitante']),
          'desSolicitante': row['desSolicitante'],
          'is_completed': _asBoolInt(row['is_completed']),
          'is_overdue': _asBoolInt(row['is_overdue']),
          'is_due_today': _asBoolInt(row['is_due_today']),
          'is_pending': _asBoolInt(row['is_pending']),
          'is_in_progress': _asBoolInt(row['is_in_progress']),
          'priority_order': _asInt(row['priority_order']) ?? _priorityOrder(statusCode),
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
      if (_isDeleted(row)) {
        await txn.delete('meetings_meeting', where: 'codActReuReuniones = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'meetings_meeting',
        {
          'codActReuReuniones': id,
          'codProyecto': _asInt(row['codProyecto']),
          'codActReu': _asInt(row['codActReu']),
          'codActReuCategoria': _asInt(row['codActReuCategoria']),
          'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
          'desCategoria': row['desCategoria'],
          'desSubCategoria': row['desSubCategoria'],
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
      if (_isDeleted(row)) {
        await txn.delete('meetings_participant', where: 'codActReuParticipante = ?', whereArgs: [id]);
        continue;
      }

      await txn.insert(
        'meetings_participant',
        {
          'codActReuParticipante': id,
          'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
          'codProyecto': _asInt(row['codProyecto']),
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
          'codProyecto': _asInt(row['codProyecto']),
          'desAcuerdo': row['desAcuerdo'],
          'dayFechaAcuerdo': row['dayFechaAcuerdo'],
          'dayFechaAplazo': row['dayFechaAplazo'],
          'dayFechaLevantamiento': row['dayFechaLevantamiento'],
          'numAplazos': _asInt(row['numAplazos']),
          'idUsuarioResponsable': _asInt(row['idUsuarioResponsable']),
          'desResponsable': row['desResponsable'],
          'codEstado': row['codEstado'],
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

  Map<String, Object?> _statusFlags(String statusCode) {
    return {
      'is_completed': statusCode == 'completed' ? 1 : 0,
      'is_overdue': 0,
      'is_due_today': 0,
      'is_pending': statusCode == 'pending' ? 1 : 0,
      'is_in_progress': statusCode == 'in_progress' ? 1 : 0,
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

  String _normalizeStoredStatus(String statusCode) {
    return statusCode == 'overdue' ? 'pending' : statusCode;
  }

  String _normalizeStatusLabel(String raw) {
    if (raw == 'Completado') return 'Finalizado';
    if (raw == 'Retrasado') return 'Pendiente';
    return raw;
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
