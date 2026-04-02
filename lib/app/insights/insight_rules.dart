import 'package:flutter/foundation.dart';

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
