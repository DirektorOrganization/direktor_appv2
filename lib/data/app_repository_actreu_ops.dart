part of 'app_repository.dart';

extension AppRepositoryActreuOps on AppRepository {
  Future<int?> createActreuCategory({
    required String name,
    int statusCode = 1,
  }) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);

    final existingActaRows = await db.query(
      'actreu_actareuniones',
      columns: ['codActReu'],
      where: 'codProyecto = ? AND deleted = 0',
      whereArgs: [projectId],
      orderBy: 'codActReu DESC',
      limit: 1,
    );

    int actaId;
    if (existingActaRows.isNotEmpty) {
      actaId = _asInt(existingActaRows.first['codActReu']) ?? 0;
    } else {
      actaId = await _nextActreuActaId(db);
      await db.insert('actreu_actareuniones', {
        'codActReu': actaId,
        'codProyecto': projectId,
        'codEstado': 1,
        'dayFechaCreacion': nowIso,
        'desUsuarioCreacion': actor,
        'updated_at': nowIso,
        'deleted': 0,
      });
      await _enqueueSync(
        db,
        entityType: 'actreu_acta',
        entityId: '$actaId',
        operationType: 'create',
        payload: await _buildActreuActaSyncPayload(db, actaId),
        isFromRemoteTable: await _resolveActreuLocalLineageFlag(
          db,
          entityType: 'actreu_acta',
          entityId: '$actaId',
          operationType: 'create',
        ),
      );

      // Si es un acta nueva, inicializamos sus integrantes con los del proyecto
      // para habilitar de inmediato la selecciÃƒÂ³n de participantes en subcategorÃƒÂ­as.
      final memberRows = await db.query(
        'projects_member',
        columns: ['codProyIntegrante'],
        where: 'codProyecto = ?',
        whereArgs: [projectId],
      );
      for (final member in memberRows) {
        final memberId = _asInt(member['codProyIntegrante']);
        if (memberId == null) continue;
        await db.insert('actreu_integrantes', {
          'codProyecto': projectId,
          'codActReu': actaId,
          'codProyIntegrante': memberId,
          'codEstado': 1,
          'dayFechaCreacion': nowIso,
          'desUsuarioCreacion': actor,
          'dayFechaModificacion': nowIso,
          'desUsuarioModificacion': actor,
          'updated_at': nowIso,
          'deleted': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await _enqueueSync(
          db,
          entityType: 'actreu_integrante',
          entityId: '$projectId-$actaId-$memberId',
          operationType: 'create',
          payload: await _buildActreuIntegranteSyncPayload(
            db,
            projectId: projectId,
            actaId: actaId,
            memberId: memberId,
          ),
          isFromRemoteTable: await _resolveActreuLocalLineageFlag(
            db,
            entityType: 'actreu_integrante',
            entityId: '$projectId-$actaId-$memberId',
            operationType: 'create',
            parentRefs: [('actreu_acta', '$actaId')],
          ),
        );
      }
    }

    final categoryId = await _nextActreuCategoryId(db);

    await db.insert('actreu_categoria', {
      'codActReuCategoria': categoryId,
      'codProyecto': projectId,
      'codActReu': actaId,
      'desNombreCategoria': trimmed,
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': actor,
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': actor,
      'codEstado': statusCode,
      'updated_at': nowIso,
      'deleted': 0,
    });
    await _enqueueSync(
      db,
      entityType: 'actreu_categoria',
      entityId: '$categoryId',
      operationType: 'create',
      payload: await _buildActreuCategoriaSyncPayload(db, categoryId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_categoria',
        entityId: '$categoryId',
        operationType: 'create',
      ),
    );

    return categoryId;
  }

  Future<int?> createActreuSubcategory({
    required int categoryId,
    required String name,
    int statusCode = 1,
  }) async {
    final db = await _database.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final categoryRows = await db.query(
      'actreu_categoria',
      columns: ['codProyecto', 'codActReu', 'codActReuCategoria'],
      where: 'codActReuCategoria = ? AND deleted = 0',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (categoryRows.isEmpty) return null;

    final category = categoryRows.first;
    final projectId = _asInt(category['codProyecto']);
    final actaId = _asInt(category['codActReu']);
    if (projectId == null || actaId == null) return null;

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final subcategoryId = await _nextActreuSubcategoryId(db);

    await db.insert('actreu_subcategoria', {
      'codActReuSubCategoria': subcategoryId,
      'codProyecto': projectId,
      'codActReu': actaId,
      'codActReuCategoria': categoryId,
      'codEstado': statusCode,
      'desNombreSubCategoria': trimmed,
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': actor,
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': actor,
      'updated_at': nowIso,
      'deleted': 0,
    });
    await _enqueueSync(
      db,
      entityType: 'actreu_subcategoria',
      entityId: '$subcategoryId',
      operationType: 'create',
      payload: await _buildActreuSubcategoriaSyncPayload(db, subcategoryId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_subcategoria',
        entityId: '$subcategoryId',
        operationType: 'create',
        parentRefs: [('actreu_categoria', '$categoryId')],
      ),
    );

    return subcategoryId;
  }

  Future<bool> updateActreuCategoryName({
    required int categoryId,
    required String name,
  }) async {
    final db = await _database.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final rows = await db.query(
      'actreu_categoria',
      where: 'codActReuCategoria = ? AND deleted = 0',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_categoria',
      {
        'desNombreCategoria': trimmed,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuCategoria = ?',
      whereArgs: [categoryId],
    );
    await _enqueueSync(
      db,
      entityType: 'actreu_categoria',
      entityId: '$categoryId',
      operationType: 'update',
      payload: await _buildActreuCategoriaSyncPayload(db, categoryId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_categoria',
        entityId: '$categoryId',
        operationType: 'update',
      ),
    );
    return true;
  }

  Future<bool> updateActreuSubcategoryName({
    required int subcategoryId,
    required String name,
  }) async {
    final db = await _database.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final rows = await db.query(
      'actreu_subcategoria',
      where: 'codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_subcategoria',
      {
        'desNombreSubCategoria': trimmed,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuSubCategoria = ?',
      whereArgs: [subcategoryId],
    );
    await _enqueueSync(
      db,
      entityType: 'actreu_subcategoria',
      entityId: '$subcategoryId',
      operationType: 'update',
      payload: await _buildActreuSubcategoriaSyncPayload(db, subcategoryId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_subcategoria',
        entityId: '$subcategoryId',
        operationType: 'update',
      ),
    );
    return true;
  }

  Future<bool> deleteActreuCategory(int categoryId) async {
    final db = await _database.database;
    final categoryRows = await db.query(
      'actreu_categoria',
      where: 'codActReuCategoria = ? AND deleted = 0',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (categoryRows.isEmpty) return false;

    final activeSubcategories =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_subcategoria
            WHERE codActReuCategoria = ?
              AND deleted = 0
              AND IFNULL(codEstado, 1) <> 2
            ''',
            [categoryId],
          ),
        ) ??
        0;
    if (activeSubcategories > 0) {
      throw Exception(
        'No se puede eliminar la categorÃƒÂ­a porque tiene subcategorÃƒÂ­as activas.',
      );
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_categoria',
      {
        'deleted': 1,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuCategoria = ?',
      whereArgs: [categoryId],
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_categoria',
      entityId: '$categoryId',
      operationType: 'delete',
      payload: await _buildActreuCategoriaSyncPayload(db, categoryId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_categoria',
        entityId: '$categoryId',
        operationType: 'delete',
      ),
    );
    return true;
  }

  Future<bool> deleteActreuSubcategory(int subcategoryId) async {
    final db = await _database.database;
    final subcategoryRows = await db.query(
      'actreu_subcategoria',
      where: 'codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    if (subcategoryRows.isEmpty) return false;

    final agreementsCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_acuerdos
            WHERE codActReuSubCategoria = ?
              AND deleted = 0
            ''',
            [subcategoryId],
          ),
        ) ??
        0;
    if (agreementsCount > 0) {
      throw Exception(
        'No se puede eliminar la subcategorÃƒÂ­a porque tiene acuerdos registrados.',
      );
    }

    final pendingSessionsCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_reuniones
            WHERE codActReuSubCategoria = ?
              AND deleted = 0
              AND IFNULL(codEstado, 1) <> 2
            ''',
            [subcategoryId],
          ),
        ) ??
        0;
    if (pendingSessionsCount > 0) {
      throw Exception(
        'No se puede eliminar la subcategorÃƒÂ­a porque tiene sesiones pendientes.',
      );
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_subcategoria',
      {
        'deleted': 1,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuSubCategoria = ?',
      whereArgs: [subcategoryId],
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_subcategoria',
      entityId: '$subcategoryId',
      operationType: 'delete',
      payload: await _buildActreuSubcategoriaSyncPayload(db, subcategoryId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_subcategoria',
        entityId: '$subcategoryId',
        operationType: 'delete',
      ),
    );
    return true;
  }

  Future<ActreuSubcategoryViewData?> loadActreuSubcategoryView(
    int subcategoryId,
  ) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return null;

    final subRows = await db.rawQuery(
      '''
      SELECT sub.codActReuSubCategoria, sub.desNombreSubCategoria, cat.desNombreCategoria, sub.codActReu
      FROM actreu_subcategoria sub
      LEFT JOIN actreu_categoria cat ON cat.codActReuCategoria = sub.codActReuCategoria
      WHERE sub.codProyecto = ? AND sub.codActReuSubCategoria = ? AND sub.deleted = 0
      LIMIT 1
      ''',
      [projectId, subcategoryId],
    );
    if (subRows.isEmpty) return null;
    final subRow = subRows.first;
    final actaId = _asInt(subRow['codActReu']);

    final sessionRows = await db.query(
      'actreu_reuniones',
      where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [projectId, subcategoryId],
      orderBy: 'dayFechaReunion DESC, codActReuReuniones DESC',
    );

    final agreementRows = await db.query(
      'actreu_acuerdos',
      where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [projectId, subcategoryId],
      orderBy: 'codActReuAcuerdos DESC',
    );

    final commentCountRows = await db.rawQuery(
      '''
      SELECT codActReuAcuerdos, COUNT(*) as total
      FROM actreu_comentarios_acuerdo
      WHERE codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0
      GROUP BY codActReuAcuerdos
      ''',
      [projectId, subcategoryId],
    );
    final commentsByAgreement = <int, int>{
      for (final row in commentCountRows)
        if (_asInt(row['codActReuAcuerdos']) != null)
          _asInt(row['codActReuAcuerdos'])!: _asInt(row['total']) ?? 0,
    };

    final groupRows = await db.query(
      'actreu_grupoacuerdo',
      columns: [
        'codActReuGrupoAcuerdo',
        'desGrupoAcuerdo',
        'desColorGrupoAcuerdo',
      ],
      where: 'deleted = 0',
    );
    final groupById = <int, Map<String, String?>>{
      for (final row in groupRows)
        if (_asInt(row['codActReuGrupoAcuerdo']) != null)
          _asInt(row['codActReuGrupoAcuerdo'])!: {
            'name': _asString(row['desGrupoAcuerdo']) ?? 'Sin grupo',
            'color': _asString(row['desColorGrupoAcuerdo']),
          },
    };
    if (AppRepository._traceActreuGroupResolution) {
      _traceActreuGroupMaster(
        scope: 'subcategory_view',
        projectId: projectId,
        subcategoryId: subcategoryId,
        groupRows: groupRows,
      );
    }
    final groupOptions = groupRows
        .map((row) {
          final groupId = _asInt(row['codActReuGrupoAcuerdo']);
          if (groupId == null) return null;
          return ActreuGroupOptionItem(
            groupId: groupId,
            groupName: _asString(row['desGrupoAcuerdo']) ?? 'Sin grupo',
            groupColorHex: _asString(row['desColorGrupoAcuerdo']),
          );
        })
        .whereType<ActreuGroupOptionItem>()
        .toList();

    final agreementsBySession = <int, List<Map<String, Object?>>>{};
    for (final agreement in agreementRows) {
      final sessionId = _asInt(agreement['codActReuReuniones']);
      if (sessionId == null) continue;
      agreementsBySession.putIfAbsent(sessionId, () => []).add(agreement);
    }

    final asistenciaRows = await db.query(
      'actreu_asistencias',
      columns: ['codActReuReuniones', 'codEstado'],
      where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [projectId, subcategoryId],
    );
    final attendanceBySessionTotal = <int, int>{};
    final attendanceBySessionPresent = <int, int>{};
    for (final asistencia in asistenciaRows) {
      final sessionId = _asInt(asistencia['codActReuReuniones']);
      if (sessionId == null) continue;
      attendanceBySessionTotal[sessionId] =
          (attendanceBySessionTotal[sessionId] ?? 0) + 1;
      if ((_asInt(asistencia['codEstado']) ?? 0) == 1) {
        attendanceBySessionPresent[sessionId] =
            (attendanceBySessionPresent[sessionId] ?? 0) + 1;
      }
    }

    final sessions = sessionRows
        .map((row) {
          final sessionId = _asInt(row['codActReuReuniones']);
          if (sessionId == null) return null;
          final sessionAgreements = agreementsBySession[sessionId] ?? const [];
          final overdue = sessionAgreements.where((item) {
            final status = _asInt(item['codEstado']) ?? 1;
            if (status == 3 || status == 6) return false;
            final dueDate = _parseDateOnly(
              item['dayFechaAplazo'] ?? item['dayFechaAcuerdo'],
            );
            if (dueDate == null) return false;
            final today = DateTime.now();
            final nowDate = DateTime(today.year, today.month, today.day);
            return (status == 4 || status == 5) || dueDate.isBefore(nowDate);
          }).length;
          return ActreuSubcategorySessionItem(
            sessionId: sessionId,
            title: _asString(row['desNombre']) ?? 'Sesion',
            date: _parseDateOnly(row['dayFechaReunion']),
            statusCode: _asInt(row['codEstado']) ?? 1,
            attendedCount: attendanceBySessionPresent[sessionId] ?? 0,
            totalCount: attendanceBySessionTotal[sessionId] ?? 0,
            agreementsCount: sessionAgreements.length,
            overdueCount: overdue,
          );
        })
        .whereType<ActreuSubcategorySessionItem>()
        .toList();
    final sessionStatusById = <int, int>{
      for (final session in sessions) session.sessionId: session.statusCode,
    };

    final participantRows = await db.query(
      'actreu_participantes',
      where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [projectId, subcategoryId],
      orderBy: 'codActReuParticipante DESC',
    );
    final participants = participantRows
        .map((row) {
          final participantId = _asInt(row['codActReuParticipante']);
          if (participantId == null) return null;
          return ActreuSubcategoryParticipantItem(
            participantId: participantId,
            name: _asString(row['desNombre']) ?? '-',
            area: _asString(row['codArea']) ?? '-',
            role: _asString(row['desCorreoElectronico']) ?? '-',
            userId: _asInt(row['idUsuarioParticipante']),
            projectMemberId: _asInt(row['codProyIntegrante']),
          );
        })
        .whereType<ActreuSubcategoryParticipantItem>()
        .toList();

    final recommendations = await _loadActreuRecommendationsForSubcategory(
      db,
      projectId: projectId,
      subcategoryId: subcategoryId,
      knownActaId: actaId,
    );

    final agreements = agreementRows
        .map((row) {
          final agreementId = _asInt(row['codActReuAcuerdos']);
          if (agreementId == null) return null;
          final groupId = _asInt(row['codGrupoAcuerdo']);
          final groupData = groupById[groupId] ?? const {};
          final resolvedGroupName =
              groupData['name'] ??
              (groupId != null ? 'Grupo $groupId' : 'Sin grupo');
          if (AppRepository._traceActreuGroupResolution) {
            _traceActreuAgreementGroupMatch(
              scope: 'subcategory_view',
              agreementId: agreementId,
              rawGroupId: row['codGrupoAcuerdo'],
              parsedGroupId: groupId,
              resolvedGroupName: resolvedGroupName,
              resolvedGroupColor: groupData['color'],
              foundInMaster: groupData.isNotEmpty,
            );
          }
          return ActreuSubcategoryAgreementItem(
            agreementId: agreementId,
            description: _asString(row['desAcuerdo']) ?? '-',
            responsible:
                participants
                    .where(
                      (p) =>
                          p.participantId ==
                          _asInt(row['idUsuarioResponsable']),
                    )
                    .map((p) => p.name)
                    .firstOrNull ??
                'Sin responsable',
            responsibleParticipantId: _asInt(row['idUsuarioResponsable']),
            dueDate: _parseDateOnly(
              row['dayFechaAplazo'] ?? row['dayFechaAcuerdo'],
            ),
            statusCode: _asInt(row['codEstado']) ?? 1,
            groupId: groupId,
            group: resolvedGroupName,
            groupColorHex: groupData['color'],
            sessionLabel:
                sessions
                    .where(
                      (s) => s.sessionId == _asInt(row['codActReuReuniones']),
                    )
                    .map((s) => s.title)
                    .firstOrNull ??
                '-',
            commentsCount: commentsByAgreement[agreementId] ?? 0,
            deferralsCount: _asInt(row['numAplazos']) ?? 0,
            lockedByActiveSession:
                (sessionStatusById[_asInt(row['codActReuReuniones']) ?? -1] ??
                    0) ==
                1,
          );
        })
        .whereType<ActreuSubcategoryAgreementItem>()
        .toList();

    return ActreuSubcategoryViewData(
      subcategoryId: subcategoryId,
      subcategoryName: _asString(subRow['desNombreSubCategoria']) ?? '-',
      categoryName: _asString(subRow['desNombreCategoria']) ?? '-',
      agreements: agreements,
      sessions: sessions,
      participants: participants,
      recommendations: recommendations,
      groupOptions: groupOptions,
    );
  }

  Future<List<ActreuAgreementCommentItem>> loadActreuAgreementComments(
    int agreementId,
  ) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return const [];

    final rows = await db.query(
      'actreu_comentarios_acuerdo',
      where: 'codProyecto = ? AND codActReuAcuerdos = ? AND deleted = 0',
      whereArgs: [projectId, agreementId],
      orderBy: 'dayFechaComentario ASC, codComentario ASC',
    );

    return rows
        .map((row) {
          final commentId = _asInt(row['codComentario']);
          final agreementRef = _asInt(row['codActReuAcuerdos']);
          if (commentId == null || agreementRef == null) return null;
          return ActreuAgreementCommentItem(
            commentId: commentId,
            agreementId: agreementRef,
            parentCommentId: _asInt(row['codComentarioPadre']),
            userId: _asInt(row['idUsuario']),
            message: _asString(row['desMensaje']) ?? '',
            createdAt: _parseDateTime(row['dayFechaComentario'] as String?),
            author:
                _asString(row['desUsuarioCreacion']) ??
                (_asInt(row['idUsuario']) != null
                    ? 'Usuario ${_asInt(row['idUsuario'])}'
                    : 'Participante'),
          );
        })
        .whereType<ActreuAgreementCommentItem>()
        .toList();
  }

  Future<int?> createActreuAgreementComment({
    required int agreementId,
    required String message,
    int? parentCommentId,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;

    final db = await _database.database;
    final agreementRows = await db.query(
      'actreu_acuerdos',
      columns: [
        'codProyecto',
        'codActReu',
        'codActReuCategoria',
        'codActReuSubCategoria',
        'codActReuReuniones',
        'codActReuAcuerdos',
      ],
      where: 'codActReuAcuerdos = ? AND deleted = 0',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (agreementRows.isEmpty) {
      throw Exception(
        'No se encontrÃƒÂ³ el acuerdo para registrar comentario.',
      );
    }

    final agreement = agreementRows.first;
    final projectId = _asInt(agreement['codProyecto']);
    final actaId = _asInt(agreement['codActReu']);
    final categoryId = _asInt(agreement['codActReuCategoria']);
    final subcategoryId = _asInt(agreement['codActReuSubCategoria']);
    final sessionId = _asInt(agreement['codActReuReuniones']);
    if (projectId == null || actaId == null || categoryId == null) {
      throw Exception('No se pudo resolver la jerarquÃƒÂ­a del acuerdo.');
    }

    int? safeParentId;
    if (parentCommentId != null) {
      final parentRows = await db.query(
        'actreu_comentarios_acuerdo',
        columns: ['codComentario'],
        where: 'codComentario = ? AND codActReuAcuerdos = ? AND deleted = 0',
        whereArgs: [parentCommentId, agreementId],
        limit: 1,
      );
      if (parentRows.isNotEmpty) {
        safeParentId = parentCommentId;
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final userId = await _loadCurrentUserId(db);
    final commentId = await _nextActreuCommentId(db);

    await db.insert('actreu_comentarios_acuerdo', {
      'codComentario': commentId,
      'codProyecto': projectId,
      'codActReu': actaId,
      'codActReuCategoria': categoryId,
      'codActReuSubCategoria': subcategoryId,
      'codActReuReuniones': sessionId,
      'codActReuAcuerdos': agreementId,
      'codComentarioPadre': safeParentId,
      'idUsuario': userId,
      'desMensaje': trimmed,
      'dayFechaComentario': nowIso,
      'desUsuarioCreacion': actor,
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': actor,
      'updated_at': nowIso,
      'deleted': 0,
    });

    await _enqueueSync(
      db,
      entityType: 'actreu_comentario',
      entityId: '$commentId',
      operationType: 'create',
      payload: await _buildActreuCommentSyncPayload(db, commentId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_comentario',
        entityId: '$commentId',
        operationType: 'create',
        parentRefs: [('actreu_acuerdo', '$agreementId')],
      ),
    );

    return commentId;
  }

  Future<List<ActreuOverdueAgreementItem>> _loadActreuOverdueAgreements(
    Database db,
    int projectId,
  ) async {
    final groupColorRows = await db.query(
      'actreu_grupoacuerdo',
      columns: ['codActReuGrupoAcuerdo', 'desColorGrupoAcuerdo'],
      where: '(codProyecto = ? OR codProyecto IS NULL) AND deleted = 0',
      whereArgs: [projectId],
    );
    final groupColorById = <int, String?>{
      for (final row in groupColorRows)
        if (_asInt(row['codActReuGrupoAcuerdo']) != null)
          _asInt(row['codActReuGrupoAcuerdo'])!: _asString(
            row['desColorGrupoAcuerdo'],
          ),
    };

    final overdueRows = await db.rawQuery(
      '''
      SELECT
        acu.codActReuAcuerdos,
        acu.desAcuerdo,
        acu.dayFechaAcuerdo,
        acu.dayFechaAplazo,
        acu.numAplazos,
        acu.codEstado,
        acu.codGrupoAcuerdo,
        COALESCE(part.desNombre, part.desCorreoElectronico, 'Sin responsable') as desResponsable,
        COALESCE(ga.desGrupoAcuerdo, 'General') as desGrupoAcuerdo,
        COALESCE(reu.desNombre, sub.desNombreSubCategoria, '-') as desSesion
      FROM actreu_acuerdos acu
      LEFT JOIN actreu_participantes part
        ON part.codActReuParticipante = acu.idUsuarioResponsable
      LEFT JOIN actreu_grupoacuerdo ga
        ON ga.codActReuGrupoAcuerdo = acu.codGrupoAcuerdo
      LEFT JOIN actreu_reuniones reu
        ON reu.codActReuReuniones = acu.codActReuReuniones
      LEFT JOIN actreu_subcategoria sub
        ON sub.codActReuSubCategoria = acu.codActReuSubCategoria
      WHERE acu.codProyecto = ? AND acu.deleted = 0
      ORDER BY acu.codActReuAcuerdos DESC
      ''',
      [projectId],
    );

    final commentCountRows = await db.rawQuery(
      '''
      SELECT codActReuAcuerdos, COUNT(*) as total
      FROM actreu_comentarios_acuerdo
      WHERE codProyecto = ? AND deleted = 0
      GROUP BY codActReuAcuerdos
      ''',
      [projectId],
    );
    final commentsByAgreement = <int, int>{
      for (final row in commentCountRows)
        if (_asInt(row['codActReuAcuerdos']) != null)
          _asInt(row['codActReuAcuerdos'])!: _asInt(row['total']) ?? 0,
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = <ActreuOverdueAgreementItem>[];
    for (final row in overdueRows) {
      final agreementId = _asInt(row['codActReuAcuerdos']);
      if (agreementId == null) continue;
      final status = _asInt(row['codEstado']) ?? 1;
      if (status == 3 || status == 6) continue;
      final dueDate =
          _parseDateOnly(row['dayFechaAplazo'] ?? row['dayFechaAcuerdo']) ??
          today;
      final isOverdue = (status == 4 || status == 5) || dueDate.isBefore(today);
      if (!isOverdue) continue;
      final daysOverdue = max(0, today.difference(dueDate).inDays);
      items.add(
        ActreuOverdueAgreementItem(
          agreementId: agreementId,
          description: _asString(row['desAcuerdo']) ?? '-',
          responsible: _asString(row['desResponsable']) ?? 'Sin responsable',
          group: _asString(row['desGrupoAcuerdo']) ?? 'General',
          groupColorHex: groupColorById[_asInt(row['codGrupoAcuerdo']) ?? -1],
          dueDate: dueDate,
          daysOverdue: daysOverdue,
          commentsCount: commentsByAgreement[agreementId] ?? 0,
          deferralsCount: _asInt(row['numAplazos']) ?? 0,
          sessionLabel: _asString(row['desSesion']) ?? '-',
        ),
      );
    }
    items.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
    return items;
  }

  Future<List<ActreuOverdueAgreementItem>> loadActreuOverdueAgreements() async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return const [];
    return _loadActreuOverdueAgreements(db, projectId);
  }

  Future<ActreuSessionViewData?> loadActreuSessionView({
    required int subcategoryId,
    int? sessionId,
  }) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return null;

    Map<String, Object?>? sessionRow;
    if (sessionId != null) {
      final rows = await db.query(
        'actreu_reuniones',
        where:
            'codProyecto = ? AND codActReuSubCategoria = ? AND codActReuReuniones = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId, sessionId],
        limit: 1,
      );
      if (rows.isNotEmpty) sessionRow = rows.first;
    } else {
      final rows = await db.query(
        'actreu_reuniones',
        where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId],
        orderBy: 'dayFechaReunion DESC, codActReuReuniones DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) sessionRow = rows.first;
    }
    if (sessionRow == null) return null;

    final resolvedSessionId = _asInt(sessionRow['codActReuReuniones']);
    if (resolvedSessionId == null) return null;
    final isClosedSession = (_asInt(sessionRow['codEstado']) ?? 1) == 2;

    final participantRows = await db.query(
      'actreu_participantes',
      where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [projectId, subcategoryId],
      orderBy: 'codActReuParticipante DESC',
    );

    final asistenciaRows = await db.query(
      'actreu_asistencias',
      where:
          'codProyecto = ? AND codActReuSubCategoria = ? AND codActReuReuniones = ? AND deleted = 0',
      whereArgs: [projectId, subcategoryId, resolvedSessionId],
    );
    final attendanceByParticipant = <int, bool>{};
    for (final row in asistenciaRows) {
      final participantId = _asInt(row['codActReuParticipante']);
      if (participantId == null) continue;
      attendanceByParticipant[participantId] =
          (_asInt(row['codEstado']) ?? 0) == 1;
    }

    final attendance = participantRows
        .map((row) {
          final participantId = _asInt(row['codActReuParticipante']);
          if (participantId == null) return null;
          return ActreuSessionAttendanceItem(
            participantId: participantId,
            name: _asString(row['desNombre']) ?? '-',
            area: _asString(row['codArea']) ?? '-',
            present: attendanceByParticipant[participantId] ?? false,
          );
        })
        .whereType<ActreuSessionAttendanceItem>()
        .toList();

    final groupRows = await db.query(
      'actreu_grupoacuerdo',
      columns: [
        'codActReuGrupoAcuerdo',
        'desGrupoAcuerdo',
        'desColorGrupoAcuerdo',
      ],
      where: 'deleted = 0',
    );
    final groupById = <int, Map<String, String?>>{
      for (final row in groupRows)
        if (_asInt(row['codActReuGrupoAcuerdo']) != null)
          _asInt(row['codActReuGrupoAcuerdo'])!: {
            'name': _asString(row['desGrupoAcuerdo']) ?? 'Sin grupo',
            'color': _asString(row['desColorGrupoAcuerdo']),
          },
    };
    if (AppRepository._traceActreuGroupResolution) {
      _traceActreuGroupMaster(
        scope: 'session_view',
        projectId: projectId,
        subcategoryId: subcategoryId,
        groupRows: groupRows,
      );
    }

    final commentsCountRows = await db.rawQuery(
      '''
      SELECT codActReuAcuerdos, COUNT(*) as total
      FROM actreu_comentarios_acuerdo
      WHERE codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0
      GROUP BY codActReuAcuerdos
      ''',
      [projectId, subcategoryId],
    );
    final commentsByAgreement = <int, int>{
      for (final row in commentsCountRows)
        if (_asInt(row['codActReuAcuerdos']) != null)
          _asInt(row['codActReuAcuerdos'])!: _asInt(row['total']) ?? 0,
    };

    final agreementRows = isClosedSession
        ? await db.query(
            'actreu_acuerdosfoto',
            where:
                'codProyecto = ? AND codActReuSubCategoria = ? AND codActReuReuniones = ? AND deleted = 0',
            whereArgs: [projectId, subcategoryId, resolvedSessionId],
            orderBy: 'codActReuAcuerdosFoto DESC',
          )
        : await db.query(
            'actreu_acuerdos',
            where:
                'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
            whereArgs: [projectId, subcategoryId],
            orderBy: 'codActReuAcuerdos DESC',
          );

    final agreements = agreementRows
        .map((row) {
          final agreementId =
              _asInt(row['codActReuAcuerdos']) ??
              _asInt(row['codActReuAcuerdosFoto']);
          if (agreementId == null) return null;
          final responsibleUserId = _asInt(row['idUsuarioResponsable']);
          final responsible =
              participantRows
                  .where(
                    (p) =>
                        _asInt(p['codActReuParticipante']) == responsibleUserId,
                  )
                  .map((p) => _asString(p['desNombre']) ?? '-')
                  .firstOrNull ??
              'Sin asignar';
          final groupId = _asInt(row['codGrupoAcuerdo']);
          final groupData = groupById[groupId] ?? const {};
          final resolvedGroupName =
              groupData['name'] ??
              (groupId != null ? 'Grupo $groupId' : 'Sin grupo');
          if (AppRepository._traceActreuGroupResolution) {
            _traceActreuAgreementGroupMatch(
              scope: 'session_view',
              agreementId: agreementId,
              rawGroupId: row['codGrupoAcuerdo'],
              parsedGroupId: groupId,
              resolvedGroupName: resolvedGroupName,
              resolvedGroupColor: groupData['color'],
              foundInMaster: groupData.isNotEmpty,
            );
          }
          final agreementSessionId = _asInt(row['codActReuReuniones']);
          return ActreuSessionAgreementItem(
            agreementId: agreementId,
            description: _asString(row['desAcuerdo']) ?? '-',
            responsible: responsible,
            responsibleParticipantId: responsibleUserId,
            agreementDate: _parseDateOnly(row['dayFechaAcuerdo']),
            dueDate: _parseDateOnly(
              row['dayFechaAplazo'] ?? row['dayFechaAcuerdo'],
            ),
            statusCode: _asInt(row['codEstado']) ?? 1,
            groupId: groupId,
            group: resolvedGroupName,
            groupColorHex: groupData['color'],
            commentsCount:
                commentsByAgreement[_asInt(row['codActReuAcuerdos']) ??
                    agreementId] ??
                0,
            deferralsCount: _asInt(row['numAplazos']) ?? 0,
            isFromPrevious: isClosedSession
                ? false
                : agreementSessionId != resolvedSessionId,
          );
        })
        .whereType<ActreuSessionAgreementItem>()
        .toList();

    final groupNames = groupRows
        .map((row) => _asString(row['desGrupoAcuerdo']))
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    final groupOptions = groupRows
        .map((row) {
          final groupId = _asInt(row['codActReuGrupoAcuerdo']);
          if (groupId == null) return null;
          return ActreuGroupOptionItem(
            groupId: groupId,
            groupName: _asString(row['desGrupoAcuerdo']) ?? 'Sin grupo',
            groupColorHex: _asString(row['desColorGrupoAcuerdo']),
          );
        })
        .whereType<ActreuGroupOptionItem>()
        .toList();

    return ActreuSessionViewData(
      sessionId: resolvedSessionId,
      subcategoryId: subcategoryId,
      sessionTitle: _asString(sessionRow['desNombre']) ?? 'Sesion',
      sessionDate: _parseDateOnly(sessionRow['dayFechaReunion']),
      startTime: _asString(sessionRow['horHoraInicio']) ?? '',
      endTime: _asString(sessionRow['horHoraFin']) ?? '',
      attendance: attendance,
      agreements: agreements,
      groupNames: groupNames,
      groupOptions: groupOptions,
    );
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  _loadActreuRecommendationsForSubcategory(
    Database db, {
    required int projectId,
    required int subcategoryId,
    int? knownActaId,
  }) async {
    int? actaId = knownActaId;
    if (actaId == null) {
      final subRows = await db.query(
        'actreu_subcategoria',
        columns: ['codActReu'],
        where: 'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId],
        limit: 1,
      );
      actaId = subRows.isEmpty ? null : _asInt(subRows.first['codActReu']);
    }

    List<Map<String, Object?>> integrantRows = const [];
    var source = 'acta';
    if (actaId != null) {
      integrantRows = await db.rawQuery(
        '''
        SELECT
          i.codProyIntegrante,
          pm.user_id AS idIntegrante,
          pm.desCorreo,
          usr.name AS desNombreUsuario,
          usr.lastname AS desApellidoUsuario
        FROM actreu_integrantes i
        LEFT JOIN projects_member pm ON pm.codProyIntegrante = i.codProyIntegrante
        LEFT JOIN auth_user usr ON usr.id = pm.user_id
        WHERE i.codProyecto = ? AND i.codActReu = ? AND i.deleted = 0
          AND IFNULL(i.codEstado, 1) = 1
        ORDER BY i.codProyIntegrante DESC
        ''',
        [projectId, actaId],
      );
    }

    if (integrantRows.isEmpty) {
      source = 'project_fallback';
      integrantRows = await db.rawQuery(
        '''
        SELECT
          i.codProyIntegrante,
          pm.user_id AS idIntegrante,
          pm.desCorreo,
          usr.name AS desNombreUsuario,
          usr.lastname AS desApellidoUsuario
        FROM actreu_integrantes i
        LEFT JOIN projects_member pm ON pm.codProyIntegrante = i.codProyIntegrante
        LEFT JOIN auth_user usr ON usr.id = pm.user_id
        WHERE i.codProyecto = ? AND i.deleted = 0
          AND IFNULL(i.codEstado, 1) = 1
        ORDER BY i.codProyIntegrante DESC
        ''',
        [projectId],
      );
    }

    final recommendations = <ActreuSubcategoryRecommendationItem>[];
    final usedMemberIds = <int>{};
    for (final row in integrantRows) {
      final memberId = _asInt(row['codProyIntegrante']);
      if (memberId == null || !usedMemberIds.add(memberId)) continue;
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
        '[ActreuTrace][participants_reco] source=$source project=$projectId '
        'subcategory=$subcategoryId acta=${actaId ?? '-'} member=$memberId '
        'idIntegrante=$integranteId invited=$isInvited '
        'user="$fullName" email="${email ?? '-'}" resolved="$label"',
      );

      recommendations.add(
        ActreuSubcategoryRecommendationItem(
          projectMemberId: memberId,
          label: label,
        ),
      );
    }
    debugPrint(
      '[ActreuTrace][participants_reco] source=$source project=$projectId '
      'subcategory=$subcategoryId acta=${actaId ?? '-'} total=${recommendations.length}',
    );
    return recommendations;
  }

  Future<bool> hasActreuParticipantsConfigured(int subcategoryId) async {
    final db = await _database.database;
    final projectId = await _loadCurrentProjectId(db);
    if (projectId == null) return false;
    final total =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_participantes
            WHERE codProyecto = ?
              AND codActReuSubCategoria = ?
              AND deleted = 0
              AND IFNULL(codEstado, 1) = 1
            ''',
            [projectId, subcategoryId],
          ),
        ) ??
        0;
    return total > 0;
  }

  Future<int?> createActreuParticipant({
    required int subcategoryId,
    required String name,
    String? area,
    int? projectMemberId,
  }) async {
    final db = await _database.database;
    final subcategoryRows = await db.query(
      'actreu_subcategoria',
      columns: ['codProyecto', 'codActReu', 'codActReuCategoria'],
      where: 'codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    if (subcategoryRows.isEmpty) {
      throw Exception(
        'No se encontro la subcategoria para registrar participante.',
      );
    }
    final subcategory = subcategoryRows.first;
    final projectId = _asInt(subcategory['codProyecto']);
    final actaId = _asInt(subcategory['codActReu']);
    final categoryId = _asInt(subcategory['codActReuCategoria']);
    if (projectId == null || actaId == null || categoryId == null) {
      throw Exception('No se pudo resolver la jerarquia de la subcategoria.');
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw Exception('El nombre del participante es obligatorio.');
    }

    if (projectMemberId != null) {
      final existingByMember = await db.query(
        'actreu_participantes',
        columns: ['codActReuParticipante'],
        where:
            'codProyecto = ? AND codActReuSubCategoria = ? AND codProyIntegrante = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId, projectMemberId],
        limit: 1,
      );
      if (existingByMember.isNotEmpty) {
        return _asInt(existingByMember.first['codActReuParticipante']);
      }
    } else {
      final existingByName = await db.query(
        'actreu_participantes',
        columns: ['codActReuParticipante'],
        where:
            'codProyecto = ? AND codActReuSubCategoria = ? AND LOWER(desNombre) = ? AND deleted = 0',
        whereArgs: [projectId, subcategoryId, normalizedName.toLowerCase()],
        limit: 1,
      );
      if (existingByName.isNotEmpty) {
        return _asInt(existingByName.first['codActReuParticipante']);
      }
    }

    String? resolvedName = normalizedName;
    String? resolvedArea = area?.trim().isNotEmpty == true
        ? area!.trim()
        : null;
    String? resolvedEmail;
    int? resolvedUserId;
    var invitedFlag = 1;

    if (projectMemberId != null) {
      final memberRows = await db.rawQuery(
        '''
        SELECT
          pm.user_id,
          pm.codArea,
          pm.desArea,
          pm.desCorreo,
          usr.name AS desNombreUsuario,
          usr.lastname AS desApellidoUsuario
        FROM projects_member pm
        LEFT JOIN auth_user usr ON usr.id = pm.user_id
        WHERE pm.codProyecto = ? AND pm.codProyIntegrante = ?
        LIMIT 1
        ''',
        [projectId, projectMemberId],
      );
      if (memberRows.isNotEmpty) {
        final row = memberRows.first;
        final firstName = _asString(row['desNombreUsuario']) ?? '';
        final lastName = _asString(row['desApellidoUsuario']) ?? '';
        final fullName = '$firstName $lastName'.trim();
        resolvedName = fullName.isNotEmpty ? fullName : normalizedName;
        final memberAreaCode = _asInt(row['codArea']);
        if (memberAreaCode != null) {
          resolvedArea = '$memberAreaCode';
        } else if (resolvedArea == null || resolvedArea.trim().isEmpty) {
          resolvedArea = _asString(row['desArea']);
        }
        resolvedEmail = _asString(row['desCorreo']);
        resolvedUserId = _asInt(row['user_id']);
        invitedFlag = (resolvedUserId == null || resolvedUserId == -999)
            ? 1
            : 0;
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final participantId = await _nextActreuParticipantId(db);

    await db.insert('actreu_participantes', {
      'codActReuParticipante': participantId,
      'codProyecto': projectId,
      'codActReu': actaId,
      'codActReuCategoria': categoryId,
      'codActReuSubCategoria': subcategoryId,
      'desNombre': resolvedName,
      'codArea': resolvedArea,
      'desCorreoElectronico': resolvedEmail,
      'idUsuarioParticipante': resolvedUserId,
      'codProyIntegrante': projectMemberId,
      'flgParticipanteInvitado': invitedFlag,
      'codEstado': 1,
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': actor,
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': actor,
      'updated_at': nowIso,
      'deleted': 0,
    });

    await _enqueueSync(
      db,
      entityType: 'actreu_participante',
      entityId: '$participantId',
      operationType: 'create',
      payload: await _buildActreuParticipantSyncPayload(db, participantId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_participante',
        entityId: '$participantId',
        operationType: 'create',
        parentRefs: [('actreu_subcategoria', '$subcategoryId')],
      ),
    );

    return participantId;
  }

  Future<int> createActreuSessionNow({
    required int subcategoryId,
    required DateTime sessionDate,
    required String sessionStartTime,
  }) async {
    final hasParticipants = await hasActreuParticipantsConfigured(
      subcategoryId,
    );
    if (!hasParticipants) {
      throw Exception(
        'Antes de iniciar una sesiÃƒÂ³n debes registrar participantes en la subcategorÃƒÂ­a.',
      );
    }
    final db = await _database.database;
    final subcategoryRows = await db.query(
      'actreu_subcategoria',
      columns: [
        'codProyecto',
        'codActReu',
        'codActReuCategoria',
        'codActReuSubCategoria',
      ],
      where: 'codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    if (subcategoryRows.isEmpty) {
      throw Exception(
        'No se encontrÃƒÂ³ la subcategorÃƒÂ­a para iniciar la sesiÃƒÂ³n no programada.',
      );
    }

    final subcategory = subcategoryRows.first;
    final projectId = _asInt(subcategory['codProyecto']);
    if (projectId == null) {
      throw Exception('No se pudo resolver el proyecto de la subcategorÃƒÂ­a.');
    }

    final normalizedDate = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );
    final nowIso = DateTime.now().toIso8601String();
    final nextSessionId = await _nextActreuSessionId(db);
    final actor = await _resolveCurrentActorName(db);
    final day = normalizedDate.day.toString().padLeft(2, '0');
    final month = normalizedDate.month.toString().padLeft(2, '0');

    await db.insert('actreu_reuniones', {
      'codActReuReuniones': nextSessionId,
      'codProyecto': projectId,
      'codActReu': _asInt(subcategory['codActReu']),
      'codActReuCategoria': _asInt(subcategory['codActReuCategoria']),
      'codActReuSubCategoria': subcategoryId,
      'desNombre': 'Sesion no programada $day/$month/${normalizedDate.year}',
      'dayFechaReunion': _formatDate(normalizedDate),
      'dayFechaCierre': null,
      'horHoraInicio': _normalizeHourMinute(sessionStartTime),
      'horHoraFin': null,
      'codEstado': 1,
      'desLinkActaReunion': null,
      'groupedActReu': null,
      'desNombreArchivoActaGenerada': null,
      'desNombreArchivoActaGeneradaFirmada': null,
      'desUrlDireccionActaGenerada': null,
      'desUrlDireccionActaGeneradaFirmada': null,
      'ordenGruposAcuerdo': null,
      'ordenGruposAcuerdoAnteriores': null,
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': actor,
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': actor,
      'updated_at': nowIso,
      'deleted': 0,
    });

    await _enqueueSync(
      db,
      entityType: 'actreu_reunion',
      entityId: '$nextSessionId',
      operationType: 'create',
      payload: await _buildActreuSessionSyncPayload(db, nextSessionId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_reunion',
        entityId: '$nextSessionId',
        operationType: 'create',
        parentRefs: [('actreu_subcategoria', '$subcategoryId')],
      ),
    );

    return nextSessionId;
  }

  Future<int> scheduleActreuSessions({
    required int subcategoryId,
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
    required String sessionStartTime,
    required Set<int> weekdays,
    int? monthlyDay,
  }) async {
    final hasParticipants = await hasActreuParticipantsConfigured(
      subcategoryId,
    );
    if (!hasParticipants) {
      throw Exception(
        'Antes de programar sesiones debes registrar participantes en la subcategorÃƒÂ­a.',
      );
    }

    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw Exception(
        'La fecha fin debe ser mayor o igual a la fecha de inicio.',
      );
    }

    final db = await _database.database;
    final subcategoryRows = await db.query(
      'actreu_subcategoria',
      columns: [
        'codProyecto',
        'codActReu',
        'codActReuCategoria',
        'codActReuSubCategoria',
      ],
      where: 'codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    if (subcategoryRows.isEmpty) {
      throw Exception(
        'No se encontrÃƒÂ³ la subcategorÃƒÂ­a para programar sesiones.',
      );
    }
    final subcategory = subcategoryRows.first;
    final projectId = _asInt(subcategory['codProyecto']);
    if (projectId == null) {
      throw Exception('No se pudo resolver el proyecto de la subcategorÃƒÂ­a.');
    }

    final candidateDates = _buildActreuScheduleDates(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      frequency: frequency,
      weekdays: weekdays,
      monthlyDay: monthlyDay,
    );
    if (candidateDates.isEmpty) {
      return 0;
    }

    final existingRows = await db.query(
      'actreu_reuniones',
      columns: ['dayFechaReunion'],
      where:
          'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0 AND dayFechaReunion >= ? AND dayFechaReunion <= ?',
      whereArgs: [
        projectId,
        subcategoryId,
        _formatDate(normalizedStart),
        _formatDate(normalizedEnd),
      ],
    );
    final existingDates = existingRows
        .map((row) => _asString(row['dayFechaReunion']))
        .whereType<String>()
        .toSet();

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final safeStartTime = _normalizeHourMinute(sessionStartTime);

    var createdCount = 0;
    for (final date in candidateDates) {
      final dateKey = _formatDate(date);
      if (existingDates.contains(dateKey)) {
        continue;
      }
      final nextSessionId = await _nextActreuSessionId(db);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      await db.insert('actreu_reuniones', {
        'codActReuReuniones': nextSessionId,
        'codProyecto': projectId,
        'codActReu': _asInt(subcategory['codActReu']),
        'codActReuCategoria': _asInt(subcategory['codActReuCategoria']),
        'codActReuSubCategoria': subcategoryId,
        'desNombre': 'Sesion programada $day/$month/${date.year}',
        'dayFechaReunion': dateKey,
        'dayFechaCierre': null,
        'horHoraInicio': safeStartTime,
        'horHoraFin': null,
        'codEstado': 1,
        'desLinkActaReunion': null,
        'groupedActReu': null,
        'desNombreArchivoActaGenerada': null,
        'desNombreArchivoActaGeneradaFirmada': null,
        'desUrlDireccionActaGenerada': null,
        'desUrlDireccionActaGeneradaFirmada': null,
        'ordenGruposAcuerdo': null,
        'ordenGruposAcuerdoAnteriores': null,
        'dayFechaCreacion': nowIso,
        'desUsuarioCreacion': actor,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
        'deleted': 0,
      });

      await _enqueueSync(
        db,
        entityType: 'actreu_reunion',
        entityId: '$nextSessionId',
        operationType: 'create',
        payload: await _buildActreuSessionSyncPayload(db, nextSessionId),
        isFromRemoteTable: await _resolveActreuLocalLineageFlag(
          db,
          entityType: 'actreu_reunion',
          entityId: '$nextSessionId',
          operationType: 'create',
          parentRefs: [('actreu_subcategoria', '$subcategoryId')],
        ),
      );
      existingDates.add(dateKey);
      createdCount++;
    }

    return createdCount;
  }

  Future<void> deleteActreuSession(int sessionId) async {
    final db = await _database.database;
    final rows = await db.query(
      'actreu_reuniones',
      where: 'codActReuReuniones = ? AND deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('No se encontrÃƒÂ³ la sesiÃƒÂ³n.');
    }
    final session = rows.first;
    final status = _asInt(session['codEstado']) ?? 1;
    final agreementsCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_acuerdos
            WHERE codActReuReuniones = ?
              AND deleted = 0
            ''',
            [sessionId],
          ),
        ) ??
        0;
    final attendanceCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_asistencias
            WHERE codActReuReuniones = ?
              AND deleted = 0
            ''',
            [sessionId],
          ),
        ) ??
        0;
    if (status == 2 || agreementsCount > 0 || attendanceCount > 0) {
      throw Exception(
        'No se puede eliminar la sesiÃƒÂ³n porque ya fue iniciada o tiene datos registrados.',
      );
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_reuniones',
      {
        'deleted': 1,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuReuniones = ?',
      whereArgs: [sessionId],
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_reunion',
      entityId: '$sessionId',
      operationType: 'delete',
      payload: await _buildActreuSessionDeleteSyncPayload(db, sessionId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_reunion',
        entityId: '$sessionId',
        operationType: 'delete',
      ),
    );
  }

  Future<void> deleteActreuParticipant(int participantId) async {
    final db = await _database.database;
    final rows = await db.query(
      'actreu_participantes',
      where: 'codActReuParticipante = ? AND deleted = 0',
      whereArgs: [participantId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('No se encontrÃƒÂ³ el participante.');
    }

    final assignedAgreementCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM actreu_acuerdos
            WHERE idUsuarioResponsable = ?
              AND deleted = 0
            ''',
            [participantId],
          ),
        ) ??
        0;
    if (assignedAgreementCount > 0) {
      throw Exception(
        'No se puede eliminar el participante porque estÃƒÂ¡ asignado a acuerdos.',
      );
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_participantes',
      {
        'deleted': 1,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuParticipante = ?',
      whereArgs: [participantId],
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_participante',
      entityId: '$participantId',
      operationType: 'delete',
      payload: await _buildActreuParticipantDeleteSyncPayload(
        db,
        participantId,
      ),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_participante',
        entityId: '$participantId',
        operationType: 'delete',
      ),
    );
  }

  Future<void> deleteActreuAgreement({
    required int agreementId,
    required int sessionId,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'actreu_acuerdos',
      where: 'codActReuAcuerdos = ? AND deleted = 0',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('No se encontrÃƒÂ³ el acuerdo.');
    }
    final agreement = rows.first;
    final agreementSessionId = _asInt(agreement['codActReuReuniones']);
    if (agreementSessionId == null || agreementSessionId != sessionId) {
      throw Exception(
        'Solo se pueden eliminar acuerdos creados en la sesiÃƒÂ³n actual.',
      );
    }

    final sessionRows = await db.query(
      'actreu_reuniones',
      columns: ['codEstado'],
      where: 'codActReuReuniones = ? AND deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (sessionRows.isNotEmpty) {
      final sessionStatus = _asInt(sessionRows.first['codEstado']) ?? 1;
      if (sessionStatus == 2) {
        throw Exception(
          'No se puede eliminar acuerdos en una sesiÃƒÂ³n cerrada.',
        );
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    await db.update(
      'actreu_acuerdos',
      {
        'deleted': 1,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_acuerdo',
      entityId: '$agreementId',
      operationType: 'delete',
      payload: await _buildActreuAgreementDeleteSyncPayload(db, agreementId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_acuerdo',
        entityId: '$agreementId',
        operationType: 'delete',
      ),
    );
  }

  Future<void> upsertActreuAttendance({
    required int sessionId,
    required int participantId,
    required bool present,
  }) async {
    final db = await _database.database;
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);

    final participantRows = await db.query(
      'actreu_participantes',
      where: 'codActReuParticipante = ? AND deleted = 0',
      whereArgs: [participantId],
      limit: 1,
    );
    if (participantRows.isEmpty) {
      throw Exception(
        'No se encontro el participante para registrar asistencia.',
      );
    }
    final participant = participantRows.first;
    final projectId = _asInt(participant['codProyecto']);
    final subcategoryId = _asInt(participant['codActReuSubCategoria']);
    if (projectId == null || subcategoryId == null) {
      throw Exception(
        'No se pudo resolver proyecto/subcategoria para la asistencia.',
      );
    }

    final existingRows = await db.query(
      'actreu_asistencias',
      where:
          'codProyecto = ? AND codActReuReuniones = ? AND codActReuParticipante = ? AND deleted = 0',
      whereArgs: [projectId, sessionId, participantId],
      limit: 1,
    );

    int attendanceId;
    if (existingRows.isNotEmpty) {
      attendanceId = _asInt(existingRows.first['codActReuAsistencia']) ?? 0;
      if (attendanceId <= 0) {
        attendanceId = await _nextActreuAttendanceId(db);
      }
      await db.update(
        'actreu_asistencias',
        {
          'codEstado': present ? 1 : 0,
          'desNombre': _asString(participant['desNombre']),
          'desCorreoElectronico': _asString(
            participant['desCorreoElectronico'],
          ),
          'idUsuarioParticipante': _asInt(participant['idUsuarioParticipante']),
          'codProyIntegrante': _asInt(participant['codProyIntegrante']),
          'dayFechaModificacion': nowIso,
          'desUsuarioModificacion': actor,
          'updated_at': nowIso,
          'deleted': 0,
        },
        where: 'codActReuAsistencia = ?',
        whereArgs: [attendanceId],
      );
    } else {
      attendanceId = await _nextActreuAttendanceId(db);
      await db.insert('actreu_asistencias', {
        'codActReuAsistencia': attendanceId,
        'codProyecto': projectId,
        'codActReu': _asInt(participant['codActReu']),
        'codActReuCategoria': _asInt(participant['codActReuCategoria']),
        'codActReuSubCategoria': subcategoryId,
        'codActReuReuniones': sessionId,
        'codEstado': present ? 1 : 0,
        'desNombre': _asString(participant['desNombre']),
        'desCorreoElectronico': _asString(participant['desCorreoElectronico']),
        'idUsuarioParticipante': _asInt(participant['idUsuarioParticipante']),
        'codProyIntegrante': _asInt(participant['codProyIntegrante']),
        'codActReuParticipante': participantId,
        'desJustificacion': null,
        'dayFechaCreacion': nowIso,
        'desUsuarioCreacion': actor,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
        'deleted': 0,
      });
    }

    await _enqueueSync(
      db,
      entityType: 'actreu_asistencia',
      entityId: '$attendanceId',
      operationType: existingRows.isEmpty ? 'create' : 'update',
      payload: await _buildActreuAttendanceSyncPayload(db, attendanceId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_asistencia',
        entityId: '$attendanceId',
        operationType: existingRows.isEmpty ? 'create' : 'update',
        parentRefs: [
          ('actreu_reunion', '$sessionId'),
          ('actreu_participante', '$participantId'),
        ],
      ),
    );
  }

  Future<int> createActreuAgreement({
    required int subcategoryId,
    required int sessionId,
    required String description,
    required DateTime agreementDate,
    required bool isInformative,
    int? responsibleParticipantId,
    int? groupId,
    String? groupName,
  }) async {
    final db = await _database.database;
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);

    final sessionRows = await db.query(
      'actreu_reuniones',
      where:
          'codActReuReuniones = ? AND codActReuSubCategoria = ? AND deleted = 0',
      whereArgs: [sessionId, subcategoryId],
      limit: 1,
    );
    if (sessionRows.isEmpty) {
      throw Exception('No se encontro la sesion para registrar el acuerdo.');
    }
    final session = sessionRows.first;
    final projectId = _asInt(session['codProyecto']);
    if (projectId == null) {
      throw Exception('No se pudo resolver el proyecto de la sesion.');
    }

    int? resolvedGroupId = groupId;
    if (resolvedGroupId != null) {
      final exists = await _meetingGroupExists(db, resolvedGroupId);
      if (!exists) {
        resolvedGroupId = null;
      }
    }
    if (resolvedGroupId == null &&
        groupName != null &&
        groupName.trim().isNotEmpty) {
      final groupRows = await db.query(
        'actreu_grupoacuerdo',
        columns: ['codActReuGrupoAcuerdo'],
        where:
            '(codProyecto = ? OR codProyecto IS NULL) AND deleted = 0 AND LOWER(TRIM(desGrupoAcuerdo)) = ?',
        whereArgs: [projectId, groupName.trim().toLowerCase()],
        limit: 1,
      );
      if (groupRows.isNotEmpty) {
        resolvedGroupId = _asInt(groupRows.first['codActReuGrupoAcuerdo']);
      } else {
        final createdGroupId = await _nextActreuGroupId(db);
        await db.insert('actreu_grupoacuerdo', {
          'codActReuGrupoAcuerdo': createdGroupId,
          'codProyecto': projectId,
          'desGrupoAcuerdo': groupName.trim(),
          'desColorGrupoAcuerdo': '#9CA3AF',
          'codOptionalArea': null,
          'updated_at': nowIso,
          'deleted': 0,
        });
        resolvedGroupId = createdGroupId;
      }
    }

    if (responsibleParticipantId != null) {
      final participantExists = await _meetingParticipantExists(
        db,
        responsibleParticipantId,
      );
      if (!participantExists) {
        responsibleParticipantId = null;
      }
    }

    final agreementId = await _nextActreuAgreementId(db);
    await db.insert('actreu_acuerdos', {
      'codActReuAcuerdos': agreementId,
      'codProyecto': projectId,
      'codActReu': _asInt(session['codActReu']),
      'codActReuCategoria': _asInt(session['codActReuCategoria']),
      'codActReuSubCategoria': subcategoryId,
      'codActReuReuniones': sessionId,
      'desAcuerdo': description.trim(),
      'dayFechaAcuerdo': _formatDate(agreementDate),
      'dayFechaAplazo': null,
      'dayFechaLevantamiento': null,
      'numAplazos': 0,
      'idUsuarioResponsable': isInformative ? null : responsibleParticipantId,
      'codEstado': isInformative ? 6 : 1,
      'numOrden': '$agreementId',
      'dayFechaCreacion': nowIso,
      'desUsuarioCreacion': actor,
      'dayFechaModificacion': nowIso,
      'desUsuarioModificacion': actor,
      'codGrupoAcuerdo': resolvedGroupId,
      'numOrdenAnteriores': null,
      'updated_at': nowIso,
      'deleted': 0,
    });

    await _enqueueSync(
      db,
      entityType: 'actreu_acuerdo',
      entityId: '$agreementId',
      operationType: 'create',
      payload: await _buildActreuAgreementSyncPayload(db, agreementId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_acuerdo',
        entityId: '$agreementId',
        operationType: 'create',
        parentRefs: [
          ('actreu_reunion', '$sessionId'),
          ('actreu_subcategoria', '$subcategoryId'),
        ],
      ),
    );

    return agreementId;
  }

  Future<void> updateActreuAgreementStatus({
    required int agreementId,
    required int statusCode,
  }) async {
    final db = await _database.database;
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final rows = await db.query(
      'actreu_acuerdos',
      where: 'codActReuAcuerdos = ? AND deleted = 0',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final agreementRow = rows.first;
    final previousStatusCode = _asInt(agreementRow['codEstado']) ?? 1;
    if (previousStatusCode == 6 && statusCode != 6) {
      debugPrint(
        '[ActreuStateTrace][status_update] agreement=$agreementId '
        'blocked=true reason=informative current=6 requested=$statusCode',
      );
      return;
    }
    final agreementDate = _parseDateOnly(agreementRow['dayFechaAcuerdo']);
    final deferredDate = _parseDateOnly(agreementRow['dayFechaAplazo']);
    final resolvedStatusCode = statusCode == 3
        ? 3
        : _resolveActreuAgreementStatusCode(
            currentStatusCode: statusCode,
            agreementDate: agreementDate,
            deferredDate: deferredDate,
            today: DateTime.now(),
          );
    final previousLiftDate = _asString(agreementRow['dayFechaLevantamiento']);
    final resolvedLiftDate = resolvedStatusCode == 3
        ? (previousLiftDate ?? nowIso)
        : null;

    await db.update(
      'actreu_acuerdos',
      {
        'codEstado': resolvedStatusCode,
        'dayFechaLevantamiento': resolvedLiftDate,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
    );
    debugPrint(
      '[ActreuStateTrace][status_update] agreement=$agreementId '
      'previous=$previousStatusCode requested=$statusCode resolved=$resolvedStatusCode',
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_acuerdo',
      entityId: '$agreementId',
      operationType: 'update',
      payload: await _buildActreuAgreementSyncPayload(db, agreementId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_acuerdo',
        entityId: '$agreementId',
        operationType: 'update',
      ),
    );
  }

  Future<void> deferActreuAgreement({
    required int agreementId,
    required DateTime newDueDate,
  }) async {
    final db = await _database.database;
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final rows = await db.query(
      'actreu_acuerdos',
      columns: ['numAplazos', 'dayFechaAcuerdo', 'codEstado'],
      where: 'codActReuAcuerdos = ? AND deleted = 0',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final currentStatusCode = _asInt(rows.first['codEstado']) ?? 1;
    if (currentStatusCode == 6) {
      debugPrint(
        '[ActreuStateTrace][defer] agreement=$agreementId blocked=true '
        'reason=informative current=6',
      );
      return;
    }
    final plannedDate = _parseDateOnly(rows.first['dayFechaAcuerdo']);
    if (plannedDate != null) {
      final normalizedPlanned = DateTime(
        plannedDate.year,
        plannedDate.month,
        plannedDate.day,
      );
      final normalizedNewDue = DateTime(
        newDueDate.year,
        newDueDate.month,
        newDueDate.day,
      );
      if (!normalizedNewDue.isAfter(normalizedPlanned)) {
        throw Exception(
          'La fecha de aplazo debe ser mayor a la fecha de acuerdo original.',
        );
      }
    }
    final previousDeferrals = _asInt(rows.first['numAplazos']) ?? 0;
    final resolvedStatusCode = _resolveActreuAgreementStatusCode(
      currentStatusCode: currentStatusCode,
      agreementDate: plannedDate,
      deferredDate: DateTime(newDueDate.year, newDueDate.month, newDueDate.day),
      today: DateTime.now(),
    );

    await db.update(
      'actreu_acuerdos',
      {
        'dayFechaAplazo': _formatDate(newDueDate),
        'numAplazos': previousDeferrals + 1,
        'codEstado': resolvedStatusCode,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
    );
    debugPrint(
      '[ActreuStateTrace][defer] agreement=$agreementId '
      'previous=$currentStatusCode resolved=$resolvedStatusCode '
      'newDue=${_formatDate(newDueDate)} numAplazos=${previousDeferrals + 1}',
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_acuerdo',
      entityId: '$agreementId',
      operationType: 'update',
      payload: await _buildActreuAgreementSyncPayload(db, agreementId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_acuerdo',
        entityId: '$agreementId',
        operationType: 'update',
      ),
    );
  }

  Future<void> updateActreuAgreement({
    required int agreementId,
    required String description,
    required DateTime dueDate,
    required int statusCode,
    int? responsibleParticipantId,
    int? groupId,
  }) async {
    final db = await _database.database;
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final rows = await db.query(
      'actreu_acuerdos',
      where: 'codActReuAcuerdos = ? AND deleted = 0',
      whereArgs: [agreementId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final agreementRow = rows.first;
    final previousStatusCode = _asInt(agreementRow['codEstado']) ?? 1;

    int? resolvedGroupId = groupId;
    if (resolvedGroupId != null) {
      final groupExists = await _meetingGroupExists(db, resolvedGroupId);
      if (!groupExists) resolvedGroupId = null;
    }
    int? resolvedResponsible = responsibleParticipantId;
    if (resolvedResponsible != null) {
      final participantExists = await _meetingParticipantExists(
        db,
        resolvedResponsible,
      );
      if (!participantExists) resolvedResponsible = null;
    }

    final baseAgreementDate = _parseDateOnly(agreementRow['dayFechaAcuerdo']);
    final previousDueDate = _parseDateOnly(
      agreementRow['dayFechaAplazo'] ?? agreementRow['dayFechaAcuerdo'],
    );
    final previousDeferrals = _asInt(agreementRow['numAplazos']) ?? 0;
    if (baseAgreementDate != null) {
      final normalizedBase = DateTime(
        baseAgreementDate.year,
        baseAgreementDate.month,
        baseAgreementDate.day,
      );
      final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (normalizedDue.isBefore(normalizedBase)) {
        throw Exception(
          'La fecha de acuerdo no puede ser menor a la fecha original.',
        );
      }
    }
    final resolvedDeferralDate =
        (baseAgreementDate != null &&
            DateTime(dueDate.year, dueDate.month, dueDate.day).isAfter(
              DateTime(
                baseAgreementDate.year,
                baseAgreementDate.month,
                baseAgreementDate.day,
              ),
            ))
        ? _formatDate(dueDate)
        : null;
    final normalizedNewDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final normalizedPreviousDue = previousDueDate == null
        ? null
        : DateTime(
            previousDueDate.year,
            previousDueDate.month,
            previousDueDate.day,
          );
    final shouldIncrementDeferrals =
        resolvedDeferralDate != null &&
        normalizedPreviousDue != null &&
        normalizedNewDue.isAfter(normalizedPreviousDue);
    final resolvedDeferralsCount = shouldIncrementDeferrals
        ? previousDeferrals + 1
        : previousDeferrals;
    final previousLiftDate = _asString(agreementRow['dayFechaLevantamiento']);
    final resolvedStatusCode = previousStatusCode == 6
        ? 6
        : statusCode == 3
        ? 3
        : _resolveActreuAgreementStatusCode(
            currentStatusCode: statusCode,
            agreementDate: baseAgreementDate,
            deferredDate: resolvedDeferralDate == null
                ? null
                : _parseDateOnly(resolvedDeferralDate),
            today: DateTime.now(),
          );
    final resolvedLiftDate = resolvedStatusCode == 3
        ? (previousLiftDate ?? nowIso)
        : null;

    await db.update(
      'actreu_acuerdos',
      {
        'desAcuerdo': description.trim(),
        'dayFechaAplazo': resolvedDeferralDate,
        'numAplazos': resolvedDeferralsCount,
        'dayFechaLevantamiento': resolvedLiftDate,
        'idUsuarioResponsable': resolvedStatusCode == 6
            ? null
            : resolvedResponsible,
        'codGrupoAcuerdo': resolvedGroupId,
        'codEstado': resolvedStatusCode,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
    );
    debugPrint(
      '[ActreuStateTrace][update] agreement=$agreementId '
      'previous=$previousStatusCode requested=$statusCode resolved=$resolvedStatusCode '
      'aplazo=$resolvedDeferralDate numAplazos=$resolvedDeferralsCount',
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_acuerdo',
      entityId: '$agreementId',
      operationType: 'update',
      payload: await _buildActreuAgreementSyncPayload(db, agreementId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_acuerdo',
        entityId: '$agreementId',
        operationType: 'update',
      ),
    );
  }

  int _resolveActreuAgreementStatusCode({
    required int? currentStatusCode,
    required DateTime? agreementDate,
    required DateTime? deferredDate,
    required DateTime today,
  }) {
    final current = currentStatusCode ?? 1;
    if (current == 3 || current == 6) return current;
    final base = agreementDate == null
        ? null
        : DateTime(agreementDate.year, agreementDate.month, agreementDate.day);
    final deferred = deferredDate == null
        ? null
        : DateTime(deferredDate.year, deferredDate.month, deferredDate.day);
    final due = deferred ?? base;
    if (due == null) return 1;
    final nowDate = DateTime(today.year, today.month, today.day);
    if (due.isBefore(nowDate)) {
      return deferred != null ? 5 : 4;
    }
    if (deferred != null) return 2;
    return 1;
  }

  Future<int> _normalizeActreuAgreementStatusesForSync(Database db) async {
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final rows = await db.query(
      'actreu_acuerdos',
      columns: [
        'codActReuAcuerdos',
        'codEstado',
        'dayFechaAcuerdo',
        'dayFechaAplazo',
        'deleted',
      ],
      where: 'deleted = 0',
    );
    var updatedCount = 0;
    for (final row in rows) {
      final agreementId = _asInt(row['codActReuAcuerdos']);
      if (agreementId == null) continue;
      final currentStatus = _asInt(row['codEstado']) ?? 1;
      if (currentStatus == 6) {
        debugPrint(
          '[ActreuStateTrace][normalize] agreement=$agreementId '
          'skipped=true reason=informative status=6',
        );
        continue;
      }
      final resolvedStatus = _resolveActreuAgreementStatusCode(
        currentStatusCode: currentStatus,
        agreementDate: _parseDateOnly(row['dayFechaAcuerdo']),
        deferredDate: _parseDateOnly(row['dayFechaAplazo']),
        today: DateTime.now(),
      );
      if (resolvedStatus == currentStatus) continue;
      await db.update(
        'actreu_acuerdos',
        {
          'codEstado': resolvedStatus,
          'dayFechaModificacion': nowIso,
          'desUsuarioModificacion': actor,
          'updated_at': nowIso,
        },
        where: 'codActReuAcuerdos = ?',
        whereArgs: [agreementId],
      );
      await _enqueueSync(
        db,
        entityType: 'actreu_acuerdo',
        entityId: '$agreementId',
        operationType: 'update',
        payload: await _buildActreuAgreementSyncPayload(db, agreementId),
        isFromRemoteTable: await _resolveActreuLocalLineageFlag(
          db,
          entityType: 'actreu_acuerdo',
          entityId: '$agreementId',
          operationType: 'update',
        ),
      );
      debugPrint(
        '[ActreuStateTrace][normalize] agreement=$agreementId '
        'previous=$currentStatus resolved=$resolvedStatus',
      );
      updatedCount++;
    }
    debugPrint('[ActreuStateTrace][normalize] updated=$updatedCount');
    return updatedCount;
  }

  Future<void> closeActreuSession(int sessionId) async {
    final db = await _database.database;
    final nowIso = DateTime.now().toIso8601String();
    final actor = await _resolveCurrentActorName(db);
    final rows = await db.query(
      'actreu_reuniones',
      where: 'codActReuReuniones = ? AND deleted = 0',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final sessionRow = rows.first;

    await _snapshotActreuSessionAgreements(
      db: db,
      sessionId: sessionId,
      sessionRow: sessionRow,
      nowIso: nowIso,
      actor: actor,
    );

    await db.update(
      'actreu_reuniones',
      {
        'codEstado': 2,
        'dayFechaCierre': nowIso,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
      },
      where: 'codActReuReuniones = ?',
      whereArgs: [sessionId],
    );

    await _enqueueSync(
      db,
      entityType: 'actreu_reunion',
      entityId: '$sessionId',
      operationType: 'update',
      payload: await _buildActreuSessionSyncPayload(db, sessionId),
      isFromRemoteTable: await _resolveActreuLocalLineageFlag(
        db,
        entityType: 'actreu_reunion',
        entityId: '$sessionId',
        operationType: 'update',
      ),
    );
  }

  Future<void> _snapshotActreuSessionAgreements({
    required Database db,
    required int sessionId,
    required Map<String, Object?> sessionRow,
    required String nowIso,
    required String actor,
  }) async {
    final projectId = _asInt(sessionRow['codProyecto']);
    final actaId = _asInt(sessionRow['codActReu']);
    final categoryId = _asInt(sessionRow['codActReuCategoria']);
    final subcategoryId = _asInt(sessionRow['codActReuSubCategoria']);
    if (projectId == null || subcategoryId == null) return;

    await db.delete(
      'actreu_acuerdosfoto',
      where: 'codActReuReuniones = ?',
      whereArgs: [sessionId],
    );

    final agreementRows = await db.query(
      'actreu_acuerdos',
      where:
          'codProyecto = ? AND codActReuSubCategoria = ? AND deleted = 0 AND codEstado != 3',
      whereArgs: [projectId, subcategoryId],
      orderBy: 'codActReuAcuerdos ASC',
    );

    for (final row in agreementRows) {
      final statusCode = _asInt(row['codEstado']) ?? 1;
      final agreementSessionId = _asInt(row['codActReuReuniones']);
      final isInformative = statusCode == 6;
      if (isInformative && agreementSessionId != sessionId) {
        continue;
      }

      final photoId = await _nextActreuAgreementPhotoId(db);
      await db.insert('actreu_acuerdosfoto', {
        'codActReuAcuerdosFoto': photoId,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']) ?? actaId,
        'codActReuCategoria': _asInt(row['codActReuCategoria']) ?? categoryId,
        'codActReuSubCategoria':
            _asInt(row['codActReuSubCategoria']) ?? subcategoryId,
        'codActReuAcuerdos': _asInt(row['codActReuAcuerdos']),
        'codActReuReuniones': sessionId,
        'desAcuerdo': row['desAcuerdo'],
        'dayFechaAcuerdo': row['dayFechaAcuerdo'],
        'dayFechaAplazo': row['dayFechaAplazo'],
        'dayFechaLevantamiento': row['dayFechaLevantamiento'],
        'numAplazos': _asInt(row['numAplazos']),
        'idUsuarioResponsable': _asInt(row['idUsuarioResponsable']),
        'codGrupoAcuerdo': _asInt(row['codGrupoAcuerdo']),
        'codEstado': statusCode,
        'numOrden': row['numOrden'],
        'dayFechaCreacion': row['dayFechaCreacion'] ?? nowIso,
        'desUsuarioCreacion': row['desUsuarioCreacion'] ?? actor,
        'dayFechaModificacion': nowIso,
        'desUsuarioModificacion': actor,
        'updated_at': nowIso,
        'deleted': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
