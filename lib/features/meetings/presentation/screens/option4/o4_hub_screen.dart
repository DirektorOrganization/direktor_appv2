import 'package:flutter/material.dart';

import 'o4_subcategory_screen.dart';

class O4HubScreen extends StatelessWidget {
  const O4HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft blue-grey background
      appBar: AppBar(
        title: const Text('Tablero de Reuniones', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Process-oriented header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fase Actual: Estructuras', style: theme.textTheme.titleMedium?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('3 Reuniones programadas esta semana', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  ],
                ),
                FloatingActionButton.small(
                  onPressed: () => _startGuidedMeetingCreation(context),
                  backgroundColor: const Color(0xFF0F7AD8),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('PROCESOS ACTIVOS', style: theme.textTheme.labelMedium?.copyWith(color: Colors.blueGrey, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ProcessCard(title: 'Comité de Obra', progress: 0.8, openAgreements: 4, nextDate: 'Mañana, 09:00 AM'),
            _ProcessCard(title: 'Seguridad y Salud (SST)', progress: 0.5, openAgreements: 12, nextDate: 'Viernes, 15:00 PM'),
            _ProcessCard(title: 'Calidad y Entregas', progress: 0.9, openAgreements: 1, nextDate: 'Lunes, 10:00 AM'),
            const SizedBox(height: 32),
            Text('ACTIVIDAD RECIENTE', style: theme.textTheme.labelMedium?.copyWith(color: Colors.blueGrey, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _TimelineEvent(title: 'Acta Cerrada: Comité #12', time: 'Hace 2 horas', icon: Icons.check_circle, color: Colors.green),
            _TimelineEvent(title: 'Nuevo Acuerdo Asignado a: Carlos', time: 'Hace 4 horas', icon: Icons.assignment_ind, color: Colors.orange),
            _TimelineEvent(title: 'Reunión de Calidad Reprogramada', time: 'Ayer', icon: Icons.update, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  void _startGuidedMeetingCreation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar Nuevo Proceso de Acta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Selecciona el tipo de proceso a documentar:', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Reunión Ordinaria')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Auditoría o Inspección')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cierre de Fase')),
          ],
        ),
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  final String title;
  final double progress;
  final int openAgreements;
  final String nextDate;

  const _ProcessCard({required this.title, required this.progress, required this.openAgreements, required this.nextDate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => O4SubcategoryScreen(processTitle: title)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$openAgreements Acuerdos Pendientes', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(nextDate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF0F7AD8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _TimelineEvent({required this.title, required this.time, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
