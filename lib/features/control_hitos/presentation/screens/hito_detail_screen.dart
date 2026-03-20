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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final project = controller.currentProject;
        final item = controller.findMilestoneById(milestoneId);
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Hito no encontrado')));
        }

        final currentExtension = item.extensions.isEmpty ? null : item.extensions.last;
        final theme = Theme.of(context);
        final topTags = <Widget>[
          if (item.typeLabel.trim().isNotEmpty) _TopTag(icon: Icons.flag_outlined, label: item.typeLabel),
          if (item.classificationLabel.trim().isNotEmpty) _TopTag(icon: Icons.folder_copy_outlined, label: item.classificationLabel),
        ];

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: topTags.isEmpty
                              ? const SizedBox.shrink()
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: topTags,
                                ),
                        ),
                        const SizedBox(width: 8),
                        _TopSyncBadge(synced: item.isSynced),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(item.description, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event_repeat_outlined, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Fecha meta: ${_formatDate(item.effectiveTargetDate)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ContractualStatusBadge(
                          isDelayed: item.isDelayed,
                          statusLabel: item.contractualStatusLabel,
                        ),
                        _TopPenaltyBadge(
                          isPenalizable: item.isPenalizable,
                          percent: item.penaltyPercent,
                          amount: item.penaltyAmount,
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
                      _DetailRow(
                        icon: milestoneStatusIcon(item.contractualStatusCode),
                        label: 'Estado contractual',
                        value: item.contractualStatusLabel,
                        accentColor: milestoneStatusColor(item.contractualStatusCode),
                      ),
                      const _DividerGap(),
                      _DetailRow(
                        icon: milestoneStatusIcon(item.internalStatusCode),
                        label: 'Estado interno',
                        value: item.internalStatusLabel,
                        accentColor: milestoneStatusColor(item.internalStatusCode),
                      ),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.event_available_outlined, label: 'Fecha contractual vigente', value: _formatDate(item.effectiveContractualDate)),
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
      },
    );
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _ContractualStatusBadge extends StatelessWidget {
  const _ContractualStatusBadge({
    required this.isDelayed,
    required this.statusLabel,
  });

  final bool isDelayed;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final color = isDelayed ? const Color(0xFFE46B6B) : milestoneStatusColorFromLabel(statusLabel);
    final label = isDelayed ? 'Retraso' : statusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDelayed ? Icons.warning_amber_rounded : milestoneStatusIconFromLabel(statusLabel),
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPenaltyBadge extends StatelessWidget {
  const _TopPenaltyBadge({
    required this.isPenalizable,
    required this.percent,
    required this.amount,
  });

  final bool isPenalizable;
  final double percent;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final hasPenalty = isPenalizable && percent > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasPenalty ? Icons.payments_outlined : Icons.shield_outlined,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            hasPenalty ? '${(percent * 100).toStringAsFixed(2)}% | S/ ${amount.toStringAsFixed(0)}' : 'Sin penalidad',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color milestoneStatusColorFromLabel(String statusLabel) {
  final value = statusLabel.toLowerCase();
  if (value.contains('complet')) return const Color(0xFF1B8E5A);
  if (value.contains('retras')) return const Color(0xFFD64545);
  return const Color(0xFFF0A11E);
}

IconData milestoneStatusIconFromLabel(String statusLabel) {
  final value = statusLabel.toLowerCase();
  if (value.contains('complet')) return Icons.check_circle_rounded;
  if (value.contains('retras')) return Icons.warning_amber_rounded;
  return Icons.timelapse_rounded;
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSyncBadge extends StatelessWidget {
  const _TopSyncBadge({required this.synced});

  final bool synced;

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
          Icon(
            synced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            synced ? 'Sync' : 'Pendiente',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (accentColor ?? AppTheme.brandBlue).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: accentColor ?? AppTheme.brandBlue),
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
