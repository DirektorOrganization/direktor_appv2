import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../../data/app_repository.dart';
import '../../data/models/app_models.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController({AppRepository? repository}) : _repository = repository ?? AppRepository() {
    WidgetsBinding.instance.addObserver(this);
  }

  final AppRepository _repository;

  bool _initialized = false;
  bool _busy = false;
  bool _syncing = false;
  String? _error;
  LocationAccessState? _locationAccessState;
  bool _shouldShowLocationGuidance = false;
  String? _lastLocationGuidanceKey;
  Future<void>? _initializingFuture;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _pushLoopTimer;
  Timer? _operationalLoopTimer;
  bool _syncAllOnNextManual = false;
  UserSession? _session;
  UserProfile? _user;
  List<ProjectRecord> _projects = const [];
  ProjectRecord? _currentProject;
  ProjectSnapshot? _snapshot;
  AppPreferences _preferences = const AppPreferences(
    keepSignedIn: true,
    isDarkMode: false,
    isOfflineMode: false,
    isOfflineForced: false,
    hasNetwork: true,
    apiConfigured: false,
    remoteSyncEnabled: true,
    isDeviceLinked: false,
    linkedDeviceId: null,
    linkedDeviceLabel: null,
    deviceLinkedAt: null,
    currentProjectId: null,
    lastSyncAt: null,
    lastDailyFullSyncBusinessDate: null,
  );
  List<SyncQueueRecord> _syncQueue = const [];
  SyncOverview _syncOverview = const SyncOverview(
    pendingCount: 0,
    failedCount: 0,
    lastSyncAt: null,
    isOfflineMode: false,
    isOfflineForced: false,
    hasNetwork: true,
    apiConfigured: false,
    remoteSyncEnabled: true,
    lastDailyFullSyncBusinessDate: null,
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
  MilestoneGeneralRecord? get milestoneGeneral => _snapshot?.milestoneGeneral;
  MilestoneDashboardSummary get milestoneSummary => _snapshot?.milestoneSummary ?? const MilestoneDashboardSummary(
        compliance: 0,
        completedCount: 0,
        inProgressCount: 0,
        delayedCount: 0,
        activeDelayCount: 0,
        accumulatedPenalty: 0,
        potentialPenalty: 0,
        activeExtensions: 0,
      );
  List<MilestoneRecord> get milestones => _snapshot?.milestones ?? const [];
  RestrictionCatalogs get catalogs =>
      _snapshot?.catalogs ?? const RestrictionCatalogs(fronts: [], phases: [], areas: [], types: [], responsibles: [], statuses: []);
  AppPreferences get preferences => _preferences;
  List<SyncQueueRecord> get syncQueue => _syncQueue;
  SyncOverview get syncOverview => _syncOverview.copyWith(isSyncing: _syncing);
  bool get isOfflineMode => _preferences.isOfflineEffective;
  bool get isDarkMode => _preferences.isDarkMode;
  bool get isDeviceLinked => _preferences.isDeviceLinked;
  String? get linkedDeviceId => _preferences.linkedDeviceId;
  String? get linkedDeviceLabel => _preferences.linkedDeviceLabel;
  DateTime? get deviceLinkedAt => _preferences.deviceLinkedAt;
  LocationAccessState? get locationAccessState => _locationAccessState;
  bool get shouldShowLocationGuidance => _shouldShowLocationGuidance;
  bool get hasPendingSyncItems => _syncQueue.any((item) => item.status == 'pending' || item.status == 'failed');
  bool get syncAllOnNextManual => _syncAllOnNextManual;

  Future<void> ensureInitialized() {
    if (_initialized) return Future.value();
    _initializingFuture ??= _runGuarded(() async {
      final data = await _repository.bootstrap();
      _apply(data);
      await _repository.ensureLocationConsentRequested();
      await _refreshLocationGuidance(showPrompt: hasActiveSession);
      _startConnectivityWatch();
      _startSyncLoops();
      _initialized = true;
      await _runAutomaticSyncChecks();
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
      _startConnectivityWatch();
      _startSyncLoops();
      _initialized = true;
      success = true;
    });
    if (success &&
        hasActiveSession &&
        _preferences.remoteSyncEnabled &&
        !_preferences.isOfflineEffective &&
        _preferences.apiConfigured) {
      await _refreshLocationGuidance(showPrompt: true, forcePrompt: true);
      await _performFullSync(
        markDailyFullSync: _repository.shouldRunDailyFullSync(_preferences),
      );
    }
    return success;
  }

  Future<void> logout() async {
    await _runGuarded(() async {
      await _connectivitySubscription?.cancel();
      _pushLoopTimer?.cancel();
      _operationalLoopTimer?.cancel();
      await _repository.logout();
      _session = null;
      _user = null;
      _projects = const [];
      _snapshot = null;
      _currentProject = null;
      _syncQueue = const [];
      _syncAllOnNextManual = false;
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

  Future<String?> createRestrictionFront({required int projectId, required String name}) async {
    String? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createRestrictionFront(projectId: projectId, name: name);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdId;
  }

  Future<String?> createRestrictionPhase({
    required int projectId,
    required String frontId,
    required String name,
  }) async {
    String? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createRestrictionPhase(projectId: projectId, frontId: frontId, name: name);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdId;
  }

  Future<void> deleteRestriction(int restrictionId) async {
    await _runGuarded(() async {
      final data = await _repository.deleteRestriction(restrictionId);
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

  Future<void> saveMilestone(MilestoneDraft draft) async {
    await _runGuarded(() async {
      final data = await _repository.saveMilestone(draft);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> saveMilestoneExtension(MilestoneExtensionDraft draft) async {
    await _runGuarded(() async {
      final data = await _repository.saveMilestoneExtension(draft);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> saveMilestoneDocument(MilestoneDocumentDraft draft) async {
    await _runGuarded(() async {
      final data = await _repository.saveMilestoneDocument(draft);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> deleteMilestone(int milestoneId) async {
    await _runGuarded(() async {
      final data = await _repository.deleteMilestone(milestoneId);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> deleteMilestoneDocument(int documentId) async {
    await _runGuarded(() async {
      final data = await _repository.deleteMilestoneDocument(documentId);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> setOfflineMode(bool enabled) async {
    if (_preferences.isOfflineForced) return;
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
    if (enabled) {
      await _runAutomaticSyncChecks();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    await _runGuarded(() async {
      final data = await _repository.setDarkMode(enabled);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> linkCurrentDevice() async {
    await _runGuarded(() async {
      final data = await _repository.linkCurrentDevice(userId: _session?.userId);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> unlinkCurrentDevice() async {
    await _runGuarded(() async {
      final data = await _repository.unlinkCurrentDevice();
      _apply(data);
      _initialized = true;
    });
  }

  Future<String?> buildAttendanceQrPayload() {
    return _repository.buildAttendanceQrPayload(
      userId: _session?.userId,
      userEmail: _user?.email,
    );
  }

  void dismissLocationGuidance() {
    _shouldShowLocationGuidance = false;
    notifyListeners();
  }

  Future<void> openLocationGuidanceSettings() async {
    final state = _locationAccessState;
    if (state == null) return;
    if (state.needsPermissionGuidance) {
      await _repository.openLocationAppSettings();
    } else if (state.needsServiceGuidance) {
      await _repository.openLocationSettings();
    }
    _shouldShowLocationGuidance = false;
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (!hasActiveSession) return;
    if (_syncAllOnNextManual) {
      await _performFullSync(resetManualToggle: true);
      return;
    }

    await _tryPushSync(force: true);
    await _performOperationalSync(resetManualToggle: true);
  }

  void setSyncAllOnNextManual(bool enabled) {
    _syncAllOnNextManual = enabled;
    notifyListeners();
  }

  void _startConnectivityWatch() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      if (hasConnection) {
        unawaited(_refreshAndRunSyncChecks());
      } else {
        unawaited(_refreshState());
      }
    });
  }

  void _startSyncLoops() {
    _pushLoopTimer?.cancel();
    _pushLoopTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_tryPushSync());
    });

    _operationalLoopTimer?.cancel();
    _operationalLoopTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_tryOperationalSyncIfNeeded());
    });
  }

  Future<void> _refreshState() async {
    if (_busy || _syncing) return;
    final data = await _repository.bootstrap();
    _apply(data);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _refreshAndRunSyncChecks() async {
    await _refreshState();
    await _runAutomaticSyncChecks();
  }

  Future<void> _runAutomaticSyncChecks() async {
    if (!_initialized || !hasActiveSession) return;

    final fullSyncRan = await _tryDailyFullSyncIfNeeded();
    if (fullSyncRan) return;

    await _tryPushSync();
    await _tryOperationalSyncIfNeeded();
  }

  Future<bool> _tryDailyFullSyncIfNeeded() async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) return false;
    if (!_preferences.remoteSyncEnabled || _preferences.isOfflineEffective || !_preferences.apiConfigured) return false;
    if (!_repository.shouldRunDailyFullSync(_preferences)) return false;

    await _performFullSync(markDailyFullSync: true);
    return true;
  }

  Future<void> _tryOperationalSyncIfNeeded() async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) return;
    if (!_preferences.remoteSyncEnabled || _preferences.isOfflineEffective || !_preferences.apiConfigured) return;
    if (!_repository.shouldRunOperationalSync(_preferences)) return;

    await _performOperationalSync();
  }

  Future<void> _tryPushSync({bool force = false}) async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) return;
    if (!_preferences.remoteSyncEnabled || _preferences.isOfflineEffective || !_preferences.apiConfigured) return;
    if (!force && !hasPendingSyncItems) return;

    await _performPushSync();
  }

  Future<void> _performFullSync({
    bool markDailyFullSync = false,
    bool resetManualToggle = false,
  }) async {
    if (_syncing || !hasActiveSession) return;
    _syncing = true;
    notifyListeners();
    await _runGuarded(() async {
      final data = await _repository.syncFullData(markDailyFullSync: markDailyFullSync);
      _apply(data);
      _initialized = true;
    });
    if (resetManualToggle) {
      _syncAllOnNextManual = false;
    }
    _syncing = false;
    notifyListeners();
  }

  Future<void> _performOperationalSync({bool resetManualToggle = false}) async {
    if (_syncing || !hasActiveSession) return;
    _syncing = true;
    notifyListeners();
    await _runGuarded(() async {
      final data = await _repository.syncOperationalData();
      _apply(data);
      _initialized = true;
    });
    if (resetManualToggle) {
      _syncAllOnNextManual = false;
    }
    _syncing = false;
    notifyListeners();
  }

  Future<void> _performPushSync() async {
    if (_syncing || !hasActiveSession) return;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshLocationGuidance(showPrompt: hasActiveSession, forcePrompt: true));
      unawaited(_refreshAndRunSyncChecks());
    }
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

  MilestoneRecord? findMilestoneById(int id) {
    for (final item in milestones) {
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

  Future<void> _refreshLocationGuidance({
    required bool showPrompt,
    bool forcePrompt = false,
  }) async {
    final state = await _repository.getLocationAccessState();
    _locationAccessState = state;
    if (!showPrompt || !state.shouldShowGuidance) {
      _shouldShowLocationGuidance = false;
      notifyListeners();
      return;
    }

    if (forcePrompt || _lastLocationGuidanceKey != state.guidanceKey) {
      _lastLocationGuidanceKey = state.guidanceKey;
      _shouldShowLocationGuidance = true;
      notifyListeners();
      return;
    }

    notifyListeners();
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error, stackTrace) {
      _error = error.toString();
      debugPrint('[AppController] guarded action failed: $error');
      debugPrintStack(stackTrace: stackTrace, label: '[AppController] stack trace');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _pushLoopTimer?.cancel();
    _operationalLoopTimer?.cancel();
    super.dispose();
  }
}


