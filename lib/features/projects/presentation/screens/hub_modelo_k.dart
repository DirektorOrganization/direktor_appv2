// ============================================================
// MODELO K — "BOTANICAL"
// Hub rediseñado con paleta botánica: verde profundo, teal
// y púrpura. Inspirado en Botanical Twilight palette.
// Nature = growth = progress. Material 3 teal seedColor.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _K {
  static const bg          = Color(0xFFF0FDF4);
  static const surface     = Colors.white;
  static const surfaceTint = Color(0xFFECFDF5);
  static const stroke      = Color(0xFFD1FAE5);
  static const primary     = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const accent      = Color(0xFF7C3AED);
  static const accentLight = Color(0xFFC4B5FD);
  static const text        = Color(0xFF064E3B);
  static const muted       = Color(0xFF2D6A4F);
  static const red         = Color(0xFFDC2626);
  static const yellow      = Color(0xFFD97706);
  static const green       = Color(0xFF059669);
  static const gold        = Color(0xFF92400E);
}

// ── Screen ───────────────────────────────────────────────────
class HubModeloK extends StatelessWidget {
  const HubModeloK({super.key});

  static String _relDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
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
      backgroundColor: _K.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: projects
            .map((p) => ListTile(
                  title: Text(p.name,
                      style: const TextStyle(color: _K.text, fontSize: 14)),
                  trailing: p.id == current.id
                      ? const Icon(Icons.check, color: _K.green, size: 18)
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
        final user = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return const Scaffold(
            backgroundColor: _K.bg,
            body: Center(
              child: CircularProgressIndicator(color: _K.primary),
            ),
          );
        }

        final summary      = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones   = controller.milestoneSummary;
        final sync         = controller.syncOverview;
        final projects     = controller.projects;

        final overdueCount    = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pendingCount    = restrictions.where((r) => r.isPending && !r.isOverdue).length;
        final completed3      = controller.completedRestrictions.take(3).toList();
        final pct             = (summary.compliancePercent * 100).round();

        final firstName = user.name.split(' ').first;
        final canSync   = pendingCount > 0 && !sync.isOfflineEffective;

        final syncText = sync.isOfflineEffective
            ? 'Sin conexión — modo offline'
            : sync.lastSyncAt != null
                ? 'Última sync ${_relDate(sync.lastSyncAt)}'
                : 'Sin sincronizar';

        return Scaffold(
          backgroundColor: _K.bg,
          body: Column(
            children: [
              // ── HEADER ───────────────────────────────────────
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF064E3B),
                      Color(0xFF0F766E),
                      Color(0xFF14B8A6),
                    ],
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Row 1: logo + greeting + user menu
                        Row(
                          children: [
                            const DirektorLogo(size: 36),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, $firstName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  project.roleLabel,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.70),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'logout') {
                                  await controller.logout();
                                  if (!context.mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, RouteNames.login, (_) => false);
                                } else if (v == 'profile') {
                                  if (!context.mounted) return;
                                  Navigator.pushNamed(
                                      context, RouteNames.profile);
                                } else if (v == 'projects') {
                                  _showProjectSheet(context, projects, project,
                                      (p) => controller.changeProject(p.id));
                                } else if (v == 'styles') {
                                  if (!context.mounted) return;
                                  await showStylePicker(context);
                                }
                              },
                              color: const Color(0xFF064E3B),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: const Icon(Icons.person_outline,
                                    color: Colors.white, size: 18),
                              ),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'profile',
                                  child: Text('Mi perfil',
                                      style:
                                          TextStyle(color: Colors.white)),
                                ),
                                const PopupMenuItem(
                                  value: 'projects',
                                  child: Text('Proyectos',
                                      style:
                                          TextStyle(color: Colors.white)),
                                ),
                                PopupMenuItem(
                                  value: 'styles',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                                      SizedBox(width: 8),
                                      Text('Cambiar Estilo',
                                          style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Text('Cerrar sesión',
                                      style:
                                          TextStyle(color: Color(0xFF6EE7B7))),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2: project name + change button
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Proyecto activo',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.60),
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    project.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showProjectSheet(
                                  context, projects, project,
                                  (p) => controller.changeProject(p.id)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.folder_open,
                                        color: Colors.white, size: 15),
                                    SizedBox(width: 6),
                                    Text(
                                      'Cambiar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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

              // ── SCROLLABLE BODY ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── KPI STRIP (overlaps header) ──────────
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _K.surfaceTint,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _K.stroke),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Row(
                            children: [
                              _BotKpi(
                                icon: Icons.warning_rounded,
                                value: '$overdueCount',
                                label: 'Vencidas',
                                color: _K.red,
                              ),
                              const SizedBox(width: 8),
                              _BotKpi(
                                icon: Icons.verified_rounded,
                                value: '$pct%',
                                label: 'Cumplim.',
                                color: _K.green,
                              ),
                              const SizedBox(width: 8),
                              _BotKpi(
                                icon: Icons.timelapse_rounded,
                                value: '$inProgressCount',
                                label: 'En proceso',
                                color: _K.yellow,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── MODULE CARDS ─────────────────────────
                      _BotModuleCard(
                        icon: Icons.analytics_rounded,
                        title: 'Análisis de restricciones',
                        subtitle: 'Seguimiento y cierre',
                        accentColor: _K.primary,
                        bigStat: '$pct%',
                        showProgress: true,
                        progressValue:
                            (summary.compliancePercent).clamp(0.0, 1.0),
                        chips: [
                          _BotChip(
                              label: '$overdueCount vencidas',
                              color: _K.red),
                          _BotChip(
                              label: '$inProgressCount en proceso',
                              color: _K.yellow),
                          _BotChip(
                              label:
                                  '${summary.completed} cerradas',
                              color: _K.green),
                        ],
                        ctaLabel: 'Ver restricciones',
                        onTap: () => Navigator.pushNamed(
                            context, RouteNames.restrictionsList),
                      ),
                      const SizedBox(height: 12),

                      _BotModuleCard(
                        icon: Icons.flag_circle_rounded,
                        title: 'Control de Hitos',
                        subtitle: 'Plazos y penalidades',
                        accentColor: _K.primaryLight,
                        bigStat: '${milestones.inProgressCount}',
                        showProgress: false,
                        progressValue: 0,
                        chips: [
                          _BotChip(
                              label:
                                  '${milestones.delayedCount} retrasados',
                              color: _K.red),
                          _BotChip(
                              label:
                                  'S/${milestones.accumulatedPenalty.toStringAsFixed(0)} pen.',
                              color: _K.gold),
                        ],
                        ctaLabel: 'Ver hitos',
                        onTap: () => Navigator.pushNamed(
                            context, RouteNames.controlHitos),
                      ),
                      const SizedBox(height: 12),

                      _BotModuleCard(
                        icon: Icons.groups_rounded,
                        title: 'Acta de reuniones',
                        subtitle: 'Sesiones y acuerdos',
                        accentColor: _K.accent,
                        bigStat: '—',
                        showProgress: false,
                        progressValue: 0,
                        chips: [
                          _BotChip(
                              label: 'Option 9', color: _K.accent),
                          _BotChip(
                              label: 'Sesiones', color: _K.primaryLight),
                        ],
                        ctaLabel: 'Ver actas',
                        onTap: () => Navigator.pushNamed(
                            context, RouteNames.actaReuniones),
                      ),
                      const SizedBox(height: 20),

                      // ── RECENT CLOSURES ──────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: _K.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _K.stroke),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Últimas cerradas',
                                  style: TextStyle(
                                    color: _K.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
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
                                      color: _K.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (completed3.isEmpty)
                              Text(
                                'Sin cierres recientes.',
                                style: TextStyle(
                                  color: _K.muted,
                                  fontSize: 12,
                                ),
                              )
                            else
                              ...completed3.map((r) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: _K.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r.description,
                                            style: const TextStyle(
                                              color: _K.text,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          _relDate(r.updatedAt),
                                          style: const TextStyle(
                                            color: _K.muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── SYNC FOOTER ──────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: _K.primaryLight.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _K.stroke),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_sync_rounded,
                                color: _K.primary, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                syncText,
                                style: const TextStyle(
                                  color: _K.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (canSync)
                              TextButton(
                                onPressed: controller.syncNow,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Sync',
                                  style: TextStyle(
                                    color: _K.accent,
                                    fontSize: 11,
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
        );
      },
    );
  }
}

// ── KPI Chip ─────────────────────────────────────────────────
class _BotKpi extends StatelessWidget {
  const _BotKpi({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _K.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _K.stroke),
          boxShadow: [
            BoxShadow(
              color: _K.primary.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: _K.muted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip data ────────────────────────────────────────────────
class _BotChip {
  const _BotChip({required this.label, required this.color});
  final String label;
  final Color color;
}

// ── Module Card ──────────────────────────────────────────────
class _BotModuleCard extends StatelessWidget {
  const _BotModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bigStat,
    required this.showProgress,
    required this.progressValue,
    required this.chips,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String bigStat;
  final bool showProgress;
  final double progressValue;
  final List<_BotChip> chips;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _K.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _K.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored bar
            Container(width: 4, color: accentColor),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              Icon(icon, size: 20, color: accentColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: _K.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          bigStat,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    // Progress bar (restrictions only)
                    if (showProgress) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 7,
                          backgroundColor:
                              accentColor.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                    ],

                    // Chips
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: chips
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        c.color.withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.label,
                                    style: TextStyle(
                                      color: c.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],

                    // CTA
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }
}
