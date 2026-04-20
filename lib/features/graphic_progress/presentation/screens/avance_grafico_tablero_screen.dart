// PROPUESTA B — "TABLERO EJECUTIVO"
// Diseño ejecutivo: header oscuro con anillos de progreso por fase,
// contenido por fase en TabBarView, matrices más ricas y navegación por pisos.
// Mejoras clave sobre Codex:
//   - Fase 1: celda interactiva con tooltip de estado, shape responsivo con AspectRatio
//   - Fase 2: matriz piso×sector con scroll bidireccional + headers etiquetados
//   - Fase 3: tabs de piso + tabla sector×actividad con color por estado
//   - Header: 3 anillos de progreso circular individuales por fase
import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

abstract final class _T {
  static const bg = Color(0xFFF0F5FB);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE0EAF5);
  static const primary = Color(0xFF0A66B7);
  static const primaryDark = Color(0xFF063D73);
  static const accent = Color(0xFFD6E8FA);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const green = Color(0xFF10B981);
  static const teal = Color(0xFF0B7A43);
}

class AvanceGraficoTableroScreen extends StatefulWidget {
  const AvanceGraficoTableroScreen({super.key});

  @override
  State<AvanceGraficoTableroScreen> createState() => _AvanceGraficoTableroScreenState();
}

class _AvanceGraficoTableroScreenState extends State<AvanceGraficoTableroScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _selectedFloor = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() => _selectedFloor = 0));
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
          return const Scaffold(
            backgroundColor: _T.bg,
            body: Center(child: CircularProgressIndicator(color: _T.primary)),
          );
        }

        final s = data.summary;
        return Scaffold(
          backgroundColor: _T.bg,
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: _T.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _TableroHeader(projectName: project.name, summary: s),
                ),
                bottom: TabBar(
                  controller: _tab,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'FASE 1'),
                    Tab(text: 'FASE 2'),
                    Tab(text: 'FASE 3'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                _Phase1Tablero(data: data.phase1),
                _Phase2Tablero(data: data.phase2),
                _Phase3Tablero(
                  data: data.phase3,
                  selectedFloor: _selectedFloor,
                  onFloorChange: (i) => setState(() => _selectedFloor = i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Header con anillos ───────────────────────────────────────────────────────

class _TableroHeader extends StatelessWidget {
  const _TableroHeader({required this.projectName, required this.summary});
  final String projectName;
  final AvanceGraficoSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.primaryDark, _T.primary],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avance Grafico',
                        style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(projectName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _ActiveBadge(active: summary.isActive),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RingCard(label: 'Fase 1', value: summary.phase1Completion),
              _RingCard(label: 'Fase 2', value: summary.phase2Completion),
              _RingCard(label: 'Fase 3', value: summary.phase3Completion),
              _RingCard(
                label: 'Total',
                value: (summary.phase1Completion + summary.phase2Completion + summary.phase3Completion) / 3,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(active ? 'Activo' : 'Inactivo',
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _RingCard extends StatelessWidget {
  const _RingCard({required this.label, required this.value, this.highlight = false});
  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: highlight ? Border.all(color: Colors.white.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text('${(value * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── FASE 1 ───────────────────────────────────────────────────────────────────

class _Phase1Tablero extends StatelessWidget {
  const _Phase1Tablero({required this.data});
  final AvanceGraficoPhase1Data? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _EmptyTab();
    final d = data!;
    final groups = _groupByLado(d.sections);
    final pct = d.totalPositions == 0 ? 0.0 : d.completedPositions / d.totalPositions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Stats row
        Row(children: [
          Expanded(child: _StatTile(label: 'Completadas', value: '${d.completedPositions}', color: _T.green)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Total', value: '${d.totalPositions}', color: _T.primary)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Avance', value: '${(pct * 100).round()}%', color: _T.primary)),
        ]),
        const SizedBox(height: 14),
        // Config info
        _Box(
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _InfoTag(Icons.aspect_ratio_rounded, d.shapeLabel),
              _InfoTag(Icons.rotate_right_rounded, d.directionLabel),
              _InfoTag(Icons.grid_on_rounded, '${d.sections.length} secciones'),
              _InfoTag(Icons.block_rounded, '${d.notApplicablePositions} no aplica'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Graphic manager — responsive, no fixed 860px
        _Box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.architecture_rounded, size: 16, color: _T.primary),
                SizedBox(width: 6),
                Text('Manejador de edificio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.text)),
              ]),
              const SizedBox(height: 16),
              if (groups.top.isNotEmpty) ...[
                Center(child: _HorizontalSections(sections: groups.top, label: 'Superior')),
                const SizedBox(height: 12),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (groups.left.isNotEmpty) ...[
                      Flexible(
                        flex: 2,
                        child: _VerticalSections(sections: groups.left, label: 'Izq.'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      flex: 3,
                      child: _BuildingCenter(
                        shape: d.shapeLabel,
                        completed: d.completedPositions,
                        total: d.totalPositions,
                      ),
                    ),
                    if (groups.right.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: _VerticalSections(sections: groups.right, label: 'Der.'),
                      ),
                    ],
                  ],
                ),
              ),
              if (groups.bottom.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(child: _HorizontalSections(sections: groups.bottom, label: 'Inferior')),
              ],
              const SizedBox(height: 14),
              // Legend
              Wrap(spacing: 12, runSpacing: 6, children: const [
                _Dot(label: 'Pendiente', color: Color(0xFFBEBEB9)),
                _Dot(label: 'Completado', color: Color(0xFF6ECC77)),
                _Dot(label: 'Sem. actual', color: Color(0xFF0190DC)),
                _Dot(label: 'No aplica', color: Color(0xFF111827)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Level progress
        _Box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Avance por nivel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.text)),
              const SizedBox(height: 12),
              ..._levelProgress(d.sections),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _levelProgress(List<AvanceGraficoPhase1Section> sections) {
    final map = <int, List<int>>{};
    for (final s in sections) {
      for (final c in s.cells) {
        if (c.statusCode == 4) { continue; }
        final b = map.putIfAbsent(c.level, () => [0, 0]);
        b[1]++;
        if (c.statusCode == 2) { b[0]++; }
      }
    }
    final levels = map.keys.toList()..sort();
    return levels.map((lvl) {
      final done = map[lvl]![0];
      final tot = map[lvl]![1];
      final pct = tot == 0 ? 0.0 : done / tot;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(
            width: 56,
            child: Text('Nivel $lvl',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.text)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: _T.stroke,
                valueColor: const AlwaysStoppedAnimation<Color>(_T.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('${(pct * 100).round()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _T.primary),
                textAlign: TextAlign.end),
          ),
        ]),
      );
    }).toList();
  }
}

class _HorizontalSections extends StatelessWidget {
  const _HorizontalSections({required this.sections, required this.label});
  final List<AvanceGraficoPhase1Section> sections;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 0.8, color: _T.faint, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: sections.map((s) => _SectionBlock(section: s)).toList(),
          ),
        ],
      );
}

class _VerticalSections extends StatelessWidget {
  const _VerticalSections({required this.sections, required this.label});
  final List<AvanceGraficoPhase1Section> sections;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 0.8, color: _T.faint, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _SectionBlock(section: s),
              )),
        ],
      );
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});
  final AvanceGraficoPhase1Section section;

  @override
  Widget build(BuildContext context) {
    final byLevel = <int, List<AvanceGraficoPhase1Cell>>{};
    for (final c in section.cells) {
      byLevel.putIfAbsent(c.level, () => []).add(c);
    }
    final levels = byLevel.keys.toList()..sort((a, b) => b.compareTo(a));
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(section.abbreviation.isEmpty ? section.name : section.abbreviation,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _T.muted)),
          const SizedBox(height: 4),
          ...levels.map((lvl) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: (byLevel[lvl]!..sort((a, b) => a.bay.compareTo(b.bay)))
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: _CellBox(cell: c, size: 20),
                          ))
                      .toList(),
                ),
              )),
        ],
      ),
    );
  }
}

class _BuildingCenter extends StatelessWidget {
  const _BuildingCenter({required this.shape, required this.completed, required this.total});
  final String shape;
  final int completed;
  final int total;

  double get _aspect {
    final v = shape.toLowerCase();
    if (v.contains('vertical')) { return 0.55; }
    if (v.contains('horizontal')) { return 1.8; }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : completed / total;
    return Center(
      child: AspectRatio(
        aspectRatio: _aspect,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _T.primaryDark,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x33063D73), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.apartment_rounded, color: Colors.white38, size: 20),
              const SizedBox(height: 6),
              Text('${(pct * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('$completed/$total', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(shape, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellBox extends StatelessWidget {
  const _CellBox({required this.cell, this.size = 24});
  final AvanceGraficoPhase1Cell cell;
  final double size;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: '${cell.level}.${cell.bay}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _hexColor(cell.colorHex),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      );
}

// ─── FASE 2 ───────────────────────────────────────────────────────────────────

class _Phase2Tablero extends StatelessWidget {
  const _Phase2Tablero({required this.data});
  final AvanceGraficoPhase2Data? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _EmptyTab();
    final d = data!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          Expanded(child: _StatTile(label: 'Completadas', value: '${d.completedCount}', color: _T.green)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Calidad', value: '${d.approvedCount}', color: _T.teal)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Pendientes', value: '${d.pendingCount}', color: _T.muted)),
        ]),
        const SizedBox(height: 12),
        _Box(
          child: Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              _InfoTag(Icons.layers_rounded,
                  d.uniformFloorsEnabled ? 'Pisos uniformes (${d.uniformFloorsCount})' : 'Pisos variables'),
              _InfoTag(Icons.photo_library_outlined, '${d.documentsCount} evidencias'),
              _InfoTag(Icons.grid_on_rounded, '${d.totalCells} celdas'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Actividades', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _T.text)),
        const SizedBox(height: 10),
        ...d.activities.map((act) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ActivityMatrixCard(activity: act),
            )),
      ],
    );
  }
}

class _ActivityMatrixCard extends StatelessWidget {
  const _ActivityMatrixCard({required this.activity});
  final AvanceGraficoPhase2Activity activity;

  @override
  Widget build(BuildContext context) {
    final floors = activity.cells.map((c) => c.floor).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final sectors = activity.cells.map((c) => c.sector).toSet().toList()..sort();
    final cellMap = <String, AvanceGraficoPhase2Cell>{};
    for (final c in activity.cells) {
      cellMap['${c.floor}:${c.sector}'] = c;
    }
    final progress = activity.totalCells == 0
        ? 0.0
        : (activity.completedCount + activity.approvedCount) / activity.totalCells;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _T.accent, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(
                  activity.abbreviation.isEmpty ? 'AG' : activity.abbreviation,
                  style: const TextStyle(color: _T.primary, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _T.text)),
                    Text(
                      '${activity.floors}P · ${activity.basements}S · ${activity.sectors} sectores',
                      style: const TextStyle(fontSize: 10, color: _T.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(progress * 100).round()}%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _T.primary)),
                  Text('${activity.completedCount + activity.approvedCount}/${activity.totalCells}',
                      style: const TextStyle(fontSize: 10, color: _T.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress, minHeight: 6,
              backgroundColor: _T.stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(_T.primary),
            ),
          ),
          if (floors.isNotEmpty && sectors.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Labeled matrix piso × sector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sector header
                  Row(children: [
                    const SizedBox(width: 40),
                    ...sectors.map((s) => Container(
                          width: 30, margin: const EdgeInsets.only(right: 3),
                          alignment: Alignment.center,
                          child: Text('S$s',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _T.muted)),
                        )),
                  ]),
                  const SizedBox(height: 4),
                  ...floors.map((floor) {
                    final isBasement = floor <= 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                              decoration: isBasement
                                  ? BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(6),
                                    )
                                  : null,
                              child: Text(
                                isBasement ? 'Sot ${floor.abs()}' : 'P $floor',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: isBasement ? Colors.white : _T.muted,
                                ),
                              ),
                            ),
                            ...sectors.map((sector) {
                              final cell = cellMap['$floor:$sector'];
                              return Container(
                                width: 30, height: 22,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: cell != null ? _hexColor(cell.colorHex) : _T.stroke,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              );
                            }),
                          ],
                        ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 4, children: const [
              _Dot(label: 'Pendiente', color: Color(0xFFA0B0C8)),
              _Dot(label: 'En proceso', color: Color(0xFFF59E0B)),
              _Dot(label: 'Completado', color: Color(0xFF10B981)),
              _Dot(label: 'Calidad', color: Color(0xFF0B7A43)),
              _Dot(label: 'No aplica', color: Color(0xFFCBD5E1)),
            ]),
          ],
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _StatusCount('${activity.pendingCount}', 'pendientes', const Color(0xFFA0B0C8)),
            _StatusCount('${activity.inProgressCount}', 'proceso', const Color(0xFFF59E0B)),
            _StatusCount('${activity.completedCount}', 'completadas', _T.green),
            _StatusCount('${activity.approvedCount}', 'calidad', _T.teal),
          ]),
        ],
      ),
    );
  }
}

// ─── FASE 3 ───────────────────────────────────────────────────────────────────

class _Phase3Tablero extends StatelessWidget {
  const _Phase3Tablero({required this.data, required this.selectedFloor, required this.onFloorChange});
  final AvanceGraficoPhase3Data? data;
  final int selectedFloor;
  final ValueChanged<int> onFloorChange;

  @override
  Widget build(BuildContext context) {
    if (data == null) return const _EmptyTab();
    final d = data!;
    if (d.floors.isEmpty) return const _EmptyTab();
    final safeFloor = selectedFloor.clamp(0, d.floors.length - 1);
    final floor = d.floors[safeFloor];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          Expanded(child: _StatTile(label: 'Pisos', value: '${d.floorCount}', color: _T.primary)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Sectores', value: '${d.sectorCount}', color: _T.primary)),
          const SizedBox(width: 8),
          Expanded(child: _StatTile(label: 'Actividades', value: '${d.activityCount}', color: _T.primary)),
        ]),
        const SizedBox(height: 14),
        const Text('Seleccionar piso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.text)),
        const SizedBox(height: 8),
        // Piso picker horizontal
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(d.floors.length, (i) {
              final f = d.floors[i];
              final active = i == safeFloor;
              final pct = f.totalCells == 0
                  ? 0.0
                  : (f.completedCount + f.approvedCount) / f.totalCells;
              return GestureDetector(
                onTap: () => onFloorChange(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(right: i < d.floors.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? _T.primary : _T.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? _T.primary : _T.stroke),
                    boxShadow: active
                        ? const [BoxShadow(color: Color(0x220A66B7), blurRadius: 10, offset: Offset(0, 4))]
                        : null,
                  ),
                  child: Column(children: [
                    Text(f.abbreviation.isEmpty ? f.name : f.abbreviation,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: active ? Colors.white : _T.text)),
                    const SizedBox(height: 4),
                    Text('${(pct * 100).round()}%',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: active ? Colors.white70 : _T.muted)),
                  ]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Selected floor detail
        _Box(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: _T.accent, borderRadius: BorderRadius.circular(10)),
                  child: Text(floor.abbreviation.isEmpty ? floor.name : floor.abbreviation,
                      style: const TextStyle(color: _T.primary, fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(floor.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _T.text)),
                      Text(floor.planName ?? 'Sin plano',
                          style: const TextStyle(fontSize: 10, color: _T.muted)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatusCount('${floor.completedCount}', 'completadas', _T.green)),
                const SizedBox(width: 6),
                Expanded(child: _StatusCount('${floor.approvedCount}', 'calidad', _T.teal)),
                const SizedBox(width: 6),
                Expanded(child: _StatusCount('${floor.inProgressCount}', 'proceso', const Color(0xFFF59E0B))),
                const SizedBox(width: 6),
                Expanded(child: _StatusCount('${floor.pendingCount}', 'pendientes', _T.muted)),
              ]),
              if (floor.sectors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text('Sectores en este piso',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.text)),
                const SizedBox(height: 12),
                ...floor.sectors.map((sector) => _SectorProgressRow(sector: sector)),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF795548)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La tabla actividad × sector por piso se habilitará con la conexión al backend (avagra_actividadxsectorxpisos).',
                      style: TextStyle(fontSize: 10, color: Color(0xFF5D4037)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectorProgressRow extends StatelessWidget {
  const _SectorProgressRow({required this.sector});
  final AvanceGraficoPhase3SectorProgress sector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(sector.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _T.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(sector.stateLabel,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _T.primary)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Completado', style: TextStyle(fontSize: 9, color: _T.faint)),
                    const Spacer(),
                    Text('${(sector.completedPercent * 100).round()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _T.green)),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: sector.completedPercent, minHeight: 7,
                      backgroundColor: _T.stroke,
                      valueColor: const AlwaysStoppedAnimation<Color>(_T.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Calidad', style: TextStyle(fontSize: 9, color: _T.faint)),
                    const Spacer(),
                    Text('${(sector.approvedPercent * 100).round()}%',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _T.teal)),
                  ]),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: sector.approvedPercent, minHeight: 7,
                      backgroundColor: _T.stroke,
                      valueColor: const AlwaysStoppedAnimation<Color>(_T.teal),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _T.stroke),
        ),
        child: child,
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.stroke),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: _T.muted), textAlign: TextAlign.center),
          ],
        ),
      );
}

class _InfoTag extends StatelessWidget {
  const _InfoTag(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _T.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _T.primary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _T.muted)),
          ],
        ),
      );
}

class _StatusCount extends StatelessWidget {
  const _StatusCount(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.stroke),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: _T.muted), textAlign: TextAlign.center),
          ],
        ),
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 10, color: _T.muted)),
        ],
      );
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, color: _T.faint, size: 36),
            SizedBox(height: 12),
            Text('Sin configuracion para esta fase.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _T.muted)),
          ],
        ),
      );
}

_GroupedSections _groupByLado(List<AvanceGraficoPhase1Section> sections) {
  final top = <AvanceGraficoPhase1Section>[];
  final bottom = <AvanceGraficoPhase1Section>[];
  final left = <AvanceGraficoPhase1Section>[];
  final right = <AvanceGraficoPhase1Section>[];
  for (final s in sections) {
    final side = s.sideLabel.toLowerCase();
    if (side.contains('super')) { top.add(s); }
    else if (side.contains('infer')) { bottom.add(s); }
    else if (side.contains('izq')) { left.add(s); }
    else if (side.contains('der')) { right.add(s); }
    else { top.add(s); }
  }
  return _GroupedSections(top: top, bottom: bottom, left: left, right: right);
}

class _GroupedSections {
  const _GroupedSections({required this.top, required this.bottom, required this.left, required this.right});
  final List<AvanceGraficoPhase1Section> top;
  final List<AvanceGraficoPhase1Section> bottom;
  final List<AvanceGraficoPhase1Section> left;
  final List<AvanceGraficoPhase1Section> right;
}

Color _hexColor(String value) {
  final cleaned = value.replaceAll('#', '').trim();
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(normalized, radix: 16) ?? 0xFF94A3B8);
}
