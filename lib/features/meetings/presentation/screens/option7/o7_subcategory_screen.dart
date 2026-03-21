import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o7_session_screen.dart';

class _O7Agreement {
  _O7Agreement({required this.id, required this.description, required this.responsible, required this.dueDate, required this.status, required this.group, required this.groupColor, required this.meetingDate, required this.comments, required this.deferrals});
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

final _allAgreements = <_O7Agreement>[
  _O7Agreement(id: 1, description: 'Revisar cronograma de concreto nivel 3', responsible: 'C. Mendoza', dueDate: '25/03/2026', status: 'pending', group: 'Estructura', groupColor: const Color(0xFF0A66B7), meetingDate: '18/03/2026', comments: 2, deferrals: 1),
  _O7Agreement(id: 2, description: 'Entregar EPPs completos a cuadrilla de fierreros', responsible: 'L. Torres', dueDate: '20/03/2026', status: 'overdue', group: 'SST', groupColor: const Color(0xFF1B8E5A), meetingDate: '11/03/2026', comments: 0, deferrals: 0),
  _O7Agreement(id: 3, description: 'Solicitar segunda medición topográfica Eje B', responsible: 'R. Chavez', dueDate: '28/03/2026', status: 'completed', group: 'Calidad', groupColor: const Color(0xFFE4A620), meetingDate: '18/03/2026', comments: 1, deferrals: 0),
  _O7Agreement(id: 4, description: 'Coordinar llegada acero con Siderperú', responsible: 'P. Quispe', dueDate: '22/03/2026', status: 'overdue', group: 'Logística', groupColor: const Color(0xFFD64545), meetingDate: '11/03/2026', comments: 3, deferrals: 2),
  _O7Agreement(id: 5, description: 'Actualizar planos As-built de muro perimetral', responsible: 'A. Flores', dueDate: '30/03/2026', status: 'pending', group: 'Calidad', groupColor: const Color(0xFFE4A620), meetingDate: '18/03/2026', comments: 0, deferrals: 0),
  _O7Agreement(id: 6, description: 'Renovar póliza de seguro del proyecto', responsible: 'M. Rodriguez', dueDate: '15/03/2026', status: 'overdue', group: 'Gerencia', groupColor: const Color(0xFF7C3AED), meetingDate: '05/03/2026', comments: 2, deferrals: 1),
];

class O7SubcategoryScreen extends StatefulWidget {
  const O7SubcategoryScreen({super.key});
  @override
  State<O7SubcategoryScreen> createState() => _O7SubcategoryScreenState();
}

class _O7SubcategoryScreenState extends State<O7SubcategoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<_O7Agreement> _agreements;
  String _filter = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _agreements = List.from(_allAgreements);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  List<_O7Agreement> get _filtered {
    switch (_filter) {
      case 'Vencidos': return _agreements.where((a) => a.status == 'overdue').toList();
      case 'Pendientes': return _agreements.where((a) => a.status == 'pending').toList();
      case 'Completados': return _agreements.where((a) => a.status == 'completed').toList();
      default: return _agreements;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comité Semanal de Obra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Reuniones de Obra', style: TextStyle(fontSize: 11, color: Color(0xFF0A66B7), fontWeight: FontWeight.w600)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.brandBlue,
          tabs: [Tab(text: 'Acuerdos', icon: const Icon(Icons.assignment_rounded, size: 16)), const Tab(text: 'Sesiones', icon: Icon(Icons.event_note_rounded, size: 16))],
        ),
        actions: [IconButton(icon: const Icon(Icons.play_circle_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O7SessionScreen())), tooltip: 'Iniciar sesión')],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AgreementsTrackerTab(agreements: _filtered, filter: _filter, onFilterChange: (f) => setState(() => _filter = f), onStatusChange: (id, s) => setState(() => _agreements.firstWhere((a) => a.id == id).status = s)),
          _SessionsTimelineTab(),
        ],
      ),
    );
  }
}

class _AgreementsTrackerTab extends StatelessWidget {
  const _AgreementsTrackerTab({required this.agreements, required this.filter, required this.onFilterChange, required this.onStatusChange});
  final List<_O7Agreement> agreements;
  final String filter;
  final ValueChanged<String> onFilterChange;
  final Function(int, String) onStatusChange;

  static const _filters = ['Todos', 'Vencidos', 'Pendientes', 'Completados'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i]; final sel = f == filter;
                return ChoiceChip(selected: sel, label: Text(f), labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.muted), selectedColor: AppTheme.brandBlue, backgroundColor: AppTheme.stroke.withOpacity(0.40), side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: const VisualDensity(horizontal: -2, vertical: -2), onSelected: (_) => onFilterChange(f));
              },
            ),
          ),
        ),
        Expanded(
          child: agreements.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF1B8E5A)),
                  const SizedBox(height: 12),
                  Text('Todo en orden', style: Theme.of(context).textTheme.titleMedium),
                ]))
              : ListView.separated(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), itemCount: agreements.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _O7AgreementCard(agreement: agreements[i], onStatusChange: onStatusChange)),
        ),
      ],
    );
  }
}

class _O7AgreementCard extends StatelessWidget {
  const _O7AgreementCard({required this.agreement, required this.onStatusChange});
  final _O7Agreement agreement;
  final Function(int, String) onStatusChange;

  Color get _statusColor { switch (agreement.status) { case 'completed': return const Color(0xFF1B8E5A); case 'overdue': return const Color(0xFFD64545); default: return const Color(0xFFE4A620); } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: agreement.status == 'overdue' ? const Color(0xFFD64545).withOpacity(0.40) : AppTheme.stroke), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, decoration: BoxDecoration(color: _statusColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: agreement.groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(agreement.group, style: TextStyle(fontSize: 10, color: agreement.groupColor, fontWeight: FontWeight.w700))),
                  const Spacer(),
                  Text('Reunión: ${agreement.meetingDate}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                ]),
                const SizedBox(height: 8),
                Text(agreement.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 6, children: [
                  _MI(icon: Icons.person_outline_rounded, text: agreement.responsible),
                  _MI(icon: Icons.event_outlined, text: 'Vence: ${agreement.dueDate}'),
                  if (agreement.deferrals > 0) _MI(icon: Icons.redo_rounded, text: '${agreement.deferrals} aplazos', color: const Color(0xFFE4A620)),
                  if (agreement.comments > 0) _MI(icon: Icons.chat_bubble_outline_rounded, text: '${agreement.comments} coment.'),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  SizedBox(width: 150, child: DropdownButtonFormField<String>(value: agreement.status, isDense: true, decoration: InputDecoration(labelText: 'Estado', contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.stroke)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.stroke))),
                    items: const [DropdownMenuItem(value: 'pending', child: Text('Pendiente', style: TextStyle(fontSize: 12))), DropdownMenuItem(value: 'completed', child: Text('Completado', style: TextStyle(fontSize: 12))), DropdownMenuItem(value: 'overdue', child: Text('Vencido', style: TextStyle(fontSize: 12)))],
                    onChanged: (v) { if (v != null) onStatusChange(agreement.id, v); },
                  )),
                  const Spacer(),
                  TextButton.icon(onPressed: () => _showComment(context), icon: const Icon(Icons.add_comment_outlined, size: 15), label: const Text('Comentar', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComment(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Comentar acuerdo', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(agreement.description, style: Theme.of(ctx).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Tu comentario o avance...')),
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

class _SessionsTimelineTab extends StatelessWidget {
  _SessionsTimelineTab();
  final _sessions = [
    {'num': '#19', 'date': '25/03/2026', 'status': 'programmed', 'agreements': 0, 'attendance': 0, 'totalPart': 12},
    {'num': '#18', 'date': '18/03/2026', 'status': 'closed', 'agreements': 4, 'attendance': 10, 'totalPart': 12},
    {'num': '#17', 'date': '11/03/2026', 'status': 'closed', 'agreements': 3, 'attendance': 11, 'totalPart': 12},
    {'num': '#16', 'date': '04/03/2026', 'status': 'closed', 'agreements': 6, 'attendance': 9, 'totalPart': 12},
  ];

  Color _statusColor(String s) { switch (s) { case 'closed': return const Color(0xFF1B8E5A); case 'programmed': return AppTheme.brandBlue; default: return const Color(0xFFE4A620); } }
  IconData _statusIcon(String s) { switch (s) { case 'closed': return Icons.lock_rounded; case 'programmed': return Icons.event_rounded; default: return Icons.radio_button_checked; } }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isProgrammed = session['status'] == 'programmed';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: _statusColor(session['status'] as String).withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: _statusColor(session['status'] as String), width: 2)), child: Icon(_statusIcon(session['status'] as String), size: 18, color: _statusColor(session['status'] as String))),
              if (index < _sessions.length - 1) Container(width: 2, height: 70, color: AppTheme.stroke),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16202B) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.stroke)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text('Sesión ${session['num']}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13.5)), const Spacer(), Text(session['date'] as String, style: Theme.of(context).textTheme.bodySmall)]),
                  const SizedBox(height: 8),
                  if (!isProgrammed) Row(children: [
                    Icon(Icons.people_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text('${session['attendance']}/${session['totalPart']} asistentes', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                    const SizedBox(width: 12),
                    Icon(Icons.assignment_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text('${session['agreements']} acuerdos', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                  ]) else Row(children: [Icon(Icons.notifications_active_outlined, size: 13, color: AppTheme.brandBlue), const SizedBox(width: 4), Text('Programada', style: TextStyle(fontSize: 11, color: AppTheme.brandBlue, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (isProgrammed) Expanded(child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O7SessionScreen())), icon: const Icon(Icons.play_arrow_rounded, size: 16), label: const Text('Iniciar', style: TextStyle(fontSize: 12)), style: FilledButton.styleFrom(minimumSize: const Size(0, 36))))
                    else ...[Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O7SessionScreen())), icon: const Icon(Icons.visibility_outlined, size: 15), label: const Text('Ver acta', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)))), const SizedBox(width: 8), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_rounded, size: 15), label: const Text('PDF', style: TextStyle(fontSize: 12)), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)))],
                  ]),
                ]),
              ),
            )),
          ],
        );
      },
    );
  }
}
