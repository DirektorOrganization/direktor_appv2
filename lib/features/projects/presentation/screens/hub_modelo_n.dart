// ============================================================
// MODELO N — "FIELDWORK"
// Stormy Plum Harbor palette + Procore/Fieldwire field-first
// design philosophy. Dark earthy tones with teal + coral.
// Built for construction site supervisors — large elements,
// high contrast, no wasted space.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/core/app_clock.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ───────────────────────────────────────────────────
abstract final class _N {
  static const bg         = Color(0xFF1B2A32);
  static const surface    = Color(0xFF243540);
  static const surface2   = Color(0xFF2E4252);
  static const stroke     = Color(0xFF3A5566);
  static const teal       = Color(0xFF2A9D8F);
  static const tealBright = Color(0xFF3ECFBF);
  static const coral      = Color(0xFFE76F51);
  static const coralSoft  = Color(0xFF4A2820);
  static const amber      = Color(0xFFE9C46A);
  static const amberSoft  = Color(0xFF3A3020);
  static const green      = Color(0xFF52B788);
  static const textLight  = Color(0xFFECF0F5);
  static const muted      = Color(0xFF7B9AB0);
  static const white      = Colors.white;
}

// ── Screen ────────────────────────────────────────────────────
class HubModeloN extends StatelessWidget {
  const HubModeloN({super.key});

  static String _rel(DateTime v) {
    final now = AppClock.nowInDefaultZone();
    final dv = AppClock.toDefaultZone(v);
    final d = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dv.year, dv.month, dv.day))
        .inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${dv.day}/${dv.month}';
  }

  void _showProjectSheet(
    BuildContext context,
    List<ProjectRecord> projects,
    ProjectRecord current,
    void Function(ProjectRecord) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _N.surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: projects
            .map((p) => ListTile(
                  title: Text(p.name,
                      style: const TextStyle(
                          color: _N.textLight, fontSize: 14)),
                  trailing: p.id == current.id
                      ? const Icon(Icons.check_rounded,
                          color: _N.tealBright, size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
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
              scaffoldBackgroundColor: _N.bg,
            ),
            child: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: _N.tealBright),
              ),
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
        // ignore: unused_local_variable
        final pendingCount    = restrictions.where((r) => r.isPending && !r.isOverdue).length;
        final pct             = (summary.compliancePercent * 100).round();
        final compliance      = summary.compliancePercent / 100.0;
        final completed3      = controller.completedRestrictions.take(3).toList();

        final canSync = !controller.isBusy &&
            !sync.isOfflineEffective &&
            sync.remoteSyncEnabled &&
            sync.apiConfigured;

        final syncInfo = sync.isOfflineEffective
            ? 'Sin conexión — modo offline'
            : sync.isSyncing
                ? 'Sincronizando…'
                : sync.lastSyncAt != null
                    ? 'Última sync ${_rel(sync.lastSyncAt!)}'
                    : 'Sin sincronizar';

        final Color complianceColor = compliance >= 0.70
            ? _N.green
            : compliance >= 0.40
                ? _N.amber
                : _N.coral;

        return Theme(
          data: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: _N.bg,
          ),
          child: Scaffold(
            backgroundColor: _N.bg,
            body: Column(
              children: [
                // ── Sticky Header ────────────────────────────
                Container(
                  color: _N.surface,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: _N.stroke),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const DirektorLogo(size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showProjectSheet(
                                context,
                                projects,
                                project,
                                (p) => controller.changeProject(p.id),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.name,
                                          style: const TextStyle(
                                            color: _N.textLight,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                              color: _N.muted,
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.expand_more_rounded,
                                      color: _N.muted, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FieldStatusBadge(sync: sync),
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
                                  (p) => controller.changeProject(p.id),
                                );
                              } else if (v == 'styles') {
                                if (!context.mounted) return;
                                await showStylePicker(context);
                              }
                            },
                            color: _N.surface2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _N.stroke),
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _N.teal.withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: _N.tealBright,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'profile',
                                child: Text('Mi perfil',
                                    style: TextStyle(color: _N.textLight)),
                              ),
                              const PopupMenuItem(
                                value: 'projects',
                                child: Text('Proyectos',
                                    style: TextStyle(color: _N.textLight)),
                              ),
                              PopupMenuItem(
                                value: 'styles',
                                child: Row(
                                  children: const [
                                    Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                                    SizedBox(width: 8),
                                    Text('Cambiar Estilo',
                                        style: TextStyle(color: _N.textLight)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Text('Cerrar sesión',
                                    style: TextStyle(color: _N.coral)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Scrollable Body ──────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Critical Alert Bar ─────────────
                        if (overdueCount > 0)
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, RouteNames.restrictionsList),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _N.coralSoft,
                                border: Border.all(
                                    color:
                                        _N.coral.withValues(alpha: 0.30)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_rounded,
                                      color: _N.coral, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '! $overdueCount restricciones VENCIDAS — intervención requerida',
                                      style: const TextStyle(
                                        color: _N.coral,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'VER →',
                                    style: TextStyle(
                                      color: _N.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ── Main Metrics Row ───────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              _FieldKpi(
                                value: '$pct%',
                                label: 'CUMPLIM.',
                                color: complianceColor,
                              ),
                              const SizedBox(width: 8),
                              _FieldKpi(
                                value: '$overdueCount',
                                label: 'VENCIDAS',
                                color: overdueCount > 0
                                    ? _N.coral
                                    : _N.green,
                              ),
                              const SizedBox(width: 8),
                              _FieldKpi(
                                value: '$inProgressCount',
                                label: 'PROCESO',
                                color: _N.amber,
                              ),
                              const SizedBox(width: 8),
                              _FieldKpi(
                                value: '${milestones.inProgressCount}',
                                label: 'HITOS',
                                color: _N.teal,
                              ),
                            ],
                          ),
                        ),

                        // ── Compliance Track ───────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Progreso general',
                                    style: TextStyle(
                                      color: _N.textLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      color: complianceColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: compliance.clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor: _N.stroke,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      complianceColor),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Module Cards ───────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MÓDULOS',
                                style: TextStyle(
                                  color: _N.muted,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _FieldModuleCard(
                                accentColor: _N.teal,
                                icon: Icons.analytics_rounded,
                                title: 'RESTRICCIONES',
                                subtitle: 'Análisis operativo',
                                chips: [
                                  _ChipData(
                                      '$overdueCount venc.', _N.coral),
                                  _ChipData(
                                      '${summary.completed} cerr.',
                                      _N.green),
                                ],
                                bigVal: '$pct%',
                                bigLabel: 'CUMPLIM.',
                                ctaText: 'VER →',
                                onTap: () => Navigator.pushNamed(
                                    context, RouteNames.restrictionsList),
                              ),
                              _FieldModuleCard(
                                accentColor: _N.amber,
                                icon: Icons.flag_circle_rounded,
                                title: 'HITOS',
                                subtitle: 'Control contractual',
                                chips: [
                                  _ChipData(
                                      '${milestones.delayedCount} venc.',
                                      _N.coral),
                                  _ChipData(
                                      '${milestones.activeExtensions} amp.',
                                      _N.amber),
                                ],
                                bigVal: '${milestones.inProgressCount}',
                                bigLabel: 'ACTIVOS',
                                ctaText: 'VER →',
                                onTap: () => Navigator.pushNamed(
                                    context, RouteNames.controlHitos),
                              ),
                              _FieldModuleCard(
                                accentColor: _N.coral,
                                icon: Icons.groups_rounded,
                                title: 'ACTAS',
                                subtitle: 'Option 9 activo',
                                chips: [
                                  _ChipData('En revisión', _N.teal),
                                  _ChipData('Panel exec.', _N.amber),
                                ],
                                bigVal: '—',
                                bigLabel: 'SESIONES',
                                ctaText: 'VER →',
                                onTap: () => Navigator.pushNamed(
                                    context, RouteNames.actaReuniones),
                              ),
                            ],
                          ),
                        ),

                        // ── Recent Closures ────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'ÚLTIMAS CERRADAS',
                                    style: TextStyle(
                                      color: _N.muted,
                                      fontSize: 9,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.completedRestrictions),
                                    child: const Text(
                                      'VER TODO →',
                                      style: TextStyle(
                                        color: _N.tealBright,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: _N.surface2,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: _N.stroke),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: completed3.isEmpty
                                    ? const Text(
                                        'Sin cierres recientes.',
                                        style: TextStyle(
                                            color: _N.muted,
                                            fontSize: 11),
                                      )
                                    : Column(
                                        children: [
                                          for (int i = 0;
                                              i < completed3.length;
                                              i++) ...[
                                            if (i > 0)
                                              const Divider(
                                                color: _N.stroke,
                                                height: 1,
                                              ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 6),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: _N.green,
                                                      shape:
                                                          BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      completed3[i].activity,
                                                      style: const TextStyle(
                                                        color: _N.textLight,
                                                        fontSize: 12,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    _rel(completed3[i]
                                                        .updatedAt),
                                                    style: const TextStyle(
                                                      color: _N.muted,
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

                        // ── Sync Footer ────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          child: Row(
                            children: [
                              Icon(
                                sync.isOfflineEffective
                                    ? Icons.cloud_off_rounded
                                    : Icons.cloud_sync_rounded,
                                color: _N.muted,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  syncInfo,
                                  style: const TextStyle(
                                      color: _N.muted, fontSize: 10),
                                ),
                              ),
                              if (canSync)
                                GestureDetector(
                                  onTap: controller.syncNow,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          _N.teal.withValues(alpha: 0.20),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    child: const Text(
                                      'SYNC',
                                      style: TextStyle(
                                        color: _N.tealBright,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
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
}

// ── Field Status Badge ────────────────────────────────────────
class _FieldStatusBadge extends StatelessWidget {
  const _FieldStatusBadge({required this.sync});
  final SyncOverview sync;

  @override
  Widget build(BuildContext context) {
    final offline = !sync.hasNetwork || sync.isOfflineEffective;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: offline
            ? _N.coral.withValues(alpha: 0.20)
            : _N.teal.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        offline ? 'OFFLINE' : 'ONLINE',
        style: TextStyle(
          color: offline ? _N.coral : _N.tealBright,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Field KPI ─────────────────────────────────────────────────
class _FieldKpi extends StatelessWidget {
  const _FieldKpi({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: _N.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: color, width: 3),
            left: const BorderSide(color: _N.stroke),
            right: const BorderSide(color: _N.stroke),
            bottom: const BorderSide(color: _N.stroke),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: _N.muted,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip Data ─────────────────────────────────────────────────
class _ChipData {
  const _ChipData(this.label, this.color);
  final String label;
  final Color color;
}

// ── Field Chip ────────────────────────────────────────────────
class _FieldChip extends StatelessWidget {
  const _FieldChip({required this.data});
  final _ChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Field Module Card ─────────────────────────────────────────
class _FieldModuleCard extends StatelessWidget {
  const _FieldModuleCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.bigVal,
    required this.bigLabel,
    required this.ctaText,
    required this.onTap,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_ChipData> chips;
  final String bigVal;
  final String bigLabel;
  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _N.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: const BorderSide(color: _N.stroke),
          right: const BorderSide(color: _N.stroke),
          bottom: const BorderSide(color: _N.stroke),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _N.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _N.muted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                Row(
                  children: chips
                      .map((c) => _FieldChip(data: c))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bigVal,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                bigLabel,
                style: const TextStyle(
                  color: _N.muted,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ctaText,
                    style: TextStyle(
                      color: accentColor,
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
    );
  }
}
