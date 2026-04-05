// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

// ─── Palette (mirrors rv2 tablero) ────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const red         = Color(0xFFEF4444);
}

class RestrictionFormScreen extends StatefulWidget {
  const RestrictionFormScreen({super.key, required this.title, required this.args});
  final String title;
  final RestrictionFormArgs args;

  @override
  State<RestrictionFormScreen> createState() => _RestrictionFormScreenState();
}

class _RestrictionFormScreenState extends State<RestrictionFormScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _activityController  = TextEditingController();
  final _restrictionController = TextEditingController();

  String? _frontId;
  String? _phaseId;
  String? _areaCode;
  String? _typeId;
  String? _responsibleId;
  String? _statusCode;
  DateTime _requiredDate = DateTime.now().add(const Duration(days: 3));
  DateTime? _conciliatedDate;
  bool _requiredDatePicked = false; // true una vez que el usuario elige la fecha
  bool _isOverdue = false;          // true si la restricción editada está vencida
  bool _initialized = false;

  @override
  void dispose() {
    _activityController.dispose();
    _restrictionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final ctrl     = AppScope.of(context);
    final catalogs = ctrl.catalogs;
    final item     = widget.args.restrictionId == null ? null : ctrl.findRestrictionById(widget.args.restrictionId!);

    _frontId       = item != null ? '${item.frontId}' : catalogs.fronts.firstOrNull?.id;
    final phases   = catalogs.phases.where((p) => p.parentId == _frontId).toList();
    _phaseId       = item != null ? '${item.phaseId}' : phases.firstOrNull?.id;
    _areaCode      = item?.areaCode == null ? catalogs.areas.firstOrNull?.id : 'anares:${item!.areaCode}';
    _typeId        = item != null ? '${item.typeId}' : catalogs.types.firstOrNull?.id;
    _responsibleId = item != null ? '${item.responsibleId}' : catalogs.responsibles.firstOrNull?.id;
    _statusCode    = item?.statusCode ?? catalogs.statuses.firstOrNull?.id ?? 'pending';
    _requiredDate        = item?.requiredDate ?? DateTime.now().add(const Duration(days: 3));
    _conciliatedDate     = item?.conciliatedDate;
    _requiredDatePicked  = item != null; // en edición ya tiene fecha
    _isOverdue           = item?.isOverdue ?? false;
    _activityController.text    = item?.activity    ?? '';
    _restrictionController.text = item?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl     = AppScope.of(context);
    final catalogs = ctrl.catalogs;
    final project  = ctrl.currentProject;

    final filteredPhases   = catalogs.phases.where((p) => p.parentId == _frontId).toList();
    final resolvedPhaseId  = filteredPhases.any((p) => p.id == _phaseId) ? _phaseId : filteredPhases.firstOrNull?.id;
    if (resolvedPhaseId != _phaseId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _phaseId = resolvedPhaseId);
      });
    }

    final isEdit = widget.args.restrictionId != null;

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Header del proyecto ──────────────────────────────────────
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
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isEdit ? Icons.edit_rounded : Icons.add_task_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    if (project != null)
                      Text(project.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.80), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Sección: Ubicación ───────────────────────────────────────
            _FormSection(
              icon: Icons.place_rounded,
              title: 'Ubicación',
              children: [
                _FormField(
                  label: 'Frente *',
                  icon: Icons.layers_rounded,
                  action: project == null ? null : _AddAction(
                    label: 'Nuevo frente',
                    onTap: () => _createFront(project.id),
                  ),
                  child: _DropdownField(
                    value: _frontId,
                    items: catalogs.fronts,
                    hint: 'Seleccionar frente',
                    onChanged: (v) => setState(() {
                      _frontId = v;
                      final phasesForFront = catalogs.phases.where((p) => p.parentId == v).toList();
                      _phaseId = phasesForFront.firstOrNull?.id;
                    }),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Fase *',
                  icon: Icons.account_tree_rounded,
                  action: project == null || _frontId == null ? null : _AddAction(
                    label: 'Nueva fase',
                    onTap: () => _createPhase(project.id),
                  ),
                  child: _DropdownField(
                    value: resolvedPhaseId,
                    items: filteredPhases,
                    hint: 'Seleccionar fase',
                    onChanged: (v) => setState(() => _phaseId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Área *',
                  icon: Icons.domain_rounded,
                  child: _DropdownField(
                    value: _areaCode,
                    items: catalogs.areas,
                    hint: 'Seleccionar área',
                    onChanged: (v) => setState(() => _areaCode = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sección: Restricción ─────────────────────────────────────
            _FormSection(
              icon: Icons.report_problem_rounded,
              title: 'Detalle de la restricción',
              children: [
                _FormField(
                  label: 'Actividad *',
                  icon: Icons.work_outline_rounded,
                  child: TextFormField(
                    controller: _activityController,
                    style: const TextStyle(fontSize: 13, color: _D.text),
                    decoration: _inputDec('Nombre de la actividad'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Descripción *',
                  icon: Icons.notes_rounded,
                  child: TextFormField(
                    controller: _restrictionController,
                    style: const TextStyle(fontSize: 13, color: _D.text),
                    decoration: _inputDec('Describe la restricción…'),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Tipo *',
                  icon: Icons.category_outlined,
                  child: _DropdownField(
                    value: _typeId,
                    items: catalogs.types,
                    hint: 'Tipo de restricción',
                    onChanged: (v) => setState(() => _typeId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Sección: Planificación ───────────────────────────────────
            _FormSection(
              icon: Icons.schedule_rounded,
              title: 'Planificación',
              children: [
                _FormField(
                  label: 'Fecha requerida *',
                  icon: Icons.event_rounded,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: _D.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _D.stroke),
                      ),
                      child: Row(children: [
                        Expanded(child: Text(
                          '${_requiredDate.day.toString().padLeft(2, '0')}/${_requiredDate.month.toString().padLeft(2, '0')}/${_requiredDate.year}',
                          style: const TextStyle(fontSize: 13, color: _D.text, fontWeight: FontWeight.w500),
                        )),
                        const Icon(Icons.calendar_month_rounded, size: 16, color: _D.muted),
                      ]),
                    ),
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: _isOverdue && _conciliatedDate == null
                      ? 'Fecha conciliada  ⚠ vencida — conciliar para ampliar'
                      : 'Fecha conciliada',
                  icon: Icons.event_available_rounded,
                  child: Opacity(
                    opacity: _requiredDatePicked ? 1.0 : 0.45,
                    child: AbsorbPointer(
                      absorbing: !_requiredDatePicked,
                      child: GestureDetector(
                        onTap: _pickConciliatedDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: _isOverdue && _conciliatedDate == null
                                ? const Color(0xFFFFF3F3)
                                : _D.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _conciliatedDate != null
                                  ? _D.primary
                                  : _isOverdue
                                      ? _D.red
                                      : _D.stroke,
                              width: _isOverdue && _conciliatedDate == null ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(children: [
                            Expanded(child: Text(
                              _conciliatedDate != null
                                  ? '${_conciliatedDate!.day.toString().padLeft(2, '0')}/${_conciliatedDate!.month.toString().padLeft(2, '0')}/${_conciliatedDate!.year}'
                                  : _requiredDatePicked
                                      ? 'Toca para conciliar (opcional)'
                                      : 'Primero define la fecha requerida',
                              style: TextStyle(
                                fontSize: 13,
                                color: _conciliatedDate != null
                                    ? _D.text
                                    : _isOverdue
                                        ? _D.red
                                        : _D.mutedLight,
                                fontWeight: _conciliatedDate != null ? FontWeight.w500 : FontWeight.w400,
                              ),
                            )),
                            if (_conciliatedDate != null)
                              GestureDetector(
                                onTap: () => setState(() => _conciliatedDate = null),
                                child: const Icon(Icons.close_rounded, size: 14, color: _D.muted),
                              )
                            else
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: _isOverdue ? _D.red : _D.muted,
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Responsable *',
                  icon: Icons.person_outline_rounded,
                  child: _DropdownField(
                    value: _responsibleId,
                    items: catalogs.responsibles,
                    hint: 'Seleccionar responsable',
                    onChanged: (v) => setState(() => _responsibleId = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Estado *',
                  icon: Icons.flag_rounded,
                  child: _DropdownField(
                    value: _statusCode,
                    items: catalogs.statuses,
                    hint: 'Estado inicial',
                    onChanged: (v) => setState(() => _statusCode = v),
                    validator: (v) => v == null ? 'Requerido' : null,
                  ),
                ),
                const _FieldDivider(),
                _FormField(
                  label: 'Solicitante',
                  icon: Icons.manage_accounts_rounded,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: _D.stroke.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ctrl.user?.fullName ?? 'Usuario local',
                      style: const TextStyle(fontSize: 13, color: _D.muted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Guardar ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: ctrl.isBusy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _D.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: ctrl.isBusy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(isEdit ? 'Guardar cambios' : 'Crear restricción',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: _D.mutedLight),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.stroke)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.stroke)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.red, width: 1.5)),
    filled: true,
    fillColor: _D.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    isDense: true,
  );

  Future<void> _pickConciliatedDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _conciliatedDate ?? _requiredDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _D.primary, onPrimary: Colors.white, surface: _D.surface),
        ),
        child: child!,
      ),
    );
    if (selected != null) setState(() => _conciliatedDate = selected);
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _requiredDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _D.primary, onPrimary: Colors.white, surface: _D.surface),
        ),
        child: child!,
      ),
    );
    if (selected != null) setState(() { _requiredDate = selected; _requiredDatePicked = true; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = AppScope.of(context);
    await ctrl.saveRestriction(RestrictionDraft(
      id:               widget.args.restrictionId,
      frontId:          _frontId!,
      phaseId:          _phaseId!,
      areaCode:         _areaCode!,
      activity:         _activityController.text.trim(),
      description:      _restrictionController.text.trim(),
      typeId:           _typeId!,
      requiredDate:     _requiredDate,
      conciliatedDate:  _conciliatedDate,
      responsibleId:    _responsibleId!,
      statusCode:       _statusCode!,
    ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _createFront(int projectId) async {
    final name = await _showNameSheet(title: 'Nuevo frente', label: 'Nombre del frente');
    if (!mounted || name == null) return;
    final ctrl = AppScope.of(context);
    final newId = await ctrl.createRestrictionFront(projectId: projectId, name: name);
    if (!mounted || newId == null) return;
    setState(() { _frontId = newId; _phaseId = null; });
  }

  Future<void> _createPhase(int projectId) async {
    if (_frontId == null) return;
    final name = await _showNameSheet(title: 'Nueva fase', label: 'Nombre de la fase');
    if (!mounted || name == null) return;
    final ctrl = AppScope.of(context);
    final newId = await ctrl.createRestrictionPhase(projectId: projectId, frontId: _frontId!, name: name);
    if (!mounted || newId == null) return;
    setState(() => _phaseId = newId);
  }

  Future<String?> _showNameSheet({required String title, required String label}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameInputSheet(title: title, label: label),
    );
  }
}

// ─── Widgets de soporte ───────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.icon, required this.title, required this.children});
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
          child: Row(children: [
            Icon(icon, size: 15, color: _D.primary),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _D.primary, letterSpacing: 0.5)),
          ]),
        ),
        const Divider(height: 1, color: _D.stroke),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    ),
  );
}

class _FormField extends StatelessWidget {
  const _FormField({required this.label, required this.icon, this.action, required this.child});
  final String label;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 12, color: _D.mutedLight),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.muted, letterSpacing: 0.3)),
      ]),
      const SizedBox(height: 5),
      child,
      if (action != null) ...[const SizedBox(height: 4), action!],
    ],
  );
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(height: 1, color: _D.stroke),
  );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.validator,
  });
  final String? value;
  final List<CatalogOption> items;
  final String hint;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final unique = <CatalogOption>[];
    final seen   = <String>{};
    for (final it in items) {
      if (it.id.isEmpty || seen.contains(it.id)) continue;
      seen.add(it.id);
      unique.add(it);
    }
    final resolved = value != null && seen.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: resolved,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(fontSize: 13, color: _D.mutedLight)),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.stroke)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.stroke)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.red)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.red, width: 1.5)),
        filled: true,
        fillColor: _D.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: _D.text),
      dropdownColor: _D.surface,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _D.muted),
      selectedItemBuilder: (_) => unique.map((it) => Align(
        alignment: Alignment.centerLeft,
        child: Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _D.text)),
      )).toList(),
      items: unique.map((it) => DropdownMenuItem(
        value: it.id,
        child: Text(it.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      )).toList(),
      validator: validator,
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

class _AddAction extends StatelessWidget {
  const _AddAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.add_circle_outline_rounded, size: 14, color: _D.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _D.primary)),
      ]),
    ),
  );
}

// ─── Name Input Sheet ─────────────────────────────────────────────────────────
class _NameInputSheet extends StatefulWidget {
  const _NameInputSheet({required this.title, required this.label});
  final String title;
  final String label;

  @override
  State<_NameInputSheet> createState() => _NameInputSheetState();
}

class _NameInputSheetState extends State<_NameInputSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(); }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: _D.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _D.stroke, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _D.text)),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 13, color: _D.text),
          decoration: InputDecoration(
            hintText: widget.label,
            hintStyle: const TextStyle(color: _D.mutedLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.stroke)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.stroke)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _D.primary, width: 1.5)),
            filled: true,
            fillColor: _D.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: () {
              final v = _ctrl.text.trim();
              if (v.isEmpty) return;
              Navigator.of(context).pop(v);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _D.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}
