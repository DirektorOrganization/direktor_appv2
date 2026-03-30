// ============================================================
// MODELO E — "CAMPO"
// Diseñado para trabajadores de campo en construcción.
// Grande, claro, rápido. Optimizado para uso con guantes
// y condiciones de luz solar directa.
// Paleta: naranja profundo + azul corporativo + semáforo.
// "Para el campo — grande, claro, rápido"
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Paleta de colores del modelo ─────────────────────────────
abstract final class _C {
  static const bg     = Color(0xFFF5F7FA);
  static const orange = Color(0xFFF5A623); // AppTheme.brandOrange
  static const headerOrange = Color(0xFFE8941A);
  static const blue   = Color(0xFF0A66B7); // AppTheme.brandBlue
  static const blueDark = Color(0xFF084C8D);
  static const teal   = Color(0xFF0F7AD8);
  static const red    = Color(0xFFD64545);
  static const green  = Color(0xFF1B8E5A);
  static const yellow = Color(0xFFE4A620);
  static const text   = Color(0xFF1E2B3A);
  static const muted  = Color(0xFF62748A);
  static const white  = Colors.white;
}

// ── Meses abreviados en español ───────────────────────────────
const _monthLabels = [
  '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
  'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_monthLabels[d.month]} ${d.year}';

// ── Pantalla principal ────────────────────────────────────────
class HubModeloE extends StatelessWidget {
  const HubModeloE({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final user    = controller.user;
          final project = controller.currentProject;

          if (project == null || user == null) {
            return const Scaffold(
              backgroundColor: _C.bg,
              body: Center(
                child: CircularProgressIndicator(color: _C.blue),
              ),
            );
          }

          final summary      = controller.restrictionSummary;
          final restrictions = controller.restrictions;
          final milestones   = controller.milestoneSummary;
          final sync         = controller.syncOverview;

          final overdueCount    = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
          final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
          final pendingCount    = restrictions.where((r) => r.isPending).length;
          final completed3      = controller.completedRestrictions.take(3).toList();

          final compliance = summary.compliancePercent.clamp(0.0, 100.0);
          final isOffline  = sync.isOfflineEffective;
          final showSyncChip = sync.pendingCount > 0 || isOffline;

          void handleMenu(String value) async {
            if (value == 'logout') {
              await controller.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, RouteNames.login, (_) => false);
            } else if (value == 'profile') {
              if (!context.mounted) return;
              Navigator.pushNamed(context, RouteNames.profile);
            } else if (value == 'styles') {
              if (!context.mounted) return;
              await showStylePicker(context);
            }
          }

          return Scaffold(
            backgroundColor: _C.bg,
            body: Column(
              children: [
                // ── 1. Header naranja sólido ──────────────────
                _CampoHeader(
                  user: user,
                  project: project,
                  projects: controller.projects,
                  onProjectChange: controller.changeProject,
                  onMenuSelected: handleMenu,
                ),

                // ── Contenido scrollable ──────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 2. Alerta de vencidas ─────────────
                        if (overdueCount > 0) ...[
                          _AlertStrip(
                            overdueCount: overdueCount,
                            onTap: () => Navigator.pushNamed(
                                context, RouteNames.restrictionsList),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── 3. Grid de acciones rápidas ───────
                        _QuickActionGrid(
                          overdueCount:    overdueCount,
                          inProgressCount: inProgressCount,
                          delayedMilestones: milestones.delayedCount,
                          onRestrictiones: () => Navigator.pushNamed(
                              context, RouteNames.restrictionsList),
                          onNuevaRestriccion: () => Navigator.pushNamed(
                              context, RouteNames.restrictionCreate),
                          onHitos: () => Navigator.pushNamed(
                              context, RouteNames.controlHitos),
                          onActas: () => Navigator.pushNamed(
                              context, RouteNames.actaReuniones),
                        ),
                        const SizedBox(height: 14),

                        // ── 4. Fila de métricas ───────────────
                        _StatusSnapshotRow(
                          overdue:    overdueCount,
                          inProgress: inProgressCount,
                          pending:    pendingCount,
                          completed:  summary.completed,
                        ),
                        const SizedBox(height: 14),

                        // ── 5. Barra de cumplimiento ──────────
                        _ComplianceBar(
                          percent: compliance,
                          onAnalysis: () => Navigator.pushNamed(
                              context, RouteNames.restrictionsList),
                        ),
                        const SizedBox(height: 14),

                        // ── 6. Últimas finalizadas ────────────
                        if (completed3.isNotEmpty) ...[
                          _RecentClosures(
                            items: completed3,
                            onTap: () => Navigator.pushNamed(
                                context, RouteNames.completedRestrictions),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── 7. Chip de sincronización ─────────
                        if (showSyncChip)
                          _SyncChip(
                            sync: sync,
                            isBusy: controller.isBusy,
                            isOffline: isOffline,
                            onSync: controller.syncNow,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── 1. Header naranja sólido ──────────────────────────────────
class _CampoHeader extends StatelessWidget {
  const _CampoHeader({
    required this.user,
    required this.project,
    required this.projects,
    required this.onProjectChange,
    required this.onMenuSelected,
  });

  final UserProfile          user;
  final ProjectRecord        project;
  final List<ProjectRecord>  projects;
  final ValueChanged<int>    onProjectChange;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final initial = (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: _C.headerOrange,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila: Logo + título + avatar
              Row(
                children: [
                  const DirektorLogo(size: 36),
                  const SizedBox(width: 10),
                  const Text(
                    'DIREKTOR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Avatar con popup menu
                  PopupMenuButton<String>(
                    onSelected: onMenuSelected,
                    tooltip: user.fullName,
                    offset: const Offset(0, 44),
                    color: _C.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: _C.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _C.blue,
                        ),
                      ),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 16, color: _C.muted),
                            const SizedBox(width: 10),
                            Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : user.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _C.text,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'styles',
                        child: Row(
                          children: [
                            Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                            SizedBox(width: 8),
                            Text('Cambiar Estilo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _C.text,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 16, color: _C.red),
                            SizedBox(width: 10),
                            Text('Cerrar sesión',
                                style: TextStyle(
                                    color: _C.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nombre del proyecto (tappable)
              GestureDetector(
                onTap: () =>
                    _showProjectSheet(context, projects, project, onProjectChange),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.white,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.unfold_more_rounded,
                        size: 18, color: _C.white.withValues(alpha: 0.7)),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // Rol
              Text(
                project.roleLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: _C.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 2. Alerta de restricciones vencidas ───────────────────────
class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.overdueCount, required this.onTap});

  final int  overdueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _C.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.red.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _C.red, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠ $overdueCount restricciones VENCIDAS — acción requerida',
                style: const TextStyle(
                  color: _C.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _C.red, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 3. Grid de acciones rápidas 2×2 ──────────────────────────
class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.overdueCount,
    required this.inProgressCount,
    required this.delayedMilestones,
    required this.onRestrictiones,
    required this.onNuevaRestriccion,
    required this.onHitos,
    required this.onActas,
  });

  final int overdueCount;
  final int inProgressCount;
  final int delayedMilestones;
  final VoidCallback onRestrictiones;
  final VoidCallback onNuevaRestriccion;
  final VoidCallback onHitos;
  final VoidCallback onActas;

  @override
  Widget build(BuildContext context) {
    final totalPending = overdueCount + inProgressCount;

    return Column(
      children: [
        // Fila 1
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                color: _C.blue,
                icon: Icons.analytics_rounded,
                label: 'Ver Restricciones',
                badge: totalPending > 0 ? totalPending : null,
                onTap: onRestrictiones,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                color: _C.orange,
                icon: Icons.add_circle_rounded,
                label: 'Nueva Restricción',
                badge: null,
                onTap: onNuevaRestriccion,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fila 2
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                color: _C.blueDark,
                icon: Icons.flag_circle_rounded,
                label: 'Control de Hitos',
                badge: delayedMilestones > 0 ? delayedMilestones : null,
                onTap: onHitos,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                color: _C.teal,
                icon: Icons.groups_rounded,
                label: 'Actas / Reuniones',
                badge: null,
                onTap: onActas,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final Color    color;
  final IconData icon;
  final String   label;
  final int?     badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 90),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: _C.white),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Badge (top-right)
          if (badge != null)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: const BoxDecoration(
                  color: _C.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _C.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 4. Fila de métricas de estado ────────────────────────────
class _StatusSnapshotRow extends StatelessWidget {
  const _StatusSnapshotRow({
    required this.overdue,
    required this.inProgress,
    required this.pending,
    required this.completed,
  });

  final int overdue;
  final int inProgress;
  final int pending;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _MetricBox(
              value: overdue,
              label: 'Retrasadas',
              valueColor: _C.red),
          _vDivider(),
          _MetricBox(
              value: inProgress,
              label: 'Proceso',
              valueColor: _C.yellow),
          _vDivider(),
          _MetricBox(
              value: pending,
              label: 'Pendientes',
              valueColor: _C.muted),
          _vDivider(),
          _MetricBox(
              value: completed,
              label: 'Cerradas',
              valueColor: _C.green),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 40,
        color: _C.muted.withValues(alpha: 0.18),
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final int    value;
  final String label;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _C.muted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── 5. Barra de cumplimiento ──────────────────────────────────
class _ComplianceBar extends StatelessWidget {
  const _ComplianceBar({
    required this.percent,
    required this.onAnalysis,
  });

  final double percent;
  final VoidCallback onAnalysis;

  @override
  Widget build(BuildContext context) {
    final isGood  = percent >= 70;
    final barColor = isGood ? _C.green : _C.red;
    final pctLabel = '${percent.toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta + porcentaje
          Row(
            children: [
              const Text(
                'Cumplimiento:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.text,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                pctLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              minHeight: 14,
              backgroundColor: _C.muted.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          // CTA
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onAnalysis,
              child: const Text(
                'Ver análisis →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6. Últimas finalizadas ────────────────────────────────────
class _RecentClosures extends StatelessWidget {
  const _RecentClosures({
    required this.items,
    required this.onTap,
  });

  final List<RestrictionRecord> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimas finalizadas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.text,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((r) => _ClosureRow(item: r, onTap: onTap)),
        ],
      ),
    );
  }
}

class _ClosureRow extends StatelessWidget {
  const _ClosureRow({required this.item, required this.onTap});

  final RestrictionRecord item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = _fmtDate(item.conciliatedDate ?? item.requiredDate);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: _C.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.activity,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _C.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _C.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7. Chip de sincronización ─────────────────────────────────
class _SyncChip extends StatelessWidget {
  const _SyncChip({
    required this.sync,
    required this.isBusy,
    required this.isOffline,
    required this.onSync,
  });

  final SyncOverview sync;
  final bool         isBusy;
  final bool         isOffline;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final color  = isOffline ? _C.muted : _C.yellow;
    final label  = isOffline
        ? 'Sin conexión'
        : '${sync.pendingCount} cambio${sync.pendingCount == 1 ? '' : 's'} pendiente${sync.pendingCount == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.sync_problem_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (!isOffline)
            GestureDetector(
              onTap: isBusy ? null : onSync,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _C.white,
                        ),
                      )
                    : const Text(
                        'Sincronizar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom sheet: selector de proyecto ───────────────────────
void _showProjectSheet(
  BuildContext context,
  List<ProjectRecord> projects,
  ProjectRecord current,
  ValueChanged<int> onSelect,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _C.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _C.muted.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cambiar proyecto',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _C.text),
                ),
              ),
            ),
            ...projects.map((p) {
              final selected = p.id == current.id;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? _C.blue : _C.muted,
                  size: 20,
                ),
                title: Text(
                  p.name,
                  style: TextStyle(
                    color: selected ? _C.text : _C.muted,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  p.roleLabel,
                  style:
                      const TextStyle(fontSize: 11, color: _C.muted),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(p.id);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
