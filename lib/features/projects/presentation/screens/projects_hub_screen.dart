import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

class ProjectsHubScreen extends StatefulWidget {
  const ProjectsHubScreen({super.key});

  @override
  State<ProjectsHubScreen> createState() => _ProjectsHubScreenState();
}

class _ProjectsHubScreenState extends State<ProjectsHubScreen> {
  bool _redirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirected) return;
    final controller = AppScope.of(context);
    final style = controller.hubStyle ?? RouteNames.hubDefault;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushNamed(context, style);
    });
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
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        final currentUser = user;
        final currentProject = project;
        final summary = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final completedItems = controller.completedRestrictions
            .take(3)
            .toList();
        final sync = controller.syncOverview;
        final milestonesSummary = controller.milestoneSummary;
        final overdueCount = restrictions
            .where((item) => item.isOverdue && !item.isCompleted)
            .length;
        final inProgressCount = restrictions
            .where((item) => item.isInProgress && !item.isOverdue)
            .length;
        final pendingCount = restrictions
            .where((item) => item.isPending && !item.isOverdue)
            .length;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopHeader(
                    user: currentUser,
                    currentProject: currentProject,
                    projects: controller.projects,
                    onMenuSelected: (value) async {
                      if (value == 'profile') {
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, RouteNames.profile);
                        return;
                      }
                      if (value == 'styles') {
                        if (!context.mounted) return;
                        await showStylePicker(context);
                        return;
                      }
                      if (value == 'logout') {
                        await controller.logout();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          RouteNames.login,
                          (_) => false,
                        );
                      }
                    },
                    onChangeProject: (projectId) =>
                        controller.changeProject(projectId),
                  ),
                  const SizedBox(height: 14),
                  _SyncPanel(
                    sync: sync,
                    isBusy: controller.isBusy,
                    hasPendingItems: controller.hasPendingSyncItems,
                    syncAllOnNextManual: controller.syncAllOnNextManual,
                    onSyncNow: controller.syncNow,
                    onToggleSyncAll: controller.setSyncAllOnNextManual,
                    onToggleOffline: controller.setOfflineMode,
                    onToggleRemote: controller.setRemoteSyncEnabled,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Resumen del proyecto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _ModuleSummaryCard(
                    icon: Icons.analytics_rounded,
                    iconColor: AppTheme.brandBlue,
                    accentColor: AppTheme.brandBlue,
                    title: 'Analisis de restricciones',
                    subtitle: 'Cumplimiento operativo del proyecto actual',
                    indicators: [
                      _MetricItem(
                        icon: Icons.error_rounded,
                        color: const Color(0xFFD64545),
                        label: '$overdueCount retrasadas',
                      ),
                      _MetricItem(
                        icon: Icons.timelapse_rounded,
                        color: const Color(0xFFE4A620),
                        label: '$inProgressCount en proceso',
                      ),
                      _MetricItem(
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF1B8E5A),
                        label: '${summary.completed} finalizadas',
                      ),
                      _MetricItem(
                        icon: Icons.pending_outlined,
                        color: const Color(0xFFB6BFCC),
                        label: '$pendingCount pendientes',
                      ),
                    ],
                    primaryLabel: 'Ver analisis',
                    onPrimaryPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.restrictionsList,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MilestonesSummaryCard(
                    summary: milestonesSummary,
                    onOpen: () =>
                        Navigator.pushNamed(context, RouteNames.controlHitos),
                  ),
                  const SizedBox(height: 14),
                  _ModuleSummaryCard(
                    icon: Icons.groups_rounded,
                    iconColor: const Color(0xFF0A66B7),
                    accentColor: const Color(0xFF0A66B7),
                    title: 'Acta de reuniones',
                    subtitle: 'Vista operativa del modulo de reuniones',
                    progress: 0.0,
                    progressColor: const Color(0xFF0A66B7),
                    footer: 'Option 9 activa para revision visual',
                    indicators: const [
                      _MetricItem(
                        icon: Icons.view_quilt_rounded,
                        color: Color(0xFF0A66B7),
                        label: 'Panel ejecutivo',
                      ),
                      _MetricItem(
                        icon: Icons.event_available_rounded,
                        color: Color(0xFF1B8E5A),
                        label: 'Sesion en curso',
                      ),
                      _MetricItem(
                        icon: Icons.warning_amber_rounded,
                        color: Color(0xFFD64545),
                        label: 'Vencidos',
                      ),
                    ],
                    primaryLabel: 'Abrir actas',
                    onPrimaryPressed: () =>
                        Navigator.pushNamed(context, RouteNames.actaReuniones),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppTheme.brandBlue.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.task_alt_rounded,
                                  color: AppTheme.brandBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ultimas restricciones completadas',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ultimos cierres registrados',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (completedItems.isEmpty)
                            Text(
                              'No hay cierres recientes para este proyecto.',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            ...completedItems.map(
                              (item) => _RecentItem(
                                label: item.activity,
                                date: _formatRelativeDate(item.updatedAt),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RouteNames.completedRestrictions,
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: const Text('Ver mas'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatShortDate(DateTime? value) {
    if (value == null) return '-';
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]}';
  }

  String _formatRelativeDate(DateTime value) {
    final today = DateTime.now();
    final onlyToday = DateTime(today.year, today.month, today.day);
    final onlyValue = DateTime(value.year, value.month, value.day);
    final diff = onlyToday.difference(onlyValue).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return _formatShortDate(value);
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.user,
    required this.currentProject,
    required this.projects,
    required this.onMenuSelected,
    required this.onChangeProject,
  });

  final UserProfile user;
  final ProjectRecord currentProject;
  final List<ProjectRecord> projects;
  final ValueChanged<String> onMenuSelected;
  final ValueChanged<int> onChangeProject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A66B7), Color(0xFF0F7AD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DirektorLogo(size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${user.name}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentProject.roleLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onMenuSelected,
                color: isDark ? const Color(0xFF16202B) : Colors.white,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Text(
                      'Mi perfil',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.text,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'styles',
                    child: Row(
                      children: [
                        const Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                        const SizedBox(width: 8),
                        Text(
                          'Cambiar Estilo',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(
                      'Cerrar sesion',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.text,
                      ),
                    ),
                  ),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proyecto actual',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentProject.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showProjects(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProjects(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          children: projects
              .map(
                (project) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: project.id == currentProject.id
                        ? AppTheme.brandBlue.withValues(alpha: 0.08)
                        : Colors.white,
                    border: Border.all(
                      color: project.id == currentProject.id
                          ? AppTheme.brandBlue.withValues(alpha: 0.24)
                          : AppTheme.stroke,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    title: Text(project.name),
                    subtitle: Text(project.address),
                    trailing: project.id == currentProject.id
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.brandBlue,
                          )
                        : null,
                    onTap: () {
                      onChangeProject(project.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SyncPanel extends StatelessWidget {
  const _SyncPanel({
    required this.sync,
    required this.isBusy,
    required this.hasPendingItems,
    required this.syncAllOnNextManual,
    required this.onSyncNow,
    required this.onToggleSyncAll,
    required this.onToggleOffline,
    required this.onToggleRemote,
  });

  final SyncOverview sync;
  final bool isBusy;
  final bool hasPendingItems;
  final bool syncAllOnNextManual;
  final Future<void> Function() onSyncNow;
  final ValueChanged<bool> onToggleSyncAll;
  final Future<void> Function(bool) onToggleOffline;
  final Future<void> Function(bool) onToggleRemote;

  @override
  Widget build(BuildContext context) {
    final offlineEffective = sync.isOfflineEffective;
    final tone = offlineEffective
        ? const Color(0xFFD64545)
        : AppTheme.brandBlue;
    final summaryText = offlineEffective
        ? '${sync.pendingCount} pendientes en local'
        : sync.remoteSyncEnabled
        ? '${sync.pendingCount} pendientes para sincronizar'
        : '${sync.pendingCount} pendientes en cola';
    final modeText = sync.isOfflineForced
        ? 'Offline por falta de internet'
        : (sync.isOfflineMode
              ? 'Offline manual'
              : (sync.remoteSyncEnabled ? 'Remoto activo' : 'Solo local'));

    final syncInfoText = !sync.hasNetwork
        ? 'Sin internet. La cola sigue almacenandose localmente.'
        : !sync.apiConfigured
        ? 'Sin API configurada. No se puede enviar a sync_inbox.'
        : sync.lastSyncAt == null
        ? 'Aun no se registra una sincronizacion.'
        : 'Ultima sync: ${_formatDateTime(sync.lastSyncAt!)}';
    final canSyncNow =
        !isBusy &&
        !sync.isSyncing &&
        !offlineEffective &&
        sync.remoteSyncEnabled &&
        sync.apiConfigured &&
        (hasPendingItems || syncAllOnNextManual);

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              offlineEffective
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_sync_rounded,
              color: tone,
            ),
          ),
          title: Text(
            offlineEffective
                ? 'Operacion local en offline'
                : 'Sincronizacion operativa',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Text(
              '$summaryText - $modeText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          trailing: FilledButton.icon(
            onPressed: canSyncNow ? onSyncNow : null,
            icon: sync.isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded, size: 18),
            label: const Text('Sincronizar'),
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: '${sync.pendingCount} pendientes',
                  color: const Color(0xFFE4A620),
                  icon: Icons.cloud_upload_rounded,
                ),
                if (sync.failedCount > 0)
                  _StatusChip(
                    label: '${sync.failedCount} fallidas',
                    color: const Color(0xFFD64545),
                    icon: Icons.error_outline_rounded,
                  ),
                _StatusChip(
                  label: modeText,
                  color: offlineEffective
                      ? const Color(0xFFD64545)
                      : AppTheme.brandBlue,
                  icon: offlineEffective
                      ? Icons.wifi_off_rounded
                      : Icons.settings_ethernet_rounded,
                ),
                if (!sync.apiConfigured)
                  const _StatusChip(
                    label: 'API no configurada',
                    color: Color(0xFFD64545),
                    icon: Icons.link_off_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                syncInfoText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: syncAllOnNextManual,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Sincronizar todo en el proximo clic'),
              subtitle: const Text(
                'Solo afecta al boton Sincronizar. Descarga tambien tablas maestras y luego vuelve a apagarse.',
              ),
              onChanged: isBusy || sync.isOfflineForced || !sync.apiConfigured
                  ? null
                  : (value) => onToggleSyncAll(value ?? false),
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: sync.isOfflineMode,
              title: const Text('Trabajar en modo offline'),
              subtitle: Text(
                sync.isOfflineForced
                    ? 'Se activa automaticamente porque no hay internet.'
                    : 'Todo se guarda localmente y no intenta salir al backend.',
              ),
              onChanged: isBusy || sync.isOfflineForced
                  ? null
                  : onToggleOffline,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: sync.remoteSyncEnabled,
              title: const Text('Habilitar sincronizacion remota'),
              subtitle: Text(
                sync.apiConfigured
                    ? 'Permite enviar la cola al endpoint sync_inbox.'
                    : 'Configura DIREKTOR_API_BASE_URL para enviar al backend.',
              ),
              onChanged: isBusy || sync.isOfflineForced ? null : onToggleRemote,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Theme.of(context).textTheme.labelMedium?.color ?? AppTheme.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _ModuleSummaryCard extends StatelessWidget {
  const _ModuleSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.indicators,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.footer,
    this.progress,
    this.progressColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String? footer;
  final List<_MetricItem> indicators;
  final double? progress;
  final Color? progressColor;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: AppTheme.stroke,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor ?? accentColor,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: indicators
                  .map((item) => _IndicatorChip(item: item))
                  .toList(),
            ),
            if (footer != null && footer!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(footer!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryPressed,
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  const _IndicatorChip({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: item.color),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _MilestonesSummaryCard extends StatelessWidget {
  const _MilestonesSummaryCard({required this.summary, required this.onOpen});

  final MilestoneDashboardSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7AD8).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flag_circle_rounded,
                    color: Color(0xFF0F7AD8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Control de Hitos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Seguimiento contractual de hitos y penalidades',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MilestoneStatLine(
                    icon: Icons.timelapse_rounded,
                    color: const Color(0xFFE4A620),
                    label: 'En Progreso',
                    value: '${summary.inProgressCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MilestoneStatLine(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFD64545),
                    label: 'Vencidos',
                    value: '${summary.delayedCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MilestoneInlineInfo(
              icon: Icons.payments_outlined,
              color: const Color(0xFF1B8E5A),
              label: 'Penalidad acumulada',
              value: 'S/ ${summary.accumulatedPenalty.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 6),
            _MilestoneInlineInfo(
              icon: Icons.report_problem_outlined,
              color: const Color(0xFFD64545),
              label: 'Penalidad potencial',
              value: 'S/ ${summary.potentialPenalty.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _MilestoneInlineInfo(
                    icon: Icons.schedule_send_rounded,
                    color: AppTheme.brandBlue,
                    label: 'Ampliaciones',
                    value: '${summary.activeExtensions}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MilestoneInlineInfo(
                    icon: Icons.construction_rounded,
                    color: const Color(0xFF8A5A14),
                    label: 'Retrasos activos',
                    value: '${summary.activeDelayCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('Ver Hitos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneStatLine extends StatelessWidget {
  const _MilestoneStatLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _MilestoneInlineInfo extends StatelessWidget {
  const _MilestoneInlineInfo({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.text;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: foreground),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({required this.label, required this.date});

  final String label;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFF1B8E5A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(date, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

