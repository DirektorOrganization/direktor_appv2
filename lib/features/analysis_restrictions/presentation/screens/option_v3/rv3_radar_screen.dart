// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg        = Color(0xFF0B1420);
  static const surface   = Color(0xFF121E30);
  static const card      = Color(0xFF1A2840);
  static const border    = Color(0xFF243450);
  static const primary   = Color(0xFF3B82F6);
  static const text      = Color(0xFFE2E8F0);
  static const muted     = Color(0xFF64748B);
  static const dim       = Color(0xFF334155);
  static const red       = Color(0xFFEF4444);
  static const orange    = Color(0xFFF97316);
  static const yellow    = Color(0xFFF59E0B);
  static const green     = Color(0xFF10B981);
  static const blue      = Color(0xFF3B82F6);
  // construction accent
  static const hardhat   = Color(0xFFFBBF24);
  static const steel     = Color(0xFF94A3B8);
}

Color _urgencyColor(RestrictionRecord r) {
  if (r.isOverdue) return _D.red;
  if (r.isDueToday) return _D.orange;
  if (r.isInProgress) return _D.yellow;
  if (r.isCompleted) return _D.green;
  return _D.blue;
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
  return '?';
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv3RadarScreen extends StatefulWidget {
  const Rv3RadarScreen({super.key});

  @override
  State<Rv3RadarScreen> createState() => _Rv3RadarScreenState();
}

class _Rv3RadarScreenState extends State<Rv3RadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _sweep;

  // 0=All 1=Overdue 2=Today 3=InProgress 4=Pending 5=Completed
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _sweep = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<RestrictionRecord> _filtered(List<RestrictionRecord> all) {
    switch (_tab) {
      case 1: return all.where((r) => r.isOverdue).toList();
      case 2: return all.where((r) => r.isDueToday).toList();
      case 3: return all.where((r) => r.isInProgress).toList();
      case 4: return all.where((r) => r.isPending && !r.isDueToday).toList();
      case 5: return all.where((r) => r.isCompleted).toList();
      default: return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    final all = ctrl.restrictions;
    final summary = ctrl.restrictionSummary;
    final filtered = _filtered(all);

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.bg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _D.steel),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RADAR', style: TextStyle(color: _D.hardhat, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3)),
            Text(ctrl.currentProject?.name ?? '—', style: const TextStyle(color: _D.text, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Radar visualization ───────────────────────────────────────────
          SizedBox(
            height: 240,
            child: AnimatedBuilder(
              animation: _sweep,
              builder: (context2, w) => CustomPaint(
                painter: _RadarPainter(
                  pct: _sweep.value,
                  compliance: summary.compliancePercent / 100,
                  overdue: summary.overdue,
                  today: all.where((r) => r.isDueToday).length,
                  inProgress: summary.inProgress,
                  pending: summary.pending,
                  completed: summary.completed,
                  total: summary.total,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${summary.compliancePercent.toStringAsFixed(0)}%',
                        style: const TextStyle(color: _D.hardhat, fontSize: 38, fontWeight: FontWeight.w900, height: 1),
                      ),
                      const SizedBox(height: 2),
                      const Text('CUMPLIMIENTO', style: TextStyle(color: _D.muted, fontSize: 10, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Spoke legend row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SpokeLegend(label: 'VENC', count: summary.overdue, color: _D.red),
                _SpokeLegend(label: 'HOY', count: all.where((r) => r.isDueToday).length, color: _D.orange),
                _SpokeLegend(label: 'EN PROC', count: summary.inProgress, color: _D.yellow),
                _SpokeLegend(label: 'PEND', count: summary.pending, color: _D.blue),
                _SpokeLegend(label: 'CIERRE', count: summary.completed, color: _D.green),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Filter tabs ───────────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Tab(label: 'TODAS', count: all.length, active: _tab == 0, color: _D.steel, onTap: () => setState(() => _tab = 0)),
                _Tab(label: 'VENCIDAS', count: summary.overdue, active: _tab == 1, color: _D.red, onTap: () => setState(() => _tab = 1)),
                _Tab(label: 'HOY', count: all.where((r) => r.isDueToday).length, active: _tab == 2, color: _D.orange, onTap: () => setState(() => _tab = 2)),
                _Tab(label: 'EN PROCESO', count: summary.inProgress, active: _tab == 3, color: _D.yellow, onTap: () => setState(() => _tab = 3)),
                _Tab(label: 'PENDIENTES', count: summary.pending, active: _tab == 4, color: _D.blue, onTap: () => setState(() => _tab = 4)),
                _Tab(label: 'CERRADAS', count: summary.completed, active: _tab == 5, color: _D.green, onTap: () => setState(() => _tab = 5)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Card list ─────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Sin restricciones', style: TextStyle(color: _D.muted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _RadarCard(r: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Spoke legend chip ────────────────────────────────────────────────────────
class _SpokeLegend extends StatelessWidget {
  const _SpokeLegend({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$count', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(label, style: const TextStyle(color: _D.muted, fontSize: 9, letterSpacing: 1)),
    ],
  );
}

// ─── Filter tab ───────────────────────────────────────────────────────────────
class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.count, required this.active, required this.color, required this.onTap});
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.18) : _D.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? color : _D.border),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (active) Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text('$label  $count', style: TextStyle(color: active ? color : _D.muted, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    ),
  );
}

// ─── Restriction card ─────────────────────────────────────────────────────────
class _RadarCard extends StatelessWidget {
  const _RadarCard({required this.r});
  final RestrictionRecord r;

  @override
  Widget build(BuildContext context) {
    final accent = _urgencyColor(r);
    final daysLeft = r.requiredDate.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.activity, style: const TextStyle(color: _D.text, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _DayBadge(daysLeft: daysLeft, r: r, accent: accent),
              ],
            ),
            const SizedBox(height: 5),
            Text('${r.front}  ›  ${r.phase}', style: const TextStyle(color: _D.muted, fontSize: 11)),
            const SizedBox(height: 3),
            Text(r.description, style: const TextStyle(color: _D.dim, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 7),
            Row(
              children: [
                _Avatar(name: r.responsible, color: accent),
                const SizedBox(width: 6),
                Expanded(child: Text(r.responsible, style: const TextStyle(color: _D.muted, fontSize: 11))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: _D.border, borderRadius: BorderRadius.circular(4)),
                  child: Text(r.area, style: const TextStyle(color: _D.steel, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Icon(r.isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 14, color: r.isSynced ? _D.green : _D.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.daysLeft, required this.r, required this.accent});
  final int daysLeft;
  final RestrictionRecord r;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (r.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: _D.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
        child: const Text('✓', style: TextStyle(color: _D.green, fontSize: 13, fontWeight: FontWeight.w800)),
      );
    }
    final label = r.isOverdue
        ? '↑ ${(-daysLeft)} d'
        : r.isDueToday
            ? 'HOY'
            : '$daysLeft d';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 11,
    backgroundColor: color.withValues(alpha: 0.2),
    child: Text(_initials(name), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

// ─── Radar CustomPainter ──────────────────────────────────────────────────────
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.pct,
    required this.compliance,
    required this.overdue,
    required this.today,
    required this.inProgress,
    required this.pending,
    required this.completed,
    required this.total,
  });

  final double pct;
  final double compliance;
  final int overdue, today, inProgress, pending, completed, total;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = math.min(cx, cy) - 20;

    // ── Grid rings ──
    final ringPaint = Paint()
      ..color = _D.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(Offset(cx, cy), R * f, ringPaint);
    }

    // ── Spokes (5 axes) ──
    final spokePaint = Paint()
      ..color = _D.border
      ..strokeWidth = 0.8;
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / 5) * i;
      canvas.drawLine(Offset(cx, cy), Offset(cx + R * math.cos(angle), cy + R * math.sin(angle)), spokePaint);
    }

    // ── Radar polygon (data) ──
    final maxVal = total > 0 ? total.toDouble() : 1.0;
    final vals = [
      overdue / maxVal,
      today / maxVal,
      inProgress / maxVal,
      pending / maxVal,
      completed / maxVal,
    ];
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / 5) * i;
      final r2 = R * vals[i] * pct;
      final x = cx + r2 * math.cos(angle);
      final y = cy + r2 * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, Paint()
      ..color = _D.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = _D.primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // ── Compliance arc (outer) ──
    final arcPaint = Paint()
      ..color = _D.hardhat
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final trackPaint = Paint()
      ..color = _D.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final arcR = R + 12;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * compliance * pct, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.pct != pct;
}
