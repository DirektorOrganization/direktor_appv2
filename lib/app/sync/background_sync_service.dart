import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/app_clock.dart';
import '../notifications/notification_service.dart';
import '../../data/app_repository.dart';
import '../../data/models/app_models.dart';
import '../../data/remote/sync_api_client.dart';
import 'sync_rules.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    _adbLog('callback received task=$task inputData=$inputData');

    if (task != SyncRules.operationalBackgroundTaskName) {
      _adbLog('callback ignored task=$task');
      return true;
    }

    _adbLog('callback executing operational task=$task');
    return BackgroundSyncService.runOperationalTask();
  });
}

abstract final class BackgroundSyncService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    _initialized = true;
    _adbLog('initialize completed debug=$kDebugMode');
  }

  static Future<void> syncOperationalSchedule({
    required bool hasActiveSession,
    required AppPreferences preferences,
    bool resetTimer = false,
  }) async {
    await initialize();

    if (!hasActiveSession ||
        !preferences.remoteSyncEnabled ||
        !preferences.apiConfigured) {
      _adbLog(
        'schedule cancel hasSession=$hasActiveSession '
        'remoteSyncEnabled=${preferences.remoteSyncEnabled} '
        'apiConfigured=${preferences.apiConfigured}',
      );
      await cancelOperationalSync();
      return;
    }

    final scheduleAnchor = resetTimer ? DateTime.now() : preferences.lastSyncAt;
    final initialDelay = _computeNextInitialDelay(lastSyncAt: scheduleAnchor);
    const uniqueName = SyncRules.operationalBackgroundUniqueName;

    await Workmanager().registerOneOffTask(
      uniqueName,
      SyncRules.operationalBackgroundTaskName,
      tag: SyncRules.operationalBackgroundTag,
      initialDelay: initialDelay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    debugPrint(
      '[BackgroundSyncService][schedule] '
      'uniqueName=$uniqueName '
      'delayMin=${initialDelay.inMinutes} '
      'lastSyncAtLima=${_fmtLima(scheduleAnchor)}',
    );
    _adbLog(
      'schedule oneoff '
      'uniqueName=$uniqueName '
      'delayMin=${initialDelay.inMinutes} '
      'lastSyncAtLima=${_fmtLima(scheduleAnchor)}',
    );
  }

  static Future<void> cancelOperationalSync() async {
    await initialize();
    await Workmanager().cancelByTag(SyncRules.operationalBackgroundTag);
    _adbLog('cancel oneoff tag=${SyncRules.operationalBackgroundTag}');
  }

  static Future<bool> runOperationalTask() async {
    final repository = AppRepository();
    try {
      _adbLog('task start');
      await repository.setBackgroundSyncInProgress(true);
      await NotificationService.instance.initialize();
      final bootstrap = await repository.bootstrap();
      final session = bootstrap.session;
      final preferences = bootstrap.preferences;

      if (session?.isActive != true) {
        debugPrint('[BackgroundSyncService][task] skip no active session');
        _adbLog('task skip no active session');
        await cancelOperationalSync();
        return true;
      }

      if (!preferences.remoteSyncEnabled || !preferences.apiConfigured) {
        debugPrint(
          '[BackgroundSyncService][task] skip '
          'remoteSyncEnabled=${preferences.remoteSyncEnabled} '
          'apiConfigured=${preferences.apiConfigured}',
        );
        _adbLog(
          'task skip remoteSyncEnabled=${preferences.remoteSyncEnabled} '
          'apiConfigured=${preferences.apiConfigured}',
        );
        await cancelOperationalSync();
        return true;
      }

      if (!preferences.hasNetwork || preferences.isOfflineEffective) {
        debugPrint(
          '[BackgroundSyncService][task] skip '
          'hasNetwork=${preferences.hasNetwork} '
          'offlineEffective=${preferences.isOfflineEffective}',
        );
        _adbLog(
          'task skip hasNetwork=${preferences.hasNetwork} '
          'offlineEffective=${preferences.isOfflineEffective}',
        );
        await syncOperationalSchedule(
          hasActiveSession: true,
          preferences: preferences,
          resetTimer: true,
        );
        return true;
      }

      if (!repository.shouldRunOperationalSync(preferences)) {
        debugPrint(
          '[BackgroundSyncService][task] skip rule=false '
          'lastSyncAtLima=${_fmtLima(preferences.lastSyncAt)} '
          'nowLima=${_fmtNowLima()}',
        );
        _adbLog(
          'task skip rule=false '
          'lastSyncAtLima=${_fmtLima(preferences.lastSyncAt)} '
          'nowLima=${_fmtNowLima()}',
        );
        await syncOperationalSchedule(
          hasActiveSession: true,
          preferences: preferences,
          resetTimer: true,
        );
        return true;
      }

      _adbLog(
        'task run syncOperationalData '
        'lastSyncAtLima=${_fmtLima(preferences.lastSyncAt)} '
        'nowLima=${_fmtNowLima()}',
      );
      final result = await repository.syncOperationalData(
        source: 'workmanager',
      );
      await _processNotifications(
        events: result.syncChangeEvents ?? const [],
        preferences: result.preferences,
      );
      await syncOperationalSchedule(
        hasActiveSession: result.session?.isActive == true,
        preferences: result.preferences,
        resetTimer: true,
      );
      debugPrint('[BackgroundSyncService][task] operational sync completed');
      _adbLog(
        'task completed '
        'newLastSyncAtLima=${_fmtLima(result.preferences.lastSyncAt)}',
      );
      return true;
    } on SyncAuthRevokedException catch (error, stackTrace) {
      debugPrint('[BackgroundSyncService][task] auth revoked: $error');
      _adbLog('task auth revoked status=${error.statusCode}');
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[BackgroundSyncService][task] auth revoked stack',
      );
      try {
        await repository.revokeSessionAndLogout(reason: 'forbidden_403');
        await cancelOperationalSync();
        _adbLog('task auth revoked -> session closed and schedule cancelled');
      } catch (logoutError, logoutStackTrace) {
        _adbLog('task auth revoked logout failed: $logoutError');
        debugPrintStack(
          stackTrace: logoutStackTrace,
          label: '[BackgroundSyncService][task] auth revoked logout stack',
        );
      }
      return true;
    } on SubscriptionAccessRevokedException catch (error, stackTrace) {
      debugPrint('[BackgroundSyncService][task] subscription revoked: $error');
      _adbLog('task subscription revoked');
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[BackgroundSyncService][task] subscription revoked stack',
      );
      try {
        await repository.revokeSessionAndLogout(reason: error.reason);
        await cancelOperationalSync();
        _adbLog(
          'task subscription revoked -> session closed and schedule cancelled',
        );
      } catch (logoutError, logoutStackTrace) {
        _adbLog('task subscription revoked logout failed: $logoutError');
        debugPrintStack(
          stackTrace: logoutStackTrace,
          label:
              '[BackgroundSyncService][task] subscription revoked logout stack',
        );
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('[BackgroundSyncService][task] failed: $error');
      _adbLog('task failed error=$error');
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[BackgroundSyncService][task] stack',
      );
      try {
        final recoveryBootstrap = await repository.bootstrap();
        await syncOperationalSchedule(
          hasActiveSession: recoveryBootstrap.session?.isActive == true,
          preferences: recoveryBootstrap.preferences,
          resetTimer: true,
        );
        _adbLog(
          'task rescheduled after error '
          'hasSession=${recoveryBootstrap.session?.isActive == true}',
        );
      } catch (rescheduleError, rescheduleStackTrace) {
        _adbLog('task reschedule after error failed: $rescheduleError');
        debugPrintStack(
          stackTrace: rescheduleStackTrace,
          label: '[BackgroundSyncService][task] reschedule stack',
        );
      }
      return true;
    } finally {
      await repository.setBackgroundSyncInProgress(false);
    }
  }

  static Future<void> _processNotifications({
    required List<SyncChangeEvent> events,
    required AppPreferences preferences,
  }) async {
    if (events.isEmpty || !preferences.notificationsEnabled) return;

    for (final event in events) {
      final moduleEnabled = event.module == 'restrictions'
          ? preferences.notificationsRestrictionsEnabled
          : preferences.notificationsActreuEnabled;
      if (!moduleEnabled) continue;

      await NotificationService.instance.showAlert(
        title: event.description,
        body: '${event.oldStatus} -> ${event.newStatus}',
      );
    }
  }

  static Duration _computeNextInitialDelay({required DateTime? lastSyncAt}) {
    final nowUtc = DateTime.now().toUtc();
    final minIntervalReadyAt = lastSyncAt == null
        ? nowUtc.add(SyncRules.operationalBackgroundOneOffDelay)
        : lastSyncAt.toUtc().add(SyncRules.operationalBackgroundOneOffDelay);
    final candidateUtc = minIntervalReadyAt.isAfter(nowUtc)
        ? minIntervalReadyAt
        : nowUtc;
    final windowReadyUtc = _alignUtcToOperationalWindow(candidateUtc);
    final delay = windowReadyUtc.difference(nowUtc);
    if (delay.isNegative || delay == Duration.zero) {
      return const Duration(seconds: 5);
    }
    return delay;
  }

  static DateTime _alignUtcToOperationalWindow(DateTime utcInstant) {
    final zoned = AppClock.toDefaultZone(utcInstant);
    if (zoned.hour < SyncRules.syncWindowStartHour) {
      return _defaultZoneToUtc(
        DateTime.utc(
          zoned.year,
          zoned.month,
          zoned.day,
          SyncRules.syncWindowStartHour,
        ),
      );
    }
    if (zoned.hour >= SyncRules.syncWindowEndHour) {
      final nextDay = DateTime.utc(
        zoned.year,
        zoned.month,
        zoned.day + 1,
        SyncRules.syncWindowStartHour,
      );
      return _defaultZoneToUtc(nextDay);
    }
    return utcInstant;
  }

  static DateTime _defaultZoneToUtc(DateTime zoned) {
    return zoned.subtract(AppClock.defaultUtcOffset);
  }

  static String _fmtLima(DateTime? value) {
    if (value == null) return 'null';
    return AppClock.toIso8601WithDefaultOffset(value);
  }

  static String _fmtNowLima() {
    return AppClock.nowIso8601InDefaultZone();
  }
}

void _adbLog(String message) {
  developer.log(message, name: 'DirektorWorkManager');
  debugPrint('[WM-ADB] $message');
}
