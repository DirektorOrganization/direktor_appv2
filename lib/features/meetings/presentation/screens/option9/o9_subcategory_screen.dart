import 'package:flutter/material.dart';
import '../../../../../../app/state/app_scope.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o9_session_screen.dart';
import 'o9_comments_screen.dart';
import 'o9_agreement_detail_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Subcategory Screen
// ─────────────────────────────────────────────

class _O9Agreement {
  _O9Agreement({
    required this.id,
    required this.description,
    required this.responsible,
    required this.dueDate,
    required this.status,
    required this.groupId,
    required this.group,
    required this.groupColor,
    required this.meetingDate,
    required this.comments,
    required this.deferrals,
    this.lockedByActiveSession = false,
  });
  final int id;
  final String description;
  final String responsible;
  final String dueDate;
  String status;
  int? groupId;
  String group;
  Color groupColor;
  final String meetingDate;
  final int comments;
  final int deferrals;
  final bool lockedByActiveSession;
}

class _O9Session {
  _O9Session({
    required this.sessionId,
    required this.num,
    required this.date,
    required this.status,
    required this.attended,
    required this.total,
    required this.agreements,
    required this.overdue,
  });
  final int? sessionId;
  final String num;
  String date;
  String status;
  final int attended;
  final int total;
  final int agreements;
  final int overdue;
}

class _O9Participant {
  _O9Participant({
    required this.id,
    required this.name,
    required this.area,
    required this.present,
    required this.role,
    this.projectMemberId,
  });
  final int id;
  String name;
  String area;
  bool present;
  final String role;
  final int? projectMemberId;
}

class _O9GroupOption {
  const _O9GroupOption({
    required this.id,
    required this.name,
    required this.color,
  });

  final int id;
  final String name;
  final Color color;
}

final _o9Agreements = <_O9Agreement>[
  _O9Agreement(
    id: 1,
    description: 'Revisar cronograma de concreto nivel 3',
    responsible: 'C. Mendoza',
    dueDate: '25/03/2026',
    status: 'pending',
    groupId: 1,
    group: 'Estructura',
    groupColor: const Color(0xFF0A66B7),
    meetingDate: '18/03/2026',
    comments: 2,
    deferrals: 1,
  ),
  _O9Agreement(
    id: 2,
    description: 'Entregar EPPs completos a cuadrilla de fierreros',
    responsible: 'L. Torres',
    dueDate: '20/03/2026',
    status: 'overdue',
    groupId: 2,
    group: 'SST',
    groupColor: const Color(0xFF1B8E5A),
    meetingDate: '11/03/2026',
    comments: 5,
    deferrals: 0,
  ),
  _O9Agreement(
    id: 3,
    description: 'Solicitar segunda medición topográfica Eje B',
    responsible: 'R. Chavez',
    dueDate: '28/03/2026',
    status: 'completed',
    groupId: 3,
    group: 'Calidad',
    groupColor: const Color(0xFFE4A620),
    meetingDate: '18/03/2026',
    comments: 1,
    deferrals: 0,
  ),
  _O9Agreement(
    id: 4,
    description: 'Coordinar llegada acero con Siderperú',
    responsible: 'P. Quispe',
    dueDate: '22/03/2026',
    status: 'overdue',
    groupId: 4,
    group: 'Logística',
    groupColor: const Color(0xFFD64545),
    meetingDate: '11/03/2026',
    comments: 3,
    deferrals: 2,
  ),
  _O9Agreement(
    id: 5,
    description: 'Actualizar planos As-built de muro perimetral',
    responsible: 'A. Flores',
    dueDate: '30/03/2026',
    status: 'pending',
    groupId: 3,
    group: 'Calidad',
    groupColor: const Color(0xFFE4A620),
    meetingDate: '18/03/2026',
    comments: 0,
    deferrals: 0,
  ),
  _O9Agreement(
    id: 6,
    description: 'Renovar póliza de seguro del proyecto',
    responsible: 'M. Rodriguez',
    dueDate: '15/03/2026',
    status: 'overdue',
    groupId: 5,
    group: 'Gerencia',
    groupColor: const Color(0xFF7C3AED),
    meetingDate: '05/03/2026',
    comments: 2,
    deferrals: 1,
  ),
];

final _o9Sessions = [
  _O9Session(
    sessionId: 19,
    num: '#19',
    date: '25/03/2026',
    status: 'programmed',
    attended: 0,
    total: 12,
    agreements: 0,
    overdue: 0,
  ),
  _O9Session(
    sessionId: 18,
    num: '#18',
    date: '18/03/2026',
    status: 'closed',
    attended: 10,
    total: 12,
    agreements: 4,
    overdue: 2,
  ),
  _O9Session(
    sessionId: 17,
    num: '#17',
    date: '11/03/2026',
    status: 'closed',
    attended: 11,
    total: 12,
    agreements: 3,
    overdue: 1,
  ),
  _O9Session(
    sessionId: 16,
    num: '#16',
    date: '04/03/2026',
    status: 'closed',
    attended: 9,
    total: 12,
    agreements: 6,
    overdue: 3,
  ),
];

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────

class O9SubcategoryScreen extends StatefulWidget {
  const O9SubcategoryScreen({
    super.key,
    this.subcategoryId,
    this.subcategoryName = 'Comité Semanal de Obra',
    this.categoryName = 'Reuniones de Obra',
    this.categoryColor = const Color(0xFF0A66B7),
  });
  final int? subcategoryId;
  final String subcategoryName;
  final String categoryName;
  final Color categoryColor;
  @override
  State<O9SubcategoryScreen> createState() => _O9SubcategoryScreenState();
}

class _O9SubcategoryScreenState extends State<O9SubcategoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _participantsTabKey = GlobalKey<_ParticipantsTabState>();
  late final List<_O9Agreement> _ag;
  late final List<_O9Session> _sessions;
  late final List<_O9Participant> _participants;
  List<_O9GroupOption> _groupOptions = const [];
  List<Map<String, String>> _availableRecommendations = const [];
  List<Map<String, String>> _otherProjectRecommendations = const [];
  bool _loading = true;
  bool _loaded = false;
  String _agFilter = 'Todos';
  bool _analysisExpanded = false;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_handleTabChanged);
    _ag = List.from(_o9Agreements);
    _sessions = List.from(_o9Sessions);
    _participants = [
      _O9Participant(
        id: 1,
        name: 'Carlos Mendoza',
        area: 'Ingeniería',
        present: true,
        role: 'Residente de obra',
      ),
      _O9Participant(
        id: 2,
        name: 'Lucia Torres',
        area: 'SST',
        present: true,
        role: 'Jefa de SST',
      ),
      _O9Participant(
        id: 3,
        name: 'Roberto Chavez',
        area: 'Calidad',
        present: true,
        role: 'Jefe de Calidad',
      ),
      _O9Participant(
        id: 4,
        name: 'Ana Flores',
        area: 'Supervisión',
        present: false,
        role: 'Supervisora Técnica',
      ),
      _O9Participant(
        id: 5,
        name: 'Pedro Quispe',
        area: 'Logística',
        present: true,
        role: 'Jefe de Procura',
      ),
      _O9Participant(
        id: 6,
        name: 'Marco Rivera',
        area: 'Contratista',
        present: false,
        role: 'Representante',
      ),
      _O9Participant(
        id: 7,
        name: 'Maria Gutierrez',
        area: 'Gerencia',
        present: true,
        role: 'Coordinadora General',
      ),
      _O9Participant(
        id: 8,
        name: 'Luis Saenz',
        area: 'Finanzas',
        present: true,
        role: 'Analista Financiero',
      ),
    ];
    _groupOptions = _ag
        .map(
          (item) => _O9GroupOption(
            id: item.groupId ?? item.id,
            name: item.group,
            color: item.groupColor,
          ),
        )
        .toList();
  }

  void _handleTabChanged() {
    final hasOperationalData =
        _sessions.isNotEmpty || _ag.where((a) => a.status != 'info').isNotEmpty;
    final seguimientoTabIndex = hasOperationalData ? 0 : 2;
    if (_tabs.indexIsChanging) return;
    if (_tabs.index != seguimientoTabIndex &&
        (_isSearching || _searchQuery.isNotEmpty)) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadData();
  }

  Future<void> _loadData() async {
    final subcategoryId = widget.subcategoryId;
    if (subcategoryId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final controller = AppScope.of(context);
    final data = await controller.loadActreuSubcategoryView(subcategoryId);
    if (!mounted) return;
    if (data == null) {
      setState(() => _loading = false);
      return;
    }
    final mappedAgreements = data.agreements
        .map(
          (item) => _O9Agreement(
            id: item.agreementId,
            description: item.description,
            responsible: item.responsible,
            dueDate: _formatDate(item.dueDate),
            status: _statusFromCode(item.statusCode),
            groupId: item.groupId,
            group: item.group,
            groupColor: _groupDisplayColorFromHex(item.groupColorHex),
            meetingDate: item.sessionLabel,
            comments: item.commentsCount,
            deferrals: item.deferralsCount,
            lockedByActiveSession: item.lockedByActiveSession,
          ),
        )
        .toList();
    final mappedSessions = data.sessions
        .map(
          (item) => _O9Session(
            sessionId: item.sessionId,
            num: '#${item.sessionId}',
            date: _formatDate(item.date),
            status: item.statusCode == 2 ? 'closed' : 'programmed',
            attended: item.attendedCount,
            total: item.totalCount,
            agreements: item.agreementsCount,
            overdue: item.overdueCount,
          ),
        )
        .toList();
    final mappedParticipants = data.participants
        .map(
          (item) => _O9Participant(
            id: item.participantId,
            name: item.name,
            area: item.area,
            present: true,
            role: item.role,
            projectMemberId: item.projectMemberId,
          ),
        )
        .toList();
    final mappedRecommendations = data.recommendations
        .map(
          (item) => {
            'name': item.label,
            'area': 'Integrante',
            'memberId': '${item.projectMemberId}',
          },
        )
        .toList();
    final mappedGroupOptions = data.groupOptions
        .map(
          (item) => _O9GroupOption(
            id: item.groupId,
            name: item.groupName,
            color: _groupDisplayColorFromHex(item.groupColorHex),
          ),
        )
        .toList();
    setState(() {
      _ag
        ..clear()
        ..addAll(mappedAgreements);
      _sessions
        ..clear()
        ..addAll(mappedSessions);
      _participants
        ..clear()
        ..addAll(mappedParticipants);
      _groupOptions = mappedGroupOptions;
      _availableRecommendations = mappedRecommendations;
      _loading = false;
    });
  }

  Future<void> _persistAgreementStatus(int agreementId, String statusKey) async {
    final statusCode = _statusCodeFromKey(statusKey);
    if (statusCode == null) return;
    final index = _ag.indexWhere((item) => item.id == agreementId);
    if (index < 0) return;
    final current = _ag[index];
    if (current.status == 'info' || current.status == statusKey) return;
    final previousStatus = current.status;
    setState(() => current.status = statusKey);
    try {
      await AppScope.of(context).updateActreuAgreementStatus(
        agreementId: agreementId,
        statusCode: statusCode,
      );
      if (!mounted) return;
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      setState(() => current.status = previousStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el estado del acuerdo.')),
      );
    }
  }

  Future<void> _quickDeferAgreement(_O9Agreement agreement) async {
    if (agreement.status == 'info' || agreement.lockedByActiveSession) return;
    final parsedDue = _parseSessionDate(agreement.dueDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextFromDue = parsedDue == null
        ? today
        : DateTime(parsedDue.year, parsedDue.month, parsedDue.day + 1);
    final firstAllowed = nextFromDue.isAfter(today) ? nextFromDue : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: firstAllowed,
      firstDate: firstAllowed,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Nueva fecha límite',
      cancelText: 'Cancelar',
      confirmText: 'Aplazar',
    );
    if (picked == null) return;
    try {
      await AppScope.of(context).deferActreuAgreement(
        agreementId: agreement.id,
        newDueDate: picked,
      );
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acuerdo aplazado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  List<_O9Agreement> get _filtered {
    final trackable = _ag.where((a) => a.status != 'info');
    switch (_agFilter) {
      case 'Vencidos':
        return trackable.where((a) => a.status == 'overdue').toList();
      case 'Pendientes':
        return trackable
            .where((a) => a.status == 'in_progress' || a.status == 'pending')
            .toList();
      case 'Completados':
        return trackable.where((a) => a.status == 'completed').toList();
      default:
        return trackable.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    final pendingCount = _ag
        .where((a) => a.status != 'completed' && a.status != 'info')
        .length;
    final hasOperationalData =
        _sessions.isNotEmpty || _ag.where((a) => a.status != 'info').isNotEmpty;
    final isOnboardingOrder = !hasOperationalData;
    final seguimientoTabIndex = isOnboardingOrder ? 2 : 0;

    final seguimientoTab = _SeguimientoTab(
      ag: _filtered,
      allAg: _ag.where((a) => a.status != 'info').toList(),
      groupOptions: _groupOptions,
      participants: _participants,
      filter: _agFilter,
      searchQuery: _searchQuery,
      onFilter: (f) => setState(() => _agFilter = f),
      onStatusChange: (id, s) {
        _persistAgreementStatus(id, s);
      },
      onQuickDefer: _quickDeferAgreement,
      onReloadRequested: _loadData,
      analysisExpanded: _analysisExpanded,
      onToggleAnalysis: () => setState(() => _analysisExpanded = !_analysisExpanded),
    );

    final sessionsTab = _SessionsTab(
      sessions: _sessions,
      subcategoryId: widget.subcategoryId,
      hasParticipants: _participants.isNotEmpty,
      onRefreshRequested: _loadData,
      onParticipantsRequired: _redirectToParticipantsWithPrompt,
    );

    final participantsTab = _ParticipantsTab(
      key: _participantsTabKey,
      participants: _participants,
      available: _availableRecommendations,
      otherProjectAvailable: _otherProjectRecommendations,
      onRequestAvailable: () => _loadRecommendationsOnDemand(),
      onRequestOtherProjectAvailable: () =>
          _loadOtherProjectRecommendationsOnDemand(),
      onAdd: (name, area, projectMemberId) async {
        final subcategoryId = widget.subcategoryId;
        var participantId = DateTime.now().millisecondsSinceEpoch;
        if (subcategoryId != null) {
          final createdId = await AppScope.of(context).createActreuParticipant(
            subcategoryId: subcategoryId,
            name: name,
            area: area,
            projectMemberId: projectMemberId,
          );
          if (createdId == null) return;
          participantId = createdId;
        }
        if (!mounted) return;
        setState(
          () => _participants.add(
            _O9Participant(
              id: participantId,
              name: name,
              area: area,
              present: true,
              role: 'Invitado',
              projectMemberId: projectMemberId,
            ),
          ),
        );
      },
      onDelete: (participantId) async {
        await AppScope.of(context).deleteActreuParticipant(participantId);
        if (!mounted) return false;
        final error = AppScope.of(context).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.replaceFirst('Exception: ', ''))),
          );
          return false;
        }
        await _loadData();
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participante eliminado.')),
        );
        return true;
      },
    );

    final tabs = isOnboardingOrder
        ? <Widget>[
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  SizedBox(width: 4),
                  Icon(Icons.people_rounded, size: 14),
                  SizedBox(width: 3),
                  Text('Participan.', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  SizedBox(width: 4),
                  Icon(Icons.event_note_rounded, size: 14),
                  SizedBox(width: 3),
                  Text('Sesiones', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  const Icon(Icons.track_changes_rounded, size: 14),
                  const SizedBox(width: 3),
                  Badge(
                    label: Text(
                      '$pendingCount',
                      style: const TextStyle(fontSize: 8),
                    ),
                    child: const Text(
                      'Seguimiento',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ]
        : <Widget>[
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.track_changes_rounded, size: 14),
                  const SizedBox(width: 3),
                  Badge(
                    label: Text(
                      '$pendingCount',
                      style: const TextStyle(fontSize: 8),
                    ),
                    child: const Text(
                      'Seguimiento',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_rounded, size: 14),
                  SizedBox(width: 3),
                  Text('Sesiones', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_rounded, size: 14),
                  SizedBox(width: 3),
                  Text('Participan.', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ];

    final tabViews = isOnboardingOrder
        ? <Widget>[participantsTab, sessionsTab, seguimientoTab]
        : <Widget>[seguimientoTab, sessionsTab, participantsTab];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: (_isSearching && _tabs.index == seguimientoTabIndex)
            ? Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.stroke.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar en seguimiento...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 13, color: AppTheme.muted),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subcategoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.categoryName,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.brandBlue,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: tabs,
        ),
        actions: [
          if (_tabs.index == seguimientoTabIndex)
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = '';
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          if (!_isSearching)
            FilledButton.icon(
              onPressed: _openSessionFromHeader,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Iniciar sesión'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: tabViews,
      ),
    );
  }

  Future<void> _openSessionFromHeader() async {
    final routedToExisting = await _openExistingSessionFromHeader();
    if (routedToExisting) {
      return;
    }
    if (_participants.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero agrega participantes en esta subcategoría para ingresar a sesiones.',
          ),
        ),
      );
      return;
    }
    final activeSession = _sessions.where((item) {
      if (item.status != 'programmed' || item.sessionId == null) return false;
      final date = _parseSessionDate(item.date);
      if (date == null) return false;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return !date.isAfter(today);
    }).toList()
      ..sort((a, b) {
        final dateA =
            _parseSessionDate(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            _parseSessionDate(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });

    if (activeSession.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => O9SessionScreen(
            subcategoryId: widget.subcategoryId,
            sessionId: activeSession.last.sessionId,
          ),
        ),
      );
      if (!mounted) return;
      await _loadData();
      return;
    }

    _showCreateSessionNowFromHeader();
  }

  Future<bool> _openExistingSessionFromHeader() async {
    final programmedSessions = _sessions.where((item) {
      if (item.status != 'programmed' || item.sessionId == null) return false;
      return _parseSessionDate(item.date) != null;
    }).toList()
      ..sort((a, b) {
        final dateA =
            _parseSessionDate(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            _parseSessionDate(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });
    if (programmedSessions.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeSession = programmedSessions.where((item) {
      final date = _parseSessionDate(item.date);
      if (date == null) return false;
      return !date.isAfter(today);
    }).toList();
    if (activeSession.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => O9SessionScreen(
            subcategoryId: widget.subcategoryId,
            sessionId: activeSession.last.sessionId,
          ),
        ),
      );
      if (!mounted) return true;
      await _loadData();
      return true;
    }

    final upcomingProgrammed = programmedSessions.where((item) {
      final date = _parseSessionDate(item.date);
      if (date == null) return false;
      return date.isAfter(today);
    }).toList();
    if (upcomingProgrammed.isNotEmpty) {
      final nextProgrammed = upcomingProgrammed.first;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => O9SessionScreen(
            subcategoryId: widget.subcategoryId,
            sessionId: nextProgrammed.sessionId,
          ),
        ),
      );
      if (!mounted) return true;
      await _loadData();
      return true;
    }
    return false;
  }

  void _redirectToParticipantsWithPrompt() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Primero agrega participantes en esta subcategoría para ingresar a sesiones.',
        ),
      ),
    );
    _tabs.animateTo(2);
    Future.delayed(const Duration(milliseconds: 180), () async {
      if (!mounted) return;
      await _participantsTabKey.currentState?.showAddModal();
    });
  }

  DateTime? _parseSessionDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  void _showCreateSessionNowFromHeader() {
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    TimeOfDay selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    bool creating = false;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Iniciar sesión ahora',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Confirma la fecha para crear la sesión no programada.',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: creating
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModal(
                            () => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            ),
                          );
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.stroke.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: ${_formatDate(selectedDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_rounded, size: 14, color: AppTheme.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: creating
                    ? null
                    : () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModal(() => selectedTime = picked);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.stroke.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Hora: ${_formatTimeOfDay(selectedTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_rounded, size: 14, color: AppTheme.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: creating
                      ? null
                      : () async {
                          final subcategoryId = widget.subcategoryId;
                          if (subcategoryId == null) return;
                          setModal(() => creating = true);
                          final createdId = await AppScope.of(
                            context,
                          ).createActreuSessionNow(
                            subcategoryId: subcategoryId,
                            sessionDate: selectedDate,
                            sessionStartTime: _formatTimeOfDay(selectedTime),
                          );
                          if (!mounted) return;
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (createdId == null) {
                            await _loadData();
                            return;
                          }
                          await _loadData();
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => O9SessionScreen(
                                subcategoryId: subcategoryId,
                                sessionId: createdId,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          await _loadData();
                        },
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: Text(
                    creating ? 'Creando...' : 'Iniciar sesión',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> _loadRecommendationsOnDemand() async {
    final subcategoryId = widget.subcategoryId;
    final app = AppScope.of(context);
    final items = subcategoryId == null
        ? await app.loadActreuParticipantRecommendationsForProject()
        : await app.loadActreuParticipantRecommendations(subcategoryId);
    final mapped = items
        .map(
          (item) => {
            'name': item.label,
            'area': 'Integrante',
            'memberId': '${item.projectMemberId}',
          },
        )
        .toList();
    if (mounted) {
      setState(() => _availableRecommendations = mapped);
    }
    return mapped;
  }

  Future<List<Map<String, String>>>
  _loadOtherProjectRecommendationsOnDemand() async {
    final app = AppScope.of(context);
    final items = await app.loadActreuOtherProjectParticipantRecommendations(
      subcategoryId: widget.subcategoryId,
    );
    final mapped = items
        .map(
          (item) => {
            'name': item.label,
            'area': 'Integrante proyecto',
            'memberId': '${item.projectMemberId}',
          },
        )
        .toList();
    if (mounted) {
      setState(() => _otherProjectRecommendations = mapped);
    }
    return mapped;
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatTimeOfDay(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _statusFromCode(int code) {
  switch (code) {
    case 1:
    case 2:
      return 'in_progress';
    case 3:
      return 'completed';
    case 4:
    case 5:
      return 'overdue';
    case 6:
      return 'info';
    default:
      return 'in_progress';
  }
}

int? _statusCodeFromKey(String key) {
  switch (key) {
    case 'in_progress':
      return 1;
    case 'completed':
      return 3;
    default:
      return null;
  }
}

Color? _parseColor(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final hex = value.replaceAll('#', '').trim();
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  if (normalized.length != 8) return null;
  return Color(int.parse(normalized, radix: 16));
}

Color _groupDisplayColorFromHex(String? value) {
  final parsed = _parseColor(value);
  return parsed ?? const Color(0xFF0A66B7);
}

Color _groupTextColor(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.62 ? const Color(0xFF1F2937) : Colors.white;
}

Border? _groupChipBorder(Color background) {
  if (background.computeLuminance() <= 0.62) return null;
  return Border.all(color: const Color(0x33000000));
}

// ─────────────────────────────────────────────
// TAB: SEGUIMIENTO (antes: Acuerdos)
// ─────────────────────────────────────────────

class _SeguimientoTab extends StatelessWidget {
  const _SeguimientoTab({
    required this.ag,
    required this.allAg,
    required this.groupOptions,
    required this.participants,
    required this.filter,
    required this.searchQuery,
    required this.onFilter,
    required this.onStatusChange,
    required this.onQuickDefer,
    required this.onReloadRequested,
    required this.analysisExpanded,
    required this.onToggleAnalysis,
  });
  final List<_O9Agreement> ag;
  final List<_O9Agreement> allAg;
  final List<_O9GroupOption> groupOptions;
  final List<_O9Participant> participants;
  final String filter;
  final String searchQuery;
  final ValueChanged<String> onFilter;
  final Function(int, String) onStatusChange;
  final Future<void> Function(_O9Agreement agreement) onQuickDefer;
  final Future<void> Function() onReloadRequested;
  final bool analysisExpanded;
  final VoidCallback onToggleAnalysis;

  static const _filters = ['Todos', 'Vencidos', 'Pendientes', 'Completados'];

  @override
  Widget build(BuildContext context) {
    List<_O9Agreement> displayAg = ag;
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      displayAg = displayAg
          .where(
            (a) =>
                a.description.toLowerCase().contains(q) ||
                a.responsible.toLowerCase().contains(q) ||
                a.group.toLowerCase().contains(q),
          )
          .toList();
    }

    return Column(
      children: [
        _AnalysisBanner(
          ag: allAg,
          expanded: analysisExpanded,
          onToggle: onToggleAnalysis,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final sel = f == filter;
                return ChoiceChip(
                  selected: sel,
                  label: Text(f),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppTheme.muted,
                  ),
                  selectedColor: AppTheme.brandBlue,
                  backgroundColor: AppTheme.stroke.withOpacity(0.40),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                  onSelected: (_) => onFilter(f),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: displayAg.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 48,
                        color: Color(0xFF1B8E5A),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin acuerdos en este estado',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: displayAg.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _O9AgreementCard(
                    agreement: displayAg[i],
                    onStatusChange: onStatusChange,
                    onQuickDefer: onQuickDefer,
                    onReloadRequested: onReloadRequested,
                    groupOptions: groupOptions,
                    responsibleOptions: participants
                        .map((p) => p.name)
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Banner de Análisis con grupos ──
class _AnalysisBanner extends StatelessWidget {
  const _AnalysisBanner({
    required this.ag,
    required this.expanded,
    required this.onToggle,
  });
  final List<_O9Agreement> ag;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final completed = ag.where((a) => a.status == 'completed').length;
    final overdue = ag.where((a) => a.status == 'overdue').length;
    final pending = ag.where((a) => a.status == 'pending').length;
    final total = ag.length;
    final pct = total > 0 ? completed / total : 0.0;

    final Map<String, List<_O9Agreement>> byGroup = {};
    for (final a in ag) {
      byGroup.putIfAbsent(a.group, () => []).add(a);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppTheme.brandBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Análisis',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      color: AppTheme.brandBlue,
                    ),
                  ),
                  const Spacer(),
                  if (!expanded)
                    Row(
                      children: [
                        _MiniStat(
                          value: '${(pct * 100).round()}%',
                          color: const Color(0xFF1B8E5A),
                        ),
                        const SizedBox(width: 6),
                        _MiniStat(
                          value: '$overdue venc.',
                          color: const Color(0xFFD64545),
                        ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: AppTheme.brandBlue.withOpacity(0.12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats generales
                  Row(
                    children: [
                      _AnalysisStat(
                        value: '${(pct * 100).round()}%',
                        label: 'Cumplim.',
                        color: const Color(0xFF1B8E5A),
                      ),
                      const SizedBox(width: 14),
                      _AnalysisStat(
                        value: '$completed',
                        label: 'OK',
                        color: const Color(0xFF1B8E5A),
                      ),
                      const SizedBox(width: 14),
                      _AnalysisStat(
                        value: '$pending',
                        label: 'Pend.',
                        color: const Color(0xFFE4A620),
                      ),
                      const SizedBox(width: 14),
                      _AnalysisStat(
                        value: '$overdue',
                        label: 'Venc.',
                        color: const Color(0xFFD64545),
                      ),
                      const SizedBox(width: 14),
                      _AnalysisStat(
                        value: '$total',
                        label: 'Total',
                        color: AppTheme.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor: AppTheme.stroke,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF1B8E5A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Por grupo de acuerdo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Grupos al estilo Opción 8
                  ...byGroup.entries.map((e) {
                    final groupAg = e.value;
                    final g = groupAg.first;
                    final ok = groupAg
                        .where((a) => a.status == 'completed')
                        .length;
                    final ov = groupAg
                        .where((a) => a.status == 'overdue')
                        .length;
                    final pe = groupAg
                        .where((a) => a.status == 'pending')
                        .length;
                    final grPct = groupAg.isNotEmpty
                        ? ok / groupAg.length
                        : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(color: g.groupColor, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(grPct * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: grPct,
                              minHeight: 5,
                              backgroundColor: AppTheme.stroke,
                              valueColor: AlwaysStoppedAnimation(g.groupColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 11,
                                color: const Color(0xFF1B8E5A),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$ok',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF1B8E5A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: const Color(0xFFE4A620),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$pe',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFFE4A620),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 11,
                                color: const Color(0xFFD64545),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$ov',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFFD64545),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.color});
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      value,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _AnalysisStat extends StatelessWidget {
  const _AnalysisStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: AppTheme.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// ── Card de acuerdo enriquecida (Opción 7 style + acciones) ──
class _O9AgreementCard extends StatelessWidget {
  const _O9AgreementCard({
    required this.agreement,
    required this.onStatusChange,
    required this.onQuickDefer,
    required this.onReloadRequested,
    required this.groupOptions,
    required this.responsibleOptions,
  });
  final _O9Agreement agreement;
  final Function(int, String) onStatusChange;
  final Future<void> Function(_O9Agreement agreement) onQuickDefer;
  final Future<void> Function() onReloadRequested;
  final List<_O9GroupOption> groupOptions;
  final List<String> responsibleOptions;

  Color get _statusColor {
    switch (agreement.status) {
      case 'completed':
        return const Color(0xFF1B8E5A);
      case 'overdue':
        return const Color(0xFFD64545);
      case 'in_progress':
        return AppTheme.brandBlue;
      case 'info':
        return const Color(0xFF0A66B7);
      default:
        return const Color(0xFFE4A620);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final locked = agreement.lockedByActiveSession;

    return Container(
      decoration: BoxDecoration(
        color: locked ? surface.withOpacity(0.82) : surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locked
              ? AppTheme.stroke.withOpacity(0.8)
              : agreement.status == 'overdue'
              ? const Color(0xFFD64545).withOpacity(0.35)
              : AppTheme.stroke,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: agreement.status == 'info'
                            ? const Color(0xFF0A66B7).withOpacity(0.12)
                            : agreement.groupColor,
                        borderRadius: BorderRadius.circular(5),
                        border: agreement.status == 'info'
                            ? null
                            : _groupChipBorder(agreement.groupColor),
                      ),
                      child: Text(
                        agreement.group,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: agreement.status == 'info'
                              ? const Color(0xFF0A66B7)
                              : _groupTextColor(agreement.groupColor),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reunión: ${agreement.meetingDate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: AppTheme.muted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (locked) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.stroke.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'En sesión',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Dropdown de estado compacto
                    _StatusDropdown(
                      status: agreement.status,
                      statusColor: _statusColor,
                      onChanged: locked
                          ? null
                          : (v) {
                              if (v != null) onStatusChange(agreement.id, v);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  agreement.description,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 11,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      agreement.responsible,
                      style: TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.event_outlined, size: 11, color: AppTheme.muted),
                    const SizedBox(width: 3),
                    Text(
                      agreement.dueDate,
                      style: TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                    if (agreement.deferrals > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4A620).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFE4A620).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.redo_rounded,
                              size: 11,
                              color: Color(0xFFE4A620),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Aplz ${agreement.deferrals}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFE4A620),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Comentarios
                    _ActionBtn(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: agreement.comments > 0
                          ? '${agreement.comments} coment.'
                          : 'Comentar',
                      onTap: locked
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => O9CommentsScreen(
                                  agreementId: agreement.id,
                                  agreementTitle: agreement.description,
                                  agreementGroup: agreement.group,
                                  groupColor: agreement.groupColor,
                                ),
                              ),
                            ),
                    ),
                    // Ver detalle
                    _ActionBtn(
                      icon: Icons.open_in_new_rounded,
                      label: 'Ver detalle',
                      onTap: locked
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => O9AgreementDetailScreen(
                                    id: agreement.id,
                                    description: agreement.description,
                                    responsible: agreement.responsible,
                                    dueDate: agreement.dueDate,
                                    status: agreement.status,
                                    group: agreement.group,
                                    groupColor: agreement.groupColor,
                                    groupId: agreement.groupId,
                                    groupOptions: groupOptions
                                        .map(
                                          (item) => O9AgreementGroupOption(
                                            id: item.id,
                                            name: item.name,
                                            color: item.color,
                                          ),
                                        )
                                        .toList(),
                                    responsibleOptions: responsibleOptions,
                                    meetingDate: agreement.meetingDate,
                                    comments: agreement.comments,
                                    deferrals: agreement.deferrals,
                                    onStatusChange: onStatusChange,
                                    onGroupChange:
                                        (groupId, groupName, groupColor) {
                                          agreement.groupId = groupId;
                                          agreement.group = groupName;
                                          agreement.groupColor = groupColor;
                                          onStatusChange(
                                            agreement.id,
                                            agreement.status,
                                          );
                                        },
                                  ),
                                ),
                              );
                              if (!context.mounted) return;
                              await onReloadRequested();
                            },
                    ),
                    _ActionBtn(
                      icon: Icons.redo_rounded,
                      label: 'Aplazar',
                      onTap: locked ? null : () => onQuickDefer(agreement),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.status,
    required this.statusColor,
    required this.onChanged,
  });
  final String status;
  final Color statusColor;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 108),
    child: Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.30)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status == 'completed' ? 'completed' : 'in_progress',
          isDense: true,
          style: TextStyle(
            fontSize: 10,
            color: statusColor,
            fontWeight: FontWeight.w700,
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            size: 14,
            color: statusColor,
          ),
          items: const [
            DropdownMenuItem(
              value: 'in_progress',
              child: Text('En progreso', style: TextStyle(fontSize: 10)),
            ),
            DropdownMenuItem(
              value: 'completed',
              child: Text('Finalizado', style: TextStyle(fontSize: 10)),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.stroke.withOpacity(0.40),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// ─────────────────────────────────────────────
// TAB: SESIONES — scheduler + calendario
// ─────────────────────────────────────────────

class _SessionsTab extends StatefulWidget {
  const _SessionsTab({
    required this.sessions,
    required this.subcategoryId,
    required this.hasParticipants,
    required this.onRefreshRequested,
    required this.onParticipantsRequired,
  });
  final List<_O9Session> sessions;
  final int? subcategoryId;
  final bool hasParticipants;
  final Future<void> Function() onRefreshRequested;
  final VoidCallback onParticipantsRequired;
  @override
  State<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<_SessionsTab> {
  bool _pastExpanded = false;
  bool _upcomingExpanded = false;
  bool _calendarView = false;
  bool _creatingSessionNow = false;
  late DateTime _calMonth;

  @override
  void initState() {
    super.initState();
    _calMonth = DateTime(2026, 3);
  }

  Color _sc(String s) {
    switch (s) {
      case 'closed':
        return const Color(0xFF1B8E5A);
      case 'programmed':
        return AppTheme.brandBlue;
      default:
        return const Color(0xFFE4A620);
    }
  }

  String _sl(String s) {
    switch (s) {
      case 'closed':
        return 'Cerrada';
      case 'programmed':
        return 'Programada';
      default:
        return 'En curso';
    }
  }

  IconData _si(String s) {
    switch (s) {
      case 'closed':
        return Icons.lock_rounded;
      case 'programmed':
        return Icons.event_rounded;
      default:
        return Icons.radio_button_checked;
    }
  }

  DateTime? _parseDate(String d) {
    final p = d.split('/');
    if (p.length < 3) return null;
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  bool _canDeleteSession(_O9Session s) {
    // Solo permitimos eliminar sesiones programadas no iniciadas.
    return s.status == 'programmed' && s.agreements == 0 && s.attended == 0;
  }

  Future<void> _deleteSession(_O9Session s) async {
    final sessionId = s.sessionId;
    if (sessionId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sesión'),
        content: Text('¿Eliminar la sesión ${s.num}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await AppScope.of(context).deleteActreuSession(sessionId);
    if (!mounted) return;
    final error = AppScope.of(context).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.replaceFirst('Exception: ', ''))),
      );
      return;
    }
    await widget.onRefreshRequested();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sesión eliminada.')));
  }

  Widget _buildSessionTile({
    required _O9Session session,
    required int? nextSessionId,
    required bool canStartSessions,
    required Color surface,
    required bool compact,
  }) {
    final enabled =
        session.status == 'closed' ||
        (canStartSessions &&
            (nextSessionId == null || session.sessionId == nextSessionId));
    final child = _SessionCard(
      s: session,
      subcategoryId: widget.subcategoryId,
      onRefreshRequested: widget.onRefreshRequested,
      enabled: enabled,
      surface: surface,
      sc: _sc,
      sl: _sl,
      si: _si,
      compact: compact,
      onEdit: () => _editSession(session),
    );
    if (!_canDeleteSession(session)) return child;

    return Dismissible(
      key: ValueKey('actreu-session-${session.sessionId ?? session.num}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: compact ? 8 : 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFD64545),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteSession(session);
        return false;
      },
      child: child,
    );
  }

  void _showScheduler() {
    String frequency = 'Semanal';
    String time = '08:00';
    final Set<int> days = {2};
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = startDate.add(const Duration(days: 30));
    int monthlyDay = startDate.day.clamp(1, 28);
    bool scheduling = false;
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Programar sesiones',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Configura la recurrencia de las reuniones',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              const SizedBox(height: 14),
              Text(
                'Frecuencia',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    ['Diaria', 'Interdiaria', 'Semanal', 'Quincenal', 'Mensual']
                        .map(
                          (f) => ChoiceChip(
                            selected: frequency == f,
                            label: Text(f),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: frequency == f
                                  ? Colors.white
                                  : AppTheme.muted,
                            ),
                            selectedColor: AppTheme.brandBlue,
                            backgroundColor: AppTheme.stroke.withOpacity(0.40),
                            side: BorderSide.none,
                            visualDensity: const VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                            onSelected: (_) => setM(() => frequency = f),
                          ),
                        )
                        .toList(),
              ),
              if (frequency == 'Semanal' || frequency == 'Quincenal') ...[
                const SizedBox(height: 14),
                Text(
                  'Días de reunión',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final sel = days.contains(day);
                    return GestureDetector(
                      onTap: () => setM(() {
                        if (sel)
                          days.remove(day);
                        else
                          days.add(day);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.brandBlue
                              : AppTheme.stroke.withOpacity(0.30),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : AppTheme.muted,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Hora de inicio',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final parts = time.split(':');
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        ),
                      );
                      if (picked != null)
                        setM(
                          () => time =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                        );
                    },
                    icon: const Icon(Icons.access_time_rounded, size: 14),
                    label: Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Fecha fin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: scheduling
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: startDate.add(const Duration(days: 730)),
                            );
                            if (picked != null) {
                              setM(
                                () => endDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.event_rounded, size: 14),
                    label: Text(
                      _formatDate(endDate),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ),
              if (frequency == 'Mensual') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Día del mes',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: monthlyDay,
                      items: List.generate(
                        28,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      onChanged: scheduling
                          ? null
                          : (v) {
                              if (v == null) return;
                              setM(() => monthlyDay = v);
                            },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppTheme.brandBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        frequency == 'Diaria'
                            ? 'Se creará una sesión cada día a las $time'
                            : frequency == 'Interdiaria'
                            ? 'Se creará una sesión cada 2 días a las $time'
                            : frequency == 'Mensual'
                            ? 'Se creará una sesión mensual a las $time'
                            : 'Sesiones los ${days.map((d) => dayLabels[d - 1]).join(', ')} a las $time ($frequency)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.brandBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: scheduling
                      ? null
                      : () async {
                          final subcategoryId = widget.subcategoryId;
                          if (subcategoryId == null) return;
                          if (!widget.hasParticipants) {
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            _showParticipantsRequiredMessage();
                            return;
                          }
                          if (days.isEmpty &&
                              (frequency == 'Semanal' ||
                                  frequency == 'Quincenal')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selecciona al menos un día para programar.',
                                ),
                              ),
                            );
                            return;
                          }
                          setM(() => scheduling = true);
                          try {
                            final created = await AppScope.of(
                              context,
                            ).scheduleActreuSessions(
                              subcategoryId: subcategoryId,
                              startDate: startDate,
                              endDate: endDate,
                              frequency: frequency,
                              sessionStartTime: time,
                              weekdays: days,
                              monthlyDay: monthlyDay,
                            );
                            if (!mounted) return;
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            await widget.onRefreshRequested();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  created == 0
                                      ? 'No se generaron nuevas sesiones (ya existen en ese rango).'
                                      : 'Se programaron $created sesiones.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            if (ctx.mounted) {
                              setM(() => scheduling = false);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: Text(
                    scheduling ? 'Programando...' : 'Programar',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming =
        widget.sessions.where((s) {
          final sessionDate = _parseDate(s.date);
          if (sessionDate == null) return false;
          return s.status != 'closed' &&
              !DateTime(
                sessionDate.year,
                sessionDate.month,
                sessionDate.day,
              ).isBefore(today);
        }).toList()..sort((a, b) {
          final ad = _parseDate(a.date) ?? DateTime(9999);
          final bd = _parseDate(b.date) ?? DateTime(9999);
          return ad.compareTo(bd);
        });
    final past = widget.sessions.where((s) => !upcoming.contains(s)).toList()
      ..sort((a, b) {
        final ad = _parseDate(a.date) ?? DateTime(1970);
        final bd = _parseDate(b.date) ?? DateTime(1970);
        return bd.compareTo(ad);
      });
    final nextSessionId = upcoming.isNotEmpty ? upcoming.first.sessionId : null;

    return Stack(
      children: [
        _calendarView
            ? _buildCalendar(theme, surface, nextSessionId)
            : _buildList(theme, surface, upcoming, past, nextSessionId),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'cal',
            backgroundColor: surface,
            onPressed: () => setState(() => _calendarView = !_calendarView),
            child: Icon(
              _calendarView ? Icons.list_rounded : Icons.calendar_month_rounded,
              color: AppTheme.brandBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  void _editSession(_O9Session s) {
    final dateCtrl = TextEditingController(text: s.date);
    String status = s.status;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar sesión ${s.num}',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fecha (DD/MM/AAAA)',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Estado',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text(
                      'Programada',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: status == 'programmed',
                    selectedColor: AppTheme.brandBlue,
                    labelStyle: TextStyle(
                      color: status == 'programmed' ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => setM(() => status = 'programmed'),
                  ),
                  ChoiceChip(
                    label: const Text(
                      'En curso',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: status == 'active',
                    selectedColor: const Color(0xFFE4A620),
                    labelStyle: TextStyle(
                      color: status == 'active' ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => setM(() => status = 'active'),
                  ),
                  ChoiceChip(
                    label: const Text(
                      'Cerrada',
                      style: TextStyle(fontSize: 11),
                    ),
                    selected: status == 'closed',
                    selectedColor: const Color(0xFF1B8E5A),
                    labelStyle: TextStyle(
                      color: status == 'closed' ? Colors.white : null,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => setM(() => status = 'closed'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 14),
                  label: const Text('Guardar', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    setState(() {
                      s.date = dateCtrl.text.trim();
                      s.status = status;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickStart() {
    if (!widget.hasParticipants) {
      _showParticipantsRequiredMessage();
      return;
    }
    if (_creatingSessionNow) return;
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    TimeOfDay selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Iniciar sesión ahora',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Confirma la fecha para crear la sesión no programada.',
                style: TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _creatingSessionNow
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModal(
                            () => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            ),
                          );
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.stroke.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: ${_formatDate(selectedDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_rounded, size: 14, color: AppTheme.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _creatingSessionNow
                    ? null
                    : () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModal(() => selectedTime = picked);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.stroke.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Hora: ${_formatTimeOfDay(selectedTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_rounded, size: 14, color: AppTheme.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _creatingSessionNow
                      ? null
                      : () => _createSessionNow(
                          date: selectedDate,
                          startTime: _formatTimeOfDay(selectedTime),
                        ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: Text(
                    _creatingSessionNow ? 'Creando...' : 'Iniciar sesión',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createSessionNow({
    required DateTime date,
    required String startTime,
  }) async {
    final subcategoryId = widget.subcategoryId;
    if (subcategoryId == null) return;
    if (!widget.hasParticipants) {
      _showParticipantsRequiredMessage();
      return;
    }
    setState(() => _creatingSessionNow = true);
    final controller = AppScope.of(this.context);
    final createdId = await controller.createActreuSessionNow(
      subcategoryId: subcategoryId,
      sessionDate: date,
      sessionStartTime: startTime,
    );
    if (!mounted) return;
    setState(() => _creatingSessionNow = false);
    Navigator.of(this.context).pop();
    if (createdId == null) return;
    await widget.onRefreshRequested();
    if (!mounted) return;
    await Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (_) =>
            O9SessionScreen(subcategoryId: subcategoryId, sessionId: createdId),
      ),
    );
    if (!mounted) return;
    await widget.onRefreshRequested();
  }

  Widget _buildList(
    ThemeData theme,
    Color surface,
    List<_O9Session> upcoming,
    List<_O9Session> past,
    int? nextSessionId,
  ) {
    final canStartSessions = widget.hasParticipants;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Header con botones
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                upcoming.isNotEmpty ? 'Próxima sesión' : 'Sesiones',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showScheduler,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Programar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 30)),
              ),
            ],
          ),
        ),
        // Sin reuniones próximas → estado vacío con "Iniciar ahora"
        if (upcoming.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.brandBlue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.brandBlue.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.event_busy_rounded,
                    size: 26,
                    color: AppTheme.brandBlue,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No hay reuniones agendadas',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Puedes iniciar una sesión al momento o programar reuniones futuras.',
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canStartSessions ? _quickStart : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text(
                      'Iniciar sesión ahora',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showScheduler,
                    icon: const Icon(Icons.calendar_month_rounded, size: 14),
                    label: const Text(
                      'Programar reuniones',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          ...(_upcomingExpanded ? upcoming : upcoming.take(3)).map(
            (s) => _buildSessionTile(
              session: s,
              nextSessionId: nextSessionId,
              canStartSessions: canStartSessions,
              surface: surface,
              compact: false,
            ),
          ),
          const SizedBox(height: 8),
          // Botón secundario "Iniciar ahora" debajo de las proximas
          if (upcoming.length > 3)
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _upcomingExpanded = !_upcomingExpanded),
                icon: Icon(
                  _upcomingExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 14,
                  color: AppTheme.brandBlue,
                ),
                label: Text(
                  _upcomingExpanded
                      ? 'Mostrar menos programaciones'
                      : 'Mostrar más programaciones',
                  style: TextStyle(fontSize: 11, color: AppTheme.brandBlue),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          if (_shouldShowQuickStart(upcoming))
            Center(
              child: TextButton.icon(
                onPressed: canStartSessions ? _quickStart : null,
                icon: Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: AppTheme.brandBlue,
                ),
                label: Text(
                  'Iniciar sesión no programada',
                  style: TextStyle(fontSize: 11, color: AppTheme.brandBlue),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],

        if (past.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _pastExpanded = !_pastExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.stroke.withOpacity(0.30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: AppTheme.muted),
                  const SizedBox(width: 8),
                  Text(
                    'Sesiones pasadas (${past.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(
                    _pastExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_pastExpanded) ...[
            const SizedBox(height: 10),
            ...past.map(
              (s) => _buildSessionTile(
                session: s,
                nextSessionId: nextSessionId,
                canStartSessions: canStartSessions,
                surface: surface,
                compact: true,
              ),
            ),
          ],
        ],
      ],
    );
  }

  bool _shouldShowQuickStart(List<_O9Session> upcoming) {
    return upcoming.isEmpty;
  }

  Widget _buildCalendar(ThemeData theme, Color surface, int? nextSessionId) {
    final canStartSessions = widget.hasParticipants;
    final year = _calMonth.year;
    final month = _calMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final Map<int, _O9Session> sessionDays = {};
    for (final s in widget.sessions) {
      final dt = _parseDate(s.date);
      if (dt != null && dt.year == year && dt.month == month)
        sessionDays[dt.day] = s;
    }

    final totalCells = (firstWeekday - 1) + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: () =>
                  setState(() => _calMonth = DateTime(year, month - 1)),
            ),
            Text(
              '${months[month - 1]} $year',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: () =>
                  setState(() => _calMonth = DateTime(year, month + 1)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: weekDays
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: rows * 7,
          itemBuilder: (_, index) {
            final dayNum = index - (firstWeekday - 1) + 1;
            if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
            final session = sessionDays[dayNum];
            final color = session != null
                ? _sc(session.status)
                : Colors.transparent;
            return GestureDetector(
              onTap:
                  session != null &&
                      (session.status == 'closed' ||
                          (canStartSessions &&
                              (nextSessionId == null ||
                                  session.sessionId == nextSessionId)))
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => O9SessionScreen(
                            subcategoryId: widget.subcategoryId,
                            sessionId: session.sessionId,
                            isClosed: session.status == 'closed',
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      await widget.onRefreshRequested();
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: session != null ? color.withOpacity(0.12) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: session != null
                      ? Border.all(color: color.withOpacity(0.40), width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: session != null
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: session != null
                            ? color
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (session != null)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _CalLegend(color: AppTheme.brandBlue, label: 'Programada'),
            const SizedBox(width: 10),
            _CalLegend(color: const Color(0xFFE4A620), label: 'En curso'),
            const SizedBox(width: 10),
            _CalLegend(color: const Color(0xFF1B8E5A), label: 'Cerrada'),
          ],
        ),
      ],
    );
  }

  void _showParticipantsRequiredMessage() {
    widget.onParticipantsRequired();
  }
}

class _CalLegend extends StatelessWidget {
  const _CalLegend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.muted)),
    ],
  );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.s,
    required this.subcategoryId,
    required this.onRefreshRequested,
    required this.enabled,
    required this.surface,
    required this.sc,
    required this.sl,
    required this.si,
    required this.compact,
    this.onEdit,
  });
  final _O9Session s;
  final int? subcategoryId;
  final Future<void> Function() onRefreshRequested;
  final bool enabled;
  final Color surface;
  final Color Function(String) sc;
  final String Function(String) sl;
  final IconData Function(String) si;
  final bool compact;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProg = s.status == 'programmed';
    final color = sc(s.status);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(si(s.status), size: 13, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesión ${s.num}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: compact ? 11 : 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sl(s.status),
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null) ...[
                  GestureDetector(
                    onTap: enabled ? onEdit : null,
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: AppTheme.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  s.date,
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
                if (!isProg) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.people_outline_rounded,
                    size: 11,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${s.attended}/${s.total}',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.assignment_rounded,
                    size: 11,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${s.agreements} ac.',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                  if (s.overdue > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64545).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${s.overdue} venc.',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFFD64545),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 6),
            if (isProg)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: enabled
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => O9SessionScreen(
                                subcategoryId: subcategoryId,
                                sessionId: s.sessionId,
                                isClosed: s.status == 'closed',
                              ),
                            ),
                          );
                          if (!context.mounted) return;
                          await onRefreshRequested();
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 14),
                  label: const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 30)),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: enabled
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => O9SessionScreen(
                                    subcategoryId: subcategoryId,
                                    sessionId: s.sessionId,
                                    isClosed: s.status == 'closed',
                                  ),
                                ),
                              );
                              if (!context.mounted) return;
                              await onRefreshRequested();
                            }
                          : null,
                      icon: const Icon(Icons.visibility_outlined, size: 12),
                      label: const Text(
                        'Ver acta',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: enabled
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => O9SessionScreen(
                                  subcategoryId: subcategoryId,
                                  sessionId: s.sessionId,
                                  isClosed: s.status == 'closed',
                                ),
                              ),
                            );
                            if (!context.mounted) return;
                            await onRefreshRequested();
                          }
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 12),
                    label: const Text('PDF', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB: PARTICIPANTES
// ─────────────────────────────────────────────

class _ParticipantsTab extends StatefulWidget {
  const _ParticipantsTab({
    super.key,
    required this.participants,
    required this.available,
    required this.otherProjectAvailable,
    required this.onRequestAvailable,
    required this.onRequestOtherProjectAvailable,
    required this.onAdd,
    required this.onDelete,
  });
  final List<_O9Participant> participants;
  final List<Map<String, String>> available;
  final List<Map<String, String>> otherProjectAvailable;
  final Future<List<Map<String, String>>> Function() onRequestAvailable;
  final Future<List<Map<String, String>>> Function()
  onRequestOtherProjectAvailable;
  final Future<void> Function(String name, String area, int? projectMemberId)
  onAdd;
  final Future<bool> Function(int participantId) onDelete;
  @override
  State<_ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends State<_ParticipantsTab> {
  Future<void> showAddModal() async {
    final requestedAvailable = await widget.onRequestAvailable();
    final available = requestedAvailable.isEmpty
        ? widget.available
        : requestedAvailable;
    final requestedOtherProject = await widget.onRequestOtherProjectAvailable();
    final otherProjectAvailable = requestedOtherProject.isEmpty
        ? widget.otherProjectAvailable
        : requestedOtherProject;
    if (!mounted) return;
    final existingMemberIds = widget.participants
        .map((p) => p.projectMemberId)
        .whereType<int>()
        .toSet();
    final existingNames = widget.participants
        .map((p) => p.name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    final searchCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    String query = '';
    bool showManual = false;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agregar participante',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              if (!showManual) ...[
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setModal(() => query = v.toLowerCase()),
                ),
                const SizedBox(height: 10),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No hay integrantes disponibles en actreu_integrantes para esta subcategoría.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ),
                if (available.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Integrantes del acta',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                // Lista filtrada
                ...available
                    .where(
                      (p) =>
                          query.isEmpty ||
                          (p['name'] ?? '').toLowerCase().contains(query),
                    )
                    .map(
                      (p) {
                        final memberId = int.tryParse(p['memberId'] ?? '');
                        final name = (p['name'] ?? '-').trim();
                        final alreadyAdded =
                            (memberId != null &&
                                existingMemberIds.contains(memberId)) ||
                            existingNames.contains(name.toLowerCase());
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
                            child: Text(
                              name.split(' ').map((w) => w[0]).take(2).join(),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.brandBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(name, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            p['area'] ?? '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: FilledButton(
                            onPressed: alreadyAdded
                                ? null
                                : () async {
                                    await widget.onAdd(
                                      p['name'] ?? '-',
                                      p['area'] ?? '-',
                                      memberId,
                                    );
                                    if (!mounted) return;
                                    setModal(() {
                                      if (memberId != null) {
                                        existingMemberIds.add(memberId);
                                      }
                                      existingNames.add(name.toLowerCase());
                                    });
                                  },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 30),
                              textStyle: const TextStyle(fontSize: 11),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(alreadyAdded ? 'Agregado' : 'Agregar'),
                          ),
                        );
                      },
                    ),
                if (otherProjectAvailable.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text(
                    'Otros integrantes del proyecto',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...otherProjectAvailable
                      .where(
                        (p) =>
                            query.isEmpty ||
                            (p['name'] ?? '').toLowerCase().contains(query),
                      )
                      .map((p) {
                        final memberId = int.tryParse(p['memberId'] ?? '');
                        final name = (p['name'] ?? '-').trim();
                        final alreadyAdded =
                            (memberId != null &&
                                existingMemberIds.contains(memberId)) ||
                            existingNames.contains(name.toLowerCase());
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.stroke.withOpacity(0.35),
                            child: Text(
                              name.split(' ').map((w) => w[0]).take(2).join(),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: const Text(
                            'Integrante del proyecto',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: FilledButton(
                            onPressed: alreadyAdded
                                ? null
                                : () async {
                                    await widget.onAdd(
                                      p['name'] ?? '-',
                                      p['area'] ?? '-',
                                      memberId,
                                    );
                                    if (!mounted) return;
                                    setModal(() {
                                      if (memberId != null) {
                                        existingMemberIds.add(memberId);
                                      }
                                      existingNames.add(name.toLowerCase());
                                    });
                                  },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 30),
                              textStyle: const TextStyle(fontSize: 11),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(alreadyAdded ? 'Agregado' : 'Agregar'),
                          ),
                        );
                      }),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => setModal(() => showManual = true),
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Agregar nueva persona'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 38),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Área / Empresa',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setModal(() => showManual = false),
                        child: const Text('Volver'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Confirmar'),
                        onPressed: () async {
                          final normalizedName = nameCtrl.text.trim();
                          if (normalizedName.isNotEmpty) {
                            await widget.onAdd(
                              normalizedName,
                              areaCtrl.text.trim().isEmpty
                                  ? 'Sin área'
                                  : areaCtrl.text.trim(),
                              null,
                            );
                            if (!mounted) return;
                            setModal(() {
                              existingNames.add(normalizedName.toLowerCase());
                              nameCtrl.clear();
                              areaCtrl.clear();
                              showManual = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final presentCount = widget.participants.where((p) => p.present).length;
    final total = widget.participants.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A66B7), Color(0xFF1581D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Asistencia — Última sesión',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$presentCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ $total participantes',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total > 0 ? presentCount / total : 0,
                  minHeight: 7,
                  backgroundColor: Colors.white.withOpacity(0.20),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SPill(value: '$presentCount', label: 'Presentes'),
                  const SizedBox(width: 8),
                  _SPill(value: '${total - presentCount}', label: 'Ausentes'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Miembros', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: showAddModal,
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Agregar', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 34)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final p in widget.participants)
          Dismissible(
            key: ValueKey('actreu-participant-${p.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: const Color(0xFFD64545),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar participante'),
                  content: Text('Â¿Eliminar a "${p.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD64545),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return false;
              return widget.onDelete(p.id);
            },
            child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: p.present
                  ? const Color(0xFF1B8E5A).withOpacity(0.06)
                  : surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: p.present
                    ? const Color(0xFF1B8E5A).withOpacity(0.25)
                    : AppTheme.stroke,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: p.present
                    ? const Color(0xFF1B8E5A).withOpacity(0.15)
                    : AppTheme.stroke.withOpacity(0.40),
                child: Text(
                  p.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.present ? const Color(0xFF1B8E5A) : AppTheme.muted,
                  ),
                ),
              ),
              title: Text(
                p.name,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13),
              ),
              subtitle: Text(
                '${p.role} · ${p.area}',
                style: TextStyle(fontSize: 10, color: AppTheme.muted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.present
                          ? const Color(0xFF1B8E5A).withOpacity(0.12)
                          : AppTheme.stroke.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.present ? 'Presente' : 'Ausente',
                      style: TextStyle(
                        fontSize: 10,
                        color: p.present
                            ? const Color(0xFF1B8E5A)
                            : AppTheme.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  /*
                      size: 18,
                      color: Color(0xFFD64545),
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar participante'),
                          content: Text('¿Eliminar a "${p.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFD64545),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !mounted) return;
                      await widget.onDelete(p.id);

                    },
                  ),
                  */
                ],
              ),
            ),
          ),
          ),
      ],
    );
  }
}

class _SPill extends StatelessWidget {
  const _SPill({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}
