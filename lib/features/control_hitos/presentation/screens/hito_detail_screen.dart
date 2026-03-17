import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../control_hitos_demo_store.dart';

class HitoDetailScreen extends StatelessWidget {
  const HitoDetailScreen({super.key, required this.milestoneId});

  final int milestoneId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.currentProject;
    final item = ControlHitosDemoStore.milestoneById(milestoneId);
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Hito no encontrado')));
    }

    final currentExtension = item.extensions.isEmpty ? null : item.extensions.last;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de hito')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A66B7), Color(0xFF0F7AD8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TopTag(icon: Icons.flag_outlined, label: item.typeLabel),
                        _TopTag(icon: Icons.folder_copy_outlined, label: item.classificationLabel),
                        _TopTag(icon: Icons.numbers_rounded, label: item.code),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(item.description, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      item.notes,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.84), fontSize: 11.8),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _TopBadge(
                          icon: milestoneStatusIcon(item.statusCode),
                          label: item.statusLabel,
                          color: milestoneStatusColor(item.statusCode),
                        ),
                        const SizedBox(width: 10),
                        _TopBadge(
                          icon: item.isSynced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
                          label: item.isSynced ? 'Sync' : 'Pendiente',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _DetailRow(icon: Icons.business_outlined, label: 'Proyecto', value: project?.name ?? '-'),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.event_available_outlined, label: 'Fecha contractual', value: _formatDate(item.contractualDate)),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.event_repeat_outlined, label: 'Fecha meta vigente', value: _formatDate(item.effectiveTargetDate)),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.task_alt_outlined, label: 'Fecha real', value: item.actualDate == null ? '-' : _formatDate(item.actualDate!)),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.payments_outlined, label: 'Penalidad', value: '${(item.penaltyPercent * 100).toStringAsFixed(2)}% | S/ ${item.penaltyAmount.toStringAsFixed(0)}'),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.attach_file_rounded, label: 'Documentos', value: '${item.documents.length} cargados'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _DetailRow(icon: Icons.schedule_send_outlined, label: 'Ampliacion vigente', value: currentExtension == null ? 'Sin ampliaciones registradas' : currentExtension.title),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.format_list_numbered_rounded, label: 'Numero de ampliaciones', value: '${item.extensionCount}'),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.insert_drive_file_outlined, label: 'Sustento', value: currentExtension == null ? '0 documentos' : currentExtension.supportDocument),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.controlHitosExtensions,
                        arguments: MilestoneExtensionsArgs(milestoneId: item.id),
                      ),
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Ampliaciones'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.controlHitosExtensionCreate,
                        arguments: MilestoneExtensionFormArgs(milestoneId: item.id),
                      ),
                      icon: const Icon(Icons.add_chart_rounded),
                      label: const Text('Nueva ampliacion'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.controlHitosEdit,
                    arguments: MilestoneFormArgs(milestoneId: item.id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar hito'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _TopTag extends StatelessWidget {
  const _TopTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color == Colors.white ? Colors.white.withValues(alpha: 0.14) : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppTheme.brandBlue.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: AppTheme.brandBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.2, fontWeight: FontWeight.w700, color: AppTheme.text),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerGap extends StatelessWidget {
  const _DividerGap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1),
    );
  }
}
