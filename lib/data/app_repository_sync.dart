part of 'app_repository.dart';

extension AppRepositorySync on AppRepository {
  bool shouldRunDailyFullSync(AppPreferences preferences, {DateTime? now}) {
    final currentInstant = (now ?? DateTime.now()).toUtc();
    final current = _toLimaDateTime(currentInstant);
    if (current.hour < SyncRules.dailyFullEarliestHour) {
      return false;
    }
    final currentBusinessDate = _currentBusinessDateKey(now: current);
    return preferences.lastDailyFullSyncBusinessDate != currentBusinessDate;
  }

  bool shouldRunOperationalSync(AppPreferences preferences, {DateTime? now}) {
    final currentInstant = (now ?? DateTime.now()).toUtc();
    final currentLima = _toLimaDateTime(currentInstant);
    if (currentLima.hour < SyncRules.syncWindowStartHour ||
        currentLima.hour >= SyncRules.syncWindowEndHour) {
      debugPrint(
        '[AppRepository][operational][rule] window=false current=$currentLima '
        'start=${SyncRules.syncWindowStartHour} end=${SyncRules.syncWindowEndHour}',
      );
      return false;
    }
    final lastSyncAt = preferences.lastSyncAt;
    if (lastSyncAt == null) {
      debugPrint('[AppRepository][operational][rule] lastSyncAt=null -> true');
      return true;
    }
    final lastSyncInstant = lastSyncAt.toUtc();
    final diff = currentInstant.difference(lastSyncInstant);
    final allowed = diff >= SyncRules.operationalMinInterval;
    debugPrint(
      '[AppRepository][operational][rule] current=$currentLima '
      'lastSyncAt=$lastSyncAt diffMin=${diff.inMinutes} '
      'minRequired=${SyncRules.operationalMinInterval.inMinutes} allowed=$allowed',
    );
    return allowed;
  }

  Future<void> _ensureRemoteSyncAllowed(AppPreferences preferences) async {
    if (preferences.isOfflineEffective) {
      throw Exception(
        'La app esta en modo offline. Desactiva el modo offline para sincronizar.',
      );
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
    final now = _toLimaIso8601String(DateTime.now());
    await _normalizePendingSyncQueueIds(db);
    final effectiveQueue = await db.query(
      'sync_queue',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC, id ASC',
    );
    debugPrint(
      '[AppRepository] push queue userId=$userId companyId=$companyId items=${effectiveQueue.length}',
    );
    for (final row in effectiveQueue) {
      final queueId = row['id'];
      final entityType = row['entity_type'] as String? ?? '';
      final entityId = row['entity_id'] as String? ?? '';
      final rawOperationType = row['operation_type'] as String? ?? '';
      final operationType =
          entityType == 'restriction' && rawOperationType == 'status_update'
          ? 'update'
          : rawOperationType;
      final payloadJson = row['payload_json'] as String? ?? '{}';
      final item = <Map<String, Object?>>[
        {
          'queueId': queueId,
          'entityType': entityType,
          'entityId': entityId,
          'operationType': operationType,
          'payload': payloadJson,
        },
      ];

      try {
        await _syncApiClient.pushInbox(
          userId: userId,
          authToken: authToken,
          companyId: companyId,
          items: item,
        );

        await db.update(
          'sync_queue',
          {'status': 'synced', 'error_message': null, 'updated_at': now},
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
      } catch (error) {
        debugPrint(
          '[AppRepository] push failed entity=$entityType:$entityId op=$operationType error=$error',
        );
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
    if (scope == 'operational') {
      debugPrint(
        '[AppRepository][operational][request] '
        'userId=$userId companyId=$companyId scope=$scope '
        'businessDate=$businessDate since=$since',
      );
    }

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
      'milestones=${_asMapList(result.payload['milestones']).length} '
      'actreu_reuniones=${_asMapList(_asMap(result.payload['actreu'])['reuniones']).length} '
      'actreu_acuerdos=${_asMapList(_asMap(result.payload['actreu'])['acuerdos']).length}',
    );

    if (scope == 'operational') {
      final anaresPayload = _asMap(result.payload['anares']);
      final restrictions = _asMapList(result.payload['restrictions']);
      final analysisAreas = _asMapList(anaresPayload['analysisAreas']);
      final members = _asMapList(anaresPayload['members']);
      final analysis = _asMapList(anaresPayload['analysis']);
      final restrictionIds = restrictions
          .map((row) => _asInt(row['codAnaResActividad']))
          .whereType<int>()
          .take(8)
          .join(',');
      final analysisAreaIds = analysisAreas
          .map((row) => _asInt(row['codAnaresArea']))
          .whereType<int>()
          .take(8)
          .join(',');

      debugPrint(
        '[AppRepository][operational][response] '
        'serverTime=${result.payload['serverTime']} '
        'version=${result.payload['version']} '
        'restrictions=${restrictions.length} '
        'anares.analysis=${analysis.length} '
        'anares.analysisAreas=${analysisAreas.length} '
        'anares.members=${members.length} '
        'restrictionIds=[$restrictionIds] '
        'analysisAreaIds=[$analysisAreaIds]',
      );
      debugPrint(
        '[AppRepository][operational][response_body_preview] '
        '${_compactPreview(result.rawBody, 900)}',
      );
    }

    final anares = _asMap(result.payload['anares']);
    final catalogs = _asMap(result.payload['catalogs']);
    List<Map<String, dynamic>> masterRows(List<String> keys) {
      for (final key in keys) {
        final rowsFromAnares = _asMapList(anares[key]);
        if (rowsFromAnares.isNotEmpty) return rowsFromAnares;
        final rowsFromCatalogs = _asMapList(catalogs[key]);
        if (rowsFromCatalogs.isNotEmpty) return rowsFromCatalogs;
        final rowsFromRoot = _asMapList(result.payload[key]);
        if (rowsFromRoot.isNotEmpty) return rowsFromRoot;
      }
      return const [];
    }

    if (scope == 'full') {
      debugPrint(
        '[AppRepository] pull masters '
        'areas=${masterRows(const ['areas']).length} '
        'analysisAreas=${masterRows(const ['analysisAreas', 'analysis_areas']).length} '
        'fronts=${masterRows(const ['fronts', 'frentes', 'analysisFronts']).length} '
        'phases=${masterRows(const ['phases', 'fases', 'analysisPhases']).length} '
        'types=${masterRows(const ['types', 'tipos']).length} '
        'statuses=${masterRows(const ['statuses', 'estados']).length} '
        'members=${masterRows(const ['members', 'integrantes']).length}',
      );
    }

    if (scope == 'operational' &&
        await _containsNewProjects(db, result.payload)) {
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

    final version = result.payload['version']?.toString();
    final serverTime = result.payload['serverTime']?.toString();
    final now = _toLimaIso8601String(DateTime.now());
    final syncCursor =
        (version != null && version.isNotEmpty)
            ? version
            : ((serverTime != null && serverTime.isNotEmpty)
                  ? serverTime
                  : now);
    await _saveSetting(db, 'last_sync_at', syncCursor);
    if (version != null && version.isNotEmpty) {
      await _saveSetting(db, 'last_sync_version', version);
    }
    if (scope == 'full' && markDailyFullSync) {
      await _saveSetting(
        db,
        'last_daily_full_sync_business_date',
        businessDate,
      );
    }
    await _refreshDerivedState(db);
    await _logTableCounts(db, label: 'after_pull_$scope');
    await db.insert('sync_log', {
      'entity_type': 'system',
      'entity_id': businessDate,
      'action': scope == 'full' ? 'full_pull' : 'operational_pull',
      'result': 'success',
      'message': scope == 'full'
          ? 'Descarga total completada.'
          : 'Descarga operativa completada.',
      'created_at': now,
    });
  }

  Future<void> _applyPullPayload(
    DatabaseExecutor txn,
    Map<String, dynamic> payload, {
    required String scope,
  }) async {
    final projectRows = _asMapList(payload['projects']);
    await _applyProjects(txn, projectRows);
    if (scope == 'full') {
      await _pruneMissingProjectsForFullPull(txn, projectRows);
    }
    final conthit = _asMap(payload['conthit']);
    final legacyConhit = _asMap(payload['conhit']);
    final legacyControlHitos = _asMap(payload['controlHitos']);
    final actreu = _asMap(payload['actreu']);
    final avagra = _asMap(payload['avagra']);

    List<Map<String, dynamic>> controlHitosRows(String key) {
      final rowsFromConthit = _asMapList(conthit[key]);
      if (rowsFromConthit.isNotEmpty) return rowsFromConthit;
      final rowsFromLegacyConhit = _asMapList(legacyConhit[key]);
      if (rowsFromLegacyConhit.isNotEmpty) return rowsFromLegacyConhit;
      final rowsFromLegacyControlHitos = _asMapList(legacyControlHitos[key]);
      if (rowsFromLegacyControlHitos.isNotEmpty) {
        return rowsFromLegacyControlHitos;
      }
      return _asMapList(payload[key]);
    }

    List<Map<String, dynamic>> actreuRows(List<String> keys) {
      for (final key in keys) {
        final rowsFromActreu = _asMapList(actreu[key]);
        if (rowsFromActreu.isNotEmpty) return rowsFromActreu;
      }
      for (final key in keys) {
        final rowsFromRoot = _asMapList(payload[key]);
        if (rowsFromRoot.isNotEmpty) return rowsFromRoot;
      }
      return const [];
    }

    List<Map<String, dynamic>> avagraRows(List<String> keys) {
      for (final key in keys) {
        final rowsFromAvagra = _asMapList(avagra[key]);
        if (rowsFromAvagra.isNotEmpty) return rowsFromAvagra;
      }
      for (final key in keys) {
        final rowsFromRoot = _asMapList(payload[key]);
        if (rowsFromRoot.isNotEmpty) return rowsFromRoot;
      }
      return const [];
    }

    final anares = _asMap(payload['anares']);
    final catalogs = _asMap(payload['catalogs']);
    List<Map<String, dynamic>> masterRows(List<String> keys) {
      for (final key in keys) {
        final rowsFromAnares = _asMapList(anares[key]);
        if (rowsFromAnares.isNotEmpty) return rowsFromAnares;
        final rowsFromCatalogs = _asMapList(catalogs[key]);
        if (rowsFromCatalogs.isNotEmpty) return rowsFromCatalogs;
        final rowsFromRoot = _asMapList(payload[key]);
        if (rowsFromRoot.isNotEmpty) return rowsFromRoot;
      }
      return const [];
    }

    // Nuevo contrato API: para analisis/frentes/fases priorizamos raiz.
    // Mantenemos fallback a anares/catalogs por compatibilidad legacy.
    List<Map<String, dynamic>> rootFirstRows(List<String> keys) {
      for (final key in keys) {
        final rowsFromRoot = _asMapList(payload[key]);
        if (rowsFromRoot.isNotEmpty) return rowsFromRoot;
      }
      for (final key in keys) {
        final rowsFromAnares = _asMapList(anares[key]);
        if (rowsFromAnares.isNotEmpty) return rowsFromAnares;
        final rowsFromCatalogs = _asMapList(catalogs[key]);
        if (rowsFromCatalogs.isNotEmpty) return rowsFromCatalogs;
      }
      return const [];
    }

    final analysisRows = _mergeRestrictionModuleRows(
      masterRows(const ['analysis', 'analysisRestrictions']),
      rootFirstRows(const ['fronts', 'frentes', 'analysisFronts']),
      rootFirstRows(const ['phases', 'fases', 'analysisPhases']),
      _asMapList(payload['restrictions']),
    );
    final frontsRows = rootFirstRows(
      const ['fronts', 'frentes', 'analysisFronts'],
    );
    final phasesRows = rootFirstRows(
      const ['phases', 'fases', 'analysisPhases'],
    );
    final membersRows = masterRows(const ['members', 'integrantes']);
    final restrictionRows = _asMapList(payload['restrictions']);
    final avagraStatusesRows = avagraRows(const ['statuses', 'estados']);
    final avagraClockDirectionsRows = avagraRows(
      const ['clockDirections', 'sentidoHorario'],
    );
    final avagraSideTypesRows = avagraRows(const ['sideTypes', 'tiposLado']);
    final avagraShapesRows = avagraRows(const ['shapes', 'formas']);

    // Catalogos Avance Grafico (full) y fallback compatible si llegan en otro scope.
    await _applyAvagraStatuses(txn, avagraStatusesRows);
    await _applyAvagraClockDirections(txn, avagraClockDirectionsRows);
    await _applyAvagraSideTypes(txn, avagraSideTypesRows);
    await _applyAvagraShapes(txn, avagraShapesRows);

    if (scope == 'full') {
      await _clearActreuTablesForFullPull(txn);

      await _applyAreaMembers(txn, masterRows(const ['areas']));
      await _applyRestrictionModules(txn, analysisRows);
      await _applyAnalysisAreas(
        txn,
        masterRows(const ['analysisAreas', 'analysis_areas']),
      );
      await _applyTypes(txn, masterRows(const ['types', 'tipos']));
      await _applyStatuses(txn, masterRows(const ['statuses', 'estados']));
      await _applyMembers(txn, membersRows);
      await _applyFronts(txn, frontsRows);
      await _applyPhases(txn, phasesRows);
      await _applyMilestoneTypes(txn, controlHitosRows('milestoneTypes'));
      await _applyMilestoneClassifications(
        txn,
        controlHitosRows('milestoneClassifications'),
      );
      await _applyMilestoneInternalStatuses(
        txn,
        controlHitosRows('milestoneStatusesInterno'),
      );
      await _applyMilestoneContractualStatuses(
        txn,
        controlHitosRows('milestoneStatusesContractual'),
      );
      await _applyActreuStatusCategoria(
        txn,
        actreuRows(const ['status_categoria', 'statusCategoria']),
      );
      await _applyActreuStatusSubcategoria(
        txn,
        actreuRows(const ['status_subcategoria', 'statusSubcategoria']),
      );
      await _applyActreuStatusReuniones(
        txn,
        actreuRows(const ['status_reuniones', 'statusReuniones']),
      );
      await _applyActreuStatusAcuerdos(
        txn,
        actreuRows(const ['status_acuerdos', 'statusAcuerdos']),
      );
      await _applyActreuSummary(
        txn,
        actreuRows(const ['summary', 'actreu_summary', 'resumen']),
      );
    } else {
      // Operational: primero sincronizamos bloque prefijado `anares.*`.
      await _applyAreaMembers(txn, masterRows(const ['areas']));
      await _applyRestrictionModules(txn, analysisRows);
      await _applyAnalysisAreas(
        txn,
        masterRows(const ['analysisAreas', 'analysis_areas']),
      );
      await _applyMembers(txn, membersRows);
      await _applyFronts(txn, frontsRows);
      await _applyPhases(txn, phasesRows);
      await _applyTypes(txn, masterRows(const ['types', 'tipos']));
      await _applyStatuses(txn, masterRows(const ['statuses', 'estados']));
      await _applyRestrictions(txn, restrictionRows);

      // Luego continuamos con el resto de dominios.
      await _applyMilestoneTypes(txn, controlHitosRows('milestoneTypes'));
      await _applyMilestoneClassifications(
        txn,
        controlHitosRows('milestoneClassifications'),
      );
      await _applyMilestoneInternalStatuses(
        txn,
        controlHitosRows('milestoneStatusesInterno'),
      );
      await _applyMilestoneContractualStatuses(
        txn,
        controlHitosRows('milestoneStatusesContractual'),
      );
      await _applyActreuStatusCategoria(
        txn,
        actreuRows(const ['status_categoria', 'statusCategoria']),
      );
      await _applyActreuStatusSubcategoria(
        txn,
        actreuRows(const ['status_subcategoria', 'statusSubcategoria']),
      );
      await _applyActreuStatusReuniones(
        txn,
        actreuRows(const ['status_reuniones', 'statusReuniones']),
      );
      await _applyActreuStatusAcuerdos(
        txn,
        actreuRows(const ['status_acuerdos', 'statusAcuerdos']),
      );
      await _applyActreuSummary(
        txn,
        actreuRows(const ['summary', 'actreu_summary', 'resumen']),
      );
    }

    if (scope == 'full') {
      await _applyRestrictions(txn, restrictionRows);
    }

    // Datos operacionales Avance Grafico.
    await _applyAvagraAdvanceGraphics(
      txn,
      avagraRows(const ['advanceGraphics', 'avancesgraficos']),
    );
    await _applyAvagraPhaseOnes(
      txn,
      avagraRows(const ['phaseOnes', 'faseuno']),
    );
    await _applyAvagraSections(
      txn,
      avagraRows(const ['sections', 'secciones']),
    );
    await _applyAvagraPositions(
      txn,
      avagraRows(const ['positions', 'posiciones']),
    );
    await _applyAvagraPhaseTwos(
      txn,
      avagraRows(const ['phaseTwos', 'fasedos']),
    );
    await _applyAvagraPhaseTwoActivities(
      txn,
      avagraRows(const ['phaseTwoActivities', 'actividades']),
    );
    await _applyAvagraPhaseTwoBoards(
      txn,
      avagraRows(const ['phaseTwoBoards', 'cuadros']),
    );
    await _applyAvagraPhaseThrees(
      txn,
      avagraRows(const ['phaseThrees', 'fasetres']),
    );
    await _applyAvagraFloors(
      txn,
      avagraRows(const ['floors', 'pisos']),
    );
    await _applyAvagraSectors(
      txn,
      avagraRows(const ['sectors', 'sectores']),
    );
    await _applyAvagraPhaseThreeActivities(
      txn,
      avagraRows(const ['phaseThreeActivities', 'actividad']),
    );
    await _applyAvagraSectorsByFloor(
      txn,
      avagraRows(const ['sectorsByFloor', 'sectoresxpisos']),
    );
    await _applyAvagraActivitiesByFloor(
      txn,
      avagraRows(const ['activitiesByFloor', 'actividadxpisos']),
    );
    await _applyAvagraActivitiesBySectorByFloor(
      txn,
      avagraRows(
        const ['activitiesBySectorByFloor', 'actividadxsectorxpisos'],
      ),
    );

    await _applyMilestoneControls(txn, controlHitosRows('milestoneControls'));
    await _applyMilestoneGenerals(txn, controlHitosRows('milestoneGenerals'));
    await _applyMilestones(txn, controlHitosRows('milestones'));
    await _applyMilestoneDocuments(txn, controlHitosRows('milestoneDocuments'));
    await _applyMilestoneExtensions(
      txn,
      controlHitosRows('milestoneExtensions'),
    );
    await _applyActreuActasReuniones(
      txn,
      actreuRows(const ['actasReuniones', 'actareuniones']),
    );
    await _applyActreuCategorias(
      txn,
      actreuRows(const ['categorias', 'categoria']),
    );
    await _applyActreuSubcategorias(
      txn,
      actreuRows(const ['subcategorias', 'subcategoria']),
    );
    await _applyActreuReuniones(
      txn,
      actreuRows(const ['reuniones', 'sessions']),
    );
    await _applyActreuIntegrantes(
      txn,
      actreuRows(const [
        'integrantes',
        'integrantesReuniones',
        'participantsIntegrantes',
      ]),
    );
    await _applyActreuParticipantes(
      txn,
      actreuRows(const ['participantes', 'participants']),
    );
    await _applyActreuGrupoAcuerdos(
      txn,
      actreuRows(const ['grupoAcuerdos', 'gruposAcuerdo']),
    );
    await _applyActreuAcuerdos(
      txn,
      actreuRows(const ['acuerdos', 'agreements']),
    );
    await _applyActreuAcuerdosFoto(
      txn,
      actreuRows(const ['acuerdosFoto', 'agreementsPhoto']),
    );
    await _applyActreuComentariosAcuerdo(
      txn,
      actreuRows(const ['comentariosAcuerdo', 'comentarios_acuerdo']),
    );
    await _applyActreuAsistencias(
      txn,
      actreuRows(const ['asistencias', 'attendances']),
    );
  }

  List<Map<String, dynamic>> _mergeRestrictionModuleRows(
    List<Map<String, dynamic>> incomingModules,
    List<Map<String, dynamic>> fronts,
    List<Map<String, dynamic>> phases,
    List<Map<String, dynamic>> restrictions,
  ) {
    final byId = <int, Map<String, dynamic>>{};
    final nowIso = _toLimaIso8601String(DateTime.now());

    void upsertModule({
      required int moduleId,
      int? projectId,
      String? updatedAt,
      dynamic deleted,
    }) {
      final current = byId[moduleId];
      if (current == null) {
        byId[moduleId] = <String, dynamic>{
          'codAnaRes': moduleId,
          'codProyecto': projectId,
          'codEstado': 0,
          'updated_at': updatedAt ?? nowIso,
          'deleted': deleted ?? false,
        };
        return;
      }
      if ((current['codProyecto'] == null) && projectId != null) {
        current['codProyecto'] = projectId;
      }
      if (updatedAt != null && updatedAt.isNotEmpty) {
        current['updated_at'] = updatedAt;
      }
      if (deleted != null) {
        current['deleted'] = deleted;
      }
    }

    for (final row in incomingModules) {
      final moduleId = _asInt(row['codAnaRes'] ?? row['codAnares']);
      if (moduleId == null) continue;
      upsertModule(
        moduleId: moduleId,
        projectId: _asInt(row['codProyecto']),
        updatedAt: _asString(row['updated_at']),
        deleted: row['deleted'],
      );
      byId[moduleId]!.addAll(row);
      byId[moduleId]!['codAnaRes'] =
          _asInt(byId[moduleId]!['codAnaRes'] ?? byId[moduleId]!['codAnares']) ??
          moduleId;
      byId[moduleId]!['codEstado'] = _asInt(byId[moduleId]!['codEstado']) ?? 0;
      byId[moduleId]!['updated_at'] =
          _asString(byId[moduleId]!['updated_at']) ?? nowIso;
      byId[moduleId]!['deleted'] = byId[moduleId]!['deleted'] ?? false;
    }

    void collectFrom(List<Map<String, dynamic>> rows) {
      for (final row in rows) {
        final moduleId = _asInt(row['codAnaRes'] ?? row['codAnares']);
        if (moduleId == null) continue;
        upsertModule(
          moduleId: moduleId,
          projectId: _asInt(row['codProyecto']),
          updatedAt: _asString(row['updated_at']),
        );
      }
    }

    collectFrom(fronts);
    collectFrom(phases);
    collectFrom(restrictions);

    return byId.values.toList();
  }

  Future<void> _clearActreuTablesForFullPull(DatabaseExecutor txn) async {
    final tablesInDeleteOrder = <String>[
      'actreu_comentarios_acuerdo',
      'actreu_asistencias',
      'actreu_acuerdosfoto',
      'actreu_acuerdos',
      'actreu_participantes',
      'actreu_integrantes',
      'actreu_reuniones',
      'actreu_subcategoria',
      'actreu_categoria',
      'actreu_actareuniones',
      'actreu_grupoacuerdo',
      'actreu_summary',
      'actreu_status_acuerdos',
      'actreu_status_reuniones',
      'actreu_status_subcategoria',
      'actreu_status_categoria',
    ];
    for (final table in tablesInDeleteOrder) {
      await txn.delete(table);
    }
  }

  Future<void> _pruneMissingProjectsForFullPull(
    DatabaseExecutor txn,
    List<Map<String, dynamic>> projectRows,
  ) async {
    if (projectRows.isEmpty) return;

    final incomingIds = <int>{};
    for (final row in projectRows) {
      final id = _asInt(row['codProyecto']);
      if (id != null) {
        incomingIds.add(id);
      }
    }
    if (incomingIds.isEmpty) return;

    final placeholders = List.filled(incomingIds.length, '?').join(', ');
    final removed = await txn.delete(
      'projects_project',
      where: 'codProyecto NOT IN ($placeholders)',
      whereArgs: incomingIds.toList(growable: false),
    );

    if (removed > 0) {
      debugPrint(
        '[AppRepository][full][projects] pruned_missing=$removed incoming=${incomingIds.length}',
      );
    }
  }

  Future<void> _logTableCounts(Database db, {required String label}) async {
    final projects =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM projects_project'),
        ) ??
        0;
    final restrictions =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM anares_restriction'),
        ) ??
        0;
    final projectAreas =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM anares_area'),
        ) ??
        0;
    final generalAreas =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM projects_area_member'),
        ) ??
        0;
    final currentProject = await _loadCurrentProjectId(db);

    debugPrint(
      '[AppRepository] $label currentProject=$currentProject '
      'projects=$projects restrictions=$restrictions '
      'anaresArea=$projectAreas generalAreas=$generalAreas',
    );
  }

  Future<bool> _containsNewProjects(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final remoteProjects = _asMapList(payload['projects']);
    if (remoteProjects.isEmpty) {
      return false;
    }

    final localProjectRows = await db.query(
      'projects_project',
      columns: ['codProyecto'],
    );
    final localIds = localProjectRows
        .map((row) => row['codProyecto'])
        .whereType<int>()
        .toSet();

    for (final project in remoteProjects) {
      final remoteId = _asInt(project['codProyecto']);
      if (remoteId != null && !localIds.contains(remoteId)) {
        return true;
      }
    }

    return false;
  }

  String _compactPreview(String input, int maxChars) {
    final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxChars) return compact;
    return '${compact.substring(0, maxChars)}...';
  }
}
