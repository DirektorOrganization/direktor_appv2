part of 'app_repository.dart';

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}

extension _AppRepositoryUtils on AppRepository {
  DateTime _toLimaDateTime(DateTime value) {
    return AppClock.toDefaultZone(value);
  }

  DateTime _nowInLima() => AppClock.nowInDefaultZone();

  String _toLimaIso8601String(DateTime value) =>
      AppClock.toIso8601WithDefaultOffset(value);

  String? _buildOperationalSinceCursor(DateTime? lastSyncAt) {
    if (lastSyncAt == null) return null;

    final baseInstant = SyncRules.enableSinceOverlap
        ? lastSyncAt.subtract(SyncRules.sinceOverlapDuration)
        : lastSyncAt;
    final utc = baseInstant.toUtc();
    // Truncamos al minuto para evitar perdidas por segundos/milisegundos.
    final flooredUtc = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
    );
    return _toLimaIso8601String(flooredUtc);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, item) => MapEntry('$key', item));
    return const {};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => row.map((key, item) => MapEntry('$key', item)))
        .toList();
  }

  bool _isDeleted(Map<String, dynamic> row) {
    final value = row['deleted'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  bool _isDeletedByStatus(
    Map<String, dynamic> row, {
    String statusField = 'codEstado',
  }) {
    if (_isDeleted(row)) return true;
    return _asInt(row[statusField]) == -1;
  }

  bool _isRestrictionActivityDeleted(Map<String, dynamic> row) {
    if (_isDeleted(row)) return true;
    return _asInt(row['codEstadoActividad']) == -1;
  }

  bool _isMilestoneDeleted(Map<String, dynamic> row) {
    return _isDeletedByStatus(row);
  }

  void _traceActreuGroupMaster({
    required String scope,
    required int projectId,
    required int subcategoryId,
    required List<Map<String, Object?>> groupRows,
  }) {
    final ids = groupRows
        .map((row) => _asInt(row['codActReuGrupoAcuerdo']))
        .whereType<int>()
        .toList();
    final unique = ids.toSet();
    final duplicates = <int>{};
    final seen = <int>{};
    for (final id in ids) {
      if (!seen.add(id)) duplicates.add(id);
    }
    final duplicateIds = duplicates.toList()..sort();
    debugPrint(
      '[ActreuTrace][$scope] project=$projectId subcategory=$subcategoryId '
      'groupRows=${groupRows.length} uniqueIds=${unique.length} '
      'duplicateIds=${duplicates.isEmpty ? 'none' : duplicateIds}',
    );
    if (duplicates.isNotEmpty) {
      for (final id in duplicates) {
        final duplicateRows = groupRows
            .where((row) => _asInt(row['codActReuGrupoAcuerdo']) == id)
            .toList();
        debugPrint(
          '[ActreuTrace][$scope] duplicate_group id=$id rows=$duplicateRows',
        );
      }
    }
  }

  void _traceActreuAgreementGroupMatch({
    required String scope,
    required int agreementId,
    required dynamic rawGroupId,
    required int? parsedGroupId,
    required String resolvedGroupName,
    required String? resolvedGroupColor,
    required bool foundInMaster,
  }) {
    debugPrint(
      '[ActreuTrace][$scope] agreement=$agreementId '
      'rawGroupId=$rawGroupId parsedGroupId=$parsedGroupId '
      'foundInMaster=$foundInMaster resolvedName="$resolvedGroupName" '
      'resolvedColor=${resolvedGroupColor ?? '-'}',
    );
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    final text = '$value';
    return text.isEmpty ? null : text;
  }

  int _asBoolInt(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value == 0 ? 0 : 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return 1;
      if (normalized == 'false' || normalized == '0') return 0;
    }
    return 0;
  }

  Map<String, Object?> _statusFlagsFromCatalogRow(Map<String, Object?> row) {
    final controlOrder = _asInt(row['codElementoControl']);
    final statusLabel = _asString(row['desEstado']) ?? '';
    if (controlOrder != null) {
      switch (controlOrder) {
        case 3:
          return _statusFlagsFromKind('completed');
        case 2:
          return _statusFlagsFromKind('in_progress');
        default:
          return _statusFlagsFromKind('pending');
      }
    }
    return _statusFlagsFromStatusCode(
      _asString(row['codEstado']) ?? '',
      statusLabel: statusLabel,
    );
  }

  Map<String, Object?> _statusFlagsFromStatusCode(
    String statusCode, {
    String statusLabel = '',
  }) {
    return _statusFlagsFromKind(
      _restrictionStatusKind(statusCode, statusLabel: statusLabel),
    );
  }

  Map<String, Object?> _statusFlagsFromKind(String statusKind) {
    return {
      'is_completed': statusKind == 'completed' ? 1 : 0,
      'is_overdue': 0,
      'is_due_today': 0,
      'is_pending': statusKind == 'pending' ? 1 : 0,
      'is_in_progress': statusKind == 'in_progress' ? 1 : 0,
    };
  }

  int _priorityOrder(String statusCode) {
    switch (statusCode) {
      case 'in_progress':
        return 2;
      case 'pending':
        return 3;
      case 'completed':
        return 5;
      default:
        return 9;
    }
  }

  String _restrictionStatusKind(String statusCode, {String statusLabel = ''}) {
    switch (statusCode) {
      case '1':
      case 'pending':
        return 'pending';
      case '2':
      case 'in_progress':
        return 'in_progress';
      case '3':
      case 'completed':
        return 'completed';
    }

    final normalizedLabel = statusLabel.trim().toLowerCase();
    if (normalizedLabel.contains('complet')) return 'completed';
    if (normalizedLabel.contains('proceso') ||
        normalizedLabel.contains('progress')) {
      return 'in_progress';
    }
    return 'pending';
  }

  String _milestoneTypeLabel(int? code) {
    return '';
  }

  String _milestoneClassificationLabel(int? code) {
    return '';
  }

  bool _isPastDate(DateTime value) {
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final target = DateTime(value.year, value.month, value.day);
    return current.isAfter(target);
  }

  bool _isToday(DateTime value) {
    final today = DateTime.now();
    return value.year == today.year &&
        value.month == today.month &&
        value.day == today.day;
  }

  DateTime? _parseDateOnly(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day, 12);
    }

    final parsed = _parseDate(value.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day, 12);
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    // Conservamos el instante real y evitamos convertir aqui para no desplazar
    // 5 horas al volver a serializar `since`.
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  List<DateTime> _buildActreuScheduleDates({
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
    required Set<int> weekdays,
    int? monthlyDay,
  }) {
    final dates = <DateTime>[];
    if (endDate.isBefore(startDate)) return dates;
    final normalizedWeekdays = weekdays.where((d) => d >= 1 && d <= 7).toSet();
    final baseWeekStart = startDate.subtract(
      Duration(days: startDate.weekday - 1),
    );
    final safeMonthlyDay = (monthlyDay ?? startDate.day).clamp(1, 28);

    var current = startDate;
    while (!current.isAfter(endDate)) {
      var include = false;
      switch (frequency) {
        case 'Diaria':
          include = true;
          break;
        case 'Interdiaria':
          include = current.difference(startDate).inDays % 2 == 0;
          break;
        case 'Semanal':
          include = normalizedWeekdays.isEmpty
              ? current.weekday == startDate.weekday
              : normalizedWeekdays.contains(current.weekday);
          break;
        case 'Quincenal':
          final weekStart = current.subtract(
            Duration(days: current.weekday - 1),
          );
          final weekDelta = weekStart.difference(baseWeekStart).inDays ~/ 7;
          final weekdayMatch = normalizedWeekdays.isEmpty
              ? current.weekday == startDate.weekday
              : normalizedWeekdays.contains(current.weekday);
          include = weekdayMatch && weekDelta % 2 == 0;
          break;
        case 'Mensual':
          include = current.day == safeMonthlyDay;
          break;
        default:
          include = false;
      }
      if (include) {
        dates.add(DateTime(current.year, current.month, current.day));
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  String _normalizeHourMinute(String value) {
    final raw = value.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(raw);
    if (match == null) {
      return '00:00';
    }
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return '00:00';
    }
    final safeHour = hour.clamp(0, 23);
    final safeMinute = minute.clamp(0, 59);
    return '${safeHour.toString().padLeft(2, '0')}:${safeMinute.toString().padLeft(2, '0')}';
  }

  String _currentBusinessDateKey({DateTime? now}) {
    final current = now == null ? _nowInLima() : _toLimaDateTime(now);
    final anchor = current.hour >= 6
        ? current
        : current.subtract(const Duration(days: 1));
    final month = anchor.month.toString().padLeft(2, '0');
    final day = anchor.day.toString().padLeft(2, '0');
    return '${anchor.year}-$month-$day';
  }

  String _capitalizeWords(String value) {
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
