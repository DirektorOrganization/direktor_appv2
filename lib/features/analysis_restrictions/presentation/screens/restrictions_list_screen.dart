import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';

class RestrictionsListScreen extends StatefulWidget {
  const RestrictionsListScreen({super.key});

  @override
  State<RestrictionsListScreen> createState() => _RestrictionsListScreenState();
}

class _RestrictionsListScreenState extends State<RestrictionsListScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Retrasados';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final project = controller.currentProject;
        final allItems = controller.restrictions;
        final prioritizedFilter = _resolvePriority(allItems);
        final effectiveFilter = _filter == 'Retrasados' && !_hasFilterItems(allItems, 'Retrasados')
            ? prioritizedFilter
            : _filter;
        final query = _searchController.text.trim().toLowerCase();
        final visibleItems = allItems.where((item) {
          final haystack = [
            item.front,
            item.phase,
            item.activity,
            item.description,
            item.type,
            item.responsible,
            _normalizedStatusLabel(item),
            item.requester,
          ].join(' ').toLowerCase();
          final matchesSearch = query.isEmpty || haystack.contains(query);
          final matchesFilter = effectiveFilter == 'Todas' || _matchesFilter(item, effectiveFilter);
          return matchesSearch && matchesFilter;
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
                          projectName: project?.name ?? 'Proyecto',
                          selectedFilter: effectiveFilter,
                          priorityLabel: prioritizedFilter,
                          searchController: _searchController,
                          onClearSearch: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          onFilterChanged: (value) => setState(() => _filter = value),
                          onSearchChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: visibleItems.isEmpty
                              ? const _EmptyRestrictions()
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: visibleItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = visibleItems[index];
                                    return _RestrictionCard(
                                      item: item,
                                      onStatusChanged: (value) => controller.updateRestrictionStatus(item.id, value),
                                      onView: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.restrictionDetail,
                                        arguments: RestrictionDetailArgs(restrictionId: item.id),
                                      ),
                                      onEdit: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.restrictionEdit,
                                        arguments: RestrictionFormArgs(restrictionId: item.id),
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
                        onPressed: () => Navigator.pushNamed(context, RouteNames.restrictionCreate),
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
      },
    );
  }

  bool _matchesFilter(RestrictionRecord item, String filter) {
    switch (filter) {
      case 'Retrasados':
        return _isOverdue(item);
      case 'Vence hoy':
        return _isDueToday(item);
      case 'Pendientes':
        return _normalizedStatusCode(item) == 'pending';
      case 'En proceso':
        return _normalizedStatusCode(item) == 'in_progress';
      case 'Finalizados':
        return _normalizedStatusCode(item) == 'completed';
      default:
        return true;
    }
  }

  bool _hasFilterItems(List<RestrictionRecord> items, String filter) {
    return items.any((item) => _matchesFilter(item, filter));
  }

  String _resolvePriority(List<RestrictionRecord> items) {
    for (final label in const ['Retrasados', 'Vence hoy', 'Pendientes', 'En proceso', 'Finalizados']) {
      if (_hasFilterItems(items, label)) return label;
    }
    return 'Todas';
  }

  bool _isOverdue(RestrictionRecord item) {
    if (_normalizedStatusCode(item) == 'completed') return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final required = DateTime(item.requiredDate.year, item.requiredDate.month, item.requiredDate.day);
    return current.isAfter(required);
  }

  bool _isDueToday(RestrictionRecord item) {
    if (_normalizedStatusCode(item) == 'completed') return false;
    final today = DateTime.now();
    return item.requiredDate.year == today.year && item.requiredDate.month == today.month && item.requiredDate.day == today.day;
  }

  String _normalizedStatusCode(RestrictionRecord item) {
    if (item.statusCode == 'overdue') return 'pending';
    return item.statusCode;
  }

  String _normalizedStatusLabel(RestrictionRecord item) {
    final meta = _statusMeta[_normalizedStatusCode(item)]!;
    return meta.label;
  }
}

class _RestrictionsHeader extends StatelessWidget {
  const _RestrictionsHeader({
    required this.projectName,
    required this.selectedFilter,
    required this.priorityLabel,
    required this.searchController,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final String projectName;
  final String selectedFilter;
  final String priorityLabel;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityMeta = _filterMeta[priorityLabel] ?? _filterMeta['Todas']!;

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
                child: Icon(Icons.rule_folder_outlined, size: 20, color: AppTheme.brandBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(projectName, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Lista priorizada de restricciones', style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5)),
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
            decoration: InputDecoration(
              hintText: 'Buscar por frente, fase, responsable, actividad, restriccion o estado',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Limpiar',
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Filtros rapidos',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.text),
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
                  avatar: Icon(filter.icon, size: 15, color: selected ? filter.color : AppTheme.muted),
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
              color: priorityMeta.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(priorityMeta.icon, size: 16, color: priorityMeta.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prioridad actual: $priorityLabel',
                    style: const TextStyle(fontSize: 11.8, fontWeight: FontWeight.w700),
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

  final RestrictionRecord item;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = item.statusCode == 'overdue' ? 'pending' : item.statusCode;
    final statusStyle = _statusMeta[normalizedStatus] ?? _statusMeta['pending']!;
    final theme = Theme.of(context);
    final overdue = _isOverdue(item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TopContextChip(icon: Icons.apartment_rounded, label: 'Frente: ${item.front}'),
                      _TopContextChip(icon: Icons.layers_outlined, label: 'Fase: ${item.phase}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, height: 1.25),
                  ),
                ),
                const SizedBox(width: 10),
                _SyncBadge(synced: item.isSynced),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(label: 'Responsable', value: item.responsible),
            const SizedBox(height: 8),
            _InfoLine(label: 'Fecha requerida', value: _formatDate(item.requiredDate)),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Estado:',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.8, fontWeight: FontWeight.w700, color: AppTheme.text),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 132,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusStyle.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: normalizedStatus,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: statusStyle.color, size: 18),
                        dropdownColor: Colors.white,
                        style: theme.textTheme.labelMedium?.copyWith(fontSize: 11.2, color: statusStyle.color),
                        selectedItemBuilder: (context) {
                          return _statusOptions.map((status) {
                            final meta = _statusMeta[status]!;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                meta.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(fontSize: 11.2, color: meta.color),
                              ),
                            );
                          }).toList();
                        },
                        items: _statusOptions.map((status) {
                          final meta = _statusMeta[status]!;
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(meta.icon, size: 15, color: meta.color),
                                const SizedBox(width: 8),
                                Expanded(child: Text(meta.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                const SizedBox(width: 12),
                if (overdue)
                  const _DueBadge()
                else
                  const Spacer(),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: onView, child: const Text('Ver detalle'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: onEdit, child: const Text('Editar'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isOverdue(RestrictionRecord item) {
    if (item.statusCode == 'completed') return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final required = DateTime(item.requiredDate.year, item.requiredDate.month, item.requiredDate.day);
    return current.isAfter(required);
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _TopContextChip extends StatelessWidget {
  const _TopContextChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.brandBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.3, fontWeight: FontWeight.w700, color: AppTheme.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 106,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.6, fontWeight: FontWeight.w700, color: AppTheme.text),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.8, color: AppTheme.muted),
          ),
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
    final icon = synced ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined;
    final label = synced ? 'Sync' : 'Pendiente';

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.2, color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD64545).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('VENCIDA', style: TextStyle(fontSize: 11.2, fontWeight: FontWeight.w800, color: Color(0xFFD64545))),
          SizedBox(width: 6),
          Icon(Icons.circle, size: 10, color: Color(0xFFD64545)),
        ],
      ),
    );
  }
}

class _EmptyRestrictions extends StatelessWidget {
  const _EmptyRestrictions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'No se tienen registros para el filtro o busqueda actual.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
        ),
      ),
    );
  }
}

class _FilterMeta {
  const _FilterMeta({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;
}

const _statusOptions = ['pending', 'in_progress', 'completed'];

const _statusMeta = {
  'pending': _FilterMeta(label: 'Pendiente', icon: Icons.pending_outlined, color: Color(0xFF98A3B3)),
  'in_progress': _FilterMeta(label: 'En proceso', icon: Icons.timelapse_rounded, color: Color(0xFFF0A11E)),
  'completed': _FilterMeta(label: 'Finalizado', icon: Icons.check_circle_rounded, color: Color(0xFF1B8E5A)),
};

final _filterMeta = {
  'Retrasados': const _FilterMeta(label: 'Retrasados', icon: Icons.error_rounded, color: Color(0xFFD64545)),
  'Vence hoy': const _FilterMeta(label: 'Vence hoy', icon: Icons.today_rounded, color: Color(0xFFE4A620)),
  'Pendientes': const _FilterMeta(label: 'Pendientes', icon: Icons.pending_outlined, color: Color(0xFF98A3B3)),
  'En proceso': const _FilterMeta(label: 'En proceso', icon: Icons.timelapse_rounded, color: Color(0xFFF0A11E)),
  'Finalizados': const _FilterMeta(label: 'Finalizados', icon: Icons.check_circle_rounded, color: Color(0xFF1B8E5A)),
  'Todas': _FilterMeta(label: 'Todas', icon: Icons.apps_rounded, color: AppTheme.brandBlue),
};

final _statusFilters = [
  _FilterMeta(label: 'Retrasados', icon: Icons.error_rounded, color: Color(0xFFD64545)),
  _FilterMeta(label: 'Vence hoy', icon: Icons.today_rounded, color: Color(0xFFE4A620)),
  _FilterMeta(label: 'Pendientes', icon: Icons.pending_outlined, color: Color(0xFF98A3B3)),
  _FilterMeta(label: 'En proceso', icon: Icons.timelapse_rounded, color: Color(0xFFF0A11E)),
  _FilterMeta(label: 'Finalizados', icon: Icons.check_circle_rounded, color: Color(0xFF1B8E5A)),
  _FilterMeta(label: 'Todas', icon: Icons.apps_rounded, color: AppTheme.brandBlue),
];
