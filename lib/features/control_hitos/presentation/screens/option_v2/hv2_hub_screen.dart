// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Paleta Direktor ──────────────────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
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
  if (m.isInProgress) return _D.accent;
  return _D.mutedLight;
}

IconData _statusIcon(MilestoneRecord m) {
  if (m.isCompleted) return Icons.check_circle_rounded;
  if (m.isDelayed) return Icons.warning_amber_rounded;
  if (m.isInProgress) return Icons.timelapse_rounded;
  return Icons.pending_outlined;
}

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

Color _complianceColor(double pct) {
  if (pct >= 80) return _D.green;
  if (pct >= 50) return _D.yellow;
  return _D.red;
}

// ─── Clasificación colors ─────────────────────────────────────────────────────
Color _classColor(String? label) {
  switch (label?.toLowerCase()) {
    case 'contractual': return const Color(0xFF0A66B7);
    case 'crítico':
    case 'critico':     return _D.red;
    case 'calidad':     return const Color(0xFF7C3AED);
    default:            return _D.muted;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Hv2HubScreen extends StatefulWidget {
  const Hv2HubScreen({super.key});

  @override
  State<Hv2HubScreen> createState() => _Hv2HubScreenState();
}

enum _Filter { all, inProgress, delayed, completed, penalizable }

class _Hv2HubScreenState extends State<Hv2HubScreen> {
  _Filter _filter = _Filter.all;
  final _listKey = GlobalKey<AnimatedListState>();

  List<MilestoneRecord> _applyFilter(List<MilestoneRecord> all) {
    return switch (_filter) {
      _Filter.all         => all,
      _Filter.inProgress  => all.where((m) => m.isInProgress).toList(),
      _Filter.delayed     => all.where((m) => m.isDelayed).toList(),
      _Filter.completed   => all.where((m) => m.isCompleted).toList(),
      _Filter.penalizable => all.where((m) => m.isPenalizable && m.isDelayed).toList(),
    };
  }

  void _openDetail(BuildContext ctx, int milestoneId) {
    Navigator.of(ctx).pushNamed(
      RouteNames.controlHitosV2Detail,
      arguments: MilestoneDetailArgs(milestoneId: milestoneId),
    );
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
        final sorted     = [...milestones]..sort((a, b) {
            final aDate = a.effectiveContractualDate;
            final bDate = b.effectiveContractualDate;
            return aDate.compareTo(bDate);
          });

        // Penalizable delayed — for alert
        final penalDelayed = milestones
            .where((m) => m.isPenalizable && m.isDelayed)
            .toList();

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: Column(
            children: [
              // ── Stats ─────────────────────────────────────────────────────
              _StatsPanel(summary: summary, totalCount: milestones.length),
              // ── Journey timeline ─────────────────────────────────────────
              if (sorted.isNotEmpty)
                _JourneyTimeline(
                  milestones: sorted,
                  onTap: (m) => _openDetail(ctx, m.id),
                ),
              // ── Penalty alert ─────────────────────────────────────────────
              if (penalDelayed.isNotEmpty)
                _PenaltyAlert(items: penalDelayed),
              // ── Filters ───────────────────────────────────────────────────
              _FilterBar(
                current: _filter,
                summary: summary,
                totalCount: milestones.length,
                hasPenal: penalDelayed.isNotEmpty,
                onChanged: (f) => setState(() => _filter = f),
              ),
              // ── List ──────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : ListView.builder(
                        key: _listKey,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _MilestoneCard(
                          milestone: filtered[i],
                          onTap: () => _openDetail(ctx, filtered[i].id),
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

  AppBar _buildAppBar(BuildContext ctx, dynamic project) {
    return AppBar(
      backgroundColor: _D.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control de Hitos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _D.text,
            ),
          ),
          if (project != null && project.name.isNotEmpty)
            Text(
              project.name,
              style: const TextStyle(fontSize: 11, color: _D.muted),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded, color: _D.muted),
          tooltip: 'Vista clásica',
          onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.controlHitos),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

// ─── Stats Panel ─────────────────────────────────────────────────────────────
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.summary, required this.totalCount});
  final MilestoneDashboardSummary? summary;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final total     = totalCount;
    final completed = s?.completedCount ?? 0;
    final overdue   = s?.delayedCount ?? 0;
    final pct       = s?.compliance ?? 0.0;

    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          // Compliance ring
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(72, 72),
                  painter: _CompliancePainter(percent: pct / 100),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _complianceColor(pct),
                      ),
                    ),
                    const Text(
                      'cumpl.',
                      style: TextStyle(fontSize: 9, color: _D.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stat pills
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Total',
                  value: '$total',
                  color: _D.primary,
                ),
                _StatPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completados',
                  value: '$completed',
                  color: _D.green,
                ),
                _StatPill(
                  icon: Icons.warning_amber_rounded,
                  label: 'Retrasados',
                  value: '$overdue',
                  color: overdue > 0 ? _D.red : _D.mutedLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _D.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Compliance ring painter ──────────────────────────────────────────────────
class _CompliancePainter extends CustomPainter {
  const _CompliancePainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap  = StrokeCap.round;

    // Track
    paint.color = _D.stroke;
    canvas.drawCircle(center, radius, paint);

    // Arc
    final color = _complianceColor(percent * 100);
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CompliancePainter old) => old.percent != percent;
}

// ─── Journey Timeline ─────────────────────────────────────────────────────────
class _JourneyTimeline extends StatelessWidget {
  const _JourneyTimeline({
    required this.milestones,
    required this.onTap,
  });

  final List<MilestoneRecord> milestones;
  final void Function(MilestoneRecord) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _D.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: _D.stroke),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 13,
                  color: _D.muted,
                ),
                const SizedBox(width: 5),
                const Text(
                  'CAMINO DE HITOS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _D.muted,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '${milestones.length} hitos',
                  style: const TextStyle(fontSize: 10, color: _D.mutedLight),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: milestones.length,
              itemBuilder: (_, i) {
                final m      = milestones[i];
                final isLast = i == milestones.length - 1;
                final color  = _statusColor(m);
                final filled = m.isCompleted;
                final label  = m.code.isNotEmpty ? m.code : '#${m.order}';

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => onTap(m),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Node circle
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: filled
                                  ? color
                                  : color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color,
                                width: m.isInProgress ? 2.5 : 2,
                              ),
                            ),
                            child: Icon(
                              _statusIcon(m),
                              size: 17,
                              color: filled ? _D.white : color,
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Label
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Connecting line (not after last)
                    if (!isLast) ...[
                      const SizedBox(width: 3),
                      _ConnectingLine(isCompleted: m.isCompleted),
                      const SizedBox(width: 3),
                    ],
                  ],
                );
              },
            ),
          ),
          // Legend row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _LegendDot(color: _D.green,    label: 'Completado'),
                const SizedBox(width: 12),
                _LegendDot(color: _D.accent,   label: 'En proceso'),
                const SizedBox(width: 12),
                _LegendDot(color: _D.red,      label: 'Retrasado'),
                const SizedBox(width: 12),
                _LegendDot(color: _D.mutedLight, label: 'Pendiente'),
              ],
            ),
          ),
          Container(height: 1, color: _D.stroke),
        ],
      ),
    );
  }
}

class _ConnectingLine extends StatelessWidget {
  const _ConnectingLine({required this.isCompleted});
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 2,
      child: CustomPaint(
        painter: _LinePainter(
          color: isCompleted ? _D.green : _D.stroke,
          dashed: !isCompleted,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2;
    if (!dashed) {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      const w = 4.0, gap = 3.0;
      var x = 0.0;
      final y = size.height / 2;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset((x + w).clamp(0, size.width), y), paint);
        x += w + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.color != color || o.dashed != dashed;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _D.muted)),
      ],
    );
  }
}

// ─── Penalty Alert Banner ────────────────────────────────────────────────────
class _PenaltyAlert extends StatelessWidget {
  const _PenaltyAlert({required this.items});
  final List<MilestoneRecord> items;

  @override
  Widget build(BuildContext context) {
    final totalPenalty = items.fold(0.0, (s, m) => s + m.penaltyAmount);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _D.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _D.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.gpp_bad_outlined,
              size: 18,
              color: _D.red,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${items.length} hito${items.length > 1 ? 's' : ''} con penalidad en riesgo',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _D.red,
                  ),
                ),
                if (totalPenalty > 0)
                  Text(
                    'Penalidad acumulada: \$${totalPenalty.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: _D.muted),
                  ),
              ],
            ),
          ),
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
    required this.totalCount,
    required this.hasPenal,
    required this.onChanged,
  });

  final _Filter current;
  final MilestoneDashboardSummary? summary;
  final int totalCount;
  final bool hasPenal;
  final void Function(_Filter) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final filters = <({_Filter filter, String label, int? count})>[
      (filter: _Filter.all,         label: 'Todos',       count: totalCount),
      (filter: _Filter.inProgress,  label: 'En proceso',  count: s?.inProgressCount),
      (filter: _Filter.delayed,     label: 'Retrasados',  count: s?.delayedCount),
      (filter: _Filter.completed,   label: 'Completados', count: s?.completedCount),
      if (hasPenal)
        (filter: _Filter.penalizable, label: 'Con penalidad', count: null),
    ];

    return Container(
      color: _D.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: filters.map((f) {
                final selected = current == f.filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(f.filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? _D.primary : _D.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _D.primary : _D.stroke,
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
                              color: selected ? _D.white : _D.muted,
                            ),
                          ),
                          if (f.count != null) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _D.white.withValues(alpha: 0.2)
                                    : _D.stroke,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${f.count}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? _D.white : _D.muted,
                                ),
                              ),
                            ),
                          ],
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

// ─── Milestone Card ───────────────────────────────────────────────────────────
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone, required this.onTap});
  final MilestoneRecord milestone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m          = milestone;
    final color      = _statusColor(m);
    final classColor = _classColor(m.classificationLabel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _D.stroke),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status color bar
                Container(width: 4, color: color),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: badges + delay chip
                        Row(
                          children: [
                            if (m.classificationLabel.isNotEmpty)
                              _Badge(
                                label: m.classificationLabel,
                                color: classColor,
                              ),
                            if (m.typeLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _Badge(
                                label: m.typeLabel,
                                color: _D.muted,
                                outlined: true,
                              ),
                            ],
                            const Spacer(),
                            if (m.isDelayed && m.delayDays > 0)
                              _DelayChip(days: m.delayDays),
                          ],
                        ),
                        const SizedBox(height: 7),
                        // Description
                        Text(
                          m.description,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _D.text,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Bottom row: date + status + penalty
                        Row(
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              size: 13,
                              color: _D.mutedLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _fmtDate(m.effectiveContractualDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: _D.muted,
                              ),
                            ),
                            const Spacer(),
                            if (m.isPenalizable)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.gpp_bad_outlined,
                                  size: 14,
                                  color: _D.red,
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                m.contractualStatusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Chevron
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: _D.mutedLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.outlined = false});
  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: outlined
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Delay Chip ───────────────────────────────────────────────────────────────
class _DelayChip extends StatelessWidget {
  const _DelayChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _D.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_upward_rounded, size: 10, color: _D.red),
          const SizedBox(width: 2),
          Text(
            '$days d',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _D.red,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      _Filter.all         => 'No hay hitos registrados',
      _Filter.inProgress  => 'No hay hitos en proceso',
      _Filter.delayed     => 'Sin hitos retrasados',
      _Filter.completed   => 'Sin hitos completados',
      _Filter.penalizable => 'Sin hitos con penalidad en riesgo',
    };
    final icon = switch (filter) {
      _Filter.delayed     => Icons.check_circle_outline_rounded,
      _Filter.completed   => Icons.emoji_events_outlined,
      _Filter.penalizable => Icons.shield_outlined,
      _              => Icons.checklist_rounded,
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _D.accentLight.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: _D.primary),
          ),
          const SizedBox(height: 14),
          Text(
            label,
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
}
