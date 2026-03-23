import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o9_subcategory_screen.dart';
import 'o9_category_screen.dart';
import 'o9_overdue_screen.dart';
import 'o9_session_screen.dart';
import 'o9_agreement_detail_screen.dart';

// ─────────────────────────────────────────────
// OPCIÓN 9 — "Panel Ejecutivo +" (evolución de Opción 8)
// ─────────────────────────────────────────────

class _O9KPI {
  const _O9KPI({required this.value, required this.label, required this.icon, required this.color, required this.trend});
  final String value; final String label; final IconData icon; final Color color; final String trend;
}

class _O9SubRow {
  const _O9SubRow({required this.name, required this.category, required this.categoryColor, required this.overdue, required this.pending, required this.nextDate, required this.hasActiveSession});
  final String name; final String category; final Color categoryColor;
  final int overdue; final int pending; final String? nextDate; final bool hasActiveSession;
}

final _o9Kpis = <_O9KPI>[
  _O9KPI(value: '9', label: 'Vencidos', icon: Icons.error_rounded, color: const Color(0xFFD64545), trend: '+2 vs sem. ant.'),
  _O9KPI(value: '27', label: 'Pendientes', icon: Icons.schedule_rounded, color: const Color(0xFFE4A620), trend: '-5 vs sem. ant.'),
  _O9KPI(value: '63%', label: 'Cumplimiento', icon: Icons.pie_chart_rounded, color: const Color(0xFF1B8E5A), trend: '+4% vs sem. ant.'),
  _O9KPI(value: '4', label: 'Subcategorías', icon: Icons.folder_rounded, color: AppTheme.brandBlue, trend: 'activas'),
];

final _o9SubRows = <_O9SubRow>[
  _O9SubRow(name: 'Comité Semanal de Obra', category: 'Obra', categoryColor: const Color(0xFF0A66B7), overdue: 2, pending: 7, nextDate: 'Lun 24 Mar', hasActiveSession: true),
  _O9SubRow(name: 'Comité SST Mensual', category: 'SST', categoryColor: const Color(0xFF1B8E5A), overdue: 1, pending: 5, nextDate: 'Vie 28 Mar', hasActiveSession: false),
  _O9SubRow(name: 'Reunión Financiera', category: 'Gerencia', categoryColor: const Color(0xFF7C3AED), overdue: 3, pending: 4, nextDate: null, hasActiveSession: false),
  _O9SubRow(name: 'Coord. de Materiales', category: 'Logística', categoryColor: const Color(0xFFD64545), overdue: 4, pending: 8, nextDate: 'Mié 26 Mar', hasActiveSession: false),
];

// Sólo los 3 primeros para mostrar en el hub (por daysOverdue desc)
final _o9OverduePreview = [
  {'desc': 'Presentar informe de avance semana 9', 'resp': 'C. Mendoza', 'due': '08/03/2026', 'daysOverdue': 13, 'group': 'Gerencia', 'groupColor': const Color(0xFF7C3AED)},
  {'desc': 'Actualizar planos de instalaciones sanitarias nivel 2', 'resp': 'A. Flores', 'due': '10/03/2026', 'daysOverdue': 11, 'group': 'Calidad', 'groupColor': const Color(0xFFE4A620)},
  {'desc': 'Revisar cronograma de encofrado nivel 4', 'resp': 'C. Mendoza', 'due': '12/03/2026', 'daysOverdue': 9, 'group': 'Estructura', 'groupColor': const Color(0xFF0A66B7)},
];

// ─────────────────────────────────────────────
// PANTALLA HUB — Opción 9
// ─────────────────────────────────────────────

class O9HubScreen extends StatelessWidget {
  const O9HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta de Reuniones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.category_rounded),
            tooltip: 'Gestionar categorías',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9CategoryScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Solo sesión activa (sin KPI strip) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Residencial Las Lomas', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('Panorama general del módulo', style: theme.textTheme.bodySmall),
                ]),
              ),
            ),
            // ── Sesión activa banner ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ActiveSessionBanner(onEnter: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SessionScreen()))),
              ),
            ),
            // ── Acuerdos vencidos (máx. 3) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD64545)),
                    const SizedBox(width: 6),
                    Text('Acuerdos vencidos', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFFD64545))),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9OverdueScreen())),
                      child: const Text('Ver todos', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final a = _o9OverduePreview[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _OverduePreviewCard(
                      agreement: a, surface: surface,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => O9AgreementDetailScreen(
                        id: i, description: a['desc'] as String, responsible: a['resp'] as String,
                        dueDate: a['due'] as String, status: 'overdue', group: a['group'] as String,
                        groupColor: a['groupColor'] as Color, meetingDate: 'Comité Sem. #18',
                        comments: 2, deferrals: 0, onStatusChange: (_, __) {},
                      ))),
                    ),
                  );
                },
                childCount: _o9OverduePreview.length,
              ),
            ),
            // ── Subcategorías ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text('Subcategorías y sesiones', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9CategoryScreen())),
                      icon: const Icon(Icons.edit_rounded, size: 14),
                      label: const Text('Gestionar', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _O9SubCard(sub: _o9SubRows[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SubcategoryScreen()))),
                ),
                childCount: _o9SubRows.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets del Hub ───

class _KPIBox extends StatelessWidget {
  const _KPIBox({required this.kpi});
  final _O9KPI kpi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kpi.color.withOpacity(0.25)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: kpi.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(kpi.icon, size: 16, color: kpi.color)),
        const SizedBox(height: 8),
        Text(kpi.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kpi.color)),
        Text(kpi.label, style: TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(kpi.trend, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.onEnter});
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A3D62), Color(0xFF0A66B7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Sesión en curso', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          const Text('Comité Semanal #18 — Sem. 12', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: const [
            Icon(Icons.access_time_rounded, size: 11, color: Colors.white60), SizedBox(width: 3),
            Text('08:00 – Hoy', style: TextStyle(color: Colors.white60, fontSize: 10)),
            SizedBox(width: 8),
            Icon(Icons.people_outline_rounded, size: 11, color: Colors.white60), SizedBox(width: 3),
            Text('10/12', style: TextStyle(color: Colors.white60, fontSize: 10)),
          ]),
        ])),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onEnter,
          style: FilledButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.20), minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: const Text('Entrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
    );
  }
}

class _OverduePreviewCard extends StatelessWidget {
  const _OverduePreviewCard({required this.agreement, required this.surface, required this.onTap});
  final Map<String, dynamic> agreement;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gc = agreement['groupColor'] as Color;
    final days = agreement['daysOverdue'] as int;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD64545).withOpacity(0.25)), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 6)]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(agreement['group'] as String, style: TextStyle(fontSize: 10, color: gc, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(agreement['desc'] as String, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.muted), const SizedBox(width: 4),
                Text(agreement['resp'] as String, style: theme.textTheme.bodySmall),
                const SizedBox(width: 10),
                Icon(Icons.warning_amber_rounded, size: 12, color: const Color(0xFFD64545)), const SizedBox(width: 4),
                Text('Hace $days días', style: const TextStyle(fontSize: 11, color: Color(0xFFD64545), fontWeight: FontWeight.w600)),
              ]),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD64545)),
          ]),
        ),
      ),
    );
  }
}

class _O9SubCard extends StatelessWidget {
  const _O9SubCard({required this.sub, required this.onTap});
  final _O9SubRow sub;
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
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: hasAlert ? const Color(0xFFD64545).withOpacity(0.30) : AppTheme.stroke), boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8)]),
          child: Row(children: [
            Container(width: 6, height: 44, decoration: BoxDecoration(color: sub.categoryColor, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(sub.name, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: sub.categoryColor.withOpacity(0.10), borderRadius: BorderRadius.circular(4)), child: Text(sub.category, style: TextStyle(fontSize: 10, color: sub.categoryColor, fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                if (sub.overdue > 0) _Pill(label: '${sub.overdue} venc.', color: const Color(0xFFD64545)),
                if (sub.overdue > 0 && sub.pending > 0) const SizedBox(width: 6),
                if (sub.pending > 0) _Pill(label: '${sub.pending} pend.', color: const Color(0xFFE4A620)),
              ]),
              const SizedBox(height: 6),
              // Indicador de sesión
              if (sub.hasActiveSession)
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1B8E5A), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('Sesión en curso', style: TextStyle(fontSize: 11, color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700)),
                  const Spacer(),
                  SizedBox(height: 24, child: FilledButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O9SessionScreen())),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 24), textStyle: const TextStyle(fontSize: 10)),
                    child: const Text('Entrar'),
                  )),
                ])
              else if (sub.nextDate != null)
                Row(children: [
                  Icon(Icons.event_rounded, size: 12, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text('Próxima: ${sub.nextDate}', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                ])
              else
                Row(children: [
                  Icon(Icons.event_busy_rounded, size: 12, color: AppTheme.muted),
                  const SizedBox(width: 4),
                  Text('Sin sesiones agendadas', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
                ]),
            ])),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
          ]),
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
