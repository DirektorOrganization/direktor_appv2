import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

// ─── Palette (aligned with CAMPO screen) ─────────────────────────────────────
abstract final class _C {
  static const bg      = Color(0xFFF3F7FC);
  static const surface = Colors.white;
  static const stroke  = Color(0xFFDDE8F5);
  static const primary = Color(0xFF0A66B7);
  static const text    = Color(0xFF0F172A);
  static const muted   = Color(0xFF64748B);
  static const faint   = Color(0xFF94A3B8);
  static const green   = Color(0xFF10B981);
  static const amber   = Color(0xFFF59E0B);
  static const red     = Color(0xFFEF4444);
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AvanceGraficoResumenScreen extends StatelessWidget {
  const AvanceGraficoResumenScreen({super.key});

  void _enter(BuildContext context, int tab) {
    Navigator.pushNamed(
      context,
      RouteNames.avanceGraficoCampo,
      arguments: tab,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl    = AppScope.of(context);
    final project = ctrl.currentProject;
    final data    = ctrl.avanceGraficoData;

    final summary = data?.summary;
    final p1 = data?.phase1;
    final p2 = data?.phase2;
    final p3 = data?.phase3;

    final overall = summary == null
        ? 0.0
        : (summary.phase1Completion + summary.phase2Completion + summary.phase3Completion) / 3;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
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
              project?.name ?? 'Cargando...',
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
          if (summary != null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD6E8FA),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _C.stroke),
              ),
              child: Text(
                '${(overall * 100).round()}% General',
                style: const TextStyle(
                  color: _C.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.stroke),
        ),
      ),
      body: data == null
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ── Overall strip ─────────────────────────────────────────
                _OverallStrip(overall: overall),
                const SizedBox(height: 20),
                // ── Phase cards ───────────────────────────────────────────
                _PhaseCard(
                  phase: 1,
                  title: 'Fase 1',
                  subtitle: 'Secciones y posiciones',
                  pct: summary?.phase1Completion ?? 0,
                  completed: p1?.completedPositions ?? 0,
                  total: p1?.totalPositions ?? 0,
                  color: _C.primary,
                  rows: p1 == null ? [] : _phase1Rows(p1),
                  onEnter: () => _enter(context, 0),
                ),
                const SizedBox(height: 14),
                _PhaseCard(
                  phase: 2,
                  title: 'Fase 2',
                  subtitle: 'Actividades y cuadros',
                  pct: summary?.phase2Completion ?? 0,
                  completed: p2?.completedCount ?? 0,
                  total: p2?.totalCells ?? 0,
                  color: _C.green,
                  rows: p2 == null ? [] : _phase2Rows(p2),
                  onEnter: () => _enter(context, 1),
                ),
                const SizedBox(height: 14),
                _PhaseCard(
                  phase: 3,
                  title: 'Fase 3',
                  subtitle: 'Pisos, sectores y actividades',
                  pct: summary?.phase3Completion ?? 0,
                  completed: p3?.completedCount ?? 0,
                  total: p3?.totalCells ?? 0,
                  color: _C.amber,
                  rows: p3 == null ? [] : _phase3Rows(p3),
                  onEnter: () => _enter(context, 2),
                ),
              ],
            ),
    );
  }

  List<_RowData> _phase1Rows(AvanceGraficoPhase1Data p) {
    // Group cells by level → show per-level progress
    final byLevel = <int, _LevelStats>{};
    for (final sec in p.sections) {
      for (final cell in sec.cells) {
        final s = byLevel.putIfAbsent(cell.level, () => _LevelStats());
        s.total++;
        if (cell.statusCode == 2 || cell.statusCode == 3) s.completed++;
      }
    }
    final levels = byLevel.keys.toList()..sort();
    return levels.take(6).map((lvl) {
      final s = byLevel[lvl]!;
      final pct = s.total == 0 ? 0.0 : s.completed / s.total;
      return _RowData('Nivel $lvl', s.completed, s.total, pct);
    }).toList();
  }

  List<_RowData> _phase2Rows(AvanceGraficoPhase2Data p) =>
      p.activities.take(5).map((a) {
        final pct = a.totalCells == 0 ? 0.0 : a.completedCount / a.totalCells;
        return _RowData(a.name, a.completedCount, a.totalCells, pct);
      }).toList();

  List<_RowData> _phase3Rows(AvanceGraficoPhase3Data p) =>
      p.floors.take(5).map((f) {
        final pct = f.totalCells == 0 ? 0.0 : f.completedCount / f.totalCells;
        return _RowData(f.name, f.completedCount, f.totalCells, pct);
      }).toList();
}

class _LevelStats {
  int completed = 0, total = 0;
}

class _RowData {
  const _RowData(this.label, this.completed, this.total, this.pct);
  final String label;
  final int completed, total;
  final double pct;
}

// ─── Overall progress strip ───────────────────────────────────────────────────

class _OverallStrip extends StatelessWidget {
  const _OverallStrip({required this.overall});
  final double overall;

  @override
  Widget build(BuildContext context) {
    final pct = (overall * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bar_chart_rounded, size: 16, color: _C.primary),
            const SizedBox(width: 6),
            const Text('Progreso general del módulo',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.muted)),
            const Spacer(),
            Text('$pct%',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _C.primary)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: overall, minHeight: 8,
              backgroundColor: _C.stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(_C.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase card ──────────────────────────────────────────────────────────────

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.title,
    required this.subtitle,
    required this.pct,
    required this.completed,
    required this.total,
    required this.color,
    required this.rows,
    required this.onEnter,
  });

  final int phase;
  final String title, subtitle;
  final double pct;
  final int completed, total;
  final Color color;
  final List<_RowData> rows;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text('$phase',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: _C.text)),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 11, color: _C.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _RingProgress(pct: pct, color: color, size: 60),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Detail rows ─────────────────────────────────────────────────
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: _C.faint),
                const SizedBox(width: 6),
                const Text('Sin datos disponibles',
                    style: TextStyle(fontSize: 12, color: _C.faint)),
              ]),
            )
          else ...[
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: Text(phase == 1 ? 'NIVEL' : phase == 2 ? 'ACTIVIDAD' : 'PISO',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: _C.faint, letterSpacing: 0.8))),
                SizedBox(width: 90,
                    child: Text('COMPLETADO / TOTAL',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                            color: _C.faint, letterSpacing: 0.6))),
                const SizedBox(width: 40,
                    child: Text('%', textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                            color: _C.faint, letterSpacing: 0.8))),
              ]),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ...rows.map((r) => _DetailRow(row: r, color: color)),
          ],
          // ── Footer ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('$completed / $total',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _C.text)),
              const Spacer(),
              FilledButton.icon(
                onPressed: onEnter,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login_rounded, size: 15),
                label: const Text('Ingresar',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Detail row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row, required this.color});
  final _RowData row;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pctInt = (row.pct * 100).round();
    final textColor = pctInt == 0 ? _C.faint : pctInt < 10 ? _C.red : _C.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Expanded(
          child: Text(row.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _C.text),
              overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: 90,
          child: Text('${row.completed} / ${row.total}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _C.muted)),
        ),
        SizedBox(
          width: 40,
          child: Text('$pctInt%',
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
        ),
      ]),
    );
  }
}

// ─── Ring progress (custom paint) ────────────────────────────────────────────

class _RingProgress extends StatelessWidget {
  const _RingProgress({required this.pct, required this.color, required this.size});
  final double pct;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pctInt = (pct * 100).round();
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _RingPainter(pct: pct, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$pctInt%',
                  style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w900,
                      color: pct == 0 ? _C.faint : color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.pct, required this.color});
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (size.width / 2) - 6;
    const strokeW = 6.0;
    final bg = Paint()
      ..color = const Color(0xFFE2EAF4)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, bg);
    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -pi / 2,
        2 * pi * pct,
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct || old.color != color;
}
