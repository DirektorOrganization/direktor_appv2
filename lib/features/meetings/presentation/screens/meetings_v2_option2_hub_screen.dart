import 'package:flutter/material.dart';

class MeetingsV2Option2HubScreen extends StatelessWidget {
  const MeetingsV2Option2HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF16202B),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Acta de Reuniones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF16202B), Color(0xFF1F2E3E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resumen Global', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('27 Acuerdos Activos', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatBadge(label: '8 Atrasados', color: Colors.redAccent),
                              const SizedBox(width: 8),
                              _StatBadge(label: '19 En Tiempo', color: Colors.greenAccent),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acciones Rapidas', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionBtn(icon: Icons.add_task, label: 'Nuevo\nAcuerdo', color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionBtn(icon: Icons.event_available, label: 'Programar\nReunion', color: Colors.indigo),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionBtn(icon: Icons.history, label: 'Ver\nHistorial', color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text('Categorias', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _GridCategory(title: 'Construccion\ny Obra', percentage: 65, color: Colors.orange),
                _GridCategory(title: 'Seguridad\nSST', percentage: 90, color: Colors.green),
                _GridCategory(title: 'Administracion', percentage: 40, color: Colors.blue),
                _GridCategory(title: 'Direccion', percentage: 100, color: Colors.purple),
              ]),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionBtn({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ]
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _GridCategory extends StatelessWidget {
  final String title;
  final double percentage;
  final Color color;

  const _GridCategory({required this.title, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text('${percentage.toInt()}% resueltos', style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
