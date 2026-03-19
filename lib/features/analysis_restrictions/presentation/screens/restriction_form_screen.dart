import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

class RestrictionFormScreen extends StatefulWidget {
  const RestrictionFormScreen({super.key, required this.title, required this.args});

  final String title;
  final RestrictionFormArgs args;

  @override
  State<RestrictionFormScreen> createState() => _RestrictionFormScreenState();
}

class _RestrictionFormScreenState extends State<RestrictionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _restrictionController = TextEditingController();

  String? _frontId;
  String? _phaseId;
  String? _areaCode;
  String? _typeId;
  String? _responsibleId;
  String? _statusCode;
  DateTime _requiredDate = DateTime(2026, 3, 12);
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
    final controller = AppScope.of(context);
    final catalogs = controller.catalogs;
    final item = widget.args.restrictionId == null ? null : controller.findRestrictionById(widget.args.restrictionId!);

    _frontId = item != null ? '${item.frontId}' : catalogs.fronts.firstOrNull?.id;
    final initialPhases = catalogs.phases.where((phase) => phase.parentId == _frontId).toList();
    _phaseId = item != null ? '${item.phaseId}' : initialPhases.firstOrNull?.id;
    _areaCode = item?.areaCode == null ? catalogs.areas.firstOrNull?.id : 'anares:${item!.areaCode}';
    _typeId = item != null ? '${item.typeId}' : catalogs.types.firstOrNull?.id;
    _responsibleId = item != null ? '${item.responsibleId}' : catalogs.responsibles.firstOrNull?.id;
    _statusCode = item?.statusCode ?? catalogs.statuses.firstOrNull?.id ?? 'pending';
    _requiredDate = item?.requiredDate ?? DateTime.now().add(const Duration(days: 3));
    _activityController.text = item?.activity ?? '';
    _restrictionController.text = item?.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final catalogs = controller.catalogs;
    final project = controller.currentProject;
    final filteredPhases = catalogs.phases.where((phase) => phase.parentId == _frontId).toList();
    final resolvedPhaseId = filteredPhases.any((phase) => phase.id == _phaseId) ? _phaseId : filteredPhases.firstOrNull?.id;
    if (resolvedPhaseId != _phaseId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _phaseId = resolvedPhaseId);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Form(
            key: _formKey,
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
                      Text('Proyecto: ${project?.name ?? '-'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.84))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _SelectField(
                          label: 'Frente *',
                          value: _frontId,
                          icon: Icons.apartment_rounded,
                          items: catalogs.fronts,
                          onChanged: (value) => setState(() {
                            _frontId = value;
                            final phasesForFront = catalogs.phases.where((phase) => phase.parentId == value).toList();
                            _phaseId = phasesForFront.firstOrNull?.id;
                          }),
                          onAddPressed: project == null ? null : () => _createFront(project.id),
                          addLabel: 'Nuevo frente',
                        ),
                        const SizedBox(height: 14),
                        _SelectField(
                          label: 'Fase *',
                          value: resolvedPhaseId,
                          icon: Icons.layers_outlined,
                          items: filteredPhases,
                          onChanged: (value) => setState(() => _phaseId = value),
                          onAddPressed: project == null || _frontId == null ? null : () => _createPhase(project.id),
                          addLabel: 'Nueva fase',
                        ),
                        const SizedBox(height: 14),
                        _SelectField(
                          label: 'Area *',
                          value: _areaCode,
                          icon: Icons.domain_verification_outlined,
                          items: catalogs.areas,
                          onChanged: (value) => setState(() => _areaCode = value),
                        ),
                        const SizedBox(height: 14),
                        _InputField(label: 'Actividad *', icon: Icons.work_outline_rounded, controller: _activityController),
                        const SizedBox(height: 14),
                        _InputField(label: 'Restriccion *', icon: Icons.report_problem_outlined, controller: _restrictionController, maxLines: 4),
                        const SizedBox(height: 14),
                        _SelectField(
                          label: 'Tipo de restriccion *',
                          value: _typeId,
                          icon: Icons.category_outlined,
                          items: catalogs.types,
                          onChanged: (value) => setState(() => _typeId = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _DateField(value: _requiredDate, onTap: _pickDate),
                        const SizedBox(height: 14),
                        _SelectField(
                          label: 'Responsable *',
                          value: _responsibleId,
                          icon: Icons.person_outline_rounded,
                          items: catalogs.responsibles,
                          onChanged: (value) => setState(() => _responsibleId = value),
                        ),
                        const SizedBox(height: 14),
                        _SelectField(
                          label: 'Estado *',
                          value: _statusCode,
                          icon: Icons.flag_outlined,
                          items: catalogs.statuses,
                          onChanged: (value) => setState(() => _statusCode = value),
                        ),
                        const SizedBox(height: 14),
                        _ReadonlyField(label: 'Solicitante', value: controller.user?.fullName ?? 'Usuario local', icon: Icons.manage_accounts_outlined),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isBusy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _requiredDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (selected != null) {
      setState(() => _requiredDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    await controller.saveRestriction(
      RestrictionDraft(
        id: widget.args.restrictionId,
        frontId: _frontId!,
        phaseId: _phaseId!,
        areaCode: _areaCode!,
        activity: _activityController.text.trim(),
        description: _restrictionController.text.trim(),
        typeId: _typeId!,
        requiredDate: _requiredDate,
        responsibleId: _responsibleId!,
        statusCode: _statusCode!,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _createFront(int projectId) async {
    final name = await _showNameSheet(title: 'Nuevo frente', label: 'Nombre del frente');
    if (!mounted || name == null) return;
    final controller = AppScope.of(context);
    final newId = await controller.createRestrictionFront(projectId: projectId, name: name);
    if (!mounted || newId == null) return;
    setState(() {
      _frontId = newId;
      _phaseId = null;
    });
  }

  Future<void> _createPhase(int projectId) async {
    if (_frontId == null) return;
    final name = await _showNameSheet(title: 'Nueva fase', label: 'Nombre de la fase');
    if (!mounted || name == null) return;
    final controller = AppScope.of(context);
    final newId = await controller.createRestrictionPhase(projectId: projectId, frontId: _frontId!, name: name);
    if (!mounted || newId == null) return;
    setState(() => _phaseId = newId);
  }

  Future<String?> _showNameSheet({required String title, required String label}) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _NameInputSheet(title: title, label: label),
    );
  }
}

class _NameInputSheet extends StatefulWidget {
  const _NameInputSheet({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_NameInputSheet> createState() => _NameInputSheetState();
}

class _NameInputSheetState extends State<_NameInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.label),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final value = _controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.onAddPressed,
    this.addLabel,
  });

  final String label;
  final String? value;
  final IconData icon;
  final List<CatalogOption> items;
  final ValueChanged<String> onChanged;
  final VoidCallback? onAddPressed;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final uniqueItems = <CatalogOption>[];
    final seenIds = <String>{};
    for (final item in items) {
      if (item.id.isEmpty || seenIds.contains(item.id)) continue;
      seenIds.add(item.id);
      uniqueItems.add(item);
    }
    final resolvedValue = value != null && seenIds.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: resolvedValue,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
          selectedItemBuilder: (context) {
            return uniqueItems.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            }).toList();
          },
          items: uniqueItems.map((item) {
            return DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
        if (onAddPressed != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onAddPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0A66B7)),
                    const SizedBox(width: 4),
                    Text(
                      addLabel ?? 'Agregar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF0A66B7),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.label, required this.icon, required this.controller, this.maxLines = 1});

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) => value == null || value.trim().isEmpty ? 'Campo requerido' : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18), alignLabelWithHint: maxLines > 1),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha requerida *',
          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(formatted),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
      child: Text(value),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
