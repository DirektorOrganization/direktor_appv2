import 'package:flutter/material.dart';

class CompletedRestrictionsScreen extends StatelessWidget {
  const CompletedRestrictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restricciones completadas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(hintText: 'Buscar restriccion...', prefixIcon: Icon(Icons.search_rounded))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFD69E2E), borderRadius: BorderRadius.circular(16)),
              child: const Text('Sin conexion. Usando modo offline.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _CompletedCard(title: 'Instalacion de tuberia', front: '2', phase: 'Acabados', responsible: 'Juan Perez', completedAt: 'Hoy 10:30'),
                    SizedBox(height: 12),
                    _CompletedCard(title: 'Validacion de planos', front: '1', phase: 'Estructura', responsible: 'Maria Torres', completedAt: 'Ayer'),
                  ],
                ),
              ),
            ),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: null, child: const Text('Ver mas resultados'))),
          ],
        ),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.title, required this.front, required this.phase, required this.responsible, required this.completedAt});

  final String title;
  final String front;
  final String phase;
  final String responsible;
  final String completedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_rounded),
        title: Text(title),
        subtitle: Text('Frente: $front - Fase: $phase\nResponsable: $responsible\nCompletada: $completedAt'),
      ),
    );
  }
}
