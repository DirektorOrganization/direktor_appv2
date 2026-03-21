import 'package:flutter/material.dart';

import 'o4_meeting_detail_screen.dart';

class O4SubcategoryScreen extends StatelessWidget {
  final String processTitle;

  const O4SubcategoryScreen({super.key, required this.processTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(processTitle, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const Text('Historial y Próximas Sesiones', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 24),
          _TimelineNode(
            title: 'Revisión Muros Anclados #3',
            date: 'Hoy, 09:00 AM',
            status: 'En curso',
            isPast: false,
            isActive: true,
          ),
          _TimelineNode(
            title: 'Revisión Muros Anclados #2',
            date: 'La semana pasada',
            status: 'Cerrado - 3 Acuerdos',
            isPast: true,
            isActive: false,
          ),
          _TimelineNode(
            title: 'Revisión Muros Anclados #1',
            date: 'Hace 2 semanas',
            status: 'Cerrado - 1 Acuerdo',
            isPast: true,
            isActive: false,
            isLast: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F7AD8),
        onPressed: () {
          // Add new meeting node
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NUEVA SESIÓN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final bool isPast;
  final bool isActive;
  final bool isLast;

  const _TimelineNode({
    required this.title,
    required this.date,
    required this.status,
    required this.isPast,
    required this.isActive,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF0F7AD8) : (isPast ? Colors.green : Colors.grey),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 120,
                color: isActive ? const Color(0xFF0F7AD8) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => O4MeetingDetailScreen(title: title)));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? const Color(0xFF0F7AD8).withOpacity(0.5) : Colors.grey.shade200),
                boxShadow: isActive ? [BoxShadow(color: const Color(0xFF0F7AD8).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(date, style: TextStyle(color: isActive ? const Color(0xFF0F7AD8) : Colors.grey, fontWeight: FontWeight.bold)),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      else
                        Text(status, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  const SizedBox(height: 16),
                  if (isActive)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => O4MeetingDetailScreen(title: title)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7AD8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('GESTIONAR ACTA', style: TextStyle(color: Colors.white)),
                    ),
                  if (!isActive)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => O4MeetingDetailScreen(title: title)));
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('VER DETALLES', style: TextStyle(color: Colors.blueGrey)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
