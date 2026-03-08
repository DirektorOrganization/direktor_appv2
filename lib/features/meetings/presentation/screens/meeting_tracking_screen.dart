import 'package:flutter/material.dart';

class MeetingTrackingScreen extends StatelessWidget {
  const MeetingTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: const Text('Proxima reunion: 12 Mar 2026', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Card(child: ListTile(leading: Icon(Icons.assignment_turned_in_outlined), title: Text('Enviar planos actualizados'), subtitle: Text('Pendiente'))),
            const SizedBox(height: 12),
            const Card(child: ListTile(leading: Icon(Icons.assignment_turned_in_outlined), title: Text('Cerrar observaciones de seguridad'), subtitle: Text('Vencido'))),
          ],
        ),
      ),
    );
  }
}
