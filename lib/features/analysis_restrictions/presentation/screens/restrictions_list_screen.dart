import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_theme.dart';

class RestrictionsListScreen extends StatefulWidget {
  const RestrictionsListScreen({super.key});

  @override
  State<RestrictionsListScreen> createState() => _RestrictionsListScreenState();
}

class _RestrictionsListScreenState extends State<RestrictionsListScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Retrasados';

  final List<_RestrictionViewModel> _items = [
    _RestrictionViewModel(
      title:
          'Falta permiso municipal para liberar el frente y continuar con el avance programado',
      front: 'Torre A - Frente Norte de obra',
      phase: 'Estructuras y concreto armado',
      responsible: 'Juan Perez',
      requiredDate: '12/03/2026',
      status: 'Retrasado',
      synced: false,
    ),
    _RestrictionViewModel(
      title: 'Material no llega segun cronograma de abastecimiento',
      front: 'Sotano 1',
      phase: 'Instalaciones sanitarias',
      responsible: 'Carlos Ruiz',
      requiredDate: '12/03/2026',
      status: 'En proceso',
      synced: true,
    ),
    _RestrictionViewModel(
      title: 'Coordinar entrega de planos revisados con arquitectura',
      front: 'Lobby principal',
      phase: 'Acabados interiores y carpinteria',
      responsible: 'Maria Torres',
      requiredDate: '14/03/2026',
      status: 'Pendiente',
      synced: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _items.where((item) {
      final query = _searchController.text.trim().toLowerCase();
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.front.toLowerCase().contains(query) ||
          item.phase.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Restricciones')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    _RestrictionsHeader(
                      selectedFilter: _filter,
                      searchController: _searchController,
                      onFilterChanged: (value) =>
                          setState(() => _filter = value),
                      onSearchChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          return _RestrictionCard(
                            item: item,
                            onStatusChanged: (value) =>
                                setState(() => item.status = value),
                            onView: () => Navigator.pushNamed(
                              context,
                              RouteNames.restrictionDetail,
                            ),
                            onEdit: () => Navigator.pushNamed(
                              context,
                              RouteNames.restrictionEdit,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.restrictionCreate,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nueva restriccion'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictionsHeader extends StatelessWidget {
  const _RestrictionsHeader({
    required this.selectedFilter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final String selectedFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17324D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
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
                  color: AppTheme.brandBlue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.rule_folder_outlined,
                  size: 20,
                  color: AppTheme.brandBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyecto A',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lista priorizada de restricciones',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
            decoration: const InputDecoration(
              hintText: 'Buscar por restriccion, frente o fase',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Filtros rapidos',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final selected = selectedFilter == filter.label;
                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(
                    filter.icon,
                    size: 15,
                    color: selected ? filter.color : AppTheme.muted,
                  ),
                  label: Text(filter.label),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.text : AppTheme.muted,
                  ),
                  onSelected: (_) => onFilterChanged(filter.label),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD64545).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_rounded, size: 16, color: Color(0xFFD64545)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prioridad actual: Retrasados (3)',
                    style: TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictionCard extends StatelessWidget {
  const _RestrictionCard({
    required this.item,
    required this.onStatusChanged,
    required this.onView,
    required this.onEdit,
  });

  final _RestrictionViewModel item;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusMeta[item.status] ?? _statusMeta['Pendiente']!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            _ContextRow(
              icon: Icons.apartment_rounded,
              label: 'Frente',
              value: item.front,
            ),
            const SizedBox(height: 8),
            _ContextRow(
              icon: Icons.layers_outlined,
              label: 'Fase',
              value: item.phase,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _MetaLine(
                  icon: Icons.person_outline_rounded,
                  text: item.responsible,
                ),
                _MetaLine(icon: Icons.event_outlined, text: item.requiredDate),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: item.status,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: statusStyle.color,
                        ),
                        dropdownColor: Colors.white,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 11.5,
                          color: statusStyle.color,
                        ),
                        items: _statusOptions.map((status) {
                          final meta =
                              _statusMeta[status] ?? _statusMeta['Pendiente']!;
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(meta.icon, size: 15, color: meta.color),
                                const SizedBox(width: 8),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) onStatusChanged(value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _SyncBadge(synced: item.synced),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onView,
                    child: const Text('Ver detalle'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onEdit,
                    child: const Text('Editar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppTheme.brandBlue),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.8,
              color: AppTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.muted),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 11.6),
        ),
      ],
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    final color = synced ? AppTheme.brandBlue : const Color(0xFFE4A620);
    final icon = synced
        ? Icons.cloud_done_outlined
        : Icons.cloud_upload_outlined;
    final label = synced ? 'Sync' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.2,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestrictionViewModel {
  _RestrictionViewModel({
    required this.title,
    required this.front,
    required this.phase,
    required this.responsible,
    required this.requiredDate,
    required this.status,
    required this.synced,
  });

  final String title;
  final String front;
  final String phase;
  final String responsible;
  final String requiredDate;
  final bool synced;
  String status;
}

class _StatusStyle {
  const _StatusStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class _StatusFilter {
  const _StatusFilter(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

final _statusFilters = [
  _StatusFilter('Retrasados', Icons.error_rounded, Color(0xFFD64545)),
  _StatusFilter('Vence hoy', Icons.today_rounded, Color(0xFFE4A620)),
  _StatusFilter('Pendientes', Icons.pending_outlined, Color(0xFF98A3B3)),
  _StatusFilter('En proceso', Icons.timelapse_rounded, Color(0xFFF0A11E)),
  _StatusFilter('Finalizados', Icons.check_circle_rounded, Color(0xFF1B8E5A)),
  _StatusFilter('Todas', Icons.apps_rounded, AppTheme.brandBlue),
];

const _statusOptions = ['Pendiente', 'En proceso', 'Completado', 'Retrasado'];

const _statusMeta = {
  'Retrasado': _StatusStyle(
    icon: Icons.error_rounded,
    color: Color(0xFFD64545),
  ),
  'Pendiente': _StatusStyle(
    icon: Icons.pending_outlined,
    color: Color(0xFF98A3B3),
  ),
  'En proceso': _StatusStyle(
    icon: Icons.timelapse_rounded,
    color: Color(0xFFF0A11E),
  ),
  'Completado': _StatusStyle(
    icon: Icons.check_circle_rounded,
    color: Color(0xFF1B8E5A),
  ),
};
