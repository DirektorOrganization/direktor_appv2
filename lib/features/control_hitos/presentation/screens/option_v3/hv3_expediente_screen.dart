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
  if (m.isDelayed)   return _D.red;
  return _D.accent;
}

IconData _statusIcon(MilestoneRecord m) {
  if (m.isCompleted) return Icons.check_circle_rounded;
  if (m.isDelayed)   return Icons.warning_amber_rounded;
  return Icons.timelapse_rounded;
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ─── Screen ───────────────────────────────────────────────────────────────────
/// "EXPEDIENTE" redesign — each milestone displayed as a physical document card
/// (folder/ficha style). Groups by classification. Left side: classification
/// color tab. Inside: structured like an official document brief with code,
/// description, dates in a table-like layout, penalty badge, extension count,
/// and completion stamp. Concept: digital construction file cabinet.
class Hv3ExpedienteScreen extends StatefulWidget {
  const Hv3ExpedienteScreen({super.key});

  @override
  State<Hv3ExpedienteScreen> createState() => _Hv3ExpedienteScreenState();
}

enum _ExpFilter { all, inProgress, delayed, completed, penalizable }

class _Hv3ExpedienteScreenState extends State<Hv3ExpedienteScreen> {
  _ExpFilter _filter = _ExpFilter.all;

  List<MilestoneRecord> _applyFilter(List<MilestoneRecord> all) {
    return switch (_filter) {
      _ExpFilter.all         => all,
      _ExpFilter.inProgress  => all.where((m) => m.isInProgress).toList(),
      _ExpFilter.delayed     => all.where((m) => m.isDelayed).toList(),
      _ExpFilter.completed   => all.where((m) => m.isCompleted).toList(),
      _ExpFilter.penalizable => all.where((m) => m.isPenalizable && m.isDelayed).toList(),
    };
  }

  // Groups filtered list by classificationLabel
  Map<String, List<MilestoneRecord>> _groupByClass(
    List<MilestoneRecord> items,
  ) {
    final map = <String, List<MilestoneRecord>>{};
    for (final m in items) {
      final key = m.classificationLabel.isNotEmpty
          ? m.classificationLabel
          : 'Sin clasificacion';
      map.putIfAbsent(key, () => []).add(m);
    }
    return map;
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

        // Sort by date within each group
        filtered.sort((a, b) =>
            a.effectiveContractualDate.compareTo(b.effectiveContractualDate));

        final grouped = _groupByClass(filtered);
        final groups  = grouped.keys.toList()..sort();

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: Column(
            children: [
              // ── Compliance header ─────────────────────────────────────────
              _ComplianceHeader(summary: summary, total: milestones.length),
              // ── Filter strip ──────────────────────────────────────────────
              _FilterStrip(
                current: _filter,
                summary: summary,
                total: milestones.length,
                onChanged: (f) => setState(() => _filter = f),
              ),
              // ── Expediente list ───────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: groups.length,
                        itemBuilder: (_, gi) {
                          final groupName = groups[gi];
                          final items     = grouped[groupName]!;
                          return _ClassificationGroup(
                            name: groupName,
                            items: items,
                            onTap: (m) => Navigator.of(ctx).pushNamed(
                              RouteNames.controlHitosV2Detail,
                              arguments: MilestoneDetailArgs(
                                milestoneId: m.id,
                              ),
                            ),
                          );
                        },
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
            'Expediente de Hitos',
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
          icon: const Icon(Icons.table_chart_outlined, color: _D.muted),
          tooltip: 'Vista Gantt',
          onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.controlHitosV3Gantt),
        ),
        IconButton(
          icon: const Icon(Icons.format_list_bulleted_rounded, color: _D.muted),
          tooltip: 'Vista lista',
          onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.controlHitosV2),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

// ─── Compliance Header ────────────────────────────────────────────────────────
class _ComplianceHeader extends StatelessWidget {
  const _ComplianceHeader({required this.summary, required this.total});
  final MilestoneDashboardSummary summary;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = summary.compliance;
    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _RingPainter(percent: pct / 100),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: pct >= 80
                            ? _D.green
                            : pct >= 50
                                ? _D.yellow
                                : _D.red,
                      ),
                    ),
                    const Text(
                      'cumpl.',
                      style: TextStyle(fontSize: 8, color: _D.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Badge(
                      label: '$total hitos',
                      color: _D.primary,
                      icon: Icons.folder_copy_outlined,
                    ),
                    const SizedBox(width: 8),
                    if (summary.delayedCount > 0)
                      _Badge(
                        label: '${summary.delayedCount} retrasados',
                        color: _D.red,
                        icon: Icons.warning_amber_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Badge(
                      label: '${summary.completedCount} completados',
                      color: _D.green,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    if (summary.accumulatedPenalty > 0) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: '\$${summary.accumulatedPenalty.toStringAsFixed(0)}',
                        color: _D.red,
                        icon: Icons.gpp_bad_outlined,
                      ),
                    ],
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 6
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
  bool shouldRepaint(_RingPainter o) => o.percent != percent;
}

// ─── Filter Strip ─────────────────────────────────────────────────────────────
class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.current,
    required this.summary,
    required this.total,
    required this.onChanged,
  });
  final _ExpFilter current;
  final MilestoneDashboardSummary summary;
  final int total;
  final void Function(_ExpFilter) onChanged;

  @override
  Widget build(BuildContext context) {
    final hasPenal = summary.delayedCount > 0;
    final filters = <({_ExpFilter f, String label, int? count})>[
      (f: _ExpFilter.all,         label: 'Todos',        count: total),
      (f: _ExpFilter.inProgress,  label: 'En proceso',   count: summary.inProgressCount),
      (f: _ExpFilter.delayed,     label: 'Retrasados',   count: summary.delayedCount),
      (f: _ExpFilter.completed,   label: 'Completados',  count: summary.completedCount),
      if (hasPenal)
        (f: _ExpFilter.penalizable, label: 'Penalidad', count: null),
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
                        horizontal: 13,
                        vertical: 7,
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
                          if (f.count != null) ...[
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

// ─── Classification Group ─────────────────────────────────────────────────────
class _ClassificationGroup extends StatelessWidget {
  const _ClassificationGroup({
    required this.name,
    required this.items,
    required this.onTap,
  });
  final String name;
  final List<MilestoneRecord> items;
  final void Function(MilestoneRecord) onTap;

  Color get _groupColor {
    final n = name.toLowerCase();
    if (n.contains('contractual'))  return _D.primary;
    if (n.contains('critico') || n.contains('crítico')) return _D.red;
    if (n.contains('calidad'))      return const Color(0xFF7C3AED);
    return _D.muted;
  }

  @override
  Widget build(BuildContext context) {
    final color = _groupColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Expediente cards
        ...items.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpedienteCard(
                milestone: m,
                classColor: color,
                onTap: () => onTap(m),
              ),
            )),
      ],
    );
  }
}

// ─── Expediente Card ──────────────────────────────────────────────────────────
class _ExpedienteCard extends StatelessWidget {
  const _ExpedienteCard({
    required this.milestone,
    required this.classColor,
    required this.onTap,
  });
  final MilestoneRecord milestone;
  final Color classColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m     = milestone;
    final color = _statusColor(m);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _D.stroke),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Classification color tab (left)
                Container(width: 5, color: classColor),
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: code + type + status icon
                        Row(
                          children: [
                            if (m.code.isNotEmpty)
                              _DocChip(label: m.code, color: _D.primary),
                            if (m.typeLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _DocChip(label: m.typeLabel, color: _D.muted),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _statusIcon(m),
                                size: 14,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Description
                        Text(
                          m.description,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _D.text,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Document-style date table
                        _DateTable(milestone: m),
                        const SizedBox(height: 10),
                        // Footer: penalty + extensions + delay + sync
                        _CardFooter(milestone: m, statusColor: color),
                      ],
                    ),
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

// ─── Date Table ───────────────────────────────────────────────────────────────
class _DateTable extends StatelessWidget {
  const _DateTable({required this.milestone});
  final MilestoneRecord milestone;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    final hasExt = m.extensionCount > 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        children: [
          _DateRow(
            icon: Icons.gavel_rounded,
            label: 'Contractual',
            date: m.effectiveContractualDate,
            extended: hasExt && m.extendedContractualDate != null,
            original: m.contractualDate,
            color: _D.primary,
          ),
          const SizedBox(height: 6),
          _DateRow(
            icon: Icons.flag_rounded,
            label: 'Meta',
            date: m.effectiveTargetDate,
            extended: hasExt && m.extendedTargetDate != null,
            original: m.targetDate,
            color: _D.accent,
          ),
          if (m.actualDate != null) ...[
            const SizedBox(height: 6),
            _DateRow(
              icon: Icons.check_circle_rounded,
              label: 'Realizado',
              date: m.actualDate!,
              extended: false,
              original: m.actualDate!,
              color: _D.green,
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.date,
    required this.extended,
    required this.original,
    required this.color,
  });
  final IconData icon;
  final String label;
  final DateTime date;
  final bool extended;
  final DateTime original;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _D.muted),
          ),
        ),
        if (extended) ...[
          Text(
            _fmtDate(original),
            style: const TextStyle(
              fontSize: 11,
              color: _D.mutedLight,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          _fmtDate(date),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Card Footer ─────────────────────────────────────────────────────────────
class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.milestone, required this.statusColor});
  final MilestoneRecord milestone;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    return Row(
      children: [
        // Status label pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            m.contractualStatusLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        if (m.isDelayed && m.delayDays > 0) ...[
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 11,
                color: _D.red,
              ),
              Text(
                '${m.delayDays}d',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _D.red,
                ),
              ),
            ],
          ),
        ],
        if (m.extensionCount > 0) ...[
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.update_rounded,
                size: 11,
                color: _D.yellow,
              ),
              const SizedBox(width: 2),
              Text(
                '${m.extensionCount} amp.',
                style: const TextStyle(
                  fontSize: 10,
                  color: _D.yellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
        if (m.isPenalizable) ...[
          const SizedBox(width: 6),
          const Icon(Icons.gpp_bad_outlined, size: 13, color: _D.red),
        ],
        const Spacer(),
        // Sync dot
        Icon(
          m.isSynced
              ? Icons.cloud_done_outlined
              : Icons.cloud_upload_outlined,
          size: 13,
          color: m.isSynced ? _D.green : _D.mutedLight,
        ),
        // Docs count
        if (m.documents.isNotEmpty) ...[
          const SizedBox(width: 6),
          const Icon(Icons.attach_file_rounded, size: 12, color: _D.mutedLight),
          Text(
            '${m.documents.length}',
            style: const TextStyle(fontSize: 10, color: _D.mutedLight),
          ),
        ],
        const SizedBox(width: 6),
        // Completed stamp
        if (m.isCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: _D.green.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'COMPLETADO',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: _D.green,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Doc Chip ─────────────────────────────────────────────────────────────────
class _DocChip extends StatelessWidget {
  const _DocChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
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
              Icons.folder_copy_outlined,
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
