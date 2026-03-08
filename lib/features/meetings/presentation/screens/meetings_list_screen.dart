import 'package:flutter/material.dart';

class MeetingsListScreen extends StatelessWidget {
  const MeetingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reuniones')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Card(child: ListTile(title: Text('Reunion semanal de obra'), subtitle: Text('12/03/2026 - Categoria: Produccion'))),
            SizedBox(height: 12),
            Card(child: ListTile(title: Text('Coordinacion tecnica'), subtitle: Text('15/03/2026 - Categoria: Ingenieria'))),
          ],
        ),
      ),
    );
  }
}
