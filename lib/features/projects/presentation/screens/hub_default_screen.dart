// ============================================================
// VISTA POR DEFECTO — DIREKTOR
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/core/app_clock.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ───────────────────────────────────────────────────
abstract final class _D {
  static const bg           = Color(0xFFF5FAFE);
  static const surface      = Colors.white;
  static const stroke       = Color(0xFFE0EAF6);
  static const primary      = Color(0xFF0A66B7); // Direktor brand blue
  static const primaryDark  = Color(0xFF0852A3);
  static const accent       = Color(0xFF1167C8);
  static const accentLight  = Color(0xFFCCDFF7);
  static const text         = Color(0xFF0F172A);
  static const muted        = Color(0xFF64748B);
  static const mutedLight   = Color(0xFF94A3B8);
  static const red          = Color(0xFFEF4444);
  static const green        = Color(0xFF10B981);
  static const yellow       = Color(0xFFF59E0B);
  static const white        = Colors.white;
}

// ── Screen ────────────────────────────────────────────────────
class HubDefaultScreen extends StatelessWidget {
  const HubDefaultScreen({super.key});

  static String _rel(DateTime dt) {
    final now = AppClock.nowInDefaultZone();
    final v = AppClock.toDefaultZone(dt);
    final d = DateTime(now.year, now.month, now.day)
        .difference(DateTime(v.year, v.month, v.day))
        .inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    return '${v.day}/${v.month}';
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
            backgroundColor: _D.bg,
            body: Center(child: CircularProgressIndicator(color: _D.primary)),
          );
        }

        final summary    = controller.restrictionSummary;
        final milestones = controller.milestoneSummary;
        final avanceGrafico = controller.avanceGraficoData;
        final sync         = controller.syncOverview;
        final projects     = controller.projects;

        final pct = (summary.compliancePercent * 100).round();
        final completed3      = controller.completedRestrictions.take(3).toList();
        final isOnline        = sync.hasNetwork && !sync.isOfflineEffective;

        final canSync = !controller.isBusy &&
            !sync.isOfflineEffective &&
            sync.remoteSyncEnabled &&
            sync.apiConfigured;

        return Scaffold(
          backgroundColor: _D.bg,
          body: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────
              Container(
                color: _D.surface,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _D.stroke)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const DirektorLogo(size: 26),
                        const SizedBox(width: 8),
                        const Text(
                          'DIREKTOR',
                          style: TextStyle(
                            color: _D.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        // Pill de modo — tappable para toggle offline
                        _ConnTogglePill(
                          sync: sync,
                          onToggle: () => controller.setOfflineMode(!sync.isOfflineMode),
                        ),
                        const SizedBox(width: 10),
                        // Boton usuario rediseñado
                        _UserMenuButton(
                          user: user,
                          isOnline: isOnline,
                          onSelected: (v) async {
                            if (v == 'logout') {
                              await controller.logout();
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                  context, RouteNames.login, (_) => false);
                            } else if (v == 'profile') {
                              if (!context.mounted) return;
                              Navigator.pushNamed(context, RouteNames.profile);
                            } else if (v == 'styles') {
                              if (!context.mounted) return;
                              await showStylePicker(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Scrollable Body ───────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(project.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      // ── Selector de Proyecto ───────────────
                      _ProjectSelectorRow(
                        currentProject: project,
                        projects: projects,
                        onChangeProject: (id) => controller.changeProject(id),
                      ),

                      // ── Sync Panel ─────────────────────────
                      _SyncPanel(
                        sync: sync,
                        canSync: canSync,
                        onSync: controller.syncNow,
                      ),

                      // ── Mis Indicadores ────────────────────
                      _IndicatorSection(controller: controller),

                      // ── Module Navigation ──────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODULOS',
                              style: TextStyle(
                                color: _D.muted,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ── Restricciones ──────────────────
                            _DefaultModuleRow(
                              icon: Icons.analytics_rounded,
                              accentColor: _D.primary,
                              title: 'Análisis de Restricciones',
                              subtitle: 'Tablero · Lookahead · Gantt',
                              bigValue: '$pct%',
                              bigLabel: 'cumplim.',
                              locked: !project.restrictionsEnabled,
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.restrictionsList),
                            ),
                            // ── Control de Hitos ───────────────
                            _DefaultModuleRow(
                              icon: Icons.flag_rounded,
                              accentColor: const Color(0xFF0A66B7),
                              title: 'Control de Hitos',
                              subtitle: 'Matriz operativa · Datos · Diagrama',
                              bigValue: '${milestones.delayedCount}',
                              bigLabel: 'vencidos',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.controlHitos),
                            ),
                            _DefaultModuleRow(
                              icon: Icons.construction_rounded,
                              accentColor: const Color(0xFF1565C0),
                              title: 'Avance Grafico — CAMPO',
                              subtitle: 'Propuesta A · Field-first',
                              bigValue: avanceGrafico == null
                                  ? '0%'
                                  : '${(((avanceGrafico.summary.phase1Completion + avanceGrafico.summary.phase2Completion + avanceGrafico.summary.phase3Completion) / 3) * 100).round()}%',
                              bigLabel: 'avance visual',
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.avanceGraficoResumen),
                            ),
                            _DefaultModuleRow(
                              icon: Icons.groups_rounded,
                              accentColor: const Color(0xFF6366F1),
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Ultimas cerradas',
                                  style: TextStyle(
                                    color: _D.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, RouteNames.restrictionsList),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Ver todo →',
                                    style: TextStyle(color: _D.primary, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _D.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _D.stroke),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: completed3.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Sin cierres recientes.',
                                        style: TextStyle(color: _D.muted, fontSize: 12),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        for (int i = 0; i < completed3.length; i++) ...[
                                          if (i > 0) const Divider(color: _D.stroke, height: 1),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: _D.green,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    completed3[i].activity,
                                                    style: const TextStyle(
                                                      color: _D.text,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  _rel(completed3[i].updatedAt),
                                                  style: const TextStyle(
                                                    color: _D.muted,
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

                        ],
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────
// SYNC PANEL
// ─────────────────────────────────────────────────────────────

class _SyncPanel extends StatefulWidget {
  const _SyncPanel({
    required this.sync,
    required this.canSync,
    required this.onSync,
  });

  final SyncOverview sync;
  final bool canSync;
  final VoidCallback onSync;

  @override
  State<_SyncPanel> createState() => _SyncPanelState();
}

class _SyncPanelState extends State<_SyncPanel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = widget.sync;
    final canSync = widget.canSync;
    final onSync = widget.onSync;
    final total = sync.pendingCount + sync.failedCount;
    final isEffective = sync.isOfflineEffective;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Row(
        children: [
          // Estado: pendientes / al día / offline
          if (isEffective)
            _SyncBadge(
              icon: Icons.cloud_off_rounded,
              label: sync.isOfflineForced ? 'Sin red' : 'Modo offline',
              color: sync.isOfflineForced ? _D.red : const Color(0xFFF97316),
            )
          else if (total > 0)
            _SyncBadge(
              icon: Icons.upload_rounded,
              label: '$total pendiente${total == 1 ? '' : 's'}',
              color: sync.failedCount > 0 ? _D.red : const Color(0xFFF97316),
            )
          else if (!sync.isSyncing)
            _SyncBadge(icon: Icons.check_rounded, label: 'Al día', color: _D.green),
          // Última sync
          if (sync.lastSyncAt != null && !isEffective) ...[
            const SizedBox(width: 8),
            _SyncBadge(
              icon: Icons.history_rounded,
              label: _fmtSync(sync.lastSyncAt!),
              color: _D.mutedLight,
            ),
          ],
          const Spacer(),
          // Spinner o botón sincronizar
          if (sync.isSyncing)
            const SizedBox(
              width: 13, height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
            )
          else if (canSync)
            GestureDetector(
              onTap: onSync,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.cloud_upload_rounded, size: 12, color: _D.primary),
                  SizedBox(width: 4),
                  Text('Sincronizar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtSync(DateTime dt) {
    final now = AppClock.nowInDefaultZone();
    final v = AppClock.toDefaultZone(dt);
    final diff = now.difference(v);
    if (diff.inMinutes < 1)  return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      return '${v.hour.toString().padLeft(2,'0')}:${v.minute.toString().padLeft(2,'0')}';
    }
    return '${v.day}/${v.month}';
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PILL DE MODO — tappable (reemplaza _ConnPill)
// ─────────────────────────────────────────────────────────────

class _ConnTogglePill extends StatelessWidget {
  const _ConnTogglePill({required this.sync, required this.onToggle});

  final SyncOverview sync;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isForced = sync.isOfflineForced;
    final isManual = sync.isOfflineMode;

    final Color color;
    final IconData icon;
    final String label;

    if (isForced) {
      color = _D.red;
      icon  = Icons.signal_wifi_off_rounded;
      label = 'Sin red';
    } else if (isManual) {
      color = const Color(0xFFF97316);
      icon  = Icons.cloud_off_rounded;
      label = 'Offline';
    } else {
      color = _D.green;
      icon  = Icons.cloud_done_rounded;
      label = 'Online';
    }

    return GestureDetector(
      onTap: isForced ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            if (!isForced) ...[
              const SizedBox(width: 4),
              Icon(
                isManual ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SELECTOR DE PROYECTO (fila con icono, nombre, empresa y flechas)
// ─────────────────────────────────────────────────────────────

class _ProjectSelectorRow extends StatelessWidget {
  const _ProjectSelectorRow({
    required this.currentProject,
    required this.projects,
    required this.onChangeProject,
  });

  final ProjectRecord currentProject;
  final List<ProjectRecord> projects;
  final ValueChanged<int> onChangeProject;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          color: _D.surface,
          border: Border(bottom: BorderSide(color: _D.stroke)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _D.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_open_rounded, color: _D.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentProject.name,
                    style: const TextStyle(
                      color: _D.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 12, color: _D.mutedLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          currentProject.company,
                          style: const TextStyle(
                            color: _D.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.unfold_more_rounded, color: _D.mutedLight, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectPickerSheet(
        projects: projects,
        currentProjectId: currentProject.id,
        onSelect: (id) {
          onChangeProject(id);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PICKER DE PROYECTOS (bottom sheet con buscador)
// ─────────────────────────────────────────────────────────────

class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({
    required this.projects,
    required this.currentProjectId,
    required this.onSelect,
  });

  final List<ProjectRecord> projects;
  final int currentProjectId;
  final ValueChanged<int> onSelect;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.projects
        .where((p) =>
            _query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.company.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 18),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _D.stroke,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              'Cambiar proyecto',
              style: TextStyle(
                color: _D.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar proyecto...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _D.muted),
                filled: true,
                fillColor: _D.bg,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _D.stroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _D.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _D.primary, width: 1.4),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: _D.muted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final project = filtered[i];
                      final isCurrent = project.id == widget.currentProjectId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? _D.primary.withValues(alpha: 0.06)
                              : _D.surface,
                          border: Border.all(
                            color: isCurrent
                                ? _D.primary.withValues(alpha: 0.28)
                                : _D.stroke,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _D.primary
                                  .withValues(alpha: isCurrent ? 0.14 : 0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.folder_outlined,
                              size: 18,
                              color: _D.primary,
                            ),
                          ),
                          title: Text(
                            project.name,
                            style: const TextStyle(
                              color: _D.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            project.company,
                            style: const TextStyle(color: _D.muted, fontSize: 11),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle_rounded,
                                  color: _D.primary)
                              : null,
                          onTap: () => widget.onSelect(project.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTON DE USUARIO
// ─────────────────────────────────────────────────────────────

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({
    required this.user,
    required this.isOnline,
    required this.onSelected,
  });

  final UserProfile user;
  final bool isOnline;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: _D.accentLight,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: _D.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserMenuSheet(
        user: user,
        isOnline: isOnline,
        onSelected: onSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MENU DE USUARIO (bottom sheet rediseñado)
// ─────────────────────────────────────────────────────────────

class _UserMenuSheet extends StatefulWidget {
  const _UserMenuSheet({
    required this.user,
    required this.isOnline,
    required this.onSelected,
  });

  final UserProfile user;
  final bool isOnline;
  final ValueChanged<String> onSelected;

  @override
  State<_UserMenuSheet> createState() => _UserMenuSheetState();
}

class _UserMenuSheetState extends State<_UserMenuSheet> {
  String? _locationText;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    if (!widget.isOnline) {
      if (mounted) setState(() => _loadingLocation = false);
      return;
    }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationText = 'Ubicacion no disponible';
            _loadingLocation = false;
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      final result = await _reverseGeocode(position.latitude, position.longitude);
      if (mounted) setState(() { _locationText = result; _loadingLocation = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'No se pudo obtener ubicacion';
          _loadingLocation = false;
        });
      }
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=es',
      );
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'DirektorApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 8));
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final address = (data['address'] as Map<String, dynamic>?) ?? {};
      final city = (address['city'] ?? address['town'] ?? address['county'] ?? '') as String;
      final state = (address['state'] ?? '') as String;
      final parts = [city, state].where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(', ');
      return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        '${widget.user.name.isNotEmpty ? widget.user.name[0] : ''}'
        '${widget.user.lastName.isNotEmpty ? widget.user.lastName[0] : ''}'
            .toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 22),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _D.stroke,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          // Avatar + info del usuario
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_D.primaryDark, _D.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: _D.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.fullName,
                      style: const TextStyle(
                        color: _D.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.user.role,
                      style: const TextStyle(color: _D.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Ubicacion
                    if (!widget.isOnline)
                      Row(
                        children: const [
                          Icon(Icons.wifi_off_rounded, size: 12, color: _D.red),
                          SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(color: _D.red, fontSize: 11),
                          ),
                        ],
                      )
                    else if (_loadingLocation)
                      Row(
                        children: const [
                          SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: _D.primary,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Detectando ubicacion...',
                            style: TextStyle(color: _D.muted, fontSize: 11),
                          ),
                        ],
                      )
                    else if (_locationText != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              size: 12, color: _D.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _locationText!,
                              style: const TextStyle(
                                color: _D.muted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(color: _D.stroke, height: 1),
          const SizedBox(height: 10),
          // Opciones
          _MenuOption(
            icon: Icons.person_rounded,
            label: 'Mi perfil',
            color: _D.primary,
            onTap: () {
              Navigator.pop(context);
              widget.onSelected('profile');
            },
          ),
          _MenuOption(
            icon: Icons.palette_rounded,
            label: 'Cambiar estilo',
            color: const Color(0xFFE8941A),
            onTap: () {
              Navigator.pop(context);
              widget.onSelected('styles');
            },
          ),
          _MenuOption(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesion',
            color: _D.red,
            onTap: () {
              Navigator.pop(context);
              widget.onSelected('logout');
            },
          ),
        ],
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  const _MenuOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: _D.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.40),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Module badge helper ───────────────────────────────────────
({String label, Color color}) _moduleInfo(String key) {
  if (key.startsWith('res_')) {
    return (label: 'Restricciones', color: const Color(0xFF0A66B7));
  } else if (key.startsWith('hit_')) {
    return (label: 'Control de Hitos', color: const Color(0xFF0891B2));
  } else if (key.startsWith('act_')) {
    return (label: 'Acta de Reuniones', color: const Color(0xFF6366F1));
  }
  return (label: '', color: _D.muted);
}

// ── Indicator Data ────────────────────────────────────────────
class _IndicatorData {
  _IndicatorData({
    required this.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.sublabel = '',
    this.donutPercent,
    this.barItems,
  });

  final String key;
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String sublabel;
  final double? donutPercent;
  final List<_BarItem>? barItems;
}

class _BarItem {
  const _BarItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

// ── Donut Painter ─────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const sw = 12.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round;

    paint.color = const Color(0xFFE0EAF6);
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.percent != percent || old.color != color;
}

// ── Indicadores Section ───────────────────────────────────────
class _IndicatorSection extends StatelessWidget {
  const _IndicatorSection({required this.controller});

  final AppController controller;

  // Prefs that are shown when the DB has no saved prefs yet (fresh user)
  static final _seedPrefs = [
    HubIndicatorPref(
        key: 'res_cumplimiento', userId: 0, isEnabled: true,
        displayType: 'chart_donut', sortOrder: 0),
    HubIndicatorPref(
        key: 'res_vencidas', userId: 0, isEnabled: true,
        displayType: 'card', sortOrder: 1),
    HubIndicatorPref(
        key: 'res_en_proceso', userId: 0, isEnabled: true,
        displayType: 'card', sortOrder: 2),
    HubIndicatorPref(
        key: 'hit_activos', userId: 0, isEnabled: true,
        displayType: 'card', sortOrder: 6),
  ];

  @override
  Widget build(BuildContext context) {
    if (!controller.indicatorsEnabled) return const SizedBox.shrink();

    final raw = controller.indicatorPrefs;
    // Merge: seed defaults are the base; saved DB prefs override per-key.
    // This ensures indicators not yet saved (never toggled) still show at
    // their default state, while user changes are respected.
    final seedMap = {for (final p in _seedPrefs) p.key: p};
    final rawMap  = {for (final p in raw) p.key: p};
    final prefs   = {...seedMap, ...rawMap}.values.toList();
    bool moduleEnabledForKey(String key) {
      if (key.startsWith('res_')) return controller.indicatorsRestrictionsEnabled;
      if (key.startsWith('hit_')) return controller.indicatorsMilestonesEnabled;
      if (key.startsWith('act_')) return controller.indicatorsActreuEnabled;
      return true;
    }
    final enabled = prefs.where((p) => p.isEnabled && moduleEnabledForKey(p.key)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (enabled.isEmpty) return const SizedBox.shrink();

    final summary       = controller.restrictionSummary;
    final restrictions  = controller.restrictions;
    final milestones    = controller.milestoneSummary;
    final actreuSummary = controller.actreuSummary;

    final overdueCount    = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
    final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
    final dueTodayCount   = restrictions.where((r) => r.isDueToday && !r.isCompleted).length;
    final pct             = (summary.compliancePercent * 100).round();

    // Group: cards → 2-per-row, charts → full-width
    final rows = <Widget>[];
    HubIndicatorPref? pendingCard;

    void flushSolo() {
      if (pendingCard == null) return;
      final d = _resolveData(pendingCard!, pct, overdueCount, inProgressCount,
          dueTodayCount, milestones, actreuSummary, restrictions);
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildCardWidget(d),
      ));
      pendingCard = null;
    }

    for (final pref in enabled) {
      final isChart = pref.displayType != 'card';
      if (isChart) {
        flushSolo();
        final d = _resolveData(pref, pct, overdueCount, inProgressCount,
            dueTodayCount, milestones, actreuSummary, restrictions);
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: pref.displayType == 'chart_donut'
              ? _buildDonutWidget(d)
              : _buildBarWidget(d),
        ));
      } else {
        if (pendingCard != null) {
          final d1 = _resolveData(pendingCard!, pct, overdueCount, inProgressCount,
              dueTodayCount, milestones, actreuSummary, restrictions);
          final d2 = _resolveData(pref, pct, overdueCount, inProgressCount,
              dueTodayCount, milestones, actreuSummary, restrictions);
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildCardWidget(d1)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCardWidget(d2)),
                ],
              ),
            ),
          ));
          pendingCard = null;
        } else {
          pendingCard = pref;
        }
      }
    }
    flushSolo();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MIS INDICADORES',
                style: TextStyle(
                  color: _D.muted,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, RouteNames.indicatorManager),
                child: const Text(
                  'Editar →',
                  style: TextStyle(color: _D.primary, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  _IndicatorData _resolveData(
    HubIndicatorPref pref,
    int pct,
    int overdueCount,
    int inProgressCount,
    int dueTodayCount,
    MilestoneDashboardSummary milestones,
    ActreuSummaryRecord? actreuSummary,
    List<RestrictionRecord> restrictions,
  ) {
    switch (pref.key) {
      case 'res_cumplimiento':
        return _IndicatorData(
          key: pref.key,
          label: 'Cumplimiento',
          value: '$pct%',
          color: pct >= 80 ? _D.green : pct >= 50 ? _D.yellow : _D.red,
          icon: Icons.verified_rounded,
          sublabel: 'restricciones',
          donutPercent: pct / 100.0,
        );
      case 'res_vencidas':
        return _IndicatorData(
          key: pref.key,
          label: 'Vencidas',
          value: '$overdueCount',
          color: overdueCount > 0 ? _D.red : _D.green,
          icon: Icons.warning_rounded,
          sublabel: 'accion requerida',
        );
      case 'res_en_proceso':
        return _IndicatorData(
          key: pref.key,
          label: 'En proceso',
          value: '$inProgressCount',
          color: _D.yellow,
          icon: Icons.timelapse_rounded,
          sublabel: 'activas ahora',
        );
      case 'res_vencen_hoy':
        return _IndicatorData(
          key: pref.key,
          label: 'Vencen hoy',
          value: '$dueTodayCount',
          color: dueTodayCount > 0 ? _D.yellow : _D.green,
          icon: Icons.today_rounded,
          sublabel: 'restricciones',
        );
      case 'res_dias_criticos':
        final umbral = int.tryParse(pref.customParam ?? '3') ?? 3;
        final count = restrictions
            .where((r) =>
                !r.isCompleted &&
                DateTime.now().difference(r.requiredDate).inDays > umbral)
            .length;
        return _IndicatorData(
          key: pref.key,
          label: 'Retraso > $umbral dias',
          value: '$count',
          color: count > 0 ? _D.red : _D.green,
          icon: Icons.schedule_rounded,
          sublabel: 'restricciones',
        );
      case 'res_distribucion':
        final total = restrictions.length;
        final completed =
            restrictions.where((r) => r.isCompleted).length;
        return _IndicatorData(
          key: pref.key,
          label: 'Distribucion',
          value: '$total',
          color: _D.primary,
          icon: Icons.bar_chart_rounded,
          sublabel: 'restricciones',
          barItems: [
            _BarItem(label: 'Completadas', count: completed, color: _D.green),
            _BarItem(label: 'Vencidas', count: overdueCount, color: _D.red),
            _BarItem(label: 'En proceso', count: inProgressCount, color: _D.yellow),
          ],
        );
      case 'hit_activos':
        return _IndicatorData(
          key: pref.key,
          label: 'Hitos activos',
          value: '${milestones.inProgressCount}',
          color: _D.primary,
          icon: Icons.flag_circle_rounded,
          sublabel: 'en seguimiento',
        );
      case 'hit_cumplimiento':
        final hitPct = (milestones.compliance * 100).round();
        return _IndicatorData(
          key: pref.key,
          label: 'Cumplimiento hitos',
          value: '$hitPct%',
          color: hitPct >= 80 ? _D.green : hitPct >= 50 ? _D.yellow : _D.red,
          icon: Icons.flag_circle_rounded,
          sublabel: 'contractual',
          donutPercent: milestones.compliance,
        );
      case 'hit_vencidos':
        return _IndicatorData(
          key: pref.key,
          label: 'Hitos vencidos',
          value: '${milestones.delayedCount}',
          color: milestones.delayedCount > 0 ? _D.red : _D.green,
          icon: Icons.flag_rounded,
          sublabel: 'accion requerida',
        );
      case 'hit_penalidad_acum':
        return _IndicatorData(
          key: pref.key,
          label: 'Penalidad acum.',
          value: milestones.accumulatedPenalty > 0
              ? 'S/ ${milestones.accumulatedPenalty.toStringAsFixed(0)}'
              : 'S/ 0',
          color: milestones.accumulatedPenalty > 0 ? _D.red : _D.green,
          icon: Icons.money_off_rounded,
          sublabel: 'acumulada',
        );
      case 'hit_penalidad_potencial':
        return _IndicatorData(
          key: pref.key,
          label: 'Penalidad potencial',
          value: milestones.potentialPenalty > 0
              ? 'S/ ${milestones.potentialPenalty.toStringAsFixed(0)}'
              : 'S/ 0',
          color: milestones.potentialPenalty > 0 ? _D.yellow : _D.green,
          icon: Icons.warning_amber_rounded,
          sublabel: 'estimada',
        );
      case 'hit_ampliaciones':
        return _IndicatorData(
          key: pref.key,
          label: 'Ampliaciones',
          value: '${milestones.activeExtensions}',
          color: _D.primary,
          icon: Icons.schedule_send_rounded,
          sublabel: 'activas',
        );
      case 'hit_distribucion':
        return _IndicatorData(
          key: pref.key,
          label: 'Distribucion hitos',
          value:
              '${milestones.completedCount + milestones.inProgressCount + milestones.delayedCount}',
          color: _D.primary,
          icon: Icons.bar_chart_rounded,
          sublabel: 'total',
          barItems: [
            _BarItem(
                label: 'Completados',
                count: milestones.completedCount,
                color: _D.green),
            _BarItem(
                label: 'En proceso',
                count: milestones.inProgressCount,
                color: _D.yellow),
            _BarItem(
                label: 'Vencidos',
                count: milestones.delayedCount,
                color: _D.red),
          ],
        );
      case 'act_vencidos':
        return _IndicatorData(
          key: pref.key,
          label: 'Acuerdos vencidos',
          value: '${actreuSummary?.overdueAgreements ?? 0}',
          color: (actreuSummary?.overdueAgreements ?? 0) > 0
              ? _D.red
              : _D.green,
          icon: Icons.gavel_rounded,
          sublabel: 'sin completar',
        );
      case 'act_pendientes':
        return _IndicatorData(
          key: pref.key,
          label: 'Acuerdos pendientes',
          value: '${actreuSummary?.pendingAgreements ?? 0}',
          color: _D.yellow,
          icon: Icons.pending_actions_rounded,
          sublabel: 'pendientes',
        );
      case 'act_cumplimiento':
        final actPct = actreuSummary?.compliancePercent ?? 0.0;
        final actPctInt = (actPct * 100).round();
        return _IndicatorData(
          key: pref.key,
          label: 'Cumplimiento acuerdos',
          value: '$actPctInt%',
          color: actPctInt >= 80
              ? _D.green
              : actPctInt >= 50
                  ? _D.yellow
                  : _D.red,
          icon: Icons.handshake_rounded,
          sublabel: 'de acuerdos',
          donutPercent: actPct,
        );
      case 'act_sesiones_activas':
        return _IndicatorData(
          key: pref.key,
          label: 'Sesiones activas',
          value: '${actreuSummary?.activeSessions ?? 0}',
          color: _D.primary,
          icon: Icons.groups_rounded,
          sublabel: 'en curso',
        );
      case 'act_distribucion':
        final pending = actreuSummary?.pendingAgreements ?? 0;
        final overdueAct = actreuSummary?.overdueAgreements ?? 0;
        return _IndicatorData(
          key: pref.key,
          label: 'Distribucion acuerdos',
          value: '${pending + overdueAct}',
          color: _D.primary,
          icon: Icons.bar_chart_rounded,
          sublabel: 'total',
          barItems: [
            _BarItem(label: 'Pendientes', count: pending, color: _D.yellow),
            _BarItem(label: 'Vencidos', count: overdueAct, color: _D.red),
          ],
        );
      default:
        return _IndicatorData(
          key: pref.key,
          label: pref.key,
          value: '—',
          color: _D.muted,
          icon: Icons.analytics_rounded,
        );
    }
  }

  // ── Module pill ───────────────────────────────────────────────
  Widget _modulePill(String key) {
    final info = _moduleInfo(key);
    if (info.label.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: info.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            info.label,
            style: TextStyle(
              color: info.color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Card widget (compact, 2-per-row friendly) ────────────────
  Widget _buildCardWidget(_IndicatorData data) {
    return Container(
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _D.stroke),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 16),
              ),
              const Spacer(),
              _modulePill(data.key),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
              color: data.color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              color: _D.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (data.sublabel.isNotEmpty)
            Text(
              data.sublabel,
              style: const TextStyle(color: _D.mutedLight, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  // ── Donut chart (full-width) ──────────────────────────────────
  Widget _buildDonutWidget(_IndicatorData data) {
    final percent = data.donutPercent ?? 0.0;
    return Container(
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: CustomPaint(
              painter: _DonutPainter(percent: percent, color: data.color),
              child: Center(
                child: Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modulePill(data.key),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  style: const TextStyle(
                    color: _D.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (data.sublabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    data.sublabel,
                    style: const TextStyle(color: _D.muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: _D.stroke,
                    valueColor: AlwaysStoppedAnimation<Color>(data.color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(percent * 100).round()}% completado',
                  style: const TextStyle(color: _D.mutedLight, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart (full-width) ────────────────────────────────────
  Widget _buildBarWidget(_IndicatorData data) {
    final items = data.barItems ?? [];
    final maxCount = items.isEmpty
        ? 1
        : items.fold(0, (acc, i) => math.max(acc, i.count));
    return Container(
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.stroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modulePill(data.key),
                    const SizedBox(height: 2),
                    Text(
                      data.label,
                      style: const TextStyle(
                        color: _D.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (data.sublabel.isNotEmpty)
                      Text(
                        data.sublabel,
                        style:
                            const TextStyle(color: _D.muted, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < items.length; i++) ...[
            Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Text(
                    items[i].label,
                    style: const TextStyle(color: _D.muted, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: maxCount == 0
                          ? 0
                          : items[i].count / maxCount,
                      minHeight: 8,
                      backgroundColor: _D.stroke,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          items[i].color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 26,
                  child: Text(
                    '${items[i].count}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: items[i].color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (i < items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Module Row ────────────────────────────────────────────────
class _DefaultModuleRow extends StatelessWidget {
  const _DefaultModuleRow({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.bigValue,
    required this.bigLabel,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String bigValue;
  final String bigLabel;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? _D.mutedLight : accentColor;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: locked ? _D.bg : _D.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _D.stroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  locked ? Icons.lock_outline_rounded : icon,
                  color: effectiveColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _D.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      locked ? 'Módulo cerrado para este proyecto' : subtitle,
                      style: const TextStyle(color: _D.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!locked) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bigValue,
                      style: TextStyle(
                        color: effectiveColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      bigLabel,
                      style: const TextStyle(color: _D.muted, fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _D.mutedLight,
                  size: 12,
                ),
              ] else
                const Icon(Icons.arrow_forward_ios_rounded, color: _D.stroke, size: 12),
            ],
          ),
        ),
      ),
    );
  }
}
