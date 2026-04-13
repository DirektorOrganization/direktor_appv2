import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../notifications/notification_service.dart';
import '../sync/sync_rules.dart';
import '../../data/app_repository.dart';
import '../../data/models/app_models.dart';

class AppController extends ChangeNotifier with WidgetsBindingObserver {
  AppController({AppRepository? repository})
    : _repository = repository ?? AppRepository() {
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
  bool? _lastConnectivityHasConnection;
  UserSession? _session;
  UserProfile? _user;
  String? _hubStyle;
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
  List<HubIndicatorPref> _indicatorPrefs = const [];
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
  String? get hubStyle => _hubStyle;
  List<ProjectRecord> get projects => _projects;
  ProjectRecord? get currentProject => _currentProject;
  ProjectSnapshot? get snapshot => _snapshot;
  List<RestrictionRecord> get restrictions =>
      _snapshot?.restrictions ?? const [];
  List<RestrictionRecord> get completedRestrictions =>
      _snapshot?.completedRestrictions ?? const [];
  RestrictionSummary get restrictionSummary =>
      _snapshot?.summary ??
      const RestrictionSummary(
        total: 0,
        completed: 0,
        overdue: 0,
        inProgress: 0,
        pending: 0,
        compliancePercent: 0,
      );
  List<MilestoneLookupOption> get milestoneTypes =>
      _snapshot?.milestoneTypes ?? const [];
  List<MilestoneLookupOption> get milestoneClassifications =>
      _snapshot?.milestoneClassifications ?? const [];
  MilestoneGeneralRecord? get milestoneGeneral => _snapshot?.milestoneGeneral;
  MilestoneDashboardSummary get milestoneSummary =>
      _snapshot?.milestoneSummary ??
      const MilestoneDashboardSummary(
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
  List<ModuleInsightRecord> get restrictionInsights =>
      _snapshot?.restrictionInsights ?? const [];
  List<ModuleInsightRecord> get actaReunionesInsights =>
      _snapshot?.actaReunionesInsights ?? const [];
  ActreuSummaryRecord? get actreuSummary => _snapshot?.actreuSummary;
  RestrictionCatalogs get catalogs =>
      _snapshot?.catalogs ??
      const RestrictionCatalogs(
        fronts: [],
        phases: [],
        areas: [],
        types: [],
        responsibles: [],
        statuses: [],
      );
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
  bool get hasPendingSyncItems => _syncQueue.any(
    (item) => item.status == 'pending' || item.status == 'failed',
  );
  bool get syncAllOnNextManual => _syncAllOnNextManual;
  List<HubIndicatorPref> get indicatorPrefs => _indicatorPrefs;
  bool get notificationsEnabled => _preferences.notificationsEnabled;
  bool get notificationsRestrictionsEnabled => _preferences.notificationsRestrictionsEnabled;
  bool get notificationsActreuEnabled => _preferences.notificationsActreuEnabled;
  bool get indicatorsEnabled => _preferences.indicatorsEnabled;
  bool get indicatorsRestrictionsEnabled => _preferences.indicatorsRestrictionsEnabled;
  bool get indicatorsMilestonesEnabled => _preferences.indicatorsMilestonesEnabled;
  bool get indicatorsActreuEnabled => _preferences.indicatorsActreuEnabled;

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

  Future<void> updateRestrictionStatus(
    int restrictionId,
    String statusCode,
  ) async {
    await _runGuarded(() async {
      final data = await _repository.updateRestrictionStatus(
        restrictionId: restrictionId,
        statusCode: statusCode,
      );
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

  Future<String?> createRestrictionFront({
    required int projectId,
    required String name,
  }) async {
    String? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createRestrictionFront(
        projectId: projectId,
        name: name,
      );
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
      createdId = await _repository.createRestrictionPhase(
        projectId: projectId,
        frontId: frontId,
        name: name,
      );
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

  Future<void> saveMilestone(MilestoneDraft draft) async {
    await _runGuarded(() async {
      final data = await _repository.saveMilestone(draft);
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> saveMilestoneGeneral(MilestoneGeneralDraft draft) async {
    await _runGuarded(() async {
      final data = await _repository.saveMilestoneGeneral(draft);
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

  List<ModuleInsightRecord> insightsForModule(ModuleInsightModule module) {
    switch (module) {
      case ModuleInsightModule.restrictions:
        return restrictionInsights;
      case ModuleInsightModule.actaReuniones:
        return actaReunionesInsights;
    }
  }

  bool shouldShowInsights(ModuleInsightModule module) {
    final items = insightsForModule(module);
    if (items.isEmpty) return false;
    return items.any(
      (item) =>
          !item.isResolved &&
          (item.severity == ModuleInsightSeverity.warning ||
              item.severity == ModuleInsightSeverity.critical),
    );
  }

  Future<void> setModuleInsightResolved({
    required ModuleInsightModule module,
    required String insightKey,
    required bool resolved,
  }) async {
    final projectId = _currentProject?.id;
    if (projectId == null) return;
    await _runGuarded(() async {
      final data = await _repository.setModuleInsightResolved(
        projectId: projectId,
        module: module,
        insightKey: insightKey,
        resolved: resolved,
      );
      _apply(data);
      _initialized = true;
    });
  }

  Future<List<InsightRuleConfigRecord>> loadInsightRuleConfigs(
    ModuleInsightModule module,
  ) async {
    final userId = _user?.id;
    if (userId == null) return [];
    return _repository.loadInsightRuleConfigs(
      userId: userId,
      module: module,
    );
  }

  Future<void> saveInsightRuleConfig({
    required ModuleInsightModule module,
    required String ruleKey,
    required bool isEnabled,
    required Map<String, int> thresholds,
  }) async {
    final userId = _user?.id;
    if (userId == null) return;
    await _runGuarded(() async {
      await _repository.saveInsightRuleConfig(
        userId: userId,
        module: module,
        ruleKey: ruleKey,
        isEnabled: isEnabled,
        thresholds: thresholds,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
  }

  /// Saves all records in batch then does a single bootstrap.
  Future<void> saveInsightRuleConfigBatch(List<InsightRuleConfigRecord> records) async {
    final userId = _user?.id;
    if (userId == null || records.isEmpty) return;
    await _runGuarded(() async {
      await _repository.saveInsightRuleConfigBatch(
        userId: userId,
        records: records,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
  }

  Future<ActreuHubViewData> loadActreuHubView() {
    return _repository.loadActreuHubData();
  }

  Future<List<ActreuCategoryTreeItem>> loadActreuCategoryTree() {
    return _repository.loadActreuCategoryTree();
  }

  Future<int?> createActreuCategory({
    required String name,
    int statusCode = 1,
  }) async {
    int? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createActreuCategory(
        name: name,
        statusCode: statusCode,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdId;
  }

  Future<int?> createActreuSubcategory({
    required int categoryId,
    required String name,
    int statusCode = 1,
  }) async {
    int? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createActreuSubcategory(
        categoryId: categoryId,
        name: name,
        statusCode: statusCode,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdId;
  }

  Future<bool> updateActreuCategoryName({
    required int categoryId,
    required String name,
  }) async {
    var updated = false;
    await _runGuarded(() async {
      updated = await _repository.updateActreuCategoryName(
        categoryId: categoryId,
        name: name,
      );
      if (updated) {
        final data = await _repository.bootstrap();
        _apply(data);
        _initialized = true;
      }
    });
    return updated;
  }

  Future<bool> updateActreuSubcategoryName({
    required int subcategoryId,
    required String name,
  }) async {
    var updated = false;
    await _runGuarded(() async {
      updated = await _repository.updateActreuSubcategoryName(
        subcategoryId: subcategoryId,
        name: name,
      );
      if (updated) {
        final data = await _repository.bootstrap();
        _apply(data);
        _initialized = true;
      }
    });
    return updated;
  }

  Future<bool> deleteActreuCategory(int categoryId) async {
    var deleted = false;
    await _runGuarded(() async {
      deleted = await _repository.deleteActreuCategory(categoryId);
      if (deleted) {
        final data = await _repository.bootstrap();
        _apply(data);
        _initialized = true;
      }
    });
    return deleted;
  }

  Future<bool> deleteActreuSubcategory(int subcategoryId) async {
    var deleted = false;
    await _runGuarded(() async {
      deleted = await _repository.deleteActreuSubcategory(subcategoryId);
      if (deleted) {
        final data = await _repository.bootstrap();
        _apply(data);
        _initialized = true;
      }
    });
    return deleted;
  }

  Future<ActreuSubcategoryViewData?> loadActreuSubcategoryView(
    int subcategoryId,
  ) {
    return _repository.loadActreuSubcategoryView(subcategoryId);
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  loadActreuParticipantRecommendations(int subcategoryId) {
    return _repository.loadActreuParticipantRecommendations(subcategoryId);
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  loadActreuParticipantRecommendationsForProject() {
    return _repository.loadActreuParticipantRecommendationsForProject();
  }

  Future<List<ActreuSubcategoryRecommendationItem>>
  loadActreuOtherProjectParticipantRecommendations({int? subcategoryId}) {
    return _repository.loadActreuOtherProjectParticipantRecommendations(
      subcategoryId: subcategoryId,
    );
  }

  Future<ActreuSessionViewData?> loadActreuSessionView({
    required int subcategoryId,
    int? sessionId,
  }) {
    return _repository.loadActreuSessionView(
      subcategoryId: subcategoryId,
      sessionId: sessionId,
    );
  }

  Future<bool> hasActreuParticipantsConfigured(int subcategoryId) {
    return _repository.hasActreuParticipantsConfigured(subcategoryId);
  }

  Future<int?> createActreuParticipant({
    required int subcategoryId,
    required String name,
    String? area,
    int? projectMemberId,
  }) async {
    int? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createActreuParticipant(
        subcategoryId: subcategoryId,
        name: name,
        area: area,
        projectMemberId: projectMemberId,
      );
    });
    return createdId;
  }

  Future<int?> createActreuSessionNow({
    required int subcategoryId,
    required DateTime sessionDate,
    required String sessionStartTime,
  }) async {
    int? createdSessionId;
    await _runGuarded(() async {
      createdSessionId = await _repository.createActreuSessionNow(
        subcategoryId: subcategoryId,
        sessionDate: sessionDate,
        sessionStartTime: sessionStartTime,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdSessionId;
  }

  Future<int> scheduleActreuSessions({
    required int subcategoryId,
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
    required String sessionStartTime,
    required Set<int> weekdays,
    int? monthlyDay,
  }) async {
    var createdCount = 0;
    await _runGuarded(() async {
      createdCount = await _repository.scheduleActreuSessions(
        subcategoryId: subcategoryId,
        startDate: startDate,
        endDate: endDate,
        frequency: frequency,
        sessionStartTime: sessionStartTime,
        weekdays: weekdays,
        monthlyDay: monthlyDay,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdCount;
  }

  Future<void> deleteActreuSession(int sessionId) async {
    await _runGuarded(() async {
      await _repository.deleteActreuSession(sessionId);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> deleteActreuParticipant(int participantId) async {
    await _runGuarded(() async {
      await _repository.deleteActreuParticipant(participantId);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
  }

  Future<List<ActreuAgreementCommentItem>> loadActreuAgreementComments(
    int agreementId,
  ) {
    return _repository.loadActreuAgreementComments(agreementId);
  }

  Future<int?> createActreuAgreementComment({
    required int agreementId,
    required String message,
    int? parentCommentId,
  }) async {
    int? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createActreuAgreementComment(
        agreementId: agreementId,
        message: message,
        parentCommentId: parentCommentId,
      );
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
    return createdId;
  }

  Future<List<ActreuOverdueAgreementItem>> loadActreuOverdueAgreements() {
    return _repository.loadActreuOverdueAgreements();
  }

  Future<void> upsertActreuAttendance({
    required int sessionId,
    required int participantId,
    required bool present,
  }) async {
    await _runGuarded(() async {
      await _repository.upsertActreuAttendance(
        sessionId: sessionId,
        participantId: participantId,
        present: present,
      );
    });
    await _pushActreuChangesNow();
  }

  Future<int?> createActreuAgreement({
    required int subcategoryId,
    required int sessionId,
    required String description,
    required DateTime agreementDate,
    required bool isInformative,
    int? responsibleParticipantId,
    int? groupId,
    String? groupName,
  }) async {
    int? createdId;
    await _runGuarded(() async {
      createdId = await _repository.createActreuAgreement(
        subcategoryId: subcategoryId,
        sessionId: sessionId,
        description: description,
        agreementDate: agreementDate,
        isInformative: isInformative,
        responsibleParticipantId: responsibleParticipantId,
        groupId: groupId,
        groupName: groupName,
      );
    });
    await _pushActreuChangesNow();
    return createdId;
  }

  Future<void> updateActreuAgreementStatus({
    required int agreementId,
    required int statusCode,
  }) async {
    await _runGuarded(() async {
      await _repository.updateActreuAgreementStatus(
        agreementId: agreementId,
        statusCode: statusCode,
      );
    });
    await _pushActreuChangesNow();
  }

  Future<void> deferActreuAgreement({
    required int agreementId,
    required DateTime newDueDate,
  }) async {
    await _runGuarded(() async {
      await _repository.deferActreuAgreement(
        agreementId: agreementId,
        newDueDate: newDueDate,
      );
    });
    await _pushActreuChangesNow();
  }

  Future<void> updateActreuAgreement({
    required int agreementId,
    required String description,
    required DateTime dueDate,
    required int statusCode,
    int? responsibleParticipantId,
    int? groupId,
  }) async {
    await _runGuarded(() async {
      await _repository.updateActreuAgreement(
        agreementId: agreementId,
        description: description,
        dueDate: dueDate,
        statusCode: statusCode,
        responsibleParticipantId: responsibleParticipantId,
        groupId: groupId,
      );
    });
    await _pushActreuChangesNow();
  }

  Future<void> deleteActreuAgreement({
    required int agreementId,
    required int sessionId,
  }) async {
    await _runGuarded(() async {
      await _repository.deleteActreuAgreement(
        agreementId: agreementId,
        sessionId: sessionId,
      );
    });
    await _pushActreuChangesNow();
  }

  Future<void> closeActreuSession(int sessionId) async {
    await _runGuarded(() async {
      await _repository.closeActreuSession(sessionId);
    });
    await _pushActreuChangesNow();
  }

  Future<void> _pushActreuChangesNow() async {
    if (_error != null) return;
    await _tryPushSync(force: true);
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
      final data = await _repository.linkCurrentDevice(
        userId: _session?.userId,
      );
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
    // Manual sync button: siempre forzamos FULL.
    await _performFullSync(resetManualToggle: true);
  }

  void setSyncAllOnNextManual(bool enabled) {
    _syncAllOnNextManual = enabled;
    notifyListeners();
  }

  void _startConnectivityWatch() {
    _connectivitySubscription?.cancel();
    _lastConnectivityHasConnection = _preferences.hasNetwork;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      final regainedConnection =
          _lastConnectivityHasConnection == false && hasConnection;
      _lastConnectivityHasConnection = hasConnection;

      if (regainedConnection) {
        unawaited(
          _refreshAndRunSyncChecks(
            forcePushOnReconnect: SyncRules.pushOnReconnectEnabled,
            forceOperationalOnReconnect:
                SyncRules.operationalOnReconnectEnabled,
          ),
        );
      } else {
        unawaited(_refreshState());
      }
    });
  }

  void _startSyncLoops() {
    _pushLoopTimer?.cancel();
    _pushLoopTimer = Timer.periodic(SyncRules.pushLoopInterval, (_) {
      unawaited(_tryPushSync());
    });

    _operationalLoopTimer?.cancel();
    _operationalLoopTimer = Timer.periodic(SyncRules.operationalCheckInterval, (
      _,
    ) {
      debugPrint('[AppController][operational][tick]');
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

  Future<void> _refreshAndRunSyncChecks({
    bool forcePushOnReconnect = false,
    bool forceOperationalOnReconnect = false,
  }) async {
    await _refreshState();
    await _runAutomaticSyncChecks(
      forcePush: forcePushOnReconnect,
      forceOperational: forceOperationalOnReconnect,
    );
  }

  Future<void> _runAutomaticSyncChecks({
    bool forcePush = false,
    bool forceOperational = false,
  }) async {
    if (!_initialized || !hasActiveSession) return;

    // En reconexion (forceOperational), priorizamos operational y evitamos
    // disparar full automaticamente.
    if (!forceOperational) {
      final fullSyncRan = await _tryDailyFullSyncIfNeeded();
      if (fullSyncRan) return;
    }

    await _tryPushSync(force: forcePush);
    if (forceOperational) {
      await _tryOperationalSyncNow();
    } else {
      await _tryOperationalSyncIfNeeded();
    }
  }

  Future<bool> _tryDailyFullSyncIfNeeded() async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) return false;
    if (!_preferences.remoteSyncEnabled ||
        _preferences.isOfflineEffective ||
        !_preferences.apiConfigured)
      return false;
    if (!_repository.shouldRunDailyFullSync(_preferences)) return false;

    await _performFullSync(markDailyFullSync: true);
    return true;
  }

  Future<void> _tryOperationalSyncIfNeeded() async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) {
      debugPrint(
        '[AppController][operational][skip] '
        'initialized=$_initialized busy=$_busy syncing=$_syncing hasSession=$hasActiveSession',
      );
      return;
    }
    if (!_preferences.remoteSyncEnabled ||
        _preferences.isOfflineEffective ||
        !_preferences.apiConfigured) {
      debugPrint(
        '[AppController][operational][skip] '
        'remoteSyncEnabled=${_preferences.remoteSyncEnabled} '
        'offlineEffective=${_preferences.isOfflineEffective} '
        'apiConfigured=${_preferences.apiConfigured}',
      );
      return;
    }
    final shouldRun = _repository.shouldRunOperationalSync(_preferences);
    if (!shouldRun) {
      debugPrint(
        '[AppController][operational][skip] '
        'rule=false lastSyncAt=${_preferences.lastSyncAt?.toIso8601String()}',
      );
      return;
    }

    debugPrint('[AppController][operational][run] starting sync');
    await _performOperationalSync();
  }

  Future<void> _tryOperationalSyncNow() async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) return;
    if (!_preferences.remoteSyncEnabled ||
        _preferences.isOfflineEffective ||
        !_preferences.apiConfigured) {
      return;
    }
    // Reconexion: forzamos un intento inmediato sin esperar el intervalo
    // minimo. Mantenemos la validacion de ventana horaria operacional.
    if (SyncRules.reconnectOperationalRespectsWindow) {
      final now = DateTime.now();
      if (now.hour < SyncRules.syncWindowStartHour ||
          now.hour >= SyncRules.syncWindowEndHour) {
        return;
      }
    }
    await _performOperationalSync();
  }

  Future<void> _tryPushSync({bool force = false}) async {
    if (!_initialized || _busy || _syncing || !hasActiveSession) return;
    if (!_preferences.remoteSyncEnabled ||
        _preferences.isOfflineEffective ||
        !_preferences.apiConfigured)
      return;
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
      final data = await _repository.syncFullData(
        markDailyFullSync: markDailyFullSync,
      );
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
    List<SyncChangeEvent> events = const [];
    await _runGuarded(() async {
      final data = await _repository.syncOperationalData();
      events = data.syncChangeEvents ?? const [];
      _apply(data);
      _initialized = true;
    });
    if (resetManualToggle) _syncAllOnNextManual = false;
    _syncing = false;
    notifyListeners();
    await _processNotifications(events);
  }

  Future<void> _processNotifications(List<SyncChangeEvent> events) async {
    if (events.isEmpty) return;
    if (!_preferences.notificationsEnabled) return;
    for (final e in events) {
      final moduleEnabled = e.module == 'restrictions'
          ? _preferences.notificationsRestrictionsEnabled
          : _preferences.notificationsActreuEnabled;
      if (!moduleEnabled) continue;
      await NotificationService.instance.showAlert(
        title: e.description,
        body: '${e.oldStatus} → ${e.newStatus}',
      );
    }
  }

  Future<void> saveNotificationPref(String key, bool enabled) async {
    await _runGuarded(() async {
      await _repository.saveNotificationPref(key, enabled);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> saveIndicatorsEnabled(bool enabled) async {
    await _runGuarded(() async {
      await _repository.saveIndicatorsEnabled(enabled);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
  }

  Future<void> saveIndicatorsModulePref(String key, bool enabled) async {
    await _runGuarded(() async {
      await _repository.saveIndicatorsModulePref(key, enabled);
      final data = await _repository.bootstrap();
      _apply(data);
      _initialized = true;
    });
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
      unawaited(
        _refreshLocationGuidance(
          showPrompt: hasActiveSession,
          forcePrompt: true,
        ),
      );
      // Al volver de pantalla apagada/resume solo refrescamos estado.
      // La sincronizacion automatica se dispara en timer o reconexion real.
      unawaited(_refreshState());
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
    _hubStyle = data.user?.hubStyle;
    _projects = data.projects;
    _currentProject = data.currentProject;
    _snapshot = data.snapshot;
    _preferences = data.preferences;
    _syncQueue = data.syncQueue;
    _syncOverview = data.syncOverview;
    _indicatorPrefs = data.indicatorPrefs ?? const [];
  }

  Future<void> saveIndicatorPref(HubIndicatorPref pref) async {
    await _runGuarded(() async {
      await _repository.saveIndicatorPref(pref);
      final idx = _indicatorPrefs.indexWhere((p) => p.key == pref.key);
      if (idx >= 0) {
        final updated = List<HubIndicatorPref>.of(_indicatorPrefs);
        updated[idx] = pref;
        _indicatorPrefs = updated;
      } else {
        _indicatorPrefs = [..._indicatorPrefs, pref];
      }
    });
  }

  Future<void> saveHubStyle(String? style) async {
    final userId = _user?.id;
    if (userId == null) return;
    await _repository.saveHubStyle(userId, style);
    _hubStyle = style;
    notifyListeners();
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
      final raw = error.toString();
      _error = raw.startsWith('Exception: ') ? raw.substring('Exception: '.length) : raw;
      debugPrint('[AppController] guarded action failed: $error');
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[AppController] stack trace',
      );
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
