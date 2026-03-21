import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';
import 'o6_hub_screen.dart';
import 'o6_session_screen.dart';

// ─────────────────────────────────────────────
// DUMMY DATA
// ─────────────────────────────────────────────

class _O6Session {
  const _O6Session({
    required this.id,
    required this.name,
    required this.date,
    required this.timeRange,
    required this.status,
    required this.attendedCount,
    required this.totalParticipants,
    required this.newAgreements,
    required this.pendingAgreements,
    required this.closedAt,
  });
  final int id;
  final String name;
  final String date;
  final String timeRange;
  final String status; // 'open' | 'closed' | 'programmed'
  final int attendedCount;
  final int totalParticipants;
  final int newAgreements;
  final int pendingAgreements;
  final String? closedAt;
}

final _dummySessions = <_O6Session>[
  _O6Session(id: 1, name: 'Sesión #18 - Semana 12', date: '18/03/2026', timeRange: '08:00 - 09:30', status: 'closed', attendedCount: 10, totalParticipants: 12, newAgreements: 4, pendingAgreements: 7, closedAt: '18/03/2026 09:35'),
  _O6Session(id: 2, name: 'Sesión #17 - Semana 11', date: '11/03/2026', timeRange: '08:00 - 09:15', status: 'closed', attendedCount: 11, totalParticipants: 12, newAgreements: 3, pendingAgreements: 9, closedAt: '11/03/2026 09:20'),
  _O6Session(id: 3, name: 'Sesión #19 - Semana 13', date: '25/03/2026', timeRange: '08:00 - 09:30', status: 'programmed', attendedCount: 0, totalParticipants: 12, newAgreements: 0, pendingAgreements: 0, closedAt: null),
];

final _dummyParticipants = [
  {'name': 'Carlos Mendoza', 'area': 'Residente de Obra', 'email': 'c.mendoza@obra.pe', 'active': true},
  {'name': 'Lucia Torres', 'area': 'Jefa SST', 'email': 'l.torres@obra.pe', 'active': true},
  {'name': 'Roberto Chavez', 'area': 'Jefe de Calidad', 'email': 'r.chavez@obra.pe', 'active': true},
  {'name': 'Ana Flores', 'area': 'Supervisora', 'email': 'a.flores@obra.pe', 'active': true},
  {'name': 'Pedro Quispe', 'area': 'Contratista Principal', 'email': 'p.quispe@contr.pe', 'active': false},
  {'name': 'Marco Rivera', 'area': 'Subcontratista', 'email': 'm.rivera@sub.pe', 'active': true},
];

// ─────────────────────────────────────────────
// PANTALLA SUBCATEGORÍA — Opción 6
// ─────────────────────────────────────────────

class O6SubcategoryScreen extends StatefulWidget {
  const O6SubcategoryScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.subcategory,
  });

  final String categoryName;
  final Color categoryColor;
  final dynamic subcategory; // _O6Subcategory

  @override
  State<O6SubcategoryScreen> createState() => _O6SubcategoryScreenState();
}

class _O6SubcategoryScreenState extends State<O6SubcategoryScreen>
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.categoryColor;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subcategory.name ?? 'Comité Semanal', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.categoryName, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: color,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: color,
          tabs: const [
            Tab(text: 'Sesiones', icon: Icon(Icons.event_note_rounded, size: 18)),
            Tab(text: 'Participantes', icon: Icon(Icons.people_rounded, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showNewSessionSheet(context),
            tooltip: 'Programar sesión',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SessionsTab(color: color),
          _ParticipantsTab(color: color),
        ],
      ),
    );
  }

  void _showNewSessionSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Programar nueva sesión', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre de la sesión')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_today_rounded, size: 16), label: const Text('Elegir fecha'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.access_time_rounded, size: 16), label: const Text('Horario'))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Guardar sesión'))),
          ],
        ),
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _dummySessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = _dummySessions[index];
        return _O6SessionCard(session: session, color: color);
      },
    );
  }
}

class _O6SessionCard extends StatelessWidget {
  const _O6SessionCard({required this.session, required this.color});

  final _O6Session session;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;

    final statusData = _statusInfo(session.status);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: session.status == 'programmed' ? color.withOpacity(0.30) : AppTheme.stroke,
        ),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: statusData['color'].withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusData['color'].withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusData['icon'], size: 13, color: statusData['color']),
                      const SizedBox(width: 4),
                      Text(statusData['label'], style: TextStyle(fontSize: 11, color: statusData['color'], fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(session.date, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Text(session.timeRange, style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Text(session.status == 'programmed'
                        ? '${session.totalParticipants} esperados'
                        : '${session.attendedCount}/${session.totalParticipants} asistieron',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                if (session.status != 'programmed') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AgreementPill(label: '${session.newAgreements} nuevos', color: color),
                      const SizedBox(width: 8),
                      _AgreementPill(label: '${session.pendingAgreements} pendientes', color: const Color(0xFFE4A620)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (session.status == 'programmed')
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O6SessionScreen())),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Iniciar sesión'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const O6SessionScreen())),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Ver acta'),
                        ),
                      ),
                    if (session.closedAt != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text('PDF'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'closed':
        return {'label': 'Cerrada', 'color': const Color(0xFF1B8E5A), 'icon': Icons.lock_rounded};
      case 'programmed':
        return {'label': 'Programada', 'color': const Color(0xFF0A66B7), 'icon': Icons.event_rounded};
      default:
        return {'label': 'En curso', 'color': const Color(0xFFE4A620), 'icon': Icons.radio_button_checked};
    }
  }
}

class _AgreementPill extends StatelessWidget {
  const _AgreementPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  const _ParticipantsTab({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Participantes registrados', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Agregar'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), textStyle: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._dummyParticipants.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.stroke),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Text((p['name']! as String).split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name']! as String, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 13)),
                    Text(p['area']! as String, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (p['active'] as bool ? const Color(0xFF1B8E5A) : AppTheme.muted).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  p['active'] as bool ? 'Activo' : 'Invitado',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p['active'] as bool ? const Color(0xFF1B8E5A) : AppTheme.muted),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
