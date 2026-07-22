// ignore_for_file: lines_longer_than_80_chars
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import 'conhit_customization.dart';
import '../control_hitos_demo_store.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE0EAF6);
  static const primary = Color(0xFF0A66B7);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
}

class HitoFormScreen extends StatefulWidget {
  const HitoFormScreen({super.key, required this.title, this.milestoneId});

  final String title;
  final int? milestoneId;

  bool get isEdit => milestoneId != null;

  @override
  State<HitoFormScreen> createState() => _HitoFormScreenState();
}

class _HitoFormScreenState extends State<HitoFormScreen> {
  final _descriptionController = TextEditingController();
  final _penaltyPercentController = TextEditingController();

  bool _loadedRecord = false;
  bool _saving = false;
  DateTime? _contractualDate;
  DateTime? _targetDate;
  DateTime? _actualDate;
  String? _selectedTypeCode;
  String? _selectedClassificationCode;
  bool _isPenalizable = true;
  String? _closureDocPath;
  String? _closureDocName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRecord) return;
    _loadedRecord = true;
    final controller = AppScope.of(context);
    final record = widget.milestoneId == null
        ? null
        : controller.findMilestoneById(widget.milestoneId!);
    _descriptionController.text = record?.description ?? '';
    _penaltyPercentController.text = record == null
        ? ''
        : (record.penaltyPercent * 100).toStringAsFixed(2);
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime? d) => d == null
      ? '--/--/----'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _D.primary,
            onPrimary: Colors.white,
            surface: _D.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null) onSelected(selected);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final canWrite = controller.canWriteProjectModule('CONHIT');
    final project = controller.currentProject;
    final record = widget.milestoneId == null
        ? null
        : controller.findMilestoneById(widget.milestoneId!);

    final typeItems = _resolveTypeItems(controller, record);
    final classificationItems = _resolveClassificationItems(controller, record);
    final selectedTypeCode = _coerceCode(_selectedTypeCode, typeItems);
    final selectedClassCode = _coerceCode(
      _selectedClassificationCode,
      classificationItems,
    );

    final generalApplies =
        controller.milestoneGeneral?.appliesToGeneral ?? false;
    final showPenalty = generalApplies && selectedClassCode == '2';

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A66B7), Color(0xFF1580D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isEdit ? Icons.edit_rounded : Icons.add_task_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (project != null)
                        Text(
                          project.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Sección: Información general ──────────────────────────────────
          _FormSection(
            icon: Icons.info_outline_rounded,
            title: 'Información general',
            children: [
              if (conhitColumnVisible(controller, ConHitColumns.description))
                _FormField(
                  label:
                      '${conhitColumnLabel(controller, ConHitColumns.description, 'Descripción del hito')} *',
                  icon: Icons.notes_rounded,
                  child: TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(fontSize: 13, color: _D.text),
                    decoration: _inputDec(
                      context,
                      'Ingresa la descripción del hito',
                    ),
                    maxLines: 2,
                  ),
                ),
              if (conhitColumnVisible(controller, ConHitColumns.description))
                const _FieldDivider(),
              if (conhitColumnVisible(controller, ConHitColumns.type))
                _FormField(
                  label:
                      '${conhitColumnLabel(controller, ConHitColumns.type, 'Tipo de hito')} *',
                  icon: Icons.category_outlined,
                  child: _ItemDropdownField(
                    value: selectedTypeCode,
                    items: typeItems,
                    hint: 'Seleccionar tipo',
                    onChanged: (v) => setState(() => _selectedTypeCode = v),
                  ),
                ),
              if (conhitColumnVisible(controller, ConHitColumns.type))
                const _FieldDivider(),
              if (conhitColumnVisible(controller, ConHitColumns.classification))
                _FormField(
                  label:
                      '${conhitColumnLabel(controller, ConHitColumns.classification, 'Clasificación')} *',
                  icon: Icons.bookmark_outline_rounded,
                  child: _ItemDropdownField(
                    value: selectedClassCode,
                    items: classificationItems,
                    hint: 'Seleccionar clasificación',
                    onChanged: (v) =>
                        setState(() => _selectedClassificationCode = v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Sección: Fechas ────────────────────────────────────────────────
          _FormSection(
            icon: Icons.calendar_today_rounded,
            title: 'Fechas',
            children: [
              if (conhitColumnVisible(
                controller,
                ConHitColumns.contractualDate,
              ))
                _FormField(
                  label:
                      '${conhitColumnLabel(controller, ConHitColumns.contractualDate, 'Fecha contractual')} *',
                  icon: Icons.event_rounded,
                  child: _DateTap(
                    value: _fmt(_contractualDate),
                    hasValue: _contractualDate != null,
                    onTap: () => _pickDate(
                      initial: _contractualDate,
                      onSelected: (d) => setState(() => _contractualDate = d),
                    ),
                  ),
                ),
              if (conhitColumnVisible(
                controller,
                ConHitColumns.contractualDate,
              ))
                const _FieldDivider(),
              if (conhitColumnVisible(controller, ConHitColumns.targetDate))
                _FormField(
                  label:
                      '${conhitColumnLabel(controller, ConHitColumns.targetDate, 'Fecha meta')} *',
                  icon: Icons.flag_rounded,
                  child: _DateTap(
                    value: _fmt(_targetDate),
                    hasValue: _targetDate != null,
                    onTap: () => _pickDate(
                      initial: _targetDate ?? _contractualDate,
                      onSelected: (d) => setState(() => _targetDate = d),
                    ),
                  ),
                ),
              if (conhitColumnVisible(controller, ConHitColumns.targetDate))
                const _FieldDivider(),
              if (conhitColumnVisible(controller, ConHitColumns.actualDate))
                _FormField(
                  label:
                      '${conhitColumnLabel(controller, ConHitColumns.actualDate, 'Fecha real')} — finalización del hito',
                  icon: Icons.check_circle_outline_rounded,
                  child: _DateTap(
                    value: _actualDate == null
                        ? 'Sin fecha real (opcional)'
                        : _fmt(_actualDate),
                    hasValue: _actualDate != null,
                    placeholder: true,
                    onTap: () => _pickDate(
                      initial: _actualDate ?? _targetDate,
                      onSelected: (d) => setState(() => _actualDate = d),
                    ),
                  ),
                ),
            ],
          ),

          // ── Evidencias de cierre ───────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _actualDate == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ClosureEvidenceSection(
                      docName: _closureDocName,
                      onPickDoc: _pickClosureDoc,
                      onClearDoc: () => setState(() {
                        _closureDocPath = null;
                        _closureDocName = null;
                      }),
                      onClearDate: () => setState(() {
                        _actualDate = null;
                        _closureDocPath = null;
                        _closureDocName = null;
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // ── Sección: Penalidad (condicional) ──────────────────────────────
          if (showPenalty) ...[
            _FormSection(
              icon: Icons.gavel_rounded,
              title: 'Penalidad',
              children: [
                _FormField(
                  label: '¿Aplica penalidad?',
                  icon: Icons.percent_rounded,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: true, label: Text('Sí')),
                      ButtonSegment<bool>(value: false, label: Text('No')),
                    ],
                    selected: {_isPenalizable},
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: _D.primary,
                      selectedForegroundColor: Colors.white,
                    ),
                    onSelectionChanged: (v) =>
                        setState(() => _isPenalizable = v.first),
                  ),
                ),
                if (_isPenalizable) ...[
                  const _FieldDivider(),
                  if (conhitColumnVisible(
                    controller,
                    ConHitColumns.penaltyPercent,
                  ))
                    _FormField(
                      label: conhitColumnLabel(
                        controller,
                        ConHitColumns.penaltyPercent,
                        '% de penalidad',
                      ),
                      icon: Icons.numbers_rounded,
                      child: TextFormField(
                        controller: _penaltyPercentController,
                        style: const TextStyle(fontSize: 13, color: _D.text),
                        decoration: _inputDec(context, 'Ej: 5.00'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Sección: Estado ────────────────────────────────────────────────
          _FormSection(
            icon: Icons.flag_outlined,
            title: 'Estado',
            children: [
              if (record == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'El estado se asignará automáticamente según los eventos del hito.',
                    style: const TextStyle(fontSize: 12, color: _D.muted),
                  ),
                )
              else ...[
                _ReadonlyStatusTile(
                  label: 'Estado contractual',
                  statusCode: record.contractualStatusCode,
                  statusLabel: conhitStatusLabel(
                    controller,
                    record.contractualStatusCode,
                    record.contractualStatusLabel,
                  ),
                  statusColor: conhitStatusColor(
                    controller,
                    record.contractualStatusCode,
                    milestoneStatusColor(record.contractualStatusCode),
                  ),
                ),
                const _FieldDivider(),
                _ReadonlyStatusTile(
                  label: 'Estado interno',
                  statusCode: record.internalStatusCode,
                  statusLabel: conhitStatusLabel(
                    controller,
                    record.internalStatusCode,
                    record.internalStatusLabel,
                  ),
                  statusColor: conhitStatusColor(
                    controller,
                    record.internalStatusCode,
                    milestoneStatusColor(record.internalStatusCode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Sección: Documentos ────────────────────────────────────────────
          _FormSection(
            icon: Icons.folder_open_rounded,
            title: 'Documentos',
            children: [
              if (widget.isEdit) ...[
                _FormField(
                  label: 'Evidencias cargadas',
                  icon: Icons.attach_file_rounded,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: _D.stroke.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${record?.documents.length ?? 0} documento(s) adjunto(s)',
                      style: const TextStyle(fontSize: 13, color: _D.muted),
                    ),
                  ),
                ),
                const _FieldDivider(),
              ],
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(
                      icon: Icons.upload_file_rounded,
                      label: 'Subir documento',
                      onTap: canWrite ? () => _showUploadSheet(context) : null,
                    ),
                  ),
                  if (widget.isEdit && record != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.visibility_outlined,
                        label: 'Ver documentos',
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.controlHitosDocuments,
                          arguments: MilestoneDocumentsArgs(
                            milestoneId: record.id,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // ── Sección: Ampliación (sólo edición) ────────────────────────────
          if (widget.isEdit && record != null) ...[
            const SizedBox(height: 12),
            _FormSection(
              icon: Icons.update_rounded,
              title: 'Ampliación',
              children: [
                _FormField(
                  label: 'Última ampliación',
                  icon: Icons.history_rounded,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: _D.stroke.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.extensions.isEmpty
                              ? 'Sin ampliaciones registradas'
                              : 'Nueva meta: ${_fmt(record.extensions.last.newTargetDate)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _D.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record.extensions.isEmpty
                              ? '0 sustentos'
                              : '${record.extensions.length} sustento(s)',
                          style: const TextStyle(fontSize: 11, color: _D.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                const _FieldDivider(),
                Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.list_alt_rounded,
                        label: 'Ver ampliaciones',
                        onTap: () => Navigator.pushNamed(
                          context,
                          RouteNames.controlHitosExtensions,
                          arguments: MilestoneExtensionsArgs(
                            milestoneId: record.id,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.add_rounded,
                        label: 'Nueva ampliación',
                        onTap: canWrite
                            ? () => Navigator.pushNamed(
                                context,
                                RouteNames.controlHitosExtensionCreate,
                                arguments: MilestoneExtensionFormArgs(
                                  milestoneId: record.id,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ── Guardar ────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: (!canWrite || _saving)
                  ? null
                  : () => _save(
                      context,
                      controller,
                      record,
                      selectedTypeCode,
                      selectedClassCode,
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: _D.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _saving
                    ? 'Guardando...'
                    : (!canWrite
                          ? 'Solo lectura'
                          : (widget.isEdit ? 'Guardar cambios' : 'Crear hito')),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _save(
    BuildContext context,
    AppController controller,
    MilestoneRecord? record,
    String? typeCode,
    String? classCode,
  ) async {
    if (_contractualDate == null || _targetDate == null) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar fecha contractual y fecha meta.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await controller.saveMilestone(
        MilestoneDraft(
          id: widget.milestoneId,
          description: _descriptionController.text.trim(),
          typeCode: typeCode ?? '',
          classificationCode: classCode ?? '',
          contractualDate: _contractualDate!,
          targetDate: _targetDate!,
          actualDate: _actualDate,
          isPenalizable: _isPenalizable,
          penaltyPercent:
              (double.tryParse(_penaltyPercentController.text.trim()) ?? 0) /
              100,
          internalStatusCode: record?.internalStatusCode ?? '1',
        ),
      );
      if (!mounted) return;
      navigator.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showUploadSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              decoration: const BoxDecoration(
                color: _D.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _D.stroke,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Subir documento',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _D.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    label: 'Nombre del documento',
                    icon: Icons.label_outline_rounded,
                    child: TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 13, color: _D.text),
                      decoration: _inputDec(ctx, 'Nombre del documento'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FormField(
                    label: 'Archivo seleccionado',
                    icon: Icons.attach_file_rounded,
                    child: GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const [
                            'pdf',
                            'doc',
                            'docx',
                            'jpg',
                            'jpeg',
                            'png',
                            'webp',
                          ],
                        );
                        final file = (result == null || result.files.isEmpty)
                            ? null
                            : result.files.first;
                        if (file == null) return;
                        pathController.text = file.path ?? file.name;
                        if (nameController.text.trim().isEmpty)
                          nameController.text = file.name;
                        setModal(() {});
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: _D.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _D.stroke),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.upload_file_rounded,
                              size: 16,
                              color: _D.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pathController.text.isEmpty
                                    ? 'Seleccionar archivo…'
                                    : pathController.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: pathController.text.isEmpty
                                      ? _D.mutedLight
                                      : _D.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: _D.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Subir',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

  Future<void> _pickClosureDoc() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final file = (result == null || result.files.isEmpty)
          ? null
          : result.files.first;
      if (file == null || !mounted) return;
      setState(() {
        _closureDocPath = file.path ?? file.name;
        _closureDocName = file.name;
      });
    } catch (_) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el selector de archivos.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ── Catalog helpers ────────────────────────────────────────────────────────

  List<DropdownMenuItem<String>> _resolveTypeItems(
    AppController ctrl,
    MilestoneRecord? _,
  ) => ctrl.milestoneTypes
      .map((o) => DropdownMenuItem<String>(value: o.code, child: Text(o.label)))
      .toList();

  List<DropdownMenuItem<String>> _resolveClassificationItems(
    AppController ctrl,
    MilestoneRecord? _,
  ) => ctrl.milestoneClassifications
      .map((o) => DropdownMenuItem<String>(value: o.code, child: Text(o.label)))
      .toList();

  String? _coerceCode(String? raw, List<DropdownMenuItem<String>> items) {
    final vals = items.map((i) => i.value).whereType<String>().toSet();
    return (raw != null && raw.isNotEmpty && vals.contains(raw)) ? raw : null;
  }
}

// ─── InputDecoration helper ───────────────────────────────────────────────────
InputDecoration _inputDec(BuildContext context, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: _D.mutedLight),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: _D.stroke),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: _D.stroke),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: _D.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: _D.red),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: _D.red, width: 1.5),
  ),
  filled: true,
  fillColor: _D.bg,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  isDense: true,
);

// ─── _FormSection ─────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.children,
  });
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _D.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _D.stroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            children: [
              Icon(icon, size: 15, color: _D.primary),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _D.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: _D.stroke),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}

// ─── _FormField ───────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.icon,
    required this.child,
  });
  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 12, color: _D.mutedLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _D.muted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      child,
    ],
  );
}

// ─── _FieldDivider ────────────────────────────────────────────────────────────
class _FieldDivider extends StatelessWidget {
  const _FieldDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: _D.stroke),
  );
}

// ─── _DateTap ─────────────────────────────────────────────────────────────────
class _DateTap extends StatelessWidget {
  const _DateTap({
    required this.value,
    required this.hasValue,
    required this.onTap,
    this.placeholder = false,
  });
  final String value;
  final bool hasValue;
  final bool placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasValue ? _D.primary : _D.stroke,
          width: hasValue ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: (placeholder && !hasValue) ? _D.mutedLight : _D.text,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          const Icon(Icons.calendar_month_rounded, size: 16, color: _D.muted),
        ],
      ),
    ),
  );
}

// ─── _ItemDropdownField ───────────────────────────────────────────────────────
class _ItemDropdownField extends StatelessWidget {
  const _ItemDropdownField({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final vals = items.map((i) => i.value).whereType<String>().toSet();
    final resolved = (value != null && vals.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: resolved,
      isExpanded: true,
      hint: Text(
        hint,
        style: const TextStyle(fontSize: 13, color: _D.mutedLight),
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _D.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _D.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _D.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _D.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _D.red, width: 1.5),
        ),
        filled: true,
        fillColor: _D.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: _D.text),
      dropdownColor: _D.surface,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: _D.muted,
      ),
      selectedItemBuilder: (_) => items
          .map(
            (i) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                i.child is Text ? (i.child as Text).data ?? '' : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _D.text),
              ),
            ),
          )
          .toList(),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ─── _OutlineBtn ──────────────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _D.stroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15,
            color: onTap == null ? _D.mutedLight : _D.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onTap == null ? _D.mutedLight : _D.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── _ReadonlyStatusTile ──────────────────────────────────────────────────────
class _ReadonlyStatusTile extends StatelessWidget {
  const _ReadonlyStatusTile({
    required this.label,
    required this.statusCode,
    required this.statusLabel,
    this.statusColor,
  });
  final String label;
  final String statusCode;
  final String statusLabel;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final color = statusColor ?? milestoneStatusColor(statusCode);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(milestoneStatusIcon(statusCode), size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _D.muted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13,
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

// ─── _ClosureEvidenceSection ──────────────────────────────────────────────────
class _ClosureEvidenceSection extends StatelessWidget {
  const _ClosureEvidenceSection({
    required this.docName,
    required this.onPickDoc,
    required this.onClearDoc,
    required this.onClearDate,
  });
  final String? docName;
  final VoidCallback onPickDoc;
  final VoidCallback onClearDoc;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final hasDoc = docName != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _D.green.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _D.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: _D.green,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hito finalizado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Adjunta la evidencia de cierre (opcional)',
                      style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClearDate,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: hasDoc ? onClearDoc : onPickDoc,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: hasDoc ? _D.green.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasDoc
                      ? _D.green.withValues(alpha: 0.4)
                      : const Color(0xFFD1FAE5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasDoc
                        ? Icons.insert_drive_file_rounded
                        : Icons.upload_file_rounded,
                    size: 18,
                    color: hasDoc ? _D.green : const Color(0xFF059669),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasDoc ? docName! : 'Seleccionar archivo de evidencia',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasDoc ? FontWeight.w600 : FontWeight.w400,
                        color: hasDoc
                            ? const Color(0xFF065F46)
                            : const Color(0xFF059669),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    hasDoc ? Icons.close_rounded : Icons.chevron_right_rounded,
                    size: hasDoc ? 16 : 18,
                    color: const Color(0xFF059669),
                  ),
                ],
              ),
            ),
          ),
          if (!hasDoc) ...[
            const SizedBox(height: 6),
            const Text(
              'PDF, imagen o Word · algunos hitos no requieren evidencia',
              style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7)),
            ),
          ],
        ],
      ),
    );
  }
}
