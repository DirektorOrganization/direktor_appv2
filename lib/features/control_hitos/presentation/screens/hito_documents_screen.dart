import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    var isSaving = false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  TextField(controller: pathController, readOnly: true, decoration: const InputDecoration(labelText: 'Archivo seleccionado')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            try {
                              final result = await FilePicker.platform.pickFiles(type: FileType.any);
                              if (!sheetContext.mounted) return;
                              final file = (result == null || result.files.isEmpty) ? null : result.files.first;
                              if (file == null) return;
                              if (!_isAllowedDocument(file.name)) {
                                _showUploadMessage(sheetContext, 'Selecciona un PDF, Word o imagen.');
                                return;
                              }
                              pathController.text = file.path ?? file.name;
                              if (nameController.text.trim().isEmpty) {
                                nameController.text = file.name;
                              }
                              setModalState(() {});
                            } on MissingPluginException {
                              if (!sheetContext.mounted) return;
                              _showUploadMessage(sheetContext, 'Debes cerrar y volver a abrir la app para habilitar la carga de archivos.');
                            }
                          },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Seleccionar archivo'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final navigator = Navigator.of(sheetContext);
                              setModalState(() => isSaving = true);
                              try {
                                await controller.saveMilestoneDocument(
                                  MilestoneDocumentDraft(
                                    milestoneId: milestoneId,
                                    name: nameController.text.trim(),
                                    path: pathController.text.trim(),
                                  ),
                                );
                                if (!sheetContext.mounted) return;
                                navigator.pop();
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar documento'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    pathController.dispose();
  }

  bool _isAllowedDocument(String fileName) {
    final normalized = fileName.toLowerCase();
    return normalized.endsWith('.pdf') ||
        normalized.endsWith('.doc') ||
        normalized.endsWith('.docx') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.webp');
  }

  void _showUploadMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
