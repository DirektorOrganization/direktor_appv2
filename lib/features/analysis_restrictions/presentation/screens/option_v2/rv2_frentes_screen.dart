// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
  static const white = Colors.white;
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
}

class Rv2FrentesScreen extends StatefulWidget {
  const Rv2FrentesScreen({super.key});

  @override
  State<Rv2FrentesScreen> createState() => _Rv2FrentesScreenState();
}

class _Rv2FrentesScreenState extends State<Rv2FrentesScreen> {
  final Set<String> _expandedFronts = <String>{};

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final restrictions = controller.restrictions;
        final summary = controller.restrictionSummary;
        final project = controller.currentProject;
        final grouped = _groupByFront(restrictions);
        final frontNames = grouped.keys.toList()
          ..sort((a, b) {
            final aHasOverdue = grouped[a]!.any((r) => r.isOverdue);
            final bHasOverdue = grouped[b]!.any((r) => r.isOverdue);
            if (aHasOverdue != bHasOverdue) {
              return aHasOverdue ? -1 : 1;
            }
            return a.toLowerCase().compareTo(b.toLowerCase());
          });

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frentes de Obra',
                  style: TextStyle(
                    color: _D.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  project?.name ?? 'Sin proyecto',
                  style: const TextStyle(
                    color: _D.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: _D.stroke,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  RouteNames.restrictionCreate,
                ),
                icon: const Icon(Icons.add_rounded, color: _D.primary),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: _SummaryHeader(summary: summary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (restrictions.isEmpty) {
                      return const _EmptyState();
                    }
                    final frontName = frontNames[index];
                    final items = grouped[frontName]!;
                    final isExpanded = _expandedFronts.contains(frontName);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FrontCard(
                        frontName: frontName,
                        items: items,
                        isExpanded: isExpanded,
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedFronts.remove(frontName);
                            } else {
                              _expandedFronts.add(frontName);
                            }
                          });
                        },
                      ),
                    );
                  }, childCount: restrictions.isEmpty ? 1 : frontNames.length),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 80),
                sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _D.primary,
            foregroundColor: _D.white,
            onPressed: () => Navigator.pushNamed(
              context,
              RouteNames.restrictionCreate,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva Restriccion'),
          ),
        );
      },
    );
  }
}

Map<String, List<RestrictionRecord>> _groupByFront(List<RestrictionRecord> restrictions) {
  final grouped = <String, List<RestrictionRecord>>{};
  for (final item in restrictions) {
    final front = item.front.trim().isEmpty ? 'Sin frente' : item.front.trim();
    grouped.putIfAbsent(front, () => <RestrictionRecord>[]).add(item);
  }
  return grouped;
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final RestrictionSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = summary.compliancePercent.clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  icon: Icons.list_alt_rounded,
                  color: _D.primary,
                  count: summary.total,
                  label: 'Total',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  icon: Icons.error_outline_rounded,
                  color: _D.red,
                  count: summary.overdue,
                  label: 'Vencidas',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  icon: Icons.timelapse_rounded,
                  color: _D.yellow,
                  count: summary.inProgress,
                  label: 'En-proceso',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(
                  icon: Icons.check_circle_outline_rounded,
                  color: _D.green,
                  count: summary.completed,
                  label: 'Finalizadas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: _D.accentLight.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(_D.green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percent * 100).round()}% cumplimiento',
                style: const TextStyle(
                  color: _D.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _D.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontCard extends StatelessWidget {
  const _FrontCard({
    required this.frontName,
    required this.items,
    required this.isExpanded,
    required this.onTap,
  });

  final String frontName;
  final List<RestrictionRecord> items;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdueCount = items.where((r) => r.isOverdue).length;
    final inProgressCount = items.where((r) => r.isInProgress).length;
    final completedCount = items.where((r) => r.isCompleted).length;
    final allCompleted = items.isNotEmpty && completedCount == items.length;
    final hasOverdue = overdueCount > 0;
    final accent = hasOverdue
        ? _D.red
        : allCompleted
        ? _D.green
        : _D.primary;

    return Material(
      color: _D.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _D.stroke),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: accent.withValues(alpha: 0.14),
                      child: Icon(
                        Icons.engineering_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            frontName,
                            style: const TextStyle(
                              color: _D.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${items.length} restricciones',
                            style: const TextStyle(
                              color: _D.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isExpanded) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (overdueCount > 0)
                                  _MiniBadge(
                                    color: _D.red,
                                    label: 'Vencidas',
                                    count: overdueCount,
                                  ),
                                if (inProgressCount > 0)
                                  _MiniBadge(
                                    color: _D.yellow,
                                    label: 'Proceso',
                                    count: inProgressCount,
                                  ),
                                if (completedCount > 0)
                                  _MiniBadge(
                                    color: _D.green,
                                    label: 'OK',
                                    count: completedCount,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CustomPaint(
                        painter: _FrontDonutPainter(
                          percent: items.isEmpty ? 0 : completedCount / items.length,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const Divider(height: 1, thickness: 1, color: _D.stroke),
                    ...List.generate(items.length, (index) {
                      return Column(
                        children: [
                          _RestrictionRow(item: items[index]),
                          if (index != items.length - 1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: _D.stroke,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictionRow extends StatelessWidget {
  const _RestrictionRow({required this.item});

  final RestrictionRecord item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item);
    final date = item.conciliatedDate ?? item.requiredDate;

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        RouteNames.restrictionDetail,
        arguments: RestrictionDetailArgs(restrictionId: item.id),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.activity,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _D.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _D.accentLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item.phase,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _D.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _fmtShort(date),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrontDonutPainter extends CustomPainter {
  _FrontDonutPainter({required this.percent});

  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final p = percent.clamp(0.0, 1.0).toDouble();
    final strokeWidth = 5.0;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = _D.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    Color progressColor;
    if (p >= 0.8) {
      progressColor = _D.green;
    } else if (p >= 0.5) {
      progressColor = _D.yellow;
    } else {
      progressColor = _D.red;
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * p, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _FrontDonutPainter oldDelegate) {
    return oldDelegate.percent != percent;
  }
}

Color _statusColor(RestrictionRecord r) {
  if (r.isOverdue) return _D.red;
  if (r.isDueToday) return _D.orange;
  if (r.isInProgress) return _D.yellow;
  if (r.isCompleted) return _D.green;
  return _D.mutedLight;
}

String _fmtShort(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded, color: _D.green, size: 56),
            SizedBox(height: 10),
            Text(
              'Todos los frentes al dia',
              style: TextStyle(
                color: _D.green,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
