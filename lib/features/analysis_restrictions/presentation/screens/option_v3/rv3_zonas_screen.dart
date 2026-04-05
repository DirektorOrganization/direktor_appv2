// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg      = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const stroke  = Color(0xFFE2EAF4);
  static const primary = Color(0xFF0A66B7);
  static const text    = Color(0xFF0F172A);
  static const muted   = Color(0xFF64748B);
  static const dim     = Color(0xFF94A3B8);
  static const red     = Color(0xFFEF4444);
  static const orange  = Color(0xFFF97316);
  static const yellow  = Color(0xFFF59E0B);
  static const green   = Color(0xFF10B981);
  static const blue    = Color(0xFF3B82F6);
  // area zone palette — construction sectors
  static final zoneColors = [
    const Color(0xFF0A66B7),
    const Color(0xFF7C3AED),
    const Color(0xFF059669),
    const Color(0xFFD97706),
    const Color(0xFFDC2626),
    const Color(0xFF0891B2),
    const Color(0xFF9333EA),
    const Color(0xFF16A34A),
  ];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Color _zoneColor(int index) => _D.zoneColors[index % _D.zoneColors.length];

Color _urgencyColor(RestrictionRecord r) {
  if (r.isOverdue) return _D.red;
  if (r.isDueToday) return _D.orange;
  if (r.isInProgress) return _D.yellow;
  if (r.isCompleted) return _D.green;
  return _D.blue;
}

String _initials(String name) {
  final p = name.trim().split(' ');
  if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
  return p[0].isNotEmpty ? p[0][0].toUpperCase() : '?';
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

// ─── Data structures ──────────────────────────────────────────────────────────
class _ZoneGroup {
  _ZoneGroup({required this.area, required this.items, required this.zoneIndex});
  final String area;
  final List<RestrictionRecord> items;
  final int zoneIndex;

  int get total => items.length;
  int get overdue => items.where((r) => r.isOverdue).length;
  int get completed => items.where((r) => r.isCompleted).length;
  double get compliance => total == 0 ? 0 : completed / total;
}

List<_ZoneGroup> _buildGroups(List<RestrictionRecord> all) {
  final map = <String, List<RestrictionRecord>>{};
  for (final r in all) {
    map.putIfAbsent(r.area, () => []).add(r);
  }
  final keys = map.keys.toList()..sort();
  return keys.indexed.map((e) => _ZoneGroup(area: e.$2, items: map[e.$2]!, zoneIndex: e.$1)).toList();
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv3ZonasScreen extends StatefulWidget {
  const Rv3ZonasScreen({super.key});

  @override
  State<Rv3ZonasScreen> createState() => _Rv3ZonasScreenState();
}

class _Rv3ZonasScreenState extends State<Rv3ZonasScreen> {
  final _expanded = <String>{};

  void _toggle(String area) => setState(() {
    _expanded.contains(area) ? _expanded.remove(area) : _expanded.add(area);
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final all = ctrl.restrictions;
        final summary = ctrl.restrictionSummary;
        final groups = _buildGroups(all);

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: _D.muted),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('POR ÁREA', style: TextStyle(color: _D.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                Text(ctrl.currentProject?.name ?? '—', style: const TextStyle(color: _D.text, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: _D.primary),
                onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: _D.stroke),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              // ── Zone tiles overview ──────────────────────────────────────
              SliverToBoxAdapter(child: _ZoneOverview(groups: groups, summary: summary)),
              // ── Section list ─────────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final g = groups[i];
                    final open = _expanded.contains(g.area);
                    return _ZoneSection(
                      group: g,
                      expanded: open,
                      onToggle: () => _toggle(g.area),
                    );
                  },
                  childCount: groups.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: _D.primary,
            foregroundColor: Colors.white,
            onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}

// ─── Zone overview grid ───────────────────────────────────────────────────────
class _ZoneOverview extends StatelessWidget {
  const _ZoneOverview({required this.groups, required this.summary});
  final List<_ZoneGroup> groups;
  final RestrictionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Expanded(child: Text('${groups.length} áreas · ${summary.total} restricciones', style: const TextStyle(color: _D.muted, fontSize: 12))),
              _CompliancePill(pct: summary.compliancePercent),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            itemCount: groups.length,
            itemBuilder: (_, i) => _ZoneTile(group: groups[i]),
          ),
        ),
        Divider(height: 1, color: _D.stroke),
      ],
    );
  }
}

class _CompliancePill extends StatelessWidget {
  const _CompliancePill({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _D.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _D.green.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified_outlined, size: 13, color: _D.green),
        const SizedBox(width: 4),
        Text('${pct.toStringAsFixed(0)}% cumpl.', style: const TextStyle(color: _D.green, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({required this.group});
  final _ZoneGroup group;

  @override
  Widget build(BuildContext context) {
    final color = _zoneColor(group.zoneIndex);
    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // mini compliance arc
          SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(painter: _MiniArcPainter(pct: group.compliance, color: color)),
          ),
          const Spacer(),
          Text(group.area, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
          Text('${group.total}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, height: 1.1)),
        ],
      ),
    );
  }
}

class _MiniArcPainter extends CustomPainter {
  const _MiniArcPainter({required this.pct, required this.color});
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false,
        Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 3);
    if (pct > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_MiniArcPainter old) => old.pct != pct;
}

// ─── Zone section (expandable) ────────────────────────────────────────────────
class _ZoneSection extends StatelessWidget {
  const _ZoneSection({required this.group, required this.expanded, required this.onToggle});
  final _ZoneGroup group;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = _zoneColor(group.zoneIndex);
    return Column(
      children: [
        // section header
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _D.surface,
            child: Row(
              children: [
                Container(width: 4, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.area, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${group.total} restricciones  ·  ${group.overdue > 0 ? "${group.overdue} vencidas  ·  " : ""}${(group.compliance * 100).toStringAsFixed(0)}% cumpl.',
                          style: const TextStyle(color: _D.muted, fontSize: 11)),
                    ],
                  ),
                ),
                // compliance bar
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(group.compliance * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: group.compliance,
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: _D.dim),
                ),
              ],
            ),
          ),
        ),
        // expanded cards
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: _D.bg,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: group.items.map((r) => _ZonaCard(r: r, zoneColor: color)).toList(),
            ),
          ),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        Divider(height: 1, color: _D.stroke),
      ],
    );
  }
}

// ─── Zona card ────────────────────────────────────────────────────────────────
class _ZonaCard extends StatelessWidget {
  const _ZonaCard({required this.r, required this.zoneColor});
  final RestrictionRecord r;
  final Color zoneColor;

  @override
  Widget build(BuildContext context) {
    final accent = _urgencyColor(r);
    final days = r.requiredDate.difference(DateTime.now()).inDays;
    final dayLabel = r.isCompleted ? '✓' : r.isOverdue ? '↑${-days}d' : r.isDueToday ? 'HOY' : '${days}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3), top: BorderSide(color: _D.stroke), right: BorderSide(color: _D.stroke), bottom: BorderSide(color: _D.stroke)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.activity, style: const TextStyle(color: _D.text, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${r.front} · ${r.phase}', style: const TextStyle(color: _D.muted, fontSize: 11)),
                const SizedBox(height: 3),
                Text(r.description, style: const TextStyle(color: _D.dim, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(radius: 9, backgroundColor: zoneColor.withValues(alpha: 0.15), child: Text(_initials(r.responsible), style: TextStyle(color: zoneColor, fontSize: 7, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 5),
                    Text(r.responsible, style: const TextStyle(color: _D.muted, fontSize: 10)),
                    const Spacer(),
                    Text(_fmtDate(r.requiredDate), style: const TextStyle(color: _D.dim, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(dayLabel, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
