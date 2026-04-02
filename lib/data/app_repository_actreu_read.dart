part of 'app_repository.dart';

extension AppRepositoryActreuRead on AppRepository {
  Future<ActreuHubViewData> loadActreuHubData() async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) {
      return const ActreuHubViewData(
        hasSubcategories: false,
        activeSession: null,
        overdueAgreements: [],
        subcategories: [],
      );
    }

    final hasSubcategories =
        (Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COUNT(*) FROM actreu_subcategoria WHERE codProyecto = ? AND deleted = 0',
                [projectId],
              ),
            ) ??
            0) >
        0;

    final subRows = await db.rawQuery(
      '''
      SELECT
        sub.codActReuSubCategoria,
        sub.desNombreSubCategoria,
        cat.desNombreCategoria
      FROM actreu_subcategoria sub
      LEFT JOIN actreu_categoria cat
        ON cat.codActReuCategoria = sub.codActReuCategoria
      WHERE sub.codProyecto = ? AND sub.deleted = 0
      ORDER BY sub.codActReuSubCategoria DESC
      ''',
      [projectId],
    );

    final now = DateTime.now();
    // _parseDateOnly normaliza al mediodia; usamos el mismo ancla para evitar
    // que sesiones del mismo dia queden fuera por diferencia horaria.
    final today = DateTime(now.year, now.month, now.day, 12);
    final hubSubcategories = <ActreuHubSubcategoryItem>[];

    for (final row in subRows) {
      final subcategoryId = _asInt(row['codActReuSubCategoria']);
      if (subcategoryId == null) continue;

      final agreements = await db.query(
        'actreu_acuerdos',
        columns: [
          'codEstado',
          'dayFechaAcuerdo',
          'dayFechaAplazo',
          'codActReuReuniones',
        ],
        where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId],
      );

      var overdueCount = 0;
      var pendingCount = 0;
      for (final agreement in agreements) {
        final status = _asInt(agreement['codEstado']) ?? 1;
        if (status == 3 || status == 6) continue;
        final dueDate =
            _parseDateOnly(
              agreement['dayFechaAplazo'] ?? agreement['dayFechaAcuerdo'],
            ) ??
            today;
        final isOverdue =
            (status == 4 || status == 5) || dueDate.isBefore(today);
        if (isOverdue) {
          overdueCount++;
        } else {
          pendingCount++;
        }
      }

      final nextSessionRows = await db.query(
        'actreu_reuniones',
        columns: ['codActReuReuniones', 'dayFechaReunion', 'codEstado'],
        where:
            'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0 AND codEstado = 1',
        whereArgs: [projectId, subcategoryId],
        orderBy: 'dayFechaReunion ASC',
      );
      DateTime? nextSessionDate;
      var hasActiveSession = false;
      int? activeSessionId;
      for (final session in nextSessionRows) {
        final sessionId = _asInt(session['codActReuReuniones']);
        final date = _parseDateOnly(session['dayFechaReunion']);
        if (date == null) continue;
        if (!hasActiveSession &&
            (date.isAtSameMomentAs(today) || date.isBefore(today))) {
          hasActiveSession = true;
          activeSessionId = sessionId;
        }
        if (date.isAtSameMomentAs(today) || date.isAfter(today)) {
          nextSessionDate ??= date;
        }
      }

      hubSubcategories.add(
        ActreuHubSubcategoryItem(
          subcategoryId: subcategoryId,
          subcategoryName: _asString(row['desNombreSubCategoria']) ?? '-',
          categoryName: _asString(row['desNombreCategoria']) ?? '-',
          overdueCount: overdueCount,
          pendingCount: pendingCount,
          nextSessionDate: nextSessionDate,
          hasActiveSession: hasActiveSession,
          activeSessionId: activeSessionId,
        ),
      );
    }

    ActreuSessionBannerItem? activeSession;
    final activeSessionRows = await db.query(
      'actreu_reuniones',
      columns: [
        'codActReuReuniones',
        'codActReuSubCategoria',
        'desNombre',
        'dayFechaReunion',
        'horHoraInicio',
        'horHoraFin',
      ],
      where: 'codProyecto = ? AND codEstado = 1 AND deleted = 0',
      whereArgs: [projectId],
      orderBy: 'dayFechaReunion ASC, codActReuReuniones ASC',
    );
    for (final row in activeSessionRows) {
      final sessionId = _asInt(row['codActReuReuniones']);
      final subcategoryId = _asInt(row['codActReuSubCategoria']);
      final sessionDate = _parseDateOnly(row['dayFechaReunion']);
      if (sessionId == null || subcategoryId == null || sessionDate == null) {
        continue;
      }
      final isCandidate =
          sessionDate.isAtSameMomentAs(today) || sessionDate.isBefore(today);
      if (!isCandidate) continue;
      final attendanceCountRows = await db.query(
        'actreu_asistencias',
        columns: ['codEstado'],
        where: 'codProyecto = ? AND codActReuReuniones = ? AND deleted = 0',
        whereArgs: [projectId, sessionId],
      );
      final attendanceTotal = attendanceCountRows.length;
      final attendancePresent = attendanceCountRows
          .where((item) => (_asInt(item['codEstado']) ?? 0) == 1)
          .length;
      activeSession = ActreuSessionBannerItem(
        sessionId: sessionId,
        subcategoryId: subcategoryId,
        title: _asString(row['desNombre']) ?? 'Sesion',
        sessionDate: sessionDate,
        startTime: _asString(row['horHoraInicio']) ?? '',
        endTime: _asString(row['horHoraFin']) ?? '',
        attendancePresent: attendancePresent,
        attendanceTotal: attendanceTotal,
      );
      break;
    }

    final overdueItems = await _loadActreuOverdueAgreements(db, projectId);

    return ActreuHubViewData(
      hasSubcategories: hasSubcategories,
      activeSession: activeSession,
      overdueAgreements: overdueItems.take(3).toList(),
      subcategories: hubSubcategories,
    );
  }

  Future<List<ActreuCategoryTreeItem>> loadActreuCategoryTree() async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return const [];

    final categories = await db.query(
      'actreu_categoria',
      columns: ['codActReuCategoria', 'desNombreCategoria'],
      where: 'codProyecto = ? AND deleted = 0',
      whereArgs: [projectId],
      orderBy: 'codActReuCategoria DESC',
    );
    final subcategories = await db.query(
      'actreu_subcategoria',
      columns: [
        'codActReuSubCategoria',
        'codActReuCategoria',
        'desNombreSubCategoria',
      ],
      where: 'codProyecto = ? AND deleted = 0',
      whereArgs: [projectId],
      orderBy: 'codActReuSubCategoria DESC',
    );
    final subByCategory = <int, List<ActreuSubcategoryTreeItem>>{};
    for (final row in subcategories) {
      final id = _asInt(row['codActReuSubCategoria']);
      final categoryId = _asInt(row['codActReuCategoria']);
      if (id == null || categoryId == null) continue;
      subByCategory
          .putIfAbsent(categoryId, () => [])
          .add(
            ActreuSubcategoryTreeItem(
              subcategoryId: id,
              subcategoryName: _asString(row['desNombreSubCategoria']) ?? '-',
            ),
          );
    }

    return categories
        .map((row) {
          final id = _asInt(row['codActReuCategoria']);
          if (id == null) return null;
          return ActreuCategoryTreeItem(
            categoryId: id,
            categoryName: _asString(row['desNombreCategoria']) ?? '-',
            subcategories: subByCategory[id] ?? const [],
          );
        })
        .whereType<ActreuCategoryTreeItem>()
        .toList();
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  loadActreuParticipantRecommendations(int subcategoryId) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return const [];
    return _loadActreuRecommendationsForSubcategory(
      db,
      projectId: projectId,
      subcategoryId: subcategoryId,
    );
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  loadActreuParticipantRecommendationsForProject() async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return const [];

    final latestActaRow = await db.query(
      'actreu_actareuniones',
      columns: ['codActReu'],
      where: 'codProyecto = ? AND deleted = 0',
      whereArgs: [projectId],
      orderBy: 'codActReu DESC',
      limit: 1,
    );
    final knownActaId = latestActaRow.isEmpty
        ? null
        : _asInt(latestActaRow.first['codActReu']);

    return _loadActreuRecommendationsForSubcategory(
      db,
      projectId: projectId,
      subcategoryId: -1,
      knownActaId: knownActaId,
    );
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  loadActreuOtherProjectParticipantRecommendations({int? subcategoryId}) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return const [];

    int? knownActaId;
    if (subcategoryId != null && subcategoryId > 0) {
      final subRows = await db.query(
        'actreu_subcategoria',
        columns: ['codActReu'],
        where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId],
        limit: 1,
      );
      knownActaId = subRows.isEmpty ? null : _asInt(subRows.first['codActReu']);
    }
    if (knownActaId == null) {
      final latestActaRow = await db.query(
        'actreu_actareuniones',
        columns: ['codActReu'],
        where: 'codProyecto = ? AND deleted = 0',
        whereArgs: [projectId],
        orderBy: 'codActReu DESC',
        limit: 1,
      );
      knownActaId = latestActaRow.isEmpty
          ? null
          : _asInt(latestActaRow.first['codActReu']);
    }

    final configuredRows = await db.query(
      'actreu_integrantes',
      columns: ['codProyIntegrante'],
      where: knownActaId == null
          ? 'codProyecto = ? AND deleted = 0 AND IFNULL(codEstado, 1) = 1'
          : 'codProyecto = ? AND codActReu = ? AND deleted = 0 AND IFNULL(codEstado, 1) = 1',
      whereArgs: knownActaId == null ? [projectId] : [projectId, knownActaId],
    );
    final configuredMemberIds = configuredRows
        .map((row) => _asInt(row['codProyIntegrante']))
        .whereType<int>()
        .toSet();

    final projectMemberRows = await db.rawQuery(
      '''
      SELECT
        pm.codProyIntegrante,
        pm.user_id AS idIntegrante,
        pm.desCorreo,
        usr.name AS desNombreUsuario,
        usr.lastname AS desApellidoUsuario
      FROM projects_member pm
      LEFT JOIN auth_user usr ON usr.id = pm.user_id
      WHERE pm.codProyecto = ?
      ORDER BY pm.codProyIntegrante DESC
      ''',
      [projectId],
    );

    final result = <ActreuSubcategoryRecommendationItem>[];
    for (final row in projectMemberRows) {
      final memberId = _asInt(row['codProyIntegrante']);
      if (memberId == null || configuredMemberIds.contains(memberId)) continue;
      final integranteId = _asInt(row['idIntegrante']) ?? -999;
      final email = _asString(row['desCorreo']);
      final firstName = _asString(row['desNombreUsuario']) ?? '';
      final lastName = _asString(row['desApellidoUsuario']) ?? '';
      final fullName = '$firstName $lastName'.trim();
      final isInvited = integranteId == -999;
      final label = isInvited
          ? (email ?? 'Invitado $memberId')
          : (fullName.isNotEmpty
                ? fullName
                : (email ?? 'Integrante $memberId'));
      debugPrint(
        '[ActreuTrace][participants_other] project=$projectId '
        'subcategory=${subcategoryId ?? '-'} acta=${knownActaId ?? '-'} '
        'member=$memberId idIntegrante=$integranteId invited=$isInvited '
        'user="$fullName" email="${email ?? '-'}" resolved="$label"',
      );
      result.add(
        ActreuSubcategoryRecommendationItem(
          projectMemberId: memberId,
          label: label,
        ),
      );
    }
    debugPrint(
      '[ActreuTrace][participants_other] project=$projectId '
      'subcategory=${subcategoryId ?? '-'} acta=${knownActaId ?? '-'} '
      'configured=${configuredMemberIds.length} total=${result.length}',
    );
    return result;
  }
}
