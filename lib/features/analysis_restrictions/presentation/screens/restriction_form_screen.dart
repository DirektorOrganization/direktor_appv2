import 'package:flutter/material.dart';

class RestrictionFormScreen extends StatefulWidget {
  const RestrictionFormScreen({super.key, required this.title});

  final String title;

  @override
  State<RestrictionFormScreen> createState() => _RestrictionFormScreenState();
}

class _RestrictionFormScreenState extends State<RestrictionFormScreen> {
  final _activityController = TextEditingController();
  final _restrictionController = TextEditingController();

  String _front = 'Torre A';
  String _phase = 'Estructuras';
  String _type = 'Permisos';
  String _responsible = 'Juan Perez';
  String _status = 'Pendiente';
  DateTime _requiredDate = DateTime(2026, 3, 12);

  final _fronts = const ['Torre A', 'Sotano 1', 'Lobby principal'];
  final _phases = const ['Estructuras', 'Instalaciones sanitarias', 'Acabados interiores'];
  final _types = const ['Permisos', 'Materiales', 'Planos'];
  final _responsibles = const ['Juan Perez', 'Carlos Ruiz', 'Maria Torres'];
  final _statuses = const ['Pendiente', 'En proceso', 'Completado'];

  @override
  void dispose() {
    _activityController.dispose();
    _restrictionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
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
                    Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Proyecto: Proyecto A', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.84))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _SelectField(label: 'Frente *', value: _front, icon: Icons.apartment_rounded, items: _fronts, onChanged: (value) => setState(() => _front = value)),
                      const SizedBox(height: 14),
                      _SelectField(label: 'Fase *', value: _phase, icon: Icons.layers_outlined, items: _phases, onChanged: (value) => setState(() => _phase = value)),
                      const SizedBox(height: 14),
                      _InputField(label: 'Actividad *', icon: Icons.work_outline_rounded, controller: _activityController),
                      const SizedBox(height: 14),
                      _InputField(label: 'Restriccion *', icon: Icons.report_problem_outlined, controller: _restrictionController, maxLines: 4),
                      const SizedBox(height: 14),
                      _SelectField(label: 'Tipo de restriccion *', value: _type, icon: Icons.category_outlined, items: _types, onChanged: (value) => setState(() => _type = value)),
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
                      _SelectField(label: 'Responsable *', value: _responsible, icon: Icons.person_outline_rounded, items: _responsibles, onChanged: (value) => setState(() => _responsible = value)),
                      const SizedBox(height: 14),
                      _SelectField(label: 'Estado *', value: _status, icon: Icons.flag_outlined, items: _statuses, onChanged: (value) => setState(() => _status = value)),
                      const SizedBox(height: 14),
                      const _ReadonlyField(label: 'Solicitante', value: 'Usuario logueado / automatico', icon: Icons.manage_accounts_outlined),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
            ],
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
}

class _SelectField extends StatelessWidget {
  const _SelectField({required this.label, required this.value, required this.icon, required this.items, required this.onChanged});

  final String label;
  final String value;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        alignLabelWithHint: maxLines > 1,
      ),
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
