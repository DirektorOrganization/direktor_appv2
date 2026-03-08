import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_theme.dart';

class RestrictionDetailScreen extends StatelessWidget {
  const RestrictionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de restriccion')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A66B7), Color(0xFF0F7AD8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Falta permiso municipal', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Restriccion principal del frente actual para continuar con el siguiente avance de obra.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.84), fontSize: 11.8),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        _TopBadge(icon: Icons.error_rounded, label: 'Pendiente', color: Color(0xFFD64545)),
                        SizedBox(width: 10),
                        _TopBadge(icon: Icons.cloud_done_outlined, label: 'Sync', color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: const [
                      _DetailRow(icon: Icons.business_outlined, label: 'Proyecto', value: 'Proyecto A'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.apartment_rounded, label: 'Frente', value: 'Torre A - Frente Norte de obra'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.layers_outlined, label: 'Fase', value: 'Estructuras'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.work_outline_rounded, label: 'Actividad', value: 'Tramitar aprobacion municipal'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.report_problem_outlined, label: 'Tipo de restriccion', value: 'Permisos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descripcion', style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Falta permiso municipal para continuar con el siguiente avance de obra y liberar el frente segun cronograma.',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: const [
                      _DetailRow(icon: Icons.event_outlined, label: 'Fecha requerida', value: '12/03/2026'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.person_outline_rounded, label: 'Responsable', value: 'Juan Perez'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.manage_accounts_outlined, label: 'Solicitante', value: 'Diego Warthon'),
                      _DividerGap(),
                      _DetailRow(icon: Icons.update_rounded, label: 'Ultima actualizacion', value: '10/03/2026 11:40'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, RouteNames.restrictionEdit),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar restriccion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color == Colors.white ? Colors.white.withOpacity(0.14) : color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.brandBlue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppTheme.brandBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.2, fontWeight: FontWeight.w700, color: AppTheme.text)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DividerGap extends StatelessWidget {
  const _DividerGap();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1),
    );
  }
}
