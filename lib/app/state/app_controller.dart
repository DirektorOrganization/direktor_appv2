import 'package:flutter/foundation.dart';

import '../../data/app_repository.dart';
import '../../data/models/app_models.dart';

class AppController extends ChangeNotifier {
  AppController({AppRepository? repository}) : _repository = repository ?? AppRepository();

  final AppRepository _repository;

  bool _initialized = false;
  bool _busy = false;
  bool _syncing = false;
  String? _error;
  Future<void>? _initializingFuture;
  UserSession? _session;
  UserProfile? _user;
  List<ProjectRecord> _projects = const [];
  ProjectRecord? _currentProject;
  ProjectSnapshot? _snapshot;
  AppPreferences _preferences = const AppPreferences(
    keepSignedIn: true,
    isOfflineMode: false,
    remoteSyncEnabled: true,
    currentProjectId: null,
    lastSyncAt: null,
  );
  List<SyncQueueRecord> _syncQueue = const [];
  SyncOverview _syncOverview = const SyncOverview(
    pendingCount: 0,
    failedCount: 0,
    lastSyncAt: null,
    isOfflineMode: false,
    remoteSyncEnabled: true,
  );

  bool get isInitialized => _initialized;
  bool get isBusy => _busy;
  bool get isSyncing => _syncing;
  String? get error => _error;
  bool get hasActiveSession => _session?.isActive == true;
  UserProfile? get user => _user;
  List<ProjectRecord> get projects => _projects;
  ProjectRecord? get currentProject => _currentProject;
  ProjectSnapshot? get snapshot => _snapshot;
  List<RestrictionRecord> get restrictions => _snapshot?.restrictions ?? const [];
  List<RestrictionRecord> get completedRestrictions => _snapshot?.completedRestrictions ?? const [];
  RestrictionSummary get restrictionSummary =>
      _snapshot?.summary ?? const RestrictionSummary(total: 0, completed: 0, overdue: 0, inProgress: 0, pending: 0, compliancePercent: 0);
  MeetingSummaryRecord get meetingSummary =>
      _snapshot?.meetingSummary ?? const MeetingSummaryRecord(overdueAgreements: 0, pendingAgreements: 0, nextMeetingDate: null);
  List<MeetingRecord> get meetings => _snapshot?.meetings ?? const [];
  List<MeetingAgreementRecord> get agreements => _snapshot?.agreements ?? const [];
  RestrictionCatalogs get catalogs =>
      _snapshot?.catalogs ?? const RestrictionCatalogs(fronts: [], phases: [], areas: [], types: [], responsibles: [], statuses: []);
  AppPreferences get preferences => _preferences;
  List<SyncQueueRecord> get syncQueue => _syncQueue;
  SyncOverview get syncOverview => _syncOverview.copyWith(isSyncing: _syncing);
  bool get isOfflineMode => _preferences.isOfflineMode;

  Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    _initializingFuture ??= _runGuarded(() async {
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    }).whenComplete(() => _initializingFuture = null);
    return _initializingFuture!;
  }

  Future<bool> login({
    required String userOrEmail,
    required String password,
    required bool keepSignedIn,
  }) async {
    var success = false;
    await _runGuarded(() async {
      final data = await _repository.login(
        userOrEmail: userOrEmail,
        password: password,
        keepSignedIn: keepSignedIn,
      );
      _apply(data);
      _initialized = true;
      success = true;
    });
    return success;
  }

  Future<void> logout() async {
    await _runGuarded(() async {
      await _repository.logout();
      _session = null;
      _user = null;
      _projects = const [];
      _snapshot = null;
      _currentProject = null;
      _syncQueue = const [];
    });
  }

  Future<void> changeProject(int projectId) async {
    await _runGuarded(() async {
      final data = await _repository.changeProject(projectId);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> updateRestrictionStatus(int restrictionId, String statusCode) async {
    await _runGuarded(() async {
      final data = await _repository.updateRestrictionStatus(restrictionId: restrictionId, statusCode: statusCode);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> saveRestriction(RestrictionDraft draft) async {
    await _runGuarded(() async {
      final data = await _repository.saveRestriction(draft);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> updateAgreementStatus(int agreementId, String statusCode) async {
    await _runGuarded(() async {
      final data = await _repository.updateAgreementStatus(agreementId: agreementId, statusCode: statusCode);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> setOfflineMode(bool enabled) async {
    await _runGuarded(() async {
      final data = await _repository.setOfflineMode(enabled);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> setRemoteSyncEnabled(bool enabled) async {
    await _runGuarded(() async {
      final data = await _repository.setRemoteSyncEnabled(enabled);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> syncNow() async {
    _syncing = true;
    notifyListeners();
    await _runGuarded(() async {
      final data = await _repository.syncPendingChanges();
      _apply(data);
      _initialized = true;
    });
    _syncing = false;
    notifyListeners();
  }

  RestrictionRecord? findRestrictionById(int id) {
    for (final item in restrictions) {
      if (item.id == id) return item;
    }
    for (final item in completedRestrictions) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _apply(AppBootstrapData data) {
    _session = data.session;
    _user = data.user;
    _projects = data.projects;
    _currentProject = data.currentProject;
    _snapshot = data.snapshot;
    _preferences = data.preferences;
    _syncQueue = data.syncQueue;
    _syncOverview = data.syncOverview;
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
