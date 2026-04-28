// PROPUESTA A — "CAMPO"
// Fase 1: editor visual interactivo con zoom/pan (InteractiveViewer),
//         atajos por lado, y configuración centralizada en un sheet.
// Indicadores: TabBar estilo Análisis de Restricciones (menos invasivo).
// Fase 2: matriz piso×sector por actividad.
// Fase 3: selector de piso → progreso por sector.
import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

abstract final class _C {
  static const bg = Color(0xFFF3F7FC);
  static const surface = Colors.white;
  static const stroke = Color(0xFFDDE8F5);
  static const primary = Color(0xFF0A66B7);
  static const accent = Color(0xFFD6E8FA);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const green = Color(0xFF10B981);
  static const teal = Color(0xFF0B7A43);
  static const red = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
}

// ─── Screen principal ─────────────────────────────────────────────────────────

class AvanceGraficoCampoScreen extends StatefulWidget {
  const AvanceGraficoCampoScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<AvanceGraficoCampoScreen> createState() =>
      _AvanceGraficoCampoScreenState();
}

class _AvanceGraficoCampoScreenState extends State<AvanceGraficoCampoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).ensureAvanceGraficoDemoData();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final project = ctrl.currentProject;
        final data = ctrl.avanceGraficoData;

        if (project == null || data == null) {
          return Scaffold(
            backgroundColor: _C.bg,
            appBar: _buildAppBar(null, data),
            body: const Center(
              child: CircularProgressIndicator(color: _C.primary),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _C.bg,
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(project.name, data),
          body: TabBarView(
            controller: _tab,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              data.phase1 != null
                  ? _Phase1Editor(data: data.phase1!, ctrl: ctrl)
                  : const _EmptyPhase(),
              data.phase2 != null
                  ? _Phase2Campo(
                      data: data.phase2!,
                      ctrl: ctrl,
                      states: data.states,
                    )
                  : const _EmptyPhase(),
              data.phase3 != null
                  ? _Phase3Campo(
                      data: data.phase3!,
                      ctrl: ctrl,
                      states: data.states,
                    )
                  : const _EmptyPhase(),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    String? projectName,
    AvanceGraficoData? data,
  ) {
    final sum = data?.summary;
    final pct1 = sum == null ? 0 : (sum.phase1Completion * 100).round();
    final pct2 = sum == null ? 0 : (sum.phase2Completion * 100).round();
    final pct3 = sum == null ? 0 : (sum.phase3Completion * 100).round();
    final overall = sum == null
        ? 0
        : ((sum.phase1Completion +
                      sum.phase2Completion +
                      sum.phase3Completion) /
                  3 *
                  100)
              .round();
    return AppBar(
      backgroundColor: _C.surface,
      foregroundColor: _C.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Avance Grafico',
            style: TextStyle(
              fontSize: 10,
              color: _C.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            projectName ?? 'Cargando...',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _C.accent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _C.stroke),
          ),
          child: Text(
            '$overall% General',
            style: const TextStyle(
              color: _C.primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(49),
        child: Column(
          children: [
            TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: _C.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: _C.primary,
              unselectedLabelColor: _C.muted,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                _PhaseTab(
                  phase: 1,
                  color: _C.primary,
                  label: 'Fase 1',
                  percent: pct1,
                ),
                _PhaseTab(
                  phase: 2,
                  color: _C.green,
                  label: 'Fase 2',
                  percent: pct2,
                ),
                _PhaseTab(
                  phase: 3,
                  color: _C.amber,
                  label: 'Fase 3',
                  percent: pct3,
                ),
              ],
            ),
            Container(height: 1, color: _C.stroke),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
class _PhaseTab extends StatelessWidget {
  const _PhaseTab({
    required this.phase,
    required this.color,
    required this.label,
    required this.percent,
  });

  final int phase;
  final Color color;
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$phase',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('$label  $percent%'),
        ],
      ),
    );
  }
}

// FASE 1 — Editor visual interactivo
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase1Editor extends StatefulWidget {
  const _Phase1Editor({required this.data, required this.ctrl});
  final AvanceGraficoPhase1Data data;
  final AppController ctrl;
  @override
  State<_Phase1Editor> createState() => _Phase1EditorState();
}

class _Phase1EditorState extends State<_Phase1Editor> {
  final TransformationController _tc = TransformationController();
  double _currentScale = 1.0;
  Size? _contentSize;
  Size? _viewportSize;
  final _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tc.addListener(_syncScale);
    // Fit content to screen after the first frame is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndFit());
  }

  @override
  void didUpdateWidget(_Phase1Editor old) {
    super.didUpdateWidget(old);
    // Any data change (shape, sections, cells) → re-fit so the whole plan stays visible
    if (old.data != widget.data) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndFit());
    }
  }

  @override
  void dispose() {
    _tc.removeListener(_syncScale);
    _tc.dispose();
    super.dispose();
  }

  // Syncs _currentScale when the user pinches (InteractiveViewer updates _tc internally)
  void _syncScale() {
    final s = _tc.value.getMaxScaleOnAxis();
    if (mounted && (_currentScale - s).abs() > 0.005) {
      setState(() => _currentScale = s);
    }
  }

  // Reads the rendered content size and applies fit-to-screen transform
  void _measureAndFit() {
    if (!mounted) return;
    final ctx = _contentKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _contentSize = box.size;
    _applyFit();
  }

  // Builds a scale+translate matrix that centers the content inside the viewport
  Matrix4 _centerMatrix(double s, double vw, double vh, double cw, double ch) {
    final tx = (vw - cw * s) / 2;
    final ty = (vh - ch * s) / 2;
    // Column-major Matrix4: scale then translate
    return Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  void _applyFit() {
    final vp = _viewportSize;
    final cs = _contentSize;
    if (vp == null || cs == null || !mounted) return;
    final s =
        ((vp.width / cs.width).clamp(0.1, 1.5) <
                    (vp.height / cs.height).clamp(0.1, 1.5)
                ? (vp.width / cs.width)
                : (vp.height / cs.height))
            .clamp(0.2, 1.5);
    setState(() => _currentScale = s);
    _tc.value = _centerMatrix(s, vp.width, vp.height, cs.width, cs.height);
  }

  // Zoom buttons — keep content centered at the new scale
  void _zoom(double factor) {
    final s = (_currentScale * factor).clamp(0.2, 4.0);
    final vp = _viewportSize;
    final cs = _contentSize;
    setState(() => _currentScale = s);
    if (vp != null && cs != null) {
      _tc.value = _centerMatrix(s, vp.width, vp.height, cs.width, cs.height);
    } else {
      _tc.value = Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    }
  }

  void _resetZoom() => _applyFit();

  // Side shortcuts — zoom so the chosen side fills the viewport
  void _jumpTo(Alignment align) {
    final vp = _viewportSize;
    final cs = _contentSize;
    if (vp == null || cs == null) return;
    final vw = vp.width;
    final vh = vp.height;
    final cw = cs.width;
    final ch = cs.height;
    const margin = 12.0;

    double s, tx, ty;

    if (align == Alignment.topCenter || align == Alignment.bottomCenter) {
      // Fit width, pan to top or bottom
      s = ((vw - margin * 2) / cw).clamp(0.2, 4.0);
      tx = (vw - cw * s) / 2;
      ty = align == Alignment.topCenter ? margin : (vh - ch * s - margin);
    } else {
      // Fit height, pan to left or right
      s = ((vh - margin * 2) / ch).clamp(0.2, 4.0);
      ty = (vh - ch * s) / 2;
      tx = align == Alignment.centerLeft ? margin : (vw - cw * s - margin);
    }

    setState(() => _currentScale = s);
    _tc.value = Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final ctrl = widget.ctrl;
    final groups = _groupByLado(data.sections);
    final pct = data.totalPositions == 0
        ? 0.0
        : data.completedPositions / data.totalPositions;

    return Column(
      children: [
        // ── Barra de accion compacta ─────────────────────────────────────────
        Container(
          color: _C.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                '${data.completedPositions}/${data.totalPositions}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.text,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: _C.stroke,
                    valueColor: const AlwaysStoppedAnimation<Color>(_C.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _C.primary,
                ),
              ),
              const SizedBox(width: 12),
              _ZoomBtn(icon: Icons.zoom_out, onTap: () => _zoom(0.8)),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: _resetZoom,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(_currentScale * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _C.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              _ZoomBtn(icon: Icons.zoom_in, onTap: () => _zoom(1.25)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showConfigSheet(context, data: data, ctrl: ctrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Config.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Vista planta (InteractiveViewer) ─────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Capture viewport size every time layout changes
              final newVp = Size(constraints.maxWidth, constraints.maxHeight);
              if (_viewportSize != newVp) {
                _viewportSize = newVp;
                // Re-fit if we already know the content size
                if (_contentSize != null) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _applyFit(),
                  );
                }
              }
              return ClipRect(
                child: InteractiveViewer(
                  transformationController: _tc,
                  constrained: false,
                  minScale: 0.2,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    key: _contentKey,
                    child: _BuildingPlanView(
                      groups: groups,
                      data: data,
                      ctrl: ctrl,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // ── Leyenda + atajos de lado ─────────────────────────────────────────
        Container(
          color: _C.surface,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: const [
                  _LegendDot(label: 'Pendiente', color: Color(0xFFBEBEB9)),
                  _LegendDot(label: 'Completado', color: Color(0xFF6ECC77)),
                  _LegendDot(label: 'Esta sem.', color: Color(0xFF0190DC)),
                  _LegendDot(label: 'N/A', color: Color(0xFF1E293B)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SideShortcut(
                      label: 'Superior',
                      icon: Icons.north_rounded,
                      onTap: () => _jumpTo(Alignment.topCenter),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _SideShortcut(
                      label: 'Derecha',
                      icon: Icons.east_rounded,
                      onTap: () => _jumpTo(Alignment.centerRight),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _SideShortcut(
                      label: 'Inferior',
                      icon: Icons.south_rounded,
                      onTap: () => _jumpTo(Alignment.bottomCenter),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _SideShortcut(
                      label: 'Izquierda',
                      icon: Icons.west_rounded,
                      onTap: () => _jumpTo(Alignment.centerLeft),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _C.stroke),
      ),
      child: Icon(icon, size: 16, color: _C.primary),
    ),
  );
}

class _SideShortcut extends StatelessWidget {
  const _SideShortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _C.primary),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _C.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Vista planta del edificio ──────────────────────────────────────────────────

class _BuildingPlanView extends StatelessWidget {
  const _BuildingPlanView({
    required this.groups,
    required this.data,
    required this.ctrl,
  });
  final _Phase1Groups groups;
  final AvanceGraficoPhase1Data data;
  final AppController ctrl;

  static const _baseCellH = 26.0;
  static const _baseCellW = 30.0;
  static const _cellM = 1.0; // margin each side

  @override
  Widget build(BuildContext context) {
    // Total paños across horizontal sides (top / bottom)
    final topBays = groups.top.fold(0, (s, sec) => s + sec.bays);
    final botBays = groups.bottom.fold(0, (s, sec) => s + sec.bays);
    final maxHBays = max(topBays, botBays);

    // Total niveles across vertical sides (left / right)
    final leftLvl = groups.left.fold(0, (s, sec) => s + sec.levels);
    final rightLvl = groups.right.fold(0, (s, sec) => s + sec.levels);
    final maxVLvl = max(leftLvl, rightLvl);

    // Center height = driven by vertical cells (min 120 px)
    final ctrH = max(120.0, maxVLvl * (_baseCellH + _cellM * 2));
    // Center width = height × aspect ratio per shapeCode
    final aspect = data.shapeCode == 1
        ? 0.55
        : data.shapeCode == 2
        ? 1.8
        : 1.0;
    final ctrW = ctrH * aspect;

    // Horizontal cell width: spread centerW across all horizontal paños
    final hCellW = maxHBays > 0
        ? (ctrW / maxHBays).clamp(20.0, 80.0)
        : _baseCellW;
    // Vertical cell height: spread centerH across all vertical levels
    final vCellH = maxVLvl > 0
        ? (ctrH / maxVLvl).clamp(16.0, 80.0)
        : _baseCellH;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _HorizontalSide(
            sideCode: 1,
            sideKey: 'SUPERIOR',
            sections: groups.top,
            data: data,
            ctrl: ctrl,
            cellW: hCellW,
            cellH: _baseCellH,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _VerticalSide(
                sideCode: 3,
                sideKey: 'IZQUIERDA',
                sections: groups.left,
                data: data,
                ctrl: ctrl,
                rotTurns: 3,
                cellW: _baseCellW,
                cellH: vCellH,
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: ctrW,
                height: ctrH,
                child: _BuildingCenter(
                  shapeLabel: data.shapeLabel,
                  directionLabel: data.directionLabel,
                  completed: data.completedPositions,
                  total: data.totalPositions,
                ),
              ),
              const SizedBox(width: 6),
              _VerticalSide(
                sideCode: 4,
                sideKey: 'DERECHA',
                sections: groups.right,
                data: data,
                ctrl: ctrl,
                rotTurns: 1,
                cellW: _baseCellW,
                cellH: vCellH,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HorizontalSide(
            sideCode: 2,
            sideKey: 'INFERIOR',
            sections: groups.bottom,
            data: data,
            ctrl: ctrl,
            cellW: hCellW,
            cellH: _baseCellH,
          ),
        ],
      ),
    );
  }
}

class _HorizontalSide extends StatelessWidget {
  const _HorizontalSide({
    required this.sideCode,
    required this.sideKey,
    required this.sections,
    required this.data,
    required this.ctrl,
    required this.cellW,
    required this.cellH,
  });
  final int sideCode;
  final String sideKey;
  final List<AvanceGraficoPhase1Section> sections;
  final AvanceGraficoPhase1Data data;
  final AppController ctrl;
  final double cellW, cellH;

  @override
  Widget build(BuildContext context) {
    final names = sections.map((s) => s.name).join(' / ');
    final label = names.isEmpty ? sideKey : '$sideKey — $names';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 7,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w700,
            color: _C.muted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.isEmpty
              ? [
                  _EmptySideCell(
                    onTap: () => _showAddSectionSheet(
                      context,
                      sideCode: sideCode,
                      data: data,
                      ctrl: ctrl,
                    ),
                  ),
                ]
              : sections
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _SectionCells(
                          section: s,
                          ctrl: ctrl,
                          cellW: cellW,
                          cellH: cellH,
                        ),
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }
}

class _VerticalSide extends StatelessWidget {
  const _VerticalSide({
    required this.sideCode,
    required this.sideKey,
    required this.sections,
    required this.data,
    required this.ctrl,
    required this.rotTurns,
    required this.cellW,
    required this.cellH,
  });
  final int sideCode;
  final String sideKey;
  final List<AvanceGraficoPhase1Section> sections;
  final AvanceGraficoPhase1Data data;
  final AppController ctrl;
  final int rotTurns;
  final double cellW, cellH;

  @override
  Widget build(BuildContext context) {
    final names = sections.map((s) => s.name).join(' / ');
    final label = names.isEmpty ? sideKey : '$sideKey — $names';
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: rotTurns,
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 7,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
              color: _C.muted,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: sections.isEmpty
              ? [
                  _EmptySideCell(
                    onTap: () => _showAddSectionSheet(
                      context,
                      sideCode: sideCode,
                      data: data,
                      ctrl: ctrl,
                    ),
                  ),
                ]
              : sections
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _SectionCells(
                          section: s,
                          ctrl: ctrl,
                          cellW: cellW,
                          cellH: cellH,
                        ),
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }
}

class _EmptySideCell extends StatelessWidget {
  const _EmptySideCell({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 64,
      height: 48,
      decoration: BoxDecoration(
        color: _C.accent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _C.primary.withValues(alpha: 0.45),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_circle_outline_rounded,
            size: 18,
            color: _C.primary,
          ),
          const SizedBox(height: 3),
          Text(
            'Agregar\nsección',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 7,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: _C.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionCells extends StatelessWidget {
  const _SectionCells({
    required this.section,
    required this.ctrl,
    required this.cellW,
    required this.cellH,
  });
  final AvanceGraficoPhase1Section section;
  final AppController ctrl;
  final double cellW, cellH;

  @override
  Widget build(BuildContext context) {
    final byLevel = <int, List<AvanceGraficoPhase1Cell>>{};
    for (final c in section.cells) {
      byLevel.putIfAbsent(c.level, () => []).add(c);
    }
    final levels = byLevel.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: levels
          .map(
            (lvl) => Row(
              mainAxisSize: MainAxisSize.min,
              children: (byLevel[lvl]!..sort((a, b) => a.bay.compareTo(b.bay)))
                  .map(
                    (c) => GestureDetector(
                      onTap: () =>
                          ctrl.cycleAvanceGraficoPhase1PositionStatus(c.id),
                      child: _CellBox(cell: c, cellW: cellW, cellH: cellH),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}

class _CellBox extends StatelessWidget {
  const _CellBox({
    required this.cell,
    required this.cellW,
    required this.cellH,
  });
  final AvanceGraficoPhase1Cell cell;
  final double cellW, cellH;

  @override
  Widget build(BuildContext context) {
    final isNA = cell.statusCode == 4;
    final isLight = cell.statusCode == 1;
    final label = isNA ? '---' : '${cell.level}.${cell.bay}';
    return Container(
      width: cellW,
      height: cellH,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _hexColor(cell.colorHex),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: (cellH * 0.28).clamp(6.0, 10.0),
            fontWeight: FontWeight.w700,
            color: isLight ? const Color(0xFF334155) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BuildingCenter extends StatelessWidget {
  const _BuildingCenter({
    required this.shapeLabel,
    required this.directionLabel,
    required this.completed,
    required this.total,
  });
  final String shapeLabel, directionLabel;
  final int completed, total;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1E3A5F),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x440A2040),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'FASE 1',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$completed / $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$directionLabel · $shapeLabel',
          style: const TextStyle(color: Colors.white54, fontSize: 8),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHEET DE CONFIGURACION CENTRALIZADA
// ═══════════════════════════════════════════════════════════════════════════════

void _showConfigSheet(
  BuildContext context, {
  required AvanceGraficoPhase1Data data,
  required AppController ctrl,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ConfigSheet(data: data, ctrl: ctrl),
  );
}

class _ConfigSheet extends StatefulWidget {
  const _ConfigSheet({required this.data, required this.ctrl});
  final AvanceGraficoPhase1Data data;
  final AppController ctrl;
  @override
  State<_ConfigSheet> createState() => _ConfigSheetState();
}

class _ConfigSheetState extends State<_ConfigSheet> {
  bool _shapeExpanded = false;
  bool _dirExpanded = false;
  bool _lvlExpanded = false;
  bool _orderExpanded = false;
  late bool _globalLevelsEnabled;
  late int _globalLevels;
  late int _shapeCode;
  late int _directionCode;

  // Orden de secciones (1=Superior, 2=Inferior, 3=Izq, 4=Der)
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    _shapeCode = widget.data.shapeCode;
    _directionCode = widget.data.directionCode;
    _globalLevelsEnabled = widget.data.globalLevelsEnabled;
    _globalLevels = widget.data.globalLevelsCount <= 0
        ? 1
        : widget.data.globalLevelsCount;
    _order = [1, 4, 2, 3];
  }

  void _schedulePhase1SettingsSync() {
    widget.ctrl.scheduleAvanceGraficoPhase1SettingsUpdate(
      phaseId: widget.data.phaseId,
      codForma: _shapeCode,
      codSentido: _directionCode,
      globalLevelsEnabled: _globalLevelsEnabled,
      globalLevelsCount: _globalLevels,
    );
  }

  String _sideLabel(int code) {
    const m = {1: 'Superior', 2: 'Inferior', 3: 'Izquierda', 4: 'Derecha'};
    return m[code] ?? '';
  }

  String _shapeLabel(int code) {
    switch (code) {
      case 1:
        return 'Rectángulo Vertical';
      case 2:
        return 'Rectángulo Horizontal';
      case 3:
        return 'Cuadrado';
      default:
        return 'Sin definir';
    }
  }

  String _directionLabel(int code) {
    switch (code) {
      case 1:
        return 'Horario';
      case 2:
        return 'Antihorario';
      default:
        return 'Sin definir';
    }
  }

  AvanceGraficoPhase1Section? _sectionForSide(int code) =>
      widget.data.sections.where((s) => s.sideCode == code).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final ctrl = widget.ctrl;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Administrar Fase 1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: _C.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.all(16),
                children: [
                  // ── FORMA CENTRAL ──────────────────────────────────────────
                  _ConfigSection(
                    icon: Icons.crop_landscape_rounded,
                    title: 'Forma central',
                    subtitle: _shapeLabel(_shapeCode),
                    expanded: _shapeExpanded,
                    onToggle: () =>
                        setState(() => _shapeExpanded = !_shapeExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ShapeCard(
                              icon: Icons.crop_portrait_rounded,
                              label: 'Rectángulo\nVertical',
                              active: _shapeCode == 1,
                              onTap: () {
                                setState(() => _shapeCode = 1);
                                _schedulePhase1SettingsSync();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ShapeCard(
                              icon: Icons.crop_landscape_rounded,
                              label: 'Rectángulo\nHorizontal',
                              active: _shapeCode == 2,
                              onTap: () {
                                setState(() => _shapeCode = 2);
                                _schedulePhase1SettingsSync();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ShapeCard(
                              icon: Icons.square_rounded,
                              label: 'Cuadrado',
                              active: _shapeCode == 3,
                              onTap: () {
                                setState(() => _shapeCode = 3);
                                _schedulePhase1SettingsSync();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── SENTIDO ────────────────────────────────────────────────
                  _ConfigSection(
                    icon: Icons.rotate_right_rounded,
                    title: 'Sentido de numeración',
                    subtitle: _directionLabel(_directionCode),
                    expanded: _dirExpanded,
                    onToggle: () =>
                        setState(() => _dirExpanded = !_dirExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DirCard(
                              icon: Icons.rotate_right_rounded,
                              label: 'Horario',
                              active: _directionCode == 1,
                              onTap: () {
                                setState(() => _directionCode = 1);
                                _schedulePhase1SettingsSync();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DirCard(
                              icon: Icons.rotate_left_rounded,
                              label: 'Antihorario',
                              active: _directionCode == 2,
                              onTap: () {
                                setState(() => _directionCode = 2);
                                _schedulePhase1SettingsSync();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── NIVELES GLOBALES ───────────────────────────────────────
                  _ConfigSection(
                    icon: Icons.layers_rounded,
                    title: 'Mismos niveles para todos',
                    subtitle: _globalLevelsEnabled
                        ? '$_globalLevels niveles — todos los lados'
                        : 'Deshabilitado',
                    expanded: _lvlExpanded,
                    onToggle: () =>
                        setState(() => _lvlExpanded = !_lvlExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: _C.muted,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Al habilitar, todos los lados tendrán la misma cantidad de niveles y no podrá modificarse por sección.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _C.muted,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            value: _globalLevelsEnabled,
                            onChanged: (v) {
                              setState(() => _globalLevelsEnabled = v);
                              _schedulePhase1SettingsSync();
                            },
                            title: const Text(
                              'Habilitar niveles globales',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.text,
                              ),
                            ),
                            dense: true,
                            activeThumbColor: _C.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_globalLevelsEnabled) ...[
                            const SizedBox(height: 10),
                            _Stepper(
                              label: 'Niveles (aplicado a todos los lados)',
                              value: _globalLevels,
                              min: 1,
                              max: 30,
                              onChanged: (v) {
                                setState(() => _globalLevels = v);
                                _schedulePhase1SettingsSync();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── SECCIONES POR LADO ─────────────────────────────────────
                  ...[1, 4, 2, 3].map((sideCode) {
                    final section = _sectionForSide(sideCode);
                    final hasSection = section != null;
                    final locked = _globalLevelsEnabled ? _globalLevels : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SectionRow(
                        sideCode: sideCode,
                        sideLabel: _sideLabel(sideCode),
                        section: section,
                        onAdd: () {
                          Navigator.pop(context);
                          _showAddSectionSheet(
                            context,
                            sideCode: sideCode,
                            data: data,
                            ctrl: ctrl,
                            lockedLevels: locked,
                          );
                        },
                        onDelete: hasSection
                            ? () {
                                ctrl.deleteAvanceGraficoPhase1Section(
                                  section.id,
                                );
                                Navigator.pop(context);
                              }
                            : null,
                        onEdit: hasSection
                            ? () {
                                Navigator.pop(context);
                                _showAddSectionSheet(
                                  context,
                                  sideCode: sideCode,
                                  data: data,
                                  ctrl: ctrl,
                                  existing: section,
                                  lockedLevels: locked,
                                );
                              }
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  // ── ORDEN DE SECCIONES ─────────────────────────────────────
                  _ConfigSection(
                    icon: Icons.sort_rounded,
                    title: 'Orden de secciones',
                    subtitle: _order.map(_sideLabel).join(' > '),
                    expanded: _orderExpanded,
                    onToggle: () =>
                        setState(() => _orderExpanded = !_orderExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          ...[
                            ('Primero', 0),
                            ('Segundo', 1),
                            ('Tercero', 2),
                            ('Cuarto', 3),
                          ].map(
                            ((String lbl, int i) pair) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      pair.$1,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _C.text,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _C.stroke),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _order[pair.$2],
                                          items: [1, 4, 2, 3]
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(_sideLabel(c)),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) {
                                              return;
                                            }
                                            setState(() => _order[pair.$2] = v);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _C.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    ctrl.updateAvanceGraficoPhase1SectionOrder(
                                      data.phaseId,
                                      _order,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Guardar orden'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _C.amber,
                                  side: const BorderSide(color: _C.amber),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _order = [1, 4, 2, 3]),
                                child: const Text('Limpiar'),
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
          ],
        ),
      ),
    );
  }
}

// Item colapsable de sección por lado
class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.sideCode,
    required this.sideLabel,
    required this.section,
    required this.onAdd,
    this.onDelete,
    this.onEdit,
  });
  final int sideCode;
  final String sideLabel;
  final AvanceGraficoPhase1Section? section;
  final VoidCallback onAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final hasSection = section != null;
    final sub = hasSection
        ? '${section!.name} · ${section!.levels} niveles · ${section!.bays} paños'
        : 'Sin sección — toca para agregar';
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.stroke),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: hasSection ? const Color(0xFFE6F4EA) : _C.bg,
          child: Icon(
            hasSection ? Icons.check_rounded : Icons.add_rounded,
            size: 16,
            color: hasSection ? _C.teal : _C.faint,
          ),
        ),
        title: Text(
          'Sección $sideLabel',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _C.text,
          ),
        ),
        subtitle: Text(
          sub,
          style: const TextStyle(fontSize: 11, color: _C.muted),
        ),
        trailing: hasSection
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: _C.faint),
                ],
              )
            : const Icon(Icons.chevron_right_rounded, color: _C.faint),
        onTap: hasSection ? onEdit : onAdd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// Tile colapsable de configuracion
class _ConfigSection extends StatelessWidget {
  const _ConfigSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });
  final IconData icon;
  final String title, subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.stroke),
    ),
    child: Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE6F4EA),
            child: Icon(Icons.check_rounded, size: 16, color: _C.teal),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _C.text,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: _C.muted),
          ),
          trailing: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: _C.faint,
          ),
          onTap: onToggle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
      ],
    ),
  );
}

class _ShapeCard extends StatelessWidget {
  const _ShapeCard({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: active ? _C.accent : _C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? _C.primary : _C.stroke,
          width: active ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: active ? _C.primary : _C.muted),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? _C.primary : _C.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DirCard extends StatelessWidget {
  const _DirCard({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? _C.accent : _C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? _C.primary : _C.stroke,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: active ? _C.primary : _C.muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? _C.primary : _C.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

// Sheet: agregar / editar sección
void _showAddSectionSheet(
  BuildContext context, {
  required int sideCode,
  required AvanceGraficoPhase1Data data,
  required AppController ctrl,
  AvanceGraficoPhase1Section? existing,
  int? lockedLevels, // when set, levels are fixed globally and cannot be edited
}) {
  const sideLabels = {
    1: 'Superior',
    2: 'Inferior',
    3: 'Izquierda',
    4: 'Derecha',
  };
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final abbrCtrl = TextEditingController(text: existing?.abbreviation ?? '');
  int levels = lockedLevels ?? existing?.levels ?? 2;
  int bays = existing?.bays ?? 3;
  final isEdit = existing != null;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_box_rounded,
                  color: _C.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isEdit ? "Editar" : "Nueva"} sección — ${sideLabels[sideCode] ?? ""}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: !isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del lado',
                hintText: 'ej. Fachada Norte',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (v) {
                if (!isEdit) {
                  abbrCtrl.text = v
                      .trim()
                      .split(' ')
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join();
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: abbrCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Abreviatura',
                hintText: 'ej. FN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: lockedLevels != null
                        ? 'Niveles (global 🔒)'
                        : 'Niveles',
                    value: levels,
                    min: 1,
                    max: 30,
                    onChanged: lockedLevels != null
                        ? null
                        : (v) => setState(() => levels = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stepper(
                    label: 'Paños',
                    value: bays,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => bays = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: Icon(isEdit ? Icons.save_rounded : Icons.add, size: 16),
                label: Text(
                  isEdit ? 'Guardar cambios' : 'Crear sección',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  final abbr = abbrCtrl.text.trim().isEmpty
                      ? name
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                            .join()
                      : abbrCtrl.text.trim();
                  Navigator.pop(ctx);
                  if (isEdit) {
                    ctrl.updateAvanceGraficoPhase1Section(
                      sectionId: existing.id,
                      name: name,
                      abbreviation: abbr,
                      levels: levels,
                      bays: bays,
                    );
                  } else {
                    ctrl.addAvanceGraficoPhase1Section(
                      name: name,
                      abbreviation: abbr,
                      sideCode: sideCode,
                      levels: levels,
                      bays: bays,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value, min, max;
  final ValueChanged<int>? onChanged; // null = locked/disabled

  bool get _locked => onChanged == null;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: _locked ? 0.5 : 1.0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _C.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _C.stroke),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: (!_locked && value > min)
                    ? () => onChanged!(value - 1)
                    : null,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.text,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: (!_locked && value < max)
                    ? () => onChanged!(value + 1)
                    : null,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FASE 2 — InteractiveViewer global (todas las actividades lado a lado)
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase2Campo extends StatefulWidget {
  const _Phase2Campo({
    required this.data,
    required this.ctrl,
    required this.states,
  });
  final AvanceGraficoPhase2Data data;
  final AppController ctrl;
  final List<AvanceGraficoStateCatalog> states;
  @override
  State<_Phase2Campo> createState() => _Phase2CampoState();
}

class _Phase2CampoState extends State<_Phase2Campo> {
  final TransformationController _tc = TransformationController();
  double _currentScale = 1.0;
  Size? _vpSize;
  Size? _contentSize;
  final _contentKey = GlobalKey();
  late List<GlobalKey> _activityKeys;
  late List<bool> _statsOpen;
  bool _panelOpen = false;
  int _selectedIdx = -1;
  int _activeStateCode = 6; // estado "pincel" activo (default: Completado)

  List<AvanceGraficoStateCatalog> get _phase2States => widget.states
      .where((state) => state.phaseKey == 'FaseDos_Cuadros')
      .toList(growable: false);

  int _resolveDefaultPhase2StateCode() {
    final phaseStates = _phase2States;
    for (final state in phaseStates) {
      if (state.label.trim().toLowerCase() == 'completado') {
        return state.code;
      }
    }
    if (phaseStates.isNotEmpty) {
      return phaseStates.first.code;
    }
    return _activeStateCode;
  }

  @override
  void initState() {
    super.initState();
    _activeStateCode = _resolveDefaultPhase2StateCode();
    _initLists(widget.data.activities.length);
    _tc.addListener(_syncScale);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndFit());
  }

  @override
  void didUpdateWidget(_Phase2Campo old) {
    super.didUpdateWidget(old);
    final n = widget.data.activities.length;
    final oldN = old.data.activities.length;
    if (n != oldN) {
      _initLists(n);
      // Solo recentramos cuando cambia la cantidad de actividades (config)
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndFit());
    }
    if (!_phase2States.any((state) => state.code == _activeStateCode)) {
      _activeStateCode = _resolveDefaultPhase2StateCode();
    }
  }

  @override
  void dispose() {
    _tc.removeListener(_syncScale);
    _tc.dispose();
    super.dispose();
  }

  void _initLists(int n) {
    _activityKeys = List.generate(n, (_) => GlobalKey());
    _statsOpen = List.filled(n, false);
  }

  void _syncScale() {
    final s = _tc.value.getMaxScaleOnAxis();
    if (mounted && (_currentScale - s).abs() > 0.005) {
      setState(() => _currentScale = s);
    }
  }

  void _measureAndFit() {
    if (!mounted) return;
    final ctx = _contentKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    _contentSize = box.size;
    _applyFit();
  }

  Matrix4 _m(double s, double vw, double vh, double cw, double ch) {
    final tx = (vw - cw * s) / 2;
    final ty = (vh - ch * s) / 2;
    return Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  void _applyFit() {
    final vp = _vpSize;
    final cs = _contentSize;
    if (vp == null || cs == null || !mounted) return;
    final s =
        ((vp.width / cs.width) < (vp.height / cs.height)
                ? vp.width / cs.width
                : vp.height / cs.height)
            .clamp(0.1, 1.5);
    setState(() => _currentScale = s);
    _tc.value = _m(s, vp.width, vp.height, cs.width, cs.height);
  }

  void _zoom(double factor) {
    final s = (_currentScale * factor).clamp(0.1, 4.0);
    setState(() => _currentScale = s);
    final vp = _vpSize;
    final cs = _contentSize;
    if (vp != null && cs != null) {
      _tc.value = _m(s, vp.width, vp.height, cs.width, cs.height);
    } else {
      _tc.value = Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    }
  }

  void _panToActivity(int idx) {
    if (idx >= _activityKeys.length) return;
    // 1. Abre indicadores y marca selección → rebuild con stats visibles
    setState(() {
      _selectedIdx = idx;
      if (idx < _statsOpen.length) _statsOpen[idx] = true;
    });
    // 2. Doble postFrameCallback: primer frame pinta stats, segundo frame tiene
    //    el layout completo con el nuevo tamaño del bloque.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _zoomToActivity(idx));
    });
  }

  void _zoomToActivity(int idx) {
    if (!mounted || idx >= _activityKeys.length) return;
    final actCtx = _activityKeys[idx].currentContext;
    final cntCtx = _contentKey.currentContext;
    final vp = _vpSize;
    if (actCtx == null || cntCtx == null || vp == null) return;
    final actBox = actCtx.findRenderObject() as RenderBox?;
    final cntBox = cntCtx.findRenderObject() as RenderBox?;
    if (actBox == null || cntBox == null || !actBox.hasSize) return;

    // localToGlobal devuelve coordenadas de pantalla (ya escaladas por el viewer).
    // Para obtener posición en espacio de contenido dividimos por la escala actual.
    final curS = _tc.value.getMaxScaleOnAxis();
    final actPos = actBox.localToGlobal(Offset.zero);
    final cntPos = cntBox.localToGlobal(Offset.zero);
    final contentX = (actPos.dx - cntPos.dx) / curS;
    final contentY = (actPos.dy - cntPos.dy) / curS;

    // actBox.size está en espacio de contenido (sin escalar).
    final actW = actBox.size.width;
    final actH = actBox.size.height;

    // Escala que encaja la actividad en toda la pantalla (el panel flota encima).
    final vpW = vp.width;
    final vpH = vp.height;
    final scaleW = (vpW * 0.92) / actW;
    final scaleH = (vpH * 0.88) / actH;
    final s = (scaleW < scaleH ? scaleW : scaleH).clamp(0.3, 5.0);

    setState(() => _currentScale = s);

    // Centrar en el viewport completo, ignorando el panel (es un overlay encima).
    final tx = vpW / 2 - (contentX + actW / 2) * s;
    final ty = vpH / 2 - (contentY + actH / 2) * s;
    _tc.value = Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final ctrl = widget.ctrl;
    final maxGraphicRows = data.activities.isEmpty
        ? 0
        : data.activities
              .map(
                (activity) =>
                    activity.cells.map((cell) => cell.floor).toSet().length,
              )
              .reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header global ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.stroke),
          ),
          child: Row(
            children: [
              // Indicador pisos uniformes (compacto)
              if (data.uniformFloorsEnabled) ...[
                const Icon(Icons.layers_rounded, size: 13, color: _C.primary),
                const SizedBox(width: 3),
                Text(
                  '${data.uniformFloorsCount}p',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _C.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 14, color: _C.stroke),
                const SizedBox(width: 8),
              ],
              _InfoTag(
                Icons.task_alt_rounded,
                '${data.completedCount}/${data.totalCells}',
              ),
              const Spacer(),
              // Zoom en header
              _ZoomBtn(icon: Icons.zoom_out, onTap: () => _zoom(0.8)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _applyFit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _C.stroke),
                  ),
                  child: Text(
                    '${(_currentScale * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _C.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _ZoomBtn(icon: Icons.zoom_in, onTap: () => _zoom(1.25)),
              const SizedBox(width: 8),
              // Config
              GestureDetector(
                onTap: () =>
                    _showPhase2ConfigSheet(context, data: data, ctrl: ctrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Config.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Viewer + overlays ─────────────────────────────────────────────
        Expanded(
          child: data.activities.isEmpty
              ? const _EmptyPhase()
              : Stack(
                  children: [
                    // InteractiveViewer global
                    LayoutBuilder(
                      builder: (ctx, cons) {
                        _vpSize = Size(cons.maxWidth, cons.maxHeight);
                        return ClipRect(
                          child: InteractiveViewer(
                            transformationController: _tc,
                            constrained: false,
                            panEnabled: true,
                            scaleEnabled: true,
                            minScale: 0.05,
                            maxScale: 5.0,
                            boundaryMargin: const EdgeInsets.all(400),
                            child: Padding(
                              key: _contentKey,
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (
                                    int i = 0;
                                    i < data.activities.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      SizedBox(width: cons.maxWidth * 0.9),
                                    KeyedSubtree(
                                      key: _activityKeys[i],
                                      child: _ActivityBlock(
                                        activity: data.activities[i],
                                        states: widget.states,
                                        ctrl: widget.ctrl,
                                        statsOpen:
                                            i < _statsOpen.length &&
                                            _statsOpen[i],
                                        maxGraphicRows: maxGraphicRows,
                                        activeStateCode: _activeStateCode,
                                        onStatsToggle: () {
                                          setState(() {
                                            if (i < _statsOpen.length) {
                                              _statsOpen[i] = !_statsOpen[i];
                                            }
                                            _selectedIdx = i;
                                          });
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback(
                                                      (_) => _zoomToActivity(i),
                                                    );
                                              });
                                        },
                                        onCellTap: (cell) {
                                          widget.ctrl
                                              .updateAvanceGraficoPhase2CellState(
                                                cellId: cell.id,
                                                newStatusCode: _activeStateCode,
                                              );
                                        },
                                        onCellDoubleTap: (cell) {
                                          final cycle = _phase2States
                                              .map((state) => state.code)
                                              .toList(growable: false);
                                          if (cycle.isEmpty) {
                                            return;
                                          }
                                          final idx = cycle.indexOf(
                                            cell.statusCode,
                                          );
                                          final next =
                                              cycle[(idx + 1) % cycle.length];
                                          setState(
                                            () => _activeStateCode = next,
                                          );
                                          widget.ctrl
                                              .updateAvanceGraficoPhase2CellState(
                                                cellId: cell.id,
                                                newStatusCode: next,
                                              );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Backdrop: cierra el panel al tocar encima del sheet
                    if (_panelOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _panelOpen = false);
                          },
                          child: Container(color: const Color(0x33000000)),
                        ),
                      ),
                    // Panel de actividades (bottom sheet deslizable)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOut,
                      left: 0,
                      right: 0,
                      bottom: _panelOpen
                          ? 0
                          : -(MediaQuery.of(context).size.height * 0.50),
                      height: MediaQuery.of(context).size.height * 0.50,
                      child: _ActivityBottomPanel(
                        activities: data.activities,
                        onSelect: (idx) {
                          FocusManager.instance.primaryFocus?.unfocus();
                          setState(() {
                            _panelOpen = false;
                            if (idx == -1) _selectedIdx = -1;
                          });
                          if (idx == -1) {
                            _measureAndFit();
                          } else {
                            _panToActivity(idx);
                          }
                        },
                        selectedIdx: _selectedIdx,
                      ),
                    ),
                    // FAB esquina inferior derecha
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: GestureDetector(
                        onTap: () => setState(() => _panelOpen = !_panelOpen),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _panelOpen ? _C.muted : _C.primary,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x44000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _panelOpen ? Icons.close : Icons.view_list_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        // ── Leyenda / indicador de estado activo ──────────────────────────
        Container(
          width: double.infinity,
          color: _C.surface,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: _phase2States.map((s) {
              final isActive = s.code == _activeStateCode;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 7 : 4,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? _hexColor(s.colorHex).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isActive
                      ? Border.all(color: _hexColor(s.colorHex), width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _hexColor(s.colorHex),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w400,
                        color: isActive ? _C.text : _C.muted,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _C.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Bottom sheet de actividades con buscador ─────────────────────────────────

class _ActivityBottomPanel extends StatefulWidget {
  const _ActivityBottomPanel({
    required this.activities,
    required this.onSelect,
    required this.selectedIdx,
  });
  final List<AvanceGraficoPhase2Activity> activities;
  final ValueChanged<int> onSelect;
  final int selectedIdx;

  @override
  State<_ActivityBottomPanel> createState() => _ActivityBottomPanelState();
}

class _ActivityBottomPanelState extends State<_ActivityBottomPanel> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = <(int, AvanceGraficoPhase2Activity)>[];
    for (var i = 0; i < widget.activities.length; i++) {
      final act = widget.activities[i];
      if (_query.isEmpty ||
          act.name.toLowerCase().contains(_query.toLowerCase()) ||
          act.abbreviation.toLowerCase().contains(_query.toLowerCase())) {
        filtered.add((i, act));
      }
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 16,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Handle ───────────────────────────────────────────────────
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: _C.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Buscador ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, color: _C.text),
                decoration: InputDecoration(
                  hintText: 'Buscar actividad...',
                  hintStyle: const TextStyle(fontSize: 13, color: _C.faint),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: _C.muted,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 14,
                            color: _C.muted,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _C.bg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _C.stroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _C.stroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _C.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            // ── Lista ────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 14,
                ),
                // +1 por el ítem "Ver Todas las Actividades"
                itemCount: filtered.isEmpty ? 1 : filtered.length + 1,
                itemBuilder: (ctx, fi) {
                  // Ítem 0 → "Ver Todas las Actividades"
                  if (fi == 0) {
                    final isAll = widget.selectedIdx == -1;
                    return InkWell(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        widget.onSelect(-1);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isAll ? _C.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAll ? _C.primary : Colors.transparent,
                            width: isAll ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isAll
                                    ? _C.primary
                                    : _C.muted.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.apps_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Ver Todas las Actividades',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isAll
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isAll ? _C.primary : _C.text,
                                ),
                              ),
                            ),
                            if (isAll)
                              const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: _C.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  final (origIdx, act) = filtered[fi - 1];
                  final isSelected = origIdx == widget.selectedIdx;
                  return InkWell(
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      widget.onSelect(origIdx);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _C.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _C.primary : Colors.transparent,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _C.primary
                                  : _C.muted.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              act.abbreviation.isEmpty ? '?' : act.abbreviation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              act.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? _C.primary : _C.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.my_location_rounded,
                                size: 14,
                                color: _C.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ), // Container
    ); // GestureDetector
  }
}

// ─── Bloque por actividad (dentro del InteractiveViewer global, sin fondo) ─────

class _ActivityBlock extends StatelessWidget {
  const _ActivityBlock({
    required this.activity,
    required this.states,
    required this.ctrl,
    required this.statsOpen,
    required this.maxGraphicRows,
    required this.activeStateCode,
    required this.onStatsToggle,
    required this.onCellTap,
    required this.onCellDoubleTap,
  });
  final AvanceGraficoPhase2Activity activity;
  final List<AvanceGraficoStateCatalog> states;
  final AppController ctrl;
  final bool statsOpen;
  final int maxGraphicRows;
  final int activeStateCode;
  final VoidCallback onStatsToggle;
  final ValueChanged<AvanceGraficoPhase2Cell> onCellTap;
  final ValueChanged<AvanceGraficoPhase2Cell> onCellDoubleTap;

  @override
  Widget build(BuildContext context) {
    final em = (MediaQuery.of(context).size.shortestSide / 28.0).clamp(
      13.0,
      28.0,
    );
    final act = activity;
    final floors = act.cells.map((c) => c.floor).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final sectors = act.cells.map((c) => c.sector).toSet().toList()..sort();
    final cellMap = {for (final c in act.cells) '${c.floor}:${c.sector}': c};
    final total = act.totalCells;
    final totalAllStates =
        act.pendingCount +
        act.inProgressCount +
        act.scheduledCount +
        act.completedCount +
        act.approvedCount +
        act.notApplicableCount;
    final pctComp = total == 0 ? 0.0 : act.completedCount / total;
    final pctFin = totalAllStates == 0
        ? 0.0
        : act.approvedCount / totalAllStates;
    // Ancho de la grilla usando misma fórmula que _ActivityGrid (+ etiqueta PISOS)
    final labelW = em * 3.4;
    final colW = em * 2.0;
    final pisosCol = em * 1.5; // espacio para la etiqueta rotada "PISOS"
    final gridW =
        pisosCol +
        (sectors.isEmpty ? em * 9.0 : (labelW + sectors.length * colW));
    final panelW = max(gridW, em * 17.0);
    final graphicHeight = _activityGraphicHeight(
      rows: max(maxGraphicRows, floors.length),
      em: em,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (mismo ancho que la grilla, botón pegado a la derecha) ──
        SizedBox(
          width: gridW,
          child: Row(
            children: [
              if (act.abbreviation.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: em * 0.55,
                    vertical: em * 0.22,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primary,
                    borderRadius: BorderRadius.circular(em * 0.4),
                  ),
                  child: Text(
                    act.abbreviation,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: em * 0.68,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: em * 0.4),
              ],
              Expanded(
                child: Text(
                  act.name.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: em * 0.72,
                    fontWeight: FontWeight.w800,
                    color: _C.text,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(width: em * 0.3),
              GestureDetector(
                onTap: onStatsToggle,
                child: Container(
                  padding: EdgeInsets.all(em * 0.3),
                  decoration: BoxDecoration(
                    color: statsOpen ? _C.primary : _C.bg,
                    borderRadius: BorderRadius.circular(em * 0.45),
                    border: Border.all(
                      color: statsOpen ? _C.primary : _C.stroke,
                    ),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: em * 0.85,
                    color: statsOpen ? Colors.white : _C.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: em * 0.6),
        // ── Grilla ───────────────────────────────────────────────────
        SizedBox(
          height: graphicHeight,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: floors.isNotEmpty && sectors.isNotEmpty
                ? _ActivityGrid(
                    floors: floors,
                    sectors: sectors,
                    cellMap: cellMap,
                    onCellTap: onCellTap,
                    onCellDoubleTap: onCellDoubleTap,
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: em * 1.5,
                      horizontal: em * 0.6,
                    ),
                    child: Text(
                      'Sin celdas',
                      style: TextStyle(fontSize: em * 0.72, color: _C.faint),
                    ),
                  ),
          ),
        ),
        // ── Panel de indicadores (debajo del grid) ────────────────────
        if (statsOpen && floors.isNotEmpty) ...[
          SizedBox(height: em * 0.6),
          SizedBox(
            width: panelW,
            child: _StatsPanel(
              pctComp: pctComp,
              pctFin: pctFin,
              pending: act.pendingCount,
              inProgress: act.inProgressCount,
              scheduled: act.scheduledCount,
              completed: act.completedCount,
              approved: act.approvedCount,
              notApplicable: act.notApplicableCount,
            ),
          ),
        ],
      ],
    );
  }
}

double _activityGraphicHeight({required int rows, required double em}) {
  final safeRows = rows <= 0 ? 1 : rows;
  final cellH = em * 1.85;
  final rowGap = em * 0.15;
  final sectorsNumbersH = em * 0.95;
  final sectorsLabelH = em * 0.8;
  final bottomGap = em * 0.45;
  return (safeRows * (cellH + rowGap)) +
      bottomGap +
      sectorsNumbersH +
      sectorsLabelH;
}

// ─── Grilla de la actividad ───────────────────────────────────────────────────

class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid({
    required this.floors,
    required this.sectors,
    required this.cellMap,
    required this.onCellTap,
    required this.onCellDoubleTap,
  });
  final List<int> floors;
  final List<int> sectors;
  final Map<String, AvanceGraficoPhase2Cell> cellMap;
  final ValueChanged<AvanceGraficoPhase2Cell> onCellTap;
  final ValueChanged<AvanceGraficoPhase2Cell> onCellDoubleTap;

  @override
  Widget build(BuildContext context) {
    final em = (MediaQuery.of(context).size.shortestSide / 28.0).clamp(
      13.0,
      28.0,
    );
    final labelW = em * 3.4;
    final cellW = em * 1.85;
    final cellH = em * 1.85;
    final cellGap = em * 0.15;
    final colW = cellW + cellGap; // debe coincidir con em * 2.0 del header

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Etiqueta "PISOS" rotada ───────────────────────────────────
        Padding(
          padding: EdgeInsets.only(right: em * 0.4),
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'PISOS',
              style: TextStyle(
                fontSize: em * 0.52,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: _C.muted,
              ),
            ),
          ),
        ),
        // ── Grilla principal ──────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filas de pisos
            ...floors.map((floor) {
              final isB = floor <= 0;
              return Padding(
                padding: EdgeInsets.only(bottom: em * 0.15),
                child: Row(
                  children: [
                    Container(
                      width: labelW,
                      height: cellH,
                      padding: EdgeInsets.symmetric(horizontal: em * 0.3),
                      alignment: Alignment.center,
                      decoration: isB
                          ? BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(em * 0.35),
                            )
                          : null,
                      child: Text(
                        '$floor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: em * 0.62,
                          fontWeight: FontWeight.w800,
                          color: isB ? Colors.white : _C.muted,
                        ),
                      ),
                    ),
                    ...sectors.map((s) {
                      final cell = cellMap['$floor:$s'];
                      final cellColor = cell != null
                          ? _hexColor(cell.colorHex)
                          : const Color(0xFFE2EAF4);
                      return GestureDetector(
                        onTap: cell != null ? () => onCellTap(cell) : null,
                        onDoubleTap: cell != null
                            ? () => onCellDoubleTap(cell)
                            : null,
                        child: Container(
                          width: cellW,
                          height: cellH,
                          margin: EdgeInsets.only(left: cellGap),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(em * 0.28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            SizedBox(height: em * 0.3),
            // ── Números de sector ABAJO ───────────────────────────────
            Row(
              children: [
                SizedBox(width: labelW),
                ...sectors.map(
                  (s) => SizedBox(
                    width: colW,
                    child: Text(
                      '$s',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: em * 0.62,
                        fontWeight: FontWeight.w800,
                        color: _C.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Etiqueta "SECTORES" ───────────────────────────────────
            Row(
              children: [
                SizedBox(width: labelW),
                Text(
                  'SECTORES',
                  style: TextStyle(
                    fontSize: em * 0.52,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Panel de indicadores (lado derecho) ─────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.pctComp,
    required this.pctFin,
    required this.pending,
    required this.inProgress,
    required this.scheduled,
    required this.completed,
    required this.approved,
    required this.notApplicable,
  });
  final double pctComp, pctFin;
  final int pending, inProgress, scheduled, completed, approved, notApplicable;

  @override
  Widget build(BuildContext context) {
    final em = (MediaQuery.of(context).size.shortestSide / 28.0).clamp(
      13.0,
      28.0,
    );
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(em * 0.75),
        border: Border.all(color: _C.stroke),
      ),
      padding: EdgeInsets.symmetric(horizontal: em * 1.1, vertical: em * 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'INDICADORES',
            style: TextStyle(
              fontSize: em * 0.6,
              fontWeight: FontWeight.w800,
              color: _C.muted,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: em * 0.75),
          Row(
            children: [
              Expanded(
                child: _StatKpi(
                  value: '${(pctComp * 100).toStringAsFixed(1)}%',
                  label: 'COMPLETADO',
                  color: _C.green,
                ),
              ),
              SizedBox(width: em * 0.9),
              Expanded(
                child: _StatKpi(
                  value: '${(pctFin * 100).toStringAsFixed(1)}%',
                  label: 'FINALIZADO',
                  color: _C.teal,
                ),
              ),
              SizedBox(width: em * 0.9),
              Expanded(
                child: _StatKpi(
                  value:
                      '${pending + inProgress + scheduled + completed + approved + notApplicable}',
                  label: 'TOTAL',
                  color: _C.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: em * 0.9),
          const Divider(height: 1),
          SizedBox(height: em * 0.6),
          Row(
            children: [
              Expanded(
                child: _StatRow(
                  color: const Color(0xFFCBD5E1),
                  label: 'Pendiente',
                  count: pending,
                ),
              ),
              SizedBox(width: em * 0.6),
              Expanded(
                child: _StatRow(
                  color: const Color(0xFFF59E0B),
                  label: 'En proceso',
                  count: inProgress,
                ),
              ),
            ],
          ),
          SizedBox(height: em * 0.3),
          Row(
            children: [
              Expanded(
                child: _StatRow(
                  color: _C.green,
                  label: 'Completado',
                  count: completed,
                ),
              ),
              SizedBox(width: em * 0.6),
              Expanded(
                child: _StatRow(
                  color: _C.teal,
                  label: 'Aprobado',
                  count: approved,
                ),
              ),
            ],
          ),
          SizedBox(height: em * 0.3),
          Row(
            children: [
              Expanded(
                child: _StatRow(
                  color: _C.primary,
                  label: 'Programado',
                  count: scheduled,
                ),
              ),
              SizedBox(width: em * 0.6),
              Expanded(
                child: _StatRow(
                  color: _C.faint,
                  label: 'No aplica',
                  count: notApplicable,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatKpi extends StatelessWidget {
  const _StatKpi({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final em = (MediaQuery.of(context).size.shortestSide / 28.0).clamp(
      13.0,
      28.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: em * 1.1,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: em * 0.52,
            fontWeight: FontWeight.w700,
            color: _C.faint,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.color,
    required this.label,
    required this.count,
  });
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final em = (MediaQuery.of(context).size.shortestSide / 28.0).clamp(
      13.0,
      28.0,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: em * 0.2),
      child: Row(
        children: [
          Container(
            width: em * 0.6,
            height: em * 0.6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: em * 0.38),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: em * 0.65, color: _C.text),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: em * 0.65,
              fontWeight: FontWeight.w800,
              color: _C.text,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FASE 2 — Config sheet
// ═══════════════════════════════════════════════════════════════════════════════

void _showPhase2ConfigSheet(
  BuildContext context, {
  required AvanceGraficoPhase2Data data,
  required AppController ctrl,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _Phase2ConfigSheet(data: data, ctrl: ctrl),
  );
}

class _Phase2ConfigSheet extends StatefulWidget {
  const _Phase2ConfigSheet({required this.data, required this.ctrl});
  final AvanceGraficoPhase2Data data;
  final AppController ctrl;
  @override
  State<_Phase2ConfigSheet> createState() => _Phase2ConfigSheetState();
}

class _Phase2ConfigSheetState extends State<_Phase2ConfigSheet> {
  late bool _uniformEnabled;
  late int _uniformCount;
  bool _uniformExpanded = false;

  @override
  void initState() {
    super.initState();
    _uniformEnabled = widget.data.uniformFloorsEnabled;
    _uniformCount = widget.data.uniformFloorsCount.clamp(1, 30);
    if (_uniformCount == 0) _uniformCount = 1;
  }

  Future<void> _saveUniform() async {
    await widget.ctrl.updateAvanceGraficoPhase2UniformFloors(
      phaseId: widget.data.phaseId,
      enabled: _uniformEnabled,
      count: _uniformCount,
    );
    if (mounted && (widget.ctrl.error == null || widget.ctrl.error!.isEmpty)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final ctrl = widget.ctrl;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: _C.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Administrar Fase 2',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: _C.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Pisos uniformes ─────────────────────────────────────
                  _ConfigSection(
                    icon: Icons.layers_rounded,
                    title: 'Pisos uniformes para todas las actividades',
                    subtitle: _uniformEnabled
                        ? '$_uniformCount pisos de referencia'
                        : 'Deshabilitado',
                    expanded: _uniformExpanded,
                    onToggle: () =>
                        setState(() => _uniformExpanded = !_uniformExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Al habilitar, las nuevas actividades usarán el mismo número de pisos de referencia.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.muted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            value: _uniformEnabled,
                            onChanged: (v) =>
                                setState(() => _uniformEnabled = v),
                            title: const Text(
                              'Habilitar pisos uniformes',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _C.text,
                              ),
                            ),
                            dense: true,
                            activeThumbColor: _C.primary,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_uniformEnabled) ...[
                            const SizedBox(height: 10),
                            _Stepper(
                              label:
                                  'Pisos de referencia (todas las actividades)',
                              value: _uniformCount,
                              min: 1,
                              max: 50,
                              onChanged: (v) =>
                                  setState(() => _uniformCount = v),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _saveUniform(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.save_rounded, size: 15),
                              label: const Text(
                                'Guardar configuración',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Lista de actividades ─────────────────────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.list_alt_rounded,
                        size: 16,
                        color: _C.primary,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Actividades',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _C.text,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddPhase2ActivitySheet(
                            context,
                            data: data,
                            ctrl: ctrl,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _C.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Nueva',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (data.activities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No hay actividades configuradas',
                          style: TextStyle(fontSize: 12, color: _C.faint),
                        ),
                      ),
                    )
                  else
                    ...data.activities.map(
                      (act) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.stroke),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _C.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  act.abbreviation.isEmpty
                                      ? 'AG'
                                      : act.abbreviation,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _C.text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${act.floors}P · ${act.basements}S · ${act.sectors} sect.',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _C.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: _C.primary,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddPhase2ActivitySheet(
                                  context,
                                  data: data,
                                  ctrl: ctrl,
                                  existing: act,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: _C.red,
                              ),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              onPressed: () {
                                ctrl.deleteAvanceGraficoPhase2Activity(act.id);
                                Navigator.pop(context);
                              },
                            ),
                          ],
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
  }
}

void _showAddPhase2ActivitySheet(
  BuildContext context, {
  required AvanceGraficoPhase2Data data,
  required AppController ctrl,
  AvanceGraficoPhase2Activity? existing,
}) {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final abbrCtrl = TextEditingController(text: existing?.abbreviation ?? '');
  final uniformLocked = data.uniformFloorsEnabled && !isEdit;
  int floors = uniformLocked
      ? data.uniformFloorsCount.clamp(1, 50)
      : (existing?.floors ?? 4);
  int basements = existing?.basements ?? 0;
  int sectors = existing?.sectors ?? 5;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_box_rounded,
                  color: _C.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isEdit ? "Editar" : "Nueva"} actividad',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: !isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre de la actividad',
                hintText: 'ej. Muro anclado',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (v) {
                if (!isEdit) {
                  abbrCtrl.text = v
                      .trim()
                      .split(' ')
                      .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                      .join();
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: abbrCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Abreviatura',
                hintText: 'ej. MA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: uniformLocked ? 'Pisos (uniforme 🔒)' : 'Pisos',
                    value: floors,
                    min: 1,
                    max: 50,
                    onChanged: uniformLocked
                        ? null
                        : (v) => setState(() => floors = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stepper(
                    label: 'Sótanos',
                    value: basements,
                    min: 0,
                    max: 20,
                    onChanged: (v) => setState(() => basements = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stepper(
                    label: 'Sectores',
                    value: sectors,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => sectors = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: Icon(isEdit ? Icons.save_rounded : Icons.add, size: 16),
                label: Text(
                  isEdit ? 'Guardar cambios' : 'Crear actividad',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final abbr = abbrCtrl.text.trim().isEmpty
                      ? name
                            .split(' ')
                            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                            .join()
                      : abbrCtrl.text.trim();
                  Navigator.pop(ctx);
                  if (isEdit) {
                    ctrl.updateAvanceGraficoPhase2Activity(
                      activityId: existing.id,
                      name: name,
                      abbreviation: abbr,
                      floors: floors,
                      basements: basements,
                      sectors: sectors,
                    );
                  } else {
                    ctrl.addAvanceGraficoPhase2Activity(
                      phaseId: data.phaseId,
                      name: name,
                      abbreviation: abbr,
                      floors: floors,
                      basements: basements,
                      sectors: sectors,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// FASE 3 — Config → Pisos → Sectores → Actividades  (rediseño estructural)
// ═══════════════════════════════════════════════════════════════════════════════

enum _P3View { pisos, resumen }

// ─── Estado de pincel ─────────────────────────────────────────────────────────

class _Phase3Campo extends StatefulWidget {
  const _Phase3Campo({
    required this.data,
    required this.ctrl,
    required this.states,
  });
  final AvanceGraficoPhase3Data data;
  final AppController ctrl;
  final List<AvanceGraficoStateCatalog> states;
  @override
  State<_Phase3Campo> createState() => _Phase3CampoState();
}

class _Phase3CampoState extends State<_Phase3Campo> {
  _P3View _view = _P3View.pisos;
  bool _configOpen = false;

  AvanceGraficoPhase3Data get d => widget.data;

  @override
  void initState() {
    super.initState();
    if (!d.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _configOpen = true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _Phase3Campo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (d.isInitialized && _configOpen) {
      setState(() => _configOpen = false);
    }
    if (!d.isInitialized &&
        !_configOpen &&
        oldWidget.data.isInitialized != d.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _configOpen = true);
      });
    }
  }

  void _openConfig() => setState(() => _configOpen = true);

  @override
  Widget build(BuildContext context) {
    final floors = d.floors;
    final totalPct = floors.isEmpty
        ? 0.0
        : floors
                  .map((f) {
                    final cells = f.activityRows.expand((r) => r.cells);
                    if (cells.isEmpty) return 0.0;
                    final done = cells
                        .where((c) => c.statusCode == 11 || c.statusCode == 14)
                        .length;
                    return done / cells.length;
                  })
                  .fold(0.0, (a, b) => a + b) /
              floors.length;

    if (!d.isInitialized) {
      return Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: _C.surface,
                  border: Border(bottom: BorderSide(color: _C.stroke)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_suggest_rounded,
                      size: 13,
                      color: _C.primary,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Fase 3 sin inicializar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.primary,
                        ),
                      ),
                    ),
                    _P3NavBtn(
                      label: 'Configurar',
                      icon: Icons.tune_rounded,
                      active: _configOpen,
                      onTap: _openConfig,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.domain_disabled_outlined,
                          size: 52,
                          color: _C.faint,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Antes de usar Campo Fase 3 debes completar la configuracion inicial.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _C.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _openConfig,
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('Abrir configuracion inicial'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_configOpen)
            _Phase3ConfigSheet(
              data: d,
              ctrl: widget.ctrl,
              onClose: () => setState(() => _configOpen = false),
            ),
        ],
      );
    }

    return Column(
      children: [
        // ── Top nav ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: _C.surface,
            border: Border(bottom: BorderSide(color: _C.stroke)),
          ),
          child: Row(
            children: [
              const Icon(Icons.domain_outlined, size: 13, color: _C.primary),
              const SizedBox(width: 3),
              Text(
                '${d.floorCount}p',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _C.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.task_alt_rounded, size: 13, color: _C.primary),
              const SizedBox(width: 3),
              Text(
                '${(totalPct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _C.primary,
                ),
              ),
              const Spacer(),
              _P3NavBtn(
                label: 'Pisos',
                icon: Icons.layers_outlined,
                active: _view == _P3View.pisos,
                onTap: () => setState(() => _view = _P3View.pisos),
              ),
              const SizedBox(width: 4),
              _P3NavBtn(
                label: 'Resumen',
                icon: Icons.grid_view_rounded,
                active: _view == _P3View.resumen,
                onTap: () => setState(() => _view = _P3View.resumen),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _C.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.stroke),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 12, color: _C.muted),
                    SizedBox(width: 4),
                    Text(
                      'Config. bloqueada',
                      style: TextStyle(
                        fontSize: 10,
                        color: _C.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Body ─────────────────────────────────────────────────────────────
        Expanded(
          child: _view == _P3View.pisos
              ? _Phase3PisosView(
                  data: d,
                  ctrl: widget.ctrl,
                  states: widget.states,
                )
              : _Phase3ResumenView(data: d, states: widget.states),
        ),
      ],
    );
  }
}

// ─── Nav button ───────────────────────────────────────────────────────────────

class _P3NavBtn extends StatelessWidget {
  const _P3NavBtn({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _C.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? null : Border.all(color: _C.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: active ? Colors.white : _C.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : _C.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PISOS VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase3PisosView extends StatefulWidget {
  const _Phase3PisosView({
    required this.data,
    required this.ctrl,
    required this.states,
  });
  final AvanceGraficoPhase3Data data;
  final AppController ctrl;
  final List<AvanceGraficoStateCatalog> states;
  @override
  State<_Phase3PisosView> createState() => _Phase3PisosViewState();
}

class _Phase3PisosViewState extends State<_Phase3PisosView> {
  int _floorIdx = 0;
  bool _showPlan = false;

  // Estado activo (siempre hay uno seleccionado, como Fase 2)
  int _activeStateCode = 12; // Pendiente por defecto

  AvanceGraficoPhase3Data get d => widget.data;

  List<AvanceGraficoStateCatalog> get _p3States => widget.states
      .where((state) => state.phaseKey == 'FaseTres_ActividadesXSectores')
      .toList(growable: false);

  int _resolveDefaultP3StateCode() {
    for (final state in _p3States) {
      if (state.label.trim().toLowerCase() == 'pendiente') {
        return state.code;
      }
    }
    if (_p3States.isNotEmpty) {
      return _p3States.first.code;
    }
    return _activeStateCode;
  }

  @override
  void initState() {
    super.initState();
    _activeStateCode = _resolveDefaultP3StateCode();
  }

  @override
  void didUpdateWidget(_Phase3PisosView old) {
    super.didUpdateWidget(old);
    // Si el estado activo no existe en el catálogo, usar el primero disponible
    if (_p3States.isNotEmpty &&
        !_p3States.any((state) => state.code == _activeStateCode)) {
      _activeStateCode = _resolveDefaultP3StateCode();
    }
  }

  void _tapCell(AvanceGraficoPhase3Cell cell) {
    widget.ctrl.updateAvanceGraficoPhase3CellState(
      cellId: cell.id,
      newStatusCode: _activeStateCode,
    );
  }

  void _doubleTapCell(AvanceGraficoPhase3Cell cell) {
    final codes = _p3States.map((s) => s.code).toList()..sort();
    if (codes.isEmpty) return;
    final idx = codes.indexOf(cell.statusCode);
    final next = codes[(idx + 1) % codes.length];
    setState(() => _activeStateCode = next);
    widget.ctrl.updateAvanceGraficoPhase3CellState(
      cellId: cell.id,
      newStatusCode: next,
    );
  }

  @override
  Widget build(BuildContext context) {
    final floors = d.floors;
    if (floors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.domain_outlined, size: 48, color: _C.faint),
            const SizedBox(height: 12),
            const Text(
              'Sin pisos configurados',
              style: TextStyle(color: _C.muted),
            ),
          ],
        ),
      );
    }

    final floor = floors[_floorIdx.clamp(0, floors.length - 1)];

    return Column(
      children: [
        // ── Tira de pisos ────────────────────────────────────────────────────
        Container(
          color: _C.surface,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: List.generate(floors.length, (i) {
                      final f = floors[i];
                      final active = i == _floorIdx;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _floorIdx = i;
                          _showPlan = false;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: active ? _C.primary : _C.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            f.abbreviation.isNotEmpty ? f.abbreviation : f.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : _C.primary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              // Ver todos
              _IconAction(
                icon: Icons.domain_outlined,
                tooltip: 'Ver todos los pisos',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) =>
                      _BuildingModal(floors: floors, states: widget.states),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _C.stroke),
        // ── Sector strip ─────────────────────────────────────────────────────
        Container(
          color: _C.surface,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...floor.sectors.map((s) {
                        final isLocal = s.baseId == -999;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text(
                              s.name,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: isLocal
                                ? () => _P3AddItemModal.show(
                                    context,
                                    title: 'Editar sector en ${floor.name}',
                                    label: 'Nombre del sector',
                                    initialName: s.name,
                                    submitLabel: 'Guardar',
                                    onAdd: (name, _) => widget.ctrl
                                        .updateAvanceGraficoPhase3SectorOnFloor(
                                          sectorFloorId: s.id,
                                          name: name,
                                          description: s.description,
                                        ),
                                  )
                                : null,
                            onDeleted: isLocal
                                ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Eliminar sector'),
                                        content: Text(
                                          'Se eliminara "${s.name}" y todas sus celdas en este piso.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && mounted) {
                                      await widget.ctrl
                                          .deleteAvanceGraficoPhase3SectorFromFloor(
                                            sectorFloorId: s.id,
                                          );
                                    }
                                  }
                                : null,
                            deleteIconColor: _C.red,
                            backgroundColor: _C.accent,
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 14),
                        label: const Text(
                          'Sector',
                          style: TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _P3AddItemModal.show(
                          context,
                          title: 'Nuevo sector en ${floor.name}',
                          label: 'Nombre del sector',
                          onAdd: (name, abbr) =>
                              widget.ctrl.addAvanceGraficoPhase3SectorToFloor(
                                pisoId: floor.id,
                                phaseId: d.phaseId,
                                projectId: d.projectId,
                                moduleId: d.moduleId,
                                name: name,
                                description: '',
                              ),
                        ),
                        backgroundColor: _C.bg,
                        side: const BorderSide(color: _C.stroke),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
              // Toggle plan
              _IconAction(
                icon: _showPlan ? Icons.grid_on : Icons.map_outlined,
                tooltip: _showPlan ? 'Mostrar matriz' : 'Mostrar plano',
                onTap: () => setState(() => _showPlan = !_showPlan),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _C.stroke),
        // ── Matrix or Plan ───────────────────────────────────────────────────
        Expanded(
          child: _showPlan
              ? _Phase3PlanView(floor: floor, ctrl: widget.ctrl, data: d)
              : _Phase3ActivityMatrix(
                  floor: floor,
                  onTap: _tapCell,
                  onDoubleTap: _doubleTapCell,
                  activeStateCode: _activeStateCode,
                  states: _p3States,
                  ctrl: widget.ctrl,
                  data: d,
                ),
        ),
        // ── Leyenda al fondo (igual que Fase 2) ─────────────────────────────
        if (!_showPlan)
          _Phase3LegendBar(
            states: _p3States,
            activeCode: _activeStateCode,
            onTap: (code) => setState(() => _activeStateCode = code),
          ),
      ],
    );
  }
}

// ─── Activity × Sector matrix (frozen left col) ───────────────────────────────

class _Phase3ActivityMatrix extends StatelessWidget {
  const _Phase3ActivityMatrix({
    required this.floor,
    required this.onTap,
    required this.onDoubleTap,
    required this.activeStateCode,
    required this.states,
    required this.ctrl,
    required this.data,
  });
  final AvanceGraficoPhase3Floor floor;
  final void Function(AvanceGraficoPhase3Cell) onTap;
  final void Function(AvanceGraficoPhase3Cell) onDoubleTap;
  final int activeStateCode;
  final List<AvanceGraficoStateCatalog> states;
  final AppController ctrl;
  final AvanceGraficoPhase3Data data;

  Color _colorFor(int code) => _hexColor(
    states
        .firstWhere(
          (s) => s.code == code,
          orElse: () => AvanceGraficoStateCatalog(
            code: code,
            label: '',
            phaseKey: '',
            colorHex: '#94A3B8',
            colorName: '',
          ),
        )
        .colorHex,
  );

  String _labelFor(int code) => states
      .firstWhere(
        (s) => s.code == code,
        orElse: () => AvanceGraficoStateCatalog(
          code: code,
          label: 'Estado',
          phaseKey: '',
          colorHex: '#94A3B8',
          colorName: '',
        ),
      )
      .label;

  static const double _actColW = 120;
  static const double _cellW = 72;
  static const double _rowH = 44;
  static const double _headerH = 36;
  static const double _actionIconSize = 16;
  static const double _actionHitBox = 24;

  @override
  Widget build(BuildContext context) {
    final sectors = floor.sectors;
    final activities = floor.activityRows;

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_list_outlined, size: 40, color: _C.faint),
            const SizedBox(height: 8),
            const Text(
              'Sin actividades',
              style: TextStyle(color: _C.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _P3AddItemModal.show(
                context,
                title: 'Nueva actividad en ${floor.name}',
                label: 'Nombre de actividad',
                showAbbr: true,
                onAdd: (name, abbr) =>
                    ctrl.addAvanceGraficoPhase3ActivityToFloor(
                      pisoId: floor.id,
                      phaseId: data.phaseId,
                      projectId: data.projectId,
                      moduleId: data.moduleId,
                      name: name,
                      abbreviation: abbr,
                    ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar actividad'),
            ),
          ],
        ),
      );
    }

    final scrollCtrl = ScrollController();

    return Column(
      children: [
        // Header row
        Row(
          children: [
            // Frozen activity header
            Container(
              width: _actColW,
              height: _headerH,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: _C.surface,
                border: Border(
                  right: BorderSide(color: _C.stroke),
                  bottom: BorderSide(color: _C.stroke),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Actividad',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _C.muted,
                    ),
                  ),
                  SizedBox(
                    width: _actionHitBox,
                    height: _actionHitBox,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: _actionHitBox,
                        height: _actionHitBox,
                      ),
                      iconSize: _actionIconSize,
                      splashRadius: _actionHitBox / 2,
                      onPressed: () => _P3AddItemModal.show(
                        context,
                        title: 'Nueva actividad en ${floor.name}',
                        label: 'Nombre de actividad',
                        showAbbr: true,
                        onAdd: (name, abbr) =>
                            ctrl.addAvanceGraficoPhase3ActivityToFloor(
                              pisoId: floor.id,
                              phaseId: data.phaseId,
                              projectId: data.projectId,
                              moduleId: data.moduleId,
                              name: name,
                              abbreviation: abbr,
                            ),
                      ),
                      icon: const Icon(Icons.add, color: _C.primary),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable sector headers
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sectors
                      .map(
                        (s) => Container(
                          width: _cellW,
                          height: _headerH,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _C.accent,
                            border: Border(
                              right: BorderSide(color: _C.stroke),
                              bottom: BorderSide(color: _C.stroke),
                            ),
                          ),
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _C.primary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, rowIdx) {
              final row = activities[rowIdx];
              final isLocalActivity = row.activityId == -999;
              final rowBaseColor = isLocalActivity
                  ? _C.amber.withValues(alpha: 0.22)
                  : (rowIdx.isEven ? _C.surface : _C.bg);
              return SizedBox(
                height: _rowH,
                child: Row(
                  children: [
                    // Frozen activity name
                    Container(
                      width: _actColW,
                      height: _rowH,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: rowBaseColor,
                        border: const Border(
                          right: BorderSide(color: _C.stroke),
                          bottom: BorderSide(color: _C.stroke),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.abbreviation.isNotEmpty
                                  ? row.abbreviation
                                  : row.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _C.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLocalActivity)
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: _actionHitBox,
                                height: _actionHitBox,
                              ),
                              iconSize: _actionIconSize,
                              splashRadius: _actionHitBox / 2,
                              icon: const Icon(
                                Icons.more_vert,
                                color: _C.muted,
                              ),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _P3AddItemModal.show(
                                    context,
                                    title: 'Editar actividad en ${floor.name}',
                                    label: 'Nombre de actividad',
                                    showAbbr: true,
                                    initialName: row.name,
                                    initialAbbr: row.abbreviation,
                                    submitLabel: 'Guardar',
                                    onAdd: (name, abbr) => ctrl
                                        .updateAvanceGraficoPhase3ActivityOnFloor(
                                          activityFloorId: row.id,
                                          name: name,
                                          abbreviation: abbr,
                                        ),
                                  );
                                  return;
                                }
                                if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Eliminar actividad'),
                                      content: Text(
                                        'Se eliminara "${row.name}" y sus celdas en este piso.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    await ctrl
                                        .deleteAvanceGraficoPhase3ActivityFromFloor(
                                          activityFloorId: row.id,
                                        );
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Scrollable cells
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sectors.map((s) {
                            final cell = row.cells.where(
                              (c) => c.sectorFloorId == s.id,
                            );
                            if (cell.isEmpty) {
                              return Container(
                                width: _cellW,
                                height: _rowH,
                                decoration: BoxDecoration(
                                  color: rowBaseColor,
                                  border: const Border(
                                    right: BorderSide(color: _C.stroke),
                                    bottom: BorderSide(color: _C.stroke),
                                  ),
                                ),
                              );
                            }
                            final c = cell.first;
                            final color = _colorFor(c.statusCode);
                            return GestureDetector(
                              onTap: () => onTap(c),
                              onDoubleTap: () => onDoubleTap(c),
                              child: Tooltip(
                                message: _labelFor(c.statusCode),
                                child: Container(
                                  width: _cellW,
                                  height: _rowH,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.18),
                                    border: Border(
                                      right: const BorderSide(color: _C.stroke),
                                      bottom: const BorderSide(
                                        color: _C.stroke,
                                      ),
                                      left: BorderSide(color: color, width: 3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PLAN VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase3PlanView extends StatefulWidget {
  const _Phase3PlanView({
    required this.floor,
    required this.ctrl,
    required this.data,
  });
  final AvanceGraficoPhase3Floor floor;
  final AppController ctrl;
  final AvanceGraficoPhase3Data data;
  @override
  State<_Phase3PlanView> createState() => _Phase3PlanViewState();
}

class _Phase3PlanViewState extends State<_Phase3PlanView> {
  final _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectors = widget.floor.sectors;
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.3,
          maxScale: 4,
          child: CustomPaint(
            painter: _GridPainter(),
            child: SizedBox(
              width: 800,
              height: 600,
              child: Stack(
                children: sectors.map((s) {
                  double dx = 80;
                  double dy = 80;
                  if (s.planPositionJson != null &&
                      s.planPositionJson!.isNotEmpty) {
                    try {
                      // parse "x,y" simple format
                      final parts = s.planPositionJson!.split(',');
                      dx = double.tryParse(parts[0]) ?? dx;
                      dy = double.tryParse(parts[1]) ?? dy;
                    } catch (_) {}
                  }
                  return Positioned(
                    left: dx,
                    top: dy,
                    child: Draggable(
                      feedback: _SectorMarker(sector: s, opacity: 0.7),
                      childWhenDragging: const SizedBox.shrink(),
                      child: _SectorMarker(sector: s),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        // Upload plan hint
        Positioned(
          bottom: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'upload_plan_${widget.floor.id}',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carga de plano próximamente'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            backgroundColor: _C.primary,
            child: const Icon(Icons.upload_file, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _SectorMarker extends StatelessWidget {
  const _SectorMarker({required this.sector, this.opacity = 1.0});
  final AvanceGraficoPhase3SectorProgress sector;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Center(
              child: Text(
                sector.name.substring(0, sector.name.length.clamp(0, 2)),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2),
              ],
            ),
            child: Text(
              sector.name,
              style: const TextStyle(fontSize: 9, color: _C.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDE8F5)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// RESUMEN VIEW — Activity × Floors matrix
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase3ResumenView extends StatefulWidget {
  const _Phase3ResumenView({required this.data, required this.states});
  final AvanceGraficoPhase3Data data;
  final List<AvanceGraficoStateCatalog> states;
  @override
  State<_Phase3ResumenView> createState() => _Phase3ResumenViewState();
}

class _Phase3ResumenViewState extends State<_Phase3ResumenView> {
  bool _fullscreen = false;

  static const double _actColW = 130;
  static const double _floorColW = 80;
  static const double _rowH = 40;
  static const double _headerH = 36;

  double _floorPct(AvanceGraficoPhase3Floor f) {
    final cells = f.activityRows.expand((r) => r.cells).toList();
    if (cells.isEmpty) return 0;
    final done = cells
        .where((c) => c.statusCode == 11 || c.statusCode == 14)
        .length;
    return done / cells.length;
  }

  double _activityFloorPct(AvanceGraficoPhase3ActivityRow row) {
    if (row.cells.isEmpty) return 0;
    final done = row.cells
        .where((c) => c.statusCode == 11 || c.statusCode == 14)
        .length;
    return done / row.cells.length;
  }

  @override
  Widget build(BuildContext context) {
    final floors = widget.data.floors;
    // Collect unique activity names across all floors
    final actNames = <String>{};
    for (final f in floors) {
      for (final r in f.activityRows) {
        actNames.add(r.name);
      }
    }
    final activities = actNames.toList();

    Widget matrix = Column(
      children: [
        // Header
        Row(
          children: [
            Container(
              width: _actColW,
              height: _headerH,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: _C.surface,
                border: Border(
                  right: BorderSide(color: _C.stroke),
                  bottom: BorderSide(color: _C.stroke),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Actividad',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _C.muted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _fullscreen = !_fullscreen),
                    child: Icon(
                      _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      size: 16,
                      color: _C.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: floors
                      .map(
                        (f) => Container(
                          width: _floorColW,
                          height: _headerH,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _C.accent,
                            border: Border(
                              right: BorderSide(color: _C.stroke),
                              bottom: BorderSide(color: _C.stroke),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                f.abbreviation.isNotEmpty
                                    ? f.abbreviation
                                    : f.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${(_floorPct(f) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _C.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        // Rows
        Expanded(
          child: ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, rowIdx) {
              final actName = activities[rowIdx];
              return SizedBox(
                height: _rowH,
                child: Row(
                  children: [
                    Container(
                      width: _actColW,
                      height: _rowH,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: rowIdx.isEven ? _C.surface : _C.bg,
                        border: const Border(
                          right: BorderSide(color: _C.stroke),
                          bottom: BorderSide(color: _C.stroke),
                        ),
                      ),
                      child: Text(
                        actName,
                        style: const TextStyle(fontSize: 11, color: _C.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: floors.map((f) {
                            final row = f.activityRows.where(
                              (r) => r.name == actName,
                            );
                            final pct = row.isEmpty
                                ? null
                                : _activityFloorPct(row.first);
                            return Container(
                              width: _floorColW,
                              height: _rowH,
                              decoration: BoxDecoration(
                                color: rowIdx.isEven ? _C.surface : _C.bg,
                                border: const Border(
                                  right: BorderSide(color: _C.stroke),
                                  bottom: BorderSide(color: _C.stroke),
                                ),
                              ),
                              child: pct == null
                                  ? const Center(
                                      child: Text(
                                        '—',
                                        style: TextStyle(
                                          color: _C.faint,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )
                                  : Center(child: _P3ProgressBar(value: pct)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );

    if (_fullscreen) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Padding(padding: const EdgeInsets.all(8), child: matrix),
      );
    }
    return matrix;
  }
}

class _P3ProgressBar extends StatelessWidget {
  const _P3ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: pct >= 100 ? _C.green : _C.primary,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 52,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: _C.stroke,
              valueColor: AlwaysStoppedAnimation(
                pct >= 100 ? _C.green : _C.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUILDING MODAL — vista de todos los pisos
// ═══════════════════════════════════════════════════════════════════════════════

class _BuildingModal extends StatelessWidget {
  const _BuildingModal({required this.floors, required this.states});
  final List<AvanceGraficoPhase3Floor> floors;
  final List<AvanceGraficoStateCatalog> states;

  double _floorPct(AvanceGraficoPhase3Floor f) {
    final cells = f.activityRows.expand((r) => r.cells).toList();
    if (cells.isEmpty) return 0;
    final done = cells
        .where((c) => c.statusCode == 11 || c.statusCode == 14)
        .length;
    return done / cells.length;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.domain_outlined, color: _C.primary),
                const SizedBox(width: 8),
                const Text(
                  'Todos los pisos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.text,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: floors.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (_, i) {
                final f = floors[i];
                return _BuildingFloorTile(floor: f, pct: _floorPct(f));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingFloorTile extends StatelessWidget {
  const _BuildingFloorTile({required this.floor, required this.pct});
  final AvanceGraficoPhase3Floor floor;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final p = (pct * 100).round();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                floor.abbreviation.isNotEmpty
                    ? floor.abbreviation.substring(
                        0,
                        floor.abbreviation.length.clamp(0, 3),
                      )
                    : floor.name.substring(0, floor.name.length.clamp(0, 3)),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  floor.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.text,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: _C.stroke,
                    valueColor: AlwaysStoppedAnimation(
                      p >= 100 ? _C.green : _C.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$p%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p >= 100 ? _C.green : _C.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIG SHEET — wizard de 3 pasos
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase3ConfigSheet extends StatefulWidget {
  const _Phase3ConfigSheet({
    required this.data,
    required this.ctrl,
    required this.onClose,
  });
  final AvanceGraficoPhase3Data data;
  final AppController ctrl;
  final VoidCallback onClose;
  @override
  State<_Phase3ConfigSheet> createState() => _Phase3ConfigSheetState();
}

class _Phase3ConfigSheetState extends State<_Phase3ConfigSheet> {
  int _step = 0;
  bool _saving = false;

  AvanceGraficoPhase3Data get d => widget.data;

  Future<void> _finishSetup() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.ctrl.initializeAvanceGraficoPhase3Config(phaseId: d.phaseId);
    if (!mounted) return;
    setState(() => _saving = false);
    final error = widget.ctrl.error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _C.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _StepDot(
                      index: 0,
                      current: _step,
                      label: 'Pisos',
                      onTap: () => setState(() => _step = 0),
                    ),
                    _StepLine(active: _step >= 1),
                    _StepDot(
                      index: 1,
                      current: _step,
                      label: 'Sectores',
                      onTap: () => setState(() => _step = 1),
                    ),
                    _StepLine(active: _step >= 2),
                    _StepDot(
                      index: 2,
                      current: _step,
                      label: 'Actividades',
                      onTap: () => setState(() => _step = 2),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _saving ? null : widget.onClose,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Step content
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: IndexedStack(
                  index: _step,
                  children: [
                    _ConfigStepPisos(data: d, ctrl: widget.ctrl),
                    _ConfigStepSectores(data: d, ctrl: widget.ctrl),
                    _ConfigStepActividades(data: d, ctrl: widget.ctrl),
                  ],
                ),
              ),
              // Navigation buttons
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Row(
                  children: [
                    if (_step > 0)
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _step--),
                        child: const Text('Anterior'),
                      ),
                    const Spacer(),
                    if (_step < 2)
                      ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _step++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Siguiente'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _saving ? null : _finishSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _saving
                              ? 'Guardando configuracion...'
                              : 'Guardar configuracion',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Config steps ─────────────────────────────────────────────────────────────

class _ConfigStepPisos extends StatelessWidget {
  const _ConfigStepPisos({required this.data, required this.ctrl});
  final AvanceGraficoPhase3Data data;
  final AppController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              const Text(
                'Pisos configurados',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.text,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _P3AddFloorModal.show(
                  context,
                  ctrl: ctrl,
                  phaseId: data.phaseId,
                  projectId: data.projectId,
                  moduleId: data.moduleId,
                  nextOrder: data.floors.isEmpty
                      ? 1
                      : data.floors.map((floor) => floor.order).reduce(max) + 1,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        if (data.floors.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Sin pisos. Agrega el primero.',
                style: TextStyle(color: _C.muted),
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: data.floors.length,
              itemBuilder: (_, i) {
                final f = data.floors[i];
                return _StepChip(
                  label: f.name,
                  sub: '${f.sectors.length} sectores',
                  onDelete: () => ctrl.deleteAvanceGraficoPhase3Floor(f.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConfigStepSectores extends StatelessWidget {
  const _ConfigStepSectores({required this.data, required this.ctrl});
  final AvanceGraficoPhase3Data data;
  final AppController ctrl;

  @override
  Widget build(BuildContext context) {
    final global = data.globalSectors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              const Text(
                'Sectores globales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.text,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _P3AddItemModal.show(
                  context,
                  title: 'Nuevo sector global',
                  label: 'Nombre del sector',
                  onAdd: (name, _) => ctrl.addAvanceGraficoPhase3Sector(
                    phaseId: data.phaseId,
                    projectId: data.projectId,
                    moduleId: data.moduleId,
                    name: name,
                    description: '',
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        if (global.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Sin sectores globales.',
                style: TextStyle(color: _C.muted),
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: global.length,
              itemBuilder: (_, i) {
                final s = global[i];
                return _StepChip(
                  label: s.name,
                  sub: s.description,
                  onDelete: () => ctrl.deleteAvanceGraficoPhase3Sector(s.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConfigStepActividades extends StatelessWidget {
  const _ConfigStepActividades({required this.data, required this.ctrl});
  final AvanceGraficoPhase3Data data;
  final AppController ctrl;

  @override
  Widget build(BuildContext context) {
    final global = data.globalActivities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              const Text(
                'Actividades globales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.text,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _P3AddItemModal.show(
                  context,
                  title: 'Nueva actividad global',
                  label: 'Nombre de actividad',
                  showAbbr: true,
                  onAdd: (name, abbr) => ctrl.addAvanceGraficoPhase3Activity(
                    phaseId: data.phaseId,
                    projectId: data.projectId,
                    moduleId: data.moduleId,
                    name: name,
                    abbreviation: abbr,
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        if (global.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Sin actividades globales.',
                style: TextStyle(color: _C.muted),
              ),
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: global.length,
              itemBuilder: (_, i) {
                final r = global[i];
                return _StepChip(
                  label: r.name,
                  sub: r.abbreviation,
                  onDelete: () => ctrl.deleteAvanceGraficoPhase3Activity(r.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── Wizard helpers ───────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.current,
    required this.label,
    required this.onTap,
  });
  final int index, current;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? _C.primary : _C.stroke,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : _C.muted,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: active ? _C.primary : _C.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: active ? _C.primary : _C.stroke,
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label, this.sub, this.onDelete});
  final String label;
  final String? sub;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.text,
                  ),
                ),
                if (sub != null && sub!.isNotEmpty)
                  Text(
                    sub!,
                    style: const TextStyle(fontSize: 11, color: _C.muted),
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: _C.red),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LEGEND BAR
// ═══════════════════════════════════════════════════════════════════════════════

class _Phase3LegendBar extends StatelessWidget {
  const _Phase3LegendBar({
    required this.states,
    required this.onTap,
    required this.activeCode,
  });
  final List<AvanceGraficoStateCatalog> states;
  final void Function(int) onTap;
  final int activeCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.surface,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: states.map((s) {
          final color = _hexColor(s.colorHex);
          final isActive = activeCode == s.code;
          return GestureDetector(
            onTap: () => onTap(s.code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 7 : 4,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isActive ? Border.all(color: color, width: 1.5) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                      color: isActive ? _C.text : _C.muted,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _C.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODAL HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: _C.primary),
        ),
      ),
    );
  }
}

class _P3AddFloorModal {
  static void show(
    BuildContext context, {
    required AppController ctrl,
    required int phaseId,
    required int projectId,
    required int moduleId,
    required int nextOrder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _P3AddFloorSheet(
        ctrl: ctrl,
        phaseId: phaseId,
        projectId: projectId,
        moduleId: moduleId,
        nextOrder: nextOrder,
      ),
    );
  }
}

class _P3AddFloorSheet extends StatefulWidget {
  const _P3AddFloorSheet({
    required this.ctrl,
    required this.phaseId,
    required this.projectId,
    required this.moduleId,
    required this.nextOrder,
  });
  final AppController ctrl;
  final int phaseId, projectId, moduleId, nextOrder;
  @override
  State<_P3AddFloorSheet> createState() => _P3AddFloorSheetState();
}

class _P3AddFloorSheetState extends State<_P3AddFloorSheet> {
  final _name = TextEditingController();
  final _abbr = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuevo piso',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.text,
            ),
          ),
          const SizedBox(height: 16),
          _P3Field(ctrl: _name, label: 'Nombre del piso'),
          const SizedBox(height: 10),
          _P3Field(ctrl: _abbr, label: 'Abreviación (ej: P1)'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                widget.ctrl.addAvanceGraficoPhase3Floor(
                  phaseId: widget.phaseId,
                  projectId: widget.projectId,
                  moduleId: widget.moduleId,
                  name: _name.text.trim(),
                  abbreviation: _abbr.text.trim(),
                  order: widget.nextOrder,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar piso'),
            ),
          ),
        ],
      ),
    );
  }
}

class _P3AddItemModal {
  static void show(
    BuildContext context, {
    required String title,
    required String label,
    bool showAbbr = false,
    String initialName = '',
    String initialAbbr = '',
    String submitLabel = 'Agregar',
    required void Function(String name, String abbr) onAdd,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _P3AddItemSheet(
        title: title,
        label: label,
        showAbbr: showAbbr,
        initialName: initialName,
        initialAbbr: initialAbbr,
        submitLabel: submitLabel,
        onAdd: onAdd,
      ),
    );
  }
}

class _P3AddItemSheet extends StatefulWidget {
  const _P3AddItemSheet({
    required this.title,
    required this.label,
    required this.showAbbr,
    required this.initialName,
    required this.initialAbbr,
    required this.submitLabel,
    required this.onAdd,
  });
  final String title, label;
  final bool showAbbr;
  final String initialName;
  final String initialAbbr;
  final String submitLabel;
  final void Function(String, String) onAdd;
  @override
  State<_P3AddItemSheet> createState() => _P3AddItemSheetState();
}

class _P3AddItemSheetState extends State<_P3AddItemSheet> {
  final _name = TextEditingController();
  final _abbr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = widget.initialName;
    _abbr.text = widget.initialAbbr;
  }

  @override
  void dispose() {
    _name.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _C.text,
            ),
          ),
          const SizedBox(height: 16),
          _P3Field(ctrl: _name, label: widget.label),
          if (widget.showAbbr) ...[
            const SizedBox(height: 10),
            _P3Field(ctrl: _abbr, label: 'Abreviación'),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_name.text.trim().isEmpty) return;
                widget.onAdd(_name.text.trim(), _abbr.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _P3Field extends StatelessWidget {
  const _P3Field({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _C.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _C.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _C.stroke),
        ),
      ),
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _C.bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _C.stroke),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _C.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _C.muted,
          ),
        ),
      ],
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: _C.muted)),
    ],
  );
}

class _EmptyPhase extends StatelessWidget {
  const _EmptyPhase();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox_rounded, color: _C.faint, size: 32),
        SizedBox(height: 10),
        Text(
          'Sin configuración cargada para esta fase.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _C.muted,
          ),
        ),
      ],
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Phase1Groups {
  const _Phase1Groups({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });
  final List<AvanceGraficoPhase1Section> top, bottom, left, right;
}

_Phase1Groups _groupByLado(List<AvanceGraficoPhase1Section> sections) {
  final top = <AvanceGraficoPhase1Section>[];
  final bottom = <AvanceGraficoPhase1Section>[];
  final left = <AvanceGraficoPhase1Section>[];
  final right = <AvanceGraficoPhase1Section>[];
  for (final s in sections) {
    final side = s.sideLabel.toLowerCase();
    if (side.contains('super')) {
      top.add(s);
    } else if (side.contains('infer')) {
      bottom.add(s);
    } else if (side.contains('izq')) {
      left.add(s);
    } else if (side.contains('der')) {
      right.add(s);
    } else {
      top.add(s);
    }
  }
  return _Phase1Groups(top: top, bottom: bottom, left: left, right: right);
}

Color _hexColor(String value) {
  final cleaned = value.replaceAll('#', '').trim();
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(normalized, radix: 16) ?? 0xFF94A3B8);
}
