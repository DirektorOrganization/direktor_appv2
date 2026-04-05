// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg         = Color(0xFFF5FAFE);
  static const surface    = Colors.white;
  static const stroke     = Color(0xFFE0EAF6);
  static const primary    = Color(0xFF0A66B7);
  static const hero       = Color(0xFF0D1B2A);
  static const heroMid    = Color(0xFF1B2B3B);
  static const text       = Color(0xFF0F172A);
  static const muted      = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
  static const red        = Color(0xFFEF4444);
  static const green      = Color(0xFF10B981);
  static const yellow     = Color(0xFFF59E0B);
  static const orange     = Color(0xFFF97316);
  static const white      = Colors.white;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
int _daysUntil(DateTime d) {
  final now    = DateTime.now();
  final today  = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  return target.difference(today).inDays;
}

Color _urgencyColor(RestrictionRecord r) {
  if (r.isOverdue)    return _D.red;
  if (r.isDueToday)   return _D.orange;
  if (r.isInProgress) return _D.yellow;
  if (r.isCompleted)  return _D.green;
  return _D.mutedLight;
}

String _initials(String name) {
  final p = name.trim().split(' ');
  if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

Color _avatarColor(String name) {
  const pool = [
    Color(0xFF0A66B7), Color(0xFF0891B2), Color(0xFF7C3AED),
    Color(0xFF059669), Color(0xFFDC2626),
  ];
  return pool[name.hashCode.abs() % pool.length];
}

// ─── Filter ───────────────────────────────────────────────────────────────────
enum _Filter { all, overdue, dueToday, pending, inProgress, completed }

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv2CampoScreen extends StatefulWidget {
  const Rv2CampoScreen({super.key});

  @override
  State<Rv2CampoScreen> createState() => _Rv2CampoScreenState();
}

class _Rv2CampoScreenState extends State<Rv2CampoScreen> {
  _Filter _filter = _Filter.all;

  List<RestrictionRecord> _apply(List<RestrictionRecord> all) {
    final out = switch (_filter) {
      _Filter.all        => all,
      _Filter.overdue    => all.where((r) => r.isOverdue).toList(),
      _Filter.dueToday   => all.where((r) => r.isDueToday && !r.isOverdue).toList(),
      _Filter.pending    => all.where((r) => r.isPending && !r.isOverdue && !r.isDueToday).toList(),
      _Filter.inProgress => all.where((r) => r.isInProgress).toList(),
      _Filter.completed  => all.where((r) => r.isCompleted).toList(),
    };
    return out..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final all      = ctrl.restrictions;
        final summary  = ctrl.restrictionSummary;
        final project  = ctrl.currentProject;
        final filtered = _apply(all);

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(ctx, project),
          body: Column(
            children: [
              _HeroPanel(summary: summary),
              _UrgencyStrip(all: all),
              _FilterBar(
                current: _filter,
                summary: summary,
                total: all.length,
                onChanged: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _Empty(filter: _filter)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _WorkOrderCard(
                          record: filtered[i],
                          onTap: () => Navigator.of(ctx).pushNamed(
                            RouteNames.restrictionDetail,
                            arguments: RestrictionDetailArgs(
                              restrictionId: filtered[i].id,
                            ),
                          ),
                        ),
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
      backgroundColor: _D.hero,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: _D.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Restricciones · Campo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _D.white,
            ),
          ),
          if (project != null)
            Text(
              project.name,
              style: TextStyle(
                fontSize: 11,
                color: _D.white.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          onPressed: () =>
              Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
        ),
      ],
    );
  }
}

// ─── Hero Panel ───────────────────────────────────────────────────────────────
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.summary});
  final RestrictionSummary summary;

  @override
  Widget build(BuildContext context) {
    final pct      = summary.compliancePercent;
    final arcColor = pct >= 80 ? _D.green : pct >= 50 ? _D.yellow : _D.red;

    return Container(
      color: _D.hero,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          // ── Compliance ring ──────────────────────────────────────────────
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(88, 88),
                  painter: _ArcPainter(
                    percent: pct / 100,
                    track: _D.heroMid,
                    arc: arcColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: arcColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'cumplim.',
                      style: TextStyle(
                        fontSize: 9,
                        color: _D.white.withValues(alpha: 0.4),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // ── 4 counters ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    _Counter(value: summary.total,    label: 'Total',    color: _D.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 16),
                    _Counter(value: summary.overdue,  label: 'Vencidas', color: summary.overdue > 0 ? _D.red : _D.mutedLight, big: summary.overdue > 0),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Counter(value: summary.inProgress, label: 'En proceso', color: _D.yellow),
                    const SizedBox(width: 16),
                    _Counter(value: summary.completed,  label: 'Cerradas',   color: _D.green),
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

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.label,
    required this.color,
    this.big = false,
  });
  final int value;
  final String label;
  final Color color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: big ? 30 : 22,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _D.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arc Painter ─────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.percent,
    required this.track,
    required this.arc,
  });
  final double percent;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 7;
    final p = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap  = StrokeCap.round;

    p.color = track;
    canvas.drawCircle(c, r, p);
    p.color = arc;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * percent.clamp(0.0, 1.0),
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter o) => o.percent != percent || o.arc != arc;
}

// ─── Urgency Strip ────────────────────────────────────────────────────────────
/// Grilla visual: un bloque por restricción, coloreado por urgencia.
/// Lectura inmediata del estado global del proyecto.
class _UrgencyStrip extends StatelessWidget {
  const _UrgencyStrip({required this.all});
  final List<RestrictionRecord> all;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) return const SizedBox.shrink();
    final sorted = [...all]
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    return Container(
      color: _D.hero,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'RESUMEN VISUAL  ·  ${all.length} restricciones',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _D.white.withValues(alpha: 0.35),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 7),
          // Bloques
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: sorted.map((r) => Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _urgencyColor(r),
                borderRadius: BorderRadius.circular(3),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Leyenda inline
          Row(
            children: [
              _Dot(color: _D.red,       label: 'Vencida'),
              const SizedBox(width: 12),
              _Dot(color: _D.orange,    label: 'Hoy'),
              const SizedBox(width: 12),
              _Dot(color: _D.yellow,    label: 'En proceso'),
              const SizedBox(width: 12),
              _Dot(color: _D.green,     label: 'Cerrada'),
              const SizedBox(width: 12),
              _Dot(color: _D.mutedLight, label: 'Pendiente'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: _D.white.withValues(alpha: 0.4),
          ),
        ),
      ],
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
  final _Filter current;
  final RestrictionSummary summary;
  final int total;
  final void Function(_Filter) onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <({_Filter f, String label, int count, Color color})>[
      (f: _Filter.all,        label: 'Todas',      count: total,              color: _D.primary),
      (f: _Filter.overdue,    label: 'Vencidas',   count: summary.overdue,    color: _D.red),
      (f: _Filter.dueToday,   label: 'Hoy',        count: 0,                  color: _D.orange),
      (f: _Filter.pending,    label: 'Pendientes', count: summary.pending,    color: _D.mutedLight),
      (f: _Filter.inProgress, label: 'En proceso', count: summary.inProgress, color: _D.yellow),
      (f: _Filter.completed,  label: 'Cerradas',   count: summary.completed,  color: _D.green),
    ];

    return Container(
      color: _D.surface,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: items.map((it) {
                final sel = current == it.f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(it.f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? it.color.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: sel
                              ? it.color.withValues(alpha: 0.5)
                              : _D.stroke,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            it.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel ? it.color : _D.muted,
                            ),
                          ),
                          if (it.count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? it.color.withValues(alpha: 0.15)
                                    : _D.stroke,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${it.count}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? it.color : _D.muted,
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

// ─── Work Order Card ──────────────────────────────────────────────────────────
/// Tarjeta estilo "orden de trabajo" de obra.
/// Badge izquierdo = contador de días (principal señal visual).
/// Contenido = actividad + ubicación + responsable.
class _WorkOrderCard extends StatelessWidget {
  const _WorkOrderCard({required this.record, required this.onTap});
  final RestrictionRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r     = record;
    final color = _urgencyColor(r);
    final days  = _daysUntil(r.requiredDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: r.isOverdue
                ? _D.red.withValues(alpha: 0.35)
                : _D.stroke,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Day Badge (izquierda) ────────────────────────────────
                _DayBadge(record: r, days: days, color: color),

                // ── Contenido ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Actividad — texto principal
                        Text(
                          r.activity,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _D.text,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Ubicación: frente > fase
                        if (r.front.isNotEmpty || r.phase.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: _D.mutedLight,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  [r.front, r.phase]
                                      .where((s) => s.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _D.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        // Descripción breve
                        if (r.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _D.mutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Footer: responsable + tipo + sync
                        Row(
                          children: [
                            // Avatar iniciales
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _avatarColor(r.responsible),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initials(r.responsible),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _D.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
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
                            // Tipo de restricción (pequeño)
                            if (r.type.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _D.stroke,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.type,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: _D.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 6),
                            Icon(
                              r.isSynced
                                  ? Icons.cloud_done_outlined
                                  : Icons.cloud_upload_outlined,
                              size: 13,
                              color: r.isSynced ? _D.green : _D.mutedLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Franja de estado (derecha) ───────────────────────────
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
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

// ─── Day Badge ────────────────────────────────────────────────────────────────
/// Panel izquierdo de la tarjeta: muestra días restantes u "HOY".
/// Es la señal visual más importante de la tarjeta.
class _DayBadge extends StatelessWidget {
  const _DayBadge({
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
    Widget content;

    if (r.isCompleted) {
      content = Icon(Icons.check_rounded, size: 26, color: _D.green);
    } else if (r.isOverdue) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_upward_rounded, size: 13, color: _D.red),
          Text(
            '${days.abs()}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _D.red,
              height: 1,
            ),
          ),
          const Text(
            'días',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _D.red,
            ),
          ),
        ],
      );
    } else if (r.isDueToday) {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.today_rounded, size: 18, color: _D.orange),
          SizedBox(height: 3),
          Text(
            'HOY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _D.orange,
            ),
          ),
        ],
      );
    } else {
      // Pendiente con cuenta atrás
      final urgent = days <= 3;
      final tc     = urgent ? _D.yellow : _D.primary;
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$days',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: tc,
              height: 1,
            ),
          ),
          Text(
            'días',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: tc.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return Container(
      width: 66,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(
          right: BorderSide(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  const _Empty({required this.filter});
  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final good = filter == _Filter.overdue || filter == _Filter.dueToday;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (good ? _D.green : _D.primary).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              good ? Icons.check_circle_outline_rounded : Icons.construction_rounded,
              size: 44,
              color: good ? _D.green : _D.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            good ? 'Todo bajo control' : 'Sin resultados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: good ? _D.green : _D.muted,
            ),
          ),
        ],
      ),
    );
  }
}
