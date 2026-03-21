import 'package:flutter/material.dart';

class O3MeetingDetailScreen extends StatefulWidget {
  final String title;

  const O3MeetingDetailScreen({super.key, required this.title});

  @override
  State<O3MeetingDetailScreen> createState() => _O3MeetingDetailScreenState();
}

class _O3MeetingDetailScreenState extends State<O3MeetingDetailScreen> {
  final List<Map<String, dynamic>> _participants = [
    {'name': 'Juan Pérez', 'role': 'Residente', 'present': true},
    {'name': 'Ana Gómez', 'role': 'Supervisor SST', 'present': false},
    {'name': 'Carlos Ruiz', 'role': 'Maestro de Obra', 'present': true},
  ];

  final List<Map<String, dynamic>> _agreements = [
    {'desc': 'Liberar sector 2 para vaciado', 'resp': 'Juan Pérez', 'date': 'Mañana'},
    {'desc': 'Revisar EPP de personal nuevo', 'resp': 'Ana Gómez', 'date': 'Hoy'},
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: const Color(0xFF1E1E1E),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFFE4A620), // High vis indicator
            labelColor: Color(0xFFE4A620),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'ASISTENCIA'),
              Tab(icon: Icon(Icons.assignment), text: 'ACUERDOS'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              tooltip: 'Cerrar Acta',
              onPressed: () => _showCloseMeetingDialog(context),
            )
          ],
        ),
        body: TabBarView(
          children: [
            _buildAttendanceTab(),
            _buildAgreementsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Participantes (3)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddParticipantSheet(),
              icon: const Icon(Icons.person_add, color: Color(0xFFE4A620)),
              label: const Text('AGREGAR', style: TextStyle(color: Color(0xFFE4A620), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        ..._participants.map((p) => _ParticipantCard(
              name: p['name'],
              role: p['role'],
              isPresent: p['present'],
              onToggle: (val) {
                setState(() {
                  p['present'] = val;
                });
              },
            )),
      ],
    );
  }

  Widget _buildAgreementsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Acuerdos (2)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddAgreementSheet(),
              icon: const Icon(Icons.add_task, color: Color(0xFFE4A620)),
              label: const Text('NUEVO', style: TextStyle(color: Color(0xFFE4A620), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        ..._agreements.map((a) => _AgreementCard(desc: a['desc'], resp: a['resp'], date: a['date'])),
      ],
    );
  }

  void _showAddParticipantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar Participante', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre o Correo',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4A620))),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4A620),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  setState(() {
                    _participants.add({'name': 'Nuevo Usuario', 'role': 'Invitado', 'present': true});
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('AGREGAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddAgreementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo Acuerdo', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descripción del acuerdo',
                alignLabelWithHint: true,
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4A620))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Responsable',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4A620))),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4A620),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  setState(() {
                    _agreements.add({'desc': 'Nuevo acuerdo guardado', 'resp': 'Responsable X', 'date': 'Fecha TBD'});
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('GUARDAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showCloseMeetingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Acta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de cerrar esta acta? Ya no podrás agregar más participantes ni acuerdos. Se enviará una copia a todos los asistentes.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // go back to subcategory
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acta cerrada y enviada.')));
            },
            child: const Text('CERRAR ACTA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final String name;
  final String role;
  final bool isPresent;
  final ValueChanged<bool> onToggle;

  const _ParticipantCard({required this.name, required this.role, required this.isPresent, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPresent ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            child: Text(name[0], style: TextStyle(color: isPresent ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(role, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          ),
          Switch(
            value: isPresent,
            onChanged: onToggle,
            activeColor: Colors.greenAccent,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.black38,
          ),
        ],
      ),
    );
  }
}

class _AgreementCard extends StatelessWidget {
  final String desc;
  final String resp;
  final String date;

  const _AgreementCard({required this.desc, required this.resp, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: Colors.white12),
          right: BorderSide(color: Colors.white12),
          bottom: BorderSide(color: Colors.white12),
          left: BorderSide(color: Color(0xFFE4A620), width: 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(desc, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(resp, style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
