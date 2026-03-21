import 'package:flutter/material.dart';

class O4MeetingDetailScreen extends StatefulWidget {
  final String title;

  const O4MeetingDetailScreen({super.key, required this.title});

  @override
  State<O4MeetingDetailScreen> createState() => _O4MeetingDetailScreenState();
}

class _O4MeetingDetailScreenState extends State<O4MeetingDetailScreen> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _participants = [
    {'name': 'Juan Pérez', 'firmado': true},
    {'name': 'Ana Gómez', 'firmado': false},
  ];

  final List<Map<String, dynamic>> _agreements = [
    {'desc': 'Liberar sector 2 para vaciado', 'estado': 'PENDIENTE'},
    {'desc': 'Revisar EPP de personal nuevo', 'estado': 'EN PROCESO'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _finalizeProcess(context),
            child: const Text('FINALIZAR', style: TextStyle(color: Color(0xFF0F7AD8), fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _finalizeProcess(context);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        onStepTapped: (index) {
          setState(() => _currentStep = index);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F7AD8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_currentStep == 2 ? 'Cerrar Acta' : 'Siguiente Paso'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Atrás', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Información General', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Temas a tratar (Agenda)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Lugar / Enlace',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Verificación de Asistencia', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showAddParticipantDialog,
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Añadir'),
                  ),
                ),
                const SizedBox(height: 16),
                ..._participants.map((p) => CheckboxListTile(
                      title: Text(p['name']),
                      subtitle: Text(p['firmado'] ? 'Asistió' : 'Falta marcar'),
                      value: p['firmado'],
                      onChanged: (v) {
                        setState(() {
                          p['firmado'] = v;
                        });
                      },
                      activeColor: const Color(0xFF0F7AD8),
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Gestión de Acuerdos (Kanban)', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _showAddAgreementDialog,
                    icon: const Icon(Icons.add_task, size: 16),
                    label: const Text('Nuevo Acuerdo'),
                  ),
                ),
                const SizedBox(height: 16),
                // Simplified Kanban list
                ..._agreements.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                      child: ListTile(
                        title: Text(a['desc'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(a['estado'], style: TextStyle(color: a['estado'] == 'PENDIENTE' ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) {
                            setState(() {
                              a['estado'] = val;
                            });
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
                            const PopupMenuItem(value: 'EN PROCESO', child: Text('En Proceso')),
                            const PopupMenuItem(value: 'COMPLETADO', child: Text('Completado')),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  void _showAddParticipantDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Participante'),
        content: TextField(
          decoration: InputDecoration(
            labelText: 'Nombre Completo',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _participants.add({'name': 'Nuevo Participante', 'firmado': true});
              });
              Navigator.pop(ctx);
            },
            child: const Text('Añadir'),
          )
        ],
      ),
    );
  }

  void _showAddAgreementDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Acuerdo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Responsable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _agreements.add({'desc': 'Acuerdo de prueba', 'estado': 'PENDIENTE'});
              });
              Navigator.pop(ctx);
            },
            child: const Text('Añadir'),
          )
        ],
      ),
    );
  }

  void _finalizeProcess(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Acta'),
        content: const Text('¿Estás seguro de cerrar el acta de esta sesión? No se podrán hacer cambios posteriores en la asistencia.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Return to subcategory
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acta finalizada y enviada al historial')));
            },
            child: const Text('Sí, Cerrar'),
          )
        ],
      ),
    );
  }
}
