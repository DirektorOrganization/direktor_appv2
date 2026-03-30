// ============================================================
// MODELO A — "DIREKTOR PRO"
// Dashboard ejecutivo premium. Header wave con gradiente,
// KPI row horizontal, tarjetas de módulo con acento lateral,
// sync discreto al pie. Estilo: corporativo moderno.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

class HubModeloA extends StatelessWidget {
  const HubModeloA({super.key});

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
          backgroundColor: const Color(0xFFF3F6FA),
          body: CustomScrollView(
            slivers: [
              // ── Header wave ──────────────────────────────────
              SliverToBoxAdapter(
                child: _WaveHeader(
                  user: user,
                  project: project,
                  projects: controller.projects,
                  onChangeProject: controller.changeProject,
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
              ),
              // ── KPI Strip ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Row(
                      children: [
                        _KpiChip(
                          value: '$overdueCount',
                          label: 'Retrasadas',
                          color: const Color(0xFFD64545),
                          icon: Icons.warning_rounded,
                        ),
                        const SizedBox(width: 10),
                        _KpiChip(
                          value: '${(summary.compliancePercent * 100).round()}%',
                          label: 'Cumplimiento',
                          color: const Color(0xFF1B8E5A),
                          icon: Icons.verified_rounded,
                        ),
                        const SizedBox(width: 10),
                        _KpiChip(
                          value: '$inProgressCount',
                          label: 'En proceso',
                          color: const Color(0xFFE4A620),
                          icon: Icons.timelapse_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Sección módulos ───────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionLabel(label: 'Módulos del proyecto'),
                    const SizedBox(height: 12),
                    _ModuleCardA(
                      accentColor: AppTheme.brandBlue,
                      icon: Icons.analytics_rounded,
                      title: 'Análisis de restricciones',
                      subtitle: 'Cumplimiento operativo',
                      bigValue: '${(summary.compliancePercent * 100).round()}%',
                      bigLabel: 'cumplimiento',
                      progress: summary.compliancePercent,
                      progressColor: const Color(0xFF1B8E5A),
                      chips: [
                        _MiniChip('$overdueCount retrasadas', const Color(0xFFD64545)),
                        _MiniChip('${summary.completed} OK', const Color(0xFF1B8E5A)),
                        _MiniChip('${summary.pending} pend.', const Color(0xFF62748A)),
                      ],
                      ctaLabel: 'Ver análisis',
                      onCta: () => Navigator.pushNamed(context, RouteNames.restrictionsList),
                    ),
                    const SizedBox(height: 14),
                    _ModuleCardA(
                      accentColor: const Color(0xFF0F7AD8),
                      icon: Icons.flag_circle_rounded,
                      title: 'Control de hitos',
                      subtitle: 'Seguimiento contractual',
                      bigValue: '${milestones.delayedCount}',
                      bigLabel: 'vencidos',
                      chips: [
                        _MiniChip('${milestones.inProgressCount} en prog.', const Color(0xFFE4A620)),
                        _MiniChip('S/ ${milestones.accumulatedPenalty.toStringAsFixed(0)} pen.', const Color(0xFFD64545)),
                        _MiniChip('${milestones.activeExtensions} amp.', AppTheme.brandBlue),
                      ],
                      ctaLabel: 'Ver hitos',
                      onCta: () => Navigator.pushNamed(context, RouteNames.controlHitos),
                    ),
                    const SizedBox(height: 14),
                    _ModuleCardA(
                      accentColor: AppTheme.brandOrange,
                      icon: Icons.groups_rounded,
                      title: 'Acta de reuniones',
                      subtitle: 'Panel ejecutivo Option 9',
                      bigValue: '—',
                      bigLabel: 'sesiones',
                      chips: [
                        _MiniChip('Sesión en curso', const Color(0xFF1B8E5A)),
                        _MiniChip('Vencidos', const Color(0xFFD64545)),
                      ],
                      ctaLabel: 'Abrir actas',
                      onCta: () => Navigator.pushNamed(context, RouteNames.actaReuniones),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Últimos cierres'),
                    const SizedBox(height: 10),
                    _RecentClosures(items: completed3),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, RouteNames.completedRestrictions),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Ver más cierres'),
                    ),
                    const SizedBox(height: 20),
                    // ── Sync pill ─────────────────────────────
                    _SyncPillA(sync: sync, isBusy: controller.isBusy, onSync: controller.syncNow),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Wave header ─────────────────────────────────────────────
String _todayLabel() {
  const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2,'0')} ${months[now.month - 1]} ${now.year}';
}

class _WaveHeader extends StatelessWidget {
  const _WaveHeader({
    required this.user,
    required this.project,
    required this.projects,
    required this.onChangeProject,
    required this.onMenuSelected,
  });

  final UserProfile user;
  final ProjectRecord project;
  final List<ProjectRecord> projects;
  final ValueChanged<int> onChangeProject;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: 230,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF084C8D), Color(0xFF0A66B7), Color(0xFF1580D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const DirektorLogo(size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, ${user.name.split(' ').first}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            project.roleLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _todayLabel(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: onMenuSelected,
                      color: Colors.white,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
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
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => _showProjects(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProjects(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: projects.map((p) => ListTile(
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.address),
            trailing: p.id == project.id
                ? Icon(Icons.check_circle_rounded, color: AppTheme.brandBlue)
                : null,
            onTap: () {
              onChangeProject(p.id);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── KPI chip ────────────────────────────────────────────────
class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E3F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF62748A), fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Module card ─────────────────────────────────────────────
class _ModuleCardA extends StatelessWidget {
  const _ModuleCardA({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bigValue,
    required this.bigLabel,
    required this.chips,
    required this.ctaLabel,
    required this.onCta,
    this.progress,
    this.progressColor,
  });

  final Color accentColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String bigValue;
  final String bigLabel;
  final List<_MiniChip> chips;
  final String ctaLabel;
  final VoidCallback onCta;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E3F0)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E2B3A))),
                              Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF62748A))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(bigValue, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: accentColor, height: 1.0)),
                            Text(bigLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF62748A))),
                          ],
                        ),
                      ],
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFD9E3F0),
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? accentColor),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: chips,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: FilledButton(
                        onPressed: onCta,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(ctaLabel),
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

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Section label ────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.brandBlue, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E2B3A))),
      ],
    );
  }
}

// ── Recent closures ──────────────────────────────────────────
class _RecentClosures extends StatelessWidget {
  const _RecentClosures({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Sin cierres recientes.', style: TextStyle(color: Color(0xFF62748A), fontSize: 12)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E3F0)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final date = _relDate(item.updatedAt);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF1B8E5A), size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.activity, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E2B3A)), overflow: TextOverflow.ellipsis)),
                    Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF62748A))),
                  ],
                ),
              ),
              if (idx < items.length - 1) const Divider(height: 1, color: Color(0xFFD9E3F0)),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _relDate(DateTime v) {
    final d = DateTime.now().difference(v).inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${v.day}/${v.month}';
  }
}

// ── Sync pill ────────────────────────────────────────────────
class _SyncPillA extends StatelessWidget {
  const _SyncPillA({required this.sync, required this.isBusy, required this.onSync});
  final SyncOverview sync;
  final bool isBusy;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final offline = sync.isOfflineEffective;
    final color = offline ? const Color(0xFFD64545) : AppTheme.brandBlue;
    final canSync = !isBusy && !sync.isSyncing && !offline && sync.remoteSyncEnabled && sync.apiConfigured;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_sync_rounded, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offline ? 'Sin conexión – modo local' : '${sync.pendingCount} pendientes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                ),
                if (sync.lastSyncAt != null)
                  Text(
                    'Última sync: ${sync.lastSyncAt!.hour.toString().padLeft(2, '0')}:${sync.lastSyncAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF62748A)),
                  ),
              ],
            ),
          ),
          if (!offline)
            TextButton(
              onPressed: canSync ? onSync : null,
              style: TextButton.styleFrom(foregroundColor: color, minimumSize: const Size(72, 32)),
              child: sync.isSyncing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sincronizar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
