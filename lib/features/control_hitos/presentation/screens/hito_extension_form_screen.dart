import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../control_hitos_demo_store.dart';

class HitoExtensionFormScreen extends StatefulWidget {
  const HitoExtensionFormScreen({super.key, required this.milestoneId});

  final int milestoneId;

  @override
  State<HitoExtensionFormScreen> createState() => _HitoExtensionFormScreenState();
}

class _HitoExtensionFormScreenState extends State<HitoExtensionFormScreen> {
  late final TextEditingController _reasonController;
  DateTime? _newContractualDate;
  DateTime? _newTargetDate;
  String? _supportDocumentPath;
  String? _supportDocumentName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final record = controller.findMilestoneById(widget.milestoneId);
        if (record == null) {
          return const Scaffold(body: Center(child: Text('Hito no encontrado')));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Nueva ampliacion')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A66B7), Color(0xFF0F7AD8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TopTag(icon: Icons.flag_outlined, label: record.typeLabel),
                        _TopTag(icon: Icons.numbers_rounded, label: record.code),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      record.description,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registra el sustento y las nuevas fechas del hito.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 11.8,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.event_available_outlined,
                        label: 'Fecha contractual vigente',
                      value: _formatDate(record.effectiveContractualDate),
                      ),
                      const _DividerGap(),
                      _DetailRow(
                        icon: Icons.event_repeat_outlined,
                        label: 'Fecha meta vigente',
                        value: _formatDate(record.effectiveTargetDate),
                      ),
                      const _DividerGap(),
                      _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: 'Ampliaciones acumuladas',
                        value: '${record.extensionCount}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'DATOS DE AMPLIACION',
                child: Column(
                  children: [
                    TextField(
                      controller: _reasonController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Motivo / sustento *',
                        alignLabelWithHint: true,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Nueva fecha contractual',
                      value: _newContractualDate,
                      onTap: () => _pickDate(
                        initialDate: _newContractualDate ?? record.effectiveContractualDate,
                        onSelected: (value) => setState(() => _newContractualDate = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Nueva fecha meta',
                      value: _newTargetDate,
                      onTap: () => _pickDate(
                        initialDate: _newTargetDate ?? record.effectiveTargetDate,
                        onSelected: (value) => setState(() => _newTargetDate = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                title: 'DOCUMENTO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickSupportDocument,
                        icon: const Icon(Icons.attach_file_rounded),
                        label: Text(_supportDocumentName == null ? 'Seleccionar archivo' : 'Cambiar archivo'),
                      ),
                    ),
                    if (_supportDocumentName != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _supportDocumentName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          final navigator = Navigator.of(context);
                          setState(() => _saving = true);
                          try {
                            await controller.saveMilestoneExtension(
                              MilestoneExtensionDraft(
                                milestoneId: widget.milestoneId,
                                justification: _reasonController.text.trim(),
                                newContractualDate: _newContractualDate,
                                newTargetDate: _newTargetDate,
                                supportDocument: _supportDocumentPath ?? '',
                                dateType: 'both',
                              ),
                            );
                            if (!mounted) return;
                            navigator.pop();
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Guardar ampliacion'),
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

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _pickSupportDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final file = (result == null || result.files.isEmpty) ? null : result.files.first;
      if (file == null || !mounted) return;
      if (!_isAllowedDocument(file.name)) {
        _showPickerMessage('Selecciona un PDF, Word o imagen.');
        return;
      }
      setState(() {
        _supportDocumentPath = file.path ?? file.name;
        _supportDocumentName = file.name;
      });
    } on MissingPluginException {
      _showPickerMessage('Debes cerrar y volver a abrir la app para habilitar la carga de archivos.');
    }
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

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

  void _showPickerMessage(String message) {
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.text, fontSize: 15),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        child: Text(
          value == null ? '--/--/----' : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.8),
        ),
      ),
    );
  }
}

class _TopTag extends StatelessWidget {
  const _TopTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.brandBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppTheme.brandBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerGap extends StatelessWidget {
  const _DividerGap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1),
    );
  }
}
