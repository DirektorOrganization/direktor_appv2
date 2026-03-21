import 'package:flutter/material.dart';
import '../../../../../../app/theme/app_theme.dart';

// ─────────────────────────────────────────────
// DUMMY DATA
// ─────────────────────────────────────────────

class _SessionAgreement {
  _SessionAgreement({required this.id, required this.description, required this.responsible, required this.dueDate, required this.status, required this.group, required this.groupColor, required this.comments});
  final int id;
  final String description;
  final String responsible;
  final String dueDate;
  String status;
  final String group;
  final Color groupColor;
  final int comments;
}

final _dummyAttendance = [
  {'name': 'Carlos Mendoza', 'area': 'Residente', 'present': true},
  {'name': 'Lucia Torres', 'area': 'Jefa SST', 'present': true},
  {'name': 'Roberto Chavez', 'area': 'Jefe Calidad', 'present': false},
  {'name': 'Ana Flores', 'area': 'Supervisora', 'present': true},
  {'name': 'Pedro Quispe', 'area': 'Contratista', 'present': true},
  {'name': 'Marco Rivera', 'area': 'Subcontratista', 'present': false},
];

final _dummyAgreements = <_SessionAgreement>[
  _SessionAgreement(id: 1, description: 'Revisar cronograma de concreto del nivel 3', responsible: 'C. Mendoza', dueDate: '25/03/2026', status: 'pending', group: 'Estructura', groupColor: const Color(0xFF0A66B7), comments: 2),
  _SessionAgreement(id: 2, description: 'Entregar EPPs completos a cuadrilla de fierreros', responsible: 'L. Torres', dueDate: '22/03/2026', status: 'overdue', group: 'SST', groupColor: const Color(0xFF1B8E5A), comments: 0),
  _SessionAgreement(id: 3, description: 'Solicitar segunda medición topográfica Eje B', responsible: 'R. Chavez', dueDate: '28/03/2026', status: 'completed', group: 'Calidad', groupColor: const Color(0xFFE4A620), comments: 1),
  _SessionAgreement(id: 4, description: 'Coordinar llegada de acero con proveedor Siderperú', responsible: 'P. Quispe', dueDate: '24/03/2026', status: 'pending', group: 'Logística', groupColor: const Color(0xFFD64545), comments: 3),
];

// ─────────────────────────────────────────────
// PANTALLA SESIÓN — Opción 6
// ─────────────────────────────────────────────

class O6SessionScreen extends StatefulWidget {
  const O6SessionScreen({super.key});

  @override
  State<O6SessionScreen> createState() => _O6SessionScreenState();
}

class _O6SessionScreenState extends State<O6SessionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<Map<String, dynamic>> _attendance;
  late final List<_SessionAgreement> _agreements;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _attendance = _dummyAttendance.map((e) => Map<String, dynamic>.from(e)).toList();
    _agreements = List.from(_dummyAgreements);
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
    final attended = _attendance.where((p) => p['present'] as bool).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sesión #18 — Sem. 12', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('18 Mar 2026 · 08:00 – 09:30', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _confirmCloseSession(context),
            icon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF1B8E5A)),
            label: const Text('Cerrar Acta', style: TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.brandBlue,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.brandBlue,
          tabs: [
            Tab(text: 'Asistencia', icon: const Icon(Icons.how_to_reg_rounded, size: 18)),
            Tab(text: 'Acuerdos', icon: Badge(label: Text('${_agreements.where((a) => a.status != 'completed').length}'), child: const Icon(Icons.fact_check_rounded, size: 18))),
            const Tab(text: 'Resumen', icon: Icon(Icons.summarize_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AttendanceTab(attendance: _attendance, onToggle: (index) => setState(() => _attendance[index]['present'] = !(_attendance[index]['present'] as bool))),
          _AgreementsTab(agreements: _agreements, onStatusChange: (id, status) => setState(() {
            final ag = _agreements.firstWhere((a) => a.id == id);
            ag.status = status;
          }), onAdd: () => _showAddAgreementSheet(context)),
          _SummaryTab(attendance: _attendance, agreements: _agreements),
        ],
      ),
    );
  }

  void _confirmCloseSession(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar acta de reunión'),
        content: const Text('Se generará un PDF con los acuerdos actuales y se enviará a todos los participantes. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            icon: const Icon(Icons.lock_rounded, size: 16),
            label: const Text('Cerrar y generar PDF'),
          ),
        ],
      ),
    );
  }

  void _showAddAgreementSheet(BuildContext context) {
    final desc = TextEditingController();
    final resp = TextEditingController();
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
            Text('Nuevo acuerdo', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción del acuerdo')),
            const SizedBox(height: 12),
            TextField(controller: resp, decoration: const InputDecoration(labelText: 'Responsable', prefixIcon: Icon(Icons.person_outline_rounded))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.calendar_today_rounded, size: 16), label: const Text('Fecha límite')),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Agregar acuerdo'))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB: ASISTENCIA
// ─────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.attendance, required this.onToggle});
  final List<Map<String, dynamic>> attendance;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final present = attendance.where((p) => p['present'] as bool).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B8E5A).withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.how_to_reg_rounded, color: Color(0xFF1B8E5A)),
              const SizedBox(width: 8),
              Text('$present / ${attendance.length} presentes', style: const TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...attendance.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isPresent = p['present'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isPresent ? const Color(0xFF1B8E5A).withOpacity(0.06) : AppTheme.stroke.withOpacity(0.30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isPresent ? const Color(0xFF1B8E5A).withOpacity(0.25) : AppTheme.stroke),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: isPresent ? const Color(0xFF1B8E5A).withOpacity(0.15) : AppTheme.stroke,
                child: Text(p['name']!.split(' ').map((w) => w[0]).take(2).join(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isPresent ? const Color(0xFF1B8E5A) : AppTheme.muted)),
              ),
              title: Text(p['name']!, style: theme.textTheme.bodyLarge),
              subtitle: Text(p['area']!, style: theme.textTheme.bodySmall),
              trailing: Switch.adaptive(
                value: isPresent,
                activeColor: const Color(0xFF1B8E5A),
                onChanged: (_) => onToggle(i),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TAB: ACUERDOS
// ─────────────────────────────────────────────

class _AgreementsTab extends StatelessWidget {
  const _AgreementsTab({required this.agreements, required this.onStatusChange, required this.onAdd});
  final List<_SessionAgreement> agreements;
  final Function(int, String) onStatusChange;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Acuerdos de esta sesión', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Agregar'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), textStyle: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...agreements.map((ag) => _AgreementCard(agreement: ag, onStatusChange: onStatusChange)),
      ],
    );
  }
}

class _AgreementCard extends StatelessWidget {
  const _AgreementCard({required this.agreement, required this.onStatusChange});
  final _SessionAgreement agreement;
  final Function(int, String) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF16202B) : Colors.white;
    final statusColor = _statusColor(agreement.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: agreement.groupColor, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0A17324D), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: agreement.groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(agreement.group, style: TextStyle(fontSize: 10, color: agreement.groupColor, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(_statusLabel(agreement.status), style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(agreement.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.muted),
                const SizedBox(width: 4),
                Text(agreement.responsible, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.event_outlined, size: 13, color: AppTheme.muted),
                const SizedBox(width: 4),
                Text(agreement.dueDate, style: theme.textTheme.bodySmall),
                const Spacer(),
                if (agreement.comments > 0)
                  Row(children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 13, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Text('${agreement.comments}', style: theme.textTheme.bodySmall),
                  ]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (agreement.status != 'completed')
                  TextButton.icon(
                    onPressed: () => onStatusChange(agreement.id, 'completed'),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF1B8E5A)),
                    label: const Text('Completar', style: TextStyle(color: Color(0xFF1B8E5A), fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_outlined, size: 15),
                  label: const Text('Comentar', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed': return const Color(0xFF1B8E5A);
      case 'overdue': return const Color(0xFFD64545);
      default: return const Color(0xFFE4A620);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'completed': return 'Completado';
      case 'overdue': return 'Vencido';
      default: return 'Pendiente';
    }
  }
}

// ─────────────────────────────────────────────
// TAB: RESUMEN
// ─────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.attendance, required this.agreements});
  final List<Map<String, dynamic>> attendance;
  final List<_SessionAgreement> agreements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final present = attendance.where((p) => p['present'] as bool).length;
    final completed = agreements.where((a) => a.status == 'completed').length;
    final overdue = agreements.where((a) => a.status == 'overdue').length;
    final pending = agreements.where((a) => a.status == 'pending').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Resumen de la sesión', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        _SummaryRow(icon: Icons.how_to_reg_rounded, color: const Color(0xFF1B8E5A), label: 'Asistencia', value: '$present / ${attendance.length}'),
        _SummaryRow(icon: Icons.fact_check_rounded, color: AppTheme.brandBlue, label: 'Acuerdos nuevos', value: '${agreements.length}'),
        _SummaryRow(icon: Icons.check_circle_rounded, color: const Color(0xFF1B8E5A), label: 'Completados', value: '$completed'),
        _SummaryRow(icon: Icons.schedule_rounded, color: const Color(0xFFE4A620), label: 'Pendientes', value: '$pending'),
        _SummaryRow(icon: Icons.warning_amber_rounded, color: const Color(0xFFD64545), label: 'Vencidos', value: '$overdue'),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.brandBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.brandBlue.withOpacity(0.20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.picture_as_pdf_rounded, color: AppTheme.brandBlue, size: 20),
                  const SizedBox(width: 8),
                  Text('Acta generada', style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.brandBlue)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Acta_Sesion18_Sem12_18032026.pdf', style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded, size: 16), label: const Text('Descargar'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_rounded, size: 16), label: const Text('Enviar'))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
        ],
      ),
    );
  }
}
