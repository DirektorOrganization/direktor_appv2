import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';

class MeetingsListScreen extends StatelessWidget {
  const MeetingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final meetings = controller.meetings;

    return Scaffold(
      appBar: AppBar(title: const Text('Reuniones')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView.separated(
          itemCount: meetings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = meetings[index];
            return Card(
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.brandBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.groups_rounded, color: AppTheme.brandBlue),
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${_format(item.meetingDate)} - ${item.category} / ${item.subCategory}',
                ),
                trailing: Text(
                  item.status,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _format(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
