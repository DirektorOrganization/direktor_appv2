import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o9_session_screen.dart';
import 'o9_comments_screen.dart';
import 'o9_agreement_detail_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Subcategory Screen
// ─────────────────────────────────────────────

class _O9Agreement {
  _O9Agreement({required this.id, required this.description, required this.responsible, required this.dueDate, required this.status, required this.group, required this.groupColor, required this.meetingDate, required this.comments, required this.deferrals});
  final int id;
  final String description;
  final String responsible;
  final String dueDate;
  String status;
  final String group;
  final Color groupColor;
  final String meetingDate;
  final int comments;
  final int deferrals;
}

class _O9Session {
  const _O9Session({required this.num, required this.date, required this.status, required this.attended, required this.total, required this.agreements, required this.overdue});
  final String num; final String date; final String status;
  final int attended; final int total; final int agreements; final int overdue;
}

class _O9Participant {
  _O9Participant({required this.name, required this.area, required this.present, required this.role});
  String name; String area; bool present; final String role;
}

final _o9Agreements = <_O9Agreement>[
  _O9Agreement(id: 1, description: 'Revisar cronograma de concreto nivel 3', responsible: 'C. Mendoza', dueDate: '25/03/2026', status: 'pending', group: 'Estructura', groupColor: const Color(0xFF0A66B7), meetingDate: '18/03/2026', comments: 2, deferrals: 1),
  _O9Agreement(id: 2, description: 'Entregar EPPs completos a cuadrilla de fierreros', responsible: 'L. Torres', dueDate: '20/03/2026', status: 'overdue', group: 'SST', groupColor: const Color(0xFF1B8E5A), meetingDate: '11/03/2026', comments: 5, deferrals: 0),
  _O9Agreement(id: 3, description: 'Solicitar segunda medición topográfica Eje B', responsible: 'R. Chavez', dueDate: '28/03/2026', status: 'completed', group: 'Calidad', groupColor: const Color(0xFFE4A620), meetingDate: '18/03/2026', comments: 1, deferrals: 0),
  _O9Agreement(id: 4, description: 'Coordinar llegada acero con Siderperú', responsible: 'P. Quispe', dueDate: '22/03/2026', status: 'overdue', group: 'Logística', groupColor: const Color(0xFFD64545), meetingDate: '11/03/2026', comments: 3, deferrals: 2),
  _O9Agreement(id: 5, description: 'Actualizar planos As-built de muro perimetral', responsible: 'A. Flores', dueDate: '30/03/2026', status: 'pending', group: 'Calidad', groupColor: const Color(0xFFE4A620), meetingDate: '18/03/2026', comments: 0, deferrals: 0),
  _O9Agreement(id: 6, description: 'Renovar póliza de seguro del proyecto', responsible: 'M. Rodriguez', dueDate: '15/03/2026', status: 'overdue', group: 'Gerencia', groupColor: const Color(0xFF7C3AED), meetingDate: '05/03/2026', comments: 2, deferrals: 1),
];

final _o9Sessions = [
  const _O9Session(num: '#19', date: '25/03/2026', status: 'programmed', attended: 0, total: 12, agreements: 0, overdue: 0),
  const _O9Session(num: '#18', date: '18/03/2026', status: 'closed', attended: 10, total: 12, agreements: 4, overdue: 2),
  const _O9Session(num: '#17', date: '11/03/2026', status: 'closed', attended: 11, total: 12, agreements: 3, overdue: 1),
  const _O9Session(num: '#16', date: '04/03/2026', status: 'closed', attended: 9, total: 12, agreements: 6, overdue: 3),
];

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────

class O9SubcategoryScreen extends StatefulWidget {
  const O9SubcategoryScreen({super.key, this.subcategoryName = 'Comité Semanal de Obra', this.categoryName = 'Reuniones de Obra', this.categoryColor = const Color(0xFF0A66B7)});
  final String subcategoryName;
  final String categoryName;
  final Color categoryColor;
  @override
  State<O9SubcategoryScreen> createState() => _O9SubcategoryScreenState();
}

class _O9SubcategoryScreenState extends State<O9SubcategoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<_O9Agreement> _ag;
  late final List<_O9Participant> _participants;
  String _agFilter = 'Todos';
  bool _analysisExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _ag = List.from(_o9Agreements);
    _participants = [
      _O9Participant(name: 'Carlos Mendoza', area: 'Ingeniería', present: true, role: 'Residente de obra'),
      _O9Participant(name: 'Lucia Torres', area: 'SST', present: true, role: 'Jefa de SST'),
      _O9Participant(name: 'Roberto Chavez', area: 'Calidad', present: true, role: 'Jefe de Calidad'),
      _O9Participant(name: 'Ana Flores', area: 'Supervisión', present: false, role: 'Supervisora Técnica'),
      _O9Participant(name: 'Pedro Quispe', area: 'Logística', present: true, role: 'Jefe de Procura'),
      _O9Participant(name: 'Marco Rivera', area: 'Contratista', present: false, role: 'Representante'),
      _O9Participant(name: 'Maria Gutierrez', area: 'Gerencia', present: true, role: 'Coordinadora General'),
      _O9Participant(name: 'Luis Saenz', area: 'Finanzas', present: true, role: 'Analista Financiero'),
    ];
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<_O9Agreement> get _filtered {
    switch (_agFilter) {
      case 'Vencidos': return _ag.where((a) => a.status == 'overdue').toList();
      case 'Pendientes': return _ag.where((a) => a.status == 'pending').toList();
      case 'Completados': return _ag.where((a) => a.status == 'completed').toList();
      default: return _ag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _ag.where((a) => a.status != 'completed').length;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.subcategoryName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text(widget.categoryName, style: TextStyle(fontSize: 11, color: widget.categoryColor, fontWeight: FontWeight.w600)),
        ]),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.brandBlue,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.track_changes_rounded, size: 14), const SizedBox(width: 3),
              Badge(label: Text('$pendingCount', style: const TextStyle(fontSize: 8)), child: const Text('Seguimiento', style: TextStyle(fontSize: 11))),
            ])),
            const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.event_note_rounded, size: 14), SizedBox(width: 3),
              Text('Sesiones', style: TextStyle(fontSize: 11)),
            ])),
            const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_rounded, size: 14), SizedBox(width: 3),
              Text('Participan.', style: TextStyle(fontSize: 11)),
            ])),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SessionScreen())),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Iniciar sesión'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 36), textStyle: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SeguimientoTab(
            ag: _filtered, allAg: _ag,
            filter: _agFilter,
            onFilter: (f) => setState(() => _agFilter = f),
            onStatusChange: (id, s) => setState(() => _ag.firstWhere((a) => a.id == id).status = s),
            analysisExpanded: _analysisExpanded,
            onToggleAnalysis: () => setState(() => _analysisExpanded = !_analysisExpanded),
          ),
          _SessionsTab(sessions: _o9Sessions),
          _ParticipantsTab(
            participants: _participants,
            onAdd: (name, area) => setState(() => _participants.add(_O9Participant(name: name, area: area, present: true, role: 'Invitado'))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB: SEGUIMIENTO (antes: Acuerdos)
// ─────────────────────────────────────────────

class _SeguimientoTab extends StatelessWidget {
  const _SeguimientoTab({required this.ag, required this.allAg, required this.filter, required this.onFilter, required this.onStatusChange, required this.analysisExpanded, required this.onToggleAnalysis});
  final List<_O9Agreement> ag;
  final List<_O9Agreement> allAg;
  final String filter;
  final ValueChanged<String> onFilter;
  final Function(int, String) onStatusChange;
  final bool analysisExpanded;
  final VoidCallback onToggleAnalysis;

  static const _filters = ['Todos', 'Vencidos', 'Pendientes', 'Completados'];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _AnalysisBanner(ag: allAg, expanded: analysisExpanded, onToggle: onToggleAnalysis),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: SizedBox(height: 32, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _filters[i]; final sel = f == filter;
            return ChoiceChip(selected: sel, label: Text(f), labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.muted), selectedColor: AppTheme.brandBlue, backgroundColor: AppTheme.stroke.withOpacity(0.40), side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: const VisualDensity(horizontal: -2, vertical: -2), onSelected: (_) => onFilter(f));
          },
        )),
      ),
      Expanded(child: ag.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF1B8E5A)), const SizedBox(height: 12), Text('Sin acuerdos en este estado', style: Theme.of(context).textTheme.titleMedium)]))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            itemCount: ag.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _O9AgreementCard(agreement: ag[i], onStatusChange: onStatusChange),
          )),
    ]);
  }
}

// ── Banner de Análisis con grupos ──
class _AnalysisBanner extends StatelessWidget {
  const _AnalysisBanner({required this.ag, required this.expanded, required this.onToggle});
  final List<_O9Agreement> ag;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final bg = isDark ? const Color(0xFF0F1923) : const Color(0xFFF3F6FA);
    final completed = ag.where((a) => a.status == 'completed').length;
    final overdue = ag.where((a) => a.status == 'overdue').length;
    final pending = ag.where((a) => a.status == 'pending').length;
    final total = ag.length;
    final pct = total > 0 ? completed / total : 0.0;

    final Map<String, List<_O9Agreement>> byGroup = {};
    for (final a in ag) { byGroup.putIfAbsent(a.group, () => []).add(a); }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Icon(Icons.bar_chart_rounded, size: 18, color: AppTheme.brandBlue),
              const SizedBox(width: 8),
              Text('Análisis', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.brandBlue)),
              const Spacer(),
              if (!expanded) Row(children: [
                _MiniStat(value: '${(pct * 100).round()}%', color: const Color(0xFF1B8E5A)),
                const SizedBox(width: 6),
                _MiniStat(value: '$overdue venc.', color: const Color(0xFFD64545)),
              ]),
              const SizedBox(width: 8),
              Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: AppTheme.muted),
            ]),
          ),
        ),
        if (expanded) ...[
          Divider(height: 1, color: AppTheme.brandBlue.withOpacity(0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Stats generales
              Row(children: [
                _AnalysisStat(value: '${(pct * 100).round()}%', label: 'Cumplim.', color: const Color(0xFF1B8E5A)),
                const SizedBox(width: 14),
                _AnalysisStat(value: '$completed', label: 'OK', color: const Color(0xFF1B8E5A)),
                const SizedBox(width: 14),
                _AnalysisStat(value: '$pending', label: 'Pend.', color: const Color(0xFFE4A620)),
                const SizedBox(width: 14),
                _AnalysisStat(value: '$overdue', label: 'Venc.', color: const Color(0xFFD64545)),
                const SizedBox(width: 14),
                _AnalysisStat(value: '$total', label: 'Total', color: AppTheme.muted),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: AppTheme.stroke, valueColor: const AlwaysStoppedAnimation(Color(0xFF1B8E5A)))),
              const SizedBox(height: 14),
              Text('Por grupo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted)),
              const SizedBox(height: 8),
              // Grupos al estilo Opción 8
              ...byGroup.entries.map((e) {
                final groupAg = e.value;
                final g = groupAg.first;
                final ok = groupAg.where((a) => a.status == 'completed').length;
                final ov = groupAg.where((a) => a.status == 'overdue').length;
                final pe = groupAg.where((a) => a.status == 'pending').length;
                final grPct = groupAg.isNotEmpty ? ok / groupAg.length : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: g.groupColor, width: 3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: g.groupColor)),
                      const Spacer(),
                      Text('${(grPct * 100).round()}%', style: TextStyle(fontSize: 12, color: g.groupColor, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: grPct, minHeight: 5, backgroundColor: AppTheme.stroke, valueColor: AlwaysStoppedAnimation(g.groupColor))),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.check_rounded, size: 11, color: const Color(0xFF1B8E5A)), const SizedBox(width: 3), Text('$ok', style: TextStyle(fontSize: 11, color: const Color(0xFF1B8E5A), fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Icon(Icons.schedule_rounded, size: 11, color: const Color(0xFFE4A620)), const SizedBox(width: 3), Text('$pe', style: TextStyle(fontSize: 11, color: const Color(0xFFE4A620), fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Icon(Icons.warning_amber_rounded, size: 11, color: const Color(0xFFD64545)), const SizedBox(width: 3), Text('$ov', style: TextStyle(fontSize: 11, color: const Color(0xFFD64545), fontWeight: FontWeight.w700)),
                    ]),
                  ]),
                );
              }),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.color});
  final String value; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
    child: Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );
}

class _AnalysisStat extends StatelessWidget {
  const _AnalysisStat({required this.value, required this.label, required this.color});
  final String value; final String label; final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: TextStyle(fontSize: 9, color: AppTheme.muted, fontWeight: FontWeight.w600)),
  ]);
}

// ── Card de acuerdo enriquecida (Opción 7 style + acciones) ──
class _O9AgreementCard extends StatelessWidget {
  const _O9AgreementCard({required this.agreement, required this.onStatusChange});
  final _O9Agreement agreement;
  final Function(int, String) onStatusChange;

  Color get _statusColor { switch (agreement.status) { case 'completed': return const Color(0xFF1B8E5A); case 'overdue': return const Color(0xFFD64545); case 'in_progress': return AppTheme.brandBlue; default: return const Color(0xFFE4A620); } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: agreement.status == 'overdue' ? const Color(0xFFD64545).withOpacity(0.35) : AppTheme.stroke)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 3, decoration: BoxDecoration(color: _statusColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(14)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: agreement.groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(agreement.group, style: TextStyle(fontSize: 10, color: agreement.groupColor, fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              Text('Reunión: ${agreement.meetingDate}', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
              const Spacer(),
              // Dropdown de estado compacto
              _StatusDropdown(status: agreement.status, statusColor: _statusColor, onChanged: (v) { if (v != null) onStatusChange(agreement.id, v); }),
            ]),
            const SizedBox(height: 6),
            Text(agreement.description, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.person_outline_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 3),
              Text(agreement.responsible, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
              const SizedBox(width: 8),
              Icon(Icons.event_outlined, size: 11, color: AppTheme.muted), const SizedBox(width: 3),
              Text(agreement.dueDate, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
              if (agreement.deferrals > 0) ...[const SizedBox(width: 8), Icon(Icons.redo_rounded, size: 11, color: const Color(0xFFE4A620)), const SizedBox(width: 3), Text('${agreement.deferrals}', style: const TextStyle(fontSize: 11, color: Color(0xFFE4A620), fontWeight: FontWeight.w600))],
            ]),
            const SizedBox(height: 8),
            Row(children: [
              // Comentarios
              _ActionBtn(
                icon: Icons.chat_bubble_outline_rounded,
                label: agreement.comments > 0 ? '${agreement.comments}  coments.' : 'Comentar',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9CommentsScreen(agreementTitle: agreement.description, agreementGroup: agreement.group, groupColor: agreement.groupColor))),
              ),
              const SizedBox(width: 8),
              // Ver detalle
              _ActionBtn(
                icon: Icons.open_in_new_rounded,
                label: 'Ver detalle',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9AgreementDetailScreen(
                  id: agreement.id, description: agreement.description, responsible: agreement.responsible,
                  dueDate: agreement.dueDate, status: agreement.status, group: agreement.group,
                  groupColor: agreement.groupColor, meetingDate: agreement.meetingDate,
                  comments: agreement.comments, deferrals: agreement.deferrals,
                  onStatusChange: onStatusChange,
                ))),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.status, required this.statusColor, required this.onChanged});
  final String status; final Color statusColor; final ValueChanged<String?> onChanged;


  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(color: statusColor.withOpacity(0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.30))),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: status, isDense: true,
      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700),
      icon: Icon(Icons.arrow_drop_down_rounded, size: 14, color: statusColor),
      items: const [
        DropdownMenuItem(value: 'pending', child: Text('Pendiente', style: TextStyle(fontSize: 10))),
        DropdownMenuItem(value: 'in_progress', child: Text('En proceso', style: TextStyle(fontSize: 10))),
        DropdownMenuItem(value: 'completed', child: Text('Finalizado', style: TextStyle(fontSize: 10))),
        DropdownMenuItem(value: 'overdue', child: Text('Vencido', style: TextStyle(fontSize: 10))),
      ],
      onChanged: onChanged,
    )),
  );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.stroke.withOpacity(0.40), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.muted), const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
// ─────────────────────────────────────────────
// TAB: SESIONES — scheduler + calendario
// ─────────────────────────────────────────────

class _SessionsTab extends StatefulWidget {
  const _SessionsTab({required this.sessions});
  final List<_O9Session> sessions;
  @override
  State<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<_SessionsTab> {
  bool _pastExpanded = false;
  bool _calendarView = false;
  late DateTime _calMonth;

  @override
  void initState() { super.initState(); _calMonth = DateTime(2026, 3); }

  Color _sc(String s) { switch (s) { case 'closed': return const Color(0xFF1B8E5A); case 'programmed': return AppTheme.brandBlue; default: return const Color(0xFFE4A620); } }
  String _sl(String s) { switch (s) { case 'closed': return 'Cerrada'; case 'programmed': return 'Programada'; default: return 'En curso'; } }
  IconData _si(String s) { switch (s) { case 'closed': return Icons.lock_rounded; case 'programmed': return Icons.event_rounded; default: return Icons.radio_button_checked; } }

  DateTime? _parseDate(String d) { final p = d.split('/'); if (p.length < 3) return null; return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0])); }

  void _showScheduler() {
    String frequency = 'Semanal';
    String time = '08:00';
    final Set<int> days = {2};
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Programar sesiones', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Configura la recurrencia de las reuniones', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
            const SizedBox(height: 14),
            Text('Frecuencia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: ['Diaria', 'Interdiaria', 'Semanal', 'Quincenal', 'Mensual'].map((f) => ChoiceChip(
              selected: frequency == f,
              label: Text(f),
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: frequency == f ? Colors.white : AppTheme.muted),
              selectedColor: AppTheme.brandBlue, backgroundColor: AppTheme.stroke.withOpacity(0.40), side: BorderSide.none,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              onSelected: (_) => setM(() => frequency = f),
            )).toList()),
            if (frequency == 'Semanal' || frequency == 'Quincenal') ...[
              const SizedBox(height: 14),
              Text('Días de reunión', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (i) {
                final day = i + 1; final sel = days.contains(day);
                return GestureDetector(
                  onTap: () => setM(() { if (sel) days.remove(day); else days.add(day); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: sel ? AppTheme.brandBlue : AppTheme.stroke.withOpacity(0.30), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(dayLabels[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.muted)),
                  ),
                );
              })),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Text('Hora de inicio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  final parts = time.split(':');
                  final picked = await showTimePicker(context: ctx, initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
                  if (picked != null) setM(() => time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                },
                icon: const Icon(Icons.access_time_rounded, size: 14),
                label: Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32)),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.brandBlue),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  frequency == 'Diaria' ? 'Se creará una sesión cada día a las $time' :
                  frequency == 'Interdiaria' ? 'Se creará una sesión cada 2 días a las $time' :
                  frequency == 'Mensual' ? 'Se creará una sesión mensual a las $time' :
                  'Sesiones los ${days.map((d) => dayLabels[d - 1]).join(', ')} a las $time ($frequency)',
                  style: TextStyle(fontSize: 10, color: AppTheme.brandBlue),
                )),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.check_rounded, size: 14),
              label: const Text('Programar', style: TextStyle(fontSize: 11)),
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final upcoming = widget.sessions.where((s) => s.status != 'closed').toList();
    final past = widget.sessions.where((s) => s.status == 'closed').toList();

    return Stack(children: [
      _calendarView ? _buildCalendar(theme, surface) : _buildList(theme, surface, upcoming, past),
      Positioned(right: 16, bottom: 16,
        child: FloatingActionButton.small(heroTag: 'cal', backgroundColor: surface,
          onPressed: () => setState(() => _calendarView = !_calendarView),
          child: Icon(_calendarView ? Icons.list_rounded : Icons.calendar_month_rounded, color: AppTheme.brandBlue, size: 18))),
    ]);
  }

  Widget _buildList(ThemeData theme, Color surface, List<_O9Session> upcoming, List<_O9Session> past) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Text('Próxima sesión', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _showScheduler,
          icon: const Icon(Icons.add_rounded, size: 14),
          label: const Text('Programar', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 30)),
        ),
      ])),
      if (upcoming.isNotEmpty) ...[
        ...upcoming.map((s) => _SessionCard(s: s, surface: surface, sc: _sc, sl: _sl, si: _si, compact: false)),
        const SizedBox(height: 16),
      ],
      if (past.isNotEmpty) ...[
        InkWell(
          onTap: () => setState(() => _pastExpanded = !_pastExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.stroke.withOpacity(0.30), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.history_rounded, size: 14, color: AppTheme.muted), const SizedBox(width: 8),
              Text('Sesiones pasadas (${past.length})', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
              const Spacer(),
              Icon(_pastExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.muted),
            ]),
          ),
        ),
        if (_pastExpanded) ...[
          const SizedBox(height: 10),
          ...past.map((s) => _SessionCard(s: s, surface: surface, sc: _sc, sl: _sl, si: _si, compact: true)),
        ],
      ],
    ]);
  }

  Widget _buildCalendar(ThemeData theme, Color surface) {
    final year = _calMonth.year; final month = _calMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    const weekDays = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    final Map<int, _O9Session> sessionDays = {};
    for (final s in widget.sessions) { final dt = _parseDate(s.date); if (dt != null && dt.year == year && dt.month == month) sessionDays[dt.day] = s; }

    final totalCells = (firstWeekday - 1) + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 20), onPressed: () => setState(() => _calMonth = DateTime(year, month - 1))),
        Text('${months[month - 1]} $year', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
        IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 20), onPressed: () => setState(() => _calMonth = DateTime(year, month + 1))),
      ]),
      const SizedBox(height: 6),
      Row(children: weekDays.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.muted))))).toList()),
      const SizedBox(height: 4),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
        itemCount: rows * 7,
        itemBuilder: (_, index) {
          final dayNum = index - (firstWeekday - 1) + 1;
          if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
          final session = sessionDays[dayNum];
          final color = session != null ? _sc(session.status) : Colors.transparent;
          return GestureDetector(
            onTap: session != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SessionScreen())) : null,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: session != null ? color.withOpacity(0.12) : null,
                borderRadius: BorderRadius.circular(8),
                border: session != null ? Border.all(color: color.withOpacity(0.40), width: 1.5) : null,
              ),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$dayNum', style: TextStyle(fontSize: 11, fontWeight: session != null ? FontWeight.w800 : FontWeight.w500, color: session != null ? color : theme.textTheme.bodyLarge?.color)),
                if (session != null) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              ]),
            ),
          );
        },
      ),
      const SizedBox(height: 14),
      Row(children: [
        _CalLegend(color: AppTheme.brandBlue, label: 'Programada'),
        const SizedBox(width: 10),
        _CalLegend(color: const Color(0xFFE4A620), label: 'En curso'),
        const SizedBox(width: 10),
        _CalLegend(color: const Color(0xFF1B8E5A), label: 'Cerrada'),
      ]),
    ]);
  }
}

class _CalLegend extends StatelessWidget {
  const _CalLegend({required this.color, required this.label});
  final Color color; final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 10, color: AppTheme.muted)),
  ]);
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.s, required this.surface, required this.sc, required this.sl, required this.si, required this.compact});
  final _O9Session s; final Color surface;
  final Color Function(String) sc; final String Function(String) sl; final IconData Function(String) si;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProg = s.status == 'programmed'; final color = sc(s.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.stroke)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(si(s.status), size: 13, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text('Sesión ${s.num}', style: theme.textTheme.titleMedium?.copyWith(fontSize: compact ? 11 : 13))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
            child: Text(sl(s.status), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          Icon(Icons.calendar_today_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 4),
          Text(s.date, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
          if (!isProg) ...[
            const SizedBox(width: 10),
            Icon(Icons.people_outline_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 3),
            Text('${s.attended}/${s.total}', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
            const SizedBox(width: 8),
            Icon(Icons.assignment_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 3),
            Text('${s.agreements} ac.', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
            if (s.overdue > 0) ...[
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFD64545).withOpacity(0.10), borderRadius: BorderRadius.circular(5)),
                child: Text('${s.overdue} venc.', style: const TextStyle(fontSize: 9, color: Color(0xFFD64545), fontWeight: FontWeight.w700))),
            ],
          ],
        ]),
        const SizedBox(height: 6),
        if (isProg)
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SessionScreen())),
            icon: const Icon(Icons.play_arrow_rounded, size: 14),
            label: const Text('Iniciar sesión', style: TextStyle(fontSize: 11)),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 30)),
          ))
        else
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SessionScreen())),
              icon: const Icon(Icons.visibility_outlined, size: 12),
              label: const Text('Ver acta', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 28)),
            )),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 12),
              label: const Text('PDF', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 28)),
            ),
          ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
// TAB: PARTICIPANTES
// ─────────────────────────────────────────────

class _ParticipantsTab extends StatefulWidget {
  const _ParticipantsTab({required this.participants, required this.onAdd});
  final List<_O9Participant> participants;
  final Function(String name, String area) onAdd;
  @override
  State<_ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends State<_ParticipantsTab> {
  // Lista dummy de personas disponibles para búsqueda
  static const _available = [
    {'name': 'José Ramos', 'area': 'Topografía'},
    {'name': 'Diana Robles', 'area': 'Arquitectura'},
    {'name': 'Fernando Castro', 'area': 'Estructura'},
    {'name': 'Claudia Vega', 'area': 'Instalaciones'},
    {'name': 'Andrés Paredes', 'area': 'Medio Ambiente'},
    {'name': 'Sofia Mendez', 'area': 'Control de Calidad'},
  ];

  void _showAddModal() {
    final searchCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    String query = '';
    bool showManual = false;

    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Agregar participante', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (!showManual) ...[
              TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(labelText: 'Buscar por nombre', prefixIcon: Icon(Icons.search_rounded)),
                onChanged: (v) => setModal(() => query = v.toLowerCase()),
              ),
              const SizedBox(height: 10),
              // Lista filtrada
              ..._available.where((p) => query.isEmpty || p['name']!.toLowerCase().contains(query)).map((p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 16, backgroundColor: AppTheme.brandBlue.withOpacity(0.12),
                  child: Text(p['name']!.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 11, color: AppTheme.brandBlue, fontWeight: FontWeight.w700))),
                title: Text(p['name']!, style: const TextStyle(fontSize: 13)),
                subtitle: Text(p['area']!, style: const TextStyle(fontSize: 11)),
                trailing: FilledButton(
                  onPressed: () { widget.onAdd(p['name']!, p['area']!); Navigator.pop(ctx); },
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 30), textStyle: const TextStyle(fontSize: 11), padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('Agregar'),
                ),
              )),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => setModal(() => showManual = true),
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Agregar nueva persona'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 38)),
              ),
            ] else ...[
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_rounded))),
              const SizedBox(height: 10),
              TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Área / Empresa', prefixIcon: Icon(Icons.business_rounded))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setModal(() => showManual = false), child: const Text('Volver'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Confirmar'),
                  onPressed: () {
                    if (nameCtrl.text.trim().isNotEmpty) widget.onAdd(nameCtrl.text.trim(), areaCtrl.text.trim().isEmpty ? 'Sin área' : areaCtrl.text.trim());
                    Navigator.pop(ctx);
                  },
                )),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final presentCount = widget.participants.where((p) => p.present).length;
    final total = widget.participants.length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Resumen
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A66B7), Color(0xFF1581D8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Asistencia — Última sesión', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$presentCount', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('/ $total participantes', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: total > 0 ? presentCount / total : 0, minHeight: 7, backgroundColor: Colors.white.withOpacity(0.20), valueColor: const AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(height: 8),
          Row(children: [
            _SPill(value: '$presentCount', label: 'Presentes'),
            const SizedBox(width: 8),
            _SPill(value: '${total - presentCount}', label: 'Ausentes'),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Text('Miembros', style: theme.textTheme.titleMedium),
        const Spacer(),
        FilledButton.icon(
          onPressed: _showAddModal,
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Agregar', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 34)),
        ),
      ]),
      const SizedBox(height: 12),
      ...widget.participants.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.06) : surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.25) : AppTheme.stroke),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: CircleAvatar(radius: 18, backgroundColor: p.present ? const Color(0xFF1B8E5A).withOpacity(0.15) : AppTheme.stroke.withOpacity(0.40),
            child: Text(p.name.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.present ? const Color(0xFF1B8E5A) : AppTheme.muted))),
          title: Text(p.name, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
          subtitle: Text('${p.role} · ${p.area}', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.12) : AppTheme.stroke.withOpacity(0.30), borderRadius: BorderRadius.circular(6)),
            child: Text(p.present ? 'Presente' : 'Ausente', style: TextStyle(fontSize: 10, color: p.present ? const Color(0xFF1B8E5A) : AppTheme.muted, fontWeight: FontWeight.w700))),
        ),
      )),
    ]);
  }
}

class _SPill extends StatelessWidget {
  const _SPill({required this.value, required this.label});
  final String value; final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  );
}
