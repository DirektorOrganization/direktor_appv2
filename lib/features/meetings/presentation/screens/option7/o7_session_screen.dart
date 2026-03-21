import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';

class _Agreement {
  _Agreement({required this.id, required this.description, required this.responsible, required this.dueDate, required this.status, required this.group, required this.groupColor, required this.comments});
  final int id; final String description; final String responsible;
  final String dueDate; String status; final String group;
  final Color groupColor; final int comments;
}

final _agreements = <_Agreement>[
  _Agreement(id: 1, description: 'Revisar cronograma de concreto nivel 3', responsible: 'C. Mendoza', dueDate: '25/03/2026', status: 'pending', group: 'Estructura', groupColor: const Color(0xFF0A66B7), comments: 2),
  _Agreement(id: 2, description: 'Entregar EPPs completos a fierreros', responsible: 'L. Torres', dueDate: '20/03/2026', status: 'overdue', group: 'SST', groupColor: const Color(0xFF1B8E5A), comments: 0),
  _Agreement(id: 3, description: 'Medición topográfica Eje B', responsible: 'R. Chavez', dueDate: '28/03/2026', status: 'completed', group: 'Calidad', groupColor: const Color(0xFFE4A620), comments: 1),
  _Agreement(id: 4, description: 'Coordinar llegada de acero con Siderperú', responsible: 'P. Quispe', dueDate: '22/03/2026', status: 'pending', group: 'Logística', groupColor: const Color(0xFFD64545), comments: 3),
];

final _attendance = [
  {'name': 'Carlos Mendoza', 'area': 'Residente', 'present': true},
  {'name': 'Lucia Torres', 'area': 'Jefa SST', 'present': true},
  {'name': 'Roberto Chavez', 'area': 'Jefe Calidad', 'present': false},
  {'name': 'Ana Flores', 'area': 'Supervisora', 'present': true},
  {'name': 'Pedro Quispe', 'area': 'Contratista', 'present': true},
  {'name': 'Marco Rivera', 'area': 'Subcontratista', 'present': false},
];

class O7SessionScreen extends StatefulWidget {
  const O7SessionScreen({super.key});
  @override
  State<O7SessionScreen> createState() => _O7SessionScreenState();
}

class _O7SessionScreenState extends State<O7SessionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<Map<String, dynamic>> _att;
  late final List<_Agreement> _ag;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _att = _attendance.map((e) => Map<String, dynamic>.from(e)).toList();
    _ag = List.from(_agreements);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final present = _att.where((p) => p['present'] as bool).length;
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sesión #18 — Sem. 12', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('18 Mar 2026 · 08:00 – 09:30', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [TextButton.icon(onPressed: () => _closeDialog(context), icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF1B8E5A)), label: const Text('Cerrar', style: TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700)))],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.brandBlue,
          tabs: [Tab(text: 'Asistencia ($present/${_att.length})', icon: const Icon(Icons.how_to_reg_rounded, size: 16)), const Tab(text: 'Acuerdos', icon: Icon(Icons.fact_check_rounded, size: 16)), const Tab(text: 'Resumen', icon: Icon(Icons.summarize_rounded, size: 16))],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AttTab(att: _att, onToggle: (i) => setState(() => _att[i]['present'] = !(_att[i]['present'] as bool))),
          _AgTab(ag: _ag, onChange: (id, s) => setState(() => _ag.firstWhere((a) => a.id == id).status = s), onAdd: () => _addDialog(context)),
          _ResumenTab(att: _att, ag: _ag),
        ],
      ),
    );
  }

  void _closeDialog(BuildContext context) {
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Cerrar acta de reunión'),
      content: const Text('Se generará un PDF y se enviará a todos los participantes. Esta acción no se puede deshacer.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Cerrar y generar PDF'))],
    ));
  }

  void _addDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nuevo acuerdo', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción del acuerdo')),
          const SizedBox(height: 12), OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_today_rounded, size: 16), label: const Text('Fecha límite')),
          const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Agregar acuerdo'))),
        ]),
      ),
    );
  }
}

class _AttTab extends StatelessWidget {
  const _AttTab({required this.att, required this.onToggle});
  final List<Map<String, dynamic>> att;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final present = att.where((p) => p['present'] as bool).length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1B8E5A).withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.how_to_reg_rounded, color: Color(0xFF1B8E5A)), const SizedBox(width: 8), Text('$present / ${att.length} presentes', style: const TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700, fontSize: 16))])),
      const SizedBox(height: 16),
      ...att.asMap().entries.map((entry) {
        final i = entry.key; final p = entry.value; final here = p['present'] as bool;
        return Container(margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: here ? const Color(0xFF1B8E5A).withOpacity(0.06) : AppTheme.stroke.withOpacity(0.30), borderRadius: BorderRadius.circular(14), border: Border.all(color: here ? const Color(0xFF1B8E5A).withOpacity(0.25) : AppTheme.stroke)),
          child: ListTile(
            leading: CircleAvatar(radius: 18, backgroundColor: here ? const Color(0xFF1B8E5A).withOpacity(0.15) : AppTheme.stroke, child: Text(p['name']!.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: here ? const Color(0xFF1B8E5A) : AppTheme.muted))),
            title: Text(p['name']!, style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text(p['area']!, style: Theme.of(context).textTheme.bodySmall),
            trailing: Switch.adaptive(value: here, activeColor: const Color(0xFF1B8E5A), onChanged: (_) => onToggle(i)),
          ),
        );
      }),
    ]);
  }
}

class _AgTab extends StatelessWidget {
  const _AgTab({required this.ag, required this.onChange, required this.onAdd});
  final List<_Agreement> ag;
  final Function(int, String) onChange;
  final VoidCallback onAdd;

  Color _sColor(String s) { switch (s) { case 'completed': return const Color(0xFF1B8E5A); case 'overdue': return const Color(0xFFD64545); default: return const Color(0xFFE4A620); } }
  String _sLabel(String s) { switch (s) { case 'completed': return 'Completado'; case 'overdue': return 'Vencido'; default: return 'Pendiente'; } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [Text('Acuerdos', style: theme.textTheme.titleMedium), const Spacer(), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Agregar'), style: FilledButton.styleFrom(minimumSize: const Size(0, 36), textStyle: const TextStyle(fontSize: 12)))]),
      const SizedBox(height: 14),
      ...ag.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: a.groupColor, width: 4)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: a.groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(a.group, style: TextStyle(fontSize: 10, color: a.groupColor, fontWeight: FontWeight.w700))),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _sColor(a.status).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(_sLabel(a.status), style: TextStyle(fontSize: 10, color: _sColor(a.status), fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8),
          Text(a.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Row(children: [Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text(a.responsible, style: theme.textTheme.bodySmall), const SizedBox(width: 12), Icon(Icons.event_outlined, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text(a.dueDate, style: theme.textTheme.bodySmall), const Spacer(), if (a.comments > 0) Row(children: [Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text('${a.comments}', style: theme.textTheme.bodySmall)])]),
          const SizedBox(height: 10),
          if (a.status != 'completed') TextButton.icon(onPressed: () => onChange(a.id, 'completed'), icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF1B8E5A)), label: const Text('Completar', style: TextStyle(color: Color(0xFF1B8E5A), fontSize: 12)), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28))),
        ])),
      )),
    ]);
  }
}

class _ResumenTab extends StatelessWidget {
  const _ResumenTab({required this.att, required this.ag});
  final List<Map<String, dynamic>> att;
  final List<_Agreement> ag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final present = att.where((p) => p['present'] as bool).length;
    final completed = ag.where((a) => a.status == 'completed').length;
    final overdue = ag.where((a) => a.status == 'overdue').length;
    final pending = ag.where((a) => a.status == 'pending').length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Resumen de la sesión', style: theme.textTheme.titleMedium),
      const SizedBox(height: 16),
      _Row(icon: Icons.how_to_reg_rounded, color: const Color(0xFF1B8E5A), label: 'Asistencia', value: '$present / ${att.length}'),
      _Row(icon: Icons.fact_check_rounded, color: AppTheme.brandBlue, label: 'Total acuerdos', value: '${ag.length}'),
      _Row(icon: Icons.check_circle_rounded, color: const Color(0xFF1B8E5A), label: 'Completados', value: '$completed'),
      _Row(icon: Icons.schedule_rounded, color: const Color(0xFFE4A620), label: 'Pendientes', value: '$pending'),
      _Row(icon: Icons.warning_amber_rounded, color: const Color(0xFFD64545), label: 'Vencidos', value: '$overdue'),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.picture_as_pdf_rounded, color: AppTheme.brandBlue, size: 20), const SizedBox(width: 8), Text('Acta generada', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.brandBlue))]),
          const SizedBox(height: 6), Text('Acta_S18_18032026.pdf', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded, size: 16), label: const Text('Descargar'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_rounded, size: 16), label: const Text('Enviar')))]),
        ])),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon; final Color color; final String label; final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 12), Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
      Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
    ]));
  }
}
