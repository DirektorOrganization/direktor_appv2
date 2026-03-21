import 'package:flutter/material.dart';

import 'o5_meeting_detail_screen.dart';

class O5SubcategoryScreen extends StatelessWidget {
  final String categoryTitle;

  const O5SubcategoryScreen({super.key, required this.categoryTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Categoría: $categoryTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registro Histórico de Actas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                ElevatedButton.icon(
                  onPressed: () {
                    // Create meeting dialog
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('NUEVA ACTA', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  columns: const [
                    DataColumn(label: Text('ID Acta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    DataColumn(label: Text('Tema / Título', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    DataColumn(label: Text('Asistencia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    DataColumn(label: Text('Acuerdos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                    DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                  ],
                  rows: [
                    _buildRow(context, 'ACT-012', 'Revisión Muros Anclados', '12 Nov 2026', 'Abierta', '3/4', '2 Pendientes', true),
                    _buildRow(context, 'ACT-011', 'Avance de Sótano 2', '05 Nov 2026', 'Cerrada', '5/5', '1 Pendiente', false),
                    _buildRow(context, 'ACT-010', 'Planificación Semanal', '28 Oct 2026', 'Cerrada', '6/6', 'Completados', false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, String id, String title, String date, String status, String attendance, String agreements, bool isOpen) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(title)),
        DataCell(Text(date)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: isOpen ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: isOpen ? Colors.green.shade700 : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        )),
        DataCell(Text(attendance)),
        DataCell(Text(agreements, style: TextStyle(color: isOpen ? Colors.orange.shade700 : Colors.grey))),
        DataCell(
          OutlinedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => O5MeetingDetailScreen(title: title)));
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: const Color(0xFF1F2937),
            ),
            child: const Text('ABRIR'),
          )
        ),
      ],
    );
  }
}
