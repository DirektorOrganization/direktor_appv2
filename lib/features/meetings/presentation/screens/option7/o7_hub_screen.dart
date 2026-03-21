import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o7_subcategory_screen.dart';

// ─────────────────────────────────────────────
// DUMMY DATA — Opción 7 "Acuerdos Primero"
// ─────────────────────────────────────────────

class _O7AgreementGroup {
  const _O7AgreementGroup({required this.name, required this.color, required this.total, required this.pending, required this.overdue, required this.completed});
  final String name;
  final Color color;
  final int total;
  final int pending;
  final int overdue;
  final int completed;
}

class _O7SubcategoryPreview {
  const _O7SubcategoryPreview({required this.name, required this.category, required this.categoryColor, required this.lastSession, required this.nextSession, required this.overdueCount, required this.pendingCount});
  final String name;
  final String category;
  final Color categoryColor;
  final String lastSession;
  final String? nextSession;
  final int overdueCount;
  final int pendingCount;
}

final _agreementGroups = <_O7AgreementGroup>[
  _O7AgreementGroup(name: 'Estructura', color: const Color(0xFF0A66B7), total: 22, pending: 5, overdue: 2, completed: 15),
  _O7AgreementGroup(name: 'SST', color: const Color(0xFF1B8E5A), total: 18, pending: 3, overdue: 1, completed: 14),
  _O7AgreementGroup(name: 'Calidad', color: const Color(0xFFE4A620), total: 14, pending: 4, overdue: 3, completed: 7),
  _O7AgreementGroup(name: 'Logística', color: const Color(0xFFD64545), total: 20, pending: 8, overdue: 4, completed: 8),
  _O7AgreementGroup(name: 'Gerencia', color: const Color(0xFF7C3AED), total: 9, pending: 2, overdue: 0, completed: 7),
];

final _subcategoryPreviews = <_O7SubcategoryPreview>[
  _O7SubcategoryPreview(name: 'Comité Semanal de Obra', category: 'Reuniones de Obra', categoryColor: const Color(0xFF0A66B7), lastSession: '18/03/2026', nextSession: 'Lun 24 Mar', overdueCount: 2, pendingCount: 7),
  _O7SubcategoryPreview(name: 'Comité de SST Mensual', category: 'SST y Sostenibilidad', categoryColor: const Color(0xFF1B8E5A), lastSession: '10/03/2026', nextSession: 'Vie 28 Mar', overdueCount: 1, pendingCount: 5),
  _O7SubcategoryPreview(name: 'Reunión Quincenal Financiera', category: 'Gerencia y Finanzas', categoryColor: const Color(0xFFE4A620), lastSession: '05/03/2026', nextSession: null, overdueCount: 3, pendingCount: 4),
  _O7SubcategoryPreview(name: 'Coordinación de Materiales', category: 'Procura y Logística', categoryColor: const Color(0xFFD64545), lastSession: '17/03/2026', nextSession: 'Mié 26 Mar', overdueCount: 4, pendingCount: 8),
];

// ─────────────────────────────────────────────
// PANTALLA HUB — Opción 7
// ─────────────────────────────────────────────

class O7HubScreen extends StatefulWidget {
  const O7HubScreen({super.key});

  @override
  State<O7HubScreen> createState() => _O7HubScreenState();
}

class _O7HubScreenState extends State<O7HubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int get _totalOverdue => _agreementGroups.fold(0, (s, g) => s + g.overdue);
  int get _totalPending => _agreementGroups.fold(0, (s, g) => s + g.pending);
  int get _totalCompleted => _agreementGroups.fold(0, (s, g) => s + g.completed);
  int get _grandTotal => _agreementGroups.fold(0, (s, g) => s + g.total);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compliance = _grandTotal > 0 ? _totalCompleted / _grandTotal : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta de Reuniones'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.brandBlue,
          tabs: const [
            Tab(text: 'Seguimiento', icon: Icon(Icons.track_changes_rounded, size: 18)),
            Tab(text: 'Sesiones', icon: Icon(Icons.calendar_month_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AgreementsOverviewTab(
            groups: _agreementGroups,
            totalOverdue: _totalOverdue,
            totalPending: _totalPending,
            totalCompleted: _totalCompleted,
            grandTotal: _grandTotal,
            compliance: compliance,
          ),
          _SessionsOverviewTab(subcategories: _subcategoryPreviews),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB: SEGUIMIENTO DE ACUERDOS
// ─────────────────────────────────────────────

class _AgreementsOverviewTab extends StatelessWidget {
  const _AgreementsOverviewTab({
    required this.groups,
    required this.totalOverdue,
    required this.totalPending,
    required this.totalCompleted,
    required this.grandTotal,
    required this.compliance,
  });

  final List<_O7AgreementGroup> groups;
  final int totalOverdue, totalPending, totalCompleted, grandTotal;
  final double compliance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Tarjeta de cumplimiento global
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A66B7), Color(0xFF1581D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cumplimiento global de acuerdos', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${(compliance * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  Text('$totalCompleted / $grandTotal completados', style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: compliance,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.20),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatPill(value: '$totalPending', label: 'Pendientes', color: const Color(0xFFFFF2DD)),
                  const SizedBox(width: 8),
                  _StatPill(value: '$totalOverdue', label: 'Vencidos', color: const Color(0xFFFFCDD2)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Por grupo de acuerdo', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...groups.map((g) => _O7GroupCard(group: g, surface: surface)),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _O7GroupCard extends StatelessWidget {
  const _O7GroupCard({required this.group, required this.surface});
  final _O7AgreementGroup group;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = group.total > 0 ? group.completed / group.total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: group.color, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: group.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(group.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
              const Spacer(),
              Text('${(pct * 100).round()}%', style: TextStyle(color: group.color, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppTheme.stroke,
              valueColor: AlwaysStoppedAnimation(group.color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _GroupStat(value: '${group.total}', label: 'Total', color: AppTheme.muted),
              const SizedBox(width: 14),
              _GroupStat(value: '${group.completed}', label: 'OK', color: const Color(0xFF1B8E5A)),
              const SizedBox(width: 14),
              _GroupStat(value: '${group.pending}', label: 'Pend.', color: const Color(0xFFE4A620)),
              const SizedBox(width: 14),
              _GroupStat(value: '${group.overdue}', label: 'Venc.', color: const Color(0xFFD64545)),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                child: const Text('Ver acuerdos', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupStat extends StatelessWidget {
  const _GroupStat({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TAB: SESIONES / SUBCATEGORÍAS
// ─────────────────────────────────────────────

class _SessionsOverviewTab extends StatelessWidget {
  const _SessionsOverviewTab({required this.subcategories});
  final List<_O7SubcategoryPreview> subcategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Subcategorías activas', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nueva'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), textStyle: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...subcategories.map((sub) => _O7SubcategoryCard(sub: sub)),
      ],
    );
  }
}

class _O7SubcategoryCard extends StatelessWidget {
  const _O7SubcategoryCard({required this.sub});
  final _O7SubcategoryPreview sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O7SubcategoryScreen())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 38,
                      decoration: BoxDecoration(color: sub.categoryColor, borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.5)),
                          const SizedBox(height: 3),
                          Text(sub.category, style: TextStyle(fontSize: 11, color: sub.categoryColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoTag(label: 'Última: ${sub.lastSession}', icon: Icons.history_rounded, color: AppTheme.muted),
                    const SizedBox(width: 8),
                    if (sub.nextSession != null)
                      _InfoTag(label: 'Próxima: ${sub.nextSession!}', icon: Icons.event_rounded, color: sub.categoryColor),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (sub.overdueCount > 0) ...[
                      _AlertPill(count: sub.overdueCount, label: 'vencidos', color: const Color(0xFFD64545)),
                      const SizedBox(width: 8),
                    ],
                    if (sub.pendingCount > 0)
                      _AlertPill(count: sub.pendingCount, label: 'pendientes', color: const Color(0xFFE4A620)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O7SubcategoryScreen())),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                      child: const Text('Ver acuerdos →', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AlertPill extends StatelessWidget {
  const _AlertPill({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$count $label', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
