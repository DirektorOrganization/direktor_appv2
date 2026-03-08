import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local/app_database.dart';
import 'models/app_models.dart';

class AppRepository {
  AppRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

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
      isOfflineMode: preferences.isOfflineMode,
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
    final db = await _database.database;
    final preferences = await _loadPreferences(db);
    if (preferences.isOfflineMode) {
      throw Exception('La app esta en modo offline. Desactiva el modo offline para sincronizar.');
    }
    if (!preferences.remoteSyncEnabled) {
      throw Exception('La sincronizacion remota esta deshabilitada.');
    }

    final queue = await db.query('sync_queue', where: "status IN ('pending', 'failed')", orderBy: 'created_at ASC, id ASC');
    final now = DateTime.now().toIso8601String();

    for (final row in queue) {
      final queueId = row['id'] as int;
      final entityType = row['entity_type'] as String? ?? '';
      final entityId = row['entity_id'] as String? ?? '';
      try {
        await Future<void>.delayed(const Duration(milliseconds: 180));
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
          'message': 'Sincronizado con backend remoto simulado',
          'created_at': now,
        });
      } catch (error) {
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
          whereArgs: [queueId],
        );
        await db.insert('sync_log', {
          'entity_type': entityType,
          'entity_id': entityId,
          'action': row['operation_type'] as String? ?? 'sync',
          'result': 'failed',
          'message': error.toString(),
          'created_at': now,
        });
      }
    }

    await _saveSetting(db, 'last_sync_at', now);
    await _refreshDerivedState(db);
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
    return AppPreferences(
      keepSignedIn: keepSignedIn != '0',
      isOfflineMode: offlineMode == '1',
      remoteSyncEnabled: remoteSyncEnabled != '0',
      currentProjectId: currentProjectId,
      lastSyncAt: lastSyncAt,
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
