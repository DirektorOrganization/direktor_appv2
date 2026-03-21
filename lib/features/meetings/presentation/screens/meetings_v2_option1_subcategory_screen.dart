import 'package:flutter/material.dart';

class MeetingsV2Option1SubcategoryScreen extends StatelessWidget {
  const MeetingsV2Option1SubcategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Reuniones Semanales'),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF0A66B7),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0A66B7),
            tabs: [
              Tab(text: 'Acuerdos (Tablero)', icon: Icon(Icons.assignment)),
              Tab(text: 'Historial', icon: Icon(Icons.calendar_month)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: const TabBarView(
          children: [
            _AgreementsTab(),
            _HistoryTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: const Color(0xFF0A66B7),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nuevo Acuerdo', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _AgreementsTab extends StatelessWidget {
  const _AgreementsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AgreementCard(
          title: 'Revisar planos eléctricos',
          assignee: 'Juan Perez',
          dueDate: 'Vence Hoy',
          status: 'Pendiente',
          statusColor: Colors.orange,
        ),
        _AgreementCard(
          title: 'Aprobar presupuesto de excavacion',
          assignee: 'Maria Gomez',
          dueDate: 'Vencido hace 2 dias',
          status: 'Atrasado',
          statusColor: Colors.red,
        ),
        _AgreementCard(
          title: 'Enviar reporte mensual SST',
          assignee: 'Carlos Ruiz',
          dueDate: 'Vence en 5 dias',
          status: 'En Proceso',
          statusColor: Colors.green,
        ),
      ],
    );
  }
}

class _AgreementCard extends StatelessWidget {
  final String title;
  final String assignee;
  final String dueDate;
  final String status;
  final Color statusColor;

  const _AgreementCard({
    required this.title,
    required this.assignee,
    required this.dueDate,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 12, backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, size: 16, color: Colors.blue)),
                  const SizedBox(width: 8),
                  Text(assignee, style: const TextStyle(fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: status == 'Atrasado' ? Colors.red : Colors.grey),
                  const SizedBox(width: 4),
                  Text(dueDate, style: TextStyle(fontSize: 12, color: status == 'Atrasado' ? Colors.red : Colors.grey)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Proxima Sesion', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _MeetingListTile(
          title: 'Reunion Semanal #15',
          date: 'Mañana, 09:00 AM',
          status: 'Programada',
          isActive: true,
        ),
        const SizedBox(height: 24),
        Text('Historial de Actas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _MeetingListTile(
          title: 'Reunion Semanal #14',
          date: '02 Mar 2026',
          status: 'Cerrada',
          isActive: false,
        ),
        _MeetingListTile(
          title: 'Reunion Semanal #13',
          date: '24 Feb 2026',
          status: 'Cerrada',
          isActive: false,
        ),
      ],
    );
  }
}

class _MeetingListTile extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final bool isActive;

  const _MeetingListTile({
    required this.title,
    required this.date,
    required this.status,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? const Color(0xFF0F7AD8).withOpacity(0.5) : Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(isActive ? Icons.play_circle_fill : Icons.picture_as_pdf, color: isActive ? const Color(0xFF0F7AD8) : Colors.redAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date • $status'),
        trailing: isActive 
          ? ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7AD8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Iniciar'),
            )
          : const Icon(Icons.download),
      ),
    );
  }
}
