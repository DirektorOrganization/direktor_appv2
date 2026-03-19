import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';

class MeetingTrackingScreen extends StatelessWidget {
  const MeetingTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.meetingSummary;
    final agreements = controller.agreements;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Seguimiento')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF08392F), Color(0xFF0B5B4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Proxima reunion: ${_format(summary.nextMeetingDate)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip(label: '${summary.overdueAgreements} vencidos', color: const Color(0xFFD64545), icon: Icons.warning_amber_rounded),
                            _StatChip(label: '${summary.pendingAgreements} pendientes', color: const Color(0xFFE4A620), icon: Icons.schedule_rounded),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: agreements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = agreements[index];
                        return _AgreementCard(
                          item: item,
                          onStatusChanged: controller.updateAgreementStatus,
                        );
                      },
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

  String _format(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _AgreementCard extends StatelessWidget {
  const _AgreementCard({required this.item, required this.onStatusChanged});

  final MeetingAgreementRecord item;
  final Future<void> Function(int, String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final status = item.isCompleted ? 'completed' : 'pending';
    final tone = item.isCompleted
        ? const Color(0xFF1B8E5A)
        : item.isOverdue
            ? const Color(0xFFD64545)
            : const Color(0xFFE4A620);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tone.withOpacity(isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assignment_turned_in_outlined, color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.description, style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _MiniInfo(icon: Icons.person_outline_rounded, text: item.responsible),
                _MiniInfo(icon: Icons.event_outlined, text: item.dueDate == null ? '-' : _format(item.dueDate!)),
                if (item.isOverdue) const _Badge(label: 'Vencido', color: Color(0xFFD64545), icon: Icons.error_rounded),
                if (item.isCompleted) const _Badge(label: 'Completado', color: Color(0xFF1B8E5A), icon: Icons.check_circle_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: status,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'completed', child: Text('Completado')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onStatusChanged(item.id, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, size: 0),
        Icon(icon, size: 13, color: AppTheme.muted),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

