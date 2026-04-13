import 'package:flutter/foundation.dart';

import '../../data/models/app_models.dart';

// ── Rule definition types ─────────────────────────────────────────────────────

/// Describes a single configurable threshold within a rule.
class InsightThresholdDef {
  const InsightThresholdDef({
    required this.key,
    required this.label,
    required this.defaultValue,
    this.min = 0,
    this.max = 999,
  });

  final String key;
  final String label;
  final int defaultValue;
  final int min;
  final int max;
}

/// Describes an insight rule (static metadata for the config UI).
class InsightRuleDef {
  const InsightRuleDef({
    required this.key,
    required this.module,
    required this.label,
    required this.description,
    this.thresholds = const [],
  });

  final String key;
  final ModuleInsightModule module;
  final String label;
  final String description;
  final List<InsightThresholdDef> thresholds;
}

// ── Restriction rules catalog ─────────────────────────────────────────────────

const List<InsightRuleDef> restrictionRulesCatalog = [
  InsightRuleDef(
    key: RestrictionInsightsRules.keyDelayLow,
    module: ModuleInsightModule.restrictions,
    label: 'Retraso leve',
    description: 'Restricciones con retraso menor al umbral configurado.',
    thresholds: [
      InsightThresholdDef(
        key: 'minDays',
        label: 'Días mínimos de retraso',
        defaultValue: RestrictionInsightsRules.delayWarningMinDays,
        min: 1,
        max: 30,
      ),
      InsightThresholdDef(
        key: 'maxDays',
        label: 'Días máximos de retraso',
        defaultValue: RestrictionInsightsRules.delayWarningMaxDays,
        min: 1,
        max: 30,
      ),
    ],
  ),
  InsightRuleDef(
    key: RestrictionInsightsRules.keyDelayHigh,
    module: ModuleInsightModule.restrictions,
    label: 'Retraso crítico',
    description: 'Restricciones con retraso mayor al umbral configurado.',
    thresholds: [
      InsightThresholdDef(
        key: 'minDays',
        label: 'Días mínimos para crítico',
        defaultValue: RestrictionInsightsRules.delayCriticalMinDays,
        min: 1,
        max: 60,
      ),
    ],
  ),
  InsightRuleDef(
    key: RestrictionInsightsRules.keyProgressWarning,
    module: ModuleInsightModule.restrictions,
    label: 'Avance con alerta',
    description: 'Porcentaje de días transcurridos con retrasos leves.',
    thresholds: [
      InsightThresholdDef(
        key: 'minPercent',
        label: 'Porcentaje mínimo de avance (%)',
        defaultValue: RestrictionInsightsRules.progressWarningMinPercentExclusive,
        min: 1,
        max: 99,
      ),
      InsightThresholdDef(
        key: 'maxPercent',
        label: 'Porcentaje máximo de avance (%)',
        defaultValue: RestrictionInsightsRules.progressWarningMaxPercentInclusive,
        min: 1,
        max: 100,
      ),
      InsightThresholdDef(
        key: 'maxOverdueDays',
        label: 'Máximo días retrasados permitidos',
        defaultValue: RestrictionInsightsRules.progressWarningMaxOverdueDays,
        min: 0,
        max: 60,
      ),
    ],
  ),
  InsightRuleDef(
    key: RestrictionInsightsRules.keyProgressCriticalMid,
    module: ModuleInsightModule.restrictions,
    label: 'Avance crítico (etapa media)',
    description: 'Muchos días retrasados en etapa intermedia del proyecto.',
    thresholds: [
      InsightThresholdDef(
        key: 'minPercent',
        label: 'Porcentaje mínimo de avance (%)',
        defaultValue: RestrictionInsightsRules.progressCriticalMidMinPercentExclusive,
        min: 1,
        max: 99,
      ),
      InsightThresholdDef(
        key: 'maxPercent',
        label: 'Porcentaje máximo de avance (%)',
        defaultValue: RestrictionInsightsRules.progressCriticalMidMaxPercentInclusive,
        min: 1,
        max: 100,
      ),
      InsightThresholdDef(
        key: 'minOverdueDays',
        label: 'Mínimo días retrasados requeridos',
        defaultValue: RestrictionInsightsRules.progressCriticalMidMinOverdueDays,
        min: 1,
        max: 90,
      ),
    ],
  ),
  InsightRuleDef(
    key: RestrictionInsightsRules.keyProgressCriticalEnd,
    module: ModuleInsightModule.restrictions,
    label: 'Avance crítico (etapa final)',
    description: 'Retrasos cuando la obra está por finalizar.',
    thresholds: [
      InsightThresholdDef(
        key: 'minPercent',
        label: 'Porcentaje mínimo de avance (%)',
        defaultValue: RestrictionInsightsRules.progressCriticalEndMinPercentExclusive,
        min: 1,
        max: 100,
      ),
      InsightThresholdDef(
        key: 'maxPercent',
        label: 'Porcentaje máximo de avance (%)',
        defaultValue: RestrictionInsightsRules.progressCriticalEndMaxPercentInclusive,
        min: 1,
        max: 100,
      ),
      InsightThresholdDef(
        key: 'minOverdueDays',
        label: 'Mínimo días retrasados requeridos',
        defaultValue: RestrictionInsightsRules.progressCriticalEndMinOverdueDays,
        min: 1,
        max: 60,
      ),
    ],
  ),
  InsightRuleDef(
    key: RestrictionInsightsRules.keyConciliatedCritical,
    module: ModuleInsightModule.restrictions,
    label: 'Conciliadas con retraso',
    description: 'Porcentaje alto de restricciones conciliadas retrasadas.',
    thresholds: [
      InsightThresholdDef(
        key: 'delayedPercent',
        label: 'Umbral de porcentaje retrasadas (%)',
        defaultValue: RestrictionInsightsRules.conciliatedCriticalDelayedPercentThreshold,
        min: 1,
        max: 100,
      ),
    ],
  ),
];

// ── Acta de Reuniones rules catalog ───────────────────────────────────────────

const List<InsightRuleDef> actaReunionesRulesCatalog = [
  InsightRuleDef(
    key: ActreuInsightsRules.keyDelayLow,
    module: ModuleInsightModule.actaReuniones,
    label: 'Acuerdo con retraso leve',
    description: 'Acuerdos con retraso menor al umbral configurado.',
    thresholds: [
      InsightThresholdDef(
        key: 'minDays',
        label: 'Días mínimos de retraso',
        defaultValue: ActreuInsightsRules.delayWarningMinDays,
        min: 1,
        max: 30,
      ),
      InsightThresholdDef(
        key: 'maxDays',
        label: 'Días máximos de retraso',
        defaultValue: ActreuInsightsRules.delayWarningMaxDays,
        min: 1,
        max: 30,
      ),
    ],
  ),
  InsightRuleDef(
    key: ActreuInsightsRules.keyDelayHigh,
    module: ModuleInsightModule.actaReuniones,
    label: 'Acuerdo con retraso crítico',
    description: 'Acuerdos con retraso mayor al umbral configurado.',
    thresholds: [
      InsightThresholdDef(
        key: 'minDays',
        label: 'Días mínimos para crítico',
        defaultValue: ActreuInsightsRules.delayCriticalMinDays,
        min: 1,
        max: 60,
      ),
    ],
  ),
  InsightRuleDef(
    key: ActreuInsightsRules.keyDeferralDaysWarning,
    module: ModuleInsightModule.actaReuniones,
    label: 'Aplazo por días (alerta)',
    description: 'Acuerdos aplazados con días de aplazo en rango de alerta.',
    thresholds: [
      InsightThresholdDef(
        key: 'minDays',
        label: 'Días mínimos de aplazo',
        defaultValue: ActreuInsightsRules.deferralDaysWarningMin,
        min: 1,
        max: 90,
      ),
      InsightThresholdDef(
        key: 'maxDaysExclusive',
        label: 'Días máximos de aplazo (exclusivo)',
        defaultValue: ActreuInsightsRules.deferralDaysWarningMaxExclusive,
        min: 1,
        max: 90,
      ),
    ],
  ),
  InsightRuleDef(
    key: ActreuInsightsRules.keyDeferralDaysCritical,
    module: ModuleInsightModule.actaReuniones,
    label: 'Aplazo por días (crítico)',
    description: 'Acuerdos aplazados con muchos días de aplazo.',
    thresholds: [
      InsightThresholdDef(
        key: 'minDays',
        label: 'Días mínimos para crítico',
        defaultValue: ActreuInsightsRules.deferralDaysCriticalMin,
        min: 1,
        max: 180,
      ),
    ],
  ),
  InsightRuleDef(
    key: ActreuInsightsRules.keyDeferralTimesWarning,
    module: ModuleInsightModule.actaReuniones,
    label: 'Múltiples aplazos (alerta)',
    description: 'Acuerdos aplazados varias veces en rango de alerta.',
    thresholds: [
      InsightThresholdDef(
        key: 'minTimes',
        label: 'Veces mínimas de aplazo',
        defaultValue: ActreuInsightsRules.deferralTimesWarningMin,
        min: 1,
        max: 20,
      ),
      InsightThresholdDef(
        key: 'maxTimesExclusive',
        label: 'Veces máximas (exclusivo)',
        defaultValue: ActreuInsightsRules.deferralTimesWarningMaxExclusive,
        min: 1,
        max: 20,
      ),
    ],
  ),
  InsightRuleDef(
    key: ActreuInsightsRules.keyDeferralTimesCritical,
    module: ModuleInsightModule.actaReuniones,
    label: 'Múltiples aplazos (crítico)',
    description: 'Acuerdos aplazados demasiadas veces.',
    thresholds: [
      InsightThresholdDef(
        key: 'minTimes',
        label: 'Veces mínimas para crítico',
        defaultValue: ActreuInsightsRules.deferralTimesCriticalMin,
        min: 1,
        max: 50,
      ),
    ],
  ),
];

/// Returns the rule catalog for a given module.
List<InsightRuleDef> insightRulesCatalogForModule(ModuleInsightModule module) {
  switch (module) {
    case ModuleInsightModule.restrictions:
      return restrictionRulesCatalog;
    case ModuleInsightModule.actaReuniones:
      return actaReunionesRulesCatalog;
  }
}

@immutable
abstract final class RestrictionInsightsRules {
  static const String delayTitle = 'Cantidad Dias de Retraso';
  static const String progressTitle = 'Porcentaje de Avance de Restricciones';
  static const String conciliatedTitle = 'Porcentaje de fechas Conciliadas';

  static const int delayWarningMinDays = 1;
  static const int delayWarningMaxDays = 3;
  static const int delayCriticalMinDays = 4;

  static const int progressWarningMinPercentExclusive = 30;
  static const int progressWarningMaxPercentInclusive = 90;
  static const int progressWarningMaxOverdueDays = 7;

  static const int progressCriticalMidMinPercentExclusive = 30;
  static const int progressCriticalMidMaxPercentInclusive = 90;
  static const int progressCriticalMidMinOverdueDays = 8;

  static const int progressCriticalEndMinPercentExclusive = 90;
  static const int progressCriticalEndMaxPercentInclusive = 100;
  static const int progressCriticalEndMinOverdueDays = 4;

  static const int conciliatedCriticalDelayedPercentThreshold = 30;

  static const String keyDelayLow = 'restrictions_delay_low';
  static const String keyDelayHigh = 'restrictions_delay_high';
  static const String keyProgressWarning = 'restrictions_progress_warning';
  static const String keyProgressCriticalMid =
      'restrictions_progress_critical_mid';
  static const String keyProgressCriticalEnd =
      'restrictions_progress_critical_end';
  static const String keyConciliatedCritical =
      'restrictions_conciliated_critical';

  static const String iconDelayLow = 'schedule';
  static const String iconDelayHigh = 'priority_high';
  static const String iconProgressWarning = 'trending_up';
  static const String iconProgressCriticalMid = 'report_problem';
  static const String iconProgressCriticalEnd = 'warning';
  static const String iconConciliatedCritical = 'event_busy';

  static String delayLowMessage(int count) =>
      'Tenemos $count restricciones con un retraso menor a 3 dias.';

  static String delayHighMessage(int count) =>
      'Tenemos $count restriccion con retraso mayor a 3 dias , tomar acciones';

  static String progressWarningMessage(String elapsedPercentText) =>
      'Se tiene $elapsedPercentText% de dias cumplidos , con retrasos en actividades. Revisar! ';

  static String progressCriticalMidMessage(
    String elapsedPercentText,
    int overdueCount,
  ) =>
      'Se tiene $elapsedPercentText% de dias cumplidos , con $overdueCount dias de retrasos. Tomar Acción. ';

  static String progressCriticalEndMessage(String elapsedPercentText) =>
      'Se cumplio $elapsedPercentText% de dias , la obra se finaliza pronto. Tomar accion con los retrasados. ';

  static const String conciliatedCriticalMessage =
      'Tenemos mas de 30% de restricciones conciliadas con retraso.Tomar accion urgente.';
}

@immutable
abstract final class ActreuInsightsRules {
  static const String delayTitle = 'Cantidad Dias de Retraso';
  static const String deferralDaysTitle = 'Cantidad Dias de Aplazo';
  static const String deferralTimesTitle = 'Cantidad de Veces Aplazadas';

  static const int delayWarningMinDays = 1;
  static const int delayWarningMaxDays = 3;
  static const int delayCriticalMinDays = 4;

  static const int deferralDaysWarningMin = 10;
  static const int deferralDaysWarningMaxExclusive = 15;
  static const int deferralDaysCriticalMin = 15;

  static const int deferralTimesWarningMin = 2;
  static const int deferralTimesWarningMaxExclusive = 5;
  static const int deferralTimesCriticalMin = 5;

  static const String keyDelayLow = 'actreu_delay_low';
  static const String keyDelayHigh = 'actreu_delay_high';
  static const String keyDeferralDaysWarning = 'actreu_deferral_days_warning';
  static const String keyDeferralDaysCritical = 'actreu_deferral_days_critical';
  static const String keyDeferralTimesWarning = 'actreu_deferral_times_warning';
  static const String keyDeferralTimesCritical =
      'actreu_deferral_times_critical';

  static const String iconDelayLow = 'flag';
  static const String iconDelayHigh = 'crisis_alert';
  static const String iconDeferralDaysWarning = 'schedule_send';
  static const String iconDeferralDaysCritical = 'event_repeat';
  static const String iconDeferralTimesWarning = 'restart_alt';
  static const String iconDeferralTimesCritical = 'dangerous';

  static String delayLowMessage(int count) =>
      'Tenemos $count acuerdos con retraso menor a 3 dias.';

  static String delayHighMessage(int count) =>
      'Tenemos $count acuerdos con retraso mayor a 3 dias , tomar acciones';

  static String deferralDaysWarningMessage(int count) =>
      'Tenemos $count acuerdos con mas de 10 dias de Aplazo ';

  static String deferralDaysCriticalMessage(int count) =>
      'Tenemos $count acuerdos con mas de 15 dias de Aplazo , Cuidado';

  static String deferralTimesWarningMessage(int count) =>
      'Tenemos $count acuerdos con mas de 2 veces de aplazo , Revisar.';

  static String deferralTimesCriticalMessage(int count) =>
      'Tenemos $count acuerdos con mas de 5 veces de aplazo ,  Revisar.';
}
