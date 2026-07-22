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
      final queuePayload = await _ensureQueuePayloadHasProjectId(
        db,
        queueId: _asInt(queueId),
        entityType: entityType,
        entityId: entityId,
        payloadJson: payloadJson,
      );
      final item = <Map<String, Object?>>[
        {
          'queueId': queueId,
          'entityType': entityType,
          'entityId': entityId,
          'operationType': operationType,
          'payload': jsonEncode(queuePayload),
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

  Future<Map<String, Object?>> _ensureQueuePayloadHasProjectId(
    Database db, {
    required int? queueId,
    required String entityType,
    required String entityId,
    required String payloadJson,
  }) async {
    final decoded = jsonDecode(payloadJson);
    final payload = decoded is Map<String, dynamic>
        ? Map<String, Object?>.from(decoded)
        : <String, Object?>{};
    final updatedPayload = await _withSyncPayloadProjectId(
      db,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
    );
    if (queueId != null &&
        updatedPayload['codProyecto'] != payload['codProyecto']) {
      await db.update(
        'sync_queue',
        {'payload_json': jsonEncode(updatedPayload)},
        where: 'id = ?',
        whereArgs: [queueId],
      );
    }
    return updatedPayload;
  }

  Future<Map<String, Object?>> _withSyncPayloadProjectId(
    Database db, {
    required String entityType,
    required String entityId,
    required Map<String, Object?> payload,
  }) async {
    final projectId = await _resolveQueueProjectId(
      db,
      entityType: entityType,
      entityId: entityId,
      payloadJson: jsonEncode(payload),
    );
    if (projectId == null) {
      return payload;
    }
    final updatedPayload = Map<String, Object?>.from(payload);
    updatedPayload['codProyecto'] = projectId;
    return updatedPayload;
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

    if (await _hasSubscriptionAccessIssue(db, result.payload)) {
      throw const SubscriptionAccessRevokedException();
    }

    final version = result.payload['version']?.toString();
    final serverTime = result.payload['serverTime']?.toString();
    final now = _toLimaIso8601String(DateTime.now());
    final syncCursor = (version != null && version.isNotEmpty)
        ? version
        : ((serverTime != null && serverTime.isNotEmpty) ? serverTime : now);
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
    final activeSubscription = _resolvePullActiveSubscription(payload);
    final personalizationRows = _asMapList(payload['personalizacion']);
    final now = _toLimaIso8601String(DateTime.now());
    if (activeSubscription.isNotEmpty) {
      await _persistActiveSubscription(txn, activeSubscription, now);
    }
    if (personalizationRows.isNotEmpty) {
      await _applySubscriptionCustomization(txn, personalizationRows, now);
    }
    await _applyProjects(txn, projectRows);
    if (scope == 'full') {
      await _pruneMissingProjectsForFullPull(txn, projectRows);
    }
    await _persistProjectProfiles(txn, projectRows, now);
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
    final frontsRows = rootFirstRows(const [
      'fronts',
      'frentes',
      'analysisFronts',
    ]);
    final phasesRows = rootFirstRows(const [
      'phases',
      'fases',
      'analysisPhases',
    ]);
    final membersRows = masterRows(const ['members', 'integrantes']);
    final restrictionRows = _asMapList(payload['restrictions']);
    final avagraStatusesRows = avagraRows(const ['statuses', 'estados']);
    final avagraClockDirectionsRows = avagraRows(const [
      'clockDirections',
      'sentidoHorario',
    ]);
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
    await _applyAvagraFloors(txn, avagraRows(const ['floors', 'pisos']));
    await _applyAvagraSectors(txn, avagraRows(const ['sectors', 'sectores']));
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
      avagraRows(const ['activitiesBySectorByFloor', 'actividadxsectorxpisos']),
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

  /// Resuelve el `codProyecto` proyectado en el servidor en cada item del
  /// sync inbox. Lee primero el payload, y si no viene ahí hace un lookup
  /// liviano contra la tabla origen. Devuelve `null` si no se puede
  /// determinar (en ese caso el servidor recibirá `null` para no inventar
  /// un projectId incorrecto).
  Future<int?> _resolveQueueProjectId(
    Database db, {
    required String entityType,
    required String entityId,
    required String payloadJson,
  }) async {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        final raw = decoded['codProyecto'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        if (raw is String) {
          final parsed = int.tryParse(raw);
          if (parsed != null) return parsed;
        }
      }
    } catch (_) {
      // seguimos con lookup por tabla
    }

    if (entityId.isEmpty) return null;

    String? column;
    String? table;
    switch (entityType) {
      case 'restriction':
      case 'analysis_front':
      case 'analysis_phase':
        table = 'anares_restriction';
        column = 'codAnaResActividad';
        break;
      case 'milestone':
      case 'milestone_extension':
      case 'milestone_document':
      case 'milestone_general':
        table = 'conhit_detallehitos';
        column = 'codConHitDetalleHitos';
        break;
      case 'actreu_category':
      case 'actreu_subcategory':
      case 'actreu_session':
      case 'actreu_acta':
        table = 'actreu_reuniones';
        column = 'codActReuReuniones';
        break;
      case 'actreu_agreement':
      case 'actreu_agreement_photo':
        table = 'actreu_acuerdos';
        column = 'codActReuAcuerdos';
        break;
      case 'actreu_member':
      case 'actreu_session_member':
        table = 'actreu_integrantes';
        column = 'codActReuIntegrante';
        break;
      case 'avagra_master':
      case 'avagra':
        table = 'avagra_avancegrafico';
        column = 'codAvaGrafico';
        break;
      default:
        return null;
    }

    final parsedId = int.tryParse(entityId);
    if (parsedId == null) return null;

    final rows = await db.query(
      table,
      columns: ['codProyecto'],
      where: '$column = ?',
      whereArgs: [parsedId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _asInt(rows.first['codProyecto']);
  }

  Map<String, dynamic> _resolvePullActiveSubscription(
    Map<String, dynamic> payload,
  ) {
    final root = _asMap(payload['suscripcionActiva']);
    if (root.isNotEmpty) {
      return root;
    }

    final auth = _asMap(payload['auth']);
    final nestedAuth = _asMap(auth['suscripcionActiva']);
    if (nestedAuth.isNotEmpty) {
      return nestedAuth;
    }

    final subscription = _asMap(payload['subscription']);
    final nestedSubscription = _asMap(subscription['suscripcionActiva']);
    if (nestedSubscription.isNotEmpty) {
      return nestedSubscription;
    }

    return const {};
  }

  /// Detecta revocación real después de aplicar un pull.
  ///
  /// Reglas:
  /// - Solo invalidamos sesión si el payload trae `suscripcionActiva` con
  ///   `codEstado = 0`, o el usuario asociado ya no cumple, o el servicio
  ///   `SERV_APP_MOVIL` no está activo. Si el pull no trae ese bloque,
  ///   conservamos la última suscrición persistida.
  Future<bool> _hasSubscriptionAccessIssue(
    Database db,
    Map<String, dynamic> payload,
  ) async {
    final activeSubscription = _resolvePullActiveSubscription(payload);
    if (activeSubscription.isEmpty) {
      return false;
    }

    final subscriptionStatus = _asInt(activeSubscription['codEstado']) ?? 1;
    if (subscriptionStatus == 0) {
      return true;
    }

    final codEmpresa = _asInt(activeSubscription['cod_Empresa']);
    final codSuscripcion = _asInt(activeSubscription['codSuscripcion']);
    if (codEmpresa == null || codSuscripcion == null) {
      return true;
    }

    final serviceRows = await db.query(
      'auth_active_subscription_service',
      columns: ['codEstado'],
      where: 'cod_Empresa = ? AND codSuscripcion = ? AND UPPER(desAbrev) = ?',
      whereArgs: [codEmpresa, codSuscripcion, 'SERV_APP_MOVIL'],
      limit: 1,
    );
    final hasMobileService =
        serviceRows.isNotEmpty &&
        (_asInt(serviceRows.first['codEstado']) ?? 0) == 1;
    if (!hasMobileService) {
      return true;
    }

    return false;
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
          _asInt(
            byId[moduleId]!['codAnaRes'] ?? byId[moduleId]!['codAnares'],
          ) ??
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
