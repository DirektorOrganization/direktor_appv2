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
  if (m.isDelayed)   return _D.red;
  if (m.isInProgress) return _D.accent;
  return _D.mutedLight;
}

IconData _statusIcon(MilestoneRecord m) {
  if (m.isCompleted)  return Icons.check_circle_rounded;
  if (m.isDelayed)    return Icons.warning_amber_rounded;
  if (m.isInProgress) return Icons.timelapse_rounded;
  return Icons.pending_outlined;
}

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

String _fmtShort(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

Color _complianceColor(double pct) {
  if (pct >= 80) return _D.green;
  if (pct >= 50) return _D.yellow;
  return _D.red;
}

Color _classColor(String? label) {
  switch (label?.toLowerCase()) {
    case 'contractual': return _D.primary;
    case 'crítico':
    case 'critico':     return _D.red;
    case 'calidad':     return const Color(0xFF7C3AED);
    default:            return _D.muted;
  }
}

// ─── View modes ───────────────────────────────────────────────────────────────
enum _ViewMode { camino, linea, matriz }
enum _Filter    { all, inProgress, delayed, completed, penalizable }

// ─── Screen ───────────────────────────────────────────────────────────────────
class Hv2HubScreen extends StatefulWidget {
  const Hv2HubScreen({super.key});
  @override
  State<Hv2HubScreen> createState() => _Hv2HubScreenState();
}

class _Hv2HubScreenState extends State<Hv2HubScreen> {
  _ViewMode _viewMode = _ViewMode.camino;
  _Filter   _filter   = _Filter.all;

  List<MilestoneRecord> _applyFilter(List<MilestoneRecord> all) => switch (_filter) {
    _Filter.all         => all,
    _Filter.inProgress  => all.where((m) => m.isInProgress).toList(),
    _Filter.delayed     => all.where((m) => m.isDelayed).toList(),
    _Filter.completed   => all.where((m) => m.isCompleted).toList(),
    _Filter.penalizable => all.where((m) => m.isPenalizable && m.isDelayed).toList(),
  };

  void _openDetail(BuildContext ctx, int id) =>
      Navigator.of(ctx).pushNamed(RouteNames.controlHitosV2Detail, arguments: MilestoneDetailArgs(milestoneId: id));

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final milestones  = ctrl.milestones;
        final summary     = ctrl.milestoneSummary;
        final project     = ctrl.currentProject;
        final filtered    = _applyFilter(milestones);
        final sorted      = [...milestones]..sort((a, b) => a.effectiveContractualDate.compareTo(b.effectiveContractualDate));
        final penalDelayed = milestones.where((m) => m.isPenalizable && m.isDelayed).toList();

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: Column(
            children: [
              // Stats — always visible
              _StatsPanel(summary: summary, totalCount: milestones.length),

              // View mode selector
              _ViewModeBar(current: _viewMode, onChanged: (v) => setState(() => _viewMode = v)),

              // Content
              Expanded(child: switch (_viewMode) {
                _ViewMode.camino => _CaminoView(
                    sorted: sorted,
                    filtered: filtered,
                    filter: _filter,
                    summary: summary,
                    totalCount: milestones.length,
                    penalDelayed: penalDelayed,
                    onTap: (m) => _openDetail(ctx, m.id),
                    onFilterChanged: (f) => setState(() => _filter = f),
                  ),
                _ViewMode.linea => _LineaView(
                    milestones: sorted,
                    onTap: (m) => _openDetail(ctx, m.id),
                  ),
                _ViewMode.matriz => _MatrizView(
                    milestones: sorted,
                    onTap: (m) => _openDetail(ctx, m.id),
                  ),
              }),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.controlHitosCreate),
            backgroundColor: _D.primary,
            foregroundColor: _D.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuevo Hito', style: TextStyle(fontWeight: FontWeight.w600)),
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
          const Text('Control de Hitos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _D.text)),
          if (project != null && project.name.isNotEmpty)
            Text(project.name, style: const TextStyle(fontSize: 11, color: _D.muted)),
        ],
      ),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _D.stroke)),
    );
  }
}

// ─── View Mode Bar ────────────────────────────────────────────────────────────
class _ViewModeBar extends StatelessWidget {
  const _ViewModeBar({required this.current, required this.onChanged});
  final _ViewMode current;
  final void Function(_ViewMode) onChanged;

  static const _modes = [
    (_ViewMode.camino, Icons.view_stream_rounded,  'Tablero'),
    (_ViewMode.linea,  Icons.commit_rounded,       'Línea'),
    (_ViewMode.matriz, Icons.table_rows_rounded,   'Matriz'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: _modes.map((m) {
          final (mode, icon, label) = m;
          final sel = current == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? _D.primary : _D.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? _D.primary : _D.stroke),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 14, color: sel ? _D.white : _D.muted),
                    const SizedBox(width: 5),
                    Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? _D.white : _D.muted)),
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

// ═══════════════════════════════════════════════════════════════════════════════
// PROPUESTA EXISTENTE: TABLERO (Camino de hitos + cards)
// ═══════════════════════════════════════════════════════════════════════════════
class _CaminoView extends StatelessWidget {
  const _CaminoView({
    required this.sorted,
    required this.filtered,
    required this.filter,
    required this.summary,
    required this.totalCount,
    required this.penalDelayed,
    required this.onTap,
    required this.onFilterChanged,
  });

  final List<MilestoneRecord> sorted;
  final List<MilestoneRecord> filtered;
  final _Filter filter;
  final MilestoneDashboardSummary? summary;
  final int totalCount;
  final List<MilestoneRecord> penalDelayed;
  final void Function(MilestoneRecord) onTap;
  final void Function(_Filter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (sorted.isNotEmpty)
          _JourneyTimeline(milestones: sorted, onTap: onTap),
        if (penalDelayed.isNotEmpty)
          _PenaltyAlert(items: penalDelayed),
        _FilterBar(
          current: filter,
          summary: summary,
          totalCount: totalCount,
          hasPenal: penalDelayed.isNotEmpty,
          onChanged: onFilterChanged,
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(filter: filter)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _MilestoneCard(
                    milestone: filtered[i],
                    onTap: () => onTap(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROPUESTA A: LÍNEA DE TIEMPO VERTICAL
// ═══════════════════════════════════════════════════════════════════════════════
class _LineaView extends StatelessWidget {
  const _LineaView({required this.milestones, required this.onTap});
  final List<MilestoneRecord> milestones;
  final void Function(MilestoneRecord) onTap;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.linear_scale_rounded, size: 40, color: _D.mutedLight),
            SizedBox(height: 12),
            Text('No hay hitos registrados', style: TextStyle(color: _D.muted, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: milestones.length,
      itemBuilder: (_, i) {
        final m       = milestones[i];
        final isFirst = i == 0;
        final isLast  = i == milestones.length - 1;
        final color   = _statusColor(m);
        final filled  = m.isCompleted || m.isDelayed;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Timeline column ───────────────────────────────────────────
              SizedBox(
                width: 44,
                child: Column(
                  children: [
                    // Top connector
                    if (!isFirst)
                      Container(
                        width: 2,
                        height: 16,
                        color: milestones[i - 1].isCompleted ? _D.green : _D.stroke,
                      )
                    else
                      const SizedBox(height: 16),
                    // Node
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? color : color.withValues(alpha: 0.10),
                        border: Border.all(color: color, width: m.isInProgress ? 2.5 : 2),
                      ),
                      child: Icon(_statusIcon(m), size: 16, color: filled ? _D.white : color),
                    ),
                    // Bottom connector extending to end of card
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: m.isCompleted ? _D.green : _D.stroke,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // ── Card ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10, top: 0),
                  child: _TimelineCard(milestone: m, onTap: () => onTap(m)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.milestone, required this.onTap});
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
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: m.isDelayed ? _D.red.withValues(alpha: 0.3) : _D.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                if (m.classificationLabel.isNotEmpty)
                  _Badge(label: m.classificationLabel, color: classColor),
                if (m.typeLabel.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  _Badge(label: m.typeLabel, color: _D.muted, outlined: true),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                  child: Text(m.contractualStatusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 7),
            // Description
            Text(m.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _D.text, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // 3 dates row
            Row(
              children: [
                _TLDateCell(label: 'Contractual', date: m.effectiveContractualDate, color: _D.primary),
                const SizedBox(width: 6),
                _TLDateCell(label: 'Meta', date: m.effectiveTargetDate, color: _D.accent),
                const SizedBox(width: 6),
                _TLDateCell(label: 'Real', date: m.actualDate, color: m.actualDate != null ? _D.green : _D.mutedLight, empty: m.actualDate == null),
              ],
            ),
            if (m.isDelayed && m.delayDays > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, size: 11, color: _D.red),
                  const SizedBox(width: 3),
                  Text('${m.delayDays} días de retraso', style: const TextStyle(fontSize: 11, color: _D.red, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TLDateCell extends StatelessWidget {
  const _TLDateCell({required this.label, required this.date, required this.color, this.empty = false});
  final String label;
  final DateTime? date;
  final Color color;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          color: empty ? Colors.transparent : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: empty ? _D.stroke : color.withValues(alpha: 0.25),
            style: empty ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: empty ? _D.mutedLight : color, letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(
              empty ? '—' : _fmtShort(date),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: empty ? _D.mutedLight : color),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROPUESTA B: MATRIZ DE FECHAS
// ═══════════════════════════════════════════════════════════════════════════════
class _MatrizView extends StatelessWidget {
  const _MatrizView({required this.milestones, required this.onTap});
  final List<MilestoneRecord> milestones;
  final void Function(MilestoneRecord) onTap;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_rows_rounded, size: 40, color: _D.mutedLight),
            SizedBox(height: 12),
            Text('No hay hitos registrados', style: TextStyle(color: _D.muted, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sticky header
        Container(
          color: _D.surface,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: const Row(
            children: [
              SizedBox(width: 28),  // # col
              SizedBox(width: 8),
              Expanded(flex: 3, child: _MatrixHeaderCell(label: 'Descripción')),
              SizedBox(width: 4),
              Expanded(flex: 2, child: _MatrixHeaderCell(label: 'Contractual', icon: Icons.gavel_rounded, color: _D.primary)),
              SizedBox(width: 4),
              Expanded(flex: 2, child: _MatrixHeaderCell(label: 'Meta', icon: Icons.flag_rounded, color: _D.accent)),
              SizedBox(width: 4),
              Expanded(flex: 2, child: _MatrixHeaderCell(label: 'Real', icon: Icons.check_circle_rounded, color: _D.green)),
            ],
          ),
        ),
        Container(height: 1, color: _D.stroke),
        // Rows
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            itemCount: milestones.length,
            separatorBuilder: (context, i) => Container(height: 1, color: _D.stroke),
            itemBuilder: (_, i) => _MatrixRow(
              milestone: milestones[i],
              index: i,
              onTap: () => onTap(milestones[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixHeaderCell extends StatelessWidget {
  const _MatrixHeaderCell({required this.label, this.icon, this.color = _D.muted});
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 3)],
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MatrixRow extends StatelessWidget {
  const _MatrixRow({required this.milestone, required this.index, required this.onTap});
  final MilestoneRecord milestone;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m     = milestone;
    final color = _statusColor(m);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: index.isEven ? _D.surface : _D.bg,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${m.order}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Description
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _D.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (m.classificationLabel.isNotEmpty)
                    Text(m.classificationLabel, style: TextStyle(fontSize: 9, color: _classColor(m.classificationLabel), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Contractual
            Expanded(flex: 2, child: _MatrixDatePill(date: m.effectiveContractualDate, color: _D.primary)),
            const SizedBox(width: 4),
            // Meta
            Expanded(flex: 2, child: _MatrixDatePill(date: m.effectiveTargetDate, color: _D.accent)),
            const SizedBox(width: 4),
            // Real
            Expanded(flex: 2, child: m.actualDate != null
                ? _MatrixDatePill(date: m.actualDate, color: _D.green)
                : _MatrixEmptyReal(isDelayed: m.isDelayed)),
          ],
        ),
      ),
    );
  }
}

class _MatrixDatePill extends StatelessWidget {
  const _MatrixDatePill({required this.date, required this.color});
  final DateTime? date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            date == null ? '—' : date!.day.toString().padLeft(2, '0'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color, height: 1),
          ),
          Text(
            date == null ? '' : '/${date!.month.toString().padLeft(2, '0')}/${date!.year.toString().substring(2)}',
            style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MatrixEmptyReal extends StatelessWidget {
  const _MatrixEmptyReal({required this.isDelayed});
  final bool isDelayed;

  @override
  Widget build(BuildContext context) {
    final color = isDelayed ? _D.red : _D.mutedLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.35), style: BorderStyle.solid),
      ),
      child: Center(
        child: Icon(
          isDelayed ? Icons.warning_amber_rounded : Icons.hourglass_empty_rounded,
          size: 14,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMPARTIDOS — CAMINO VIEW
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Stats Panel ─────────────────────────────────────────────────────────────
class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.summary, required this.totalCount});
  final MilestoneDashboardSummary? summary;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final s         = summary;
    final completed = s?.completedCount ?? 0;
    final overdue   = s?.delayedCount ?? 0;
    final pct       = s?.compliance ?? 0.0;

    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          SizedBox(
            width: 72, height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size(72, 72), painter: _CompliancePainter(percent: pct / 100)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _complianceColor(pct))),
                    const Text('cumpl.', style: TextStyle(fontSize: 9, color: _D.muted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _StatPill(icon: Icons.format_list_numbered_rounded, label: 'Total',       value: '$totalCount', color: _D.primary),
                _StatPill(icon: Icons.check_circle_outline_rounded, label: 'Completados', value: '$completed',  color: _D.green),
                _StatPill(icon: Icons.warning_amber_rounded,        label: 'Retrasados',  value: '$overdue',    color: overdue > 0 ? _D.red : _D.mutedLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
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
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: _D.muted)),
        ],
      ),
    );
  }
}

class _CompliancePainter extends CustomPainter {
  const _CompliancePainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    final paint  = Paint()..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round;
    paint.color = _D.stroke;
    canvas.drawCircle(center, radius, paint);
    paint.color = _complianceColor(percent * 100);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * percent.clamp(0.0, 1.0), false, paint);
  }

  @override
  bool shouldRepaint(_CompliancePainter old) => old.percent != percent;
}

// ─── Journey Timeline (mini horizontal) ──────────────────────────────────────
class _JourneyTimeline extends StatelessWidget {
  const _JourneyTimeline({required this.milestones, required this.onTap});
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
                const Icon(Icons.route_rounded, size: 13, color: _D.muted),
                const SizedBox(width: 5),
                const Text('CAMINO DE HITOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.muted, letterSpacing: 0.8)),
                const Spacer(),
                Text('${milestones.length} hitos', style: const TextStyle(fontSize: 10, color: _D.mutedLight)),
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
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: filled ? color : color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: m.isInProgress ? 2.5 : 2),
                            ),
                            child: Icon(_statusIcon(m), size: 17, color: filled ? _D.white : color),
                          ),
                          const SizedBox(height: 5),
                          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                        ],
                      ),
                    ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _LegendDot(color: _D.green,      label: 'Completado'),
                const SizedBox(width: 12),
                _LegendDot(color: _D.accent,     label: 'En proceso'),
                const SizedBox(width: 12),
                _LegendDot(color: _D.red,        label: 'Retrasado'),
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
      width: 28, height: 2,
      child: CustomPaint(painter: _LinePainter(color: isCompleted ? _D.green : _D.stroke, dashed: !isCompleted)),
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
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
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
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _D.muted)),
      ],
    );
  }
}

// ─── Penalty Alert ────────────────────────────────────────────────────────────
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
            decoration: BoxDecoration(color: _D.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.gpp_bad_outlined, size: 18, color: _D.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${items.length} hito${items.length > 1 ? 's' : ''} con penalidad en riesgo',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _D.red)),
                if (totalPenalty > 0)
                  Text('Penalidad acumulada: \$${totalPenalty.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: _D.muted)),
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
  const _FilterBar({required this.current, required this.summary, required this.totalCount, required this.hasPenal, required this.onChanged});
  final _Filter current;
  final MilestoneDashboardSummary? summary;
  final int totalCount;
  final bool hasPenal;
  final void Function(_Filter) onChanged;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final filters = <({_Filter filter, String label, int? count})>[
      (filter: _Filter.all,         label: 'Todos',        count: totalCount),
      (filter: _Filter.inProgress,  label: 'En proceso',   count: s?.inProgressCount),
      (filter: _Filter.delayed,     label: 'Retrasados',   count: s?.delayedCount),
      (filter: _Filter.completed,   label: 'Completados',  count: s?.completedCount),
      if (hasPenal) (filter: _Filter.penalizable, label: 'Con penalidad', count: null),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? _D.primary : _D.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? _D.primary : _D.stroke),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(f.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? _D.white : _D.muted)),
                          if (f.count != null) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: selected ? _D.white.withValues(alpha: 0.2) : _D.stroke,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${f.count}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? _D.white : _D.muted)),
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

// ─── Milestone Card (Tablero) ─────────────────────────────────────────────────
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
        decoration: BoxDecoration(color: _D.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _D.stroke)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (m.classificationLabel.isNotEmpty) _Badge(label: m.classificationLabel, color: classColor),
                            if (m.typeLabel.isNotEmpty) ...[const SizedBox(width: 6), _Badge(label: m.typeLabel, color: _D.muted, outlined: true)],
                            const Spacer(),
                            if (m.isDelayed && m.delayDays > 0) _DelayChip(days: m.delayDays),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(m.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _D.text, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 13, color: _D.mutedLight),
                            const SizedBox(width: 4),
                            Text(_fmtDate(m.effectiveContractualDate), style: const TextStyle(fontSize: 11, color: _D.muted)),
                            const Spacer(),
                            if (m.isPenalizable) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.gpp_bad_outlined, size: 14, color: _D.red)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(m.contractualStatusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.chevron_right_rounded, size: 20, color: _D.mutedLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────
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
        border: outlined ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DelayChip extends StatelessWidget {
  const _DelayChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: _D.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_upward_rounded, size: 10, color: _D.red),
          const SizedBox(width: 2),
          Text('$days d', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.red)),
        ],
      ),
    );
  }
}

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
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _D.accentLight.withValues(alpha: 0.4), shape: BoxShape.circle), child: Icon(icon, size: 36, color: _D.primary)),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _D.muted)),
        ],
      ),
    );
  }
}
