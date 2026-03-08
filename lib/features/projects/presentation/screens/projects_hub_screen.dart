import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/direktor_logo.dart';

class ProjectsHubScreen extends StatefulWidget {
  const ProjectsHubScreen({super.key});

  @override
  State<ProjectsHubScreen> createState() => _ProjectsHubScreenState();
}

class _ProjectsHubScreenState extends State<ProjectsHubScreen> {
  final _projects = const ['Proyecto A', 'Proyecto B', 'Proyecto C'];
  String _currentProject = 'Proyecto A';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeader(
                currentProject: _currentProject,
                onMenuSelected: (value) {
                  if (value == 'logout') {
                    Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
                  }
                },
                onChangeProject: _showProjects,
              ),
              const SizedBox(height: 20),
              Text('Resumen del proyecto', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _ModuleSummaryCard(
                icon: Icons.analytics_rounded,
                iconColor: AppTheme.brandBlue,
                accentColor: AppTheme.brandBlue,
                title: 'Analisis de restricciones',
                subtitle: 'Cumplimiento operativo del proyecto actual',
                progress: 0.72,
                footer: '72% de cumplimiento general',
                indicators: const [
                  _MetricItem(icon: Icons.error_rounded, color: Color(0xFFD64545), label: '3 retrasadas'),
                  _MetricItem(icon: Icons.timelapse_rounded, color: Color(0xFFE4A620), label: '5 progreso'),
                  _MetricItem(icon: Icons.pending_outlined, color: Color(0xFFB6BFCC), label: '5 pendientes'),
                ],
                primaryLabel: 'Ver analisis',
                onPrimaryPressed: () => Navigator.pushNamed(context, RouteNames.restrictionsList),
              ),
              const SizedBox(height: 14),
              _ModuleSummaryCard(
                icon: Icons.fact_check_outlined,
                iconColor: AppTheme.brandOrange,
                accentColor: AppTheme.brandOrange,
                title: 'Actas de reuniones',
                subtitle: 'Seguimiento de acuerdos y proximas sesiones',
                footer: 'Proxima reunion: 12 Mar',
                indicators: const [
                  _MetricItem(icon: Icons.warning_amber_rounded, color: Color(0xFFD64545), label: '8 acuerdos vencidos'),
                  _MetricItem(icon: Icons.schedule_rounded, color: Color(0xFFE4A620), label: '3 acuerdos pendientes'),
                ],
                primaryLabel: 'Seguimiento',
                secondaryLabel: 'Reuniones',
                onPrimaryPressed: () => Navigator.pushNamed(context, RouteNames.meetingTracking),
                onSecondaryPressed: () => Navigator.pushNamed(context, RouteNames.meetingsList),
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
                              color: AppTheme.brandBlue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.task_alt_rounded, color: AppTheme.brandBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ultimas restricciones completadas', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text('Ultimos cierres registrados', style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...const [
                        _RecentItem(label: 'Instalacion de tuberia', date: 'Hoy'),
                        _RecentItem(label: 'Validacion de planos', date: 'Ayer'),
                        _RecentItem(label: 'Entrega de materiales', date: '05 Mar'),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, RouteNames.completedRestrictions),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
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
  }

  void _showProjects() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          children: _projects
              .map(
                (project) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: project == _currentProject ? AppTheme.brandBlue.withOpacity(0.08) : Colors.white,
                    border: Border.all(
                      color: project == _currentProject ? AppTheme.brandBlue.withOpacity(0.24) : AppTheme.stroke,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    title: Text(project),
                    trailing: project == _currentProject ? Icon(Icons.check_circle_rounded, color: AppTheme.brandBlue) : null,
                    onTap: () {
                      setState(() => _currentProject = project);
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

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.currentProject,
    required this.onMenuSelected,
    required this.onChangeProject,
  });

  final String currentProject;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback onChangeProject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    Text('Hola, Diego', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      'Supervisor de obra',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.82)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onMenuSelected,
                color: Colors.white,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
                  PopupMenuItem(value: 'logout', child: Text('Cerrar sesion')),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proyecto actual',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.74)),
                      ),
                      const SizedBox(height: 4),
                      Text(currentProject, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onChangeProject,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.08),
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
}

class _ModuleSummaryCard extends StatelessWidget {
  const _ModuleSummaryCard({
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.indicators,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.progress,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String footer;
  final List<_MetricItem> indicators;
  final double? progress;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

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
                    color: accentColor.withOpacity(0.10),
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
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: indicators.map((item) => _IndicatorChip(item: item)).toList(),
            ),
            const SizedBox(height: 14),
            Text(footer, style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: FilledButton(onPressed: onPrimaryPressed, child: Text(primaryLabel))),
                if (secondaryLabel != null && onSecondaryPressed != null) ...[
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: onSecondaryPressed, child: Text(secondaryLabel!))),
                ],
              ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: item.color),
          const SizedBox(width: 6),
          Text(item.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.text)),
        ],
      ),
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
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF1B8E5A)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(date, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;
}

