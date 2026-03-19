import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';

class MeetingsListScreen extends StatelessWidget {
  const MeetingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final meetings = controller.meetings;
    final summary = controller.meetingSummary;

    return Scaffold(
      appBar: AppBar(title: const Text('Reuniones')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TopMetric(
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFD64545),
                      label: 'Acuerdos vencidos',
                      value: '${summary.overdueAgreements}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TopMetric(
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFFE4A620),
                      label: 'Acuerdos pendientes',
                      value: '${summary.pendingAgreements}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: meetings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = meetings[index];
                    return _MeetingCard(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopMetric extends StatelessWidget {
  const _TopMetric({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.item});

  final MeetingRecord item;

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
                    color: AppTheme.brandBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.groups_rounded, color: AppTheme.brandBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text('${item.category} / ${item.subCategory}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _MeetingStatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: AppTheme.muted),
                const SizedBox(width: 6),
                Text(_format(item.meetingDate), style: Theme.of(context).textTheme.bodySmall),
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

class _MeetingStatusBadge extends StatelessWidget {
  const _MeetingStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.brandBlue.withValues(alpha: 0.18)
            : AppTheme.brandBlue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.brandBlue)),
    );
  }
}

