import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../../app/state/app_scope.dart';
import 'o9_agreement_detail_screen.dart';
import 'o9_comments_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Pantalla de Sesión de Acta
// Estructura base de O8 + filtros + secciones
// ─────────────────────────────────────────────

class _Att {
  _Att({
    required this.id,
    required this.name,
    required this.area,
    required this.present,
  });
  final int id;
  final String name;
  final String area;
  bool present;
}

class _Ag {
  _Ag({
    required this.id,
    required this.desc,
    required this.resp,
    this.respId,
    required this.due,
    String? planned,
    required this.status,
    this.groupId,
    required this.group,
    required this.gc,
    required this.comments,
    required this.isFromPrevious,
    this.deferrals = 0,
    this.isInformative = false,
  }) : planned = planned ?? due;
  final int id;
  String desc;
  String resp;
  final int? respId;
  String due;
  final String planned;
  String status;
  final int? groupId;
  final String group;
  final Color gc;
  final int comments;
  final bool isFromPrevious;
  int deferrals;
  final bool isInformative;
}

class O9SessionScreen extends StatefulWidget {
  const O9SessionScreen({
    super.key,
    this.subcategoryId,
    this.sessionId,
    this.isClosed = false,
  });
  final int? subcategoryId;
  final int? sessionId;
  final bool isClosed;
  @override
  State<O9SessionScreen> createState() => _O9SessionScreenState();
}

class _O9SessionScreenState extends State<O9SessionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<_Att> _att;
  late final List<_Ag> _ag;
  final List<String> _groups = [
    'Estructura',
    'SST',
    'Calidad',
    'Logística',
    'Gerencia',
  ];
  bool _loading = true;
  bool _loaded = false;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _sessionClosed = false;
  int? _resolvedSessionId;
  int? _resolvedSubcategoryId;
  bool _closingSession = false;
  final Map<String, int> _groupIdByName = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _sessionClosed = widget.isClosed;
    _att = [
      _Att(id: 1, name: 'Carlos Mendoza', area: 'Residente', present: true),
      _Att(id: 2, name: 'Lucia Torres', area: 'Jefa SST', present: true),
      _Att(id: 3, name: 'Roberto Chavez', area: 'Jefe Calidad', present: false),
      _Att(id: 4, name: 'Ana Flores', area: 'Supervisora', present: true),
      _Att(id: 5, name: 'Pedro Quispe', area: 'Contratista', present: true),
      _Att(id: 6, name: 'Marco Rivera', area: 'Subcontratista', present: false),
    ];
    _ag = [
      _Ag(
        id: 1,
        desc: 'Revisar cronograma de concreto nivel 3',
        resp: 'C. Mendoza',
        due: '25/03/2026',
        status: 'pending',
        group: 'Estructura',
        gc: const Color(0xFF0A66B7),
        comments: 2,
        isFromPrevious: false,
      ),
      _Ag(
        id: 2,
        desc: 'Presentar cuadro de metrados actualizado',
        resp: 'R. Chavez',
        due: '25/03/2026',
        status: 'pending',
        group: 'Calidad',
        gc: const Color(0xFFE4A620),
        comments: 1,
        isFromPrevious: false,
      ),
      _Ag(
        id: 3,
        desc: 'Validar compatibilidad planos MEP con nivel 4',
        resp: 'A. Flores',
        due: '30/03/2026',
        status: 'in_progress',
        group: 'Estructura',
        gc: const Color(0xFF0A66B7),
        comments: 0,
        isFromPrevious: false,
      ),
      // Pendientes de sesiones anteriores
      _Ag(
        id: 4,
        desc: 'Entregar EPPs completos a cuadrilla de fierreros',
        resp: 'L. Torres',
        due: '20/03/2026',
        status: 'overdue',
        group: 'SST',
        gc: const Color(0xFF1B8E5A),
        comments: 5,
        isFromPrevious: true,
      ),
      _Ag(
        id: 5,
        desc: 'Coordinar llegada de acero con Siderperú',
        resp: 'P. Quispe',
        due: '22/03/2026',
        status: 'overdue',
        group: 'Logística',
        gc: const Color(0xFFD64545),
        comments: 3,
        isFromPrevious: true,
        deferrals: 2,
      ),
      _Ag(
        id: 6,
        desc: 'Renovar póliza de seguro del proyecto',
        resp: 'M. Rodriguez',
        due: '15/03/2026',
        status: 'overdue',
        group: 'Gerencia',
        gc: const Color(0xFF7C3AED),
        comments: 2,
        isFromPrevious: true,
        deferrals: 1,
      ),
      // Informativos
      _Ag(
        id: 7,
        desc:
            'Se informa que la entrega de materiales será los días viernes a partir de la semana 14.',
        resp: '',
        due: '',
        status: 'info',
        group: 'Logística',
        gc: const Color(0xFFD64545),
        comments: 0,
        isFromPrevious: false,
        isInformative: true,
      ),
      _Ag(
        id: 8,
        desc:
            'El próximo comité ejecutivo será el 28 de marzo a las 10:00 am en sala principal.',
        resp: '',
        due: '',
        status: 'info',
        group: 'Gerencia',
        gc: const Color(0xFF7C3AED),
        comments: 0,
        isFromPrevious: false,
        isInformative: true,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final subcategoryId = widget.subcategoryId;
    _resolvedSubcategoryId = subcategoryId;
    if (subcategoryId == null) {
      _att.clear();
      _ag.clear();
      _groups.clear();
      _resolvedSessionId = null;
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    final controller = AppScope.of(context);
    final hasParticipants = await controller.hasActreuParticipantsConfigured(
      subcategoryId,
    );
    if (!hasParticipants) {
      if (mounted) {
        setState(() => _loading = false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No puedes ingresar a la sesión sin participantes en la subcategoría.',
            ),
          ),
        );
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      });
      return;
    }
    final data = await controller.loadActreuSessionView(
      subcategoryId: subcategoryId,
      sessionId: widget.sessionId,
    );
    if (!mounted) return;
    if (data == null) {
      _att.clear();
      _ag.clear();
      _groups.clear();
      _resolvedSessionId = null;
      setState(() => _loading = false);
      return;
    }
    _resolvedSessionId = data.sessionId;

    _att
      ..clear()
      ..addAll(
        data.attendance.map(
          (item) => _Att(
            id: item.participantId,
            name: item.name,
            area: item.area,
            present: item.present,
          ),
        ),
      );

    _ag
      ..clear()
      ..addAll(
        data.agreements.map(
          (item) => _Ag(
            id: item.agreementId,
            desc: item.description,
            resp: item.responsible,
            respId: item.responsibleParticipantId,
            due: _formatDate(item.dueDate),
            planned: _formatDate(item.agreementDate),
            status: _statusFromCode(item.statusCode),
            groupId: item.groupId,
            group: item.group,
            gc: _groupDisplayColorFromHex(item.groupColorHex),
            comments: item.commentsCount,
            isFromPrevious: item.isFromPrevious,
            deferrals: item.deferralsCount,
            isInformative: item.statusCode == 6,
          ),
        ),
      );

    _groupIdByName
      ..clear()
      ..addEntries(
        data.groupOptions
            .where((item) => item.groupName.trim().isNotEmpty)
            .map((item) => MapEntry(item.groupName.trim(), item.groupId)),
      );

    _groups
      ..clear()
      ..addAll(data.groupNames);
    if (_groups.isEmpty) {
      _groups.addAll(['General']);
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleAttendance(int index) async {
    if (_sessionClosed) return;
    final sessionId = _resolvedSessionId;
    if (sessionId == null) return;
    if (index < 0 || index >= _att.length) return;
    final participant = _att[index];
    final next = !participant.present;
    setState(() => participant.present = next);
    await AppScope.of(context).upsertActreuAttendance(
      sessionId: sessionId,
      participantId: participant.id,
      present: next,
    );
    await _loadFromDb();
  }

  Future<void> _updateAgreementStatus(int agreementId, String statusKey) async {
    final statusCode = _statusCodeFromKey(statusKey);
    if (statusCode == null) return;
    await AppScope.of(context).updateActreuAgreementStatus(
      agreementId: agreementId,
      statusCode: statusCode,
    );
    await _loadFromDb();
  }

  Future<void> _deferAgreement(int agreementId, String dueDate) async {
    final parsedDate = _parseUiDate(dueDate);
    if (parsedDate == null) return;
    try {
      await AppScope.of(
        context,
      ).deferActreuAgreement(agreementId: agreementId, newDueDate: parsedDate);
      await _loadFromDb();
    } catch (error) {
      if (!mounted) return;
      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'No se pudo registrar el aplazo.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _addAgreement(_Ag agreement) async {
    final subcategoryId = _resolvedSubcategoryId;
    final sessionId = _resolvedSessionId;
    if (subcategoryId == null || sessionId == null) return;
    final date = _parseUiDate(agreement.due) ?? DateTime.now();
    await AppScope.of(context).createActreuAgreement(
      subcategoryId: subcategoryId,
      sessionId: sessionId,
      description: agreement.desc,
      agreementDate: date,
      isInformative: agreement.isInformative,
      responsibleParticipantId: agreement.respId,
      groupId: agreement.groupId,
      groupName: agreement.group,
    );
    await _loadFromDb();
  }

  Future<bool> _deleteAgreement(_Ag agreement) async {
    final sessionId = _resolvedSessionId;
    if (sessionId == null) return false;
    await AppScope.of(context).deleteActreuAgreement(
      agreementId: agreement.id,
      sessionId: sessionId,
    );
    if (!mounted) return false;
    final error = AppScope.of(context).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.replaceFirst('Exception: ', ''))),
      );
      return false;
    }
    await _loadFromDb();
    if (!mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Acuerdo eliminado.')));
    return true;
  }

  Future<void> _closeSession() async {
    final sessionId = _resolvedSessionId;
    if (sessionId == null) return;
    setState(() => _closingSession = true);
    await AppScope.of(context).closeActreuSession(sessionId);
    if (!mounted) return;
    setState(() {
      _sessionClosed = true;
      _closingSession = false;
    });
    await _loadFromDb();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int get _present => _att.where((a) => a.present).length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: _isSearching
            ? Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EAF6).withValues(alpha:0.30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar en acuerdos...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 13, color: const Color(0xFF64748B)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesión #19 — Sem. 13',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '25 Mar 2026 · 08:00 – 09:30',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
        actions: [
          if (_tabs.index == 1)
            IconButton(
              icon: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
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
            TextButton.icon(
              onPressed: _sessionClosed ? null : () => _closeDialog(context),
              icon: Icon(
                _sessionClosed
                    ? Icons.lock_rounded
                    : Icons.lock_outline_rounded,
                size: 16,
                color: _sessionClosed
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1B8E5A),
              ),
              label: Text(
                _sessionClosed ? 'Acta cerrada' : 'Cerrar Acta',
                style: TextStyle(
                  color: _sessionClosed
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1B8E5A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF0A66B7),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF0A66B7),
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.how_to_reg_rounded, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    'Asistencia $_present/${_att.length}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_rounded, size: 14),
                  SizedBox(width: 3),
                  Text('Acuerdos', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_rounded, size: 14),
                  SizedBox(width: 3),
                  Text('Acta', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AttTab(
            att: _att,
            onToggle: _sessionClosed
                ? null
                : (i) => unawaited(_toggleAttendance(i)),
          ),
          _AgTab(
            ag: _ag,
            groups: _groups,
            groupIdByName: _groupIdByName,
            participants: _att,
            searchQuery: _searchQuery,
            readOnly: _sessionClosed,
            onStatusChange: (id, s) => unawaited(_updateAgreementStatus(id, s)),
            onDefer: (id, d) => unawaited(_deferAgreement(id, d)),
            onAdd: (ag) => unawaited(_addAgreement(ag)),
            onDelete: (ag) => _deleteAgreement(ag),
            onAddGroup: (g) => setState(() {
              if (!_groups.contains(g)) _groups.add(g);
            }),
            onReloadRequested: () => unawaited(_loadFromDb()),
          ),
          _ActaTab(att: _att, ag: _ag),
        ],
      ),
    );
  }

  void _closeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar acta de reunión'),
        content: const Text(
          'Se generará el PDF del acta y se enviará a todos los participantes. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _closingSession
                ? null
                : () {
                    Navigator.pop(ctx);
                    unawaited(_closeSession());
                  },
            child: const Text('Cerrar y generar PDF'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _statusFromCode(int code) {
  switch (code) {
    case 1:
    case 2:
      return 'in_progress';
    case 3:
      return 'completed';
    case 4:
    case 5:
      return 'overdue';
    case 6:
      return 'info';
    default:
      return 'in_progress';
  }
}

int? _statusCodeFromKey(String key) {
  switch (key) {
    case 'in_progress':
      return 1;
    case 'completed':
      return 3;
    default:
      return null;
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

Color? _parseColor(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final hex = value.replaceAll('#', '').trim();
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  if (normalized.length != 8) return null;
  return Color(int.parse(normalized, radix: 16));
}

Color _groupDisplayColorFromHex(String? value) {
  final parsed = _parseColor(value);
  return parsed ?? const Color(0xFF0A66B7);
}

Color _groupTextColor(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.62 ? const Color(0xFF1F2937) : Colors.white;
}

Border? _groupChipBorder(Color background) {
  if (background.computeLuminance() <= 0.62) return null;
  return Border.all(color: const Color(0x33000000));
}

// ─────────────────────────────────────────────
// TAB: ASISTENCIA (igual que O8)
// ─────────────────────────────────────────────

class _AttTab extends StatelessWidget {
  const _AttTab({required this.att, required this.onToggle});
  final List<_Att> att;
  final ValueChanged<int>? onToggle;

  @override
  Widget build(BuildContext context) {
    final present = att.where((a) => a.present).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B8E5A).withValues(alpha:0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.how_to_reg_rounded,
                size: 16,
                color: Color(0xFF1B8E5A),
              ),
              const SizedBox(width: 8),
              Text(
                '$present / ${att.length} presentes',
                style: const TextStyle(
                  color: Color(0xFF1B8E5A),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...att.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: p.present
                  ? const Color(0xFF1B8E5A).withValues(alpha:0.06)
                  : const Color(0xFFE0EAF6).withValues(alpha:0.30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: p.present
                    ? const Color(0xFF1B8E5A).withValues(alpha:0.25)
                    : const Color(0xFFE0EAF6),
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 2,
              ),
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: p.present
                    ? const Color(0xFF1B8E5A).withValues(alpha:0.15)
                    : const Color(0xFFE0EAF6),
                child: Text(
                  p.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.present ? const Color(0xFF1B8E5A) : const Color(0xFF64748B),
                  ),
                ),
              ),
              title: Text(
                p.name,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 13),
              ),
              subtitle: Text(
                p.area,
                style: TextStyle(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              trailing: Switch.adaptive(
                value: p.present,
                activeThumbColor: const Color(0xFF1B8E5A),
                onChanged: onToggle == null ? null : (_) => onToggle!(i),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TAB: ACUERDOS — con filtros + secciones + acciones
// ─────────────────────────────────────────────

class _AgTab extends StatefulWidget {
  const _AgTab({
    required this.ag,
    required this.groups,
    required this.groupIdByName,
    required this.participants,
    required this.searchQuery,
    required this.readOnly,
    required this.onStatusChange,
    required this.onDefer,
    required this.onAdd,
    required this.onDelete,
    required this.onAddGroup,
    required this.onReloadRequested,
  });
  final List<_Ag> ag;
  final List<String> groups;
  final Map<String, int> groupIdByName;
  final List<_Att> participants;
  final String searchQuery;
  final bool readOnly;
  final Function(int, String) onStatusChange;
  final Function(int, String) onDefer;
  final Function(_Ag) onAdd;
  final Future<bool> Function(_Ag) onDelete;
  final Function(String) onAddGroup;
  final VoidCallback onReloadRequested;
  @override
  State<_AgTab> createState() => _AgTabState();
}

class _AgTabState extends State<_AgTab> {
  String _filter = 'Todos';
  bool _showPrevious = true;
  static const _filters = [
    'Todos',
    'Vencidos',
    'Pendientes',
    'En proceso',
    'Completados',
    'Informativos',
  ];

  static const _groupColors = {
    'Estructura': Color(0xFF0A66B7),
    'SST': Color(0xFF1B8E5A),
    'Calidad': Color(0xFFE4A620),
    'Logística': Color(0xFFD64545),
    'Gerencia': Color(0xFF7C3AED),
  };

  List<_Ag> get _filteredCurrent {
    final current = widget.ag.where((a) => !a.isFromPrevious);
    return _applyFilter(current);
  }

  List<_Ag> get _filteredPrevious {
    final prev = widget.ag.where((a) => a.isFromPrevious && !a.isInformative);
    return _applyFilter(prev);
  }

  List<_Ag> _applyFilter(Iterable<_Ag> source) {
    Iterable<_Ag> filtered = source;
    switch (_filter) {
      case 'Vencidos':
        filtered = filtered.where((a) => a.status == 'overdue');
        break;
      case 'Pendientes':
        filtered = filtered.where((a) => a.status == 'pending');
        break;
      case 'En proceso':
        filtered = filtered.where((a) => a.status == 'in_progress');
        break;
      case 'Completados':
        filtered = filtered.where((a) => a.status == 'completed');
        break;
      case 'Informativos':
        filtered = filtered.where((a) => a.isInformative);
        break;
    }
    if (widget.searchQuery.isNotEmpty) {
      final q = widget.searchQuery.toLowerCase();
      filtered = filtered.where(
        (a) =>
            a.desc.toLowerCase().contains(q) ||
            a.resp.toLowerCase().contains(q) ||
            a.group.toLowerCase().contains(q),
      );
    }
    return filtered.toList();
  }

  void _addDialog() {
    if (widget.readOnly) return;
    final descCtrl = TextEditingController();
    final newGroupCtrl = TextEditingController();
    final availableGroups = widget.groups.isEmpty
        ? <String>['General']
        : widget.groups.toList();
    String selectedGroup = availableGroups.first;
    int? selectedResponsibleId = widget.participants.isNotEmpty
        ? widget.participants.first.id
        : null;
    DateTime? selectedAgreementDate;
    bool isInformative = false;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AnimatedPadding(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.88,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo acuerdo',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // Toggle informativo
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isInformative
                          ? const Color(0xFF0A66B7).withValues(alpha:0.08)
                          : const Color(0xFFE0EAF6).withValues(alpha:0.30),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isInformative
                            ? const Color(0xFF0A66B7).withValues(alpha:0.40)
                            : const Color(0xFFE0EAF6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isInformative
                              ? const Color(0xFF0A66B7)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Acuerdo informativo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isInformative
                                      ? const Color(0xFF0A66B7)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Sin seguimiento ni responsable',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: isInformative,
                          activeThumbColor: const Color(0xFF0A66B7),
                          onChanged: (v) => setModal(() => isInformative = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isInformative
                          ? 'Nota informativa *'
                          : 'Descripción del acuerdo',
                    ),
                  ),
                  if (!isInformative) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: selectedResponsibleId,
                      decoration: const InputDecoration(
                        labelText: 'Responsable',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      items: widget.participants
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: widget.participants.isEmpty
                          ? null
                          : (value) =>
                                setModal(() => selectedResponsibleId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroup,
                      decoration: const InputDecoration(
                        labelText: 'Grupo de acuerdo *',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: availableGroups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(g, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModal(() => selectedGroup = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newGroupCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nuevo grupo (opcional)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            if (newGroupCtrl.text.trim().isNotEmpty) {
                              final name = newGroupCtrl.text.trim();
                              widget.onAddGroup(name);
                              if (!availableGroups.contains(name)) {
                                availableGroups.add(name);
                              }
                              setModal(() {
                                selectedGroup = name;
                                newGroupCtrl.clear();
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('Crear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedAgreementDate ?? now,
                          firstDate: DateTime(now.year - 2, 1, 1),
                          lastDate: DateTime(now.year + 4, 12, 31),
                          helpText: 'Fecha de acuerdo',
                          confirmText: 'Seleccionar',
                          cancelText: 'Cancelar',
                        );
                        if (picked != null) {
                          setModal(() => selectedAgreementDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        selectedAgreementDate == null
                            ? 'Fecha de acuerdo *'
                            : 'Fecha de acuerdo: ${_formatDate(selectedAgreementDate)}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final description = descCtrl.text.trim();
                        if (description.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La descripción del acuerdo es obligatoria.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (!isInformative && selectedGroup.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El grupo de acuerdo es obligatorio.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (!isInformative && selectedAgreementDate == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La fecha de acuerdo es obligatoria.',
                              ),
                            ),
                          );
                          return;
                        }

                        if (isInformative) {
                          widget.onAdd(
                            _Ag(
                              id: DateTime.now().millisecondsSinceEpoch,
                              desc: description,
                              resp: '',
                              due: _formatDate(selectedAgreementDate),
                              status: 'info',
                              groupId: widget.groupIdByName[selectedGroup],
                              group: selectedGroup,
                              gc:
                                  _groupColors[selectedGroup] ??
                                  const Color(0xFF0A66B7),
                              comments: 0,
                              isFromPrevious: false,
                              isInformative: true,
                            ),
                          );
                        } else {
                          final gc =
                              _groupColors[selectedGroup] ?? const Color(0xFF0A66B7);
                          _Att? selectedResponsible;
                          for (final participant in widget.participants) {
                            if (participant.id == selectedResponsibleId) {
                              selectedResponsible = participant;
                              break;
                            }
                          }
                          widget.onAdd(
                            _Ag(
                              id: DateTime.now().millisecondsSinceEpoch,
                              desc: description,
                              resp: selectedResponsible?.name ?? 'Sin asignar',
                              respId: selectedResponsible?.id,
                              due: _formatDate(selectedAgreementDate),
                              status: 'pending',
                              groupId: widget.groupIdByName[selectedGroup],
                              group: selectedGroup,
                              gc: gc,
                              comments: 0,
                              isFromPrevious: false,
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isInformative
                            ? 'Agregar nota informativa'
                            : 'Agregar acuerdo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeferPicker(int id, String currentDue, String plannedDue) async {
    final currentDate = _parseUiDate(currentDue);
    if (currentDate == null) return;
    final plannedDate = _parseUiDate(plannedDue);
    final minimumByAgreement = plannedDate == null
        ? DateTime.now()
        : DateTime(plannedDate.year, plannedDate.month, plannedDate.day + 1);
    final today = DateTime.now();
    final firstAllowed = minimumByAgreement.isAfter(today)
        ? minimumByAgreement
        : DateTime(today.year, today.month, today.day);
    final initial = currentDate.isBefore(firstAllowed) ? firstAllowed : currentDate;
    final picked = await showDatePicker(
      context: context,
      helpText: 'Nueva fecha límite',
      confirmText: 'Aplazar',
      cancelText: 'Cancelar',
      initialDate: initial,
      firstDate: firstAllowed,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      widget.onDefer(
        id,
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final current = _filteredCurrent;
    final previous = _filteredPrevious;
    final groupColorByName = <String, Color>{
      ..._groupColors,
      for (final agreement in widget.ag) agreement.group: agreement.gc,
    };

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final f = _filters[i];
                    final sel = f == _filter;
                    return ChoiceChip(
                      selected: sel,
                      label: Text(f),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : const Color(0xFF64748B),
                      ),
                      selectedColor: const Color(0xFF0A66B7),
                      backgroundColor: const Color(0xFFE0EAF6).withValues(alpha:0.40),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      onSelected: (_) => setState(() => _filter = f),
                    );
                  },
                ),
              ),
            ),
            // Lista
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  // ── Esta sesión ──
                  if (current.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'Esta sesión (${current.length})',
                      icon: Icons.radio_button_checked,
                      color: const Color(0xFF1B8E5A),
                    ),
                    const SizedBox(height: 6),
                    ...current.map(
                      (a) {
                        final card = _AgCard(
                          ag: a,
                          responsibleOptions: widget.participants
                              .map((p) => p.name)
                              .toList(),
                          groupIdByName: widget.groupIdByName,
                          groupColorByName: groupColorByName,
                          readOnly: widget.readOnly,
                          surface: surface,
                          onStatusChange: widget.onStatusChange,
                          onDefer: (id) =>
                              _showDeferPicker(id, a.due, a.planned),
                          onReloadRequested: widget.onReloadRequested,
                        );
                        if (widget.readOnly) return card;
                        return Dismissible(
                          key: ValueKey('actreu-session-agreement-${a.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD64545),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar acuerdo'),
                                content: Text('¿Eliminar el acuerdo "${a.desc}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFD64545),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return false;
                            return widget.onDelete(a);
                          },
                          child: card,
                        );
                      },
                    ),
                  ],
                  // ── Pendientes históricas ──
                  if (previous.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () =>
                          setState(() => _showPrevious = !_showPrevious),
                      borderRadius: BorderRadius.circular(10),
                      child: _SectionHeader(
                        label:
                            'Pendientes de otras fechas (${previous.length})',
                        icon: Icons.history_rounded,
                        color: const Color(0xFFD64545),
                        trailing: Icon(
                          _showPrevious
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    if (_showPrevious) ...[
                      const SizedBox(height: 6),
                      ...previous.map(
                        (a) => _AgCard(
                          ag: a,
                          responsibleOptions: widget.participants
                              .map((p) => p.name)
                              .toList(),
                          groupIdByName: widget.groupIdByName,
                          groupColorByName: groupColorByName,
                          readOnly: widget.readOnly,
                          surface: surface,
                          onStatusChange: widget.onStatusChange,
                          onDefer: (id) =>
                              _showDeferPicker(id, a.due, a.planned),
                          onReloadRequested: widget.onReloadRequested,
                        ),
                      ),
                    ],
                  ],
                  if (current.isEmpty && previous.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 48,
                              color: Color(0xFF1B8E5A),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin acuerdos en este filtro',
                              style: theme.textTheme.titleMedium,
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
        // FAB para agregar acuerdo
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: widget.readOnly ? null : _addDialog,
            mini: true,
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
    this.trailing,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha:0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    ),
  );
}

class _AgCard extends StatelessWidget {
  const _AgCard({
    required this.ag,
    required this.responsibleOptions,
    required this.groupIdByName,
    required this.groupColorByName,
    required this.readOnly,
    required this.surface,
    required this.onStatusChange,
    required this.onDefer,
    required this.onReloadRequested,
  });
  final _Ag ag;
  final List<String> responsibleOptions;
  final Map<String, int> groupIdByName;
  final Map<String, Color> groupColorByName;
  final bool readOnly;
  final Color surface;
  final Function(int, String) onStatusChange;
  final Function(int) onDefer;
  final VoidCallback onReloadRequested;

  Color get _sc {
    switch (ag.status) {
      case 'completed':
        return const Color(0xFF1B8E5A);
      case 'overdue':
        return const Color(0xFFD64545);
      case 'in_progress':
        return const Color(0xFF0A66B7);
      default:
        return const Color(0xFFE4A620);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Informativo: card distinto ──
    if (ag.isInformative) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A66B7).withValues(alpha:0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0A66B7).withValues(alpha:0.20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A66B7).withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFF0A66B7),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A66B7).withValues(alpha:0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'Informativo',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0A66B7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A66B7).withValues(alpha:0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            ag.group,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF0A66B7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ag.desc,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Card normal de acuerdo ──
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: ag.gc, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ag.gc,
                    borderRadius: BorderRadius.circular(5),
                    border: _groupChipBorder(ag.gc),
                  ),
                  child: Text(
                    ag.group,
                    style: TextStyle(
                      fontSize: 10,
                      color: _groupTextColor(ag.gc),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (ag.isFromPrevious) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD64545).withValues(alpha:0.10),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Fecha ant.',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFFD64545),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _sc.withValues(alpha:0.10),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _sc.withValues(alpha:0.30)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: ag.status == 'completed'
                          ? 'completed'
                          : 'in_progress',
                      isDense: true,
                      style: TextStyle(
                        fontSize: 10,
                        color: _sc,
                        fontWeight: FontWeight.w700,
                      ),
                      icon: Icon(Icons.arrow_drop_down, size: 14, color: _sc),
                      items: const [
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text(
                            'En progreso',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text(
                            'Finalizado',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                      onChanged: readOnly
                          ? null
                          : (v) {
                              if (v != null) onStatusChange(ag.id, v);
                            },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ag.desc,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 11,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 3),
                Text(
                  ag.resp,
                  style: TextStyle(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.event_outlined, size: 11, color: const Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text(
                  ag.due,
                  style: TextStyle(
                    fontSize: 11,
                    color: ag.status == 'overdue'
                        ? const Color(0xFFD64545)
                        : const Color(0xFF64748B),
                    fontWeight: ag.status == 'overdue'
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
                if (ag.deferrals > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4A620).withValues(alpha:0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFE4A620).withValues(alpha:0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.redo_rounded,
                          size: 11,
                          color: Color(0xFFE4A620),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Aplz ${ag.deferrals}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFE4A620),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (ag.comments > 0) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 11,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${ag.comments}',
                    style: TextStyle(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Aplazar solo para acuerdos de sesiones anteriores
                if (ag.isFromPrevious) ...[
                  _ABtn(
                    icon: Icons.calendar_today_rounded,
                    label: 'Aplazar',
                    onTap: readOnly ? null : () => onDefer(ag.id),
                  ),
                  const SizedBox(width: 6),
                ],
                _ABtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: ag.comments > 0
                      ? '${ag.comments} coments.'
                      : 'Comentar',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => O9CommentsScreen(
                        agreementId: ag.id,
                        agreementTitle: ag.desc,
                        agreementGroup: ag.group,
                        groupColor: ag.gc,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _ABtn(
                  icon: Icons.open_in_new_rounded,
                  label: 'Detalle',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => O9AgreementDetailScreen(
                          id: ag.id,
                          description: ag.desc,
                          responsible: ag.resp,
                          responsibleParticipantId: ag.respId,
                          responsibleOptions: responsibleOptions,
                          dueDate: ag.due,
                          status: ag.status,
                          groupId: ag.groupId ?? groupIdByName[ag.group],
                          group: ag.group,
                          groupColor: ag.gc,
                          groupOptions: groupIdByName.entries
                              .map(
                                (entry) => O9AgreementGroupOption(
                                  id: entry.value,
                                  name: entry.key,
                                  color:
                                      groupColorByName[entry.key] ??
                                      const Color(0xFF0A66B7),
                                ),
                              )
                              .toList(),
                          meetingDate: '25/03/2026',
                          comments: ag.comments,
                          deferrals: ag.deferrals,
                          readOnly: readOnly,
                          onStatusChange: onStatusChange,
                        ),
                      ),
                    );
                    onReloadRequested();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ABtn extends StatelessWidget {
  const _ABtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0EAF6).withValues(alpha:0.40),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// TAB: ACTA (igual que O8)
// ─────────────────────────────────────────────

class _ActaTab extends StatelessWidget {
  const _ActaTab({required this.att, required this.ag});
  final List<_Att> att;
  final List<_Ag> ag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final actaAgreements = [
      ...ag.where((a) => !a.isFromPrevious),
      ...ag.where(
        (a) =>
            a.isFromPrevious &&
            !a.isInformative &&
            (a.status == 'pending' ||
                a.status == 'in_progress' ||
                a.status == 'overdue'),
      ),
    ];
    final present = att.where((a) => a.present).length;
    final completed = actaAgreements
        .where((a) => a.status == 'completed')
        .length;
    final overdue = actaAgreements.where((a) => a.status == 'overdue').length;
    final pending = actaAgreements
        .where((a) => a.status == 'pending' || a.status == 'in_progress')
        .length;
    final informative = actaAgreements.where((a) => a.isInformative).length;
    Future<Uint8List> buildActaPdfBytes() async {
      final pdf = pw.Document();
      final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final presentAttendees = att.where((a) => a.present).toList();
      final pendingItems = actaAgreements
          .where((a) => a.status != 'completed')
          .toList();
      String statusLabel(String status) {
        switch (status) {
          case 'completed':
            return 'Finalizado';
          case 'in_progress':
            return 'En proceso';
          case 'overdue':
            return 'Vencido';
          case 'info':
            return 'Informativo';
          default:
            return 'Pendiente';
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Text(
              'Acta de Reunión - Sesión vigente',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generado: $generatedAt',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Presentes: $present'),
                pw.Text('Total acuerdos: ${actaAgreements.length}'),
                pw.Text('Finalizados: $completed'),
                pw.Text('Pendientes: $pending'),
                pw.Text('Vencidos: $overdue'),
                pw.Text('Informativos: $informative'),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Asistentes presentes',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (presentAttendees.isEmpty)
              pw.Text(
                'Sin asistentes registrados.',
                style: const pw.TextStyle(fontSize: 10),
              )
            else
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presentAttendees
                    .map(
                      (a) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          '${a.name} (${a.area})',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Acuerdos vigentes (no finalizados)',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            if (pendingItems.isEmpty)
              pw.Text(
                'No hay acuerdos pendientes.',
                style: const pw.TextStyle(fontSize: 10),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Acuerdo',
                  'Grupo',
                  'Responsable',
                  'Vence',
                  'Estado',
                ],
                headerStyle: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                data: pendingItems
                    .map(
                      (a) => [
                        a.desc,
                        a.group,
                        a.resp.isEmpty ? '-' : a.resp,
                        a.due.isEmpty ? '-' : a.due,
                        statusLabel(a.status),
                      ],
                    )
                    .toList(),
              ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Firmas de conformidad',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            if (presentAttendees.isEmpty)
              pw.Text(
                'Sin asistentes para firma.',
                style: const pw.TextStyle(fontSize: 10),
              )
            else
              pw.Column(
                children: presentAttendees
                    .map(
                      (a) => pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Expanded(
                              child: pw.Container(
                                height: 18,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: PdfColors.grey700,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.SizedBox(
                              width: 170,
                              child: pw.Text(
                                a.name,
                                style: const pw.TextStyle(fontSize: 9),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );

      return pdf.save();
    }

    Future<void> openPdfPreview() async {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Vista previa PDF'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presentes: $present'),
                Text('Total acuerdos: ${actaAgreements.length}'),
                Text('Finalizados: $completed'),
                Text('Pendientes: $pending'),
                Text('Vencidos: $overdue'),
                Text('Informativos: $informative'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final pdfBytes = await buildActaPdfBytes();
                await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename:
                      'acta_sesion_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
              label: const Text('Generar PDF'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A66B7).withValues(alpha:0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0A66B7).withValues(alpha:0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acta de Reunión — Sesión #19',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0A66B7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comité Semanal de Obra · 25 Marzo 2026',
                style: TextStyle(fontSize: 11, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Asistentes presentes',
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: att
              .where((a) => a.present)
              .map(
                (a) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8E5A).withValues(alpha:0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 12,
                        color: Color(0xFF1B8E5A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        a.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B8E5A),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(
          'Resumen de acuerdos',
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActaStat(
                value: '${actaAgreements.length}',
                label: 'Total',
                color: const Color(0xFF0A66B7),
              ),
            ),
            Expanded(
              child: _ActaStat(
                value: '$completed',
                label: 'OK',
                color: const Color(0xFF1B8E5A),
              ),
            ),
            Expanded(
              child: _ActaStat(
                value: '$pending',
                label: 'Pend.',
                color: const Color(0xFFE4A620),
              ),
            ),
            Expanded(
              child: _ActaStat(
                value: '$overdue',
                label: 'Venc.',
                color: const Color(0xFFD64545),
              ),
            ),
            Expanded(
              child: _ActaStat(
                value: '$informative',
                label: 'INF',
                color: const Color(0xFF0A66B7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...actaAgreements
            .where((a) => a.status != 'completed')
            .toList()
            .asMap()
            .entries
            .map(
              (entry) {
                final index = entry.key;
                final a = entry.value;
                return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0EAF6)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 36,
                      decoration: BoxDecoration(
                        color: a.gc,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.desc,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.isInformative
                                ? 'INF${index + 1} · ${a.group} · Estado: Informativo'
                                : '${a.resp} · ${a.group} · Vence: ${a.due}',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                );
              },
            ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A66B7).withValues(alpha:0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0A66B7).withValues(alpha:0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    color: const Color(0xFF0A66B7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generar PDF con vista previa',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0A66B7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openPdfPreview,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                  label: const Text(
                    'Vista previa y generar PDF',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActaStat extends StatelessWidget {
  const _ActaStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
