import 'package:flutter/material.dart';

import '../control_hitos_demo_store.dart';

class HitoDocumentsScreen extends StatelessWidget {
  const HitoDocumentsScreen({super.key, required this.milestoneId});

  final int milestoneId;

  @override
  Widget build(BuildContext context) {
    final record = ControlHitosDemoStore.milestoneById(milestoneId);
    final documents = record?.documents ?? const <MilestoneDocumentRecord>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hito: ${record?.description ?? '-'}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
              Text('EVIDENCIAS', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (documents.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('No hay documentos registrados.', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                ...documents.map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Subido: ${_formatDate(doc.uploadedAt)}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('Tipo: ${doc.typeLabel}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(onPressed: () {}, child: const Text('Ver')),
                                const SizedBox(width: 10),
                                OutlinedButton(onPressed: () {}, child: const Text('Eliminar')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Subir documento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
