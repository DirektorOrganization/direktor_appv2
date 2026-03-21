import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o6_subcategory_screen.dart';

// ─────────────────────────────────────────────
// DUMMY DATA — Opción 6 "Obra Viva"
// ─────────────────────────────────────────────

class _O6Category {
  const _O6Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.subcategories,
  });
  final int id;
  final String name;
  final Color color;
  final IconData icon;
  final List<_O6Subcategory> subcategories;
}

class _O6Subcategory {
  const _O6Subcategory({
    required this.id,
    required this.name,
    required this.totalMeetings,
    required this.pendingAgreements,
    required this.overdueAgreements,
    required this.nextSession,
    required this.participants,
  });
  final int id;
  final String name;
  final int totalMeetings;
  final int pendingAgreements;
  final int overdueAgreements;
  final String? nextSession;
  final int participants;
}

final _dummyCategories = <_O6Category>[
  _O6Category(
    id: 1,
    name: 'Reuniones de Obra',
    color: const Color(0xFF0A66B7),
    icon: Icons.construction_rounded,
    subcategories: [
      _O6Subcategory(id: 11, name: 'Comité Semanal de Obra', totalMeetings: 18, pendingAgreements: 7, overdueAgreements: 2, nextSession: 'Lun 24 Mar - 08:00', participants: 12),
      _O6Subcategory(id: 12, name: 'Coordinación Diaria', totalMeetings: 45, pendingAgreements: 3, overdueAgreements: 0, nextSession: 'Mañana - 07:30', participants: 6),
    ],
  ),
  _O6Category(
    id: 2,
    name: 'SST y Sostenibilidad',
    color: const Color(0xFF1B8E5A),
    icon: Icons.health_and_safety_rounded,
    subcategories: [
      _O6Subcategory(id: 21, name: 'Comité de SST Mensual', totalMeetings: 4, pendingAgreements: 5, overdueAgreements: 1, nextSession: 'Vie 28 Mar - 10:00', participants: 8),
      _O6Subcategory(id: 22, name: 'Charla Semanal 5 min', totalMeetings: 20, pendingAgreements: 0, overdueAgreements: 0, nextSession: 'Lun 24 Mar - 07:00', participants: 30),
    ],
  ),
  _O6Category(
    id: 3,
    name: 'Gerencia y Finanzas',
    color: const Color(0xFFE4A620),
    icon: Icons.account_balance_rounded,
    subcategories: [
      _O6Subcategory(id: 31, name: 'Reunión Quincenal Financiera', totalMeetings: 7, pendingAgreements: 4, overdueAgreements: 2, nextSession: 'Mar 01 Abr - 15:00', participants: 5),
      _O6Subcategory(id: 32, name: 'Revisión de Avance Mensual', totalMeetings: 3, pendingAgreements: 6, overdueAgreements: 3, nextSession: null, participants: 9),
    ],
  ),
  _O6Category(
    id: 4,
    name: 'Procura y Logística',
    color: const Color(0xFFD64545),
    icon: Icons.local_shipping_rounded,
    subcategories: [
      _O6Subcategory(id: 41, name: 'Coordinación de Materiales', totalMeetings: 10, pendingAgreements: 8, overdueAgreements: 4, nextSession: 'Mié 26 Mar - 09:00', participants: 7),
    ],
  ),
];

// ─────────────────────────────────────────────
// PANTALLA HUB — Opción 6
// ─────────────────────────────────────────────

class O6HubScreen extends StatefulWidget {
  const O6HubScreen({super.key});

  @override
  State<O6HubScreen> createState() => _O6HubScreenState();
}

class _O6HubScreenState extends State<O6HubScreen> {
  int _totalOverdue = 0;
  int _totalPending = 0;
  int _totalMeetings = 0;

  @override
  void initState() {
    super.initState();
    for (final cat in _dummyCategories) {
      for (final sub in cat.subcategories) {
        _totalOverdue += sub.overdueAgreements;
        _totalPending += sub.pendingAgreements;
        _totalMeetings += sub.totalMeetings;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta de Reuniones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {},
            tooltip: 'Nueva categoría',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _O6SummaryBanner(
                  overdueAgreements: _totalOverdue,
                  pendingAgreements: _totalPending,
                  totalMeetings: _totalMeetings,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text('Categorías de reunión', style: theme.textTheme.titleMedium),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = _dummyCategories[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: _O6CategoryCard(
                      category: cat,
                      surfaceColor: surfaceColor,
                      onTapSubcategory: (sub) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => O6SubcategoryScreen(
                              categoryName: cat.name,
                              categoryColor: cat.color,
                              subcategory: sub,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: _dummyCategories.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS INTERNOS
// ─────────────────────────────────────────────

class _O6SummaryBanner extends StatelessWidget {
  const _O6SummaryBanner({
    required this.overdueAgreements,
    required this.pendingAgreements,
    required this.totalMeetings,
  });

  final int overdueAgreements;
  final int pendingAgreements;
  final int totalMeetings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A66B7), Color(0xFF1581D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Residencial Las Lomas', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  Text('Próxima sesión: Lun 24 Mar — 08:00', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _BannerMetric(value: '$totalMeetings', label: 'Sesiones', icon: Icons.event_note_rounded, color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(child: _BannerMetric(value: '$pendingAgreements', label: 'Pendientes', icon: Icons.schedule_rounded, color: const Color(0xFFFFF2DD))),
              const SizedBox(width: 8),
              Expanded(child: _BannerMetric(value: '$overdueAgreements', label: 'Vencidos', icon: Icons.error_outline_rounded, color: const Color(0xFFFFCDD2))),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({required this.value, required this.label, required this.icon, required this.color});

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _O6CategoryCard extends StatelessWidget {
  const _O6CategoryCard({
    required this.category,
    required this.surfaceColor,
    required this.onTapSubcategory,
  });

  final _O6Category category;
  final Color surfaceColor;
  final ValueChanged<_O6Subcategory> onTapSubcategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const [
          BoxShadow(color: Color(0x0A17324D), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: category.color.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(category.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${category.subcategories.length} subcat.',
                    style: TextStyle(color: category.color, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          // Subcategorías
          ...category.subcategories.asMap().entries.map((entry) {
            final i = entry.key;
            final sub = entry.value;
            final isLast = i == category.subcategories.length - 1;
            return _O6SubcategoryTile(
              sub: sub,
              color: category.color,
              isLast: isLast,
              onTap: () => onTapSubcategory(sub),
            );
          }),
        ],
      ),
    );
  }
}

class _O6SubcategoryTile extends StatelessWidget {
  const _O6SubcategoryTile({
    required this.sub,
    required this.color,
    required this.isLast,
    required this.onTap,
  });

  final _O6Subcategory sub;
  final Color color;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOverdue = sub.overdueAgreements > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: hasOverdue ? const Color(0xFFD64545) : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    children: [
                      _MiniChip(label: '${sub.totalMeetings} sesiones', icon: Icons.event_rounded, color: AppTheme.muted),
                      _MiniChip(label: '${sub.participants} part.', icon: Icons.people_outline_rounded, color: AppTheme.muted),
                      if (sub.pendingAgreements > 0)
                        _MiniChip(label: '${sub.pendingAgreements} pend.', icon: Icons.schedule_rounded, color: const Color(0xFFE4A620)),
                      if (hasOverdue)
                        _MiniChip(label: '${sub.overdueAgreements} venc.', icon: Icons.warning_amber_rounded, color: const Color(0xFFD64545)),
                    ],
                  ),
                  if (sub.nextSession != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text('Próxima: ${sub.nextSession}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
