part of 'app_repository.dart';

extension AppRepositoryApply on AppRepository {
  Future<void> _applyProjects(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codProyecto']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'projects_project',
          where: 'codProyecto = ?',
          whereArgs: [id],
        );
        continue;
      }

      final projectData = <String, Object?>{
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
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      };
      final updated = await txn.update(
        'projects_project',
        projectData,
        where: 'codProyecto = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        await txn.insert(
          'projects_project',
          projectData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    }
  }

  Future<void> _applyMembers(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codProyIntegrante']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping member $id because project $projectId is missing locally',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'projects_member',
          where: 'codProyIntegrante = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('projects_member', {
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
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyAreaMembers(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codArea']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'projects_area_member',
          where: 'codArea = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('projects_area_member', {
        'codArea': id,
        'desArea': row['desArea'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyRestrictionModules(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaRes']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping restriction module $id because project $projectId is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'analysis_module',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'analysis_module',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      // `codEstado` en anares_analysis es estado funcional del modulo,
      // no una marca de borrado. Solo eliminamos cuando el payload
      // viene explicitamente marcado como `deleted`.
      if (_isDeleted(row)) {
        await txn.delete(
          'anares_analysis',
          where: 'codAnaRes = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('anares_analysis', {
        'codAnaRes': id,
        'codProyecto': projectId,
        'codEstado': _asInt(row['codEstado']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyAnalysisAreas(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaresArea']);
      if (id == null) continue;
      final remoteId = _asInt(
        row['codAnaResAreaRemoto'] ?? row['codAnaresAreaRemoto'],
      );
      if (remoteId != null && remoteId != id) {
        await _reconcileAnalysisAreaRemoteId(
          txn,
          serverId: id,
          remoteId: remoteId,
        );
      }
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping analysis area $id because project $projectId is missing locally',
        );
        continue;
      }
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'anares_area',
          where: 'codAnaresArea = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('anares_area', {
        'codAnaresArea': id,
        'codProyecto': projectId,
        'codArea': _asInt(row['codArea']),
        'desArea': row['desArea'],
        'cod_Empresa': _asInt(row['cod_Empresa'] ?? row['codEmpresa']),
        'bgColor': row['bgColor'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'is_codAnaresAreaLocal':
            _asBoolInt(row['is_codAnaresAreaLocal']) == 1 ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyFronts(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']);
      if (id == null) continue;
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'anares_front',
          where: 'codAnaResFrente = ?',
          whereArgs: [id],
        );
        continue;
      }
      final projectId = _asInt(row['codProyecto']);
      final codAnaRes = _asInt(row['codAnaRes'] ?? row['codAnares']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping front $id because project $projectId is missing locally',
        );
        continue;
      }
      if (codAnaRes != null &&
          !await _restrictionModuleExists(txn, codAnaRes)) {
        debugPrint(
          '[AppRepository] skipping front $id because analysis module $codAnaRes is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'analysis_front',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'analysis_front',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      final frontData = <String, Object?>{
        'codAnaResFrente': id,
        'codProyecto': projectId,
        'codAnaRes': codAnaRes,
        'desAnaResFrente': row['desAnaResFrente'] ?? row['desAnaresFrente'],
        'codEstado': _asInt(row['codEstado']) ?? 1,
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      };
      final updated = await txn.update(
        'anares_front',
        frontData,
        where: 'codAnaResFrente = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        await txn.insert(
          'anares_front',
          frontData,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    }
  }

  Future<void> _applyPhases(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResFase'] ?? row['codAnaresFase']);
      if (id == null) continue;
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'anares_phase',
          where: 'codAnaResFase = ?',
          whereArgs: [id],
        );
        continue;
      }
      final projectId = _asInt(row['codProyecto']);
      final frontId = _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']);
      final codAnaRes = _asInt(row['codAnaRes'] ?? row['codAnares']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping phase $id because project $projectId is missing locally',
        );
        continue;
      }
      if (frontId != null && !await _frontExists(txn, frontId)) {
        debugPrint(
          '[AppRepository] skipping phase $id because front $frontId is missing locally',
        );
        continue;
      }
      if (codAnaRes != null &&
          !await _restrictionModuleExists(txn, codAnaRes)) {
        debugPrint(
          '[AppRepository] skipping phase $id because analysis module $codAnaRes is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'analysis_phase',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'analysis_phase',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      await txn.insert('anares_phase', {
        'codAnaResFase': id,
        'codAnaResFrente': frontId,
        'codProyecto': projectId,
        'codAnaRes': codAnaRes,
        'desAnaResFase': row['desAnaResFase'] ?? row['desAnaresFase'],
        'bgColor': row['bgColor'],
        'codEstado': _asInt(row['codEstado']) ?? 1,
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyTypes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(
        row['codTipoRestriccion'] ?? row['codTipoRestricciones'],
      );
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'anares_type',
          where: 'codTipoRestriccion = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('anares_type', {
        'codTipoRestriccion': id,
        'desTipoRestriccion':
            row['desTipoRestriccion'] ?? row['desTipoRestricciones'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyStatuses(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asString(row['codEstado']);
      if (id == null || id.isEmpty) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'anares_status',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('anares_status', {
        'codEstado': id,
        'desEstado': row['desEstado'],
        'iconColor': row['iconColor'],
        'codModulo': _asInt(row['codModulo']),
        'codElementoControl': _asInt(row['codElementoControl']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyRestrictions(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codAnaResActividad']);
      if (id == null) continue;
      final remoteId = _asInt(row['codAnaResActividadRemoto']);
      if (_isRestrictionActivityDeleted(row)) {
        await txn.delete(
          'anares_restriction',
          where: 'codAnaResActividad = ?',
          whereArgs: [id],
        );
        if (remoteId != null && remoteId != id) {
          await txn.delete(
            'anares_restriction',
            where: 'codAnaResActividad = ?',
            whereArgs: [remoteId],
          );
        }
        continue;
      }
      if (remoteId != null && remoteId != id) {
        await _reconcileRestrictionRemoteId(
          txn,
          serverId: id,
          remoteId: remoteId,
        );
      }
      final projectId = _asInt(row['codProyecto']);
      final codAnaRes = _asInt(row['codAnaRes'] ?? row['codAnares']);
      final frontId = _asInt(row['codAnaResFrente'] ?? row['codAnaresFrente']);
      final phaseId = _asInt(row['codAnaResFase'] ?? row['codAnaresFase']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping restriction $id because project $projectId is missing locally',
        );
        continue;
      }
      if (codAnaRes != null &&
          !await _restrictionModuleExists(txn, codAnaRes)) {
        debugPrint(
          '[AppRepository] skipping restriction $id because analysis module $codAnaRes is missing locally',
        );
        continue;
      }
      if (frontId != null && !await _frontExists(txn, frontId)) {
        debugPrint(
          '[AppRepository] skipping restriction $id because front $frontId is missing locally',
        );
        continue;
      }
      if (phaseId != null && !await _phaseExists(txn, phaseId)) {
        debugPrint(
          '[AppRepository] skipping restriction $id because phase $phaseId is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'restriction',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'restriction',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      final statusCode = _asString(row['codEstadoActividad']) ?? '';
      await txn.insert('anares_restriction', {
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
        'priority_order':
            _asInt(row['priority_order']) ??
            _priorityOrder(
              _restrictionStatusKind(
                statusCode,
                statusLabel: _asString(row['desEstadoActividad']) ?? '',
              ),
            ),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'sync_status': 'synced',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _reconcileRestrictionRemoteId(
    DatabaseExecutor txn, {
    required int serverId,
    required int remoteId,
  }) async {
    final tempRows = await txn.query(
      'anares_restriction',
      columns: ['codAnaResActividad'],
      where: 'codAnaResActividad = ?',
      whereArgs: [remoteId],
      limit: 1,
    );
    if (tempRows.isEmpty) return;

    final serverRows = await txn.query(
      'anares_restriction',
      columns: ['codAnaResActividad'],
      where: 'codAnaResActividad = ?',
      whereArgs: [serverId],
      limit: 1,
    );

    // Si ya existe el ID de servidor, eliminamos el temporal para evitar duplicado.
    if (serverRows.isNotEmpty) {
      await txn.delete(
        'anares_restriction',
        where: 'codAnaResActividad = ?',
        whereArgs: [remoteId],
      );
    } else {
      // Si no existe, promovemos el temporal al ID definitivo del backend.
      await txn.update(
        'anares_restriction',
        {'codAnaResActividad': serverId},
        where: 'codAnaResActividad = ?',
        whereArgs: [remoteId],
      );
    }

    // Reapuntamos eventos pendientes/fallidos para mantener trazabilidad.
    await txn.update(
      'sync_queue',
      {'entity_id': '$serverId'},
      where: 'entity_type = ? AND entity_id = ? AND status IN (?, ?)',
      whereArgs: ['restriction', '$remoteId', 'pending', 'failed'],
    );
  }

  Future<void> _reconcileAnalysisAreaRemoteId(
    DatabaseExecutor txn, {
    required int serverId,
    required int remoteId,
  }) async {
    final tempRows = await txn.query(
      'anares_area',
      columns: ['codAnaresArea'],
      where: 'codAnaresArea = ?',
      whereArgs: [remoteId],
      limit: 1,
    );
    if (tempRows.isEmpty) return;

    final serverRows = await txn.query(
      'anares_area',
      columns: ['codAnaresArea'],
      where: 'codAnaresArea = ?',
      whereArgs: [serverId],
      limit: 1,
    );

    if (serverRows.isNotEmpty) {
      await txn.delete(
        'anares_area',
        where: 'codAnaresArea = ?',
        whereArgs: [remoteId],
      );
    } else {
      await txn.update(
        'anares_area',
        {'codAnaresArea': serverId, 'is_codAnaresAreaLocal': 0},
        where: 'codAnaresArea = ?',
        whereArgs: [remoteId],
      );
    }

    // Reapunta restricciones que dependian del id temporal del area.
    await txn.update(
      'anares_restriction',
      {'codAnaresArea': '$serverId'},
      where: 'codAnaresArea = ?',
      whereArgs: ['$remoteId'],
    );

    // Reapunta cola pendiente/fallida para mantener trazabilidad.
    await txn.update(
      'sync_queue',
      {'entity_id': '$serverId'},
      where: 'entity_type = ? AND entity_id = ? AND status IN (?, ?)',
      whereArgs: ['analysis_area', '$remoteId', 'pending', 'failed'],
    );

    await _repointRestrictionAreaInPendingQueue(
      txn,
      oldAreaId: remoteId,
      newAreaId: serverId,
    );
  }

  Future<void> _repointRestrictionAreaInPendingQueue(
    DatabaseExecutor txn, {
    required int oldAreaId,
    required int newAreaId,
  }) async {
    final queueRows = await txn.query(
      'sync_queue',
      columns: ['id', 'payload_json'],
      where: 'entity_type = ? AND status IN (?, ?)',
      whereArgs: ['restriction', 'pending', 'failed'],
    );

    for (final queueRow in queueRows) {
      final queueId = _asInt(queueRow['id']);
      final payloadJson = _asString(queueRow['payload_json']);
      if (queueId == null || payloadJson == null || payloadJson.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(payloadJson);
        if (decoded is! Map<String, dynamic>) continue;

        final payload = Map<String, dynamic>.from(decoded);
        final payloadArea = _asString(payload['codAnaresArea']);
        if (payloadArea != '$oldAreaId') continue;

        payload['codAnaresArea'] = '$newAreaId';
        await txn.update(
          'sync_queue',
          {
            'payload_json': jsonEncode(payload),
            'updated_at': _toLimaIso8601String(DateTime.now()),
          },
          where: 'id = ?',
          whereArgs: [queueId],
        );
      } catch (_) {
        // Ignoramos payloads invalidos para no bloquear el apply.
      }
    }
  }

  Future<void> _applyActreuStatusCategoria(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codEstado']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_status_categoria',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_status_categoria', {
        'codEstado': id,
        'desEstado': _asString(row['desEstado']) ?? '',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuStatusSubcategoria(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codEstado']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_status_subcategoria',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_status_subcategoria', {
        'codEstado': id,
        'desEstado': _asString(row['desEstado']) ?? '',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuStatusReuniones(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codEstado']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_status_reuniones',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_status_reuniones', {
        'codEstado': id,
        'desEstado': _asString(row['desEstado']) ?? '',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuStatusAcuerdos(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codEstado']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_status_acuerdos',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_status_acuerdos', {
        'codEstado': id,
        'desEstado': _asString(row['desEstado']) ?? '',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuActasReuniones(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReu']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId == null || !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping actreu_actareuniones $id because project $projectId is missing locally',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_actareuniones',
          where: 'codActReu = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_actareuniones', {
        'codActReu': id,
        'codProyecto': projectId,
        'codEstado': _asInt(row['codEstado']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuSummary(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final projectId = _asInt(row['codProyecto']);
      if (projectId == null) continue;
      final updatedAt = _parseDateTime(
        _asString(row['updated_at'] ?? row['updatedAt']),
      );
      await txn.insert('actreu_summary', {
        'codProyecto': projectId,
        'totalSessions': _asInt(row['totalSessions']) ?? 0,
        'scheduledSessions': _asInt(row['scheduledSessions']) ?? 0,
        'activeSessions': _asInt(row['activeSessions']) ?? 0,
        'overdueAgreements': _asInt(row['overdueAgreements']) ?? 0,
        'pendingAgreements': _asInt(row['pendingAgreements']) ?? 0,
        'informativeAgreements': _asInt(row['informativeAgreements']) ?? 0,
        'categoriesCount': _asInt(row['categoriesCount']) ?? 0,
        'subcategoriesCount': _asInt(row['subcategoriesCount']) ?? 0,
        'compliancePercent': _asDouble(row['compliancePercent']),
        'updated_at': updatedAt?.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuCategorias(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuCategoria']);
      if (id == null) continue;
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'actreu_categoria',
          where: 'codActReuCategoria = ?',
          whereArgs: [id],
        );
        continue;
      }
      final projectId = _asInt(row['codProyecto']);
      final actaId = _asInt(row['codActReu']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (actaId == null || !await _meetingActaExists(txn, actaId)) {
        debugPrint(
          '[AppRepository] skipping actreu_categoria $id because acta $actaId is missing locally',
        );
        continue;
      }
      await txn.insert('actreu_categoria', {
        'codActReuCategoria': id,
        'codProyecto': projectId,
        'codActReu': actaId,
        'desNombreCategoria': row['desNombreCategoria'],
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'codEstado': _asInt(row['codEstado']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuSubcategorias(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuSubCategoria']);
      if (id == null) continue;
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'actreu_subcategoria',
          where: 'codActReuSubCategoria = ?',
          whereArgs: [id],
        );
        continue;
      }
      final projectId = _asInt(row['codProyecto']);
      final actaId = _asInt(row['codActReu']);
      final categoryId = _asInt(row['codActReuCategoria']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (actaId == null || !await _meetingActaExists(txn, actaId)) continue;
      if (categoryId == null ||
          !await _meetingCategoryExists(txn, categoryId)) {
        debugPrint(
          '[AppRepository] skipping actreu_subcategoria $id because categoria $categoryId is missing locally',
        );
        continue;
      }
      await txn.insert('actreu_subcategoria', {
        'codActReuSubCategoria': id,
        'codProyecto': projectId,
        'codActReu': actaId,
        'codActReuCategoria': categoryId,
        'codEstado': _asInt(row['codEstado']),
        'desNombreSubCategoria': row['desNombreSubCategoria'],
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuReuniones(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuReuniones']);
      if (id == null) continue;
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'actreu_reuniones',
          where: 'codActReuReuniones = ?',
          whereArgs: [id],
        );
        continue;
      }
      final projectId = _asInt(row['codProyecto']);
      final subcategoryId = _asInt(row['codActReuSubCategoria']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (subcategoryId == null ||
          !await _meetingSubcategoryExists(txn, subcategoryId)) {
        debugPrint(
          '[AppRepository] skipping actreu_reuniones $id because subcategoria $subcategoryId is missing locally',
        );
        continue;
      }
      await txn.insert('actreu_reuniones', {
        'codActReuReuniones': id,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']),
        'codActReuCategoria': _asInt(row['codActReuCategoria']),
        'codActReuSubCategoria': subcategoryId,
        'desNombre': row['desNombre'],
        'dayFechaReunion': row['dayFechaReunion'],
        'dayFechaCierre': row['dayFechaCierre'],
        'horHoraInicio': row['horHoraInicio'],
        'horHoraFin': row['horHoraFin'],
        'codEstado': _asInt(row['codEstado']),
        'desLinkActaReunion': row['desLinkActaReunion'],
        'groupedActReu': row['groupedActReu'],
        'desNombreArchivoActaGenerada': row['desNombreArchivoActaGenerada'],
        'desNombreArchivoActaGeneradaFirmada':
            row['desNombreArchivoActaGeneradaFirmada'],
        'desUrlDireccionActaGenerada': row['desUrlDireccionActaGenerada'],
        'desUrlDireccionActaGeneradaFirmada':
            row['desUrlDireccionActaGeneradaFirmada'],
        'ordenGruposAcuerdo': row['ordenGruposAcuerdo'],
        'ordenGruposAcuerdoAnteriores': row['ordenGruposAcuerdoAnteriores'],
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuIntegrantes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final projectId = _asInt(row['codProyecto']);
      final actaId = _asInt(row['codActReu']);
      final integranteId = _asInt(row['codProyIntegrante']);
      if (projectId == null || actaId == null || integranteId == null) continue;
      if (!await _projectExists(txn, projectId) ||
          !await _meetingActaExists(txn, actaId)) {
        continue;
      }
      if (!await _meetingProjectMemberExists(txn, integranteId)) {
        debugPrint(
          '[AppRepository] skipping actreu_integrantes '
          '$projectId-$actaId-$integranteId because project member is missing locally',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_integrantes',
          where: 'codProyecto = ? AND codActReu = ? AND codProyIntegrante = ?',
          whereArgs: [projectId, actaId, integranteId],
        );
        continue;
      }
      await txn.insert('actreu_integrantes', {
        'codProyecto': projectId,
        'codActReu': actaId,
        'codProyIntegrante': integranteId,
        'codEstado': _asInt(row['codEstado']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuParticipantes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuParticipante']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final subcategoryId = _asInt(row['codActReuSubCategoria']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (subcategoryId == null ||
          !await _meetingSubcategoryExists(txn, subcategoryId)) {
        debugPrint(
          '[AppRepository] skipping actreu_participantes $id because subcategoria $subcategoryId is missing locally',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_participantes',
          where: 'codActReuParticipante = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_participantes', {
        'codActReuParticipante': id,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']),
        'codActReuCategoria': _asInt(row['codActReuCategoria']),
        'codActReuSubCategoria': subcategoryId,
        'desNombre': row['desNombre'],
        'codArea': _asString(row['codArea']),
        'desCorreoElectronico': row['desCorreoElectronico'],
        'idUsuarioParticipante': _asInt(row['idUsuarioParticipante']),
        'codProyIntegrante': _asInt(row['codProyIntegrante']),
        'flgParticipanteInvitado': _asBoolInt(row['flgParticipanteInvitado']),
        'codEstado': _asInt(row['codEstado']) ?? 1,
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuGrupoAcuerdos(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuGrupoAcuerdo']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_grupoacuerdo',
          where: 'codActReuGrupoAcuerdo = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_grupoacuerdo', {
        'codActReuGrupoAcuerdo': id,
        'codActReuGrupoAcuerdoRemoto': _asInt(row['codActReuGrupoAcuerdoRemoto']),
        'codProyecto': projectId,
        'desGrupoAcuerdo': row['desGrupoAcuerdo'],
        'desColorGrupoAcuerdo': row['desColorGrupoAcuerdo'],
        'codOptionalArea': _asInt(row['codOptionalArea']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuAcuerdos(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuAcuerdos']);
      if (id == null) continue;
      if (_isDeletedByStatus(row)) {
        await txn.delete(
          'actreu_acuerdos',
          where: 'codActReuAcuerdos = ?',
          whereArgs: [id],
        );
        continue;
      }
      final projectId = _asInt(row['codProyecto']);
      final sessionId = _asInt(row['codActReuReuniones']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (sessionId == null || !await _meetingSessionExists(txn, sessionId)) {
        debugPrint(
          '[AppRepository] skipping actreu_acuerdos $id because reunion $sessionId is missing locally',
        );
        continue;
      }
      final requestedGroupId = _asInt(row['codGrupoAcuerdo']);
      final groupId =
          (requestedGroupId != null &&
              await _meetingGroupExists(txn, requestedGroupId))
          ? requestedGroupId
          : null;
      await txn.insert('actreu_acuerdos', {
        'codActReuAcuerdos': id,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']),
        'codActReuCategoria': _asInt(row['codActReuCategoria']),
        'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
        'codActReuReuniones': sessionId,
        'desAcuerdo': row['desAcuerdo'],
        'dayFechaAcuerdo': row['dayFechaAcuerdo'],
        'dayFechaAplazo': row['dayFechaAplazo'],
        'dayFechaLevantamiento': row['dayFechaLevantamiento'],
        'numAplazos': _asInt(row['numAplazos']),
        'idUsuarioResponsable': _asInt(row['idUsuarioResponsable']),
        'codEstado': _asInt(row['codEstado']),
        'numOrden': _asString(row['numOrden']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'codGrupoAcuerdo': groupId,
        'numOrdenAnteriores': _asInt(row['numOrdenAnteriores']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuAcuerdosFoto(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuAcuerdosFoto']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final sessionId = _asInt(row['codActReuReuniones']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (sessionId != null && !await _meetingSessionExists(txn, sessionId)) {
        debugPrint(
          '[AppRepository] skipping actreu_acuerdosfoto $id because reunion $sessionId is missing locally',
        );
        continue;
      }
      final requestedGroupId = _asInt(row['codGrupoAcuerdo']);
      final groupId =
          (requestedGroupId != null &&
              await _meetingGroupExists(txn, requestedGroupId))
          ? requestedGroupId
          : null;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_acuerdosfoto',
          where: 'codActReuAcuerdosFoto = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_acuerdosfoto', {
        'codActReuAcuerdosFoto': id,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']),
        'codActReuCategoria': _asInt(row['codActReuCategoria']),
        'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
        'codActReuAcuerdos': _asInt(row['codActReuAcuerdos']),
        'codActReuReuniones': sessionId,
        'desAcuerdo': row['desAcuerdo'],
        'dayFechaAcuerdo': row['dayFechaAcuerdo'],
        'dayFechaAplazo': row['dayFechaAplazo'],
        'dayFechaLevantamiento': row['dayFechaLevantamiento'],
        'numAplazos': _asInt(row['numAplazos']),
        'idUsuarioResponsable': _asInt(row['idUsuarioResponsable']),
        'codGrupoAcuerdo': groupId,
        'codEstado': _asInt(row['codEstado']),
        'numOrden': _asString(row['numOrden']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuComentariosAcuerdo(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codComentario']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final agreementId = _asInt(row['codActReuAcuerdos']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (agreementId == null ||
          !await _meetingAgreementExists(txn, agreementId)) {
        debugPrint(
          '[AppRepository] skipping actreu_comentarios_acuerdo $id because acuerdo $agreementId is missing locally',
        );
        continue;
      }
      final requestedParentId = _asInt(row['codComentarioPadre']);
      final parentId =
          (requestedParentId != null &&
              await _meetingCommentExists(txn, requestedParentId))
          ? requestedParentId
          : null;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_comentarios_acuerdo',
          where: 'codComentario = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_comentarios_acuerdo', {
        'codComentario': id,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']),
        'codActReuCategoria': _asInt(row['codActReuCategoria']),
        'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
        'codActReuReuniones': _asInt(row['codActReuReuniones']),
        'codActReuAcuerdos': agreementId,
        'codComentarioPadre': parentId,
        'idUsuario': _asInt(row['idUsuario']),
        'desMensaje': _asString(row['desMensaje']) ?? '',
        'dayFechaComentario': row['dayFechaComentario'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyActreuAsistencias(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codActReuAsistencia']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      final sessionId = _asInt(row['codActReuReuniones']);
      if (projectId == null || !await _projectExists(txn, projectId)) continue;
      if (sessionId == null || !await _meetingSessionExists(txn, sessionId)) {
        debugPrint(
          '[AppRepository] skipping actreu_asistencias $id because reunion $sessionId is missing locally',
        );
        continue;
      }
      final requestedParticipantId = _asInt(row['codActReuParticipante']);
      final participantId =
          (requestedParticipantId != null &&
              await _meetingParticipantExists(txn, requestedParticipantId))
          ? requestedParticipantId
          : null;
      if (_isDeleted(row)) {
        await txn.delete(
          'actreu_asistencias',
          where: 'codActReuAsistencia = ?',
          whereArgs: [id],
        );
        continue;
      }
      await txn.insert('actreu_asistencias', {
        'codActReuAsistencia': id,
        'codProyecto': projectId,
        'codActReu': _asInt(row['codActReu']),
        'codActReuCategoria': _asInt(row['codActReuCategoria']),
        'codActReuSubCategoria': _asInt(row['codActReuSubCategoria']),
        'codActReuReuniones': sessionId,
        'codEstado': _asInt(row['codEstado']),
        'desNombre': row['desNombre'],
        'desCorreoElectronico': row['desCorreoElectronico'],
        'idUsuarioParticipante': _asInt(row['idUsuarioParticipante']),
        'codProyIntegrante': _asInt(row['codProyIntegrante']),
        'codActReuParticipante': participantId,
        'desJustificacion': row['desJustificacion'],
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
        'deleted': _asBoolInt(row['deleted']),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneTypes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isNotEmpty) {
      final validIds = rows
          .map((row) => _asInt(row['codTipoHito']))
          .whereType<int>()
          .toList();
      if (validIds.isEmpty) {
        await txn.delete('conhit_tipohito');
      } else {
        final placeholders = List.filled(validIds.length, '?').join(', ');
        await txn.delete(
          'conhit_tipohito',
          where: 'codTipoHito NOT IN ($placeholders)',
          whereArgs: validIds,
        );
      }
    }
    for (final row in rows) {
      final id = _asInt(row['codTipoHito']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_tipohito',
          where: 'codTipoHito = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_tipohito', {
        'codTipoHito': id,
        'desTipoHito': row['desTipoHito'] ?? 'Hito',
        'orden': _asInt(row['orden']),
        'codEstado': _asInt(row['codEstado']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneClassifications(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isNotEmpty) {
      final validIds = rows
          .map((row) => _asInt(row['codTipoClasificacion']))
          .whereType<int>()
          .toList();
      if (validIds.isEmpty) {
        await txn.delete('conhit_tipoclasificacion');
      } else {
        final placeholders = List.filled(validIds.length, '?').join(', ');
        await txn.delete(
          'conhit_tipoclasificacion',
          where: 'codTipoClasificacion NOT IN ($placeholders)',
          whereArgs: validIds,
        );
      }
    }
    for (final row in rows) {
      final id = _asInt(row['codTipoClasificacion']);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_tipoclasificacion',
          where: 'codTipoClasificacion = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_tipoclasificacion', {
        'codTipoClasificacion': id,
        'desTipoClasificacion': row['desTipoClasificacion'] ?? 'General',
        'orden': _asInt(row['orden']),
        'codEstado': _asInt(row['codEstado']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneInternalStatuses(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asString(row['codEstado']);
      if (id == null || id.isEmpty) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_statusinterno',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_statusinterno', {
        'codEstado': id,
        'desEstado': row['desEstado'] ?? '',
        'desColor': row['desColor'],
        'desIcono': row['desIcono'],
        'orden': _asInt(row['orden']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneContractualStatuses(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asString(row['codEstado']);
      if (id == null || id.isEmpty) continue;
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_statuscontractual',
          where: 'codEstado = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_statuscontractual', {
        'codEstado': id,
        'desEstado': row['desEstado'] ?? '',
        'desColor': row['desColor'],
        'desIcono': row['desIcono'],
        'orden': _asInt(row['orden']),
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneControls(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codConHit']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping milestone control $id because project $projectId is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'milestone_control',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'milestone_control',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_controlhitos',
          where: 'codConHit = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_controlhitos', {
        'codConHit': id,
        'codEstado': _asInt(row['codEstado']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion': row['desUsuarioModificacion'],
        'codProyecto': projectId,
        'sync_status': 'synced',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneGenerals(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
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
        debugPrint(
          '[AppRepository] skipping milestone general $id because project $projectId is missing locally',
        );
        continue;
      }
      if (controlId == null) {
        debugPrint(
          '[AppRepository] skipping milestone general $id because project $projectId has no control locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'milestone_general',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'milestone_general',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_general',
          where: 'codConHitGeneral = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_general', {
        'codConHitGeneral': id,
        'codConHitGeneralRemoto': _asInt(row['codConHitGeneralRemoto']),
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
        'flgAplicaHitoGeneral': row['flgAplicaHitoGeneral'],
        'sync_status': 'synced',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestones(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
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
        debugPrint(
          '[AppRepository] skipping milestone $id because project $projectId is missing locally',
        );
        continue;
      }
      if (controlId == null) {
        debugPrint(
          '[AppRepository] skipping milestone $id because project $projectId has no control locally',
        );
        continue;
      }
      if (generalId == null) {
        debugPrint(
          '[AppRepository] skipping milestone $id because project $projectId has no general locally '
          'for control $controlId (requestedGeneralId=$requestedGeneralId)',
        );
        continue;
      }
      if (_isMilestoneDeleted(row)) {
        await _deleteMilestoneCascade(txn, id);
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'milestone',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'milestone',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      await txn.insert('conhit_detallehitos', {
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
        'codEstado': _asInt(row['codEstado']) ?? 1,
        'sync_status': 'synced',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneDocuments(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(
        row['codConhitArchivosFechaReal'] ?? row['codConhitDocumentos'],
      );
      if (id == null) continue;
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      if (milestoneId != null && !await _milestoneExists(txn, milestoneId)) {
        await txn.delete(
          'conhit_archivosfechareal',
          where: 'codConhitArchivosFechaReal = ?',
          whereArgs: [id],
        );
        debugPrint(
          '[AppRepository] skipping milestone document $id because milestone $milestoneId is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'milestone_document',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'milestone_document',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'conhit_archivosfechareal',
          where: 'codConhitArchivosFechaReal = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conhit_archivosfechareal', {
        'codConhitArchivosFechaReal': id,
        'codConHitDetalleHitos': milestoneId,
        'desNombreArchivo': row['desNombreArchivo'],
        'desRutaArchivo': row['desRutaArchivo'] ?? '',
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion': row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModifcacion':
            row['desUsuarioModifcacion'] ?? row['desUsuarioModificacion'],
        'sync_status': 'synced',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyMilestoneExtensions(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codConHitDetalleHitosAmp']);
      if (id == null) continue;
      final milestoneId = _asInt(row['codConHitDetalleHitos']);
      if (milestoneId != null && !await _milestoneExists(txn, milestoneId)) {
        await txn.delete(
          'conthit_detallehitosamp',
          where: 'codConHitDetalleHitosAmp = ?',
          whereArgs: [id],
        );
        debugPrint(
          '[AppRepository] skipping milestone extension $id because milestone $milestoneId is missing locally',
        );
        continue;
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: 'milestone_extension',
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: 'milestone_extension',
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'conthit_detallehitosamp',
          where: 'codConHitDetalleHitosAmp = ?',
          whereArgs: [id],
        );
        continue;
      }
      if (_asInt(row['codEstado']) == -1) {
        await txn.delete(
          'conthit_detallehitosamp',
          where: 'codConHitDetalleHitosAmp = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('conthit_detallehitosamp', {
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
        'codEstado': _asInt(row['codEstado']) ?? 1,
        'sync_status': 'synced',
        'updated_at':
            _asString(row['updated_at']) ?? _toLimaIso8601String(DateTime.now()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<bool> _restrictionModuleExists(
    DatabaseExecutor txn,
    int codAnaRes,
  ) async {
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

  Future<bool> _meetingActaExists(DatabaseExecutor txn, int actaId) async {
    final rows = await txn.query(
      'actreu_actareuniones',
      columns: ['codActReu'],
      where: 'codActReu = ?',
      whereArgs: [actaId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingCategoryExists(
    DatabaseExecutor txn,
    int categoryId,
  ) async {
    final rows = await txn.query(
      'actreu_categoria',
      columns: ['codActReuCategoria'],
      where: 'codActReuCategoria = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingSubcategoryExists(
    DatabaseExecutor txn,
    int subcategoryId,
  ) async {
    final rows = await txn.query(
      'actreu_subcategoria',
      columns: ['codActReuSubCategoria'],
      where: 'codActReuSubCategoria = ?',
      whereArgs: [subcategoryId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingSessionExists(
    DatabaseExecutor txn,
    int sessionId,
  ) async {
    final rows = await txn.query(
      'actreu_reuniones',
      columns: ['codActReuReuniones'],
      where: 'codActReuReuniones = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingParticipantExists(
    DatabaseExecutor txn,
    int participantId,
  ) async {
    final rows = await txn.query(
      'actreu_participantes',
      columns: ['codActReuParticipante'],
      where: 'codActReuParticipante = ?',
      whereArgs: [participantId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingProjectMemberExists(
    DatabaseExecutor txn,
    int memberId,
  ) async {
    final rows = await txn.query(
      'projects_member',
      columns: ['codProyIntegrante'],
      where: 'codProyIntegrante = ?',
      whereArgs: [memberId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingGroupExists(DatabaseExecutor txn, int groupId) async {
    final rows = await txn.query(
      'actreu_grupoacuerdo',
      columns: ['codActReuGrupoAcuerdo'],
      where: 'codActReuGrupoAcuerdo = ?',
      whereArgs: [groupId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingAgreementExists(
    DatabaseExecutor txn,
    int agreementId,
  ) async {
    final rows = await txn.query(
      'actreu_acuerdos',
      columns: ['codActReuAcuerdos'],
      where: 'codActReuAcuerdos = ?',
      whereArgs: [agreementId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _meetingCommentExists(
    DatabaseExecutor txn,
    int commentId,
  ) async {
    final rows = await txn.query(
      'actreu_comentarios_acuerdo',
      columns: ['codComentario'],
      where: 'codComentario = ?',
      whereArgs: [commentId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int?> _loadActiveRestrictionModuleId(
    Database db,
    int projectId,
  ) async {
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

  Future<bool> _milestoneControlExists(
    DatabaseExecutor txn,
    int controlId,
  ) async {
    final rows = await txn.query(
      'conhit_controlhitos',
      columns: ['codConHit'],
      where: 'codConHit = ?',
      whereArgs: [controlId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> _milestoneGeneralExists(
    DatabaseExecutor txn,
    int generalId,
  ) async {
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
      where: 'codConHitDetalleHitos = ? AND IFNULL(codEstado, 1) = 1',
      whereArgs: [milestoneId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _applyAvagraStatuses(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraCatalogRows(
      txn,
      rows,
      table: 'avagra_estados',
      idColumn: 'codEstado',
      resolveId: (row) => _asInt(row['codEstado']),
      buildData: (row, id) => {
        'codEstado': id,
        'desEstado': row['desEstado'] ?? row['label'],
        'desFase': row['desFase'] ?? row['phase'],
        'codColor': row['codColor'] ?? row['color'],
        'desColor': row['desColor'] ?? row['colorName'],
      },
    );
  }

  Future<void> _applyAvagraClockDirections(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraCatalogRows(
      txn,
      rows,
      table: 'avagra_sentidohorario',
      idColumn: 'CodSentido',
      resolveId: (row) => _asInt(row['CodSentido'] ?? row['codSentido']),
      buildData: (row, id) => {
        'CodSentido': id,
        'DesSentido': row['DesSentido'] ?? row['desSentido'],
        'DesAbrev': row['DesAbrev'] ?? row['desAbrev'],
        'DesIcon': row['DesIcon'] ?? row['desIcon'],
      },
    );
  }

  Future<void> _applyAvagraSideTypes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraCatalogRows(
      txn,
      rows,
      table: 'avagra_tipolado',
      idColumn: 'CodTipoLado',
      resolveId: (row) => _asInt(row['CodTipoLado'] ?? row['codTipoLado']),
      buildData: (row, id) => {
        'CodTipoLado': id,
        'DesLado': row['DesLado'] ?? row['desLado'],
        'DesAbrev': row['DesAbrev'] ?? row['desAbrev'],
        'DesIcon': row['DesIcon'] ?? row['desIcon'],
      },
    );
  }

  Future<void> _applyAvagraShapes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraCatalogRows(
      txn,
      rows,
      table: 'avagra_forma',
      idColumn: 'CodForma',
      resolveId: (row) => _asInt(row['CodForma'] ?? row['codForma']),
      buildData: (row, id) => {
        'CodForma': id,
        'DesForma': row['DesForma'] ?? row['desForma'],
        'DesAbrev': row['DesAbrev'] ?? row['desAbrev'],
        'DesIcon': row['DesIcon'] ?? row['desIcon'],
      },
    );
  }

  Future<void> _applyAvagraAdvanceGraphics(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = _asInt(row['codAvaGrafico']);
      if (id == null) continue;
      final projectId = _asInt(row['codProyecto']);
      if (projectId != null && !await _projectExists(txn, projectId)) {
        debugPrint(
          '[AppRepository] skipping avagra_avancegrafico $id because project $projectId is missing locally',
        );
        continue;
      }
      if (_isDeleted(row)) {
        await txn.delete(
          'avagra_avancegrafico',
          where: 'codAvaGrafico = ?',
          whereArgs: [id],
        );
        continue;
      }

      await txn.insert('avagra_avancegrafico', {
        'codAvaGrafico': id,
        'codProyecto': projectId,
        'codEstado': _asInt(row['codEstado']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'desUsuarioCreacion':
            row['desUsuarioCreacion'] ?? row['codUsuarioCreacion'],
        'vistaSeleccionada': _asInt(row['vistaSeleccionada']) ?? 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _applyAvagraPhaseOnes(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_faseuno',
      idColumn: 'codFaseUno',
      entityType: 'avagra_faseuno',
      resolveId: (row) => _asInt(row['codFaseUno']),
      buildData: (row, id) => {
        'codFaseUno': id,
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'DesFaseUno': row['DesFaseUno'] ?? row['desFaseUno'],
        'Comentarios': row['Comentarios'] ?? row['comentarios'],
        'desResOrdenTipoLados': row['desResOrdenTipoLados'],
        'CodForma': _asInt(row['CodForma'] ?? row['codForma']),
        'CodSentido': _asInt(row['CodSentido'] ?? row['codSentido']),
        'flgNivelesGlobales': _asBoolInt(row['flgNivelesGlobales']),
        'numNivelesGlobales': _asInt(row['numNivelesGlobales']) ?? 0,
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioCreacion':
            row['codUsuarioCreacion'] ?? row['desUsuarioCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'desUsuarioModificacion':
            row['desUsuarioModificacion'] ?? row['codUsuarioModificacion'],
        'auto_generate_pdf_enabled':
            _asBoolInt(row['auto_generate_pdf_enabled']),
        'auto_generate_pdf_iso_day': _asInt(row['auto_generate_pdf_iso_day']),
        'auto_generate_pdf_hours': row['auto_generate_pdf_hours'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_faseuno because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraSections(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_secciones',
      idColumn: 'codSecciones',
      entityType: 'avagra_secciones',
      resolveId: (row) => _asInt(row['codSecciones']),
      buildData: (row, id) => {
        'codSecciones': id,
        'desSecciones': row['desSecciones'],
        'desAbrev': row['desAbrev'],
        'numNiveles': _asInt(row['numNiveles']),
        'numPanios': _asInt(row['numPanios']),
        'numOrdenTipoLado': _asInt(row['numOrdenTipoLado']),
        'CodTipoLado': _asInt(row['CodTipoLado'] ?? row['codTipoLado']),
        'codFaseUno': _asInt(row['codFaseUno']),
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'codEstado': _asInt(row['codEstado']) ?? 1,
        'codUsuarioCreacion':
            row['codUsuarioCreacion'] ?? row['desUsuarioCreacion'],
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion':
            row['codUsuarioModificacion'] ?? row['desUsuarioModificacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_secciones because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraPositions(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_posiciones',
      idColumn: 'codPosition',
      entityType: 'avagra_posiciones',
      resolveId: (row) => _asInt(row['codPosition']),
      buildData: (row, id) => {
        'codPosition': id,
        'codSecciones': _asInt(row['codSecciones']),
        'desNumeracion': row['desNumeracion'],
        'numNivel': _asInt(row['numNivel']),
        'numPanio': _asInt(row['numPanio']),
        'desPosicion': row['desPosicion'],
        'desAbrev': row['desAbrev'],
        'codEstado': _asInt(row['codEstado']),
        'codUsuarioCreacion':
            row['codUsuarioCreacion'] ?? row['desUsuarioCreacion'],
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion':
            row['codUsuarioModificacion'] ?? row['desUsuarioModificacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
    );
  }

  Future<void> _applyAvagraPhaseTwos(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_fasedos',
      idColumn: 'codFaseDos',
      entityType: 'avagra_fasedos',
      resolveId: (row) => _asInt(row['codFaseDos']),
      buildData: (row, id) => {
        'codFaseDos': id,
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'desFaseDos': row['desFaseDos'],
        'desComentarios': row['desComentarios'],
        'flgPisosUniformes': _asBoolInt(row['flgPisosUniformes']),
        'numPisosUniformes': _asInt(row['numPisosUniformes']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'dayFechaModificacion': row['dayFechaModificacion'],
        'auto_generate_pdf_enabled':
            _asBoolInt(row['auto_generate_pdf_enabled']),
        'auto_generate_pdf_iso_day': _asInt(row['auto_generate_pdf_iso_day']),
        'auto_generate_pdf_hours': row['auto_generate_pdf_hours'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_fasedos because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraPhaseTwoActivities(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_actividades',
      idColumn: 'codActividades',
      entityType: 'avagra_actividades',
      resolveId: (row) => _asInt(row['codActividades']),
      buildData: (row, id) => {
        'codActividades': id,
        'desActividades': row['desActividades'],
        'numPisos': _asInt(row['numPisos']),
        'sotanos': _asInt(row['sotanos']) ?? 0,
        'numSectores': _asInt(row['numSectores']),
        'codFaseDos': _asInt(row['codFaseDos']),
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
        'codEstado': _asInt(row['codEstado']),
        'desAbrev': row['desAbrev'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_actividades because referenced project is missing locally',
      deleteStatusField: 'codEstado',
    );
  }

  Future<void> _applyAvagraPhaseTwoBoards(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_cuadros',
      idColumn: 'codCuadros',
      entityType: 'avagra_cuadros',
      resolveId: (row) => _asInt(row['codCuadros']),
      buildData: (row, id) => {
        'codCuadros': id,
        'codActividades': _asInt(row['codActividades']),
        'numOrden': _asInt(row['numOrden']),
        'numPiso': _asInt(row['numPiso']),
        'numSector': _asInt(row['numSector']),
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
        'codEstado': _asInt(row['codEstado']),
      },
      deleteStatusField: 'codEstado',
    );
  }

  Future<void> _applyAvagraPhaseThrees(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_fasetres',
      idColumn: 'codFaseTres',
      entityType: 'avagra_fasetres',
      resolveId: (row) => _asInt(row['codFaseTres']),
      buildData: (row, id) => {
        'codFaseTres': id,
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'desFaseTres': row['desFaseTres'],
        'desComentarios': row['desComentarios'],
        'numPisos': _asInt(row['numPisos']),
        'numSectores': _asInt(row['numSectores']),
        'numActividades': _asInt(row['numActividades']),
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_fasetres because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraFloors(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_pisos',
      idColumn: 'codPiso',
      entityType: 'avagra_pisos',
      resolveId: (row) => _asInt(row['codPiso']),
      buildData: (row, id) => {
        'codPiso': id,
        'codFaseTres': _asInt(row['codFaseTres']),
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'desAbrev': row['desAbrev'],
        'desNombre': row['desNombre'],
        'numOrden': _asInt(row['numOrden']),
        'desLinkPlano': row['desLinkPlano'],
        'desNombrePlano': row['desNombrePlano'],
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_pisos because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraSectors(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_sectores',
      idColumn: 'codSector',
      entityType: 'avagra_sectores',
      resolveId: (row) => _asInt(row['codSector']),
      buildData: (row, id) => {
        'codSector': id,
        'codFaseTres': _asInt(row['codFaseTres']),
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'desNombre': row['desNombre'],
        'desAbrev': row['desAbrev'],
        'desDescripcion': row['desDescripcion'],
        'jsonPosicionamientoPlano': row['jsonPosicionamientoPlano'],
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_sectores because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraPhaseThreeActivities(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_actividad',
      idColumn: 'codActividad',
      entityType: 'avagra_actividad',
      resolveId: (row) => _asInt(row['codActividad']),
      buildData: (row, id) => {
        'codActividad': id,
        'codFaseTres': _asInt(row['codFaseTres']),
        'codProyecto': _asInt(row['codProyecto']),
        'codAvaGrafico': _asInt(row['codAvaGrafico']),
        'desNombre': row['desNombre'],
        'desDescripcion': row['desDescripcion'],
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      canApply: (row) async {
        final projectId = _asInt(row['codProyecto']);
        return projectId == null || await _projectExists(txn, projectId);
      },
      skipMessage:
          '[AppRepository] skipping avagra_actividad because referenced project is missing locally',
    );
  }

  Future<void> _applyAvagraSectorsByFloor(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_sectoresxpisos',
      idColumn: 'codSectorxPiso',
      entityType: 'avagra_sectoresxpisos',
      resolveId: (row) => _asInt(row['codSectorxPiso']),
      buildData: (row, id) => {
        'codSectorxPiso': id,
        'codPiso': _asInt(row['codPiso']),
        'codSector': _asInt(row['codSector']),
        'desNombre': row['desNombre'],
        'desAbrev': row['desAbrev'],
        'desDescripcion': row['desDescripcion'],
        'codEstado': _asInt(row['codEstado']),
        'numPorcentajeCompletados': _asDouble(row['numPorcentajeCompletados']),
        'numPorcentajeAprobadosCalidad': _asDouble(
          row['numPorcentajeAprobadosCalidad'],
        ),
        'jsonPosicionamientoPlano': row['jsonPosicionamientoPlano'],
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      deleteStatusField: 'codEstado',
    );
  }

  Future<void> _applyAvagraActivitiesByFloor(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_actividadxpisos',
      idColumn: 'codActividadxPiso',
      entityType: 'avagra_actividadxpisos',
      resolveId: (row) => _asInt(row['codActividadxPiso']),
      buildData: (row, id) => {
        'codActividadxPiso': id,
        'codActividad': _asInt(row['codActividad']),
        'codPiso': _asInt(row['codPiso']),
        'desAbrev': row['desAbrev'],
        'desDescripcion': row['desDescripcion'],
        'codEstado': _asInt(row['codEstado']),
        'numOrden': _asInt(row['numOrden']),
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      deleteStatusField: 'codEstado',
    );
  }

  Future<void> _applyAvagraActivitiesBySectorByFloor(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows,
  ) async {
    await _applyAvagraEntityRows(
      txn,
      rows,
      table: 'avagra_actividadxsectorxpisos',
      idColumn: 'codActividadxSectorxPiso',
      entityType: 'avagra_actividadxsectorxpisos',
      resolveId: (row) => _asInt(row['codActividadxSectorxPiso']),
      buildData: (row, id) => {
        'codActividadxSectorxPiso': id,
        'codActividadxPiso': _asInt(row['codActividadxPiso']),
        'codSectorxPiso': _asInt(row['codSectorxPiso']),
        'codEstado': _asInt(row['codEstado']),
        'codUsuarioCreacion': _asInt(row['codUsuarioCreacion']),
        'dayFechaCreacion': row['dayFechaCreacion'],
        'codUsuarioModificacion': _asInt(row['codUsuarioModificacion']),
        'dayFechaModificacion': row['dayFechaModificacion'],
      },
      deleteStatusField: 'codEstado',
    );
  }

  Future<void> _applyAvagraCatalogRows(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows, {
    required String table,
    required String idColumn,
    required int? Function(Map<String, dynamic> row) resolveId,
    required Map<String, Object?> Function(Map<String, dynamic> row, int id)
    buildData,
  }) async {
    if (rows.isNotEmpty) {
      final validIds = rows.map(resolveId).whereType<int>().toList();
      if (validIds.isNotEmpty) {
        final placeholders = List.filled(validIds.length, '?').join(', ');
        await txn.delete(
          table,
          where: '$idColumn NOT IN ($placeholders)',
          whereArgs: validIds,
        );
      }
    }
    for (final row in rows) {
      final id = resolveId(row);
      if (id == null) continue;
      if (_isDeleted(row)) {
        await txn.delete(table, where: '$idColumn = ?', whereArgs: [id]);
        continue;
      }
      await txn.insert(
        table,
        buildData(row, id),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _applyAvagraEntityRows(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> rows, {
    required String table,
    required String idColumn,
    required String entityType,
    required int? Function(Map<String, dynamic> row) resolveId,
    required Map<String, Object?> Function(Map<String, dynamic> row, int id)
    buildData,
    Future<bool> Function(Map<String, dynamic> row)? canApply,
    String? skipMessage,
    String? deleteStatusField,
  }) async {
    for (final row in rows) {
      final id = resolveId(row);
      if (id == null) continue;
      if (canApply != null) {
        final allowed = await canApply(row);
        if (!allowed) {
          if (skipMessage != null) debugPrint(skipMessage);
          continue;
        }
      }
      if (await _hasPendingQueueItem(
        txn,
        entityType: entityType,
        entityId: '$id',
      )) {
        await _writeConflictLog(
          txn,
          entityType: entityType,
          entityId: '$id',
          message:
              'Se conservo el cambio local pendiente frente al pull remoto.',
        );
        continue;
      }
      final deleted = deleteStatusField == null
          ? _isDeleted(row)
          : _isDeletedByStatus(row, statusField: deleteStatusField);
      if (deleted) {
        await txn.delete(table, where: '$idColumn = ?', whereArgs: [id]);
        continue;
      }
      await txn.insert(
        table,
        buildData(row, id),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _deleteMilestoneCascade(
    DatabaseExecutor txn,
    int milestoneId,
  ) async {
    await txn.delete(
      'conhit_archivosfechareal',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );
    await txn.delete(
      'conthit_detallehitosamp',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );
    await txn.delete(
      'conhit_detallehitos',
      where: 'codConHitDetalleHitos = ?',
      whereArgs: [milestoneId],
    );
  }

  Future<int?> _resolveMilestoneGeneralId(
    DatabaseExecutor txn, {
    required int? requestedGeneralId,
    required int? controlId,
    required int? projectId,
  }) async {
    if (requestedGeneralId != null &&
        await _milestoneGeneralExists(txn, requestedGeneralId)) {
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
    if (requestedControlId != null &&
        await _milestoneControlExists(txn, requestedControlId)) {
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
      'created_at': _toLimaIso8601String(DateTime.now()),
    });
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
  const _MilestoneScope({required this.controlId, required this.generalId});

  final int controlId;
  final int generalId;
}
