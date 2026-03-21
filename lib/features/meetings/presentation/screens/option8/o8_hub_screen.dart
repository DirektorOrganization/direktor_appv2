import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o8_subcategory_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 8 — "Panel Ejecutivo"
// Dashboard de alto nivel: KPIs urgentes, resumen por subcategoría,
// acceso rápido a sesión activa. Estilo premium, dark-friendly.
// ─────────────────────────────────────────────

class _O8KPI {
  const _O8KPI({required this.value, required this.label, required this.icon, required this.color, required this.trend});
  final String value; final String label; final IconData icon; final Color color; final String trend;
}

class _O8SubRow {
  const _O8SubRow({required this.name, required this.category, required this.categoryColor, required this.overdue, required this.pending, required this.nextDate, required this.hasActiveSession});
  final String name; final String category; final Color categoryColor;
  final int overdue; final int pending; final String? nextDate; final bool hasActiveSession;
}

final _kpis = <_O8KPI>[
  _O8KPI(value: '9', label: 'Vencidos', icon: Icons.error_rounded, color: const Color(0xFFD64545), trend: '+2 vs sem. ant.'),
  _O8KPI(value: '27', label: 'Pendientes', icon: Icons.schedule_rounded, color: const Color(0xFFE4A620), trend: '-5 vs sem. ant.'),
  _O8KPI(value: '63%', label: 'Cumplimiento', icon: Icons.pie_chart_rounded, color: const Color(0xFF1B8E5A), trend: '+4% vs sem. ant.'),
  _O8KPI(value: '4', label: 'Subcategorías', icon: Icons.folder_rounded, color: AppTheme.brandBlue, trend: 'activas'),
];

final _subRows = <_O8SubRow>[
  _O8SubRow(name: 'Comité Semanal de Obra', category: 'Obra', categoryColor: const Color(0xFF0A66B7), overdue: 2, pending: 7, nextDate: 'Lun 24 Mar', hasActiveSession: true),
  _O8SubRow(name: 'Comité SST Mensual', category: 'SST', categoryColor: const Color(0xFF1B8E5A), overdue: 1, pending: 5, nextDate: 'Vie 28 Mar', hasActiveSession: false),
  _O8SubRow(name: 'Reunión Financiera', category: 'Gerencia', categoryColor: const Color(0xFFE4A620), overdue: 3, pending: 4, nextDate: null, hasActiveSession: false),
  _O8SubRow(name: 'Coord. de Materiales', category: 'Logística', categoryColor: const Color(0xFFD64545), overdue: 4, pending: 8, nextDate: 'Mié 26 Mar', hasActiveSession: false),
];

final _urgentAgreements = [
  {'desc': 'Entregar EPPs a cuadrilla de fierreros', 'resp': 'L. Torres', 'due': 'Vencido hace 2 días', 'group': 'SST', 'groupColor': const Color(0xFF1B8E5A)},
  {'desc': 'Coordinar llegada de acero Siderperú', 'resp': 'P. Quispe', 'due': 'Vence hoy', 'group': 'Logística', 'groupColor': const Color(0xFFD64545)},
  {'desc': 'Renovar póliza de seguro del proyecto', 'resp': 'M. Rodriguez', 'due': 'Vencido hace 5 días', 'group': 'Gerencia', 'groupColor': const Color(0xFF7C3AED)},
];

// ─────────────────────────────────────────────
// PANTALLA HUB — Opción 8
// ─────────────────────────────────────────────

class O8HubScreen extends StatelessWidget {
  const O8HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta de Reuniones'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── KPI Strip ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Residencial Las Lomas', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Panorama general del módulo', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 14),
                    Row(
                      children: _kpis.map((k) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: k == _kpis.last ? 0 : 8),
                          child: _KPIBox(kpi: k),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            // ── Sesión activa banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ActiveSessionBanner(),
              ),
            ),
            // ── Acuerdos urgentes ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.priority_high_rounded, size: 18, color: Color(0xFFD64545)),
                    const SizedBox(width: 6),
                    Text('Acuerdos críticos', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFFD64545))),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('Ver todos', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final a = _urgentAgreements[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _UrgentCard(agreement: a, surface: surface),
                  );
                },
                childCount: _urgentAgreements.length,
              ),
            ),
            // ── Subcategorías ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text('Subcategorías y sesiones', style: theme.textTheme.titleMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _O8SubRow2Card(sub: _subRows[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O8SubcategoryScreen()))),
                ),
                childCount: _subRows.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _KPIBox extends StatelessWidget {
  const _KPIBox({required this.kpi});
  final _O8KPI kpi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kpi.color.withOpacity(0.25)),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: kpi.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(kpi.icon, size: 16, color: kpi.color)),
          const SizedBox(height: 8),
          Text(kpi.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kpi.color)),
          Text(kpi.label, style: TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(kpi.trend, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  _ActiveSessionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A3D62), Color(0xFF0A66B7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.radio_button_checked, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sesión en curso', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const Text('Comité Semanal #18 — Sem. 12', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Row(children: const [
                  Icon(Icons.access_time_rounded, size: 12, color: Colors.white60),
                  SizedBox(width: 4),
                  Text('08:00 – Hoy', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  SizedBox(width: 10),
                  Icon(Icons.people_outline_rounded, size: 12, color: Colors.white60),
                  SizedBox(width: 4),
                  Text('10/12 presentes', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ]),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.20), minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: const Text('Entrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.agreement, required this.surface});
  final Map<String, dynamic> agreement;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gc = agreement['groupColor'] as Color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD64545).withOpacity(0.25)),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(agreement['group'] as String, style: TextStyle(fontSize: 10, color: gc, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agreement['desc'] as String, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text(agreement['resp'] as String, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 10),
                  Icon(Icons.warning_amber_rounded, size: 12, color: const Color(0xFFD64545)),
                  const SizedBox(width: 4),
                  Text(agreement['due'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFFD64545), fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _O8SubRow2Card extends StatelessWidget {
  const _O8SubRow2Card({required this.sub, required this.onTap});
  final _O8SubRow sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final hasAlert = sub.overdue > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hasAlert ? const Color(0xFFD64545).withOpacity(0.30) : AppTheme.stroke),
            boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 44,
                decoration: BoxDecoration(color: sub.categoryColor, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(sub.name, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (sub.hasActiveSession) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF1B8E5A).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('En curso', style: TextStyle(fontSize: 10, color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sub.categoryColor.withOpacity(0.10), borderRadius: BorderRadius.circular(4)), child: Text(sub.category, style: TextStyle(fontSize: 10, color: sub.categoryColor, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      if (sub.nextDate != null) Row(children: [Icon(Icons.event_rounded, size: 11, color: AppTheme.muted), const SizedBox(width: 3), Text(sub.nextDate!, style: TextStyle(fontSize: 11, color: AppTheme.muted))]),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      if (sub.overdue > 0) _Pill(label: '${sub.overdue} venc.', color: const Color(0xFFD64545)),
                      if (sub.overdue > 0 && sub.pending > 0) const SizedBox(width: 6),
                      if (sub.pending > 0) _Pill(label: '${sub.pending} pend.', color: const Color(0xFFE4A620)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
  );
}
