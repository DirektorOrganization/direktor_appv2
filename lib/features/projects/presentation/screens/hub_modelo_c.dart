// ============================================================
// MODELO C — "BREEZE"
// Minimalista y limpio. AppBar fija con logo + chips de
// proyecto scrollable. Secciones compactas con dividers,
// métricas inline y accesos rápidos naranja. Máximo
// contenido en menos espacio. Estilo: Notion / Linear.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

class HubModeloC extends StatelessWidget {
  const HubModeloC({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        final project = controller.currentProject;
        if (project == null || user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final summary = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones = controller.milestoneSummary;
        final sync = controller.syncOverview;
        final overdueCount = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final completed3 = controller.completedRestrictions.take(3).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _BreezeAppBar(
            user: user,
            sync: sync,
            onMenuSelected: (v) async {
              if (v == 'logout') {
                await controller.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
              } else if (v == 'profile') {
                if (!context.mounted) return;
                Navigator.pushNamed(context, RouteNames.profile);
              } else if (v == 'styles') {
                if (!context.mounted) return;
                await showStylePicker(context);
              }
            },
          ),
          body: Column(
            children: [
              // ── Project pill selector ─────────────────────
              _ProjectPillBar(
                projects: controller.projects,
                current: project,
                onSelect: controller.changeProject,
              ),
              const Divider(height: 1, color: Color(0xFFECF0F5)),
              // ── Content ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                        child: Text(
                          'Resumen de ${project.name}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E2B3A)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Text(
                          project.roleLabel,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF62748A), fontWeight: FontWeight.w500),
                        ),
                      ),
                      // Quick stats strip
                      _QuickStatsStrip(
                        compliance: summary.compliancePercent,
                        overdue: overdueCount,
                        inProgress: inProgressCount,
                        completed: summary.completed,
                      ),
                      const SizedBox(height: 12),
                      // ── Gráfico gerencial ──────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _BreezeChartCard(
                          compliance: summary.compliancePercent,
                          overdue: overdueCount,
                          inProgress: inProgressCount,
                          pending: summary.pending,
                          completed: summary.completed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFECF0F5)),
                      // Modules
                      _BreezeSection(
                        label: 'Análisis de restricciones',
                        icon: Icons.analytics_rounded,
                        iconColor: AppTheme.brandBlue,
                        rows: [
                          _BreezeRow('Cumplimiento', '${(summary.compliancePercent * 100).round()}%', const Color(0xFF1B8E5A)),
                          _BreezeRow('Retrasadas', '$overdueCount', const Color(0xFFD64545)),
                          _BreezeRow('En proceso', '$inProgressCount', const Color(0xFFE4A620)),
                          _BreezeRow('Pendientes', '${summary.pending}', const Color(0xFF62748A)),
                        ],
                        progress: summary.compliancePercent,
                        progressColor: const Color(0xFF1B8E5A),
                        ctaLabel: 'Ver análisis →',
                        onCta: () => Navigator.pushNamed(context, RouteNames.restrictionsList),
                      ),
                      const Divider(height: 1, color: Color(0xFFECF0F5)),
                      _BreezeSection(
                        label: 'Control de hitos',
                        icon: Icons.flag_circle_rounded,
                        iconColor: const Color(0xFF0F7AD8),
                        rows: [
                          _BreezeRow('En progreso', '${milestones.inProgressCount}', const Color(0xFFE4A620)),
                          _BreezeRow('Vencidos', '${milestones.delayedCount}', const Color(0xFFD64545)),
                          _BreezeRow('Penalidad', 'S/ ${milestones.accumulatedPenalty.toStringAsFixed(0)}', const Color(0xFFD64545)),
                          _BreezeRow('Ampliaciones', '${milestones.activeExtensions}', AppTheme.brandBlue),
                        ],
                        ctaLabel: 'Ver hitos →',
                        onCta: () => Navigator.pushNamed(context, RouteNames.controlHitos),
                      ),
                      const Divider(height: 1, color: Color(0xFFECF0F5)),
                      _BreezeSection(
                        label: 'Acta de reuniones',
                        icon: Icons.groups_rounded,
                        iconColor: AppTheme.brandOrange,
                        rows: [
                          _BreezeRow('Panel ejecutivo', 'Option 9', AppTheme.brandOrange),
                          _BreezeRow('Sesión activa', '—', const Color(0xFF1B8E5A)),
                          _BreezeRow('Acuerdos vencidos', '—', const Color(0xFFD64545)),
                        ],
                        ctaLabel: 'Abrir actas →',
                        onCta: () => Navigator.pushNamed(context, RouteNames.actaReuniones),
                      ),
                      const Divider(height: 1, color: Color(0xFFECF0F5)),
                      // Recent closures
                      _BreezeClosure(items: completed3),
                      const Divider(height: 1, color: Color(0xFFECF0F5)),
                      // Sync footer
                      _BreezeSyncFooter(sync: sync, isBusy: controller.isBusy, onSync: controller.syncNow),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────
class _BreezeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BreezeAppBar({
    required this.user,
    required this.sync,
    required this.onMenuSelected,
  });

  final UserProfile user;
  final SyncOverview sync;
  final ValueChanged<String> onMenuSelected;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final offline = sync.isOfflineEffective;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        height: preferredSize.height + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const DirektorLogo(size: 28),
              const SizedBox(width: 10),
              const Text(
                'DIREKTOR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0A66B7), letterSpacing: 1.0),
              ),
              const Spacer(),
              if (offline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD64545).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('OFFLINE', style: TextStyle(color: Color(0xFFD64545), fontSize: 10, fontWeight: FontWeight.w800)),
                )
              else if (sync.pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4A620).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${sync.pendingCount} pend.', style: const TextStyle(color: Color(0xFFE4A620), fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: onMenuSelected,
                tooltip: user.name,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.brandBlue.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.brandBlue),
                        ),
                      ),
                    ),
                  ],
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  PopupMenuItem(
                    value: 'styles',
                    child: Row(
                      children: const [
                        Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                        SizedBox(width: 8),
                        Text('Cambiar Estilo'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Project pill bar ──────────────────────────────────────────
class _ProjectPillBar extends StatelessWidget {
  const _ProjectPillBar({required this.projects, required this.current, required this.onSelect});
  final List<ProjectRecord> projects;
  final ProjectRecord current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: projects.map((p) {
          final selected = p.id == current.id;
          return GestureDetector(
            onTap: () => onSelect(p.id),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppTheme.brandBlue : const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.brandBlue : const Color(0xFFD9E3F0),
                ),
              ),
              child: Text(
                p.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF62748A),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Quick stats strip ─────────────────────────────────────────
class _QuickStatsStrip extends StatelessWidget {
  const _QuickStatsStrip({
    required this.compliance,
    required this.overdue,
    required this.inProgress,
    required this.completed,
  });

  final double compliance;
  final int overdue;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFD),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _StatCell('${(compliance * 100).round()}%', 'Cumplim.', const Color(0xFF1B8E5A)),
          _vDivider(),
          _StatCell('$overdue', 'Retraso', const Color(0xFFD64545)),
          _vDivider(),
          _StatCell('$inProgress', 'Proceso', const Color(0xFFE4A620)),
          _vDivider(),
          _StatCell('$completed', 'Cerradas', const Color(0xFF1B8E5A)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: const Color(0xFFD9E3F0), margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1.1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF62748A))),
        ],
      ),
    );
  }
}

// ── Breeze section ────────────────────────────────────────────
class _BreezeRow {
  const _BreezeRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _BreezeSection extends StatelessWidget {
  const _BreezeSection({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.rows,
    required this.ctaLabel,
    required this.onCta,
    this.progress,
    this.progressColor,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final List<_BreezeRow> rows;
  final String ctaLabel;
  final VoidCallback onCta;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E2B3A))),
              ),
              GestureDetector(
                onTap: onCta,
                child: Text(ctaLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandOrange)),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFECF0F5),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? iconColor),
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  child: Text(r.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF62748A))),
                ),
                Text(r.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: r.color)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Closures ──────────────────────────────────────────────────
class _BreezeClosure extends StatelessWidget {
  const _BreezeClosure({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1B8E5A), size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text('Últimos cierres', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E2B3A)))),
              GestureDetector(
                onTap: () {},
                child: Text('Ver todos →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandOrange)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('Sin cierres recientes.', style: TextStyle(color: Color(0xFF62748A), fontSize: 12))
          else
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  const Icon(Icons.check_rounded, size: 12, color: Color(0xFF1B8E5A)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.activity, style: const TextStyle(fontSize: 12, color: Color(0xFF1E2B3A), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  Text(_rel(item.updatedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF62748A))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _rel(DateTime v) {
    final d = DateTime.now().difference(v).inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${v.day}/${v.month}';
  }
}

// ── Sync footer ───────────────────────────────────────────────
class _BreezeSyncFooter extends StatelessWidget {
  const _BreezeSyncFooter({required this.sync, required this.isBusy, required this.onSync});
  final SyncOverview sync;
  final bool isBusy;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final offline = sync.isOfflineEffective;
    final color = offline ? const Color(0xFFD64545) : const Color(0xFF62748A);
    final canSync = !isBusy && !sync.isSyncing && !offline && sync.remoteSyncEnabled && sync.apiConfigured && sync.pendingCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Icon(offline ? Icons.wifi_off_rounded : Icons.cloud_sync_rounded, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              offline
                  ? 'Sin conexión – datos guardados localmente'
                  : sync.lastSyncAt != null
                      ? 'Última sync: ${sync.lastSyncAt!.hour.toString().padLeft(2, '0')}:${sync.lastSyncAt!.minute.toString().padLeft(2, '0')} · ${sync.pendingCount} pendientes'
                      : '${sync.pendingCount} pendientes',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ),
          if (!offline && canSync)
            TextButton(
              onPressed: onSync,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandBlue,
                minimumSize: const Size(60, 28),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: sync.isSyncing
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sincronizar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

// ── Chart card con donut + barra de estado ────────────────────
class _BreezeChartCard extends StatelessWidget {
  const _BreezeChartCard({
    required this.compliance,
    required this.overdue,
    required this.inProgress,
    required this.pending,
    required this.completed,
  });

  final double compliance;
  final int overdue;
  final int inProgress;
  final int pending;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final total = overdue + inProgress + pending + completed;
    final ringColor = compliance >= 0.7
        ? const Color(0xFF1B8E5A)
        : compliance >= 0.4
            ? const Color(0xFFE4A620)
            : const Color(0xFFD64545);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista gerencial',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E2B3A)),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut ring
              _BreezeRingChart(
                value: compliance,
                color: ringColor,
                size: 90,
                strokeWidth: 12,
                centerLabel: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(compliance * 100).round()}%',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ringColor, height: 1.0),
                    ),
                    const Text('cumpl.', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF62748A))),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChartLegendRow('Retrasadas', overdue, const Color(0xFFD64545)),
                    const SizedBox(height: 6),
                    _ChartLegendRow('En proceso', inProgress, const Color(0xFFE4A620)),
                    const SizedBox(height: 6),
                    _ChartLegendRow('Pendientes', pending, const Color(0xFFB0BAC8)),
                    const SizedBox(height: 6),
                    _ChartLegendRow('Finalizadas', completed, const Color(0xFF1B8E5A)),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            const Text('Distribución por estado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF62748A))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: CustomPaint(
                size: const Size(double.infinity, 10),
                painter: _SegBarPainter(
                  segments: [
                    _Seg(overdue, const Color(0xFFD64545)),
                    _Seg(inProgress, const Color(0xFFE4A620)),
                    _Seg(pending, const Color(0xFFD0D8E4)),
                    _Seg(completed, const Color(0xFF1B8E5A)),
                  ],
                  total: total,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartLegendRow extends StatelessWidget {
  const _ChartLegendRow(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF62748A)))),
        Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

// ── Donut ring chart ──────────────────────────────────────────
class _BreezeRingChart extends StatelessWidget {
  const _BreezeRingChart({
    required this.value,
    required this.color,
    required this.size,
    required this.strokeWidth,
    required this.centerLabel,
  });

  final double value;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget centerLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainterC(
              value: value.clamp(0.0, 1.0),
              color: color,
              track: const Color(0xFFECF0F5),
              strokeWidth: strokeWidth,
            ),
          ),
          centerLabel,
        ],
      ),
    );
  }
}

class _RingPainterC extends CustomPainter {
  const _RingPainterC({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = track;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainterC old) =>
      old.value != value || old.color != color;
}

// ── Segmented horizontal bar ──────────────────────────────────
class _Seg {
  const _Seg(this.count, this.color);
  final int count;
  final Color color;
}

class _SegBarPainter extends CustomPainter {
  const _SegBarPainter({required this.segments, required this.total});
  final List<_Seg> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    double x = 0;
    for (final seg in segments) {
      if (seg.count == 0) continue;
      final w = size.width * seg.count / total;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), Paint()..color = seg.color);
      x += w;
    }
  }

  @override
  bool shouldRepaint(_SegBarPainter old) => old.total != total;
}
