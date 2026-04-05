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
  static const accentLight = Color(0xFFCCDFF7);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const red         = Color(0xFFEF4444);
  static const green       = Color(0xFF10B981);
  static const yellow      = Color(0xFFF59E0B);
  static const orange      = Color(0xFFF97316);
  static const white       = Colors.white;
  // Timeline line color
  static const timeline    = Color(0xFFCBD5E1);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Color _urgencyColor(RestrictionRecord r) {
  if (r.isOverdue)    return _D.red;
  if (r.isDueToday)   return _D.orange;
  if (r.isInProgress) return _D.yellow;
  if (r.isCompleted)  return _D.green;
  return _D.mutedLight;
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

int _daysUntil(DateTime d) {
  final today  = DateTime.now();
  final t      = DateTime(today.year, today.month, today.day);
  final target = DateTime(d.year, d.month, d.day);
  return target.difference(t).inDays;
}

// ─── Section model ────────────────────────────────────────────────────────────
enum _Section {
  overdue,
  dueToday,
  thisWeek,
  upcoming,
  closed,
}

String _sectionLabel(_Section s) => switch (s) {
  _Section.overdue   => 'VENCIDAS',
  _Section.dueToday  => 'VENCE HOY',
  _Section.thisWeek  => 'ESTA SEMANA',
  _Section.upcoming  => 'PROXIMAS',
  _Section.closed    => 'CERRADAS',
};

Color _sectionColor(_Section s) => switch (s) {
  _Section.overdue   => _D.red,
  _Section.dueToday  => _D.orange,
  _Section.thisWeek  => _D.yellow,
  _Section.upcoming  => _D.primary,
  _Section.closed    => _D.green,
};

IconData _sectionIcon(_Section s) => switch (s) {
  _Section.overdue   => Icons.warning_amber_rounded,
  _Section.dueToday  => Icons.today_rounded,
  _Section.thisWeek  => Icons.date_range_rounded,
  _Section.upcoming  => Icons.event_rounded,
  _Section.closed    => Icons.check_circle_rounded,
};

_Section _classify(RestrictionRecord r) {
  if (r.isCompleted) return _Section.closed;
  if (r.isOverdue)   return _Section.overdue;
  if (r.isDueToday)  return _Section.dueToday;
  final days = _daysUntil(r.requiredDate);
  if (days <= 7)     return _Section.thisWeek;
  return _Section.upcoming;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv2BitacoraScreen extends StatefulWidget {
  const Rv2BitacoraScreen({super.key});

  @override
  State<Rv2BitacoraScreen> createState() => _Rv2BitacoraScreenState();
}

class _Rv2BitacoraScreenState extends State<Rv2BitacoraScreen> {
  // Tracks which sections are collapsed
  final Set<_Section> _collapsed = {_Section.closed};
  // Tracks which cards are expanded (show full description)
  final Set<int> _expanded = {};

  void _toggleSection(_Section s) =>
      setState(() => _collapsed.contains(s)
          ? _collapsed.remove(s)
          : _collapsed.add(s));

  void _toggleCard(int id) =>
      setState(() => _expanded.contains(id)
          ? _expanded.remove(id)
          : _expanded.add(id));

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final restrictions = ctrl.restrictions;
        final summary      = ctrl.restrictionSummary;
        final project      = ctrl.currentProject;

        // Build section map
        final sectionMap = <_Section, List<RestrictionRecord>>{};
        for (final r in restrictions) {
          final sec = _classify(r);
          sectionMap.putIfAbsent(sec, () => []).add(r);
        }
        // Sort within each section by requiredDate
        for (final key in sectionMap.keys) {
          sectionMap[key]!.sort(
            (a, b) => a.requiredDate.compareTo(b.requiredDate),
          );
        }
        // Section display order
        const order = [
          _Section.overdue,
          _Section.dueToday,
          _Section.thisWeek,
          _Section.upcoming,
          _Section.closed,
        ];
        final activeSections = order.where((s) =>
            sectionMap.containsKey(s) && sectionMap[s]!.isNotEmpty).toList();

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: Column(
            children: [
              // ── KPI strip ─────────────────────────────────────────────────
              _KpiStrip(summary: summary),
              // ── Timeline content ──────────────────────────────────────────
              Expanded(
                child: restrictions.isEmpty
                    ? const _EmptyBitacora()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                        itemCount: activeSections.length,
                        itemBuilder: (_, i) {
                          final sec   = activeSections[i];
                          final items = sectionMap[sec]!;
                          final isLast = i == activeSections.length - 1;
                          return _SectionBlock(
                            section: sec,
                            items: items,
                            collapsed: _collapsed.contains(sec),
                            expandedCards: _expanded,
                            isLast: isLast,
                            onToggleSection: () => _toggleSection(sec),
                            onToggleCard: _toggleCard,
                            onTapCard: (r) => Navigator.of(ctx).pushNamed(
                              RouteNames.restrictionDetail,
                              arguments: RestrictionDetailArgs(
                                restrictionId: r.id,
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
                Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
            backgroundColor: _D.primary,
            foregroundColor: _D.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Nueva Restriccion',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext ctx, ProjectRecord? project) {
    return AppBar(
      backgroundColor: _D.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bitacora de Restricciones',
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
          icon: const Icon(Icons.add_rounded, color: _D.primary),
          onPressed: () =>
              Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

// ─── KPI Strip ────────────────────────────────────────────────────────────────
class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.summary});
  final RestrictionSummary summary;

  @override
  Widget build(BuildContext context) {
    final pct = summary.compliancePercent;
    return Container(
      color: _D.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Mini compliance arc
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(48, 48),
                  painter: _MiniArc(percent: pct / 100),
                ),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
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
                  value: summary.total,
                  color: _D.primary,
                ),
                _KpiPill(
                  label: 'Vencidas',
                  value: summary.overdue,
                  color: summary.overdue > 0 ? _D.red : _D.mutedLight,
                ),
                _KpiPill(
                  label: 'En proceso',
                  value: summary.inProgress,
                  color: _D.yellow,
                ),
                _KpiPill(
                  label: 'Cerradas',
                  value: summary.completed,
                  color: _D.green,
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
  });
  final String label;
  final int value;
  final Color color;

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
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _D.muted),
          ),
        ],
      ),
    );
  }
}

class _MiniArc extends CustomPainter {
  const _MiniArc({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap  = StrokeCap.round;
    final pct = percent * 100;
    paint.color = _D.stroke;
    canvas.drawCircle(center, radius, paint);
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
  bool shouldRepaint(_MiniArc o) => o.percent != percent;
}

// ─── Section Block ────────────────────────────────────────────────────────────
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    required this.items,
    required this.collapsed,
    required this.expandedCards,
    required this.isLast,
    required this.onToggleSection,
    required this.onToggleCard,
    required this.onTapCard,
  });

  final _Section section;
  final List<RestrictionRecord> items;
  final bool collapsed;
  final Set<int> expandedCards;
  final bool isLast;
  final VoidCallback onToggleSection;
  final void Function(int) onToggleCard;
  final void Function(RestrictionRecord) onTapCard;

  @override
  Widget build(BuildContext context) {
    final color = _sectionColor(section);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline column ───────────────────────────────────────────────
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Section node — circle con icono
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(_sectionIcon(section), size: 16, color: color),
                ),
                // Línea vertical continua
                if (!isLast || !collapsed)
                  Container(
                    width: 2,
                    // altura suficiente; crece con el contenido
                    height: collapsed ? 16 : null,
                    constraints: collapsed
                        ? const BoxConstraints()
                        : const BoxConstraints(minHeight: 20),
                    color: _D.timeline,
                  ),
              ],
            ),
          ),
          // ── Content column ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                GestureDetector(
                  onTap: onToggleSection,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Row(
                      children: [
                        Text(
                          _sectionLabel(section),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
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
                        const Spacer(),
                        AnimatedRotation(
                          turns: collapsed ? -0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: color.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Cards
                if (!collapsed)
                  ...items.asMap().entries.map((e) {
                    final idx        = e.key;
                    final r          = e.value;
                    final isExpanded = expandedCards.contains(r.id);
                    final isLastCard = idx == items.length - 1;

                    return _BitacoraEntry(
                      record: r,
                      section: section,
                      isExpanded: isExpanded,
                      isLastCard: isLastCard && isLast,
                      onToggleExpand: () => onToggleCard(r.id),
                      onTap: () => onTapCard(r),
                    );
                  }),
                if (collapsed) const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bitácora Entry ───────────────────────────────────────────────────────────
class _BitacoraEntry extends StatelessWidget {
  const _BitacoraEntry({
    required this.record,
    required this.section,
    required this.isExpanded,
    required this.isLastCard,
    required this.onToggleExpand,
    required this.onTap,
  });

  final RestrictionRecord record;
  final _Section section;
  final bool isExpanded;
  final bool isLastCard;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r     = record;
    final color = _urgencyColor(r);
    final days  = _daysUntil(r.requiredDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: r.isOverdue
                ? _D.red.withValues(alpha: 0.25)
                : _D.stroke,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera de la ficha ────────────────────────────────────
            GestureDetector(
              onTap: onToggleExpand,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fecha sello
                    _DateStamp(date: r.requiredDate, color: color),
                    const SizedBox(width: 10),
                    // Actividad + frente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.activity,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _D.text,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (r.front.isNotEmpty)
                                _InlineTag(
                                  icon: Icons.location_on_rounded,
                                  label: r.front,
                                  color: _D.primary,
                                ),
                              if (r.phase.isNotEmpty) ...[
                                const SizedBox(width: 5),
                                _InlineTag(
                                  icon: Icons.layers_rounded,
                                  label: r.phase,
                                  color: _D.muted,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Urgency chip derecho
                    _UrgencyChip(record: r, days: days, color: color),
                  ],
                ),
              ),
            ),

            // ── Panel expandido ─────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _ExpandedPanel(record: r, onNavigate: onTap),
            ),

            // ── Pie de la ficha ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _D.bg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: _D.stroke),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 12,
                    color: _D.mutedLight,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      r.responsible,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _D.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Sello CERRADO para completadas
                  if (r.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _D.green.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CERRADO',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: _D.green,
                          letterSpacing: 0.7,
                        ),
                      ),
                    )
                  else ...[
                    Icon(
                      r.isSynced
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined,
                      size: 13,
                      color: r.isSynced ? _D.green : _D.mutedLight,
                    ),
                    const SizedBox(width: 6),
                    // Expandir / colapsar
                    GestureDetector(
                      onTap: onToggleExpand,
                      child: Text(
                        isExpanded ? 'Ver menos' : 'Ver detalle',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _D.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Stamp ───────────────────────────────────────────────────────────────
/// Columna de fecha estilo sello de bitácora.
class _DateStamp extends StatelessWidget {
  const _DateStamp({required this.date, required this.color});
  final DateTime date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          Text(
            _fmtShort(date).substring(3), // MM/YYYY
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Urgency Chip ─────────────────────────────────────────────────────────────
class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip({
    required this.record,
    required this.days,
    required this.color,
  });
  final RestrictionRecord record;
  final int days;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = record;
    String label;
    if (r.isCompleted) {
      label = 'Cerrada';
    } else if (r.isOverdue) {
      label = '${days.abs()}d venc.';
    } else if (r.isDueToday) {
      label = 'Hoy';
    } else {
      label = 'en ${days}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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

// ─── Expanded Panel ───────────────────────────────────────────────────────────
class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({required this.record, required this.onNavigate});
  final RestrictionRecord record;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripcion completa
          if (r.description.isNotEmpty)
            Text(
              r.description,
              style: const TextStyle(
                fontSize: 12,
                color: _D.muted,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 10),
          // Tabla de datos
          _InfoRow(icon: Icons.label_outline_rounded,   label: 'Tipo',     value: r.type.isNotEmpty     ? r.type     : '—'),
          const SizedBox(height: 5),
          _InfoRow(icon: Icons.landscape_rounded,       label: 'Area',     value: r.area.isNotEmpty     ? r.area     : '—'),
          const SizedBox(height: 5),
          _InfoRow(icon: Icons.calendar_today_rounded,  label: 'Requerida', value: _fmtDate(r.requiredDate)),
          if (r.conciliatedDate != null) ...[
            const SizedBox(height: 5),
            _InfoRow(
              icon: Icons.event_available_rounded,
              label: 'Conciliada',
              value: _fmtDate(r.conciliatedDate!),
              valueColor: _D.green,
            ),
          ],
          const SizedBox(height: 10),
          // Boton ver detalle completo
          GestureDetector(
            onTap: onNavigate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: _D.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _D.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 14, color: _D.primary),
                  SizedBox(width: 6),
                  Text(
                    'Abrir ficha completa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _D.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _D.mutedLight),
        const SizedBox(width: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _D.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _D.text,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Inline Tag ───────────────────────────────────────────────────────────────
class _InlineTag extends StatelessWidget {
  const _InlineTag({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyBitacora extends StatelessWidget {
  const _EmptyBitacora();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _D.accentLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 44,
              color: _D.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bitacora sin entradas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _D.muted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No hay restricciones registradas en este proyecto.',
            style: TextStyle(fontSize: 12, color: _D.mutedLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
