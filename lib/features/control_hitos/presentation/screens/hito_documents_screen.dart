import 'package:flutter/material.dart';

import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../control_hitos_demo_store.dart';

class HitoDocumentsScreen extends StatelessWidget {
  const HitoDocumentsScreen({super.key, required this.milestoneId});

  final int milestoneId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final record = controller.findMilestoneById(milestoneId);
        final documents = record?.documents ?? const <MilestoneDocumentRecord>[];
        if (record == null) {
          return const Scaffold(body: Center(child: Text('Hito no encontrado')));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Documentos')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Hito: ${record.description}', style: Theme.of(context).textTheme.titleMedium),
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
                            Text('Ruta: ${doc.path}', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton(onPressed: () {}, child: const Text('Ver')),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () => controller.deleteMilestoneDocument(doc.id),
                                  child: const Text('Eliminar'),
                                ),
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
                  onPressed: () => _showUploadSheet(context, controller, record.id),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Subir documento'),
                ),
              ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Future<void> _showUploadSheet(BuildContext context, AppController controller, int milestoneId) async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo documento', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre del documento')),
              const SizedBox(height: 12),
              TextField(controller: pathController, decoration: const InputDecoration(labelText: 'Ruta o referencia')),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(sheetContext);
                    await controller.saveMilestoneDocument(
                      MilestoneDocumentDraft(
                        milestoneId: milestoneId,
                        name: nameController.text.trim(),
                        path: pathController.text.trim(),
                      ),
                    );
                    if (!sheetContext.mounted) return;
                    navigator.pop();
                  },
                  child: const Text('Guardar documento'),
                ),
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
    pathController.dispose();
  }
}
