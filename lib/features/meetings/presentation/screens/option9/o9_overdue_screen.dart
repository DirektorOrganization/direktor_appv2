import 'package:flutter/material.dart';

import '../../../../../../app/state/app_scope.dart';
import 'o9_agreement_detail_screen.dart';

bool _actreuColumnVisible(BuildContext context, String columnKey) {
  return AppScope.of(
    context,
  ).isCustomizedColumnVisible('ACTAREUCOM', columnKey);
}

String _actreuColumnLabel(
  BuildContext context,
  String columnKey,
  String fallback,
) {
  return AppScope.of(
    context,
  ).customizedColumnLabel('ACTAREUCOM', columnKey, fallback);
}

class _O9OverdueAgreement {
  const _O9OverdueAgreement({
    required this.id,
    required this.desc,
    required this.resp,
    required this.due,
    required this.source,
    required this.group,
    required this.groupColor,
    this.statusLabel,
    this.statusColor,
    required this.daysOverdue,
    required this.deferrals,
    required this.comments,
  });

  final int id;
  final String desc;
  final String resp;
  final String due;
  final String source;
  final String group;
  final Color groupColor;
  final String? statusLabel;
  final Color? statusColor;
  final int daysOverdue;
  final int deferrals;
  final int comments;
}

class O9OverdueScreen extends StatefulWidget {
  const O9OverdueScreen({super.key});

  @override
  State<O9OverdueScreen> createState() => _O9OverdueScreenState();
}

class _O9OverdueScreenState extends State<O9OverdueScreen> {
  String _filterSource = 'Todos';
  String _filterResp = 'Todos';
  String _filterGroup = 'Todos';
  String _sortBy = 'Más vencidos';
  String _searchQuery = '';
  bool _isSearching = false;
  bool _loaded = false;
  bool _loading = true;
  List<_O9OverdueAgreement> _all = const [];

  static const _sortOptions = ['Más vencidos', 'Recientes', 'A-Z'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadData();
  }

  Future<void> _loadData() async {
    final controller = AppScope.of(context);
    final items = await controller.loadActreuOverdueAgreements();
    if (!mounted) return;
    setState(() {
      _all = items
          .map(
            (item) => _O9OverdueAgreement(
              id: item.agreementId,
              desc: item.description,
              resp: item.responsible,
              due: _formatDate(item.dueDate),
              source: item.sessionLabel,
              group: item.group,
              groupColor: _colorFromHex(item.groupColorHex),
              statusLabel: item.statusLabel,
              statusColor: _colorFromHex(item.statusColorHex),
              daysOverdue: item.daysOverdue,
              deferrals: item.deferralsCount,
              comments: item.commentsCount,
            ),
          )
          .toList();
      _loading = false;
    });
  }

  List<String> get _sourceOptions => [
    'Todos',
    ...{for (final item in _all) item.source}.where((v) => v.isNotEmpty),
  ];
  List<String> get _respOptions => [
    'Todos',
    ...{for (final item in _all) item.resp}.where((v) => v.isNotEmpty),
  ];
  List<String> get _groupOptions => [
    'Todos',
    ...{for (final item in _all) item.group}.where((v) => v.isNotEmpty),
  ];

  List<_O9OverdueAgreement> get _filtered {
    var list = _all.toList();
    if (_filterSource != 'Todos') {
      list = list.where((a) => a.source == _filterSource).toList();
    }
    if (_filterResp != 'Todos') {
      list = list.where((a) => a.resp == _filterResp).toList();
    }
    if (_filterGroup != 'Todos') {
      list = list.where((a) => a.group == _filterGroup).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (a) =>
                a.desc.toLowerCase().contains(q) ||
                a.resp.toLowerCase().contains(q) ||
                a.group.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (_sortBy) {
      case 'Más vencidos':
        list.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
        break;
      case 'Recientes':
        list.sort((a, b) => a.daysOverdue.compareTo(b.daysOverdue));
        break;
      case 'A-Z':
        list.sort((a, b) => a.desc.compareTo(b.desc));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final canWrite = controller.canWriteProjectModule('ACTAREU');
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0EAF6)),
        ),
        titleSpacing: 16,
        title: _isSearching
            ? Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EAF6).withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              )
            : Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Acuerdos Vencidos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: const Color(0xFF64748B),
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF64748B),
              ),
              tooltip: 'Filtros',
              onPressed: () => _showFilters(context),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_filterSource != 'Todos' ||
                    _filterResp != 'Todos' ||
                    _filterGroup != 'Todos' ||
                    _sortBy != 'Más vencidos')
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        if (_filterSource != 'Todos')
                          _ActiveFilterChip(
                            label: _filterSource,
                            onRemove: () =>
                                setState(() => _filterSource = 'Todos'),
                          ),
                        if (_filterResp != 'Todos')
                          _ActiveFilterChip(
                            label: _filterResp,
                            onRemove: () =>
                                setState(() => _filterResp = 'Todos'),
                          ),
                        if (_filterGroup != 'Todos')
                          _ActiveFilterChip(
                            label: _filterGroup,
                            onRemove: () =>
                                setState(() => _filterGroup = 'Todos'),
                          ),
                        if (_sortBy != 'Más vencidos')
                          _ActiveFilterChip(
                            label: 'Orden: $_sortBy',
                            onRemove: () =>
                                setState(() => _sortBy = 'Más vencidos'),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filtered.length} acuerdos vencidos',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 64,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'No hay acuerdos vencidos con estos filtros',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final a = filtered[i];
                            return _OverdueCard(
                              agreement: a,
                              onDefer: canWrite
                                  ? () async {
                                      final due = _parseUiDate(a.due);
                                      final now = DateTime.now();
                                      final today = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      );
                                      final initial = due == null
                                          ? today
                                          : DateTime(
                                              due.year,
                                              due.month,
                                              due.day + 1,
                                            );
                                      final firstAllowed =
                                          initial.isAfter(today)
                                          ? initial
                                          : today;
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final appScope = AppScope.of(context);
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: firstAllowed,
                                        firstDate: firstAllowed,
                                        lastDate: today.add(
                                          const Duration(days: 365),
                                        ),
                                        helpText: 'Nueva fecha límite',
                                        confirmText: 'Aplazar',
                                        cancelText: 'Cancelar',
                                      );
                                      if (picked == null) return;
                                      try {
                                        await appScope.deferActreuAgreement(
                                          agreementId: a.id,
                                          newDueDate: picked,
                                        );
                                        if (!mounted) return;
                                        await _loadData();
                                      } catch (e) {
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceFirst(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              /*
                                final parts = a.due.split('/');
                                if (parts.length < 3) return;
                                final initial = DateTime(
                                  int.parse(parts[2]),
                                  int.parse(parts[1]),
                                  int.parse(parts[0]),
                                );
                                await showDatePicker(
                                  context: context,
                                  initialDate: initial.isBefore(DateTime.now())
                                      ? DateTime.now()
                                      : initial,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  helpText: 'Nueva fecha límite',
                                  confirmText: 'Aplazar',
                                  cancelText: 'Cancelar',
                                );
                              },
                              */
                              onStatusChange: canWrite
                                  ? () => _showStatusSheet(a)
                                  : null,
                              onDetail: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => O9AgreementDetailScreen(
                                      id: a.id,
                                      description: a.desc,
                                      responsible: a.resp,
                                      dueDate: a.due,
                                      status: 'overdue',
                                      statusDisplayLabel: a.statusLabel,
                                      statusDisplayColor: a.statusColor,
                                      group: a.group,
                                      groupColor: a.groupColor,
                                      meetingDate: a.source,
                                      comments: a.comments,
                                      deferrals: a.deferrals,
                                      readOnly: !canWrite,
                                      onStatusChange: (id, status) {
                                        _persistAgreementStatus(
                                          id,
                                          status == 'completed' ? 3 : 1,
                                        );
                                      },
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                await _loadData();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtrar acuerdos vencidos',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Por grupo de acuerdo',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _groupOptions
                    .map(
                      (v) => ChoiceChip(
                        label: Text(v, style: const TextStyle(fontSize: 11)),
                        selected: _filterGroup == v,
                        selectedColor: const Color(0xFF0A66B7),
                        labelStyle: TextStyle(
                          color: _filterGroup == v ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) =>
                            setModalState(() => _filterGroup = v),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Por origen',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sourceOptions
                    .map(
                      (v) => ChoiceChip(
                        label: Text(v, style: const TextStyle(fontSize: 11)),
                        selected: _filterSource == v,
                        selectedColor: const Color(0xFF0A66B7),
                        labelStyle: TextStyle(
                          color: _filterSource == v ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) =>
                            setModalState(() => _filterSource = v),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Por responsable',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _respOptions
                    .map(
                      (v) => ChoiceChip(
                        label: Text(v, style: const TextStyle(fontSize: 11)),
                        selected: _filterResp == v,
                        selectedColor: const Color(0xFF0A66B7),
                        labelStyle: TextStyle(
                          color: _filterResp == v ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) => setModalState(() => _filterResp = v),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _sortOptions
                    .map(
                      (v) => ChoiceChip(
                        label: Text(v, style: const TextStyle(fontSize: 11)),
                        selected: _sortBy == v,
                        selectedColor: const Color(0xFF0A66B7),
                        labelStyle: TextStyle(
                          color: _sortBy == v ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) => setModalState(() => _sortBy = v),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSheet(_O9OverdueAgreement a) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambiar estado',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              a.desc,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusBtn(
                  label: 'Pendiente',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.schedule_rounded,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _persistAgreementStatus(a.id, 1);
                  },
                ),
                _StatusBtn(
                  label: 'En proceso',
                  color: const Color(0xFF0A66B7),
                  icon: Icons.timelapse_rounded,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _persistAgreementStatus(a.id, 1);
                  },
                ),
                _StatusBtn(
                  label: 'Finalizado',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_rounded,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _persistAgreementStatus(a.id, 3);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _colorFromHex(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const Color(0xFF0A66B7);
    }
    final hex = value.replaceAll('#', '').trim();
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    if (normalized.length != 8) return const Color(0xFF0A66B7);
    return Color(int.parse(normalized, radix: 16));
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
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

  Future<void> _persistAgreementStatus(int agreementId, int statusCode) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppScope.of(context).updateActreuAgreementStatus(
        agreementId: agreementId,
        statusCode: statusCode,
      );
      if (!mounted) return;
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _OverdueCard extends StatelessWidget {
  const _OverdueCard({
    required this.agreement,
    required this.onDefer,
    required this.onStatusChange,
    required this.onDetail,
  });

  final _O9OverdueAgreement agreement;
  final VoidCallback? onDefer;
  final VoidCallback? onStatusChange;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final gc = agreement.groupColor;
    final showDescription = _actreuColumnVisible(context, 'desAcuerdo');
    final showResponsible = _actreuColumnVisible(context, 'responsable');
    final showGroup = _actreuColumnVisible(context, 'grupoAcuerdo');
    final showDueDate = _actreuColumnVisible(context, 'dayFechaLevantamiento');
    final showDeferrals = _actreuColumnVisible(context, 'numAplazos');
    final showStatus = _actreuColumnVisible(context, 'estado');
    final deferralsLabel = _actreuColumnLabel(context, 'numAplazos', 'Aplazos');
    final statusActionLabel = _actreuColumnLabel(context, 'estado', 'Estado');
    final metaItems = <Widget>[
      if (showResponsible && agreement.resp.isNotEmpty)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 11,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 3),
            Text(
              agreement.resp,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      if (showDueDate)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_outlined,
              size: 11,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 3),
            Text(
              agreement.due,
              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
            ),
          ],
        ),
      if (agreement.deferrals > 0 && showDeferrals)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$deferralsLabel: ${agreement.deferrals}',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFF59E0B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0EAF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showGroup) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: gc.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          agreement.group,
                          style: TextStyle(
                            fontSize: 10,
                            color: _groupTextColor(gc),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        agreement.source,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${agreement.daysOverdue}d venc.',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showDescription) ...[
                  const SizedBox(height: 6),
                  Text(
                    agreement.desc,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (metaItems.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: metaItems),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ActionB(
                      icon: Icons.calendar_today_rounded,
                      label: 'Aplazar',
                      onTap: onDefer,
                    ),
                    if (showStatus)
                      _ActionB(
                        icon: Icons.swap_horiz_rounded,
                        label: statusActionLabel,
                        onTap: onStatusChange,
                      ),
                    _ActionB(
                      icon: Icons.open_in_new_rounded,
                      label: 'Detalle',
                      onTap: onDetail,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionB extends StatelessWidget {
  const _ActionB({
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
    child: Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE0EAF6).withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusBtn extends StatelessWidget {
  const _StatusBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14, color: color),
    label: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
    ),
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: color.withValues(alpha: 0.50)),
      minimumSize: const Size(0, 32),
    ),
  );
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    deleteIcon: const Icon(Icons.close_rounded, size: 14),
    onDeleted: onRemove,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    backgroundColor: const Color(0xFF0A66B7).withValues(alpha: 0.10),
    deleteIconColor: const Color(0xFF0A66B7),
    labelStyle: const TextStyle(color: Color(0xFF0A66B7)),
    side: BorderSide.none,
  );
}

Color _groupTextColor(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.62 ? const Color(0xFF1F2937) : Colors.white;
}
