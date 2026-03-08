import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';

class MeetingTrackingScreen extends StatelessWidget {
  const MeetingTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.meetingSummary;
    final agreements = controller.agreements;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF08392F), borderRadius: BorderRadius.circular(16)),
              child: Text(
                'Proxima reunion: ${_format(summary.nextMeetingDate)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: agreements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = agreements[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.assignment_turned_in_outlined,
                        color: item.isOverdue ? const Color(0xFFD64545) : const Color(0xFFF0A11E),
                      ),
                      title: Text(item.description),
                      subtitle: Text('${item.status} - ${item.responsible}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
