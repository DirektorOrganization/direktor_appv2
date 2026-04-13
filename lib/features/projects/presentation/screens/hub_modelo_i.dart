// ============================================================
// MODELO I — "PULSE"
// Híbrido gerencial-operativo.
// Top: métricas clave con donut grande + números.
// Bottom: acceso rápido por módulo con swipe horizontal.
// Inspirado en Amplitude mobile + Datadog Mobile.
// El "puente" entre el gerente y el operativo.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/core/app_clock.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ───────────────────────────────────────────────────
abstract final class _I {
  static const navyDark = Color(0xFF0B1A2E);
  static const navy = Color(0xFF0F2744);
  static const navyLight = Color(0xFF1A3A5C);
  static const bg = Color(0xFFF3F7FC);
  static const surface = Colors.white;
  static const stroke = Color(0xFFDDE5F0);
  static const textLight = Color(0xFFF0F6FF);
  static const muted = Color(0xFF6B8099);
  static const blue = Color(0xFF1A6FE8);
  static const teal = Color(0xFF00C49A);
  static const red = Color(0xFFE04040);
  static const yellow = Color(0xFFE5A020);
  static const green = Color(0xFF1A8C5A);
  static const orange = Color(0xFFF57C20);
}

// ── Root Widget ───────────────────────────────────────────────
class HubModeloI extends StatefulWidget {
  const HubModeloI({super.key});

  @override
  State<HubModeloI> createState() => _HubModeloIState();
}

class _HubModeloIState extends State<HubModeloI> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Relative date helper ──────────────────────────────────
  String _rel(DateTime v) {
    final now = AppClock.nowInDefaultZone();
    final dv = AppClock.toDefaultZone(v);
    final d = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dv.year, dv.month, dv.day))
        .inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${dv.day}/${dv.month}';
  }

  // ── Alert text helper ────────────────────────────────────
  String _alertText(int overdue, int delayed) {
    if (overdue > 0 && delayed > 0) {
      return '$overdue restricciones y $delayed hitos requieren atención inmediata';
    } else if (overdue > 0) {
      return '$overdue restricciones vencidas pendientes de cierre';
    } else {
      return '$delayed hitos en riesgo de penalidad contractual';
    }
  }

  // ── Project picker bottom sheet ───────────────────────────
  void _showProjectPicker(
    BuildContext context,
    List<ProjectRecord> projects,
    dynamic controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _I.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Cambiar proyecto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2B3A),
                  ),
                ),
              ),
              const Divider(height: 1, color: _I.stroke),
              ...projects.map(
                (p) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _I.blue.withValues(alpha: 0.10),
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _I.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2B3A),
                    ),
                  ),
                  subtitle: Text(
                    p.company,
                    style: const TextStyle(fontSize: 11, color: _I.muted),
                  ),
                  trailing: p.isLastSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: _I.green,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.changeProject(p.id);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return const Scaffold(
            backgroundColor: _I.bg,
            body: Center(
              child: CircularProgressIndicator(color: _I.blue),
            ),
          );
        }

        final summary = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones = controller.milestoneSummary;
        final sync = controller.syncOverview;
        final projects = controller.projects;
        final completed3 =
            controller.completedRestrictions.take(3).toList();

        final overdueCount =
            restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount =
            restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pendingCount =
            restrictions.where((r) => r.isPending && !r.isOverdue).length;
        final compliancePct = summary.compliancePercent;
        final compliance = (compliancePct / 100).clamp(0.0, 1.0);
        final pct = compliancePct.toStringAsFixed(0);
        final ringColor = compliance >= 0.7
            ? _I.teal
            : compliance >= 0.4
                ? _I.yellow
                : _I.red;

        final isOffline = sync.isOfflineEffective;

        return Scaffold(
          backgroundColor: _I.bg,
          body: Column(
            children: [
              // ── Top Half ──────────────────────────────────
              _TopHalf(
                project: project,
                user: user,
                projects: projects,
                compliance: compliance,
                pct: pct,
                ringColor: ringColor,
                overdueCount: overdueCount,
                inProgressCount: inProgressCount,
                milestones: milestones,
                isOffline: isOffline,
                alertText: (overdueCount > 0 || milestones.delayedCount > 0)
                    ? _alertText(overdueCount, milestones.delayedCount)
                    : null,
                onProjectTap: () =>
                    _showProjectPicker(context, projects, controller),
                onLogout: () async {
                  await controller.logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.login,
                    (_) => false,
                  );
                },
                onProfile: () =>
                    Navigator.pushNamed(context, RouteNames.profile),
              ),

              // ── Bottom Half ───────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    // Section label row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: [
                          const Text(
                            'MÓDULOS',
                            style: TextStyle(
                              color: _I.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          _PageDots(
                            current: _currentPage,
                            count: 3,
                          ),
                        ],
                      ),
                    ),

                    // PageView of 3 module cards
                    SizedBox(
                      height: 200,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _currentPage = i),
                        children: [
                          _ModulePageCard(
                            title: 'RESTRICCIONES',
                            icon: Icons.analytics_rounded,
                            accentColor: _I.blue,
                            stats: [
                              _ModuleStat(
                                'Cumplimiento',
                                '$pct%',
                                compliance >= 0.7 ? _I.teal : _I.yellow,
                              ),
                              _ModuleStat(
                                'Vencidas',
                                '$overdueCount',
                                overdueCount > 0 ? _I.red : _I.teal,
                              ),
                              _ModuleStat(
                                'En proceso',
                                '$inProgressCount',
                                _I.yellow,
                              ),
                              _ModuleStat(
                                'Pendientes',
                                '$pendingCount',
                                _I.muted,
                              ),
                            ],
                            ctaLabel: 'Abrir módulo',
                            onCta: () => Navigator.pushNamed(
                              context,
                              RouteNames.restrictionsList,
                            ),
                          ),
                          _ModulePageCard(
                            title: 'CONTROL DE HITOS',
                            icon: Icons.flag_circle_rounded,
                            accentColor: _I.teal,
                            stats: [
                              _ModuleStat(
                                'En progreso',
                                '${milestones.inProgressCount}',
                                _I.yellow,
                              ),
                              _ModuleStat(
                                'Vencidos',
                                '${milestones.delayedCount}',
                                milestones.delayedCount > 0
                                    ? _I.red
                                    : _I.teal,
                              ),
                              _ModuleStat(
                                'Penalidad',
                                'S/ ${milestones.accumulatedPenalty.toStringAsFixed(0)}',
                                _I.red,
                              ),
                              _ModuleStat(
                                'Ampliaciones',
                                '${milestones.activeExtensions}',
                                _I.blue,
                              ),
                            ],
                            ctaLabel: 'Ver hitos',
                            onCta: () => Navigator.pushNamed(
                              context,
                              RouteNames.controlHitos,
                            ),
                          ),
                          _ModulePageCard(
                            title: 'ACTA DE REUNIONES',
                            icon: Icons.groups_rounded,
                            accentColor: _I.orange,
                            stats: const [
                              _ModuleStat('Panel', 'Option 9', _I.orange),
                              _ModuleStat('Sesión activa', '—', _I.teal),
                              _ModuleStat('Vencidos', '—', _I.red),
                            ],
                            ctaLabel: 'Abrir actas',
                            onCta: () => Navigator.pushNamed(
                              context,
                              RouteNames.actaReuniones,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recent closures + sync
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent header
                            Row(
                              children: [
                                const Text(
                                  'ÚLTIMAS CERRADAS',
                                  style: TextStyle(
                                    color: _I.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    RouteNames.completedRestrictions,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _I.blue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Ver →',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _I.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Recent closures list
                            Container(
                              decoration: BoxDecoration(
                                color: _I.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _I.stroke),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: completed3.isEmpty
                                    ? [
                                        const Text(
                                          'Sin cierres recientes.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _I.muted,
                                          ),
                                        ),
                                      ]
                                    : completed3
                                        .map(
                                          (item) => Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    bottom: 8),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .check_circle_rounded,
                                                  color: _I.green,
                                                  size: 13,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item.activity,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Color(0xFF1E2B3A),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _rel(item.updatedAt),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: _I.muted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Sync row
                            _PulseSyncRow(
                              sync: sync,
                              isBusy: controller.isBusy,
                              onSync: controller.syncNow,
                              pendingCount: pendingCount,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Top Half ───────────────────────────────────────────────────
class _TopHalf extends StatelessWidget {
  const _TopHalf({
    required this.project,
    required this.user,
    required this.projects,
    required this.compliance,
    required this.pct,
    required this.ringColor,
    required this.overdueCount,
    required this.inProgressCount,
    required this.milestones,
    required this.isOffline,
    required this.alertText,
    required this.onProjectTap,
    required this.onLogout,
    required this.onProfile,
  });

  final ProjectRecord project;
  final UserProfile user;
  final List<ProjectRecord> projects;
  final double compliance;
  final String pct;
  final Color ringColor;
  final int overdueCount;
  final int inProgressCount;
  final MilestoneDashboardSummary milestones;
  final bool isOffline;
  final String? alertText;
  final VoidCallback onProjectTap;
  final VoidCallback onLogout;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_I.navyDark, _I.navy, _I.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: const DirektorLogo(size: 32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onProjectTap,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PULSE',
                            style: TextStyle(
                              color: _I.textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  project.name,
                                  style: const TextStyle(
                                    color: _I.textLight,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.expand_more_rounded,
                                color: _I.textLight.withValues(alpha: 0.6),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Connectivity pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOffline
                              ? Icons.wifi_off_rounded
                              : Icons.cloud_done_rounded,
                          color: _I.textLight.withValues(alpha: 0.80),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOffline ? 'Offline' : 'Online',
                          style: TextStyle(
                            color: _I.textLight.withValues(alpha: 0.80),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // User popup
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'logout') {
                        onLogout();
                      } else if (v == 'profile') {
                        onProfile();
                      } else if (v == 'styles') {
                        await showStylePicker(context);
                      }
                    },
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'profile',
                        child: Row(
                          children: const [
                            Icon(Icons.person_rounded,
                                size: 16, color: _I.muted),
                            SizedBox(width: 10),
                            Text(
                              'Mi perfil',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E2B3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'styles',
                        child: Row(
                          children: const [
                            Icon(Icons.palette_rounded,
                                size: 16, color: Color(0xFFE8941A)),
                            SizedBox(width: 10),
                            Text(
                              'Cambiar Estilo',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E2B3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: const [
                            Icon(Icons.logout_rounded,
                                size: 16, color: _I.red),
                            SizedBox(width: 10),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _I.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_outline,
                        color: _I.textLight,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Main metric display — Donut + 3 side KPIs
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Big donut ring
                  _PulseRing(
                    value: compliance,
                    size: 120,
                    strokeWidth: 16,
                    color: ringColor,
                    centerWidget: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            color: _I.textLight,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'cumpl.',
                          style: TextStyle(
                            color: _I.textLight.withValues(alpha: 0.60),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // 3 side KPIs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PulseKpi(
                          label: 'Retrasadas',
                          value: '$overdueCount',
                          color: overdueCount > 0 ? _I.red : _I.teal,
                          icon: Icons.warning_rounded,
                        ),
                        const SizedBox(height: 10),
                        _PulseKpi(
                          label: 'En proceso',
                          value: '$inProgressCount',
                          color: _I.yellow,
                          icon: Icons.timelapse_rounded,
                        ),
                        const SizedBox(height: 10),
                        _PulseKpi(
                          label: 'Hitos vencidos',
                          value: '${milestones.delayedCount}',
                          color: milestones.delayedCount > 0
                              ? _I.red
                              : _I.teal,
                          icon: Icons.flag_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Alert strip
              if (alertText != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: _I.yellow,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alertText!,
                          style: TextStyle(
                            color: _I.textLight.withValues(alpha: 0.80),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pulse Ring ────────────────────────────────────────────────
class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.value,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.centerWidget,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Widget centerWidget;

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
            painter: _PulseRingPainter(
              value: value,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
          centerWidget,
        ],
      ),
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  const _PulseRingPainter({
    required this.value,
    required this.color,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_PulseRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

// ── Pulse KPI ─────────────────────────────────────────────────
class _PulseKpi extends StatelessWidget {
  const _PulseKpi({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _I.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: _I.textLight.withValues(alpha: 0.60),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Module Page Card ──────────────────────────────────────────
class _ModulePageCard extends StatelessWidget {
  const _ModulePageCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.stats,
    required this.ctaLabel,
    required this.onCta,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_ModuleStat> stats;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _I.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _I.stroke),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats wrap
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: stats.map((s) => _StatChip(stat: s)).toList(),
          ),

          const Spacer(),

          // CTA button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat});

  final _ModuleStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.label,
            style: const TextStyle(
              color: _I.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page Dots ─────────────────────────────────────────────────
class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 7 : 5,
          height: isActive ? 7 : 5,
          decoration: BoxDecoration(
            color: isActive ? _I.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            border: isActive
                ? null
                : Border.all(color: _I.stroke, width: 1.5),
          ),
        );
      }),
    );
  }
}

// ── Pulse Sync Row ────────────────────────────────────────────
class _PulseSyncRow extends StatelessWidget {
  const _PulseSyncRow({
    required this.sync,
    required this.isBusy,
    required this.onSync,
    required this.pendingCount,
  });

  final SyncOverview sync;
  final bool isBusy;
  final Future<void> Function() onSync;
  final int pendingCount;

  String _syncText() {
    if (sync.isOfflineEffective) return 'Sin conexión';
    if (sync.lastSyncAt != null) {
      final t = AppClock.toDefaultZone(sync.lastSyncAt!);
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      return 'Última sync: $hh:$mm';
    }
    return '$pendingCount pendientes';
  }

  bool get _canSync =>
      !isBusy &&
      !sync.isOfflineEffective &&
      sync.remoteSyncEnabled &&
      sync.apiConfigured;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cloud_sync_rounded, color: _I.muted, size: 12),
        const SizedBox(width: 6),
        Text(
          _syncText(),
          style: const TextStyle(
            color: _I.muted,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        if (_canSync)
          TextButton(
            onPressed: () => onSync(),
            style: TextButton.styleFrom(
              foregroundColor: _I.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'SYNC',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _I.blue,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Data Classes ──────────────────────────────────────────────
class _ModuleStat {
  const _ModuleStat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}
