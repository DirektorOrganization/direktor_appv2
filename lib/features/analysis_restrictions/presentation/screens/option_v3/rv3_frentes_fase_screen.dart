// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg      = Color(0xFF0F1923);
  static const surface = Color(0xFF1A2535);
  static const card    = Color(0xFF212F42);
  static const border  = Color(0xFF2D3F56);
  static const text    = Color(0xFFE2E8F0);
  static const muted   = Color(0xFF64748B);
  static const dim     = Color(0xFF3D5166);
  static const primary = Color(0xFF3B82F6);
  static const red     = Color(0xFFEF4444);
  static const orange  = Color(0xFFF97316);
  static const yellow  = Color(0xFFF59E0B);
  static const green   = Color(0xFF10B981);
  static const blue    = Color(0xFF3B82F6);
  // front palette — construction phases tones
  static final frontColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
  ];
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Color _frontColor(int index) => _D.frontColors[index % _D.frontColors.length];

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

// ─── Data model ───────────────────────────────────────────────────────────────
class _PhaseGroup {
  _PhaseGroup({required this.phase, required this.items});
  final String phase;
  final List<RestrictionRecord> items;

  int get total => items.length;
  int get overdue => items.where((r) => r.isOverdue).length;
  int get completed => items.where((r) => r.isCompleted).length;
  double get compliance => total == 0 ? 0 : completed / total;
}

class _FrontGroup {
  _FrontGroup({required this.front, required this.phases, required this.frontIndex});
  final String front;
  final List<_PhaseGroup> phases;
  final int frontIndex;

  int get total => phases.fold(0, (s, p) => s + p.total);
  int get overdue => phases.fold(0, (s, p) => s + p.overdue);
  int get completed => phases.fold(0, (s, p) => s + p.completed);
  double get compliance => total == 0 ? 0 : completed / total;
}

List<_FrontGroup> _buildGroups(List<RestrictionRecord> all) {
  final byFront = <String, Map<String, List<RestrictionRecord>>>{};
  for (final r in all) {
    byFront.putIfAbsent(r.front, () => {}).putIfAbsent(r.phase, () => []).add(r);
  }
  final fronts = byFront.keys.toList()..sort();
  return fronts.indexed.map((e) {
    final phases = byFront[e.$2]!;
    final phaseList = (phases.keys.toList()..sort()).map((ph) => _PhaseGroup(phase: ph, items: phases[ph]!)).toList();
    return _FrontGroup(front: e.$2, phases: phaseList, frontIndex: e.$1);
  }).toList();
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Rv3FrentesFaseScreen extends StatefulWidget {
  const Rv3FrentesFaseScreen({super.key});

  @override
  State<Rv3FrentesFaseScreen> createState() => _Rv3FrentesFaseScreenState();
}

class _Rv3FrentesFaseScreenState extends State<Rv3FrentesFaseScreen> {
  final _expandedFronts = <String>{};
  final _expandedPhases = <String>{};

  String _phaseKey(String front, String phase) => '$front|$phase';

  void _toggleFront(String front) => setState(() {
    _expandedFronts.contains(front) ? _expandedFronts.remove(front) : _expandedFronts.add(front);
  });

  void _togglePhase(String front, String phase) {
    final key = _phaseKey(front, phase);
    setState(() {
      _expandedPhases.contains(key) ? _expandedPhases.remove(key) : _expandedPhases.add(key);
    });
  }

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
            backgroundColor: _D.bg,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: _D.muted),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FRENTE › FASE', style: TextStyle(color: _D.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
                Text(ctrl.currentProject?.name ?? '—', style: const TextStyle(color: _D.text, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: _D.primary),
                onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // ── Global summary bar ───────────────────────────────────────
              SliverToBoxAdapter(child: _GlobalBar(summary: summary, groups: groups)),
              // ── Front groups ─────────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final g = groups[i];
                    return _FrontSection(
                      group: g,
                      expandedFront: _expandedFronts.contains(g.front),
                      onToggleFront: () => _toggleFront(g.front),
                      expandedPhases: _expandedPhases,
                      onTogglePhase: (ph) => _togglePhase(g.front, ph),
                      phaseKey: (ph) => _phaseKey(g.front, ph),
                    );
                  },
                  childCount: groups.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: _D.primary,
            foregroundColor: _D.text,
            onPressed: () => Navigator.of(ctx).pushNamed(RouteNames.restrictionCreate),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}

// ─── Global summary bar ───────────────────────────────────────────────────────
class _GlobalBar extends StatelessWidget {
  const _GlobalBar({required this.summary, required this.groups});
  final RestrictionSummary summary;
  final List<_FrontGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _D.border),
      ),
      child: Row(
        children: [
          // compliance ring
          SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(
              painter: _RingPainter(pct: summary.compliancePercent / 100, color: _D.green),
              child: Center(
                child: Text('${summary.compliancePercent.toStringAsFixed(0)}%',
                    style: const TextStyle(color: _D.green, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${groups.length} frentes  ·  ${summary.total} restricciones', style: const TextStyle(color: _D.text, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Pill(label: '${summary.overdue}', sub: 'VENC', color: _D.red),
                    const SizedBox(width: 6),
                    _Pill(label: '${summary.inProgress}', sub: 'EN PROC', color: _D.yellow),
                    const SizedBox(width: 6),
                    _Pill(label: '${summary.pending}', sub: 'PEND', color: _D.blue),
                    const SizedBox(width: 6),
                    _Pill(label: '${summary.completed}', sub: 'CIERRE', color: _D.green),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.sub, required this.color});
  final String label, sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(sub, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9)),
      ],
    ),
  );
}

// ─── Front section ────────────────────────────────────────────────────────────
class _FrontSection extends StatelessWidget {
  const _FrontSection({
    required this.group,
    required this.expandedFront,
    required this.onToggleFront,
    required this.expandedPhases,
    required this.onTogglePhase,
    required this.phaseKey,
  });
  final _FrontGroup group;
  final bool expandedFront;
  final VoidCallback onToggleFront;
  final Set<String> expandedPhases;
  final void Function(String phase) onTogglePhase;
  final String Function(String phase) phaseKey;

  @override
  Widget build(BuildContext context) {
    final color = _frontColor(group.frontIndex);
    return Column(
      children: [
        // front header
        InkWell(
          onTap: onToggleFront,
          child: Container(
            color: _D.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text('F${group.frontIndex + 1}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.front, style: const TextStyle(color: _D.text, fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${group.phases.length} fases  ·  ${group.total} restricciones${group.overdue > 0 ? "  ·  ${group.overdue} venc." : ""}',
                          style: const TextStyle(color: _D.muted, fontSize: 11)),
                    ],
                  ),
                ),
                // compliance bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(group.compliance * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: group.compliance,
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  turns: expandedFront ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: _D.muted, size: 20),
                ),
              ],
            ),
          ),
        ),
        // phase sub-groups
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: _D.bg,
            child: Column(
              children: group.phases.map((ph) {
                final key = phaseKey(ph.phase);
                return _PhaseSection(
                  phaseGroup: ph,
                  frontColor: color,
                  expanded: expandedPhases.contains(key),
                  onToggle: () => onTogglePhase(ph.phase),
                );
              }).toList(),
            ),
          ),
          crossFadeState: expandedFront ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        Divider(height: 1, color: _D.border),
      ],
    );
  }
}

// ─── Phase sub-section ────────────────────────────────────────────────────────
class _PhaseSection extends StatelessWidget {
  const _PhaseSection({required this.phaseGroup, required this.frontColor, required this.expanded, required this.onToggle});
  final _PhaseGroup phaseGroup;
  final Color frontColor;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.fromLTRB(32, 10, 16, 10),
            color: _D.surface.withValues(alpha: 0.5),
            child: Row(
              children: [
                Container(width: 2, height: 24, color: frontColor.withValues(alpha: 0.4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(phaseGroup.phase, style: const TextStyle(color: _D.text, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Text('${phaseGroup.total}', style: TextStyle(color: frontColor, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (phaseGroup.overdue > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: _D.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                    child: Text('${phaseGroup.overdue} venc.', style: const TextStyle(color: _D.red, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: _D.muted, size: 18),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 12, 8),
            child: Column(
              children: phaseGroup.items.map((r) => _FrenteCard(r: r, frontColor: frontColor)).toList(),
            ),
          ),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
        Divider(height: 1, color: _D.border.withValues(alpha: 0.5)),
      ],
    );
  }
}

// ─── Restriction card ─────────────────────────────────────────────────────────
class _FrenteCard extends StatelessWidget {
  const _FrenteCard({required this.r, required this.frontColor});
  final RestrictionRecord r;
  final Color frontColor;

  @override
  Widget build(BuildContext context) {
    final accent = _urgencyColor(r);
    final days = r.requiredDate.difference(DateTime.now()).inDays;
    final dayLabel = r.isCompleted ? '✓' : r.isOverdue ? '↑${-days}d' : r.isDueToday ? 'HOY' : '${days}d';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _D.card,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accent, width: 3)),
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
                Text(r.area, style: const TextStyle(color: _D.muted, fontSize: 10)),
                const SizedBox(height: 3),
                Text(r.description, style: const TextStyle(color: _D.dim, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(radius: 9, backgroundColor: frontColor.withValues(alpha: 0.18), child: Text(_initials(r.responsible), style: TextStyle(color: frontColor, fontSize: 7, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 5),
                    Expanded(child: Text(r.responsible, style: const TextStyle(color: _D.muted, fontSize: 10), overflow: TextOverflow.ellipsis)),
                    Icon(r.isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 12, color: r.isSynced ? _D.green : _D.muted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(dayLabel, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.pct, required this.color});
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, 0, 2 * math.pi, false,
        Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 4);
    if (pct > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * pct, false,
          Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.pct != pct;
}
