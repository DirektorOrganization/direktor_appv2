import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o8_session_screen.dart';

class O8SubcategoryScreen extends StatefulWidget {
  const O8SubcategoryScreen({super.key});
  @override
  State<O8SubcategoryScreen> createState() => _O8SubcategoryScreenState();
}

class _O8Session {
  const _O8Session({required this.num, required this.date, required this.status, required this.attended, required this.total, required this.agreements, required this.overdue});
  final String num; final String date; final String status;
  final int attended; final int total; final int agreements; final int overdue;
}

final _sessions = [
  _O8Session(num: '#19', date: '25/03/2026', status: 'programmed', attended: 0, total: 12, agreements: 0, overdue: 0),
  _O8Session(num: '#18', date: '18/03/2026', status: 'closed', attended: 10, total: 12, agreements: 4, overdue: 2),
  _O8Session(num: '#17', date: '11/03/2026', status: 'closed', attended: 11, total: 12, agreements: 3, overdue: 1),
  _O8Session(num: '#16', date: '04/03/2026', status: 'closed', attended: 9, total: 12, agreements: 6, overdue: 3),
];

class _O8AgreementItem {
  _O8AgreementItem({required this.id, required this.desc, required this.resp, required this.due, required this.status, required this.group, required this.groupColor, required this.comments, required this.deferrals});
  final int id; final String desc; final String resp; final String due;
  String status; final String group; final Color groupColor; final int comments; final int deferrals;
}

final _agreements = <_O8AgreementItem>[
  _O8AgreementItem(id: 1, desc: 'Revisar cronograma de concreto del nivel 3', resp: 'C. Mendoza', due: '25/03/2026', status: 'pending', group: 'Estructura', groupColor: const Color(0xFF0A66B7), comments: 2, deferrals: 1),
  _O8AgreementItem(id: 2, desc: 'Entregar EPPs completos a fierreros', resp: 'L. Torres', due: '20/03/2026', status: 'overdue', group: 'SST', groupColor: const Color(0xFF1B8E5A), comments: 0, deferrals: 0),
  _O8AgreementItem(id: 3, desc: 'Medición topográfica Eje B', resp: 'R. Chavez', due: '28/03/2026', status: 'completed', group: 'Calidad', groupColor: const Color(0xFFE4A620), comments: 1, deferrals: 0),
  _O8AgreementItem(id: 4, desc: 'Coordinar llegada de acero Siderperú', resp: 'P. Quispe', due: '22/03/2026', status: 'overdue', group: 'Logística', groupColor: const Color(0xFFD64545), comments: 3, deferrals: 2),
  _O8AgreementItem(id: 5, desc: 'Actualizar planos As-built muro perimetral', resp: 'A. Flores', due: '30/03/2026', status: 'pending', group: 'Calidad', groupColor: const Color(0xFFE4A620), comments: 0, deferrals: 0),
];

class _O8SubcategoryScreenState extends State<O8SubcategoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<_O8AgreementItem> _ag;
  String _agFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _ag = List.from(_agreements);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<_O8AgreementItem> get _filtered {
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
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comité Semanal de Obra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('Reuniones de Obra', style: TextStyle(fontSize: 11, color: Color(0xFF0A66B7), fontWeight: FontWeight.w600)),
        ]),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.brandBlue,
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.assignment_rounded, size: 16), const SizedBox(width: 4), Badge(label: Text('$pendingCount'), child: const Text('Acuerdos'))])),
            const Tab(text: 'Sesiones', icon: Icon(Icons.event_note_rounded, size: 16)),
            const Tab(text: 'Análisis', icon: Icon(Icons.bar_chart_rounded, size: 16)),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O8SessionScreen())),
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
          _AgTab(ag: _filtered, filter: _agFilter, onFilter: (f) => setState(() => _agFilter = f), onStatusChange: (id, s) => setState(() => _ag.firstWhere((a) => a.id == id).status = s)),
          _SessionsTab(sessions: _sessions),
          _AnalysisTab(ag: _ag),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB: ACUERDOS
// ─────────────────────────────────────────────

class _AgTab extends StatelessWidget {
  const _AgTab({required this.ag, required this.filter, required this.onFilter, required this.onStatusChange});
  final List<_O8AgreementItem> ag;
  final String filter;
  final ValueChanged<String> onFilter;
  final Function(int, String) onStatusChange;

  static const _filters = ['Todos', 'Vencidos', 'Pendientes', 'Completados'];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 10), child: SizedBox(height: 34, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: _filters.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) {
        final f = _filters[i]; final sel = f == filter;
        return ChoiceChip(selected: sel, label: Text(f), labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.muted), selectedColor: AppTheme.brandBlue, backgroundColor: AppTheme.stroke.withOpacity(0.40), side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: const VisualDensity(horizontal: -2, vertical: -2), onSelected: (_) => onFilter(f));
      }))),
      Expanded(child: ag.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF1B8E5A)), const SizedBox(height: 12), Text('Sin acuerdos en este estado', style: Theme.of(context).textTheme.titleMedium)]))
        : ListView.separated(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), itemCount: ag.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _O8AgCard(ag: ag[i], onStatusChange: onStatusChange))),
    ]);
  }
}

class _O8AgCard extends StatelessWidget {
  const _O8AgCard({required this.ag, required this.onStatusChange});
  final _O8AgreementItem ag;
  final Function(int, String) onStatusChange;

  Color get _sc { switch (ag.status) { case 'completed': return const Color(0xFF1B8E5A); case 'overdue': return const Color(0xFFD64545); default: return const Color(0xFFE4A620); } }
  String get _sl { switch (ag.status) { case 'completed': return 'Completado'; case 'overdue': return 'Vencido'; default: return 'Pendiente'; } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ag.status == 'overdue' ? const Color(0xFFD64545).withOpacity(0.30) : AppTheme.stroke), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 4, decoration: BoxDecoration(color: _sc, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: ag.groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(ag.group, style: TextStyle(fontSize: 10, color: ag.groupColor, fontWeight: FontWeight.w700))),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _sc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(_sl, style: TextStyle(fontSize: 10, color: _sc, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          Text(ag.desc, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 6),
          Wrap(spacing: 10, runSpacing: 4, children: [
            _MI(icon: Icons.person_outline_rounded, text: ag.resp),
            _MI(icon: Icons.event_outlined, text: ag.due),
            if (ag.deferrals > 0) _MI(icon: Icons.redo_rounded, text: '${ag.deferrals} aplazos', color: const Color(0xFFE4A620)),
            if (ag.comments > 0) _MI(icon: Icons.chat_bubble_outline_rounded, text: '${ag.comments} coment.'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (ag.status != 'completed') Expanded(child: OutlinedButton.icon(onPressed: () => onStatusChange(ag.id, 'completed'), icon: const Icon(Icons.check_rounded, size: 15, color: Color(0xFF1B8E5A)), label: const Text('Completar', style: TextStyle(color: Color(0xFF1B8E5A), fontSize: 12)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1B8E5A)), minimumSize: const Size(0, 36)))),
            if (ag.status != 'completed') const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => _showComment(context), icon: const Icon(Icons.add_comment_outlined, size: 15), label: const Text('Comentar', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)))),
          ]),
        ])),
      ]),
    );
  }

  void _showComment(BuildContext context) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comentar acuerdo', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(ag.desc, style: Theme.of(ctx).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          const TextField(maxLines: 4, decoration: InputDecoration(labelText: 'Tu comentario o avance...')),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Publicar comentario'))),
        ]),
      ),
    );
  }
}

class _MI extends StatelessWidget {
  const _MI({required this.icon, required this.text, this.color});
  final IconData icon; final String text; final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.muted;
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: c), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500))]);
  }
}

// ─────────────────────────────────────────────
// TAB: SESIONES
// ─────────────────────────────────────────────

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.sessions});
  final List<_O8Session> sessions;

  Color _sc(String s) { switch (s) { case 'closed': return const Color(0xFF1B8E5A); case 'programmed': return AppTheme.brandBlue; default: return const Color(0xFFE4A620); } }
  String _sl(String s) { switch (s) { case 'closed': return 'Cerrada'; case 'programmed': return 'Programada'; default: return 'En curso'; } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = sessions[i]; final isProg = s.status == 'programmed';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.stroke), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Sesión ${s.num}', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _sc(s.status).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text(_sl(s.status), style: TextStyle(fontSize: 11, color: _sc(s.status), fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text(s.date, style: theme.textTheme.bodySmall)]),
            if (!isProg) ...[
              const SizedBox(height: 8),
              Row(children: [
                _MI(icon: Icons.people_outline_rounded, text: '${s.attended}/${s.total} asistentes'), const SizedBox(width: 12),
                _MI(icon: Icons.assignment_rounded, text: '${s.agreements} acuerdos'), const SizedBox(width: 12),
                if (s.overdue > 0) _MI(icon: Icons.warning_amber_rounded, text: '${s.overdue} venc.', color: const Color(0xFFD64545)),
              ]),
            ],
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: isProg
              ? FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O8SessionScreen())), icon: const Icon(Icons.play_arrow_rounded, size: 16), label: const Text('Iniciar sesión'), style: FilledButton.styleFrom(minimumSize: const Size(0, 36)))
              : OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O8SessionScreen())), icon: const Icon(Icons.visibility_outlined, size: 15), label: const Text('Ver acta y PDF'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)))
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TAB: ANÁLISIS
// ─────────────────────────────────────────────

class _AnalysisTab extends StatelessWidget {
  const _AnalysisTab({required this.ag});
  final List<_O8AgreementItem> ag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final completed = ag.where((a) => a.status == 'completed').length;
    final overdue = ag.where((a) => a.status == 'overdue').length;
    final pending = ag.where((a) => a.status == 'pending').length;
    final total = ag.length;
    final compliancePct = total > 0 ? (completed / total * 100).round() : 0;

    // Group by group
    final Map<String, List<_O8AgreementItem>> byGroup = {};
    for (final a in ag) { byGroup.putIfAbsent(a.group, () => []).add(a); }

    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.stroke)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cumplimiento de esta subcategoría', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _AnalysisStat(value: '$compliancePct%', label: 'Cumplimiento', color: const Color(0xFF1B8E5A)),
            _AnalysisStat(value: '$completed', label: 'Completados', color: const Color(0xFF1B8E5A)),
            _AnalysisStat(value: '$pending', label: 'Pendientes', color: const Color(0xFFE4A620)),
            _AnalysisStat(value: '$overdue', label: 'Vencidos', color: const Color(0xFFD64545)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: total > 0 ? completed / total : 0, minHeight: 9, backgroundColor: AppTheme.stroke, valueColor: const AlwaysStoppedAnimation(Color(0xFF1B8E5A)))),
        ]),
      ),
      const SizedBox(height: 20),
      Text('Por grupo de acuerdo', style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      ...byGroup.entries.map((e) {
        final groupAg = e.value;
        final g = groupAg.first;
        final ok = groupAg.where((a) => a.status == 'completed').length;
        final ov = groupAg.where((a) => a.status == 'overdue').length;
        final pe = groupAg.where((a) => a.status == 'pending').length;
        final pct = groupAg.isNotEmpty ? ok / groupAg.length : 0.0;
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: g.groupColor, width: 4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(e.key, style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.5)), const Spacer(),
              Text('${(pct * 100).round()}%', style: TextStyle(color: g.groupColor, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppTheme.stroke, valueColor: AlwaysStoppedAnimation(g.groupColor))),
            const SizedBox(height: 8),
            Row(children: [_MI(icon: Icons.check_rounded, text: '$ok', color: const Color(0xFF1B8E5A)), const SizedBox(width: 12), _MI(icon: Icons.schedule_rounded, text: '$pe', color: const Color(0xFFE4A620)), const SizedBox(width: 12), _MI(icon: Icons.warning_amber_rounded, text: '$ov', color: const Color(0xFFD64545))]),
          ]),
        );
      }),
    ]);
  }
}

class _AnalysisStat extends StatelessWidget {
  const _AnalysisStat({required this.value, required this.label, required this.color});
  final String value; final String label; final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
    ]);
  }
}
