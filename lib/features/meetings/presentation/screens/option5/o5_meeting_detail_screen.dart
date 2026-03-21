import 'package:flutter/material.dart';

class O5MeetingDetailScreen extends StatefulWidget {
  final String title;

  const O5MeetingDetailScreen({super.key, required this.title});

  @override
  State<O5MeetingDetailScreen> createState() => _O5MeetingDetailScreenState();
}

class _O5MeetingDetailScreenState extends State<O5MeetingDetailScreen> {
  final List<Map<String, dynamic>> _participants = [
    {'name': 'Juan Pérez', 'empresa': 'Constructora Alfa', 'presente': true},
    {'name': 'Ana Gómez', 'empresa': 'Supervisión Omega', 'presente': false},
    {'name': 'Luis Santos', 'empresa': 'Subcontratista Beta', 'presente': true},
  ];

  final List<Map<String, dynamic>> _agreements = [
    {'desc': 'Liberar sector 2 para vaciado', 'resp': 'Juan Pérez', 'fecha': 'Mañana', 'estado': 'Proceso'},
    {'desc': 'Revisar EPP de personal nuevo', 'resp': 'Ana Gómez', 'fecha': 'Hoy', 'estado': 'Pendiente'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Acta: ${widget.title}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acta Guardada')));
            },
            icon: const Icon(Icons.save, size: 18, color: Colors.white),
            label: const Text('GUARDAR BORRADOR', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, elevation: 0),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showCloseDialog(context),
            icon: const Icon(Icons.check_circle, size: 18, color: Colors.white),
            label: const Text('CERRAR ACTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), elevation: 0),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel: Info & Participants
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Control de Asistencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _participants.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _participants[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: p['presente'] ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(p['presente'] ? Icons.check : Icons.close, color: p['presente'] ? Colors.green : Colors.red),
                          ),
                          title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p['empresa']),
                          trailing: Switch(
                            value: p['presente'],
                            activeColor: const Color(0xFF10B981),
                            onChanged: (v) => setState(() => p['presente'] = v),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _participants.add({'name': 'Nuevo Asistente', 'empresa': 'Empresa', 'presente': true});
                        });
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Añadir Asistente'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Panel: Agreements
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.only(right: 24, top: 24, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Registro de Acuerdos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _agreements.add({'desc': 'Nuevo acuerdo rápido', 'resp': 'Sin asignar', 'fecha': 'Pendiente', 'estado': 'Pendiente'});
                            });
                          },
                          icon: const Icon(Icons.add_task, color: Colors.blue),
                          label: const Text('AGREGAR ACUERDO', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.1), elevation: 0),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _agreements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final a = _agreements[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                              right: BorderSide(color: Colors.grey.shade200),
                              bottom: BorderSide(color: Colors.grey.shade200),
                              left: const BorderSide(color: Colors.blue, width: 4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Descripción', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(a['desc'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Responsable', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(a['resp']),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Fecha Límite', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(a['fecha'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Estado', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(a['estado'], style: TextStyle(color: a['estado'] == 'Pendiente' ? Colors.orange : Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar y Distribuir Acta'),
        content: const Text('Al cerrar el acta se generará un PDF inmutable y se notificará a los asistentes. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acta cerrada y correos enviados.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Confirmar Cierre', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
