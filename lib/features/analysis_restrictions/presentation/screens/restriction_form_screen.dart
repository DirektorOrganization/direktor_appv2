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
    _phaseId = item != null ? '${item.phaseId}' : catalogs.phases.firstOrNull?.id;
    _areaCode = item?.areaCode ?? catalogs.areas.firstOrNull?.id;
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
                      Text('Proyecto: ${project?.name ?? '-'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.84))),
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
                          onChanged: (value) => setState(() => _frontId = value),
                        ),
                        const SizedBox(height: 14),
                        _SelectField(
                          label: 'Fase *',
                          value: _phaseId,
                          icon: Icons.layers_outlined,
                          items: catalogs.phases,
                          onChanged: (value) => setState(() => _phaseId = value),
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
}

class _SelectField extends StatelessWidget {
  const _SelectField({required this.label, required this.value, required this.icon, required this.items, required this.onChanged});

  final String label;
  final String? value;
  final IconData icon;
  final List<CatalogOption> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }).toList();
      },
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item.id,
          child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
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
