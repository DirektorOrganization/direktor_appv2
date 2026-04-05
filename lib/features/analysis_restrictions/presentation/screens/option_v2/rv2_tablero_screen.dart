// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────
enum _DistMode { area, frenteFase, libre }

enum _ViewMode { tablero, lookahead, gantt }

// Persiste dentro de la sesión
_ViewMode _defaultViewMode = _ViewMode.tablero;

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE0EAF6);
  static const primary = Color(0xFF0A66B7);
  static const accent = Color(0xFF1167C8);
  static const accentLight = Color(0xFFCCDFF7);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const yellow = Color(0xFFF59E0B);
  static const orange = Color(0xFFF97316);
  static const white = Colors.white;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Color _statusColor(RestrictionRecord r) {
  if (r.isOverdue) return _D.red;
  if (r.isDueToday) return _D.orange;
  if (r.isInProgress) return _D.yellow;
  if (r.isCompleted) return _D.green;
  return _D.mutedLight;
}

String _fmtShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

bool _matchesSearch(RestrictionRecord r, String q) {
  if (q.isEmpty) return true;
  final low = q.toLowerCase();
  return r.activity.toLowerCase().contains(low) ||
      r.description.toLowerCase().contains(low) ||
      r.area.toLowerCase().contains(low) ||
      r.responsible.toLowerCase().contains(low) ||
      r.front.toLowerCase().contains(low) ||
      r.type.toLowerCase().contains(low);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv2TableroScreen extends StatefulWidget {
  const Rv2TableroScreen({super.key});

  @override
  State<Rv2TableroScreen> createState() => _Rv2TableroScreenState();
}

class _Rv2TableroScreenState extends State<Rv2TableroScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late _ViewMode _viewMode;

  // tablero state
  _DistMode _distMode = _DistMode.area;
  bool _areaExpanded = true;
  bool _typesExpanded = false;
  String? _selectedArea;
  String? _selectedFront;
  String? _selectedPhase;
  final Set<int> _dismissedRestrictionIds = <int>{};

  // search
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _viewMode = _defaultViewMode;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── View switcher modal ───────────────────────────────────────────────────
  void _openViewSwitcher(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ViewSwitcherSheet(
        current: _viewMode,
        defaultMode: _defaultViewMode,
        onSelect: (mode, setAsDefault) {
          setState(() => _viewMode = mode);
          if (setAsDefault) _defaultViewMode = mode;
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Tablero helpers ───────────────────────────────────────────────────────
  void _setDistMode(_DistMode mode) => setState(() {
    _distMode = mode;
    _selectedArea = null;
    _selectedFront = null;
    _selectedPhase = null;
    _areaExpanded = mode == _DistMode.area;
    _typesExpanded = false;
  });

  List<RestrictionRecord> _forTab(int idx, List<RestrictionRecord> all) {
    List<RestrictionRecord> base = switch (idx) {
      0 => all.where((r) => r.isOverdue || r.isDueToday).toList(),
      1 =>
        all.where((r) => r.isPending && !r.isOverdue && !r.isDueToday).toList(),
      2 => all.where((r) => r.isInProgress).toList(),
      3 => all.where((r) => r.isCompleted).toList(),
      _ => all,
    };
    if (_distMode == _DistMode.area && _selectedArea != null) {
      base = base.where((r) => r.area == _selectedArea).toList();
    }
    if (_distMode == _DistMode.frenteFase) {
      if (_selectedFront != null)
        base = base.where((r) => r.front == _selectedFront).toList();
      if (_selectedPhase != null)
        base = base.where((r) => r.phase == _selectedPhase).toList();
    }
    if (_searchQuery.isNotEmpty)
      base = base.where((r) => _matchesSearch(r, _searchQuery)).toList();
    return base;
  }

  void _onStatTap(int tabIdx) => setState(() {
    _tabs.animateTo(tabIdx);
    _selectedArea = null;
    _selectedFront = null;
    _selectedPhase = null;
  });

  void _toggleSearch() => setState(() {
    _showSearch = !_showSearch;
    if (!_showSearch) {
      _searchQuery = '';
      _searchController.clear();
    }
  });

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(BuildContext ctx, ProjectRecord? project) {
    final viewLabel = switch (_viewMode) {
      _ViewMode.tablero => 'Tablero de Control',
      _ViewMode.lookahead => 'Lookahead · 4 Semanas',
      _ViewMode.gantt => 'Diagrama Gantt',
    };
    return AppBar(
      backgroundColor: _D.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _D.text,
            ),
          ),
          if (project != null)
            Text(
              project.name,
              style: const TextStyle(fontSize: 11, color: _D.muted),
            ),
        ],
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: IconButton(
            key: ValueKey(_showSearch),
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearch ? _D.primary : _D.muted,
            ),
            onPressed: _toggleSearch,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.view_quilt_rounded, color: _D.muted),
          tooltip: 'Cambiar vista',
          onPressed: () => _openViewSwitcher(ctx),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }

  // ── Tablero body ──────────────────────────────────────────────────────────
  Widget _buildTableroBody(
    BuildContext ctx,
    List<RestrictionRecord> restrictions,
    RestrictionSummary summary,
  ) {
    final hasFilter =
        (_distMode == _DistMode.area && _selectedArea != null) ||
        (_distMode == _DistMode.frenteFase && _selectedFront != null);
    return Column(
      children: [
        _DashboardPanel(
          restrictions: restrictions,
          summary: summary,
          distMode: _distMode,
          areaExpanded: _areaExpanded,
          typesExpanded: _typesExpanded,
          selectedArea: _selectedArea,
          selectedFront: _selectedFront,
          selectedPhase: _selectedPhase,
          onStatTap: _onStatTap,
          onDistModeChange: _setDistMode,
          onAreaTap: (a) =>
              setState(() => _selectedArea = _selectedArea == a ? null : a),
          onFrontTap: (f) => setState(() {
            _selectedFront = _selectedFront == f ? null : f;
            _selectedPhase = null;
          }),
          onPhaseTap: (p) =>
              setState(() => _selectedPhase = _selectedPhase == p ? null : p),
          onToggleArea: () => setState(() => _areaExpanded = !_areaExpanded),
          onToggleTypes: () => setState(() => _typesExpanded = !_typesExpanded),
        ),
        if (hasFilter)
          Container(
            color: _D.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.filter_alt_rounded,
                  size: 13,
                  color: _D.primary,
                ),
                const SizedBox(width: 5),
                if (_selectedArea != null)
                  Text(
                    'Área: $_selectedArea',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _D.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (_selectedFront != null) ...[
                  Text(
                    'Frente: $_selectedFront',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _D.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedPhase != null) ...[
                    const Text(
                      '  ›  ',
                      style: TextStyle(fontSize: 12, color: _D.mutedLight),
                    ),
                    Text(
                      _selectedPhase!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _D.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedArea = null;
                    _selectedFront = null;
                    _selectedPhase = null;
                  }),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: _D.primary,
                  ),
                ),
              ],
            ),
          ),
        Container(
          color: _D.white,
          child: Column(
            children: [
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: _D.primary,
                labelColor: _D.primary,
                unselectedLabelColor: _D.muted,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Vencidos'),
                  Tab(text: 'Pendientes'),
                  Tab(text: 'En proceso'),
                  Tab(text: 'Finalizadas'),
                  Tab(text: 'Todas'),
                ],
              ),
              Container(height: 1, color: _D.stroke),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: List.generate(5, (i) {
              final filtered = _forTab(
                i,
                restrictions,
              ).where((r) => !_dismissedRestrictionIds.contains(r.id)).toList();
              if (filtered.isEmpty) return _EmptyTab(tabIndex: i);
              final ctrl2 = AppScope.of(ctx);
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                itemCount: filtered.length,
                itemBuilder: (_, idx) {
                  final r = filtered[idx];
                  return Dismissible(
                    key: Key('rv2_r_${r.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _D.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    onDismissed: (_) {
                      setState(() => _dismissedRestrictionIds.add(r.id));
                      ctrl2
                          .deleteRestriction(r.id)
                          .then((_) {
                            if (!mounted) return;
                            _dismissedRestrictionIds.removeWhere(
                              (id) =>
                                  !ctrl2.restrictions.any((x) => x.id == id),
                            );
                          })
                          .catchError((_) {
                            if (!mounted) return;
                            setState(
                              () => _dismissedRestrictionIds.remove(r.id),
                            );
                          });
                    },
                    child: _TableroCard(
                      restriction: r,
                      distMode: _distMode,
                      statuses: ctrl2.catalogs.statuses,
                      onTap: () => Navigator.of(ctx).pushNamed(
                        RouteNames.restrictionDetail,
                        arguments: RestrictionDetailArgs(restrictionId: r.id),
                      ),
                      onEdit: () => Navigator.of(ctx).pushNamed(
                        RouteNames.restrictionEdit,
                        arguments: RestrictionFormArgs(restrictionId: r.id),
                      ),
                      onStatusChanged: (code) =>
                          ctrl2.updateRestrictionStatus(r.id, code),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final restrictions = ctrl.restrictions;
        _dismissedRestrictionIds.removeWhere(
          (id) => !restrictions.any((r) => r.id == id),
        );
        final summary = ctrl.restrictionSummary;
        final project = ctrl.currentProject;

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: switch (_viewMode) {
            _ViewMode.tablero => _buildTableroBody(ctx, restrictions, summary),
            _ViewMode.lookahead => _LookaheadView(
              restrictions: restrictions,
              searchQuery: _searchQuery,
            ),
            _ViewMode.gantt => _GanttView(
              restrictions: restrictions,
              searchQuery: _searchQuery,
            ),
          },
          bottomSheet: _showSearch
              ? _SearchBar(
                  controller: _searchController,
                  onChanged: (q) => setState(() => _searchQuery = q),
                  onClose: _toggleSearch,
                )
              : null,
          floatingActionButton: AnimatedScale(
            scale: _showSearch ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _showSearch ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 160),
              child: FloatingActionButton.small(
                heroTag: 'add',
                backgroundColor: _D.primary,
                foregroundColor: _D.white,
                elevation: 2,
                onPressed: _showSearch
                    ? null
                    : () => Navigator.of(
                        ctx,
                      ).pushNamed(RouteNames.restrictionCreate),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── View Switcher Sheet ──────────────────────────────────────────────────────
class _ViewSwitcherSheet extends StatefulWidget {
  const _ViewSwitcherSheet({
    required this.current,
    required this.defaultMode,
    required this.onSelect,
  });
  final _ViewMode current;
  final _ViewMode defaultMode;
  final void Function(_ViewMode mode, bool setAsDefault) onSelect;

  @override
  State<_ViewSwitcherSheet> createState() => _ViewSwitcherSheetState();
}

class _ViewSwitcherSheetState extends State<_ViewSwitcherSheet> {
  late _ViewMode _selected;
  bool _setDefault = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _setDefault = false;
  }

  static const _views = [
    (
      mode: _ViewMode.tablero,
      icon: Icons.dashboard_rounded,
      label: 'Tablero',
      sublabel: 'Dashboard + lista por estado',
      desc:
          'Vista gerencial con KPIs, distribución por área/frente y listado filtrable de restricciones.',
    ),
    (
      mode: _ViewMode.lookahead,
      icon: Icons.view_week_rounded,
      label: 'Lookahead',
      sublabel: '4 semanas · Last Planner',
      desc:
          'Grilla de 4 semanas × frentes al estilo Last Planner. Muestra cada restricción en la semana en que vence para identificar cuellos de botella.',
    ),
    (
      mode: _ViewMode.gantt,
      icon: Icons.view_timeline_rounded,
      label: 'Gantt',
      sublabel: 'Diagrama de barras',
      desc:
          'Barras horizontales por restricción agrupadas por frente, con marcador de hoy y colores por estado.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.90;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: const BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _D.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cambiar vista',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige cómo visualizar las restricciones',
                style: TextStyle(fontSize: 12, color: _D.muted),
              ),
              const SizedBox(height: 16),
              // option cards
              ..._views.map((v) {
                final active = _selected == v.mode;
                final isDefault = widget.defaultMode == v.mode;
                return GestureDetector(
                  onTap: () => setState(() => _selected = v.mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active
                          ? _D.primary.withValues(alpha: 0.07)
                          : _D.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? _D.primary : _D.stroke,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: active
                                ? _D.primary.withValues(alpha: 0.12)
                                : _D.stroke.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            v.icon,
                            size: 20,
                            color: active ? _D.primary : _D.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    v.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: active ? _D.primary : _D.text,
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _D.green.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'predeterminada',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _D.green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                v.sublabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _D.muted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                v.desc,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _D.mutedLight,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _D.primary,
                            size: 20,
                          )
                        else
                          const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: _D.stroke,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              // set as default toggle
              GestureDetector(
                onTap: () => setState(() => _setDefault = !_setDefault),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _setDefault ? _D.primary : _D.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _setDefault ? _D.primary : _D.stroke,
                          width: 1.5,
                        ),
                      ),
                      child: _setDefault
                          ? const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: _D.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Usar como vista predeterminada',
                      style: TextStyle(fontSize: 12, color: _D.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _D.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => widget.onSelect(_selected, _setDefault),
                  child: const Text(
                    'Aplicar vista',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: _D.white,
          border: Border(top: BorderSide(color: _D.stroke)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 13, color: _D.text),
                decoration: InputDecoration(
                  hintText: 'Actividad, área, responsable, frente...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: _D.mutedLight,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _D.stroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _D.stroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _D.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close_rounded, size: 18, color: _D.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lookahead View (Last Planner 4-semanas × frentes) ───────────────────────
class _LookaheadView extends StatelessWidget {
  const _LookaheadView({required this.restrictions, required this.searchQuery});
  final List<RestrictionRecord> restrictions;
  final String searchQuery;

  static const _colW = 140.0;
  static const _rowH = 110.0;
  static const _labelW = 90.0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calcular las 4 semanas desde el lunes más próximo hacia atrás
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weeks = List.generate(
      4,
      (i) => startOfWeek.add(Duration(days: i * 7)),
    );

    // Frentes disponibles
    final fronts =
        restrictions
            .map((r) => r.front)
            .where((f) => f.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (fronts.isEmpty) {
      return const Center(
        child: Text('Sin datos de frentes', style: TextStyle(color: _D.muted)),
      );
    }

    // Filtrar por búsqueda
    final filtered = searchQuery.isEmpty
        ? restrictions
        : restrictions.where((r) => _matchesSearch(r, searchQuery)).toList();

    // Agrupar: front → week-index → lista
    final grid = <String, Map<int, List<RestrictionRecord>>>{};
    for (final f in fronts) {
      grid[f] = {0: [], 1: [], 2: [], 3: []};
    }
    for (final r in filtered) {
      if (r.front.isEmpty) continue;
      final ref = r.conciliatedDate ?? r.requiredDate;
      for (int w = 0; w < 4; w++) {
        final wStart = weeks[w];
        final wEnd = wStart.add(const Duration(days: 6));
        final refDay = DateTime(ref.year, ref.month, ref.day);
        if (!refDay.isBefore(wStart) && !refDay.isAfter(wEnd)) {
          grid[r.front]![w]!.add(r);
          break;
        }
      }
    }

    return Column(
      children: [
        // ── Legend ──────────────────────────────────────────────────────────
        Container(
          color: _D.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              _LegDot(color: _D.red, label: 'Vencida'),
              const SizedBox(width: 12),
              _LegDot(color: _D.orange, label: 'Hoy'),
              const SizedBox(width: 12),
              _LegDot(color: _D.yellow, label: 'En proceso'),
              const SizedBox(width: 12),
              _LegDot(color: _D.green, label: 'Cerrada'),
              const SizedBox(width: 12),
              _LegDot(color: _D.mutedLight, label: 'Pendiente'),
            ],
          ),
        ),
        Container(height: 1, color: _D.stroke),
        // ── Grid ────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _labelW + _colW * 4,
              child: Column(
                children: [
                  // header row
                  Row(
                    children: [
                      Container(
                        width: _labelW,
                        height: 40,
                        color: _D.white,
                        alignment: Alignment.center,
                        child: const Text(
                          'FRENTE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _D.muted,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      ...List.generate(4, (w) {
                        final wStart = weeks[w];
                        final wEnd = wStart.add(const Duration(days: 6));
                        final isCurrentWeek =
                            !today.isBefore(wStart) && !today.isAfter(wEnd);
                        return Container(
                          width: _colW,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrentWeek
                                ? _D.primary.withValues(alpha: 0.06)
                                : _D.white,
                            border: Border(left: BorderSide(color: _D.stroke)),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Semana ${w + 1}${isCurrentWeek ? ' ★' : ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrentWeek ? _D.primary : _D.text,
                                ),
                              ),
                              Text(
                                '${_fmtShort(wStart)} – ${_fmtShort(wEnd)}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _D.muted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  Container(height: 1, color: _D.stroke),
                  // data rows
                  Expanded(
                    child: ListView.separated(
                      itemCount: fronts.length,
                      separatorBuilder: (_, _) =>
                          Container(height: 1, color: _D.stroke),
                      itemBuilder: (_, fi) {
                        final front = fronts[fi];
                        return SizedBox(
                          height: _rowH,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // front label
                              Container(
                                width: _labelW,
                                color: _D.surface,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      front,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _D.text,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // week cells
                              ...List.generate(4, (w) {
                                final cells = grid[front]![w]!;
                                final wStart = weeks[w];
                                final wEnd = wStart.add(
                                  const Duration(days: 6),
                                );
                                final isCurrentWeek =
                                    !today.isBefore(wStart) &&
                                    !today.isAfter(wEnd);
                                return Container(
                                  width: _colW,
                                  decoration: BoxDecoration(
                                    color: isCurrentWeek
                                        ? _D.primary.withValues(alpha: 0.03)
                                        : _D.bg,
                                    border: const Border(
                                      left: BorderSide(color: _D.stroke),
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: cells.isEmpty
                                      ? null
                                      : SingleChildScrollView(
                                          child: Wrap(
                                            spacing: 3,
                                            runSpacing: 3,
                                            children: cells
                                                .take(6)
                                                .map(
                                                  (r) => _LookaheadChip(r: r),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegDot extends StatelessWidget {
  const _LegDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: _D.muted)),
    ],
  );
}

class _LookaheadChip extends StatelessWidget {
  const _LookaheadChip({required this.r});
  final RestrictionRecord r;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(r);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      constraints: const BoxConstraints(maxWidth: 126),
      child: Text(
        r.activity,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Gantt helpers ────────────────────────────────────────────────────────────
int _isoWeekNum(DateTime d) {
  final doy = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
  return ((doy - d.weekday + 10) ~/ 7);
}

String _dayAbbr(int weekday) {
  const a = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return a[weekday];
}

class _GanttItem {
  final bool isFrontHeader;
  final String? front;
  final RestrictionRecord? record;
  const _GanttItem.frontHeader(String f)
    : isFrontHeader = true,
      front = f,
      record = null;
  const _GanttItem.row(RestrictionRecord r)
    : isFrontHeader = false,
      front = null,
      record = r;
}

// ─── Gantt View ───────────────────────────────────────────────────────────────
class _GanttView extends StatefulWidget {
  const _GanttView({required this.restrictions, required this.searchQuery});
  final List<RestrictionRecord> restrictions;
  final String searchQuery;

  @override
  State<_GanttView> createState() => _GanttViewState();
}

class _GanttViewState extends State<_GanttView> {
  static const _labelW = 190.0;
  static const _dayW = 28.0;
  static const _days = 42;
  static const _rowH = 60.0;
  static const _wkH = 26.0;
  static const _dyH = 28.0;

  final _hHeader = ScrollController();
  final _hBody = ScrollController();
  bool _hSync = false;

  int? _sel1;
  int? _sel2;

  @override
  void initState() {
    super.initState();
    _hHeader.addListener(_syncH2B);
    _hBody.addListener(_syncB2H);
  }

  void _syncH2B() {
    if (_hSync || !_hBody.hasClients) return;
    _hSync = true;
    _hBody.jumpTo(_hHeader.offset);
    _hSync = false;
  }

  void _syncB2H() {
    if (_hSync || !_hHeader.hasClients) return;
    _hSync = true;
    _hHeader.jumpTo(_hBody.offset);
    _hSync = false;
  }

  @override
  void dispose() {
    _hHeader.dispose();
    _hBody.dispose();
    super.dispose();
  }

  void _tap(int id) {
    bool showPicker = false;
    setState(() {
      if (_sel1 == null) {
        _sel1 = id;
      } else if (id == _sel1) {
        _sel1 = _sel2;
        _sel2 = null;
      } else if (_sel2 == null) {
        _sel2 = id;
        showPicker = true;
      } else if (id == _sel2) {
        _sel2 = null;
      } else {
        _sel1 = _sel2;
        _sel2 = id;
        showPicker = true;
      }
    });
    if (showPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRelPicker();
      });
    }
  }

  void _showRelPicker() {
    final all = widget.restrictions;
    final r1 = all.firstWhere((r) => r.id == _sel1);
    final r2 = all.firstWhere((r) => r.id == _sel2);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RelationPicker(
        r1: r1,
        r2: r2,
        onPick: (rel) {
          Navigator.of(context).pop();
          setState(() {
            _sel1 = null;
            _sel2 = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Relación $rel registrada entre restricciones'),
              duration: const Duration(seconds: 2),
              backgroundColor: _D.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = today.subtract(const Duration(days: 7));
    final barsW = _dayW * _days;
    final totalW = _labelW + barsW;

    final filtered =
        (widget.searchQuery.isEmpty
              ? widget.restrictions
              : widget.restrictions
                    .where((r) => _matchesSearch(r, widget.searchQuery))
                    .toList())
          ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    final frontMap = <String, List<RestrictionRecord>>{};
    for (final r in filtered) {
      frontMap.putIfAbsent(r.front.isEmpty ? '—' : r.front, () => []).add(r);
    }
    final fronts = frontMap.keys.toList()..sort();

    final items = <_GanttItem>[];
    for (final f in fronts) {
      items.add(_GanttItem.frontHeader(f));
      for (final r in frontMap[f]!) {
        items.add(_GanttItem.row(r));
      }
    }

    final weeks = List.generate(6, (i) => startDay.add(Duration(days: i * 7)));
    final todayOff = today.difference(startDay).inDays;

    final selCount = (_sel1 != null ? 1 : 0) + (_sel2 != null ? 1 : 0);

    return Column(
      children: [
        // ── Header semanas + días ────────────────────────────────────────────
        SingleChildScrollView(
          controller: _hHeader,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            child: Column(
              children: [
                // fila semanas
                Row(
                  children: [
                    Container(
                      width: _labelW,
                      height: _wkH,
                      color: _D.surface,
                      alignment: Alignment.center,
                      child: const Text(
                        'RESTRICCIÓN',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: _D.muted,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    ...List.generate(6, (w) {
                      final ws = weeks[w];
                      final we = ws.add(const Duration(days: 6));
                      return Container(
                        width: _dayW * 7,
                        height: _wkH,
                        decoration: BoxDecoration(
                          color: _D.primary.withValues(
                            alpha: w.isEven ? 0.04 : 0.0,
                          ),
                          border: const Border(
                            left: BorderSide(color: _D.stroke),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Sem ${_isoWeekNum(ws)} · ${_fmtShort(ws)}–${_fmtShort(we)}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _D.text,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // fila días
                Row(
                  children: [
                    Container(
                      width: _labelW,
                      height: _dyH,
                      decoration: const BoxDecoration(
                        color: _D.surface,
                        border: Border(bottom: BorderSide(color: _D.stroke)),
                      ),
                    ),
                    ...List.generate(_days, (i) {
                      final d = startDay.add(Duration(days: i));
                      final isToday = d == today;
                      final isMon = d.weekday == DateTime.monday;
                      return Container(
                        width: _dayW,
                        height: _dyH,
                        decoration: BoxDecoration(
                          color: isToday
                              ? _D.primary.withValues(alpha: 0.10)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: _D.stroke.withValues(
                                alpha: isMon ? 1.0 : 0.4,
                              ),
                              width: isMon ? 1 : 0.5,
                            ),
                            bottom: const BorderSide(color: _D.stroke),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayAbbr(d.weekday),
                              style: TextStyle(
                                fontSize: 7,
                                color: isToday ? _D.primary : _D.mutedLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 8,
                                color: isToday ? _D.primary : _D.muted,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _hBody,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, idx) {
                  final item = items[idx];

                  // ── Frente header ─────────────────────────────────────────
                  if (item.isFrontHeader) {
                    return Container(
                      height: 28,
                      color: _D.accentLight.withValues(alpha: 0.55),
                      padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.layers_rounded,
                            size: 12,
                            color: _D.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.front!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _D.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ── Fila restricción ──────────────────────────────────────
                  final r = item.record!;
                  final color = _statusColor(r);
                  final ref = r.conciliatedDate ?? r.requiredDate;
                  final refDay = DateTime(ref.year, ref.month, ref.day);
                  final barS = refDay
                      .subtract(const Duration(days: 3))
                      .difference(startDay)
                      .inDays;
                  final barE = refDay.difference(startDay).inDays;
                  final daysOvr = r.isOverdue
                      ? today.difference(refDay).inDays
                      : 0;
                  final isSel1 = r.id == _sel1;
                  final isSel2 = r.id == _sel2;
                  final isSel = isSel1 || isSel2;

                  return GestureDetector(
                    onTap: () => _tap(r.id),
                    child: Container(
                      height: _rowH,
                      decoration: BoxDecoration(
                        color: isSel
                            ? _D.primary.withValues(alpha: 0.06)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: _D.stroke.withValues(alpha: 0.7),
                            width: 0.5,
                          ),
                          left: isSel
                              ? BorderSide(color: _D.primary, width: 3)
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          // ── Label ──────────────────────────────────────────
                          SizedBox(
                            width: _labelW,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      if (r.front.isNotEmpty) ...[
                                        const Icon(
                                          Icons.layers_rounded,
                                          size: 9,
                                          color: _D.mutedLight,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            r.front,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: _D.mutedLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      if (r.front.isNotEmpty &&
                                          r.phase.isNotEmpty)
                                        const Text(
                                          ' · ',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: _D.mutedLight,
                                          ),
                                        ),
                                      if (r.phase.isNotEmpty) ...[
                                        const Icon(
                                          Icons.account_tree_rounded,
                                          size: 9,
                                          color: _D.mutedLight,
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            r.phase,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: _D.mutedLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.activity,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSel ? _D.primary : _D.text,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (r.isOverdue)
                                    Text(
                                      '↑$daysOvr días vencida',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: _D.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // ── Barra Gantt ────────────────────────────────────
                          SizedBox(
                            width: barsW,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                // línea hoy
                                Positioned(
                                  left: todayOff * _dayW,
                                  top: 0,
                                  bottom: 0,
                                  width: 1.5,
                                  child: Container(
                                    color: _D.primary.withValues(alpha: 0.28),
                                  ),
                                ),
                                // barra
                                if (barE >= 0 && barS < _days)
                                  Positioned(
                                    left: math.max(barS * _dayW, 0),
                                    top: 16,
                                    height: 22,
                                    width: math.max(
                                      (barE - math.max(barS, 0) + 1) * _dayW,
                                      _dayW,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                          alpha: r.isCompleted ? 0.35 : 0.20,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.70),
                                          width: r.isOverdue ? 1.5 : 1,
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 5),
                                      child: Text(
                                        _fmtShort(refDay),
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                // badge selección
                                if (isSel)
                                  Positioned(
                                    right: 6,
                                    top: 8,
                                    child: Container(
                                      width: 17,
                                      height: 17,
                                      decoration: const BoxDecoration(
                                        color: _D.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        isSel1 ? '1' : '2',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // ── Banner selección ─────────────────────────────────────────────────
        if (selCount > 0)
          _GanttSelBanner(
            count: selCount,
            onClear: () => setState(() {
              _sel1 = null;
              _sel2 = null;
            }),
            onLink: selCount == 2 ? _showRelPicker : null,
          ),
      ],
    );
  }
}

// ─── Gantt: banner selección ──────────────────────────────────────────────────
class _GanttSelBanner extends StatelessWidget {
  const _GanttSelBanner({
    required this.count,
    required this.onClear,
    this.onLink,
  });
  final int count;
  final VoidCallback onClear;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
    decoration: const BoxDecoration(
      color: Color(0xFFEFF6FF),
      border: Border(top: BorderSide(color: _D.primary, width: 1.5)),
    ),
    child: Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: _D.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            count == 1
                ? 'Selecciona otra restricción para vincular'
                : '2 restricciones seleccionadas',
            style: const TextStyle(
              fontSize: 12,
              color: _D.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onLink != null)
          TextButton(
            onPressed: onLink,
            style: TextButton.styleFrom(
              foregroundColor: _D.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Vincular',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded, size: 18, color: _D.muted),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}

// ─── Gantt: selector de relación ─────────────────────────────────────────────
class _RelationPicker extends StatelessWidget {
  const _RelationPicker({
    required this.r1,
    required this.r2,
    required this.onPick,
  });
  final RestrictionRecord r1;
  final RestrictionRecord r2;
  final void Function(String) onPick;

  static const _rels = [
    (
      code: 'FC',
      label: 'Fin → Comienzo',
      desc: 'B empieza cuando A termina — la más común',
    ),
    (
      code: 'CC',
      label: 'Comienzo → Comienzo',
      desc: 'Ambas inician al mismo tiempo',
    ),
    (code: 'FF', label: 'Fin → Fin', desc: 'Ambas terminan al mismo tiempo'),
    (code: 'CF', label: 'Comienzo → Fin', desc: 'B termina cuando A comienza'),
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _D.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Definir relación',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RelChip(label: r1.activity, num: '1'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _D.muted,
                    ),
                  ),
                  Expanded(
                    child: _RelChip(label: r2.activity, num: '2'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._rels.map(
                (rel) => GestureDetector(
                  onTap: () => onPick(rel.code),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _D.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _D.stroke),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _D.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            rel.code,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _D.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rel.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _D.text,
                                ),
                              ),
                              Text(
                                rel.desc,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _D.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _D.mutedLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelChip extends StatelessWidget {
  const _RelChip({required this.label, required this.num});
  final String label;
  final String num;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: _D.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _D.primary.withValues(alpha: 0.30)),
    ),
    child: Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: _D.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _D.primary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ─── Dashboard Panel ──────────────────────────────────────────────────────────
class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.restrictions,
    required this.summary,
    required this.distMode,
    required this.areaExpanded,
    required this.typesExpanded,
    required this.selectedArea,
    required this.selectedFront,
    required this.selectedPhase,
    required this.onStatTap,
    required this.onDistModeChange,
    required this.onAreaTap,
    required this.onFrontTap,
    required this.onPhaseTap,
    required this.onToggleArea,
    required this.onToggleTypes,
  });

  final List<RestrictionRecord> restrictions;
  final RestrictionSummary summary;
  final _DistMode distMode;
  final bool areaExpanded, typesExpanded;
  final String? selectedArea, selectedFront, selectedPhase;
  final void Function(int) onStatTap;
  final void Function(_DistMode) onDistModeChange;
  final void Function(String) onAreaTap, onFrontTap, onPhaseTap;
  final VoidCallback onToggleArea, onToggleTypes;

  @override
  Widget build(BuildContext context) {
    final areaMap = <String, List<RestrictionRecord>>{};
    for (final r in restrictions) {
      if (r.area.isNotEmpty) areaMap.putIfAbsent(r.area, () => []).add(r);
    }
    final topAreas = areaMap.entries.toList()
      ..sort(
        (a, b) => b.value
            .where((r) => r.isOverdue)
            .length
            .compareTo(a.value.where((r) => r.isOverdue).length),
      );

    final frontMap = <String, Set<String>>{};
    for (final r in restrictions) {
      if (r.front.isNotEmpty)
        frontMap.putIfAbsent(r.front, () => {}).add(r.phase);
    }
    final fronts = frontMap.keys.toList()..sort();

    final typeMap = <String, int>{};
    for (final r in restrictions) {
      if (r.type.isNotEmpty) typeMap[r.type] = (typeMap[r.type] ?? 0) + 1;
    }
    final topTypes = typeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = topTypes.isEmpty ? 1 : topTypes.first.value;

    return Container(
      color: _D.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // stat cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Total',
                    value: '${summary.total}',
                    color: _D.primary,
                    onTap: () => onStatTap(4),
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Vencidos',
                    value: '${summary.overdue}',
                    color: summary.overdue > 0 ? _D.red : _D.mutedLight,
                    onTap: () => onStatTap(0),
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    icon: Icons.timelapse_rounded,
                    label: 'En proceso',
                    value: '${summary.inProgress}',
                    color: _D.yellow,
                    onTap: () => onStatTap(2),
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    icon: Icons.pending_outlined,
                    label: 'Pendientes',
                    value: '${summary.pending}',
                    color: _D.accent,
                    onTap: () => onStatTap(1),
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Finalizadas',
                    value: '${summary.completed}',
                    color: _D.green,
                    onTap: () => onStatTap(3),
                  ),
                ],
              ),
            ),
          ),
          // dist mode selector
          _DistModeSelectorB(mode: distMode, onChanged: onDistModeChange),
          // area section
          if ((distMode == _DistMode.area || distMode == _DistMode.libre) &&
              topAreas.isNotEmpty)
            _CollapsibleSection(
              title: 'DISTRIBUCIÓN POR ÁREA',
              expanded: areaExpanded,
              onToggle: onToggleArea,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: topAreas.take(6).map((entry) {
                    final items = entry.value;
                    final hasOver = items.any((r) => r.isOverdue);
                    final allDone = items.every((r) => r.isCompleted);
                    final hasProg = items.any(
                      (r) => r.isInProgress || r.isDueToday,
                    );
                    final isSel = selectedArea == entry.key;
                    final Color bg, border, badgeColor;
                    if (isSel) {
                      bg = _D.primary.withValues(alpha: 0.14);
                      border = _D.primary;
                      badgeColor = _D.primary;
                    } else if (hasOver) {
                      bg = _D.red.withValues(alpha: 0.08);
                      border = _D.red.withValues(alpha: 0.25);
                      badgeColor = _D.red;
                    } else if (allDone) {
                      bg = _D.green.withValues(alpha: 0.08);
                      border = _D.green.withValues(alpha: 0.25);
                      badgeColor = _D.green;
                    } else if (hasProg) {
                      bg = _D.yellow.withValues(alpha: 0.08);
                      border = _D.yellow.withValues(alpha: 0.25);
                      badgeColor = _D.orange;
                    } else {
                      bg = _D.accentLight;
                      border = _D.stroke;
                      badgeColor = _D.primary;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => onAreaTap(entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSel) ...[
                                const Icon(
                                  Icons.filter_alt_rounded,
                                  size: 9,
                                  color: _D.primary,
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: badgeColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${items.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          // frente y fase section
          if (distMode == _DistMode.frenteFase && fronts.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: _SectionLabel('FRENTE Y FASE'),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: fronts.map((f) {
                      final isSel = selectedFront == f;
                      final fCount = restrictions
                          .where((r) => r.front == f)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => onFrontTap(f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? _D.primary.withValues(alpha: 0.10)
                                  : _D.accentLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSel ? _D.primary : _D.stroke,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  f,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSel ? _D.primary : _D.muted,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$fCount',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? _D.primary : _D.mutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedFront != null &&
                    (frontMap[selectedFront]?.isNotEmpty ?? false)) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(26, 0, 16, 8),
                    child: Row(
                      children: (frontMap[selectedFront]!.toList()..sort()).map(
                        (ph) {
                          final isSel = selectedPhase == ph;
                          final pCount = restrictions
                              .where(
                                (r) =>
                                    r.front == selectedFront && r.phase == ph,
                              )
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () => onPhaseTap(ph),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? _D.accent.withValues(alpha: 0.10)
                                      : _D.bg,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: isSel ? _D.accent : _D.stroke,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ph,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSel ? _D.accent : _D.muted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$pCount',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSel
                                            ? _D.accent
                                            : _D.mutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ],
            ),
          // types section
          if (topTypes.isNotEmpty)
            _CollapsibleSection(
              title: 'RESTRICCIONES POR TIPO',
              expanded: typesExpanded,
              onToggle: onToggleTypes,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Column(
                  children: [
                    ...topTypes
                        .take(typesExpanded ? topTypes.length : 4)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) {
                          final barColors = [
                            _D.primary,
                            _D.accent,
                            _D.yellow,
                            _D.green,
                          ];
                          final color = barColors[e.key % barColors.length];
                          final frac = maxCount == 0
                              ? 0.0
                              : e.value.value / maxCount;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    e.value.key,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _D.muted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: frac,
                                      minHeight: 8,
                                      backgroundColor: _D.stroke,
                                      valueColor: AlwaysStoppedAnimation(color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${e.value.value}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    if (topTypes.length > 4)
                      GestureDetector(
                        onTap: onToggleTypes,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                typesExpanded
                                    ? 'Ver menos'
                                    : 'Ver más (${topTypes.length - 4})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _D.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                typesExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 14,
                                color: _D.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Container(height: 1, color: _D.stroke),
        ],
      ),
    );
  }
}

// ─── Dist mode selector B ─────────────────────────────────────────────────────
class _DistModeSelectorB extends StatelessWidget {
  const _DistModeSelectorB({required this.mode, required this.onChanged});
  final _DistMode mode;
  final void Function(_DistMode) onChanged;

  static const _items = [
    (_DistMode.area, 'Área', Icons.grid_view_rounded),
    (_DistMode.frenteFase, 'Frente y Fase', Icons.account_tree_rounded),
    (_DistMode.libre, 'Libre', Icons.dashboard_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _D.white,
        border: Border(bottom: BorderSide(color: _D.stroke)),
      ),
      child: Row(
        children: _items.map((item) {
          final active = mode == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active ? _D.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$3,
                      size: 12,
                      color: active ? _D.primary : _D.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? _D.primary : _D.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Collapsible Section ──────────────────────────────────────────────────────
class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(child: _SectionLabel(title)),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: _D.muted,
                ),
              ),
            ],
          ),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: child,
        crossFadeState: expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ],
  );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 9, color: _D.muted)),
            ],
          ),
        ],
      ),
    ),
  );
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: _D.muted,
      letterSpacing: 0.7,
    ),
  );
}

// ─── Tablero Card ─────────────────────────────────────────────────────────────
class _TableroCard extends StatelessWidget {
  const _TableroCard({
    required this.restriction,
    required this.distMode,
    required this.statuses,
    required this.onTap,
    required this.onEdit,
    required this.onStatusChanged,
  });
  final RestrictionRecord restriction;
  final _DistMode distMode;
  final List<CatalogOption> statuses;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final void Function(String) onStatusChanged;

  void _openStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(
        restriction: restriction,
        statuses: statuses,
        onSelect: (code) {
          Navigator.of(context).pop();
          onStatusChanged(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = restriction;
    final color = _statusColor(r);
    final refDate = r.conciliatedDate ?? r.requiredDate;
    final daysOverdue = r.isOverdue
        ? DateTime.now().difference(refDate).inDays
        : 0;
    final showArea = distMode == _DistMode.area && r.area.isNotEmpty;
    final showFF = distMode == _DistMode.frenteFase;
    final hasChips = showArea || showFF;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.stroke),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Franja izquierda ──────────────────────────────────
              Container(
                width: r.isOverdue ? 26 : 4,
                color: color,
                child: r.isOverdue
                    ? RotatedBox(
                        quarterTurns: 3,
                        child: Center(
                          child: Text(
                            '$daysOverdue días',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Título + sync ─────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.activity,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _D.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _SyncBadge(synced: r.isSynced),
                        ],
                      ),
                      // ── Chips contextuales ────────────────────────────
                      if (hasChips) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (showArea)
                              _Chip(label: r.area, color: _D.primary),
                            if (showFF && r.front.isNotEmpty)
                              _Chip(label: r.front, color: _D.accent),
                            if (showFF && r.phase.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _Chip(label: r.phase, color: _D.muted),
                            ],
                          ],
                        ),
                      ],
                      // ── Descripción ───────────────────────────────────
                      if (r.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.description,
                          style: const TextStyle(fontSize: 11, color: _D.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // ── Fecha de vencimiento ──────────────────────────
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            r.conciliatedDate != null
                                ? Icons.event_available_rounded
                                : Icons.event_rounded,
                            size: 11,
                            color: r.conciliatedDate != null ? _D.primary : _D.mutedLight,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            r.conciliatedDate != null ? 'Conciliada' : 'Requerida',
                            style: TextStyle(
                              fontSize: 9,
                              color: r.conciliatedDate != null ? _D.primary : _D.mutedLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _fmtShort(refDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // ── Responsable · Estado · Editar · Detalle ───────
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: _D.mutedLight,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              r.responsible,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _D.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openStatusSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 12,
                                    color: color,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onEdit,
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: _D.muted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onTap,
                            child: const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                              color: _D.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sync Badge ───────────────────────────────────────────────────────────────
class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.synced});
  final bool synced;

  @override
  Widget build(BuildContext context) {
    final color = synced ? _D.green : _D.orange;
    final icon = synced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}

// ─── Status Sheet ─────────────────────────────────────────────────────────────
class _StatusSheet extends StatelessWidget {
  const _StatusSheet({
    required this.restriction,
    required this.statuses,
    required this.onSelect,
  });
  final RestrictionRecord restriction;
  final List<CatalogOption> statuses;
  final void Function(String) onSelect;

  static String _kindFromLabel(String label) {
    final l = label.trim().toLowerCase();
    if (l.contains('complet') || l.contains('final')) return 'completed';
    if (l.contains('proceso') || l.contains('progress') || l.contains('curso'))
      return 'in_progress';
    return 'pending';
  }

  static Color _colorForKind(String k) {
    if (k == 'completed') return _D.green;
    if (k == 'in_progress') return _D.yellow;
    return _D.mutedLight;
  }

  static IconData _iconForKind(String k) {
    if (k == 'completed') return Icons.check_circle_rounded;
    if (k == 'in_progress') return Icons.timelapse_rounded;
    return Icons.pending_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final opts = statuses.isNotEmpty
        ? statuses
        : [
            CatalogOption(id: 'pending', label: 'Pendiente'),
            CatalogOption(id: 'in_progress', label: 'En Proceso'),
            CatalogOption(id: 'completed', label: 'Completada'),
          ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _D.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _D.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Cambiar estado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                restriction.activity,
                style: const TextStyle(fontSize: 11, color: _D.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              ...opts.map((opt) {
                final kind = _kindFromLabel(opt.label);
                final color = _colorForKind(kind);
                final icon = _iconForKind(kind);
                final isCurrent = opt.id == restriction.statusCode;
                return GestureDetector(
                  onTap: () => onSelect(opt.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent ? color.withValues(alpha: 0.08) : _D.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? color.withValues(alpha: 0.40)
                            : _D.stroke,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCurrent ? color : _D.text,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Icon(Icons.check_rounded, size: 16, color: color),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

// ─── Empty Tab ────────────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.tabIndex});
  final int tabIndex;

  static const _labels = [
    'Sin restricciones vencidas',
    'Sin restricciones pendientes',
    'Sin restricciones en proceso',
    'Sin restricciones finalizadas',
    'Sin restricciones registradas',
  ];
  static const _icons = [
    Icons.check_circle_outline_rounded,
    Icons.pending_outlined,
    Icons.timelapse_rounded,
    Icons.emoji_events_outlined,
    Icons.checklist_rounded,
  ];

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _D.accentLight.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(_icons[tabIndex], size: 36, color: _D.primary),
        ),
        const SizedBox(height: 14),
        Text(
          _labels[tabIndex],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _D.muted,
          ),
        ),
      ],
    ),
  );
}
