import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o9_comments_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Detalle de Acuerdo (vista / edición)
// ─────────────────────────────────────────────

class O9AgreementDetailScreen extends StatefulWidget {
  const O9AgreementDetailScreen({
    super.key,
    required this.id,
    required this.description,
    required this.responsible,
    required this.dueDate,
    required this.status,
    required this.group,
    required this.groupColor,
    required this.meetingDate,
    required this.comments,
    required this.deferrals,
    required this.onStatusChange,
  });

  final int id;
  final String description;
  final String responsible;
  final String dueDate;
  final String status;
  final String group;
  final Color groupColor;
  final String meetingDate;
  final int comments;
  final int deferrals;
  final Function(int, String) onStatusChange;

  @override
  State<O9AgreementDetailScreen> createState() => _O9AgreementDetailScreenState();
}

class _O9AgreementDetailScreenState extends State<O9AgreementDetailScreen> {
  late String _status;
  late String _dueDate;
  bool _editing = false;

  // Editable controllers
  late TextEditingController _descCtrl;
  late TextEditingController _respCtrl;
  late TextEditingController _dueCtrl;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _dueDate = widget.dueDate;
    _descCtrl = TextEditingController(text: widget.description);
    _respCtrl = TextEditingController(text: widget.responsible);
    _dueCtrl = TextEditingController(text: widget.dueDate);
  }

  @override
  void dispose() { _descCtrl.dispose(); _respCtrl.dispose(); _dueCtrl.dispose(); super.dispose(); }

  Color get _statusColor {
    switch (_status) {
      case 'completed': return const Color(0xFF1B8E5A);
      case 'overdue': return const Color(0xFFD64545);
      case 'in_progress': return AppTheme.brandBlue;
      default: return const Color(0xFFE4A620);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'completed': return 'Finalizado';
      case 'overdue': return 'Vencido';
      case 'in_progress': return 'En proceso';
      default: return 'Pendiente';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'overdue': return Icons.warning_amber_rounded;
      case 'in_progress': return Icons.timelapse_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  final _recentComments = [
    {'author': 'L. Torres', 'area': 'SST', 'text': 'Coordinaré la entrega formal con firma de cargo el jueves.', 'time': 'Hace 2 días'},
    {'author': 'P. Quispe', 'area': 'Logística', 'text': 'Puedo apoyar en la gestión del cargo de recepción.', 'time': 'Hace 18h'},
    {'author': 'Tú', 'area': 'Calidad', 'text': 'Confirmo disponibilidad. Adjunto el cargo firmado al cierre del jueves.', 'time': 'Hace 4h'},
  ];

  void _showDeferPicker() async {
    final parts = _dueDate.split('/');
    if (parts.length < 3) return;
    final initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Nueva fecha límite', confirmText: 'Aplazar', cancelText: 'Cancelar',
    );
    if (picked != null) {
      setState(() {
        _dueDate = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _dueCtrl.text = _dueDate;
      });
    }
  }

  void _changeStatus(String newStatus) {
    setState(() => _status = newStatus);
    widget.onStatusChange(widget.id, newStatus);
  }

  void _toggleEdit() => setState(() => _editing = !_editing);

  void _saveEdits() {
    setState(() {
      _dueDate = _dueCtrl.text.trim().isNotEmpty ? _dueCtrl.text.trim() : _dueDate;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final bg = isDark ? const Color(0xFF0F1923) : const Color(0xFFF3F6FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        title: Text(_editing ? 'Editar acuerdo' : 'Detalle de acuerdo', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: _editing ? _saveEdits : _toggleEdit,
            icon: Icon(_editing ? Icons.save_rounded : Icons.edit_rounded, size: 16),
            label: Text(_editing ? 'Guardar' : 'Editar', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status banner ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _statusColor.withOpacity(0.25)),
            ),
            child: Row(children: [
              Icon(_statusIcon, color: _statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_statusLabel, style: TextStyle(color: _statusColor, fontWeight: FontWeight.w800, fontSize: 15)),
                Text('Vence: $_dueDate', style: TextStyle(fontSize: 12, color: _statusColor.withOpacity(0.80))),
              ])),
              // Aplazar solo en modo edición
              if (_editing && _status != 'completed') OutlinedButton.icon(
                onPressed: _showDeferPicker,
                icon: const Icon(Icons.calendar_today_rounded, size: 14),
                label: const Text('Aplazar', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: _statusColor.withOpacity(0.50)), foregroundColor: _statusColor, minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 10)),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Descripción ──
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.stroke)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: widget.groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(widget.group, style: TextStyle(fontSize: 10, color: widget.groupColor, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 10),
              if (_editing)
                TextField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()))
              else
                Text(_descCtrl.text, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Meta / fields ──
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.stroke)),
            child: _editing
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(controller: _respCtrl, decoration: const InputDecoration(labelText: 'Responsable', prefixIcon: Icon(Icons.person_outline_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: _dueCtrl, decoration: const InputDecoration(labelText: 'Fecha límite (DD/MM/AAAA)', prefixIcon: Icon(Icons.calendar_today_rounded))),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.event_note_rounded, label: 'Origen (reunión)', value: widget.meetingDate),
                  if (widget.deferrals > 0) ...[
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.redo_rounded, label: 'Aplazos', value: '${widget.deferrals} veces', color: const Color(0xFFE4A620)),
                  ],
                ])
              : Column(children: [
                  _DetailRow(icon: Icons.person_outline_rounded, label: 'Responsable', value: _respCtrl.text),
                  const Divider(height: 20),
                  _DetailRow(icon: Icons.event_note_rounded, label: 'Origen (reunión)', value: widget.meetingDate),
                  const Divider(height: 20),
                  _DetailRow(icon: Icons.event_outlined, label: 'Fecha límite', value: _dueDate),
                  if (widget.deferrals > 0) ...[
                    const Divider(height: 20),
                    _DetailRow(icon: Icons.redo_rounded, label: 'Aplazos', value: '${widget.deferrals} veces', color: const Color(0xFFE4A620)),
                  ],
                ]),
          ),
          const SizedBox(height: 14),

          // ── Cambiar estado (solo modo edición) ──
          if (_editing) ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.stroke)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cambiar estado', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _StatusChip(label: 'Pendiente', value: 'pending', selected: _status == 'pending', color: const Color(0xFFE4A620), onTap: () => _changeStatus('pending')),
                  _StatusChip(label: 'En proceso', value: 'in_progress', selected: _status == 'in_progress', color: AppTheme.brandBlue, onTap: () => _changeStatus('in_progress')),
                  _StatusChip(label: 'Finalizado', value: 'completed', selected: _status == 'completed', color: const Color(0xFF1B8E5A), onTap: () => _changeStatus('completed')),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
          ],

          // ── Comentarios (solo modo vista) ──
          if (!_editing) ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.stroke)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Últimos comentarios', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9CommentsScreen(agreementTitle: widget.description, agreementGroup: widget.group, groupColor: widget.groupColor))),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text('Ver todos (${widget.comments + _recentComments.length})', style: const TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                  ),
                ]),
                const SizedBox(height: 10),
                ..._recentComments.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(radius: 12, backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
                        child: Text(c['author']!.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.brandBlue))),
                      const SizedBox(width: 7),
                      Text(c['author']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 5),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: AppTheme.stroke, borderRadius: BorderRadius.circular(4)),
                        child: Text(c['area']!, style: TextStyle(fontSize: 9, color: AppTheme.muted, fontWeight: FontWeight.w600))),
                      const Spacer(),
                      Text(c['time']!, style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                    ]),
                    const SizedBox(height: 6),
                    Text(c['text']!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.4)),
                  ]),
                )),
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9CommentsScreen(agreementTitle: widget.description, agreementGroup: widget.group, groupColor: widget.groupColor))),
                  icon: const Icon(Icons.chat_rounded, size: 16),
                  label: const Text('Ir al chat de comentarios'),
                )),
              ]),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value, this.color});
  final IconData icon; final String label; final String value; final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.muted;
    return Row(children: [
      Icon(icon, size: 16, color: c),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 12, color: AppTheme.muted)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? Theme.of(context).textTheme.bodyLarge?.color)),
    ]);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value, required this.selected, required this.color, required this.onTap});
  final String label; final String value; final bool selected; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? color : color.withOpacity(0.30)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : color, fontWeight: FontWeight.w700)),
    ),
  );
}
