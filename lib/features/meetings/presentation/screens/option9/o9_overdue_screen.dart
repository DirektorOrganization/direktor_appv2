import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o9_agreement_detail_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — Pantalla de Acuerdos Vencidos (listado completo con filtros)
// ─────────────────────────────────────────────

class _O9OverdueAgreement {
  const _O9OverdueAgreement({required this.id, required this.desc, required this.resp, required this.due, required this.subcategory, required this.group, required this.groupColor, required this.daysOverdue, required this.deferrals});
  final int id;
  final String desc;
  final String resp;
  final String due;
  final String subcategory;
  final String group;
  final Color groupColor;
  final int daysOverdue;
  final int deferrals;
}

final _overdueAgreements = <_O9OverdueAgreement>[
  _O9OverdueAgreement(id: 1, desc: 'Entregar EPPs completos a cuadrilla de fierreros', resp: 'L. Torres', due: '18/03/2026', subcategory: 'Comité Semanal de Obra', group: 'SST', groupColor: const Color(0xFF1B8E5A), daysOverdue: 3, deferrals: 1),
  _O9OverdueAgreement(id: 2, desc: 'Renovar póliza de seguro del proyecto', resp: 'M. Rodriguez', due: '15/03/2026', subcategory: 'Reunión Quincenal Financiera', group: 'Gerencia', groupColor: const Color(0xFF7C3AED), daysOverdue: 6, deferrals: 2),
  _O9OverdueAgreement(id: 3, desc: 'Coordinar llegada de acero Siderperú', resp: 'P. Quispe', due: '19/03/2026', subcategory: 'Coordinación de Materiales', group: 'Logística', groupColor: const Color(0xFFD64545), daysOverdue: 2, deferrals: 0),
  _O9OverdueAgreement(id: 4, desc: 'Actualizar planos de instalaciones sanitarias nivel 2', resp: 'A. Flores', due: '10/03/2026', subcategory: 'Comité Semanal de Obra', group: 'Calidad', groupColor: const Color(0xFFE4A620), daysOverdue: 11, deferrals: 3),
  _O9OverdueAgreement(id: 5, desc: 'Inspección de andamios zona norte', resp: 'R. Chavez', due: '14/03/2026', subcategory: 'Comité SST Mensual', group: 'SST', groupColor: const Color(0xFF1B8E5A), daysOverdue: 7, deferrals: 1),
  _O9OverdueAgreement(id: 6, desc: 'Presentar informe de avance semana 9', resp: 'C. Mendoza', due: '08/03/2026', subcategory: 'Reunión Quincenal Financiera', group: 'Gerencia', groupColor: const Color(0xFF7C3AED), daysOverdue: 13, deferrals: 0),
  _O9OverdueAgreement(id: 7, desc: 'Verificar stock de cemento para semana 14', resp: 'P. Quispe', due: '17/03/2026', subcategory: 'Coordinación de Materiales', group: 'Logística', groupColor: const Color(0xFFD64545), daysOverdue: 4, deferrals: 0),
  _O9OverdueAgreement(id: 8, desc: 'Revisar cronograma de encofrado nivel 4', resp: 'C. Mendoza', due: '12/03/2026', subcategory: 'Comité Semanal de Obra', group: 'Estructura', groupColor: const Color(0xFF0A66B7), daysOverdue: 9, deferrals: 2),
  _O9OverdueAgreement(id: 9, desc: 'Cierre de observaciones de calidad bloque B', resp: 'R. Chavez', due: '20/03/2026', subcategory: 'Comité Semanal de Obra', group: 'Calidad', groupColor: const Color(0xFFE4A620), daysOverdue: 1, deferrals: 0),
];

class O9OverdueScreen extends StatefulWidget {
  const O9OverdueScreen({super.key});
  @override
  State<O9OverdueScreen> createState() => _O9OverdueScreenState();
}

class _O9OverdueScreenState extends State<O9OverdueScreen> {
  String _filterSub = 'Todos';
  String _filterResp = 'Todos';
  String _filterCat = 'Todas';
  String _sortBy = 'Más vencidos';

  static const _subcategories = ['Todos', 'Comité Semanal de Obra', 'Comité SST Mensual', 'Reunión Quincenal Financiera', 'Coordinación de Materiales'];
  static const _responsibles = ['Todos', 'L. Torres', 'M. Rodriguez', 'P. Quispe', 'A. Flores', 'R. Chavez', 'C. Mendoza'];
  static const _categories = ['Todas', 'SST', 'Gerencia', 'Logística', 'Calidad', 'Estructura'];
  static const _sortOptions = ['Más vencidos', 'Recientes', 'A–Z'];

  List<_O9OverdueAgreement> get _filtered {
    var list = _overdueAgreements.toList();
    if (_filterSub != 'Todos') list = list.where((a) => a.subcategory == _filterSub).toList();
    if (_filterResp != 'Todos') list = list.where((a) => a.resp == _filterResp).toList();
    if (_filterCat != 'Todas') list = list.where((a) => a.group == _filterCat).toList();
    switch (_sortBy) {
      case 'Más vencidos': list.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue)); break;
      case 'Recientes': list.sort((a, b) => a.daysOverdue.compareTo(b.daysOverdue)); break;
      case 'A–Z': list.sort((a, b) => a.desc.compareTo(b.desc)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD64545)),
          const SizedBox(width: 8),
          const Text('Acuerdos Vencidos'),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), tooltip: 'Filtros', onPressed: () => _showFilters(context)),
        ],
      ),
      body: Column(children: [
        // ── Chips de filtros activos ──
        if (_filterSub != 'Todos' || _filterResp != 'Todos' || _filterCat != 'Todas' || _sortBy != 'Más vencidos')
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Wrap(spacing: 8, children: [
              if (_filterSub != 'Todos') _ActiveFilterChip(label: _filterSub, onRemove: () => setState(() => _filterSub = 'Todos')),
              if (_filterResp != 'Todos') _ActiveFilterChip(label: _filterResp, onRemove: () => setState(() => _filterResp = 'Todos')),
              if (_filterCat != 'Todas') _ActiveFilterChip(label: _filterCat, onRemove: () => setState(() => _filterCat = 'Todas')),
              if (_sortBy != 'Más vencidos') _ActiveFilterChip(label: 'Orden: $_sortBy', onRemove: () => setState(() => _sortBy = 'Más vencidos')),
            ]),
          ),
        // ── Contador ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFD64545).withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
              child: Text('${filtered.length} acuerdos vencidos', style: const TextStyle(fontSize: 12, color: Color(0xFFD64545), fontWeight: FontWeight.w700))),
            const Spacer(),
          ]),
        ),
        // ── Lista ──
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF1B8E5A)),
                  const SizedBox(height: 14),
                  Text('No hay acuerdos vencidos con estos filtros', style: theme.textTheme.titleMedium),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    return _OverdueCard(
                      agreement: a, surface: surface,
                      onDefer: () async {
                        final parts = a.due.split('/');
                        if (parts.length < 3) return;
                        final initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                        await showDatePicker(context: context, initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), helpText: 'Nueva fecha límite', confirmText: 'Aplazar', cancelText: 'Cancelar');
                      },
                      onStatusChange: () => _showStatusSheet(context, a),
                      onDetail: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9AgreementDetailScreen(
                        id: a.id, description: a.desc, responsible: a.resp, dueDate: a.due,
                        status: 'overdue', group: a.group, groupColor: a.groupColor,
                        meetingDate: a.subcategory, comments: 1, deferrals: a.deferrals,
                        onStatusChange: (_, __) {},
                      ))),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filtrar acuerdos vencidos', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 20),
            Text('Por categoría (grupo)', style: TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) => ChoiceChip(
              label: Text(c, style: const TextStyle(fontSize: 11)),
              selected: _filterCat == c,
              selectedColor: AppTheme.brandBlue,
              labelStyle: TextStyle(color: _filterCat == c ? Colors.white : null, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              onSelected: (_) => setModalState(() => _filterCat = c),
            )).toList()),
            const SizedBox(height: 16),
            Text('Por subcategoría', style: TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _subcategories.map((s) => ChoiceChip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              selected: _filterSub == s,
              selectedColor: AppTheme.brandBlue,
              labelStyle: TextStyle(color: _filterSub == s ? Colors.white : null, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              onSelected: (_) => setModalState(() => _filterSub = s),
            )).toList()),
            const SizedBox(height: 16),
            Text('Por responsable', style: TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _responsibles.map((r) => ChoiceChip(
              label: Text(r, style: const TextStyle(fontSize: 11)),
              selected: _filterResp == r,
              selectedColor: AppTheme.brandBlue,
              labelStyle: TextStyle(color: _filterResp == r ? Colors.white : null, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              onSelected: (_) => setModalState(() => _filterResp = r),
            )).toList()),
            const SizedBox(height: 16),
            Text('Ordenar por', style: TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: _sortOptions.map((s) => ChoiceChip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              selected: _sortBy == s,
              selectedColor: AppTheme.brandBlue,
              labelStyle: TextStyle(color: _sortBy == s ? Colors.white : null, fontWeight: FontWeight.w600),
              side: BorderSide.none,
              onSelected: (_) => setModalState(() => _sortBy = s),
            )).toList()),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { setState(() {}); Navigator.pop(ctx); }, child: const Text('Aplicar filtros'))),
          ]),
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, _O9OverdueAgreement a) {
    showModalBottomSheet<void>(
      context: context, showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cambiar estado', style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(a.desc, style: TextStyle(fontSize: 12, color: AppTheme.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _StatusBtn(label: 'Pendiente', color: const Color(0xFFE4A620), icon: Icons.schedule_rounded, onTap: () => Navigator.pop(ctx)),
            _StatusBtn(label: 'En proceso', color: AppTheme.brandBlue, icon: Icons.timelapse_rounded, onTap: () => Navigator.pop(ctx)),
            _StatusBtn(label: 'Finalizado', color: const Color(0xFF1B8E5A), icon: Icons.check_circle_rounded, onTap: () => Navigator.pop(ctx)),
          ]),
        ]),
      ),
    );
  }
}



class _OverdueCard extends StatelessWidget {
  const _OverdueCard({required this.agreement, required this.surface, required this.onDefer, required this.onStatusChange, required this.onDetail});
  final _O9OverdueAgreement agreement;
  final Color surface;
  final VoidCallback onDefer;
  final VoidCallback onStatusChange;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gc = agreement.groupColor;
    final daysStr = 'Vencido hace ${agreement.daysOverdue} ${agreement.daysOverdue == 1 ? 'día' : 'días'}';

    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD64545).withOpacity(0.25)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 4, decoration: const BoxDecoration(color: Color(0xFFD64545), borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(agreement.group, style: TextStyle(fontSize: 10, color: gc, fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              Expanded(child: Text(agreement.subcategory, style: TextStyle(fontSize: 10, color: AppTheme.muted), overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFD64545).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(daysStr, style: const TextStyle(fontSize: 10, color: Color(0xFFD64545), fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            Text(agreement.desc, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(spacing: 12, runSpacing: 4, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text(agreement.resp, style: theme.textTheme.bodySmall)]),
              Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_outlined, size: 12, color: AppTheme.muted), const SizedBox(width: 4), Text('Venció: ${agreement.due}', style: const TextStyle(fontSize: 11, color: Color(0xFFD64545), fontWeight: FontWeight.w500))]),
              if (agreement.deferrals > 0) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.redo_rounded, size: 12, color: const Color(0xFFE4A620)), const SizedBox(width: 4), Text('${agreement.deferrals} aplazos', style: const TextStyle(fontSize: 11, color: Color(0xFFE4A620), fontWeight: FontWeight.w500))]),
            ]),
            const SizedBox(height: 10),
            // ── Acciones (igual que seguimiento) ──
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onDefer,
                icon: const Icon(Icons.calendar_today_rounded, size: 12),
                label: const Text('Aplazar', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 28), foregroundColor: const Color(0xFFE4A620), side: const BorderSide(color: Color(0xFFE4A620))),
              )),
              const SizedBox(width: 6),
              Expanded(child: OutlinedButton.icon(
                onPressed: onStatusChange,
                icon: const Icon(Icons.swap_horiz_rounded, size: 12),
                label: const Text('Estado', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 28)),
              )),
              const SizedBox(width: 6),
              Expanded(child: FilledButton.icon(
                onPressed: onDetail,
                icon: const Icon(Icons.open_in_new_rounded, size: 12),
                label: const Text('Detalle', style: TextStyle(fontSize: 11)),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 28)),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  const _StatusBtn({required this.label, required this.color, required this.icon, required this.onTap});
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 14, color: color),
    label: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    style: OutlinedButton.styleFrom(side: BorderSide(color: color.withOpacity(0.50)), minimumSize: const Size(0, 32)),
  );
}


class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    deleteIcon: const Icon(Icons.close_rounded, size: 14),
    onDeleted: onRemove,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    backgroundColor: AppTheme.brandBlue.withOpacity(0.10),
    deleteIconColor: AppTheme.brandBlue,
    labelStyle: TextStyle(color: AppTheme.brandBlue),
    side: BorderSide.none,
  );
}
