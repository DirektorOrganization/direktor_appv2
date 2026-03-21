import 'package:flutter/material.dart';

import 'o3_subcategory_screen.dart';

class O3HubScreen extends StatelessWidget {
  const O3HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Field-First approach: High contrast, large touch targets
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background for high contrast in field
      appBar: AppBar(
        title: const Text('Reuniones (Campo)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Action Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE4A620), // High vis orange
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nueva Reunión', style: theme.textTheme.titleLarge?.copyWith(color: Colors.black87, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Registra un acta rápido', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 32),
                      onPressed: () => _showCreateMeetingBottomSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('ESPACIOS DE TRABAJO', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey.shade400, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _LargeCategoryCard(title: 'Comité de Obra', count: 5, color: Colors.blueAccent),
            _LargeCategoryCard(title: 'Sostenibilidad / SST', count: 2, color: Colors.greenAccent),
            _LargeCategoryCard(title: 'Gerencia y Finanzas', count: 8, color: Colors.purpleAccent),
            _LargeCategoryCard(title: 'Procura y Logística', count: 1, color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  void _showCreateMeetingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Crear Nueva Reunión', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Título de la reunión',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4A620))),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF3C3C3C),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Categoría',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
              ),
              items: ['Comité de Obra', 'Sostenibilidad / SST', 'Gerencia'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {},
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4A620),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('CREAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _LargeCategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _LargeCategoryCard({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => O3SubcategoryScreen(categoryTitle: title, categoryColor: color)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$count Subcategorías', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
