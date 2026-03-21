import 'package:flutter/material.dart';

import 'o5_subcategory_screen.dart';

class O5HubScreen extends StatelessWidget {
  const O5HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light neutral gray
      appBar: AppBar(
        title: const Text('Centro de Mando - Actas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937), // Dark slate
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar metrics
          Container(
            width: 280,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarMetric(title: 'Acuerdos Vencidos', count: '12', color: Colors.redAccent),
                _SidebarMetric(title: 'Acuerdos para Hoy', count: '5', color: Colors.orangeAccent),
                _SidebarMetric(title: 'Actas Pendientes de Firma', count: '3', color: Colors.blueAccent),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       // Open create modal
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('NUEVA ACTA', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Emerald green
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Directorio de Categorías', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _CategoryCard(title: 'Comité de Obra', meetings: 45, pending: 12, icon: Icons.maps_home_work),
                      _CategoryCard(title: 'Planificación (Lookahead)', meetings: 24, pending: 3, icon: Icons.calendar_month),
                      _CategoryCard(title: 'Seguridad y Salud', meetings: 18, pending: 8, icon: Icons.health_and_safety),
                      _CategoryCard(title: 'Calidad', meetings: 10, pending: 1, icon: Icons.verified),
                      _CategoryCard(title: 'Subcontratistas', meetings: 32, pending: 15, icon: Icons.handshake),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMetric extends StatelessWidget {
  final String title;
  final String count;
  final Color color;

  const _SidebarMetric({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold))),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int meetings;
  final int pending;
  final IconData icon;

  const _CategoryCard({required this.title, required this.meetings, required this.pending, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => O5SubcategoryScreen(categoryTitle: title)));
      },
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF6B7280)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Actas', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('$meetings', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Acuerdos Pend.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('$pending', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
