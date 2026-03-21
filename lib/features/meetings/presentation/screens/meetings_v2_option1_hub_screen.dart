import 'package:flutter/material.dart';

class MeetingsV2Option1HubScreen extends StatelessWidget {
  const MeetingsV2Option1HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean light background
      appBar: AppBar(
        title: const Text('Acta de Reuniones'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Proximas Sesiones', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _UpcomingMeetingCard(
                    title: 'Comite de Obra',
                    time: 'Hoy, 14:00 PM',
                    category: 'Construccion',
                    color: const Color(0xFFE4A620), // Construction Orange/Yellow
                  ),
                  _UpcomingMeetingCard(
                    title: 'Seguimiento Financiero',
                    time: 'Mañana, 09:00 AM',
                    category: 'Finanzas',
                    color: const Color(0xFF0F7AD8), // Brand Blue
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Espacios de Trabajo (Categorias)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _CategoryTile(title: 'Reuniones de Obra', count: 3, pendingAgreements: 12, icon: Icons.construction),
            _CategoryTile(title: 'Sostenibilidad y SST', count: 2, pendingAgreements: 5, icon: Icons.eco),
            _CategoryTile(title: 'Gerencia y Finanzas', count: 4, pendingAgreements: 8, icon: Icons.attach_money),
            _CategoryTile(title: 'Procura y Logistica', count: 1, pendingAgreements: 2, icon: Icons.local_shipping),
          ],
        ),
      ),
    );
  }
}

class _UpcomingMeetingCard extends StatelessWidget {
  final String title;
  final String time;
  final String category;
  final Color color;

  const _UpcomingMeetingCard({
    required this.title,
    required this.time,
    required this.category,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(category, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.black87,
              elevation: 0,
              minimumSize: const Size(double.infinity, 36),
            ),
            child: const Text('Ver Detalles'),
          )
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final int count;
  final int pendingAgreements;
  final IconData icon;

  const _CategoryTile({
    required this.title,
    required this.count,
    required this.pendingAgreements,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F7AD8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0F7AD8)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$count subcategorias'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$pendingAgreements pendientes', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        onTap: () {
          // Import RouteNames manually for dummy file or use string path directly if router is not imported
          Navigator.pushNamed(context, '/meetings-option1/subcategory'); 
        }, 
      ),
    );
  }
}

