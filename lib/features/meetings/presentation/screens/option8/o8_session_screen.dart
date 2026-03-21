import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';

class O8SessionScreen extends StatefulWidget {
  const O8SessionScreen({super.key});
  @override
  State<O8SessionScreen> createState() => _O8SessionScreenState();
}

class _Att { _Att({required this.name, required this.area, required this.present}); final String name; final String area; bool present; }
class _Ag { _Ag({required this.id, required this.desc, required this.resp, required this.due, required this.status, required this.group, required this.gc, required this.comments}); final int id; final String desc; final String resp; final String due; String status; final String group; final Color gc; final int comments; }

class _O8SessionScreenState extends State<O8SessionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<_Att> _att;
  late final List<_Ag> _ag;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _att = [_Att(name: 'Carlos Mendoza', area: 'Residente', present: true), _Att(name: 'Lucia Torres', area: 'Jefa SST', present: true), _Att(name: 'Roberto Chavez', area: 'Jefe Calidad', present: false), _Att(name: 'Ana Flores', area: 'Supervisora', present: true), _Att(name: 'Pedro Quispe', area: 'Contratista', present: true), _Att(name: 'Marco Rivera', area: 'Subcontratista', present: false)];
    _ag = [_Ag(id: 1, desc: 'Revisar cronograma de concreto nivel 3', resp: 'C. Mendoza', due: '25/03/2026', status: 'pending', group: 'Estructura', gc: const Color(0xFF0A66B7), comments: 2), _Ag(id: 2, desc: 'Entregar EPPs a fierreros', resp: 'L. Torres', due: '20/03/2026', status: 'overdue', group: 'SST', gc: const Color(0xFF1B8E5A), comments: 0), _Ag(id: 3, desc: 'Medición topográfica Eje B', resp: 'R. Chavez', due: '28/03/2026', status: 'completed', group: 'Calidad', gc: const Color(0xFFE4A620), comments: 1), _Ag(id: 4, desc: 'Coordinar acero con Siderperú', resp: 'P. Quispe', due: '22/03/2026', status: 'pending', group: 'Logística', gc: const Color(0xFFD64545), comments: 3)];
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
          TextButton.icon(onPressed: () => _closeDialog(context), icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF1B8E5A)), label: const Text('Cerrar Acta', style: TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700))),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue, unselectedLabelColor: AppTheme.muted, indicatorColor: AppTheme.brandBlue,
          tabs: [
            Tab(text: 'Asistencia ($_present/${_att.length})', icon: const Icon(Icons.how_to_reg_rounded, size: 16)),
            const Tab(text: 'Acuerdos', icon: Icon(Icons.fact_check_rounded, size: 16)),
            const Tab(text: 'Acta', icon: Icon(Icons.article_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AttTab(att: _att, onToggle: (i) => setState(() => _att[i].present = !_att[i].present)),
          _AgTab(ag: _ag, onStatusChange: (id, s) => setState(() => _ag.firstWhere((a) => a.id == id).status = s), onAdd: () => _addDialog(context)),
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

  void _addDialog(BuildContext context) {
    showModalBottomSheet<void>(context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nuevo acuerdo', style: Theme.of(ctx).textTheme.titleMedium), const SizedBox(height: 16),
          const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Descripción del acuerdo')), const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_today_rounded, size: 16), label: const Text('Fecha límite')), const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Agregar acuerdo'))),
        ]),
      ),
    );
  }
}

class _AttTab extends StatelessWidget {
  const _AttTab({required this.att, required this.onToggle});
  final List<_Att> att; final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final present = att.where((a) => a.present).length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF1B8E5A).withOpacity(0.10), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.how_to_reg_rounded, color: Color(0xFF1B8E5A)), const SizedBox(width: 8), Text('$present / ${att.length} presentes', style: const TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700, fontSize: 16))])),
      const SizedBox(height: 16),
      ...att.asMap().entries.map((e) {
        final i = e.key; final p = e.value;
        return Container(margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.06) : AppTheme.stroke.withOpacity(0.30), borderRadius: BorderRadius.circular(14), border: Border.all(color: p.present ? const Color(0xFF1B8E5A).withOpacity(0.25) : AppTheme.stroke)),
          child: ListTile(
            leading: CircleAvatar(radius: 18, backgroundColor: p.present ? const Color(0xFF1B8E5A).withOpacity(0.15) : AppTheme.stroke, child: Text(p.name.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.present ? const Color(0xFF1B8E5A) : AppTheme.muted))),
            title: Text(p.name, style: Theme.of(context).textTheme.bodyLarge),
            subtitle: Text(p.area, style: Theme.of(context).textTheme.bodySmall),
            trailing: Switch.adaptive(value: p.present, activeColor: const Color(0xFF1B8E5A), onChanged: (_) => onToggle(i)),
          ),
        );
      }),
    ]);
  }
}

class _AgTab extends StatelessWidget {
  const _AgTab({required this.ag, required this.onStatusChange, required this.onAdd});
  final List<_Ag> ag; final Function(int, String) onStatusChange; final VoidCallback onAdd;

  Color _sc(String s) { switch (s) { case 'completed': return const Color(0xFF1B8E5A); case 'overdue': return const Color(0xFFD64545); default: return const Color(0xFFE4A620); } }
  String _sl(String s) { switch (s) { case 'completed': return 'Completado'; case 'overdue': return 'Vencido'; default: return 'Pendiente'; } }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [Text('Acuerdos de sesión', style: theme.textTheme.titleMedium), const Spacer(), FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Agregar'), style: FilledButton.styleFrom(minimumSize: const Size(0, 36), textStyle: const TextStyle(fontSize: 12)))]),
      const SizedBox(height: 14),
      ...ag.map((a) => Container(margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: a.gc, width: 4)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: a.gc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(a.group, style: TextStyle(fontSize: 10, color: a.gc, fontWeight: FontWeight.w700))),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _sc(a.status).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(_sl(a.status), style: TextStyle(fontSize: 10, color: _sc(a.status), fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 8), Text(a.desc, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 6),
          Row(children: [Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text(a.resp, style: theme.textTheme.bodySmall), const SizedBox(width: 12), Icon(Icons.event_outlined, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text(a.due, style: theme.textTheme.bodySmall), if (a.comments > 0) ...[const SizedBox(width: 12), Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text('${a.comments}', style: theme.textTheme.bodySmall)]]),
          const SizedBox(height: 10),
          if (a.status != 'completed') TextButton.icon(onPressed: () => onStatusChange(a.id, 'completed'), icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF1B8E5A)), label: const Text('Completar', style: TextStyle(color: Color(0xFF1B8E5A), fontSize: 12)), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28))),
        ])),
      )),
    ]);
  }
}

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
    final pending = ag.where((a) => a.status == 'pending').length;

    return ListView(padding: const EdgeInsets.all(20), children: [
      // Header acta
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Acta de Reunión — Sesión #19', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.brandBlue)),
          const SizedBox(height: 4),
          Text('Comité Semanal de Obra · 25 Marzo 2026', style: theme.textTheme.bodySmall),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Asistentes presentes', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: att.where((a) => a.present).map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFF1B8E5A).withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_rounded, size: 14, color: Color(0xFF1B8E5A)), const SizedBox(width: 6), Text(a.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B8E5A)))]),
      )).toList()),
      const SizedBox(height: 16),
      Text('Resumen de acuerdos', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
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
            Text(a.desc, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2), Text('${a.resp} · Vence: ${a.due}', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ])),
        ]),
      )),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.brandBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.picture_as_pdf_rounded, color: AppTheme.brandBlue, size: 20), const SizedBox(width: 8), Text('Generar PDF del acta', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.brandBlue, fontSize: 14))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_rounded, size: 16), label: const Text('Vista previa'))), const SizedBox(width: 8), Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_rounded, size: 16), label: const Text('Enviar a todos')))]),
        ])),
    ]);
  }
}

class _ActaStat extends StatelessWidget {
  const _ActaStat({required this.value, required this.label, required this.color});
  final String value; final String label; final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
  ]);
}
