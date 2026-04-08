// ignore_for_file: lines_longer_than_80_chars
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7);
  static const accent      = Color(0xFF1167C8);
  static const accentLight = Color(0xFFCCDFF7);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const yellow      = Color(0xFFF59E0B);
  static const green       = Color(0xFF10B981);
  static const white       = Colors.white;
}

String _fmt(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Screen ───────────────────────────────────────────────────────────────────
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
  String?   _supportDocumentPath;
  String?   _supportDocumentName;
  bool      _saving = false;

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
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva Ampliación', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _D.text)),
                Text('Extender fechas del hito', style: TextStyle(fontSize: 11, color: _D.muted)),
              ],
            ),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _D.stroke)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              // ── Header card ───────────────────────────────────────────────
              _HeaderCard(record: record),
              const SizedBox(height: 16),

              // ── Fechas vigentes ───────────────────────────────────────────
              _FormSection(
                icon: Icons.event_note_rounded,
                title: 'FECHAS VIGENTES',
                child: Row(
                  children: [
                    Expanded(child: _InfoTile(label: 'Contractual', date: record.effectiveContractualDate, color: _D.primary, icon: Icons.gavel_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoTile(label: 'Meta', date: record.effectiveTargetDate, color: _D.accent, icon: Icons.flag_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoCountTile(label: 'Ampliaciones', count: record.extensionCount, color: _D.yellow, icon: Icons.update_rounded)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Nuevas fechas ─────────────────────────────────────────────
              _FormSection(
                icon: Icons.edit_calendar_rounded,
                title: 'NUEVAS FECHAS',
                child: Column(
                  children: [
                    _DatePickerField(
                      label: 'Nueva fecha contractual',
                      hint: 'Opcional',
                      value: _newContractualDate,
                      icon: Icons.gavel_rounded,
                      color: _D.primary,
                      onTap: () => _pickDate(
                        initial: _newContractualDate ?? record.effectiveContractualDate,
                        onPicked: (d) => setState(() => _newContractualDate = d),
                        clearable: true,
                        onCleared: () => setState(() => _newContractualDate = null),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DatePickerField(
                      label: 'Nueva fecha meta',
                      hint: 'Requerida para guardar',
                      value: _newTargetDate,
                      icon: Icons.flag_rounded,
                      color: _D.accent,
                      onTap: () => _pickDate(
                        initial: _newTargetDate ?? record.effectiveTargetDate,
                        onPicked: (d) => setState(() => _newTargetDate = d),
                        clearable: false,
                        onCleared: () {},
                      ),
                    ),
                    // Preview si se seleccionó alguna fecha
                    if (_newTargetDate != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: _D.green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: _D.green.withValues(alpha: 0.25))),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: _D.green),
                            const SizedBox(width: 8),
                            Text(
                              'Meta ampliada: ${_fmt(record.effectiveTargetDate)} → ${_fmt(_newTargetDate)}',
                              style: const TextStyle(fontSize: 11, color: _D.green, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Motivo ────────────────────────────────────────────────────
              _FormSection(
                icon: Icons.description_rounded,
                title: 'MOTIVO / SUSTENTO',
                child: Container(
                  decoration: BoxDecoration(
                    color: _D.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _D.stroke),
                  ),
                  child: TextField(
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 13, color: _D.text),
                    decoration: const InputDecoration(
                      hintText: 'Describe el motivo de la ampliación...',
                      hintStyle: TextStyle(color: _D.mutedLight, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Documento de sustento ─────────────────────────────────────
              _FormSection(
                icon: Icons.attach_file_rounded,
                title: 'DOCUMENTO DE SUSTENTO',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _saving ? null : _pickDocument,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _supportDocumentName != null ? _D.accentLight.withValues(alpha: 0.5) : _D.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _supportDocumentName != null ? _D.primary.withValues(alpha: 0.4) : _D.stroke,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: _D.accentLight, shape: BoxShape.circle),
                              child: const Icon(Icons.upload_file_rounded, size: 16, color: _D.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _supportDocumentName ?? 'Seleccionar archivo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _supportDocumentName != null ? _D.primary : _D.muted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _supportDocumentName != null ? 'PDF, Word o imagen · toca para cambiar' : 'PDF, Word o imagen (opcional)',
                                    style: const TextStyle(fontSize: 10, color: _D.mutedLight),
                                  ),
                                ],
                              ),
                            ),
                            if (_supportDocumentName != null)
                              GestureDetector(
                                onTap: () => setState(() { _supportDocumentPath = null; _supportDocumentName = null; }),
                                child: const Icon(Icons.close_rounded, size: 16, color: _D.muted),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ── Bottom save button ─────────────────────────────────────────────
          bottomNavigationBar: _SaveBar(
            saving: _saving,
            canSave: _newTargetDate != null && _reasonController.text.trim().isNotEmpty,
            onSave: () => _save(context, controller, record),
          ),
        );
      },
    );
  }

  Future<void> _pickDate({required DateTime initial, required void Function(DateTime) onPicked, required bool clearable, required VoidCallback onCleared}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (selected != null) onPicked(selected);
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final file   = (result == null || result.files.isEmpty) ? null : result.files.first;
      if (file == null || !mounted) return;
      if (!_isAllowed(file.name)) { _snack('Selecciona un PDF, Word o imagen.'); return; }
      setState(() { _supportDocumentPath = file.path ?? file.name; _supportDocumentName = file.name; });
    } on MissingPluginException {
      _snack('Cierra y vuelve a abrir la app para habilitar la carga de archivos.');
    }
  }

  Future<void> _save(BuildContext ctx, dynamic controller, MilestoneRecord record) async {
    if (_newTargetDate == null) { _snack('Define la nueva fecha meta.'); return; }
    if (_reasonController.text.trim().isEmpty) { _snack('Escribe el motivo de la ampliación.'); return; }
    FocusScope.of(ctx).unfocus();
    final navigator = Navigator.of(ctx);
    setState(() => _saving = true);
    try {
      await controller.saveMilestoneExtension(
        MilestoneExtensionDraft(
          milestoneId:        widget.milestoneId,
          justification:      _reasonController.text.trim(),
          newContractualDate: _newContractualDate,
          newTargetDate:      _newTargetDate,
          supportDocument:    _supportDocumentPath ?? '',
          dateType:           'both',
        ),
      );
      if (!mounted) return;
      navigator.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isAllowed(String n) {
    final l = n.toLowerCase();
    return l.endsWith('.pdf') || l.endsWith('.doc') || l.endsWith('.docx') ||
           l.endsWith('.jpg') || l.endsWith('.jpeg') || l.endsWith('.png') || l.endsWith('.webp');
  }

  void _snack(String msg) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}

// ─── Header Card ─────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.record});
  final MilestoneRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0852A3), Color(0xFF1580D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _D.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _Tag(icon: Icons.numbers_rounded, label: record.code),
              _Tag(icon: Icons.flag_outlined, label: record.typeLabel.isNotEmpty ? record.typeLabel : 'Hito'),
            ],
          ),
          const SizedBox(height: 12),
          Text(record.description, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _D.white, height: 1.3)),
          const SizedBox(height: 6),
          const Text('Registra el sustento y las nuevas fechas del hito.', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _D.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _D.white)),
        ],
      ),
    );
  }
}

// ─── Form Section ─────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  const _FormSection({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _D.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _D.stroke)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _D.muted),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _D.muted, letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Info Tiles ───────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.date, required this.color, required this.icon});
  final String label;
  final DateTime date;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 11, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))]),
          const SizedBox(height: 5),
          Text(_fmt(date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _InfoCountTile extends StatelessWidget {
  const _InfoCountTile({required this.label, required this.count, required this.color, required this.icon});
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 11, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color))]),
          const SizedBox(height: 5),
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1)),
        ],
      ),
    );
  }
}

// ─── Date Picker Field ────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.hint, required this.value, required this.icon, required this.color, required this.onTap});
  final String label;
  final String hint;
  final DateTime? value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = value != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: picked ? color.withValues(alpha: 0.05) : _D.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: picked ? color.withValues(alpha: 0.4) : _D.stroke, width: picked ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: picked ? color.withValues(alpha: 0.12) : _D.stroke, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: picked ? color : _D.muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: picked ? color : _D.muted)),
                  const SizedBox(height: 2),
                  Text(
                    picked ? _fmt(value) : hint,
                    style: TextStyle(fontSize: 13, fontWeight: picked ? FontWeight.w700 : FontWeight.w400, color: picked ? color : _D.mutedLight),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: picked ? color : _D.muted),
          ],
        ),
      ),
    );
  }
}

// ─── Save Bar ─────────────────────────────────────────────────────────────────
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.canSave, required this.onSave});
  final bool saving;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: _D.white, border: Border(top: BorderSide(color: _D.stroke))),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: canSave && !saving
                  ? [const Color(0xFF0852A3), const Color(0xFF1580D8)]
                  : [_D.stroke, _D.stroke],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: canSave && !saving
                ? [BoxShadow(color: _D.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: MaterialButton(
            onPressed: (canSave && !saving) ? onSave : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: _D.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 18, color: canSave ? _D.white : _D.muted),
                      const SizedBox(width: 8),
                      Text('Guardar ampliación', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: canSave ? _D.white : _D.muted)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
