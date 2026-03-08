import 'package:flutter/foundation.dart';

import '../../data/app_repository.dart';
import '../../data/models/app_models.dart';

class AppController extends ChangeNotifier {
  AppController({AppRepository? repository}) : _repository = repository ?? AppRepository();

  final AppRepository _repository;

  bool _initialized = false;
  bool _busy = false;
  String? _error;
  Future<void>? _initializingFuture;
  UserSession? _session;
  UserProfile? _user;
  List<ProjectRecord> _projects = const [];
  ProjectRecord? _currentProject;
  ProjectSnapshot? _snapshot;

  bool get isInitialized => _initialized;
  bool get isBusy => _busy;
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

