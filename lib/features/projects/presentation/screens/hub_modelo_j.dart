// ============================================================
// MODELO J — "ATLAS"
// Panel ejecutivo con 4 arcos de progreso (fitness rings),
// feed de insights y navegación por módulos.
// Inspirado en Apple Health + Looker Studio Mobile.
// Visión completa del proyecto en una pantalla.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _J {
  static const bg       = Color(0xFF0A0E1A);
  static const surface  = Color(0xFF131929);
  static const surface2 = Color(0xFF1A2236);
  static const stroke   = Color(0xFF253047);
  static const textLight = Color(0xFFF0F5FF);
  static const muted    = Color(0xFF7B8EAB);
  static const blue     = Color(0xFF4B9EFF);
  static const teal     = Color(0xFF00D4AA);
  static const orange   = Color(0xFFFF9F2E);
  static const red      = Color(0xFFFF5C5C);
  static const yellow   = Color(0xFFFFBF47);
  static const purple   = Color(0xFFB47FFF);
}

// ── Data helpers ─────────────────────────────────────────────
class _Insight {
  const _Insight(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
}

// ── Screen ───────────────────────────────────────────────────
class HubModeloJ extends StatelessWidget {
  const HubModeloJ({super.key});

  static String _todayLabel() {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final mon = months[now.month - 1];
    return '$day $mon ${now.year}';
  }

  static String _relTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}m';
    return 'ahora';
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return Theme(
            data: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: _J.bg,
            ),
            child: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: _J.blue),
              ),
            ),
          );
        }

        final summary    = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones = controller.milestoneSummary;
        final sync       = controller.syncOverview;
        final projects   = controller.projects;

        final overdueCount = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        // ignore: unused_local_variable
        final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pendingCount    = restrictions.where((r) => r.isPending && !r.isOverdue).length;

        final compliance    = summary.compliancePercent / 100.0;
        final compliancePct = summary.compliancePercent.round();

        // Arc values
        final restrictionArcValue = compliance.clamp(0.0, 1.0);
        final hitosArcValue = milestones.delayedCount > 0
            ? 0.3
            : milestones.inProgressCount > 0
                ? 0.6
                : 1.0;
        final cumplimientoArcValue = compliance.clamp(0.0, 1.0);
        final penaltyTotal = milestones.accumulatedPenalty + milestones.potentialPenalty + 1;
        final penaltyArcValue = milestones.accumulatedPenalty > 0
            ? (milestones.accumulatedPenalty / penaltyTotal).clamp(0.0, 1.0)
            : 0.0;

        // Insights
        final List<_Insight> insights = [];
        if (overdueCount > 0) {
          insights.add(_Insight(Icons.warning_rounded,
              '$overdueCount restricciones vencidas', _J.red));
        }
        if (milestones.delayedCount > 0) {
          insights.add(_Insight(Icons.flag_rounded,
              '${milestones.delayedCount} hitos en riesgo', _J.yellow));
        }
        if (milestones.accumulatedPenalty > 0) {
          final amt = milestones.accumulatedPenalty.toStringAsFixed(0);
          insights.add(_Insight(Icons.payments_rounded,
              'Penalidad S/ $amt', _J.red));
        }
        if (compliance >= 0.8) {
          insights.add(_Insight(Icons.verified_rounded,
              'Objetivo de cumplimiento alcanzado', _J.teal));
        }
        if (compliance < 0.5) {
          insights.add(_Insight(Icons.trending_down_rounded,
              'Cumplimiento crítico — intervención requerida', _J.red));
        }
        if (insights.isEmpty) {
          insights.add(_Insight(Icons.check_circle_rounded,
              'Proyecto operando sin alertas críticas', _J.teal));
        }
        final topInsights = insights.take(4).toList();

        // Recent activity
        final completed3 = controller.completedRestrictions.take(3).toList();

        return Theme(
          data: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: _J.bg,
          ),
          child: Scaffold(
            backgroundColor: _J.bg,
            body: Column(
              children: [
                // ── Top Bar ──────────────────────────────────
                _AtlasTopBar(
                  projectName: project.name,
                  todayLabel: _todayLabel(),
                  onMenuSelected: (v) async {
                    if (v == 'logout') {
                      await controller.logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                          context, RouteNames.login, (_) => false);
                    } else if (v == 'profile') {
                      if (!context.mounted) return;
                      Navigator.pushNamed(context, RouteNames.profile);
                    } else if (v == 'projects') {
                      _showProjectSheet(context, projects, project,
                          (p) => controller.changeProject(p.id));
                    } else if (v == 'styles') {
                      if (!context.mounted) return;
                      await showStylePicker(context);
                    }
                  },
                ),
                // ── Scrollable body ───────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Four Arcs ─────────────────────────
                        Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _J.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'ESTADO DEL PROYECTO',
                                    style: TextStyle(
                                      color: _J.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _todayLabel(),
                                    style: const TextStyle(
                                        color: _J.muted, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Row 1
                              Row(
                                children: [
                                  _ArcCard(
                                    value: restrictionArcValue,
                                    label: 'cumplimiento',
                                    centerText: '$compliancePct%',
                                    color: _J.blue,
                                    track: _J.stroke,
                                  ),
                                  const SizedBox(width: 12),
                                  _ArcCard(
                                    value: hitosArcValue,
                                    label: 'hitos',
                                    centerText:
                                        '${milestones.inProgressCount}',
                                    color: _J.teal,
                                    track: _J.stroke,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Row 2
                              Row(
                                children: [
                                  _ArcCard(
                                    value: cumplimientoArcValue,
                                    label: 'objetivo',
                                    centerText:
                                        compliance >= 0.7 ? '✓' : '↓',
                                    color: compliance >= 0.7
                                        ? _J.teal
                                        : _J.red,
                                    track: _J.stroke,
                                  ),
                                  const SizedBox(width: 12),
                                  _ArcCard(
                                    value: penaltyArcValue,
                                    label: 'riesgo',
                                    centerText:
                                        milestones.accumulatedPenalty > 0
                                            ? '⚠'
                                            : 'OK',
                                    color: milestones.accumulatedPenalty > 0
                                        ? _J.red
                                        : _J.teal,
                                    track: _J.stroke,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── Insights Feed ─────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'INSIGHTS',
                                style: TextStyle(
                                  color: _J.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...topInsights.map(
                                  (i) => _InsightTile(insight: i)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Module Navigation ─────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'MÓDULOS',
                                style: TextStyle(
                                  color: _J.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _AtlasModuleBtn(
                                    label: 'Restricciones',
                                    icon: Icons.analytics_rounded,
                                    color: _J.blue,
                                    onTap: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.restrictionsList),
                                  ),
                                  const SizedBox(width: 10),
                                  _AtlasModuleBtn(
                                    label: 'Hitos',
                                    icon: Icons.flag_circle_rounded,
                                    color: _J.teal,
                                    onTap: () => Navigator.pushNamed(
                                        context, RouteNames.controlHitos),
                                  ),
                                  const SizedBox(width: 10),
                                  _AtlasModuleBtn(
                                    label: 'Actas',
                                    icon: Icons.groups_rounded,
                                    color: _J.orange,
                                    onTap: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.actaReuniones),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Recent Activity ───────────────────
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: _J.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _J.stroke),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'ACTIVIDAD',
                                    style: TextStyle(
                                      color: _J.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.completedRestrictions),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Ver →',
                                      style: TextStyle(
                                        color: _J.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (completed3.isEmpty)
                                const Text(
                                  'Sin actividad reciente.',
                                  style: TextStyle(
                                      color: _J.muted, fontSize: 11),
                                )
                              else
                                ...completed3.map((r) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: _J.teal,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              r.description,
                                              style: const TextStyle(
                                                color: _J.textLight,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            _relTime(r.updatedAt),
                                            style: const TextStyle(
                                              color: _J.muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Sync Row ──────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_sync_rounded,
                                  color: _J.muted, size: 13),
                              const SizedBox(width: 6),
                              Text(
                                sync.isOfflineEffective
                                    ? 'Sin conexión'
                                    : sync.lastSyncAt != null
                                        ? 'Sync ${_relTime(sync.lastSyncAt)}'
                                        : 'Sin sincronizar',
                                style: const TextStyle(
                                    color: _J.muted, fontSize: 10),
                              ),
                              const Spacer(),
                              if (pendingCount > 0 &&
                                  !sync.isOfflineEffective)
                                TextButton(
                                  onPressed: controller.syncNow,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'SYNC',
                                    style: TextStyle(
                                      color: _J.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProjectSheet(
    BuildContext context,
    List<ProjectRecord> projects,
    ProjectRecord current,
    void Function(ProjectRecord) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _J.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: projects
            .map((p) => ListTile(
                  title: Text(p.name,
                      style: const TextStyle(color: _J.textLight)),
                  trailing: p.id == current.id
                      ? const Icon(Icons.check, color: _J.teal, size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(p);
                  },
                ))
            .toList(),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────
class _AtlasTopBar extends StatelessWidget {
  const _AtlasTopBar({
    required this.projectName,
    required this.todayLabel,
    required this.onMenuSelected,
  });

  final String projectName;
  final String todayLabel;
  final void Function(String) onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: _J.surface,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const DirektorLogo(size: 28),
            const SizedBox(width: 8),
            const Text(
              'ATLAS',
              style: TextStyle(
                color: _J.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    projectName,
                    style: const TextStyle(
                      color: _J.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
                Text(
                  todayLabel,
                  style:
                      const TextStyle(color: _J.muted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              onSelected: onMenuSelected,
              color: _J.surface2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _J.stroke,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    color: _J.textLight, size: 16),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Mi perfil',
                      style: TextStyle(color: _J.textLight)),
                ),
                const PopupMenuItem(
                  value: 'projects',
                  child: Text('Proyectos',
                      style: TextStyle(color: _J.textLight)),
                ),
                PopupMenuItem(
                  value: 'styles',
                  child: Row(
                    children: const [
                      Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                      SizedBox(width: 8),
                      Text('Cambiar Estilo', style: TextStyle(color: _J.textLight)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar sesión',
                      style: TextStyle(color: _J.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Arc Card ─────────────────────────────────────────────────
class _ArcCard extends StatelessWidget {
  const _ArcCard({
    required this.value,
    required this.label,
    required this.centerText,
    required this.color,
    required this.track,
  });

  final double value;
  final String label;
  final String centerText;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _J.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _J.stroke),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(64, 64),
                    painter: _ArcPainter(
                      value: value,
                      color: color,
                      track: track,
                    ),
                  ),
                  Text(
                    centerText,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: _J.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.value,
    required this.color,
    required this.track,
  });

  final double value;
  final Color color;
  final Color track;

  static const strokeWidth = 8.0;
  static const startDeg = 150.0;
  static const sweepDeg = 240.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track (full arc)
    paint.color = track;
    canvas.drawArc(
      rect,
      startDeg * math.pi / 180,
      sweepDeg * math.pi / 180,
      false,
      paint,
    );

    // Progress arc
    if (value > 0) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDeg * math.pi / 180,
        sweepDeg * value.clamp(0.0, 1.0) * math.pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}

// ── Insight Tile ──────────────────────────────────────────────
class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _J.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _J.stroke),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, size: 16, color: insight.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.text,
              style: const TextStyle(
                color: _J.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Module Button ─────────────────────────────────────────────
class _AtlasModuleBtn extends StatelessWidget {
  const _AtlasModuleBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _J.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _J.stroke),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _J.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
