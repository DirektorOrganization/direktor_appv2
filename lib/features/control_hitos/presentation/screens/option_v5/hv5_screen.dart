// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7);
  static const accent      = Color(0xFF1167C8);
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
  if (m.isCompleted)  return _D.green;
  if (m.isDelayed)    return _D.red;
  if (m.isInProgress) return _D.accent;
  return _D.mutedLight;
}

IconData _statusIcon(MilestoneRecord m) {
  if (m.isCompleted)  return Icons.check_circle_rounded;
  if (m.isDelayed)    return Icons.warning_amber_rounded;
  if (m.isInProgress) return Icons.timelapse_rounded;
  return Icons.radio_button_unchecked_rounded;
}

String _fmtShort(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';
}

/// Devuelve el índice del hito vigente (en progreso o retrasado) o el más próximo
int _activeIndex(List<MilestoneRecord> sorted) {
  for (int i = 0; i < sorted.length; i++) {
    if (sorted[i].isInProgress || sorted[i].isDelayed) return i;
  }
  // Si todos completados, el último; si todos pendientes, el primero
  for (int i = 0; i < sorted.length; i++) {
    if (!sorted[i].isCompleted) return i;
  }
  return sorted.isEmpty ? 0 : sorted.length - 1;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Hv5Screen extends StatefulWidget {
  const Hv5Screen({super.key});
  @override
  State<Hv5Screen> createState() => _Hv5ScreenState();
}

class _Hv5ScreenState extends State<Hv5Screen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _showGantt = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext ctx, int id) =>
      Navigator.of(ctx).pushNamed(RouteNames.controlHitosV2Detail, arguments: MilestoneDetailArgs(milestoneId: id));

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final milestones = ctrl.milestones;
        final summary    = ctrl.milestoneSummary;
        final project    = ctrl.currentProject;
        final sorted     = [...milestones]..sort((a, b) => a.effectiveContractualDate.compareTo(b.effectiveContractualDate));

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(project),
          body: Stack(
            children: [
              Column(
                children: [
                  // ── Stats strip ──────────────────────────────────────────
                  _StatsStrip(summary: summary, total: milestones.length),
                  // ── Tabs ─────────────────────────────────────────────────
                  Container(
                    color: _D.white,
                    child: TabBar(
                      controller: _tabCtrl,
                      labelColor: _D.primary,
                      unselectedLabelColor: _D.muted,
                      indicatorColor: _D.primary,
                      indicatorWeight: 2.5,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(icon: Icon(Icons.table_rows_rounded, size: 16), text: 'Datos'),
                        Tab(icon: Icon(Icons.commit_rounded,      size: 16), text: 'Timeline'),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _D.stroke),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Tab 1 — Datos (lista compacta)
                        _DataTab(milestones: sorted, summary: summary, onTap: (m) => _openDetail(ctx, m.id)),
                        // Tab 2 — Timeline vertical
                        _TimelineTab(milestones: sorted, onTap: (m) => _openDetail(ctx, m.id)),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Gantt overlay ─────────────────────────────────────────────
              if (_showGantt)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _GanttPanel(
                    milestones: sorted,
                    onClose: () => setState(() => _showGantt = false),
                  ),
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'hv5_gantt',
                onPressed: () => setState(() => _showGantt = !_showGantt),
                backgroundColor: _showGantt ? _D.yellow : _D.white,
                foregroundColor: _showGantt ? _D.white : _D.primary,
                tooltip: 'Gantt',
                child: const Icon(Icons.bar_chart_rounded),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'hv5_new',
                onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.controlHitosCreate),
                backgroundColor: _D.primary,
                foregroundColor: _D.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(dynamic project) {
    return AppBar(
      backgroundColor: _D.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Control de Hitos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _D.text)),
          if (project != null)
            Text(project.name ?? '', style: const TextStyle(fontSize: 11, color: _D.muted)),
        ],
      ),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _D.stroke)),
    );
  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.summary, required this.total});
  final MilestoneDashboardSummary? summary;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s   = summary;
    final pct = s?.compliance ?? 0.0;
    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _Strip(label: 'Total',       value: '$total',                    color: _D.primary),
          _Divider(),
          _Strip(label: 'Completados', value: '${s?.completedCount ?? 0}', color: _D.green),
          _Divider(),
          _Strip(label: 'En proceso',  value: '${s?.inProgressCount ?? 0}', color: _D.accent),
          _Divider(),
          _Strip(label: 'Retrasados',  value: '${s?.delayedCount ?? 0}',   color: _D.red),
          _Divider(),
          _Strip(label: 'Cumpl.',      value: '${pct.toStringAsFixed(0)}%', color: pct >= 80 ? _D.green : pct >= 50 ? _D.yellow : _D.red),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: _D.muted, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: _D.stroke, margin: const EdgeInsets.symmetric(horizontal: 4));
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — DATOS (lista compacta tipo dashboard)
// ═══════════════════════════════════════════════════════════════════════════════
class _DataTab extends StatelessWidget {
  const _DataTab({required this.milestones, required this.summary, required this.onTap});
  final List<MilestoneRecord> milestones;
  final MilestoneDashboardSummary? summary;
  final void Function(MilestoneRecord) onTap;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Center(child: Text('No hay hitos registrados', style: TextStyle(color: _D.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: milestones.length,
      itemBuilder: (_, i) => _DataCard(milestone: milestones[i], onTap: () => onTap(milestones[i])),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.milestone, required this.onTap});
  final MilestoneRecord milestone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m     = milestone;
    final color = _statusColor(m);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Icon(_statusIcon(m), size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _D.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(m.code, style: const TextStyle(fontSize: 10, color: _D.mutedLight, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_rounded, size: 10, color: _D.mutedLight),
                      const SizedBox(width: 3),
                      Text(_fmtShort(m.effectiveContractualDate), style: const TextStyle(fontSize: 10, color: _D.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (m.isDelayed && m.delayDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: _D.red.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                child: Text('+${m.delayDays}d', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.red)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                child: Text(m.contractualStatusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _D.mutedLight),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — TIMELINE VERTICAL
// ═══════════════════════════════════════════════════════════════════════════════
class _TimelineTab extends StatefulWidget {
  const _TimelineTab({required this.milestones, required this.onTap});
  final List<MilestoneRecord> milestones;
  final void Function(MilestoneRecord) onTap;

  @override
  State<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<_TimelineTab> {
  final _scrollCtrl = ScrollController();
  static const double _itemHeight = 120.0; // approx height per item

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  void _scrollToActive() {
    if (!_scrollCtrl.hasClients) return;
    final idx    = _activeIndex(widget.milestones);
    // Scroll so active item is roughly in the upper third of the viewport
    final offset = math.max(0.0, (idx - 1) * _itemHeight);
    _scrollCtrl.animateTo(offset, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milestones = widget.milestones;
    if (milestones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.commit_rounded, size: 44, color: _D.mutedLight),
            SizedBox(height: 12),
            Text('Sin hitos registrados', style: TextStyle(color: _D.muted, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final activeIdx = _activeIndex(milestones);

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: milestones.length,
      itemBuilder: (_, i) {
        final m       = milestones[i];
        final isFirst = i == 0;
        final isLast  = i == milestones.length - 1;
        final isActive = i == activeIdx;

        return _TimelineNode(
          milestone: m,
          isFirst: isFirst,
          isLast: isLast,
          isActive: isActive,
          prevCompleted: i > 0 && milestones[i - 1].isCompleted,
          onTap: () => widget.onTap(m),
        );
      },
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.milestone,
    required this.isFirst,
    required this.isLast,
    required this.isActive,
    required this.prevCompleted,
    required this.onTap,
  });

  final MilestoneRecord milestone;
  final bool isFirst, isLast, isActive, prevCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m     = milestone;
    final color = _statusColor(m);
    final nodeSize = isActive ? 44.0 : 36.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Rail ────────────────────────────────────────────────────────
          SizedBox(
            width: 56,
            child: Column(
              children: [
                // top connector
                if (!isFirst)
                  Container(width: 2, height: 14, color: prevCompleted ? _D.green : _D.stroke)
                else
                  SizedBox(height: 14),
                // node
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: m.isCompleted
                        ? color
                        : isActive
                            ? color.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.08),
                    border: Border.all(color: color, width: isActive ? 3 : 2),
                    boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 12, spreadRadius: 1)] : [],
                  ),
                  child: Icon(_statusIcon(m), size: isActive ? 20 : 16, color: m.isCompleted ? _D.white : color),
                ),
                // bottom connector
                if (!isLast)
                  Expanded(child: Center(child: Container(width: 2, color: m.isCompleted ? _D.green : _D.stroke)))
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Card ────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 0),
              child: _TLCard(milestone: m, isActive: isActive, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _TLCard extends StatelessWidget {
  const _TLCard({required this.milestone, required this.isActive, required this.onTap});
  final MilestoneRecord milestone;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m     = milestone;
    final color = _statusColor(m);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.04) : _D.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.45) : _D.stroke,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 3))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(m.code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: const Text('ACTIVO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: _D.white, letterSpacing: 0.5)),
                  ),
                ],
                const Spacer(),
                if (m.isDelayed && m.delayDays > 0)
                  Row(children: [
                    const Icon(Icons.arrow_upward_rounded, size: 10, color: _D.red),
                    Text('${m.delayDays}d', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.red)),
                  ]),
              ],
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              m.description,
              style: TextStyle(fontSize: isActive ? 14 : 13, fontWeight: FontWeight.w700, color: _D.text, height: 1.3),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Dates row
            Row(
              children: [
                _DatePill(label: 'Contractual', date: m.effectiveContractualDate, color: _D.primary),
                const SizedBox(width: 6),
                _DatePill(label: 'Meta', date: m.effectiveTargetDate, color: _D.accent),
                const SizedBox(width: 6),
                _DatePill(
                  label: 'Real',
                  date: m.actualDate,
                  color: m.actualDate != null ? _D.green : _D.mutedLight,
                  empty: m.actualDate == null,
                ),
              ],
            ),
            // Type / classification tags
            if (m.classificationLabel.isNotEmpty || m.typeLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 5, runSpacing: 4,
                children: [
                  if (m.classificationLabel.isNotEmpty) _SmallTag(m.classificationLabel),
                  if (m.typeLabel.isNotEmpty) _SmallTag(m.typeLabel, outlined: true),
                  if (m.isPenalizable) _SmallTag('Penalizable', color: _D.red),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.date, required this.color, this.empty = false});
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
          color: empty ? Colors.transparent : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: empty ? _D.stroke : color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: empty ? _D.mutedLight : color, letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(
              empty ? '—' : _fmtShort(date),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: empty ? _D.mutedLight : color),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag(this.label, {this.color = _D.muted, this.outlined = false});
  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: outlined ? Colors.transparent : color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: outlined ? 0.3 : 0)),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// GANTT PANEL — media pantalla, aparece sobre el contenido
// ═══════════════════════════════════════════════════════════════════════════════
class _GanttPanel extends StatelessWidget {
  const _GanttPanel({required this.milestones, required this.onClose});
  final List<MilestoneRecord> milestones;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.50,
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Column(
        children: [
          // ── Handle + header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: _D.stroke, borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                const Icon(Icons.bar_chart_rounded, size: 15, color: _D.muted),
                const SizedBox(width: 5),
                const Text('GANTT DE HITOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _D.muted, letterSpacing: 0.6)),
                const Spacer(),
                GestureDetector(onTap: onClose, child: const Icon(Icons.close_rounded, size: 20, color: _D.muted)),
              ],
            ),
          ),
          Container(height: 1, color: _D.stroke),
          // ── Legend ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _GanttLegend(color: _D.green,    label: 'Completado'),
                const SizedBox(width: 12),
                _GanttLegend(color: _D.accent,   label: 'En proceso'),
                const SizedBox(width: 12),
                _GanttLegend(color: _D.red,      label: 'Retrasado'),
                const SizedBox(width: 12),
                _GanttLegend(color: _D.mutedLight, label: 'Pendiente'),
                const Spacer(),
                const Icon(Icons.vertical_align_center_rounded, size: 12, color: _D.red),
                const SizedBox(width: 3),
                const Text('Hoy', style: TextStyle(fontSize: 9, color: _D.red, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // ── Chart ────────────────────────────────────────────────────────
          Expanded(
            child: milestones.isEmpty
                ? const Center(child: Text('Sin hitos', style: TextStyle(color: _D.muted)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _GanttChart(milestones: milestones),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GanttLegend extends StatelessWidget {
  const _GanttLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 9, color: _D.muted)),
    ],
  );
}

// ─── Gantt Chart ─────────────────────────────────────────────────────────────
class _GanttChart extends StatelessWidget {
  const _GanttChart({required this.milestones});
  final List<MilestoneRecord> milestones;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final now   = DateTime.now();
    final first = milestones.first.effectiveContractualDate;
    final last  = milestones.last.effectiveContractualDate;
    final spanDays = math.max(1, last.difference(first).inDays);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return CustomPaint(
          size: Size(w, h),
          painter: _GanttPainter(
            milestones: milestones,
            first: first,
            spanDays: spanDays,
            now: now,
          ),
        );
      },
    );
  }
}

class _GanttPainter extends CustomPainter {
  const _GanttPainter({
    required this.milestones,
    required this.first,
    required this.spanDays,
    required this.now,
  });

  final List<MilestoneRecord> milestones;
  final DateTime first;
  final int spanDays;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── background track line ─────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = _D.stroke
      ..strokeWidth = 2;
    final trackY = h * 0.55;
    canvas.drawLine(Offset(0, trackY), Offset(w, trackY), trackPaint);

    // ── completed fill ────────────────────────────────────────────────────
    // Draw a thick green line from start to last completed milestone
    MilestoneRecord? lastCompleted;
    for (final m in milestones) {
      if (m.isCompleted) lastCompleted = m;
    }
    if (lastCompleted != null) {
      final endX = _xFor(lastCompleted.effectiveContractualDate, w);
      final fillPaint = Paint()..color = _D.green.withValues(alpha: 0.30)..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, trackY), Offset(endX, trackY), fillPaint);
    }

    // ── start marker ──────────────────────────────────────────────────────
    _drawVerticalMarker(canvas, 0, trackY, h, _D.primary.withValues(alpha: 0.5), 'INICIO', size, top: true);

    // ── end marker ────────────────────────────────────────────────────────
    _drawVerticalMarker(canvas, w, trackY, h, _D.mutedLight, 'FIN', size, top: true);

    // ── today marker ──────────────────────────────────────────────────────
    if (now.isAfter(first) && now.isBefore(first.add(Duration(days: spanDays + 1)))) {
      final todayX = _xFor(now, w);
      _drawVerticalMarker(canvas, todayX, trackY, h, _D.red, 'HOY', size, top: false);
    }

    // ── milestone dots ────────────────────────────────────────────────────
    for (int i = 0; i < milestones.length; i++) {
      final m    = milestones[i];
      final x    = _xFor(m.effectiveContractualDate, w);
      final color = m.isCompleted ? _D.green : m.isDelayed ? _D.red : m.isInProgress ? _D.accent : _D.mutedLight;

      // Dot
      final dotPaint = Paint()..color = color;
      final dotRadius = m.isInProgress || m.isDelayed ? 8.0 : 6.0;
      canvas.drawCircle(Offset(x, trackY), dotRadius, dotPaint);

      // White inner for non-completed
      if (!m.isCompleted) {
        final innerPaint = Paint()..color = _D.white;
        canvas.drawCircle(Offset(x, trackY), dotRadius - 2.5, innerPaint);
      }

      // Number label — alternating above/below track
      final labelY = i.isEven ? trackY - dotRadius - 22 : trackY + dotRadius + 14;
      final tp = TextPainter(
        text: TextSpan(
          text: m.code.isNotEmpty ? m.code.replaceFirst('HT-', '') : '${m.order}',
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, labelY));

      // Connector tick
      final tickPaint = Paint()..color = color..strokeWidth = 1;
      canvas.drawLine(Offset(x, trackY - dotRadius), Offset(x, i.isEven ? trackY - dotRadius - 14 : trackY + dotRadius), tickPaint);
    }
  }

  double _xFor(DateTime date, double w) {
    final days = date.difference(first).inDays;
    return (days / spanDays * w).clamp(0.0, w);
  }

  void _drawVerticalMarker(Canvas canvas, double x, double trackY, double h, Color color, String label, Size size, {required bool top}) {
    final paint = Paint()..color = color..strokeWidth = 1.5;
    canvas.drawLine(Offset(x, trackY - 12), Offset(x, trackY + 12), paint);

    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
    tp.paint(canvas, Offset(labelX, top ? trackY - 26 : trackY + 14));
  }

  @override
  bool shouldRepaint(_GanttPainter old) => false;
}
