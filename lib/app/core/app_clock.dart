class AppClock {
  AppClock._();

  static const Duration _limaUtcOffset = Duration(hours: -5);
  static const String _limaLabel = 'America/Lima';

  // Configurable para futura internacionalizacion.
  static Duration _defaultUtcOffset = _limaUtcOffset;
  static String _defaultTimezoneLabel = _limaLabel;

  static Duration get defaultUtcOffset => _defaultUtcOffset;
  static String get defaultTimezoneLabel => _defaultTimezoneLabel;

  static void configureDefaultTimezone({
    required Duration utcOffset,
    required String timezoneLabel,
  }) {
    _defaultUtcOffset = utcOffset;
    _defaultTimezoneLabel = timezoneLabel;
  }

  static DateTime toDefaultZone(DateTime value) {
    final utc = value.isUtc ? value : value.toUtc();
    return utc.add(_defaultUtcOffset);
  }

  static DateTime nowInDefaultZone() => toDefaultZone(DateTime.now());

  static String toIso8601WithDefaultOffset(DateTime value) {
    final d = toDefaultZone(value);
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final second = d.second.toString().padLeft(2, '0');
    final milli = d.millisecond.toString().padLeft(3, '0');
    final sign = _defaultUtcOffset.isNegative ? '-' : '+';
    final abs = _defaultUtcOffset.abs();
    final offsetHours = abs.inHours.toString().padLeft(2, '0');
    final offsetMinutes = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '$year-$month-$day'
        'T$hour:$minute:$second.$milli$sign$offsetHours:$offsetMinutes';
  }

  static String nowIso8601InDefaultZone() =>
      toIso8601WithDefaultOffset(DateTime.now());
}

