import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../../../app/state/app_scope.dart';
import 'o9_comments_screen.dart';

Color _groupTextColor(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.62 ? const Color(0xFF1F2937) : Colors.white;
}

Border? _groupChipBorder(Color background) {
  if (background.computeLuminance() <= 0.62) return null;
  return Border.all(color: const Color(0x33000000));
}

class O9AgreementGroupOption {
  const O9AgreementGroupOption({
    required this.id,
    required this.name,
    required this.color,
  });

  final int id;
  final String name;
  final Color color;
}

// ─────────────────────────────────────────────
// OPCIÓN 9 — Detalle de Acuerdo (vista / edición)
// ─────────────────────────────────────────────

class O9AgreementDetailScreen extends StatefulWidget {
  const O9AgreementDetailScreen({
    super.key,
    required this.id,
    required this.description,
    required this.responsible,
    this.responsibleParticipantId,
    required this.dueDate,
    required this.status,
    this.statusDisplayLabel,
    this.statusDisplayColor,
    this.groupId,
    required this.group,
    required this.groupColor,
    this.groupOptions = const [],
    this.responsibleOptions = const [],
    required this.meetingDate,
    required this.comments,
    required this.deferrals,
    this.readOnly = false,
    required this.onStatusChange,
    this.onGroupChange,
  });

  final int id;
  final String description;
  final String responsible;
  final int? responsibleParticipantId;
  final String dueDate;
  final String status;
  final String? statusDisplayLabel;
  final Color? statusDisplayColor;
  final int? groupId;
  final String group;
  final Color groupColor;
  final List<O9AgreementGroupOption> groupOptions;
  final List<String> responsibleOptions;
  final String meetingDate;
  final int comments;
  final int deferrals;
  final bool readOnly;
  final Function(int, String) onStatusChange;
  final void Function(int? groupId, String groupName, Color groupColor)?
  onGroupChange;

  @override
  State<O9AgreementDetailScreen> createState() =>
      _O9AgreementDetailScreenState();
}

class _O9AgreementDetailScreenState extends State<O9AgreementDetailScreen> {
  late String _status;
  late String _dueDate;
  late int? _groupId;
  late String _groupName;
  late Color _groupColor;
  bool _editing = false;

  // Editable controllers
  late TextEditingController _descCtrl;
  late TextEditingController _respCtrl;
  late TextEditingController _dueCtrl;
  final List<_DetailCommentItem> _recentComments = [];
  bool _loadingComments = false;
  bool _didLoadComments = false;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _dueDate = widget.dueDate;
    final resolvedGroup =
        widget.groupOptions
            .where((option) => option.id == widget.groupId)
            .firstOrNull ??
        widget.groupOptions
            .where((option) => option.name == widget.group)
            .firstOrNull;
    _groupId = resolvedGroup?.id ?? widget.groupId;
    _groupName = resolvedGroup?.name ?? widget.group;
    _groupColor = resolvedGroup?.color ?? widget.groupColor;
    _descCtrl = TextEditingController(text: widget.description);
    _respCtrl = TextEditingController(text: widget.responsible);
    _dueCtrl = TextEditingController(text: widget.dueDate);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _respCtrl.dispose();
    _dueCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadComments) return;
    _didLoadComments = true;
    _loadRecentComments();
  }

  Color get _statusColor {
    if (widget.statusDisplayColor != null) {
      return widget.statusDisplayColor!;
    }
    switch (_status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'info':
        return const Color(0xFF0A66B7);
      case 'in_progress':
        return const Color(0xFF0A66B7);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get _statusLabel {
    final custom = widget.statusDisplayLabel?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    switch (_status) {
      case 'completed':
        return 'Finalizado';
      case 'overdue':
        return 'Vencido';
      case 'info':
        return 'Informativo';
      case 'in_progress':
        return 'En proceso';
      default:
        return 'Pendiente';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'overdue':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline_rounded;
      case 'in_progress':
        return Icons.timelapse_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  /*
  final _recentComments = [
    {
      'author': 'L. Torres',
      'area': 'SST',
      'text': 'Coordinaré la entrega formal con firma de cargo el jueves.',
      'time': 'Hace 2 días',
    },
    {
      'author': 'P. Quispe',
      'area': 'Logística',
      'text': 'Puedo apoyar en la gestión del cargo de recepción.',
      'time': 'Hace 18h',
    },
    {
      'author': 'Tú',
      'area': 'Calidad',
      'text':
          'Confirmo disponibilidad. Adjunto el cargo firmado al cierre del jueves.',
      'time': 'Hace 4h',
    },
  ];

  */

  Future<void> _loadRecentComments() async {
    setState(() => _loadingComments = true);
    try {
      final controller = AppScope.of(context);
      final rows = await controller.loadActreuAgreementComments(widget.id);
      if (!mounted) return;
      final mapped =
          rows
              .map(
                (row) => _DetailCommentItem(
                  author: row.author.trim().isNotEmpty
                      ? row.author
                      : 'Participante',
                  text: row.message.trim(),
                  createdAt: row.createdAt,
                ),
              )
              .where((row) => row.text.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bAt.compareTo(aAt);
            });
      setState(() {
        _recentComments
          ..clear()
          ..addAll(mapped.take(3));
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDeferPicker() async {
    final parts = _dueDate.split('/');
    if (parts.length < 3) return;
    final initial = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Nueva fecha límite',
      confirmText: 'Aplazar',
      cancelText: 'Cancelar',
    );
    if (picked != null) {
      setState(() {
        _dueDate =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _dueCtrl.text = _dueDate;
      });
    }
  }

  void _changeStatus(String newStatus) {
    if (widget.readOnly) return;
    if (_status == 'info') return;
    setState(() => _status = newStatus);
    widget.onStatusChange(widget.id, newStatus);
  }

  void _toggleEdit() {
    if (widget.readOnly) return;
    if (_status == 'info') return;
    setState(() => _editing = !_editing);
  }

  void _saveEdits() {
    final parsedDueDate = _parseUiDate(_dueCtrl.text.trim());
    if (parsedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha limite invalida (DD/MM/AAAA).')),
      );
      return;
    }
    final statusCode = _statusCodeFromKey(_status);
    if (statusCode == null) return;

    unawaited(
      AppScope.of(context).updateActreuAgreement(
        agreementId: widget.id,
        description: _descCtrl.text.trim().isEmpty
            ? widget.description
            : _descCtrl.text.trim(),
        dueDate: parsedDueDate,
        statusCode: statusCode,
        responsibleParticipantId: widget.responsibleParticipantId,
        groupId: _groupId,
      ),
    );
    setState(() {
      _dueDate = _dueCtrl.text.trim().isNotEmpty
          ? _dueCtrl.text.trim()
          : _dueDate;
      _editing = false;
    });
    widget.onGroupChange?.call(_groupId, _groupName, _groupColor);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    const surface = Colors.white;
    const bg = Color(0xFFF5FAFE);
    final isInformative = _status == 'info';
    final showDescription = controller.isCustomizedColumnVisible(
      'ACTAREUCOM',
      'desAcuerdo',
    );
    final showResponsible = controller.isCustomizedColumnVisible(
      'ACTAREUCOM',
      'responsable',
    );
    final showGroup = controller.isCustomizedColumnVisible(
      'ACTAREUCOM',
      'grupoAcuerdo',
    );
    final showDueDate = controller.isCustomizedColumnVisible(
      'ACTAREUCOM',
      'dayFechaLevantamiento',
    );
    final showDeferrals = controller.isCustomizedColumnVisible(
      'ACTAREUCOM',
      'numAplazos',
    );
    final showStatus = controller.isCustomizedColumnVisible(
      'ACTAREUCOM',
      'estado',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _editing ? 'Editar acuerdo' : 'Detalle de acuerdo',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0EAF6)),
        ),
        actions: [
          if (!isInformative && !widget.readOnly)
            TextButton.icon(
              onPressed: _editing ? _saveEdits : _toggleEdit,
              icon: Icon(
                _editing ? Icons.save_rounded : Icons.edit_rounded,
                size: 16,
                color: const Color(0xFF64748B),
              ),
              label: Text(
                _editing ? 'Guardar' : 'Editar',
                style: const TextStyle(fontSize: 12),
              ),
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
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showStatus)
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      if (showDueDate)
                        Text(
                          'Vence: $_dueDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: _statusColor.withValues(alpha: 0.80),
                          ),
                        ),
                    ],
                  ),
                ),
                // Aplazar solo en modo edición
                if (_editing && _status != 'completed')
                  OutlinedButton.icon(
                    onPressed: _showDeferPicker,
                    icon: const Icon(Icons.calendar_today_rounded, size: 14),
                    label: const Text(
                      'Aplazar',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _statusColor.withValues(alpha: 0.50),
                      ),
                      foregroundColor: _statusColor,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Descripción ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0EAF6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showGroup)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _groupColor,
                          borderRadius: BorderRadius.circular(6),
                          border: _groupChipBorder(_groupColor),
                        ),
                        child: Text(
                          _groupName,
                          style: TextStyle(
                            fontSize: 10,
                            color: _groupTextColor(_groupColor),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (showGroup && showDescription) const SizedBox(height: 10),
                if (showDescription && _editing)
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: controller.customizedColumnLabel(
                        'ACTAREUCOM',
                        'desAcuerdo',
                        'Descripción',
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  )
                else if (showDescription)
                  Text(
                    _descCtrl.text,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Meta / fields ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0EAF6)),
            ),
            child: _editing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showResponsible &&
                          widget.responsibleOptions.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue:
                              widget.responsibleOptions.contains(_respCtrl.text)
                              ? _respCtrl.text
                              : null,
                          decoration: InputDecoration(
                            labelText: controller.customizedColumnLabel(
                              'ACTAREUCOM',
                              'responsable',
                              'Responsable',
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                          items: widget.responsibleOptions
                              .map(
                                (name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _respCtrl.text = value);
                          },
                        )
                      else if (showResponsible)
                        TextField(
                          controller: _respCtrl,
                          decoration: InputDecoration(
                            labelText: controller.customizedColumnLabel(
                              'ACTAREUCOM',
                              'responsable',
                              'Responsable',
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                        ),
                      if (showResponsible && showGroup)
                        const SizedBox(height: 12),
                      if (showGroup)
                        DropdownButtonFormField<int>(
                          initialValue:
                              widget.groupOptions.any(
                                (option) => option.id == _groupId,
                              )
                              ? _groupId
                              : null,
                          decoration: InputDecoration(
                            labelText: controller.customizedColumnLabel(
                              'ACTAREUCOM',
                              'grupoAcuerdo',
                              'Grupo de acuerdo',
                            ),
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          items: widget.groupOptions
                              .map(
                                (option) => DropdownMenuItem<int>(
                                  value: option.id,
                                  child: Text(
                                    option.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final selected = widget.groupOptions
                                .where((option) => option.id == value)
                                .firstOrNull;
                            if (selected == null) return;
                            setState(() {
                              _groupId = selected.id;
                              _groupName = selected.name;
                              _groupColor = selected.color;
                            });
                          },
                        ),
                      if (showGroup && showDueDate) const SizedBox(height: 12),
                      if (showDueDate)
                        TextField(
                          controller: _dueCtrl,
                          decoration: InputDecoration(
                            labelText: controller.customizedColumnLabel(
                              'ACTAREUCOM',
                              'dayFechaLevantamiento',
                              'Fecha límite (DD/MM/AAAA)',
                            ),
                            prefixIcon: const Icon(
                              Icons.calendar_today_rounded,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.event_note_rounded,
                        label: 'Origen (reunión)',
                        value: widget.meetingDate,
                        ellipsis: true,
                      ),
                      if (widget.deferrals > 0 && showDeferrals) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.redo_rounded,
                          label: controller.customizedColumnLabel(
                            'ACTAREUCOM',
                            'numAplazos',
                            'Aplazos',
                          ),
                          value: '${widget.deferrals} veces',
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      if (showResponsible)
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: controller.customizedColumnLabel(
                            'ACTAREUCOM',
                            'responsable',
                            'Responsable',
                          ),
                          value: _respCtrl.text,
                        ),
                      if (showResponsible && showGroup)
                        const Divider(height: 20),
                      if (showGroup)
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: controller.customizedColumnLabel(
                            'ACTAREUCOM',
                            'grupoAcuerdo',
                            'Grupo de acuerdo',
                          ),
                          value: _groupName,
                          chipColor: _groupColor,
                        ),
                      const Divider(height: 20),
                      _DetailRow(
                        icon: Icons.event_note_rounded,
                        label: 'Origen (reunión)',
                        value: widget.meetingDate,
                        ellipsis: true,
                      ),
                      const Divider(height: 20),
                      if (showDueDate)
                        _DetailRow(
                          icon: Icons.event_outlined,
                          label: controller.customizedColumnLabel(
                            'ACTAREUCOM',
                            'dayFechaLevantamiento',
                            'Fecha límite',
                          ),
                          value: _dueDate,
                        ),
                      if (widget.deferrals > 0 && showDeferrals) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.redo_rounded,
                          label: controller.customizedColumnLabel(
                            'ACTAREUCOM',
                            'numAplazos',
                            'Aplazos',
                          ),
                          value: '${widget.deferrals} veces',
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 14),

          // ── Cambiar estado (solo modo edición) ──
          if (_editing && !isInformative && !widget.readOnly && showStatus) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0EAF6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.customizedColumnLabel(
                      'ACTAREUCOM',
                      'estado',
                      'Cambiar estado',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: 'Pendiente',
                        value: 'pending',
                        selected: _status == 'pending',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _changeStatus('pending'),
                      ),
                      _StatusChip(
                        label: 'En proceso',
                        value: 'in_progress',
                        selected: _status == 'in_progress',
                        color: const Color(0xFF0A66B7),
                        onTap: () => _changeStatus('in_progress'),
                      ),
                      _StatusChip(
                        label: 'Finalizado',
                        value: 'completed',
                        selected: _status == 'completed',
                        color: const Color(0xFF10B981),
                        onTap: () => _changeStatus('completed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Comentarios (solo modo vista) ──
          if (!_editing) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0EAF6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Últimos comentarios',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => O9CommentsScreen(
                              agreementId: widget.id,
                              agreementTitle: widget.description,
                              agreementGroup: _groupName,
                              groupColor: _groupColor,
                              readOnly: widget.readOnly,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: Text(
                          'Ver todos (${widget.comments})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_loadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_recentComments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Sin comentarios aún.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  else
                    ..._recentComments.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(
                                    0xFF0A66B7,
                                  ).withValues(alpha: 0.12),
                                  child: Text(
                                    c.author
                                        .split(' ')
                                        .where((w) => w.trim().isNotEmpty)
                                        .map((w) => w[0])
                                        .take(2)
                                        .join(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A66B7),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    c.author,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _timeAgo(c.createdAt),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.text,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => O9CommentsScreen(
                            agreementId: widget.id,
                            agreementTitle: widget.description,
                            agreementGroup: _groupName,
                            groupColor: _groupColor,
                            readOnly: widget.readOnly,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: const Text('Ir al chat de comentarios'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

DateTime? _parseUiDate(String value) {
  final parts = value.split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

int? _statusCodeFromKey(String key) {
  switch (key) {
    case 'pending':
      return 1;
    case 'in_progress':
      return 2;
    case 'completed':
      return 3;
    case 'overdue':
      return 4;
    case 'info':
      return 6;
    default:
      return null;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.chipColor,
    this.ellipsis = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final Color? chipColor;
  final bool ellipsis;

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF64748B);
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        if (chipColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(8),
              border: _groupChipBorder(chipColor!),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _groupTextColor(chipColor!),
              ),
            ),
          )
        else
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color ?? const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.fade,
              textAlign: TextAlign.right,
            ),
          ),
      ],
    );
  }
}

class _DetailCommentItem {
  const _DetailCommentItem({
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String author;
  final String text;
  final DateTime? createdAt;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
