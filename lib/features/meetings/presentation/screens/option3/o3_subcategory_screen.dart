import 'package:flutter/material.dart';

import 'o3_meeting_detail_screen.dart';

class O3SubcategoryScreen extends StatelessWidget {
  final String categoryTitle;
  final Color categoryColor;

  const O3SubcategoryScreen({super.key, required this.categoryTitle, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: Text(categoryTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MeetingCard(
            title: 'Revisión Muros Anclados',
            date: 'Hoy, 09:00 AM',
            status: 'En curso',
            statusColor: Colors.blueAccent,
            color: categoryColor,
          ),
          _MeetingCard(
            title: 'Avance Sótano 2',
            date: 'Mañana, 15:00 PM',
            status: 'Programada',
            statusColor: Colors.orangeAccent,
            color: categoryColor,
          ),
          _MeetingCard(
            title: 'Cierre Mensual de Obra',
            date: '10 Nov 2026',
            status: 'Finalizada',
            statusColor: Colors.greenAccent,
            color: categoryColor,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE4A620), // High vis
        onPressed: () {
          // Open create meeting sheet (similar to hub screen)
        },
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final Color statusColor;
  final Color color;

  const _MeetingCard({
    required this.title,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => O3MeetingDetailScreen(title: title)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ),
                Text(date, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => O3MeetingDetailScreen(title: title)));
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('ABRIR ACTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
