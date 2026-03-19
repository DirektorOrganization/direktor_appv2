import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../control_hitos_demo_store.dart';

class HitoExtensionsScreen extends StatelessWidget {
  const HitoExtensionsScreen({super.key, required this.milestoneId});

  final int milestoneId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final record = controller.findMilestoneById(milestoneId);
        final extensions = record?.extensions ?? const <MilestoneExtensionRecord>[];

        return Scaffold(
          appBar: AppBar(title: const Text('Lista de Ampliaciones')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
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
                        _TopTag(icon: Icons.timeline_rounded, label: '${extensions.length} ampliaciones'),
                        if (record != null) _TopTag(icon: Icons.numbers_rounded, label: record.code),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      record?.description ?? '-',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consulta el historial de ampliaciones y sus fechas vigentes.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 11.8,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (extensions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No hay ampliaciones registradas.', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                ...extensions.map(
                  (extension) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    extension.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandBlue.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatDate(extension.requestedAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.brandBlue,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailRow(
                              icon: Icons.event_repeat_outlined,
                              label: 'Fecha meta anterior',
                              value: _formatDate(extension.previousTargetDate),
                            ),
                            const _DividerGap(),
                            _DetailRow(
                              icon: Icons.event_available_outlined,
                              label: 'Nueva fecha contractual',
                              value: extension.newContractualDate == null ? '-' : _formatDate(extension.newContractualDate!),
                            ),
                            const _DividerGap(),
                            _DetailRow(
                              icon: Icons.flag_circle_outlined,
                              label: 'Nueva fecha meta',
                              value: _formatDate(extension.newTargetDate),
                            ),
                            const _DividerGap(),
                            _DetailRow(
                              icon: Icons.description_outlined,
                              label: 'Motivo',
                              value: extension.justification,
                            ),
                            const _DividerGap(),
                            _DetailRow(
                              icon: Icons.attach_file_rounded,
                              label: 'Documento',
                              value: extension.supportDocument.isEmpty ? '-' : extension.supportDocument,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.controlHitosExtensionCreate,
                    arguments: MilestoneExtensionFormArgs(milestoneId: milestoneId),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva ampliacion'),
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

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
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
          decoration: BoxDecoration(
            color: AppTheme.brandBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppTheme.brandBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
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
