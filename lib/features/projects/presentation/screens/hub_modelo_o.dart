// ============================================================
// MODELO O — "VELVET"
// Hub ejecutivo oscuro. Paleta Velvet Tide: teal profundo +
// violeta + púrpura. El dashboard que vive en el teléfono de
// un CFO. Sofisticado, denso en datos, refinado.
// ============================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../app/core/app_clock.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _O {
  static const bg           = Color(0xFF001219);
  static const surface      = Color(0xFF005F73);
  static const surface2     = Color(0xFF0A9396);
  static const card         = Color(0xFF021E24);
  static const stroke       = Color(0xFF0D4A52);
  static const violet       = Color(0xFF9D4EDD);
  static const violetLight  = Color(0xFFD4A5FF);
  static const teal         = Color(0xFF94D2BD);
  static const tealMid      = Color(0xFF0A9396);
  static const tealDeep     = Color(0xFF005F73);
  static const gold         = Color(0xFFEE9B00);
  static const textLight    = Color(0xFFE9F5F7);
  static const muted        = Color(0xFF7CBFC9);
  static const red          = Color(0xFFAE2012);
  static const redBright    = Color(0xFFBB3E03);
  static const green        = Color(0xFF80C080);
}

// ── Wave Clipper ─────────────────────────────────────────────
class _OWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height + 20, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── Connection Badge ─────────────────────────────────────────
class _OConnBadge extends StatelessWidget {
  const _OConnBadge({required this.sync});
  final SyncOverview sync;

  @override
  Widget build(BuildContext context) {
    final offline = sync.isOfflineEffective;
    final color = offline ? _O.redBright : _O.teal;
    final label = offline ? 'OFFLINE' : 'ONLINE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

// ── Chip ─────────────────────────────────────────────────────
class _OChip extends StatelessWidget {
  const _OChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Module Card ───────────────────────────────────────────────
class _OModuleCard extends StatelessWidget {
  const _OModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bigValue,
    required this.bigLabel,
    required this.chips,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String bigValue;
  final String bigLabel;
  final List<_OChip> chips;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _O.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _O.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: _O.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: _O.muted, fontSize: 11)),
                const SizedBox(height: 10),
                Row(children: chips),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Right side: value + CTA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(bigValue,
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              Text(bigLabel,
                  style: const TextStyle(color: _O.muted, fontSize: 9)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ctaLabel,
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────
class HubModeloO extends StatelessWidget {
  const HubModeloO({super.key});

  static String _rel(DateTime? dt) {
    if (dt == null) return '';
    final diff = AppClock.nowInDefaultZone().difference(
      AppClock.toDefaultZone(dt),
    );
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}m';
    return 'ahora';
  }

  void _showProjectSheet(
    BuildContext context,
    List<ProjectRecord> projects,
    ProjectRecord current,
    void Function(ProjectRecord) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _O.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: projects
            .map((p) => ListTile(
                  title: Text(p.name,
                      style: const TextStyle(
                          color: _O.textLight, fontSize: 14)),
                  trailing: p.id == current.id
                      ? const Icon(Icons.check, color: _O.teal, size: 18)
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

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user    = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return Theme(
            data: ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: _O.bg),
            child: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: _O.teal),
              ),
            ),
          );
        }

        final summary      = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones   = controller.milestoneSummary;
        final sync         = controller.syncOverview;
        final projects     = controller.projects;

        final overdueCount    =
            restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount =
            restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pendingCount    =
            restrictions.where((r) => r.isPending && !r.isOverdue).length;
        final completed3      =
            controller.completedRestrictions.take(3).toList();
        final pct             = (summary.compliancePercent * 100).round();
        final canSync         = pendingCount > 0 && !sync.isOfflineEffective;

        final accumulated = milestones.accumulatedPenalty.toStringAsFixed(0);
        final potential   = milestones.potentialPenalty.toStringAsFixed(0);
        final hasPenalty  = milestones.accumulatedPenalty > 0;

        final syncText = sync.isOfflineEffective
            ? 'Sin conexión — modo offline'
            : sync.lastSyncAt != null
                ? 'Última sync ${_rel(sync.lastSyncAt)}'
                : 'Sin sincronizar';

        return Theme(
          data: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: _O.bg),
          child: Scaffold(
            backgroundColor: _O.bg,
            body: Column(
              children: [
                // ── GRADIENT HEADER (wave) ────────────────────
                ClipPath(
                  clipper: _OWaveClipper(),
                  child: Container(
                    height: 220,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF001219),
                          _O.tealDeep,
                          _O.tealMid,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Row 1: logo + project + badge + menu
                            Row(
                              children: [
                                const DirektorLogo(size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'VELVET DASHBOARD',
                                        style: TextStyle(
                                          color: _O.muted,
                                          fontSize: 9,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      Text(
                                        project.name,
                                        style: const TextStyle(
                                          color: _O.textLight,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                _OConnBadge(sync: sync),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'logout') {
                                      await controller.logout();
                                      if (!context.mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          RouteNames.login,
                                          (_) => false);
                                    } else if (v == 'profile') {
                                      if (!context.mounted) return;
                                      Navigator.pushNamed(
                                          context, RouteNames.profile);
                                    } else if (v == 'projects') {
                                      _showProjectSheet(
                                          context,
                                          projects,
                                          project,
                                          (p) => controller
                                              .changeProject(p.id));
                                    } else if (v == 'styles') {
                                      if (!context.mounted) return;
                                      await showStylePicker(context);
                                    }
                                  },
                                  color: _O.card,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.25)),
                                    ),
                                    child: const Icon(
                                        Icons.person_outline,
                                        color: Colors.white,
                                        size: 16),
                                  ),
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'profile',
                                      child: Text('Mi perfil',
                                          style: TextStyle(
                                              color: _O.textLight)),
                                    ),
                                    const PopupMenuItem(
                                      value: 'projects',
                                      child: Text('Proyectos',
                                          style: TextStyle(
                                              color: _O.textLight)),
                                    ),
                                    PopupMenuItem(
                                      value: 'styles',
                                      child: Row(
                                        children: const [
                                          Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                                          SizedBox(width: 8),
                                          Text('Cambiar Estilo',
                                              style: TextStyle(color: _O.textLight)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'logout',
                                      child: Text('Cerrar sesión',
                                          style:
                                              TextStyle(color: _O.teal)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Row 2: big pct + stats
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$pct%',
                                        style: const TextStyle(
                                          color: _O.teal,
                                          fontSize: 52,
                                          fontWeight: FontWeight.w900,
                                          height: 0.9,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'CUMPLIMIENTO GENERAL',
                                        style: TextStyle(
                                          color: _O.muted,
                                          fontSize: 9,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 60,
                                    color: _O.stroke),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: overdueCount > 0
                                                ? _O.red
                                                : _O.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('$overdueCount vencidas',
                                            style: const TextStyle(
                                                color: _O.textLight,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ]),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                              color: _O.gold,
                                              shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                            '$inProgressCount en proceso',
                                            style: const TextStyle(
                                                color: _O.textLight,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ]),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                              color: _O.violet,
                                              shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                            '${milestones.inProgressCount} hitos activos',
                                            style: const TextStyle(
                                                color: _O.textLight,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── SCROLLABLE BODY ───────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Transform.translate(
                      offset: const Offset(0, -24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── FINANCIAL EXPOSURE ───────────────
                          if (hasPenalty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _O.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: _O.violet
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.payments_outlined,
                                          color: _O.gold,
                                          size: 18),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'EXPOSICIÓN FINANCIERA',
                                        style: TextStyle(
                                          color: _O.gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () =>
                                            Navigator.pushNamed(context,
                                                RouteNames.controlHitos),
                                        child: const Text('ver →',
                                            style: TextStyle(
                                                color: _O.violet,
                                                fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Text('Penalidad acum.',
                                          style: TextStyle(
                                              color: _O.muted,
                                              fontSize: 11)),
                                      const Spacer(),
                                      Text('S/ $accumulated',
                                          style: const TextStyle(
                                            color: _O.redBright,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text('Penalidad pot.',
                                          style: TextStyle(
                                              color: _O.muted,
                                              fontSize: 11)),
                                      const Spacer(),
                                      Text('S/ $potential',
                                          style: const TextStyle(
                                            color: _O.muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // ── MODULE CARDS ──────────────────────
                          _OModuleCard(
                            icon: Icons.analytics_rounded,
                            title: 'RESTRICCIONES',
                            subtitle: 'Análisis de restricciones',
                            accentColor: _O.teal,
                            bigValue: '$pct%',
                            bigLabel: 'CUMPLIM.',
                            chips: [
                              _OChip(
                                  label: '$overdueCount venc',
                                  color: _O.red),
                              _OChip(
                                  label:
                                      '${summary.completed} cerr',
                                  color: _O.green),
                            ],
                            ctaLabel: 'ABRIR →',
                            onTap: () => Navigator.pushNamed(
                                context, RouteNames.restrictionsList),
                          ),
                          _OModuleCard(
                            icon: Icons.flag_circle_rounded,
                            title: 'HITOS',
                            subtitle: 'Control contractual',
                            accentColor: _O.gold,
                            bigValue: '${milestones.inProgressCount}',
                            bigLabel: 'EN PROG.',
                            chips: [
                              _OChip(
                                  label:
                                      '${milestones.delayedCount} venc',
                                  color: _O.redBright),
                              _OChip(
                                  label:
                                      '${milestones.activeExtensions} amp',
                                  color: _O.gold),
                            ],
                            ctaLabel: 'ABRIR →',
                            onTap: () => Navigator.pushNamed(
                                context, RouteNames.controlHitos),
                          ),
                          _OModuleCard(
                            icon: Icons.groups_rounded,
                            title: 'ACTAS',
                            subtitle: 'Option 9 activo',
                            accentColor: _O.violet,
                            bigValue: '—',
                            bigLabel: 'SESIONES',
                            chips: [
                              const _OChip(
                                  label: 'Option 9', color: _O.violet),
                              const _OChip(
                                  label: 'Panel', color: _O.muted),
                            ],
                            ctaLabel: 'ABRIR →',
                            onTap: () => Navigator.pushNamed(
                                context, RouteNames.actaReuniones),
                          ),

                          // ── RECENT ACTIVITY ───────────────────
                          Row(
                            children: [
                              const Text(
                                'ACTIVIDAD',
                                style: TextStyle(
                                  color: _O.muted,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context,
                                    RouteNames.completedRestrictions),
                                child: const Text(
                                  'VER TODO →',
                                  style: TextStyle(
                                    color: _O.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (completed3.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              child: Text(
                                'Sin actividad reciente.',
                                style: const TextStyle(
                                    color: _O.muted, fontSize: 11),
                              ),
                            )
                          else
                            ...completed3.map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _O.card,
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 4,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: _O.gold,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          )),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          r.activity,
                                          style: const TextStyle(
                                              color: _O.textLight,
                                              fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        _rel(r.updatedAt),
                                        style: const TextStyle(
                                            color: _O.muted, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                )),

                          const SizedBox(height: 8),

                          // ── SYNC FOOTER ───────────────────────
                          Row(
                            children: [
                              const Icon(Icons.cloud_sync_rounded,
                                  color: _O.muted, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  syncText,
                                  style: const TextStyle(
                                      color: _O.muted, fontSize: 10),
                                ),
                              ),
                              if (canSync)
                                GestureDetector(
                                  onTap: controller.syncNow,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _O.violet
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'SYNC',
                                      style: TextStyle(
                                        color: _O.violet,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
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
}
