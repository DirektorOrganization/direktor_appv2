// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg        = Color(0xFFF0F4F9);
  static const surface   = Colors.white;
  static const stroke    = Color(0xFFDDE6F0);
  static const text      = Color(0xFF0F172A);
  static const muted     = Color(0xFF64748B);
  static const dim       = Color(0xFF94A3B8);
  static const red       = Color(0xFFEF4444);
  static const orange    = Color(0xFFF97316);
  static const yellow    = Color(0xFFF59E0B);
  static const green     = Color(0xFF10B981);
  static const blue      = Color(0xFF3B82F6);
  // construction palette
  static const concrete  = Color(0xFF6B7280);
  static const beam      = Color(0xFF1E293B);
}

// ─── Column config ────────────────────────────────────────────────────────────
class _KanbanCol {
  const _KanbanCol({required this.id, required this.label, required this.color, required this.icon});
  final int id;
  final String label;
  final Color color;
  final IconData icon;
}

const _cols = [
  _KanbanCol(id: 1, label: 'VENCIDAS',   color: _D.red,    icon: Icons.warning_amber_rounded),
  _KanbanCol(id: 2, label: 'HOY',        color: _D.orange, icon: Icons.today_rounded),
  _KanbanCol(id: 3, label: 'EN PROCESO', color: _D.yellow, icon: Icons.timelapse_rounded),
  _KanbanCol(id: 4, label: 'PENDIENTES', color: _D.blue,   icon: Icons.pending_outlined),
  _KanbanCol(id: 5, label: 'CERRADAS',   color: _D.green,  icon: Icons.check_circle_outline_rounded),
];

List<RestrictionRecord> _forCol(int id, List<RestrictionRecord> all) {
  switch (id) {
    case 1: return all.where((r) => r.isOverdue).toList();
    case 2: return all.where((r) => r.isDueToday && !r.isOverdue).toList();
    case 3: return all.where((r) => r.isInProgress && !r.isDueToday && !r.isOverdue).toList();
    case 4: return all.where((r) => r.isPending && !r.isDueToday && !r.isOverdue && !r.isInProgress).toList();
    case 5: return all.where((r) => r.isCompleted).toList();
    default: return [];
  }
}

String _initials(String name) {
  final p = name.trim().split(' ');
  if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
  return p[0].isNotEmpty ? p[0][0].toUpperCase() : '?';
}

int _daysLeft(RestrictionRecord r) => r.requiredDate.difference(DateTime.now()).inDays;

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv3KanbanScreen extends StatelessWidget {
  const Rv3KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final all = ctrl.restrictions;
        final project = ctrl.currentProject;

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.beam,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: _D.dim),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TABLERO KANBAN', style: TextStyle(color: _D.dim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                Text(project?.name ?? '—', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                tooltip: 'Nueva restricción',
                onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Summary strip ─────────────────────────────────────────────
              _SummaryStrip(all: all),
              // ── Kanban board ──────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  itemCount: _cols.length,
                  itemBuilder: (_, i) {
                    final col = _cols[i];
                    final cards = _forCol(col.id, all);
                    return _KanbanColumn(col: col, cards: cards);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Summary strip ────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.all});
  final List<RestrictionRecord> all;

  @override
  Widget build(BuildContext context) {
    final summary = AppScope.of(context).restrictionSummary;
    return Container(
      color: _D.beam,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _SumCell(label: 'TOTAL', value: '${summary.total}', color: Colors.white),
          _SumCell(label: 'CUMPL.', value: '${summary.compliancePercent.toStringAsFixed(0)}%', color: _D.green),
          _SumCell(label: 'VENC.', value: '${summary.overdue}', color: _D.red),
          _SumCell(label: 'EN PROC.', value: '${summary.inProgress}', color: _D.yellow),
          _SumCell(label: 'PEND.', value: '${summary.pending}', color: _D.blue),
        ],
      ),
    );
  }
}

class _SumCell extends StatelessWidget {
  const _SumCell({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800, height: 1)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _D.dim, fontSize: 9, letterSpacing: 1)),
      ],
    ),
  );
}

// ─── Kanban column ────────────────────────────────────────────────────────────
class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.col, required this.cards});
  final _KanbanCol col;
  final List<RestrictionRecord> cards;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: col.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: col.color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(col.icon, size: 15, color: col.color),
                const SizedBox(width: 7),
                Expanded(child: Text(col.label, style: TextStyle(color: col.color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: col.color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text('${cards.length}', style: TextStyle(color: col.color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // cards scroll
          Expanded(
            child: cards.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Sin restricciones', style: TextStyle(color: _D.dim, fontSize: 11), textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => _KanbanCard(r: cards[i], accentColor: col.color),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Kanban card ──────────────────────────────────────────────────────────────
class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.r, required this.accentColor});
  final RestrictionRecord r;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final days = _daysLeft(r);
    final dayLabel = r.isCompleted
        ? '✓'
        : r.isOverdue
            ? '↑${-days}d'
            : r.isDueToday
                ? 'HOY'
                : '${days}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // activity title
          Text(r.activity, style: const TextStyle(color: _D.text, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          // location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 11, color: _D.dim),
              const SizedBox(width: 3),
              Expanded(child: Text('${r.front} · ${r.phase}', style: const TextStyle(color: _D.muted, fontSize: 10), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 3),
          // area tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _D.bg, borderRadius: BorderRadius.circular(4), border: Border.all(color: _D.stroke)),
            child: Text(r.area, style: const TextStyle(color: _D.concrete, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          // footer row
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: accentColor.withValues(alpha: 0.15),
                child: Text(_initials(r.responsible), style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 5),
              Expanded(child: Text(r.responsible, style: const TextStyle(color: _D.muted, fontSize: 10), overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(dayLabel, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
