import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    final record = ControlHitosDemoStore.milestoneById(widget.milestoneId);
    final lastExtension = record == null || record.extensions.isEmpty ? null : record.extensions.last;
    _reasonController = TextEditingController(text: lastExtension?.justification ?? '');
    _newContractualDate = lastExtension?.newTargetDate;
    _newTargetDate = lastExtension?.newTargetDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = ControlHitosDemoStore.milestoneById(widget.milestoneId);
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
                      value: _formatDate(record.contractualDate),
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
                        initialDate: _newContractualDate ?? record.contractualDate,
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
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Seleccionar archivo'),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar ampliacion'),
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
    if (selected != null) {
      onSelected(selected);
    }
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
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
