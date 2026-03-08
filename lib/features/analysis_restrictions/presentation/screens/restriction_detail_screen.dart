import 'package:direktor_appv2/app/routes/route_arguments.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';

class RestrictionDetailScreen extends StatelessWidget {
  const RestrictionDetailScreen({super.key, required this.restrictionId});

  final int restrictionId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final item = controller.findRestrictionById(restrictionId);
    final project = controller.currentProject;
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Restriccion no encontrada')));
    }
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de restriccion')),
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
                    Text(item.activity, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.84), fontSize: 11.8),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _TopBadge(
                          icon: _statusIcon(item.statusCode),
                          label: item.statusLabel,
                          color: _statusColor(item.statusCode),
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
                      _DetailRow(icon: Icons.apartment_rounded, label: 'Frente', value: item.front),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.layers_outlined, label: 'Fase', value: item.phase),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.report_problem_outlined, label: 'Tipo de restriccion', value: item.type),
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
                      _DetailRow(icon: Icons.event_outlined, label: 'Fecha requerida', value: _formatDate(item.requiredDate)),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.person_outline_rounded, label: 'Responsable', value: item.responsible),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.manage_accounts_outlined, label: 'Solicitante', value: item.requester),
                      const _DividerGap(),
                      _DetailRow(icon: Icons.update_rounded, label: 'Ultima actualizacion', value: _formatDateTime(item.updatedAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.restrictionEdit,
                    arguments: RestrictionFormArgs(restrictionId: item.id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar restriccion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String statusCode) {
    switch (statusCode) {
      case 'overdue':
        return const Color(0xFFD64545);
      case 'in_progress':
        return const Color(0xFFF0A11E);
      case 'completed':
        return const Color(0xFF1B8E5A);
      default:
        return const Color(0xFF98A3B3);
    }
  }

  IconData _statusIcon(String statusCode) {
    switch (statusCode) {
      case 'overdue':
        return Icons.error_rounded;
      case 'in_progress':
        return Icons.timelapse_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.pending_outlined;
    }
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _formatDateTime(DateTime value) => '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
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
        color: color == Colors.white ? Colors.white.withOpacity(0.14) : color.withOpacity(0.16),
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
          decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
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
