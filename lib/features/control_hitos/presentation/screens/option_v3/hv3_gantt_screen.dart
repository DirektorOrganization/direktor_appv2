// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7);
  static const accent      = Color(0xFF1167C8);
  static const accentLight = Color(0xFFCCDFF7);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const red         = Color(0xFFEF4444);
  static const green       = Color(0xFF10B981);
  static const yellow      = Color(0xFFF59E0B);
  static const white       = Colors.white;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Color _statusColor(MilestoneRecord m) {
  if (m.isCompleted) return _D.green;
  if (m.isDelayed) return _D.red;
  return _D.accent;
}

String _fmtShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

// ─── GANTT bar calc ───────────────────────────────────────────────────────────
// Returns 0.0..1.0 of where `date` falls in [start, end].
double _barFrac(DateTime start, DateTime end, DateTime date) {
  final total = end.difference(start).inDays;
  if (total <= 0) return 0.0;
  final elapsed = date.difference(start).inDays;
  return (elapsed / total).clamp(0.0, 1.0);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Hv3GanttScreen extends StatefulWidget {
  const Hv3GanttScreen({super.key});

  @override
  State<Hv3GanttScreen> createState() => _Hv3GanttScreenState();
}

enum _GanttFilter { all, inProgress, delayed, completed }

class _Hv3GanttScreenState extends State<Hv3GanttScreen> {
  _GanttFilter _filter = _GanttFilter.all;

  List<MilestoneRecord> _applyFilter(List<MilestoneRecord> all) {
    return switch (_filter) {
      _GanttFilter.all        => all,
      _GanttFilter.inProgress => all.where((m) => m.isInProgress).toList(),
      _GanttFilter.delayed    => all.where((m) => m.isDelayed).toList(),
      _GanttFilter.completed  => all.where((m) => m.isCompleted).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final milestones = ctrl.milestones;
        final summary    = ctrl.milestoneSummary;
        final project    = ctrl.currentProject;
        final filtered   = _applyFilter(milestones);

        // Determine date range from all milestones for Gantt axis
        DateTime? earliest, latest;
        for (final m in milestones) {
          final s = m.effectiveContractualDate;
          final e = m.effectiveTargetDate;
          if (earliest == null || s.isBefore(earliest)) earliest = s;
          if (latest == null || e.isAfter(latest)) latest = e;
        }
        // Fallback range
        earliest ??= DateTime.now().subtract(const Duration(days: 30));
        latest   ??= DateTime.now().add(const Duration(days: 30));
        // Add 5% margin
        final rangeDays   = latest.difference(earliest).inDays;
        final margin      = Duration(days: math.max((rangeDays * 0.05).round(), 3));
        final axisStart   = earliest.subtract(margin);
        final axisEnd     = latest.add(margin);
        final today       = DateTime.now();

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: Column(
            children: [
              // ── KPI strip ─────────────────────────────────────────────────
              _KpiStrip(summary: summary, total: milestones.length),
              // ── Axis header ───────────────────────────────────────────────
              _GanttAxisHeader(
                start: axisStart,
                end: axisEnd,
                today: today,
              ),
              // ── Filter strip ──────────────────────────────────────────────
              _FilterBar(
                current: _filter,
                summary: summary,
                total: milestones.length,
                onChanged: (f) => setState(() => _filter = f),
              ),
              // ── Gantt rows ────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _GanttRow(
                          milestone: filtered[i],
                          axisStart: axisStart,
                          axisEnd: axisEnd,
                          today: today,
                          onTap: () => Navigator.of(ctx).pushNamed(
                            RouteNames.controlHitosV2Detail,
                            arguments: MilestoneDetailArgs(
                              milestoneId: filtered[i].id,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                Navigator.of(ctx).pushNamed(RouteNames.controlHitosCreate),
            backgroundColor: _D.primary,
            foregroundColor: _D.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nuevo Hito',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext ctx, ProjectRecord? project) {
    return AppBar(
      backgroundColor: _D.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hitos · Gantt',
            style: TextStyle(
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
        IconButton(
          icon: const Icon(Icons.format_list_bulleted_rounded, color: _D.muted),
          tooltip: 'Vista lista',
          onPressed: () =>
              Navigator.of(ctx).pushNamed(RouteNames.controlHitosV2),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

// ─── KPI Strip ───────────────────────────────────────────────────────────────
class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.summary, required this.total});
  final MilestoneDashboardSummary summary;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = summary.compliance;
    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Compliance mini arc
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(52, 52),
                  painter: _ArcPainter(percent: pct / 100),
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: pct >= 80
                        ? _D.green
                        : pct >= 50
                            ? _D.yellow
                            : _D.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _KpiPill(
                  label: 'Total',
                  value: '$total',
                  color: _D.primary,
                ),
                _KpiPill(
                  label: 'Completados',
                  value: '${summary.completedCount}',
                  color: _D.green,
                ),
                _KpiPill(
                  label: 'Retrasados',
                  value: '${summary.delayedCount}',
                  color: summary.delayedCount > 0 ? _D.red : _D.mutedLight,
                ),
                if (summary.accumulatedPenalty > 0)
                  _KpiPill(
                    label: 'Penalidad',
                    value: '\$${summary.accumulatedPenalty.toStringAsFixed(0)}',
                    color: _D.red,
                    icon: Icons.gpp_bad_outlined,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiPill extends StatelessWidget {
  const _KpiPill({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: _D.muted)),
        ],
      ),
    );
  }
}

// ─── Arc Painter ─────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap  = StrokeCap.round;

    paint.color = _D.stroke;
    canvas.drawCircle(center, radius, paint);

    final pct   = percent * 100;
    paint.color = pct >= 80 ? _D.green : (pct >= 50 ? _D.yellow : _D.red);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.percent != percent;
}

// ─── Gantt Axis Header ────────────────────────────────────────────────────────
class _GanttAxisHeader extends StatelessWidget {
  const _GanttAxisHeader({
    required this.start,
    required this.end,
    required this.today,
  });
  final DateTime start;
  final DateTime end;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    const labelWidth = 100.0;
    final totalDays  = end.difference(start).inDays;

    // Generate ~5 evenly-spaced tick dates
    final ticks = <DateTime>[];
    final step  = math.max(totalDays ~/ 4, 1);
    for (var i = 0; i <= totalDays; i += step) {
      ticks.add(start.add(Duration(days: i)));
    }

    // Today position
    final todayFrac = _barFrac(start, end, today);

    return Container(
      color: _D.white,
      child: Column(
        children: [
          Container(height: 1, color: _D.stroke),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                // Label column placeholder
                SizedBox(
                  width: labelWidth,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'HITO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _D.mutedLight,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                // Gantt area
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final w = constraints.maxWidth;
                      return Stack(
                        children: [
                          // Tick labels
                          ...ticks.map((t) {
                            final frac = _barFrac(start, end, t);
                            return Positioned(
                              left: frac * w - 16,
                              top: 8,
                              child: Text(
                                _fmtShort(t),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: _D.mutedLight,
                                ),
                              ),
                            );
                          }),
                          // Today marker
                          if (todayFrac >= 0 && todayFrac <= 1)
                            Positioned(
                              left: todayFrac * w,
                              top: 2,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _D.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'hoy',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: _D.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _D.stroke),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.summary,
    required this.total,
    required this.onChanged,
  });
  final _GanttFilter current;
  final MilestoneDashboardSummary summary;
  final int total;
  final void Function(_GanttFilter) onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <({_GanttFilter f, String label, int count})>[
      (f: _GanttFilter.all,        label: 'Todos',       count: total),
      (f: _GanttFilter.inProgress, label: 'En proceso',  count: summary.inProgressCount),
      (f: _GanttFilter.delayed,    label: 'Retrasados',  count: summary.delayedCount),
      (f: _GanttFilter.completed,  label: 'Completados', count: summary.completedCount),
    ];

    return Container(
      color: _D.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: filters.map((f) {
                final sel = current == f.f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(f.f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _D.primary : _D.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? _D.primary : _D.stroke,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? _D.white : _D.muted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _D.white.withValues(alpha: 0.2)
                                  : _D.stroke,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${f.count}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: sel ? _D.white : _D.muted,
                              ),
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
          Container(height: 1, color: _D.stroke),
        ],
      ),
    );
  }
}

// ─── Gantt Row ────────────────────────────────────────────────────────────────
class _GanttRow extends StatelessWidget {
  const _GanttRow({
    required this.milestone,
    required this.axisStart,
    required this.axisEnd,
    required this.today,
    required this.onTap,
  });
  final MilestoneRecord milestone;
  final DateTime axisStart;
  final DateTime axisEnd;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m          = milestone;
    final color      = _statusColor(m);
    const labelWidth = 100.0;
    final barStart   = _barFrac(axisStart, axisEnd, m.effectiveContractualDate);
    final barEnd     = _barFrac(axisStart, axisEnd, m.effectiveTargetDate);
    final todayFrac  = _barFrac(axisStart, axisEnd, today);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _D.stroke),
          ),
        ),
        child: Row(
          children: [
            // ── Label column ───────────────────────────────────────────────
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.code.isNotEmpty ? m.code : '#${m.order}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      m.description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _D.muted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // ── Gantt bar ──────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final w = constraints.maxWidth;
                  final barLeft   = barStart * w;
                  final barRight  = barEnd * w;
                  final barWidth  = (barRight - barLeft).clamp(4.0, w);
                  final todayX    = (todayFrac * w).clamp(0.0, w);
                  final isPenal   = m.isPenalizable && m.isDelayed;

                  return SizedBox(
                    height: 52,
                    child: Stack(
                      children: [
                        // Background grid lines (faint)
                        CustomPaint(
                          size: Size(w, 52),
                          painter: _GridPainter(),
                        ),
                        // Bar
                        Positioned(
                          left: barLeft,
                          top: 14,
                          width: barWidth,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 5),
                            child: m.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: _D.green,
                                  )
                                : null,
                          ),
                        ),
                        // Today vertical line
                        if (todayFrac >= 0 && todayFrac <= 1)
                          Positioned(
                            left: todayX,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1.5,
                              color: _D.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        // Penalty warning dot
                        if (isPenal)
                          Positioned(
                            right: 6,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _D.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        // Dates
                        Positioned(
                          left: barLeft,
                          bottom: 3,
                          child: Text(
                            _fmtShort(m.effectiveContractualDate),
                            style: const TextStyle(
                              fontSize: 8,
                              color: _D.mutedLight,
                            ),
                          ),
                        ),
                        if (barWidth > 30)
                          Positioned(
                            left: barLeft + barWidth - 28,
                            bottom: 3,
                            child: Text(
                              _fmtShort(m.effectiveTargetDate),
                              style: const TextStyle(
                                fontSize: 8,
                                color: _D.mutedLight,
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
        ),
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color     = _D.stroke
      ..strokeWidth = 0.5;
    const cols = 8;
    for (var i = 1; i < cols; i++) {
      final x = size.width * i / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _D.accentLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.table_chart_outlined,
              size: 40,
              color: _D.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sin hitos en esta categoria',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _D.muted,
            ),
          ),
        ],
      ),
    );
  }
}
