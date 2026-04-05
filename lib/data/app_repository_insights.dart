part of 'app_repository.dart';

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
  final projects = await db.query(
    'projects_project',
    columns: ['codProyecto'],
    orderBy: 'codProyecto ASC',
  );

  for (final row in projects) {
    final projectId = repo._asInt(row['codProyecto']);
    if (projectId == null) continue;
    final restrictionInsights = await _buildRestrictionInsightsImpl(
      repo,
      db,
      projectId: projectId,
    );
    final actaReunionesInsights = await _buildActaReunionesInsightsImpl(
      repo,
      db,
      projectId: projectId,
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
}) async {
  final rows = await db.query(
    'anares_restriction',
    columns: ['dayFechaRequerida', 'dayFechaConciliada', 'is_completed'],
    where: "codProyecto = ? AND IFNULL(codEstadoActividad, '') != ?",
    whereArgs: [projectId, '99'],
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final insights = <ModuleInsightRecord>[];

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
      if (days >= RestrictionInsightsRules.delayWarningMinDays &&
          days <= RestrictionInsightsRules.delayWarningMaxDays) {
        overdueLow += 1;
      }
      if (days >= RestrictionInsightsRules.delayCriticalMinDays) {
        overdueHigh += 1;
      }
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

  if (overdueLow > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.restrictions,
        key: RestrictionInsightsRules.keyDelayLow,
        severity: ModuleInsightSeverity.warning,
        title: RestrictionInsightsRules.delayTitle,
        message: RestrictionInsightsRules.delayLowMessage(overdueLow),
        iconName: RestrictionInsightsRules.iconDelayLow,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }
  if (overdueHigh > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.restrictions,
        key: RestrictionInsightsRules.keyDelayHigh,
        severity: ModuleInsightSeverity.critical,
        title: RestrictionInsightsRules.delayTitle,
        message: RestrictionInsightsRules.delayHighMessage(overdueHigh),
        iconName: RestrictionInsightsRules.iconDelayHigh,
        isResolved: false,
        updatedAt: now,
      ),
    );
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

    if (elapsedPercent >
            RestrictionInsightsRules.progressWarningMinPercentExclusive &&
        elapsedPercent <=
            RestrictionInsightsRules.progressWarningMaxPercentInclusive &&
        overdueCount <=
            RestrictionInsightsRules.progressWarningMaxOverdueDays) {
      insights.add(
        ModuleInsightRecord(
          projectId: projectId,
          module: ModuleInsightModule.restrictions,
          key: RestrictionInsightsRules.keyProgressWarning,
          severity: ModuleInsightSeverity.warning,
          title: RestrictionInsightsRules.progressTitle,
          message: RestrictionInsightsRules.progressWarningMessage(elapsedText),
          iconName: RestrictionInsightsRules.iconProgressWarning,
          isResolved: false,
          updatedAt: now,
        ),
      );
    } else if (elapsedPercent >
            RestrictionInsightsRules.progressCriticalMidMinPercentExclusive &&
        elapsedPercent <=
            RestrictionInsightsRules.progressCriticalMidMaxPercentInclusive &&
        overdueCount >=
            RestrictionInsightsRules.progressCriticalMidMinOverdueDays) {
      insights.add(
        ModuleInsightRecord(
          projectId: projectId,
          module: ModuleInsightModule.restrictions,
          key: RestrictionInsightsRules.keyProgressCriticalMid,
          severity: ModuleInsightSeverity.critical,
          title: RestrictionInsightsRules.progressTitle,
          message: RestrictionInsightsRules.progressCriticalMidMessage(
            elapsedText,
            overdueCount,
          ),
          iconName: RestrictionInsightsRules.iconProgressCriticalMid,
          isResolved: false,
          updatedAt: now,
        ),
      );
    } else if (elapsedPercent >
            RestrictionInsightsRules.progressCriticalEndMinPercentExclusive &&
        elapsedPercent <=
            RestrictionInsightsRules.progressCriticalEndMaxPercentInclusive &&
        overdueCount >=
            RestrictionInsightsRules.progressCriticalEndMinOverdueDays) {
      insights.add(
        ModuleInsightRecord(
          projectId: projectId,
          module: ModuleInsightModule.restrictions,
          key: RestrictionInsightsRules.keyProgressCriticalEnd,
          severity: ModuleInsightSeverity.critical,
          title: RestrictionInsightsRules.progressTitle,
          message: RestrictionInsightsRules.progressCriticalEndMessage(
            elapsedText,
          ),
          iconName: RestrictionInsightsRules.iconProgressCriticalEnd,
          isResolved: false,
          updatedAt: now,
        ),
      );
    }
  }

  if (conciliatedTotal > 0) {
    final delayedPercent = (conciliatedOverdue / conciliatedTotal) * 100;
    if (delayedPercent >
        RestrictionInsightsRules.conciliatedCriticalDelayedPercentThreshold) {
      insights.add(
        ModuleInsightRecord(
          projectId: projectId,
          module: ModuleInsightModule.restrictions,
          key: RestrictionInsightsRules.keyConciliatedCritical,
          severity: ModuleInsightSeverity.critical,
          title: RestrictionInsightsRules.conciliatedTitle,
          message: RestrictionInsightsRules.conciliatedCriticalMessage,
          iconName: RestrictionInsightsRules.iconConciliatedCritical,
          isResolved: false,
          updatedAt: now,
        ),
      );
    }
  }

  return insights;
}

Future<List<ModuleInsightRecord>> _buildActaReunionesInsightsImpl(
  AppRepository repo,
  Database db, {
  required int projectId,
}) async {
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
    if (!isCompleted &&
        !isInformative &&
        effectiveDate != null &&
        today.isAfter(effectiveDate)) {
      final days = today.difference(effectiveDate).inDays;
      if (days >= ActreuInsightsRules.delayWarningMinDays &&
          days <= ActreuInsightsRules.delayWarningMaxDays) {
        overdueLow += 1;
      }
      if (days >= ActreuInsightsRules.delayCriticalMinDays) {
        overdueHigh += 1;
      }
    }

    if (baseAgreementDate != null &&
        aplazoDate != null &&
        aplazoDate.isAfter(baseAgreementDate)) {
      final aplazoDays = aplazoDate.difference(baseAgreementDate).inDays;
      if (aplazoDays >= ActreuInsightsRules.deferralDaysWarningMin &&
          aplazoDays < ActreuInsightsRules.deferralDaysWarningMaxExclusive) {
        aplazoDaysAlert += 1;
      }
      if (aplazoDays >= ActreuInsightsRules.deferralDaysCriticalMin) {
        aplazoDaysCritical += 1;
      }
    }

    final aplazoTimes = repo._asInt(row['numAplazos']) ?? 0;
    if (aplazoTimes >= ActreuInsightsRules.deferralTimesWarningMin &&
        aplazoTimes < ActreuInsightsRules.deferralTimesWarningMaxExclusive) {
      aplazoTimesAlert += 1;
    }
    if (aplazoTimes >= ActreuInsightsRules.deferralTimesCriticalMin) {
      aplazoTimesCritical += 1;
    }
  }

  if (overdueLow > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.actaReuniones,
        key: ActreuInsightsRules.keyDelayLow,
        severity: ModuleInsightSeverity.warning,
        title: ActreuInsightsRules.delayTitle,
        message: ActreuInsightsRules.delayLowMessage(overdueLow),
        iconName: ActreuInsightsRules.iconDelayLow,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }
  if (overdueHigh > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.actaReuniones,
        key: ActreuInsightsRules.keyDelayHigh,
        severity: ModuleInsightSeverity.critical,
        title: ActreuInsightsRules.delayTitle,
        message: ActreuInsightsRules.delayHighMessage(overdueHigh),
        iconName: ActreuInsightsRules.iconDelayHigh,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }
  if (aplazoDaysAlert > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.actaReuniones,
        key: ActreuInsightsRules.keyDeferralDaysWarning,
        severity: ModuleInsightSeverity.warning,
        title: ActreuInsightsRules.deferralDaysTitle,
        message: ActreuInsightsRules.deferralDaysWarningMessage(
          aplazoDaysAlert,
        ),
        iconName: ActreuInsightsRules.iconDeferralDaysWarning,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }
  if (aplazoDaysCritical > 0) {
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
  if (aplazoTimesAlert > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.actaReuniones,
        key: ActreuInsightsRules.keyDeferralTimesWarning,
        severity: ModuleInsightSeverity.warning,
        title: ActreuInsightsRules.deferralTimesTitle,
        message: ActreuInsightsRules.deferralTimesWarningMessage(
          aplazoTimesAlert,
        ),
        iconName: ActreuInsightsRules.iconDeferralTimesWarning,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }
  if (aplazoTimesCritical > 0) {
    insights.add(
      ModuleInsightRecord(
        projectId: projectId,
        module: ModuleInsightModule.actaReuniones,
        key: ActreuInsightsRules.keyDeferralTimesCritical,
        severity: ModuleInsightSeverity.critical,
        title: ActreuInsightsRules.deferralTimesTitle,
        message: ActreuInsightsRules.deferralTimesCriticalMessage(
          aplazoTimesCritical,
        ),
        iconName: ActreuInsightsRules.iconDeferralTimesCritical,
        isResolved: false,
        updatedAt: now,
      ),
    );
  }

  return insights;
}
