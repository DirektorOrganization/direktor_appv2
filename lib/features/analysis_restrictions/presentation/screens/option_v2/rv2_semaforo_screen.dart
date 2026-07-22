// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
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
  static const white = Colors.white;
  static const darkHero = Color(0xFF0F172A);
  static const orange = Color(0xFFF97316);
}

enum _ResFilter { all, overdue, dueToday, pending, inProgress, completed }

bool _anaresColumnVisible(BuildContext context, String columnKey) {
  return AppScope.of(context).isCustomizedColumnVisible('ANARES', columnKey);
}

class Rv2SemaforoScreen extends StatefulWidget {
  const Rv2SemaforoScreen({super.key});

  @override
  State<Rv2SemaforoScreen> createState() => _Rv2SemaforoScreenState();
}

class _Rv2SemaforoScreenState extends State<Rv2SemaforoScreen> {
  _ResFilter _filter = _ResFilter.all;

  Color _statusColor(RestrictionRecord r) {
    if (r.isOverdue) return _D.red;
    if (r.isDueToday) return _D.orange;
    if (r.isInProgress) return _D.yellow;
    if (r.isCompleted) return _D.green;
    return _D.mutedLight;
  }

  String _fmtDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  int _daysFromNow(DateTime d) => d.difference(DateTime.now()).inDays;

  List<RestrictionRecord> _applyFilter(List<RestrictionRecord> all) {
    return switch (_filter) {
      _ResFilter.all => all,
      _ResFilter.overdue => all.where((r) => r.isOverdue).toList(),
      _ResFilter.dueToday =>
        all.where((r) => r.isDueToday && !r.isOverdue).toList(),
      _ResFilter.pending => all.where((r) => r.isPending).toList(),
      _ResFilter.inProgress => all.where((r) => r.isInProgress).toList(),
      _ResFilter.completed => all.where((r) => r.isCompleted).toList(),
    };
  }

  void _goCreate() =>
      Navigator.pushNamed(context, RouteNames.restrictionCreate);

  void _goDetail(int id) => Navigator.pushNamed(
    context,
    RouteNames.restrictionDetail,
    arguments: RestrictionDetailArgs(restrictionId: id),
  );

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final restrictions = controller.restrictions;
    final summary = controller.restrictionSummary;
    final project = controller.currentProject;
    final filtered = _applyFilter(restrictions);

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: _buildAppBar(project),
      body: Column(
        children: [
          _HeroSection(summary: summary),
          _FilterStrip(
            current: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _RestrictionCard(
                      record: filtered[i],
                      statusColor: _statusColor(filtered[i]),
                      fmtDate: _fmtDate,
                      daysFromNow: _daysFromNow,
                      onTap: () => _goDetail(filtered[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goCreate,
        backgroundColor: _D.primary,
        icon: const Icon(Icons.add_rounded, color: _D.white),
        label: const Text(
          'Nueva Restricción',
          style: TextStyle(color: _D.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ProjectRecord? project) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _D.text,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restricciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _D.text,
            ),
          ),
          if (project != null)
            Text(
              project.name,
              style: const TextStyle(fontSize: 12, color: _D.muted),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded, color: _D.primary),
          onPressed: _goCreate,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.summary});
  final RestrictionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _D.darkHero,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        children: [
          _SemaforoHero(summary: summary),
          const SizedBox(height: 16),
          _ComplianceBar(percent: summary.compliancePercent),
        ],
      ),
    );
  }
}

class _SemaforoHero extends StatelessWidget {
  const _SemaforoHero({required this.summary});
  final RestrictionSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasOverdue = summary.overdue > 0;
    final hasInProgress = summary.inProgress > 0;
    final redActive = hasOverdue;
    final yellowActive = !hasOverdue && hasInProgress;
    final greenActive = !hasOverdue && !hasInProgress;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TrafficCircle(
          color: _D.red,
          count: summary.overdue,
          label: 'Vencidas',
          isActive: redActive,
        ),
        _TrafficCircle(
          color: _D.yellow,
          count: summary.inProgress,
          label: 'En proceso',
          isActive: yellowActive,
        ),
        _TrafficCircle(
          color: _D.green,
          count: summary.completed,
          label: 'Finalizadas',
          isActive: greenActive,
        ),
      ],
    );
  }
}

class _TrafficCircle extends StatelessWidget {
  const _TrafficCircle({
    required this.color,
    required this.count,
    required this.label,
    required this.isActive,
  });

  final Color color;
  final int count;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final size = isActive ? 72.0 : 64.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: isActive
                ? Border.all(color: _D.white.withValues(alpha: 0.3), width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: _D.white,
                fontSize: isActive ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: _D.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ComplianceBar extends StatelessWidget {
  const _ComplianceBar({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${pct.toStringAsFixed(0)}% de cumplimiento',
          style: const TextStyle(
            color: _D.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            minHeight: 8,
            backgroundColor: _D.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(_D.primary),
          ),
        ),
      ],
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.current, required this.onChanged});

  final _ResFilter current;
  final ValueChanged<_ResFilter> onChanged;

  static const _chips = [
    (_ResFilter.all, 'Todas'),
    (_ResFilter.overdue, 'Vencidas'),
    (_ResFilter.dueToday, 'Vence hoy'),
    (_ResFilter.pending, 'Pendientes'),
    (_ResFilter.inProgress, 'En proceso'),
    (_ResFilter.completed, 'Finalizadas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _D.darkHero,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _chips
              .map(
                (entry) => _FilterChip(
                  label: entry.$2,
                  isActive: current == entry.$1,
                  onTap: () => onChanged(entry.$1),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? _D.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _D.white : _D.mutedLight.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _D.text : _D.mutedLight,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RestrictionCard extends StatelessWidget {
  const _RestrictionCard({
    required this.record,
    required this.statusColor,
    required this.fmtDate,
    required this.daysFromNow,
    required this.onTap,
  });

  final RestrictionRecord record;
  final Color statusColor;
  final String Function(DateTime) fmtDate;
  final int Function(DateTime) daysFromNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                Container(width: 6, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardTopRow(record: record, daysFromNow: daysFromNow),
                        const SizedBox(height: 8),
                        _CardMiddleRow(record: record),
                        const SizedBox(height: 8),
                        _CardBottomRow(record: record, fmtDate: fmtDate),
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

class _CardTopRow extends StatelessWidget {
  const _CardTopRow({required this.record, required this.daysFromNow});

  final RestrictionRecord record;
  final int Function(DateTime) daysFromNow;

  @override
  Widget build(BuildContext context) {
    final showFront = _anaresColumnVisible(context, 'frente');
    final showPhase = _anaresColumnVisible(context, 'fase');
    return Row(
      children: [
        if (showFront && record.front.isNotEmpty)
          _MiniPill(label: record.front, bg: _D.accentLight, fg: _D.accent),
        if (showFront &&
            record.front.isNotEmpty &&
            showPhase &&
            record.phase.isNotEmpty)
          const SizedBox(width: 6),
        if (showPhase && record.phase.isNotEmpty)
          _MiniPill(label: record.phase, bg: _D.accentLight, fg: _D.accent),
        const Spacer(),
        _UrgencyBadge(record: record, daysFromNow: daysFromNow),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.record, required this.daysFromNow});

  final RestrictionRecord record;
  final int Function(DateTime) daysFromNow;

  @override
  Widget build(BuildContext context) {
    final r = record;
    if (r.isOverdue) {
      final days = daysFromNow(r.requiredDate).abs();
      return _MiniPill(
        label: 'VENCIDA · ${days}d',
        bg: _D.red.withValues(alpha: 0.12),
        fg: _D.red,
      );
    }
    if (r.isDueToday) {
      return _MiniPill(
        label: 'VENCE HOY',
        bg: _D.orange.withValues(alpha: 0.12),
        fg: _D.orange,
      );
    }
    if (r.isPending) {
      final days = daysFromNow(r.requiredDate);
      return _MiniPill(
        label: 'en $days días',
        bg: _D.mutedLight.withValues(alpha: 0.15),
        fg: _D.muted,
      );
    }
    return const SizedBox.shrink();
  }
}

class _CardMiddleRow extends StatelessWidget {
  const _CardMiddleRow({required this.record});
  final RestrictionRecord record;

  @override
  Widget build(BuildContext context) {
    final showActivity = _anaresColumnVisible(context, 'desActividad');
    final showRestriction = _anaresColumnVisible(context, 'desRestriccion');
    final titleText = showActivity && record.activity.isNotEmpty
        ? record.activity
        : (showRestriction && record.description.isNotEmpty
              ? record.description
              : 'Restricción');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _D.text,
          ),
        ),
        if (showRestriction && record.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            record.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _D.muted),
          ),
        ],
      ],
    );
  }
}

class _CardBottomRow extends StatelessWidget {
  const _CardBottomRow({required this.record, required this.fmtDate});

  final RestrictionRecord record;
  final String Function(DateTime) fmtDate;

  @override
  Widget build(BuildContext context) {
    final showResponsible = _anaresColumnVisible(context, 'responsable');
    final showRequiredDate = _anaresColumnVisible(context, 'dayFechaRequerida');
    final showConciliatedDate = _anaresColumnVisible(
      context,
      'dayFechaConciliada',
    );
    final visibleDate = record.conciliatedDate != null && showConciliatedDate
        ? record.conciliatedDate!
        : (showRequiredDate ? record.requiredDate : null);
    return Row(
      children: [
        if (showResponsible && record.responsible.isNotEmpty) ...[
          const Icon(Icons.person_outline_rounded, size: 14, color: _D.muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              record.responsible,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _D.muted),
            ),
          ),
        ] else
          const Spacer(),
        if (visibleDate != null) ...[
          const SizedBox(width: 8),
          const Icon(Icons.access_time_rounded, size: 14, color: _D.muted),
          const SizedBox(width: 4),
          Text(
            fmtDate(visibleDate),
            style: const TextStyle(fontSize: 12, color: _D.muted),
          ),
          const SizedBox(width: 8),
        ],
        _SyncDot(isSynced: record.isSynced),
      ],
    );
  }
}

class _SyncDot extends StatelessWidget {
  const _SyncDot({required this.isSynced});
  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isSynced ? _D.green : _D.yellow,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: _D.mutedLight,
            ),
            SizedBox(height: 16),
            Text(
              'Sin restricciones en esta categía',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _D.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cambia el filtro para ver otras restricciones',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _D.muted),
            ),
          ],
        ),
      ),
    );
  }
}
