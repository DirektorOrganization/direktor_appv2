import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

class CompletedRestrictionsScreen extends StatefulWidget {
  const CompletedRestrictionsScreen({super.key});

  @override
  State<CompletedRestrictionsScreen> createState() => _CompletedRestrictionsScreenState();
}

class _CompletedRestrictionsScreenState extends State<CompletedRestrictionsScreen> {
  final _searchController = TextEditingController();
  int _visibleCount = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final items = controller.completedRestrictions.where((item) {
      final query = _searchController.text.trim().toLowerCase();
      return query.isEmpty || item.activity.toLowerCase().contains(query) || item.front.toLowerCase().contains(query);
    }).take(_visibleCount).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Restricciones completadas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Buscar restriccion...', prefixIcon: Icon(Icons.search_rounded)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFD69E2E), borderRadius: BorderRadius.circular(16)),
              child: const Text('Sin conexion. Usando modo offline.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _CompletedCard(item: items[index]),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                child: const Text('Ver mas resultados'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.item});

  final RestrictionRecord item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_rounded, color: Color(0xFF1B8E5A)),
        title: Text(item.activity),
        subtitle: Text('Frente: ${item.front}\nFase: ${item.phase}\nResponsable: ${item.responsible}\nCompletada: ${_format(item.updatedAt)}'),
      ),
    );
  }

  String _format(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
