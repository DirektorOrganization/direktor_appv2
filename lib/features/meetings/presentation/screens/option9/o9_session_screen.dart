import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o9_agreement_detail_screen.dart';
import 'o9_comments_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Pantalla de Sesión de Acta
// Estructura base de O8 + filtros + secciones
// ─────────────────────────────────────────────

class _Att { _Att({required this.name, required this.area, required this.present}); final String name; final String area; bool present; }

class _Ag {
  _Ag({required this.id, required this.desc, required this.resp, required this.due, required this.status, required this.group, required this.gc, required this.comments, required this.isFromPrevious, this.deferrals = 0, this.isInformative = false});
  final int id; final String desc; final String resp; String due; String status; final String group; final Color gc; final int comments; final bool isFromPrevious; int deferrals; final bool isInformative;
}

class O9SessionScreen extends StatefulWidget {
  const O9SessionScreen({super.key});
  @override
  State<O9SessionScreen> createState() => _O9SessionScreenState();
}

class _O9SessionScreenState extends State<O9SessionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<_Att> _att;
  late final List<_Ag> _ag;
  final List<String> _groups = ['Estructura', 'SST', 'Calidad', 'Logística', 'Gerencia'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _att = [
      _Att(name: 'Carlos Mendoza', area: 'Residente', present: true),
      _Att(name: 'Lucia Torres', area: 'Jefa SST', present: true),
      _Att(name: 'Roberto Chavez', area: 'Jefe Calidad', present: false),
      _Att(name: 'Ana Flores', area: 'Supervisora', present: true),
      _Att(name: 'Pedro Quispe', area: 'Contratista', present: true),
      _Att(name: 'Marco Rivera', area: 'Subcontratista', present: false),
    ];
    _ag = [
      _Ag(id: 1, desc: 'Revisar cronograma de concreto nivel 3', resp: 'C. Mendoza', due: '25/03/2026', status: 'pending', group: 'Estructura', gc: const Color(0xFF0A66B7), comments: 2, isFromPrevious: false),
      _Ag(id: 2, desc: 'Presentar cuadro de metrados actualizado', resp: 'R. Chavez', due: '25/03/2026', status: 'pending', group: 'Calidad', gc: const Color(0xFFE4A620), comments: 1, isFromPrevious: false),
      _Ag(id: 3, desc: 'Validar compatibilidad planos MEP con nivel 4', resp: 'A. Flores', due: '30/03/2026', status: 'in_progress', group: 'Estructura', gc: const Color(0xFF0A66B7), comments: 0, isFromPrevious: false),
      // Pendientes de sesiones anteriores
      _Ag(id: 4, desc: 'Entregar EPPs completos a cuadrilla de fierreros', resp: 'L. Torres', due: '20/03/2026', status: 'overdue', group: 'SST', gc: const Color(0xFF1B8E5A), comments: 5, isFromPrevious: true),
      _Ag(id: 5, desc: 'Coordinar llegada de acero con Siderperú', resp: 'P. Quispe', due: '22/03/2026', status: 'overdue', group: 'Logística', gc: const Color(0xFFD64545), comments: 3, isFromPrevious: true, deferrals: 2),
      _Ag(id: 6, desc: 'Renovar póliza de seguro del proyecto', resp: 'M. Rodriguez', due: '15/03/2026', status: 'overdue', group: 'Gerencia', gc: const Color(0xFF7C3AED), comments: 2, isFromPrevious: true, deferrals: 1),
      // Informativos
      _Ag(id: 7, desc: 'Se informa que la entrega de materiales será los días viernes a partir de la semana 14.', resp: '', due: '', status: 'info', group: 'Logística', gc: const Color(0xFFD64545), comments: 0, isFromPrevious: false, isInformative: true),
      _Ag(id: 8, desc: 'El próximo comité ejecutivo será el 28 de marzo a las 10:00 am en sala principal.', resp: '', due: '', status: 'info', group: 'Gerencia', gc: const Color(0xFF7C3AED), comments: 0, isFromPrevious: false, isInformative: true),
    ];
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  int get _present => _att.where((a) => a.present).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sesión #19 — Sem. 13', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('25 Mar 2026 · 08:00 – 09:30', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [
          TextButton.icon(onPressed: () => _closeDialog(context), icon: const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF1B8E5A)), label: const Text('Cerrar Acta', style: TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700, fontSize: 12))),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.brandBlue,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.how_to_reg_rounded, size: 14), const SizedBox(width: 3),
              Text('Asistencia $_present/${_att.length}', style: const TextStyle(fontSize: 11)),
            ])),
            const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.fact_check_rounded, size: 14), SizedBox(width: 3),
              Text('Acuerdos', style: TextStyle(fontSize: 11)),
            ])),
            const Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.article_rounded, size: 14), SizedBox(width: 3),
              Text('Acta', style: TextStyle(fontSize: 11)),
            ])),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AttTab(att: _att, onToggle: (i) => setState(() => _att[i].present = !_att[i].present)),
          _AgTab(
            ag: _ag, groups: _groups,
            onStatusChange: (id, s) => setState(() => _ag.firstWhere((a) => a.id == id).status = s),
            onDefer: (id, d) => setState(() { final a = _ag.firstWhere((x) => x.id == id); a.due = d; a.deferrals++; }),
            onAdd: (ag) => setState(() => _ag.insert(0, ag)),
            onAddGroup: (g) => setState(() { if (!_groups.contains(g)) _groups.add(g); }),
          ),
          _ActaTab(att: _att, ag: _ag),
        ],
      ),
    );
  }

  void _closeDialog(BuildContext context) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cerrar acta de reunión'),
      content: const Text('Se generará el PDF del acta y se enviará a todos los participantes. Esta acción no se puede deshacer.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Cerrar y generar PDF'))],
    ));
  }
}

// ─────────────────────────────────────────────
// TAB: ASISTENCIA (igual que O8)
// ─────────────────────────────────────────────

class _AttTab extends StatelessWidget {
  const _AttTab({required this.att, required this.onToggle});
  final List<_Att> att; final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final present = att.where((a) => a.present).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1B8E5A).withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.how_to_reg_rounded, size: 16, color: Color(0xFF1B8E5A)), const SizedBox(width: 8), Text('$present / ${att.length} presentes', style: const TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700, fontSize: 13))])),
      const SizedBox(height: 16),
      ...att.asMap().entries.map((e) {
        final i = e.key; final p = e.value;
        return Container(margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.06) : AppTheme.stroke.withOpacity(0.30), borderRadius: BorderRadius.circular(12), border: Border.all(color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.25) : AppTheme.stroke)),
          child: ListTile(
            dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: CircleAvatar(radius: 16, backgroundColor: p.present ? const Color(0xFF1B8E5A).withOpacity(0.15) : AppTheme.stroke, child: Text(p.name.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.present ? const Color(0xFF1B8E5A) : AppTheme.muted))),
            title: Text(p.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13)),
            subtitle: Text(p.area, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
            trailing: Switch.adaptive(value: p.present, activeColor: const Color(0xFF1B8E5A), onChanged: (_) => onToggle(i)),
          ),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────
// TAB: ACUERDOS — con filtros + secciones + acciones
// ─────────────────────────────────────────────

class _AgTab extends StatefulWidget {
  const _AgTab({required this.ag, required this.groups, required this.onStatusChange, required this.onDefer, required this.onAdd, required this.onAddGroup});
  final List<_Ag> ag;
  final List<String> groups;
  final Function(int, String) onStatusChange;
  final Function(int, String) onDefer;
  final Function(_Ag) onAdd;
  final Function(String) onAddGroup;
  @override
  State<_AgTab> createState() => _AgTabState();
}

class _AgTabState extends State<_AgTab> {
  String _filter = 'Todos';
  bool _showPrevious = true;
  static const _filters = ['Todos', 'Vencidos', 'Pendientes', 'En proceso', 'Completados', 'Informativos'];

  static const _groupColors = {
    'Estructura': Color(0xFF0A66B7), 'SST': Color(0xFF1B8E5A), 'Calidad': Color(0xFFE4A620),
    'Logística': Color(0xFFD64545), 'Gerencia': Color(0xFF7C3AED),
  };

  List<_Ag> get _filteredCurrent {
    final current = widget.ag.where((a) => !a.isFromPrevious);
    return _applyFilter(current);
  }

  List<_Ag> get _filteredPrevious {
    final prev = widget.ag.where((a) => a.isFromPrevious);
    return _applyFilter(prev);
  }

  List<_Ag> _applyFilter(Iterable<_Ag> source) {
    switch (_filter) {
      case 'Vencidos': return source.where((a) => a.status == 'overdue').toList();
      case 'Pendientes': return source.where((a) => a.status == 'pending').toList();
      case 'En proceso': return source.where((a) => a.status == 'in_progress').toList();
      case 'Completados': return source.where((a) => a.status == 'completed').toList();
      case 'Informativos': return source.where((a) => a.isInformative).toList();
      default: return source.toList();
    }
  }

  void _addDialog() {
    final descCtrl = TextEditingController();
    final respCtrl = TextEditingController();
    final newGroupCtrl = TextEditingController();
    String selectedGroup = widget.groups.first;
    bool isInformative = false;

    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nuevo acuerdo', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            // Toggle informativo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: isInformative ? const Color(0xFF0A66B7).withOpacity(0.08) : AppTheme.stroke.withOpacity(0.30), borderRadius: BorderRadius.circular(10), border: Border.all(color: isInformative ? const Color(0xFF0A66B7).withOpacity(0.40) : AppTheme.stroke)),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: isInformative ? const Color(0xFF0A66B7) : AppTheme.muted),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Acuerdo informativo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isInformative ? const Color(0xFF0A66B7) : AppTheme.muted)),
                  Text('Sin seguimiento ni responsable', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
                ])),
                Switch.adaptive(value: isInformative, activeColor: const Color(0xFF0A66B7),
                  onChanged: (v) => setModal(() => isInformative = v)),
              ]),
            ),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, maxLines: 3, decoration: InputDecoration(labelText: isInformative ? 'Nota informativa' : 'Descripción del acuerdo')),
            if (!isInformative) ...[
              const SizedBox(height: 12),
              TextField(controller: respCtrl, decoration: const InputDecoration(labelText: 'Responsable', prefixIcon: Icon(Icons.person_outline_rounded))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedGroup,
                decoration: const InputDecoration(labelText: 'Grupo de acuerdo', prefixIcon: Icon(Icons.folder_outlined)),
                items: widget.groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) { if (v != null) setModal(() => selectedGroup = v); },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: newGroupCtrl, decoration: const InputDecoration(labelText: 'Nuevo grupo (opcional)', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    if (newGroupCtrl.text.trim().isNotEmpty) {
                      final name = newGroupCtrl.text.trim();
                      widget.onAddGroup(name);
                      setModal(() { selectedGroup = name; newGroupCtrl.clear(); });
                    }
                  },
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('Crear'),
                ),
              ]),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_today_rounded, size: 16), label: const Text('Fecha límite')),
            ],
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (descCtrl.text.trim().isNotEmpty) {
                  if (isInformative) {
                    widget.onAdd(_Ag(id: DateTime.now().millisecondsSinceEpoch, desc: descCtrl.text.trim(), resp: '', due: '', status: 'info', group: selectedGroup, gc: _groupColors[selectedGroup] ?? AppTheme.brandBlue, comments: 0, isFromPrevious: false, isInformative: true));
                  } else {
                    final gc = _groupColors[selectedGroup] ?? AppTheme.brandBlue;
                    widget.onAdd(_Ag(id: DateTime.now().millisecondsSinceEpoch, desc: descCtrl.text.trim(), resp: respCtrl.text.trim().isEmpty ? 'Sin asignar' : respCtrl.text.trim(), due: '30/03/2026', status: 'pending', group: selectedGroup, gc: gc, comments: 0, isFromPrevious: false));
                  }
                }
                Navigator.pop(ctx);
              },
              child: Text(isInformative ? 'Agregar nota informativa' : 'Agregar acuerdo'),
            )),

          ]),
        ),
      ),
    );
  }

  void _showDeferPicker(int id, String currentDue) async {
    final parts = currentDue.split('/');
    if (parts.length < 3) return;
    final initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    final picked = await showDatePicker(
      context: context, helpText: 'Nueva fecha límite', confirmText: 'Aplazar', cancelText: 'Cancelar',
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      widget.onDefer(id, '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final current = _filteredCurrent;
    final previous = _filteredPrevious;

    return Stack(children: [
      Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: SizedBox(height: 32, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final f = _filters[i]; final sel = f == _filter;
            return ChoiceChip(selected: sel, label: Text(f), labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppTheme.muted), selectedColor: AppTheme.brandBlue, backgroundColor: AppTheme.stroke.withOpacity(0.40), side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 4), visualDensity: const VisualDensity(horizontal: -2, vertical: -2), onSelected: (_) => setState(() => _filter = f));
          },
        )),
      ),
      // Lista
      Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          // ── Esta sesión ──
          if (current.isNotEmpty) ...[
            _SectionHeader(label: 'Esta sesión (${current.length})', icon: Icons.radio_button_checked, color: const Color(0xFF1B8E5A)),
            const SizedBox(height: 6),
            ...current.map((a) => _AgCard(ag: a, surface: surface, onStatusChange: widget.onStatusChange, onDefer: (id) => _showDeferPicker(id, a.due))),
          ],
          // ── Pendientes históricas ──
          if (previous.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _showPrevious = !_showPrevious),
              borderRadius: BorderRadius.circular(10),
              child: _SectionHeader(
                label: 'Pendientes de otras fechas (${previous.length})',
                icon: Icons.history_rounded, color: const Color(0xFFD64545),
                trailing: Icon(_showPrevious ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.muted),
              ),
            ),
            if (_showPrevious) ...[
              const SizedBox(height: 6),
              ...previous.map((a) => _AgCard(ag: a, surface: surface, onStatusChange: widget.onStatusChange, onDefer: (id) => _showDeferPicker(id, a.due))),
            ],
          ],
          if (current.isEmpty && previous.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF1B8E5A)),
                const SizedBox(height: 12),
                Text('Sin acuerdos en este filtro', style: theme.textTheme.titleMedium),
              ])),
            ),
        ],
      )),
      ]),
      // FAB para agregar acuerdo
      Positioned(
        right: 16, bottom: 16,
        child: FloatingActionButton(
          onPressed: _addDialog,
          mini: true,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon, required this.color, this.trailing});
  final String label; final IconData icon; final Color color; final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, size: 14, color: color), const SizedBox(width: 7),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
      if (trailing != null) ...[const Spacer(), trailing!],
    ]),
  );
}

class _AgCard extends StatelessWidget {
  const _AgCard({required this.ag, required this.surface, required this.onStatusChange, required this.onDefer});
  final _Ag ag; final Color surface; final Function(int, String) onStatusChange; final Function(int) onDefer;

  Color get _sc { switch (ag.status) { case 'completed': return const Color(0xFF1B8E5A); case 'overdue': return const Color(0xFFD64545); case 'in_progress': return AppTheme.brandBlue; default: return const Color(0xFFE4A620); } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Informativo: card distinto ──
    if (ag.isInformative) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A66B7).withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0A66B7).withOpacity(0.20)),
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28, height: 28, margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(color: const Color(0xFF0A66B7).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0A66B7)),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF0A66B7).withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                child: const Text('Informativo', style: TextStyle(fontSize: 10, color: Color(0xFF0A66B7), fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ag.gc.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                child: Text(ag.group, style: TextStyle(fontSize: 10, color: ag.gc, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            Text(ag.desc, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.4)),
          ])),
        ])),
      );
    }

    // ── Card normal de acuerdo ──
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: ag.gc, width: 4)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 6)]),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ag.gc.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
            child: Text(ag.group, style: TextStyle(fontSize: 10, color: ag.gc, fontWeight: FontWeight.w700))),
          if (ag.isFromPrevious) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFD64545).withOpacity(0.10), borderRadius: BorderRadius.circular(5)),
            child: const Text('Fecha ant.', style: TextStyle(fontSize: 9, color: Color(0xFFD64545), fontWeight: FontWeight.w700)))],
          const Spacer(),
          Container(height: 24, padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: _sc.withOpacity(0.10), borderRadius: BorderRadius.circular(7), border: Border.all(color: _sc.withOpacity(0.30))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: ag.status, isDense: true,
              style: TextStyle(fontSize: 10, color: _sc, fontWeight: FontWeight.w700),
              icon: Icon(Icons.arrow_drop_down, size: 14, color: _sc),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pendiente', style: TextStyle(fontSize: 10))),
                DropdownMenuItem(value: 'in_progress', child: Text('En proceso', style: TextStyle(fontSize: 10))),
                DropdownMenuItem(value: 'completed', child: Text('Finalizado', style: TextStyle(fontSize: 10))),
                DropdownMenuItem(value: 'overdue', child: Text('Vencido', style: TextStyle(fontSize: 10))),
              ],
              onChanged: (v) { if (v != null) onStatusChange(ag.id, v); },
            )),
          ),
        ]),
        const SizedBox(height: 6),
        Text(ag.desc, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
        const SizedBox(height: 5),
        Row(children: [
          Icon(Icons.person_outline_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 3),
          Text(ag.resp, style: TextStyle(fontSize: 11, color: AppTheme.muted)),
          const SizedBox(width: 8),
          Icon(Icons.event_outlined, size: 11, color: AppTheme.muted), const SizedBox(width: 3),
          Text(ag.due, style: TextStyle(fontSize: 11, color: ag.status == 'overdue' ? const Color(0xFFD64545) : AppTheme.muted, fontWeight: ag.status == 'overdue' ? FontWeight.w700 : FontWeight.normal)),
          if (ag.deferrals > 0) ...[const SizedBox(width: 6), Icon(Icons.redo_rounded, size: 11, color: const Color(0xFFE4A620)), const SizedBox(width: 3), Text('${ag.deferrals}', style: const TextStyle(fontSize: 10, color: Color(0xFFE4A620), fontWeight: FontWeight.w700))],
          if (ag.comments > 0) ...[const SizedBox(width: 8), Icon(Icons.chat_bubble_outline_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 3), Text('${ag.comments}', style: TextStyle(fontSize: 11, color: AppTheme.muted))],
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _ABtn(icon: Icons.calendar_today_rounded, label: 'Aplazar', onTap: () => onDefer(ag.id)),
          const SizedBox(width: 6),
          _ABtn(icon: Icons.chat_bubble_outline_rounded, label: ag.comments > 0 ? '${ag.comments} coments.' : 'Comentar', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9CommentsScreen(agreementTitle: ag.desc, agreementGroup: ag.group, groupColor: ag.gc)))),
          const SizedBox(width: 6),
          _ABtn(icon: Icons.open_in_new_rounded, label: 'Detalle', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9AgreementDetailScreen(
            id: ag.id, description: ag.desc, responsible: ag.resp, dueDate: ag.due,
            status: ag.status, group: ag.group, groupColor: ag.gc, meetingDate: '25/03/2026',
            comments: ag.comments, deferrals: ag.deferrals, onStatusChange: onStatusChange,
          )))),
        ]),
      ])),
    );
  }
}

class _ABtn extends StatelessWidget {
  const _ABtn({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.stroke.withOpacity(0.40), borderRadius: BorderRadius.circular(7)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: AppTheme.muted), const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────
// TAB: ACTA (igual que O8)
// ─────────────────────────────────────────────

class _ActaTab extends StatelessWidget {
  const _ActaTab({required this.att, required this.ag});
  final List<_Att> att; final List<_Ag> ag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final present = att.where((a) => a.present).length;
    final completed = ag.where((a) => a.status == 'completed').length;
    final overdue = ag.where((a) => a.status == 'overdue').length;
    final pending = ag.where((a) => a.status == 'pending' || a.status == 'in_progress').length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Acta de Reunión — Sesión #19', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.brandBlue, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Comité Semanal de Obra · 25 Marzo 2026', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Asistentes presentes', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: att.where((a) => a.present).map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1B8E5A).withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_rounded, size: 12, color: Color(0xFF1B8E5A)), const SizedBox(width: 5), Text(a.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B8E5A)))]),
      )).toList()),
      const SizedBox(height: 16),
      Text('Resumen de acuerdos', style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _ActaStat(value: '${ag.length}', label: 'Total', color: AppTheme.brandBlue)),
        Expanded(child: _ActaStat(value: '$completed', label: 'OK', color: const Color(0xFF1B8E5A))),
        Expanded(child: _ActaStat(value: '$pending', label: 'Pend.', color: const Color(0xFFE4A620))),
        Expanded(child: _ActaStat(value: '$overdue', label: 'Venc.', color: const Color(0xFFD64545))),
      ]),
      const SizedBox(height: 14),
      ...ag.where((a) => a.status != 'completed').map((a) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.stroke)),
        child: Row(children: [
          Container(width: 6, height: 36, decoration: BoxDecoration(color: a.gc, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.desc, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2), Text('${a.resp} · Vence: ${a.due}', style: TextStyle(fontSize: 10, color: AppTheme.muted)),
          ])),
        ]),
      )),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.picture_as_pdf_rounded, color: AppTheme.brandBlue, size: 16), const SizedBox(width: 8), Text('Generar PDF del acta', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.brandBlue, fontSize: 13))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_rounded, size: 14), label: const Text('Vista previa', style: TextStyle(fontSize: 11)))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_rounded, size: 14), label: const Text('Enviar a todos', style: TextStyle(fontSize: 11))))]),
        ])),
    ]);
  }
}

class _ActaStat extends StatelessWidget {
  const _ActaStat({required this.value, required this.label, required this.color});
  final String value; final String label; final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
  ]);
}
