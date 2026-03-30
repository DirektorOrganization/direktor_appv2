// ============================================================
// MODELO H — "COMMAND CENTER"
// Panel operativo con bottom navigation.
// Inspirado en Procore + Monday.com mobile.
// Para el jefe de obra: acceso directo e inmediato.
// Diseñado para usarse con un pulgar, en campo.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
const _bg = Color(0xFFF4F6FA);
const _surface = Colors.white;
const _stroke = Color(0xFFDDE4EF);
const _blue = Color(0xFF0A66B7);
const _orange = Color(0xFFF5A623);
const _red = Color(0xFFD64545);
const _green = Color(0xFF1B8E5A);
const _yellow = Color(0xFFE4A620);
const _text = Color(0xFF1E2B3A);
const _muted = Color(0xFF62748A);

// ── Screen ───────────────────────────────────────────────────
class HubModeloH extends StatefulWidget {
  const HubModeloH({super.key});

  @override
  State<HubModeloH> createState() => _HubModeloHState();
}

class _HubModeloHState extends State<HubModeloH> {
  int _selectedTab = 0;

  // ── Relative date helper ──────────────────────────────────
  String _rel(DateTime v) {
    final d = DateTime.now().difference(v).inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${v.day}/${v.month}';
  }

  // ── Project picker bottom sheet ───────────────────────────
  void _showProjectPicker(
    BuildContext context,
    List<ProjectRecord> projects,
    AppController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
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
                    color: _text,
                  ),
                ),
              ),
              const Divider(height: 1, color: _stroke),
              ...projects.map(
                (p) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _blue.withValues(alpha: 0.10),
                    child: Text(
                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _text,
                    ),
                  ),
                  subtitle: Text(
                    p.company,
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  trailing:
                      p.isLastSelected
                          ? const Icon(
                            Icons.check_circle_rounded,
                            color: _green,
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
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _blue)),
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

        return Scaffold(
          backgroundColor: _bg,
          // ── FAB — solo tab 0 ──────────────────────────────
          floatingActionButton:
              _selectedTab == 0
                  ? FloatingActionButton(
                    onPressed: () =>
                        Navigator.pushNamed(
                          context,
                          RouteNames.restrictionCreate,
                        ),
                    backgroundColor: _orange,
                    foregroundColor: _surface,
                    elevation: 2,
                    child: const Icon(Icons.add_rounded),
                  )
                  : null,
          // ── Bottom Nav ────────────────────────────────────
          bottomNavigationBar: _buildBottomNav(
            overdueCount: overdueCount,
            delayedMilestones: milestones.delayedCount,
          ),
          body: Column(
            children: [
              // ── Top bar (fija) ─────────────────────────────
              _TopBar(
                user: user,
                project: project,
                sync: sync,
                projects: projects,
                onProjectTap: () =>
                    _showProjectPicker(context, projects, controller),
                onMenuSelected: (v) async {
                  if (v == 'logout') {
                    await controller.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                      (_) => false,
                    );
                  } else if (v == 'profile') {
                    Navigator.pushNamed(context, RouteNames.profile);
                  } else if (v == 'styles') {
                    if (!context.mounted) return;
                    await showStylePicker(context);
                  }
                },
              ),
              // ── Body ──────────────────────────────────────
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    // Tab 0 — Home
                    _HomeTab(
                      overdueCount: overdueCount,
                      inProgressCount: inProgressCount,
                      pendingCount: pendingCount,
                      summary: summary,
                      completed3: completed3,
                      compliancePct: compliancePct,
                      rel: _rel,
                    ),
                    // Tab 1 — Restricciones
                    _RestriccionesTab(),
                    // Tab 2 — Hitos
                    _HitosTab(),
                    // Tab 3 — Actas
                    _ActasTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────
  Widget _buildBottomNav({
    required int overdueCount,
    required int delayedMilestones,
  }) {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (i) => setState(() => _selectedTab = i),
      selectedItemColor: _blue,
      unselectedItemColor: _muted,
      backgroundColor: _surface,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      elevation: 0,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: _BadgedIcon(
            icon: Icons.analytics_rounded,
            count: overdueCount,
          ),
          label: 'Restricciones',
        ),
        BottomNavigationBarItem(
          icon: _BadgedIcon(
            icon: Icons.flag_circle_rounded,
            count: delayedMilestones,
          ),
          label: 'Hitos',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Actas',
        ),
      ],
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.project,
    required this.sync,
    required this.projects,
    required this.onProjectTap,
    required this.onMenuSelected,
  });

  final UserProfile user;
  final ProjectRecord project;
  final SyncOverview sync;
  final List<ProjectRecord> projects;
  final VoidCallback onProjectTap;
  final void Function(String) onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Container(
      color: _surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _stroke, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const DirektorLogo(size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onProjectTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              project.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.expand_more_rounded,
                            size: 14,
                            color: _muted,
                          ),
                        ],
                      ),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SyncDot(sync: sync),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: onMenuSelected,
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded, size: 16, color: _muted),
                            SizedBox(width: 10),
                            Text(
                              'Mi perfil',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'styles',
                        child: Row(
                          children: [
                            Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                            SizedBox(width: 10),
                            Text('Cambiar Estilo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _text,
                                )),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 16, color: _red),
                            SizedBox(width: 10),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sync Dot ─────────────────────────────────────────────────
class _SyncDot extends StatelessWidget {
  const _SyncDot({required this.sync});
  final SyncOverview sync;

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    if (sync.isOfflineEffective) {
      dotColor = _red;
    } else if (sync.pendingCount > 0) {
      dotColor = _yellow;
    } else {
      dotColor = _green;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }
}

// ── Badged Icon ───────────────────────────────────────────────
class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── TAB 0 — Home ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.overdueCount,
    required this.inProgressCount,
    required this.pendingCount,
    required this.summary,
    required this.completed3,
    required this.compliancePct,
    required this.rel,
  });

  final int overdueCount;
  final int inProgressCount;
  final int pendingCount;
  final RestrictionSummary summary;
  final List<RestrictionRecord> completed3;
  final double compliancePct;
  final String Function(DateTime) rel;

  @override
  Widget build(BuildContext context) {
    final compliance = (compliancePct / 100).clamp(0.0, 1.0);
    final complianceColor =
        compliancePct >= 80 ? _green : (compliancePct >= 50 ? _yellow : _red);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A) HOY — banner vencidas
          if (overdueCount > 0) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.08),
                border: Border.all(
                  color: _red.withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: _red,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Atención: $overdueCount restricciones vencidas',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _red,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.restrictionsList,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Ver →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // B) Quick actions grid
          const Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickTile(
                label: 'Ver Restricciones',
                icon: Icons.analytics_rounded,
                color: _blue,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.restrictionsList),
              ),
              _QuickTile(
                label: 'Nueva Restricción',
                icon: Icons.add_circle_rounded,
                color: _orange,
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.restrictionCreate),
              ),
              _QuickTile(
                label: 'Control de Hitos',
                icon: Icons.flag_circle_rounded,
                color: const Color(0xFF084C8D),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.controlHitos),
              ),
              _QuickTile(
                label: 'Acta Reuniones',
                icon: Icons.groups_rounded,
                color: const Color(0xFF0F7AD8),
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.actaReuniones),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // C) Stats row
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _stroke),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatMini(overdueCount, 'Vencidas', _red),
                  ),
                  VerticalDivider(
                    color: _stroke,
                    thickness: 1,
                    width: 1,
                  ),
                  Expanded(
                    child: _StatMini(inProgressCount, 'En proceso', _yellow),
                  ),
                  VerticalDivider(
                    color: _stroke,
                    thickness: 1,
                    width: 1,
                  ),
                  Expanded(
                    child: _StatMini(pendingCount, 'Pendientes', _muted),
                  ),
                  VerticalDivider(
                    color: _stroke,
                    thickness: 1,
                    width: 1,
                  ),
                  Expanded(
                    child: _StatMini(summary.completed, 'Cerradas', _green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // D) Últimas cerradas
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _stroke),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Últimas cerradas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.completedRestrictions,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Ver más →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (completed3.isEmpty)
                  const Text(
                    'Sin cierres recientes.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  )
                else
                  ...completed3.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _green,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.activity,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _text,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rel(r.updatedAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // E) Project compliance
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _stroke),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cumplimiento',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${compliancePct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: complianceColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: compliance,
                    minHeight: 8,
                    backgroundColor: _stroke,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(complianceColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Tile ────────────────────────────────────────────────
class _QuickTile extends StatelessWidget {
  const _QuickTile({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TAB 1 — Restricciones ─────────────────────────────────────
class _RestriccionesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_rounded, color: _blue, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Módulo de Restricciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca para ir a la lista completa',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.restrictionsList),
                child: const Text('Abrir restricciones'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.restrictionCreate),
                child: const Text('Nueva restricción'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TAB 2 — Hitos ─────────────────────────────────────────────
class _HitosTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_circle_rounded, color: _blue, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Control de Hitos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca para ir al control de hitos',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.controlHitos),
                child: const Text('Abrir hitos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TAB 3 — Actas ─────────────────────────────────────────────
class _ActasTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, color: _blue, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Acta de Reuniones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca para ir a las actas',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.actaReuniones),
                child: const Text('Abrir actas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Mini ─────────────────────────────────────────────────
class _StatMini extends StatelessWidget {
  const _StatMini(this.value, this.label, this.color);

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
