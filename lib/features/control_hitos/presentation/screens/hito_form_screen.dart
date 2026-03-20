import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../control_hitos_demo_store.dart';

class HitoFormScreen extends StatefulWidget {
  const HitoFormScreen({super.key, required this.title, this.milestoneId});

  final String title;
  final int? milestoneId;

  bool get isEdit => milestoneId != null;

  @override
  State<HitoFormScreen> createState() => _HitoFormScreenState();
}

class _HitoFormScreenState extends State<HitoFormScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _penaltyPercentController;
  bool _loadedRecord = false;
  bool _saving = false;
  DateTime? _contractualDate;
  DateTime? _targetDate;
  DateTime? _actualDate;
  String? _selectedTypeCode;
  String? _selectedClassificationCode;
  bool _isPenalizable = true;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _penaltyPercentController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRecord) return;
    _loadedRecord = true;
    final controller = AppScope.of(context);
    final record = widget.milestoneId == null ? null : controller.findMilestoneById(widget.milestoneId!);
    _descriptionController.text = record?.description ?? '';
    _penaltyPercentController.text = record == null ? '' : (record.penaltyPercent * 100).toStringAsFixed(2);
    _contractualDate = record?.contractualDate;
    _targetDate = record?.effectiveTargetDate;
    _actualDate = record?.actualDate;
    _selectedTypeCode = record?.typeCode?.toString();
    _selectedClassificationCode = record?.classificationCode?.toString();
    _isPenalizable = record?.penaltyPercent != 0;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _penaltyPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.currentProject;
    final record = widget.milestoneId == null ? null : controller.findMilestoneById(widget.milestoneId!);
    final milestoneTypeItems = _resolveMilestoneTypeItems(controller, record);
    final milestoneClassificationItems = _resolveMilestoneClassificationItems(controller, record);
    final selectedTypeCode = _coerceSelectedCode(_selectedTypeCode, milestoneTypeItems);
    final selectedClassificationCode = _coerceSelectedCode(_selectedClassificationCode, milestoneClassificationItems);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A66B7), Color(0xFF0F7AD8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      'Proyecto: ${project?.name ?? 'Proyecto actual'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.84)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSection(
                title: 'INFORMACION GENERAL',
                child: Column(
                  children: [
                    TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripcion del hito *')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTypeCode,
                      items: milestoneTypeItems,
                      onChanged: (value) => setState(() => _selectedTypeCode = value),
                      decoration: const InputDecoration(labelText: 'Tipo de hito *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClassificationCode,
                      items: milestoneClassificationItems,
                      onChanged: (value) => setState(() => _selectedClassificationCode = value),
                      decoration: const InputDecoration(labelText: 'Clasificacion *'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                title: 'FECHAS',
                child: Column(
                  children: [
                    _DateField(
                      label: 'Fecha contractual *',
                      value: _contractualDate,
                      onTap: () => _pickDate(
                        initialDate: _contractualDate ?? DateTime.now(),
                        onSelected: (value) => setState(() => _contractualDate = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Fecha meta *',
                      value: _targetDate,
                      onTap: () => _pickDate(
                        initialDate: _targetDate ?? _contractualDate ?? DateTime.now(),
                        onSelected: (value) => setState(() => _targetDate = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: 'Fecha real',
                      value: _actualDate,
                      onTap: () => _pickDate(
                        initialDate: _actualDate ?? _targetDate ?? DateTime.now(),
                        onSelected: (value) => setState(() => _actualDate = value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                title: 'PENALIDAD',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: true, label: Text('Si')),
                        ButtonSegment<bool>(value: false, label: Text('No')),
                      ],
                      selected: {_isPenalizable},
                      onSelectionChanged: (value) => setState(() => _isPenalizable = value.first),
                    ),
                    if (_isPenalizable) ...[
                      const SizedBox(height: 12),
                      TextField(controller: _penaltyPercentController, decoration: const InputDecoration(labelText: '% penalidad')),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                title: 'ESTADO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (record == null)
                      Text(
                        'El estado se asignara automaticamente segun eventos del hito.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else ...[
                      _ReadonlyStatusTile(
                        label: 'Estado contractual',
                        statusCode: record.contractualStatusCode,
                        statusLabel: record.contractualStatusLabel,
                      ),
                      const SizedBox(height: 10),
                      _ReadonlyStatusTile(
                        label: 'Estado interno',
                        statusCode: record.internalStatusCode,
                        statusLabel: record.internalStatusLabel,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _FormSection(
                title: 'DOCUMENTOS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isEdit) ...[
                      Text('Evidencias cargadas', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('${record?.documents.length ?? 0} documentos', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showUploadSheet(context),
                            child: const Text('Subir documento'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (record == null) return;
                              Navigator.pushNamed(
                                context,
                                RouteNames.controlHitosDocuments,
                                arguments: MilestoneDocumentsArgs(milestoneId: record.id),
                              );
                            },
                            child: const Text('Ver documentos'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.isEdit && record != null) ...[
                const SizedBox(height: 14),
                _FormSection(
                  title: 'AMPLIACION',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ultima ampliacion', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        record.extensions.isEmpty ? 'Sin ampliaciones registradas' : 'Nueva meta: ${_formatDate(record.extensions.last.newTargetDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(record.extensions.isEmpty ? '0 sustento' : '1 sustento', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RouteNames.controlHitosExtensions,
                                arguments: MilestoneExtensionsArgs(milestoneId: record.id),
                              ),
                              child: const Text('Ver ampliaciones'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                RouteNames.controlHitosExtensionCreate,
                                arguments: MilestoneExtensionFormArgs(milestoneId: record.id),
                              ),
                              child: const Text('Nueva ampliacion'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (_contractualDate == null || _targetDate == null) return;
                          FocusScope.of(context).unfocus();
                          final navigator = Navigator.of(context);
                          setState(() => _saving = true);
                          try {
                            await controller.saveMilestone(
                              MilestoneDraft(
                                id: widget.milestoneId,
                                description: _descriptionController.text.trim(),
                                typeCode: selectedTypeCode ?? '',
                                classificationCode: selectedClassificationCode ?? '',
                                contractualDate: _contractualDate!,
                                targetDate: _targetDate!,
                                actualDate: _actualDate,
                                isPenalizable: _isPenalizable,
                                penaltyPercent: (double.tryParse(_penaltyPercentController.text.trim()) ?? 0) / 100,
                                internalStatusCode: record?.internalStatusCode ?? '1',
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
                  label: Text(_saving ? 'Guardando...' : (widget.isEdit ? 'Guardar cambios' : 'Guardar')),
                ),
              ),
            ],
          ),
        ),
      ),
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
    if (selected != null) onSelected(selected);
  }

  Future<void> _showUploadSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subir documento', style: Theme.of(sheetContext).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre del documento')),
                  const SizedBox(height: 12),
                  TextField(controller: pathController, readOnly: true, decoration: const InputDecoration(labelText: 'Archivo seleccionado')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
                      );
                      final file = (result == null || result.files.isEmpty) ? null : result.files.first;
                      if (file == null) return;
                      pathController.text = file.path ?? file.name;
                      if (nameController.text.trim().isEmpty) {
                        nameController.text = file.name;
                      }
                      setModalState(() {});
                    },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Seleccionar archivo'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Subir'),
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

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  List<DropdownMenuItem<String>> _resolveMilestoneTypeItems(AppController controller, MilestoneRecord? record) {
    final options = controller.milestoneTypes;
    return options.map((option) => DropdownMenuItem<String>(value: option.code, child: Text(option.label))).toList();
  }

  List<DropdownMenuItem<String>> _resolveMilestoneClassificationItems(AppController controller, MilestoneRecord? record) {
    final options = controller.milestoneClassifications;
    return options.map((option) => DropdownMenuItem<String>(value: option.code, child: Text(option.label))).toList();
  }

  String? _coerceSelectedCode(String? rawCode, List<DropdownMenuItem<String>> items) {
    final availableValues = items.map((item) => item.value).whereType<String>().toSet();
    if (rawCode != null && rawCode.isNotEmpty && availableValues.contains(rawCode)) {
      return rawCode;
    }
    return null;
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

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.text;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: titleColor, fontSize: 15),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReadonlyStatusTile extends StatelessWidget {
  const _ReadonlyStatusTile({
    required this.label,
    required this.statusCode,
    required this.statusLabel,
  });

  final String label;
  final String statusCode;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final color = milestoneStatusColor(statusCode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(milestoneStatusIcon(statusCode), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
