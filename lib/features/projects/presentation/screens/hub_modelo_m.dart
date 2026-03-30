// ============================================================
// MODELO M — "ARCTIC"
// Ultra-clean, Scandinavian minimal. Cold color palette
// (ice blue + teal + indigo). Inspired by Linear.app +
// Arctic Iris palette. Enterprise SaaS feel.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ───────────────────────────────────────────────────
abstract final class _M {
  static const bg           = Color(0xFFF5FAFE);
  static const surface      = Colors.white;
  static const stroke       = Color(0xFFE0EAF6);
  static const strokeStrong = Color(0xFFB8D0EE);
  static const primary      = Color(0xFF0891B2);
  // primaryDark retained for completeness: Color(0xFF0E7490)
  static const accent       = Color(0xFF6366F1);
  static const accentLight  = Color(0xFFC7D2FE);
  static const text         = Color(0xFF0F172A);
  static const muted        = Color(0xFF64748B);
  static const mutedLight   = Color(0xFF94A3B8);
  static const red          = Color(0xFFEF4444);
  // redSoft retained for completeness: Color(0xFFFEF2F2)
  static const green        = Color(0xFF10B981);
  // greenSoft retained for completeness: Color(0xFFECFDF5)
  static const yellow       = Color(0xFFF59E0B);
  // yellowSoft retained for completeness: Color(0xFFFFFBEB)
  static const white        = Colors.white;
}

// ── Screen ────────────────────────────────────────────────────
class HubModeloM extends StatelessWidget {
  const HubModeloM({super.key});

  static String _todayLabel() {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    return '$day ${months[now.month - 1]} ${now.year}';
  }

  static String _rel(DateTime dt) {
    final d = DateTime.now().difference(dt).inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${dt.day}/${dt.month}';
  }

  void _showProjectSheet(
    BuildContext context,
    List<ProjectRecord> projects,
    ProjectRecord current,
    void Function(ProjectRecord) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _M.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: projects
            .map((p) => ListTile(
                  title: Text(p.name,
                      style: const TextStyle(color: _M.text, fontSize: 14)),
                  trailing: p.id == current.id
                      ? const Icon(Icons.check_rounded,
                          color: _M.primary, size: 18)
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
          return const Scaffold(
            backgroundColor: _M.bg,
            body: Center(
              child: CircularProgressIndicator(color: _M.primary),
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
        final pct             = (summary.compliancePercent * 100).round();
        final compliance      = summary.compliancePercent / 100.0;
        final completed3      = controller.completedRestrictions.take(3).toList();

        final canSync = !controller.isBusy &&
            !sync.isOfflineEffective &&
            sync.remoteSyncEnabled &&
            sync.apiConfigured;

        final syncText = sync.isOfflineEffective
            ? 'Sin conexión — modo offline'
            : sync.isSyncing
                ? 'Sincronizando…'
                : sync.lastSyncAt != null
                    ? 'Sincronizado ${_rel(sync.lastSyncAt!)}'
                    : pendingCount > 0
                        ? '$pendingCount cambios pendientes de sincronizar'
                        : 'Todo sincronizado';

        return Scaffold(
          backgroundColor: _M.bg,
          body: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────
              Container(
                color: _M.surface,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _M.stroke),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const DirektorLogo(size: 26),
                        const SizedBox(width: 8),
                        const Text(
                          'DIREKTOR',
                          style: TextStyle(
                            color: _M.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        _StatusPill(sync: sync),
                        const SizedBox(width: 10),
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
                              _showProjectSheet(
                                context,
                                projects,
                                project,
                                (p) => controller.changeProject(p.id),
                              );
                            } else if (v == 'styles') {
                              if (!context.mounted) return;
                              await showStylePicker(context);
                            }
                          },
                          color: _M.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _M.stroke),
                          ),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _M.accentLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: _M.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'profile',
                              child: Text('Mi perfil',
                                  style: TextStyle(color: _M.text)),
                            ),
                            const PopupMenuItem(
                              value: 'projects',
                              child: Text('Proyectos',
                                  style: TextStyle(color: _M.text)),
                            ),
                            PopupMenuItem(
                              value: 'styles',
                              child: Row(
                                children: const [
                                  Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                                  SizedBox(width: 8),
                                  Text('Cambiar Estilo',
                                      style: TextStyle(color: _M.text)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Text('Cerrar sesión',
                                  style: TextStyle(color: _M.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Scrollable Body ───────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Project Pills ──────────────────────
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          itemCount: projects.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final p = projects[i];
                            final selected = p.id == project.id;
                            return GestureDetector(
                              onTap: () =>
                                  controller.changeProject(p.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _M.primary
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: selected
                                      ? null
                                      : Border.all(
                                          color: _M.strokeStrong),
                                ),
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    color: selected
                                        ? _M.white
                                        : _M.muted,
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Resumen Header ─────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    project.name,
                                    style: const TextStyle(
                                      color: _M.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _todayLabel(),
                                  style: const TextStyle(
                                    color: _M.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${user.name} · ${project.roleLabel}',
                              style: const TextStyle(
                                  color: _M.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // ── Metrics Grid ───────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.5,
                          children: [
                            _ArcticMetric(
                              label: 'Cumplimiento',
                              value: '$pct%',
                              sublabel: 'restricciones',
                              color: _M.green,
                              icon: Icons.verified_rounded,
                            ),
                            _ArcticMetric(
                              label: 'Vencidas',
                              value: '$overdueCount',
                              sublabel: 'acción requerida',
                              color: overdueCount > 0
                                  ? _M.red
                                  : _M.green,
                              icon: Icons.warning_rounded,
                            ),
                            _ArcticMetric(
                              label: 'En proceso',
                              value: '$inProgressCount',
                              sublabel: 'activas ahora',
                              color: _M.yellow,
                              icon: Icons.timelapse_rounded,
                            ),
                            _ArcticMetric(
                              label: 'Hitos activos',
                              value: '${milestones.inProgressCount}',
                              sublabel: 'seguimiento',
                              color: _M.primary,
                              icon: Icons.flag_circle_rounded,
                            ),
                          ],
                        ),
                      ),

                      // ── Compliance Bar ─────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Cumplimiento general',
                                  style: TextStyle(
                                    color: _M.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$pct%',
                                  style: TextStyle(
                                    color: pct >= 70
                                        ? _M.green
                                        : pct >= 40
                                            ? _M.yellow
                                            : _M.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: compliance.clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: _M.stroke,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      pct >= 70
                                          ? _M.green
                                          : pct >= 40
                                              ? _M.yellow
                                              : _M.red,
                                    ),
                                  ),
                                ),
                                if (overdueCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: -2,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: _M.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Module Navigation ──────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MÓDULOS',
                              style: TextStyle(
                                color: _M.muted,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ArcticModuleRow(
                              icon: Icons.analytics_rounded,
                              accentColor: _M.primary,
                              title: 'Análisis de restricciones',
                              subtitle: 'Cumplimiento y vencidas',
                              bigValue: '$pct%',
                              bigLabel: 'cumplim.',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.restrictionsList),
                            ),
                            _ArcticModuleRow(
                              icon: Icons.flag_circle_rounded,
                              accentColor: const Color(0xFF0891B2),
                              title: 'Control de Hitos',
                              subtitle: 'Seguimiento contractual',
                              bigValue: '${milestones.delayedCount}',
                              bigLabel: 'vencidos',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.controlHitos),
                            ),
                            _ArcticModuleRow(
                              icon: Icons.groups_rounded,
                              accentColor: _M.accent,
                              title: 'Acta de Reuniones',
                              subtitle: 'Option 9 panel',
                              bigValue: '—',
                              bigLabel: 'sesiones',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.actaReuniones),
                            ),
                          ],
                        ),
                      ),

                      // ── Recent Closures ────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Últimas cerradas',
                                  style: TextStyle(
                                    color: _M.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
                                    'Ver todo →',
                                    style: TextStyle(
                                      color: _M.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _M.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _M.stroke),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: completed3.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Sin cierres recientes.',
                                        style: TextStyle(
                                            color: _M.muted, fontSize: 12),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (int i = 0;
                                            i < completed3.length;
                                            i++) ...[
                                          if (i > 0)
                                            const Divider(
                                              color: _M.stroke,
                                              height: 1,
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: _M.green,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    completed3[i].activity,
                                                    style: const TextStyle(
                                                      color: _M.text,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _rel(completed3[i].updatedAt),
                                                  style: const TextStyle(
                                                    color: _M.muted,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // ── Sync Footer ────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_sync_rounded,
                                color: _M.mutedLight, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                syncText,
                                style: const TextStyle(
                                    color: _M.muted, fontSize: 11),
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
                                  'Sincronizar',
                                  style: TextStyle(
                                    color: _M.primary,
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

// ── Status Pill ───────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.sync});
  final SyncOverview sync;

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String label;

    if (!sync.hasNetwork || sync.isOfflineEffective) {
      dotColor = _M.red;
      label = 'Sin conexión';
    } else if (sync.pendingCount > 0) {
      dotColor = _M.yellow;
      label = '${sync.pendingCount} pendientes';
    } else {
      dotColor = _M.green;
      label = 'Sincronizado';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: dotColor.withValues(alpha: 0.08),
        border: Border.all(color: dotColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: dotColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Arctic Metric Card ────────────────────────────────────────
class _ArcticMetric extends StatelessWidget {
  const _ArcticMetric({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _M.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _M.stroke),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: _M.mutedLight,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: const TextStyle(
                      color: _M.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Arctic Module Row ─────────────────────────────────────────
class _ArcticModuleRow extends StatelessWidget {
  const _ArcticModuleRow({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.bigValue,
    required this.bigLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String bigValue;
  final String bigLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _M.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _M.stroke),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _M.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: _M.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bigValue,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  bigLabel,
                  style: const TextStyle(
                      color: _M.muted, fontSize: 9),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _M.mutedLight,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
