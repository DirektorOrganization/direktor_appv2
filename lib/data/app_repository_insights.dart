part of 'app_repository.dart';

// ── Insight Rule Config ───────────────────────────────────────────────────────

Future<List<InsightRuleConfigRecord>> _loadInsightRuleConfigsImpl(
  AppRepository repo,
  Database db, {
  required int userId,
  required ModuleInsightModule module,
}) async {
  final rows = await db.query(
    'insight_rule_config',
    where: 'codUsuario = ? AND desModulo = ?',
    whereArgs: [userId, repo._moduleInsightModuleToDb(module)],
  );
  return rows.map((row) {
    Map<String, int> thresholds = {};
    final raw = row['thresholdsJson'] as String?;
    if (raw != null && raw.isNotEmpty && raw != '{}') {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        thresholds = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    }
    return InsightRuleConfigRecord(
      userId: userId,
      module: module,
      ruleKey: (row['desRuleKey'] as String?) ?? '',
      isEnabled: repo._asInt(row['isEnabled']) != 0,
      thresholds: thresholds,
    );
  }).toList();
}

Future<void> _saveInsightRuleConfigImpl(
  AppRepository repo,
  Database db, {
  required int userId,
  required ModuleInsightModule module,
  required String ruleKey,
  required bool isEnabled,
  required Map<String, int> thresholds,
}) async {
  final now = repo._toLimaIso8601String(DateTime.now());
  final moduleStr = repo._moduleInsightModuleToDb(module);
  await db.insert(
    'insight_rule_config',
    {
      'codUsuario': userId,
      'desModulo': moduleStr,
      'desRuleKey': ruleKey,
      'isEnabled': isEnabled ? 1 : 0,
      'thresholdsJson': jsonEncode(thresholds),
      'updated_at': now,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<AppBootstrapData> _setModuleInsightResolvedImpl(
  AppRepository repo, {
  required int projectId,
  required ModuleInsightModule module,
  required String insightKey,
  required bool resolved,
}) async {
  final db = await repo._database.database;
  final now = repo._toLimaIso8601String(DateTime.now());
  await db.update(
    'module_insights',
    {
      'is_resolved': resolved ? 1 : 0,
      'dayResolvedAt': resolved ? now : null,
      'updated_at': now,
    },
    where: 'codProyecto = ? AND desModulo = ? AND desInsightKey = ?',
    whereArgs: [projectId, repo._moduleInsightModuleToDb(module), insightKey],
  );
  return repo.bootstrap();
}

Future<List<ModuleInsightRecord>> _loadModuleInsightsForProjectImpl(
  AppRepository repo,
  Database db, {
  required int projectId,
  required ModuleInsightModule module,
}) async {
  final rows = await db.query(
    'module_insights',
    where: 'codProyecto = ? AND desModulo = ?',
    whereArgs: [projectId, repo._moduleInsightModuleToDb(module)],
    orderBy:
        "CASE desSeverity WHEN 'critical' THEN 0 ELSE 1 END ASC, desInsightKey ASC",
  );
  return rows
      .map(
        (row) => ModuleInsightRecord(
          projectId: repo._asInt(row['codProyecto']) ?? projectId,
          module: repo._moduleInsightModuleFromDb(
            (row['desModulo'] as String?) ?? '',
          ),
          key: (row['desInsightKey'] as String?) ?? '',
          severity: repo._moduleInsightSeverityFromDb(
            (row['desSeverity'] as String?) ?? 'warning',
          ),
          title: (row['desTitle'] as String?) ?? '',
          message: (row['desMessage'] as String?) ?? '',
          iconName: (row['desIconName'] as String?) ?? 'insights',
          isResolved: repo._asInt(row['is_resolved']) == 1,
          updatedAt: repo._parseDateTime(row['updated_at'] as String?),
        ),
      )
      .toList();
}

Future<void> _recalculateModuleInsightsImpl(
  AppRepository repo,
  Database db,
) async {
  final now = repo._toLimaIso8601String(DateTime.now());

  // Load the active session user — configs are per-user, not per-project.
  final sessionRows = await db.query(
    'auth_session',
    where: 'is_active = 1',
    orderBy: 'id DESC',
    limit: 1,
  );
  if (sessionRows.isEmpty) return;
  final userId = repo._asInt(sessionRows.first['user_id']);
  if (userId == null) return;

  // Load user-level rule configs once (apply to all projects).
  final restrictionConfigs = {
    for (final c in await _loadInsightRuleConfigsImpl(
      repo, db, userId: userId, module: ModuleInsightModule.restrictions,
    )) c.ruleKey: c,
  };
  final actaConfigs = {
    for (final c in await _loadInsightRuleConfigsImpl(
      repo, db, userId: userId, module: ModuleInsightModule.actaReuniones,
    )) c.ruleKey: c,
  };

  final projects = await db.query(
    'projects_project',
    columns: ['codProyecto'],
    orderBy: 'codProyecto ASC',
  );

  for (final row in projects) {
    final projectId = repo._asInt(row['codProyecto']);
    if (projectId == null) continue;

    final restrictionInsights = await _buildRestrictionInsightsImpl(
      repo, db, projectId: projectId, configs: restrictionConfigs,
    );
    final actaReunionesInsights = await _buildActaReunionesInsightsImpl(
      repo, db, projectId: projectId, configs: actaConfigs,
    );
    final allInsights = <ModuleInsightRecord>[
      ...restrictionInsights,
      ...actaReunionesInsights,
    ];

    await db.delete(
      'module_insights',
      where: 'codProyecto = ?',
      whereArgs: [projectId],
    );

    for (final insight in allInsights) {
      await db.insert('module_insights', {
        'codProyecto': insight.projectId,
        'desModulo': repo._moduleInsightModuleToDb(insight.module),
        'desInsightKey': insight.key,
        'desSeverity': repo._moduleInsightSeverityToDb(insight.severity),
        'desTitle': insight.title,
        'desMessage': insight.message,
        'desIconName': insight.iconName,
        'is_resolved': 0,
        'dayResolvedAt': null,
        'updated_at': now,
      });
    }
  }
}

Future<List<ModuleInsightRecord>> _buildRestrictionInsightsImpl(
  AppRepository repo,
  Database db, {
  required int projectId,
  Map<String, InsightRuleConfigRecord> configs = const {},
}) async {
  // Helper: resolve a threshold — uses DB config if present, else falls back to default.
  int thresh(String ruleKey, String threshKey, int fallback) {
    return configs[ruleKey]?.threshold(threshKey, fallback) ?? fallback;
  }
  // Helper: is a rule enabled?
  bool enabled(String ruleKey) => configs[ruleKey]?.isEnabled ?? true;

  final rows = await db.query(
    'anares_restriction',
    columns: ['dayFechaRequerida', 'dayFechaConciliada', 'is_completed'],
    where: "codProyecto = ? AND IFNULL(codEstadoActividad, '') != ?",
    whereArgs: [projectId, '99'],
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final insights = <ModuleInsightRecord>[];

  // Resolve thresholds (DB config overrides static defaults).
  final delayLowMin  = thresh(RestrictionInsightsRules.keyDelayLow, 'minDays', RestrictionInsightsRules.delayWarningMinDays);
  final delayLowMax  = thresh(RestrictionInsightsRules.keyDelayLow, 'maxDays', RestrictionInsightsRules.delayWarningMaxDays);
  final delayHighMin = thresh(RestrictionInsightsRules.keyDelayHigh, 'minDays', RestrictionInsightsRules.delayCriticalMinDays);

  final progWarnMin       = thresh(RestrictionInsightsRules.keyProgressWarning, 'minPercent', RestrictionInsightsRules.progressWarningMinPercentExclusive);
  final progWarnMax       = thresh(RestrictionInsightsRules.keyProgressWarning, 'maxPercent', RestrictionInsightsRules.progressWarningMaxPercentInclusive);
  final progWarnMaxOverdue = thresh(RestrictionInsightsRules.keyProgressWarning, 'maxOverdueDays', RestrictionInsightsRules.progressWarningMaxOverdueDays);

  final progMidMin        = thresh(RestrictionInsightsRules.keyProgressCriticalMid, 'minPercent', RestrictionInsightsRules.progressCriticalMidMinPercentExclusive);
  final progMidMax        = thresh(RestrictionInsightsRules.keyProgressCriticalMid, 'maxPercent', RestrictionInsightsRules.progressCriticalMidMaxPercentInclusive);
  final progMidMinOverdue = thresh(RestrictionInsightsRules.keyProgressCriticalMid, 'minOverdueDays', RestrictionInsightsRules.progressCriticalMidMinOverdueDays);

  final progEndMin        = thresh(RestrictionInsightsRules.keyProgressCriticalEnd, 'minPercent', RestrictionInsightsRules.progressCriticalEndMinPercentExclusive);
  final progEndMax        = thresh(RestrictionInsightsRules.keyProgressCriticalEnd, 'maxPercent', RestrictionInsightsRules.progressCriticalEndMaxPercentInclusive);
  final progEndMinOverdue = thresh(RestrictionInsightsRules.keyProgressCriticalEnd, 'minOverdueDays', RestrictionInsightsRules.progressCriticalEndMinOverdueDays);

  final conciliatedThreshold = thresh(RestrictionInsightsRules.keyConciliatedCritical, 'delayedPercent', RestrictionInsightsRules.conciliatedCriticalDelayedPercentThreshold);

  int overdueLow = 0;
  int overdueHigh = 0;
  final requiredDates = <DateTime>[];
  var overdueCount = 0;
  var conciliatedTotal = 0;
  var conciliatedOverdue = 0;

  for (final row in rows) {
    final isCompleted = repo._asInt(row['is_completed']) == 1;
    final requiredDate = repo._parseDateOnly(row['dayFechaRequerida']);
    if (requiredDate != null) requiredDates.add(requiredDate);
    if (!isCompleted && requiredDate != null && today.isAfter(requiredDate)) {
      final days = today.difference(requiredDate).inDays;
      if (days >= delayLowMin && days <= delayLowMax) overdueLow += 1;
      if (days >= delayHighMin) overdueHigh += 1;
      overdueCount += 1;
    }

    final conciliatedDate = repo._parseDateOnly(row['dayFechaConciliada']);
    if (conciliatedDate != null) {
      conciliatedTotal += 1;
      if (!isCompleted && today.isAfter(conciliatedDate)) {
        conciliatedOverdue += 1;
      }
    }
  }

  if (enabled(RestrictionInsightsRules.keyDelayLow) && overdueLow > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.restrictions,
      key: RestrictionInsightsRules.keyDelayLow,
      severity: ModuleInsightSeverity.warning,
      title: RestrictionInsightsRules.delayTitle,
      message: RestrictionInsightsRules.delayLowMessage(overdueLow),
      iconName: RestrictionInsightsRules.iconDelayLow,
      isResolved: false,
      updatedAt: now,
    ));
  }
  if (enabled(RestrictionInsightsRules.keyDelayHigh) && overdueHigh > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.restrictions,
      key: RestrictionInsightsRules.keyDelayHigh,
      severity: ModuleInsightSeverity.critical,
      title: RestrictionInsightsRules.delayTitle,
      message: RestrictionInsightsRules.delayHighMessage(overdueHigh),
      iconName: RestrictionInsightsRules.iconDelayHigh,
      isResolved: false,
      updatedAt: now,
    ));
  }

  if (requiredDates.isNotEmpty) {
    requiredDates.sort((a, b) => a.compareTo(b));
    final start = requiredDates.first;
    final end = requiredDates.last;
    final totalDays = end.difference(start).inDays.abs();
    final safeTotalDays = totalDays <= 0 ? 1 : totalDays;
    final rawElapsed = today.difference(start).inDays;
    final boundedElapsed = rawElapsed.clamp(0, safeTotalDays);
    final elapsedPercent = (boundedElapsed / safeTotalDays) * 100;
    final elapsedText = elapsedPercent.toStringAsFixed(0);

    if (enabled(RestrictionInsightsRules.keyProgressWarning) &&
        elapsedPercent > progWarnMin &&
        elapsedPercent <= progWarnMax &&
        overdueCount <= progWarnMaxOverdue) {
      insights.add(ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.restrictions,
        key: RestrictionInsightsRules.keyProgressWarning,
        severity: ModuleInsightSeverity.warning,
        title: RestrictionInsightsRules.progressTitle,
        message: RestrictionInsightsRules.progressWarningMessage(elapsedText),
        iconName: RestrictionInsightsRules.iconProgressWarning,
        isResolved: false,
        updatedAt: now,
      ));
    } else if (enabled(RestrictionInsightsRules.keyProgressCriticalMid) &&
        elapsedPercent > progMidMin &&
        elapsedPercent <= progMidMax &&
        overdueCount >= progMidMinOverdue) {
      insights.add(ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.restrictions,
        key: RestrictionInsightsRules.keyProgressCriticalMid,
        severity: ModuleInsightSeverity.critical,
        title: RestrictionInsightsRules.progressTitle,
        message: RestrictionInsightsRules.progressCriticalMidMessage(elapsedText, overdueCount),
        iconName: RestrictionInsightsRules.iconProgressCriticalMid,
        isResolved: false,
        updatedAt: now,
      ));
    } else if (enabled(RestrictionInsightsRules.keyProgressCriticalEnd) &&
        elapsedPercent > progEndMin &&
        elapsedPercent <= progEndMax &&
        overdueCount >= progEndMinOverdue) {
      insights.add(ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.restrictions,
        key: RestrictionInsightsRules.keyProgressCriticalEnd,
        severity: ModuleInsightSeverity.critical,
        title: RestrictionInsightsRules.progressTitle,
        message: RestrictionInsightsRules.progressCriticalEndMessage(elapsedText),
        iconName: RestrictionInsightsRules.iconProgressCriticalEnd,
        isResolved: false,
        updatedAt: now,
      ));
    }
  }

  if (enabled(RestrictionInsightsRules.keyConciliatedCritical) && conciliatedTotal > 0) {
    final delayedPercent = (conciliatedOverdue / conciliatedTotal) * 100;
    if (delayedPercent > conciliatedThreshold) {
      insights.add(ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.restrictions,
        key: RestrictionInsightsRules.keyConciliatedCritical,
        severity: ModuleInsightSeverity.critical,
        title: RestrictionInsightsRules.conciliatedTitle,
        message: RestrictionInsightsRules.conciliatedCriticalMessage,
        iconName: RestrictionInsightsRules.iconConciliatedCritical,
        isResolved: false,
        updatedAt: now,
      ));
    }
  }

  return insights;
}

Future<List<ModuleInsightRecord>> _buildActaReunionesInsightsImpl(
  AppRepository repo,
  Database db, {
  required int projectId,
  Map<String, InsightRuleConfigRecord> configs = const {},
}) async {
  int thresh(String ruleKey, String threshKey, int fallback) =>
      configs[ruleKey]?.threshold(threshKey, fallback) ?? fallback;
  bool enabled(String ruleKey) => configs[ruleKey]?.isEnabled ?? true;

  // Resolve thresholds.
  final delayLowMin  = thresh(ActreuInsightsRules.keyDelayLow, 'minDays', ActreuInsightsRules.delayWarningMinDays);
  final delayLowMax  = thresh(ActreuInsightsRules.keyDelayLow, 'maxDays', ActreuInsightsRules.delayWarningMaxDays);
  final delayHighMin = thresh(ActreuInsightsRules.keyDelayHigh, 'minDays', ActreuInsightsRules.delayCriticalMinDays);

  final deferDaysWarnMin = thresh(ActreuInsightsRules.keyDeferralDaysWarning, 'minDays', ActreuInsightsRules.deferralDaysWarningMin);
  final deferDaysWarnMax = thresh(ActreuInsightsRules.keyDeferralDaysWarning, 'maxDaysExclusive', ActreuInsightsRules.deferralDaysWarningMaxExclusive);
  final deferDaysCritMin = thresh(ActreuInsightsRules.keyDeferralDaysCritical, 'minDays', ActreuInsightsRules.deferralDaysCriticalMin);

  final deferTimesWarnMin = thresh(ActreuInsightsRules.keyDeferralTimesWarning, 'minTimes', ActreuInsightsRules.deferralTimesWarningMin);
  final deferTimesWarnMax = thresh(ActreuInsightsRules.keyDeferralTimesWarning, 'maxTimesExclusive', ActreuInsightsRules.deferralTimesWarningMaxExclusive);
  final deferTimesCritMin = thresh(ActreuInsightsRules.keyDeferralTimesCritical, 'minTimes', ActreuInsightsRules.deferralTimesCriticalMin);

  final rows = await db.query(
    'actreu_acuerdos',
    columns: ['dayFechaAcuerdo', 'dayFechaAplazo', 'numAplazos', 'codEstado'],
    where: 'codProyecto = ? AND IFNULL(deleted, 0) = 0',
    whereArgs: [projectId],
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final insights = <ModuleInsightRecord>[];

  var overdueLow = 0;
  var overdueHigh = 0;
  var aplazoDaysAlert = 0;
  var aplazoDaysCritical = 0;
  var aplazoTimesAlert = 0;
  var aplazoTimesCritical = 0;

  for (final row in rows) {
    final statusCode = repo._asInt(row['codEstado']);
    final isCompleted = statusCode == 3;
    final isInformative = statusCode == 6;
    final agreementDate = repo._parseDateOnly(row['dayFechaAcuerdo']);
    final aplazoDate = repo._parseDateOnly(row['dayFechaAplazo']);
    final baseAgreementDate = agreementDate;
    final effectiveDate = aplazoDate ?? agreementDate;
    if (!isCompleted && !isInformative && effectiveDate != null && today.isAfter(effectiveDate)) {
      final days = today.difference(effectiveDate).inDays;
      if (days >= delayLowMin && days <= delayLowMax) overdueLow += 1;
      if (days >= delayHighMin) overdueHigh += 1;
    }

    if (baseAgreementDate != null && aplazoDate != null && aplazoDate.isAfter(baseAgreementDate)) {
      final aplazoDays = aplazoDate.difference(baseAgreementDate).inDays;
      if (aplazoDays >= deferDaysWarnMin && aplazoDays < deferDaysWarnMax) aplazoDaysAlert += 1;
      if (aplazoDays >= deferDaysCritMin) aplazoDaysCritical += 1;
    }

    final aplazoTimes = repo._asInt(row['numAplazos']) ?? 0;
    if (aplazoTimes >= deferTimesWarnMin && aplazoTimes < deferTimesWarnMax) aplazoTimesAlert += 1;
    if (aplazoTimes >= deferTimesCritMin) aplazoTimesCritical += 1;
  }

  if (enabled(ActreuInsightsRules.keyDelayLow) && overdueLow > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.actaReuniones,
      key: ActreuInsightsRules.keyDelayLow,
      severity: ModuleInsightSeverity.warning,
      title: ActreuInsightsRules.delayTitle,
      message: ActreuInsightsRules.delayLowMessage(overdueLow),
      iconName: ActreuInsightsRules.iconDelayLow,
      isResolved: false,
      updatedAt: now,
    ));
  }
  if (enabled(ActreuInsightsRules.keyDelayHigh) && overdueHigh > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.actaReuniones,
      key: ActreuInsightsRules.keyDelayHigh,
      severity: ModuleInsightSeverity.critical,
      title: ActreuInsightsRules.delayTitle,
      message: ActreuInsightsRules.delayHighMessage(overdueHigh),
      iconName: ActreuInsightsRules.iconDelayHigh,
      isResolved: false,
      updatedAt: now,
    ));
  }
  if (enabled(ActreuInsightsRules.keyDeferralDaysWarning) && aplazoDaysAlert > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.actaReuniones,
      key: ActreuInsightsRules.keyDeferralDaysWarning,
      severity: ModuleInsightSeverity.warning,
      title: ActreuInsightsRules.deferralDaysTitle,
      message: ActreuInsightsRules.deferralDaysWarningMessage(aplazoDaysAlert),
      iconName: ActreuInsightsRules.iconDeferralDaysWarning,
      isResolved: false,
      updatedAt: now,
    ));
  }
  if (enabled(ActreuInsightsRules.keyDeferralDaysCritical) && aplazoDaysCritical > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.actaReuniones,
        key: ActreuInsightsRules.keyDeferralDaysCritical,
        severity: ModuleInsightSeverity.critical,
        title: ActreuInsightsRules.deferralDaysTitle,
        message: ActreuInsightsRules.deferralDaysCriticalMessage(
          aplazoDaysCritical,
        ),
        iconName: ActreuInsightsRules.iconDeferralDaysCritical,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }
  if (enabled(ActreuInsightsRules.keyDeferralTimesWarning) && aplazoTimesAlert > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.actaReuniones,
      key: ActreuInsightsRules.keyDeferralTimesWarning,
      severity: ModuleInsightSeverity.warning,
      title: ActreuInsightsRules.deferralTimesTitle,
      message: ActreuInsightsRules.deferralTimesWarningMessage(aplazoTimesAlert),
      iconName: ActreuInsightsRules.iconDeferralTimesWarning,
      isResolved: false,
      updatedAt: now,
    ));
  }
  if (enabled(ActreuInsightsRules.keyDeferralTimesCritical) && aplazoTimesCritical > 0) {
    insights.add(ModuleInsightRecord(
      projectId: projectId,
      module: ModuleInsightModule.actaReuniones,
      key: ActreuInsightsRules.keyDeferralTimesCritical,
      severity: ModuleInsightSeverity.critical,
      title: ActreuInsightsRules.deferralTimesTitle,
      message: ActreuInsightsRules.deferralTimesCriticalMessage(aplazoTimesCritical),
      iconName: ActreuInsightsRules.iconDeferralTimesCritical,
      isResolved: false,
      updatedAt: now,
    ));
  }

  return insights;
}
