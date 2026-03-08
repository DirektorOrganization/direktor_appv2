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
  String? _selectedAreaCode;

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
        final catalogs = controller.catalogs;
        final allItems = controller.restrictions;
        final prioritizedFilter = _resolvePriority(allItems);
        final effectiveFilter =
            _filter == 'Retrasados' && !_hasFilterItems(allItems, 'Retrasados')
            ? prioritizedFilter
            : _filter;
        final query = _searchController.text.trim().toLowerCase();
        final visibleItems = allItems.where((item) {
          final haystack = [
            item.front,
            item.phase,
            item.area,
            item.activity,
            item.description,
            item.type,
            item.responsible,
            _normalizedStatusLabel(item),
            item.requester,
          ].join(' ').toLowerCase();
          final matchesSearch = query.isEmpty || haystack.contains(query);
          final matchesFilter =
              effectiveFilter == 'Todas' ||
              _matchesFilter(item, effectiveFilter);
          final matchesArea =
              _selectedAreaCode == null || item.areaCode == _selectedAreaCode;
          return matchesSearch && matchesFilter && matchesArea;
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
                          selectedAreaCode: _selectedAreaCode,
                          catalogs: catalogs,
                          priorityLabel: prioritizedFilter,
                          searchController: _searchController,
                          onClearSearch: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          onFilterChanged: (value) {
                            if (value == 'Area') {
                              _showAreaPicker(catalogs.areas);
                              return;
                            }
                            setState(() => _filter = value);
                          },
                          onAreaTap: () => _showAreaPicker(catalogs.areas),
                          onSearchChanged: (_) => setState(() {}),
                          onClearArea: () =>
                              setState(() => _selectedAreaCode = null),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: visibleItems.isEmpty
                              ? const _EmptyRestrictions()
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: visibleItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final item = visibleItems[index];
                                    return _RestrictionCard(
                                      item: item,
                                      onStatusChanged: (value) =>
                                          controller.updateRestrictionStatus(
                                            item.id,
                                            value,
                                          ),
                                      onView: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.restrictionDetail,
                                        arguments: RestrictionDetailArgs(
                                          restrictionId: item.id,
                                        ),
                                      ),
                                      onEdit: () => Navigator.pushNamed(
                                        context,
                                        RouteNames.restrictionEdit,
                                        arguments: RestrictionFormArgs(
                                          restrictionId: item.id,
                                        ),
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
      },
    );
  }

  Future<void> _showAreaPicker(List<CatalogOption> areas) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por area',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.apps_rounded),
                  title: const Text('Todas las areas'),
                  trailing: _selectedAreaCode == null
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, ''),
                ),
                ...areas.map((area) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.domain_verification_outlined),
                    title: Text(area.label),
                    trailing: _selectedAreaCode == area.id
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () => Navigator.pop(context, area.id),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() => _selectedAreaCode = selected.isEmpty ? null : selected);
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
    for (final label in const [
      'Retrasados',
      'Vence hoy',
      'Pendientes',
      'En proceso',
      'Finalizados',
    ]) {
      if (_hasFilterItems(items, label)) return label;
    }
    return 'Todas';
  }

  bool _isOverdue(RestrictionRecord item) {
    if (_normalizedStatusCode(item) == 'completed') return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final required = DateTime(
      item.requiredDate.year,
      item.requiredDate.month,
      item.requiredDate.day,
    );
    return current.isAfter(required);
  }

  bool _isDueToday(RestrictionRecord item) {
    if (_normalizedStatusCode(item) == 'completed') return false;
    final today = DateTime.now();
    return item.requiredDate.year == today.year &&
        item.requiredDate.month == today.month &&
        item.requiredDate.day == today.day;
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
    required this.selectedAreaCode,
    required this.catalogs,
    required this.priorityLabel,
    required this.searchController,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onAreaTap,
    required this.onSearchChanged,
    required this.onClearArea,
  });

  final String projectName;
  final String selectedFilter;
  final String? selectedAreaCode;
  final RestrictionCatalogs catalogs;
  final String priorityLabel;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onAreaTap;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityMeta = _filterMeta[priorityLabel] ?? _filterMeta['Todas']!;
    final selectedAreaLabel = catalogs.areas
        .firstWhere(
          (item) => item.id == selectedAreaCode,
          orElse: () => const CatalogOption(id: '', label: 'Todas las areas'),
        )
        .label;

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
                      projectName,
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
            decoration: InputDecoration(
              hintText:
                  'Buscar por area, frente, fase, responsable, actividad o estado',
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onAreaTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.stroke),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.domain_verification_outlined,
                          size: 16,
                          color: AppTheme.brandBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedAreaCode == null
                                ? 'Area: todas'
                                : 'Area: $selectedAreaLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (selectedAreaCode != null)
                          GestureDetector(
                            onTap: onClearArea,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.close_rounded, size: 16),
                            ),
                          ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // const SizedBox(height: 14),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //   decoration: BoxDecoration(
          //     color: priorityMeta.color.withOpacity(0.08),
          //     borderRadius: BorderRadius.circular(14),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(priorityMeta.icon, size: 16, color: priorityMeta.color),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Text(
          //           'Prioridad actual: $priorityLabel',
          //           style: const TextStyle(
          //             fontSize: 11.8,
          //             fontWeight: FontWeight.w700,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817324D),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _CompactTag(icon: Icons.apartment_rounded, text: item.front),
                    _CompactTag(icon: Icons.layers_outlined, text: item.phase),
                    if (item.area.isNotEmpty)
                      _CompactTag(icon: Icons.domain_verification_outlined, text: item.area),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SyncIndicator(synced: item.isSynced),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.2, height: 1.25),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _MiniInfo(icon: Icons.person_outline_rounded, text: item.responsible),
              _MiniInfo(icon: Icons.event_outlined, text: _formatDate(item.requiredDate)),
              if (overdue) const _InlineDueBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 118,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: statusStyle.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: SizedBox(
                      height: 34,
                      child: DropdownButton<String>(
                        value: normalizedStatus,
                        isDense: true,
                        itemHeight: 48,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: statusStyle.color,
                          size: 18,
                        ),
                        dropdownColor: Colors.white,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 10.8,
                          color: statusStyle.color,
                        ),
                        selectedItemBuilder: (context) {
                          return _statusOptions.map((status) {
                            final meta = _statusMeta[status]!;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                meta.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 10.8,
                                  color: meta.color,
                                ),
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
                                Icon(meta.icon, size: 14, color: meta.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    meta.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Detalle'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              const SizedBox(width: 2),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ],
          ),
        ],
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
class _CompactTag extends StatelessWidget {
  const _CompactTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.brandBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.brandBlue),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.muted),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10.9,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.synced});

  final bool synced;

  @override
  Widget build(BuildContext context) {
    final color = synced ? const Color(0xFF1B8E5A) : const Color(0xFFE4A620);
    final icon = synced ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded;
    final tooltip = synced ? 'Sincronizado' : 'Pendiente de sincronizacion';

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _InlineDueBadge extends StatelessWidget {
  const _InlineDueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD64545).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.error_rounded, size: 13, color: Color(0xFFD64545)),
          SizedBox(width: 4),
          Text(
            'Vencida',
            style: TextStyle(
              fontSize: 10.6,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD64545),
            ),
          ),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
        ),
      ),
    );
  }
}

class _FilterMeta {
  const _FilterMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const _statusOptions = ['pending', 'in_progress', 'completed'];

const _statusMeta = {
  'pending': _FilterMeta(
    label: 'Pendiente',
    icon: Icons.pending_outlined,
    color: Color(0xFF98A3B3),
  ),
  'in_progress': _FilterMeta(
    label: 'En proceso',
    icon: Icons.timelapse_rounded,
    color: Color(0xFFF0A11E),
  ),
  'completed': _FilterMeta(
    label: 'Finalizado',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF1B8E5A),
  ),
};

final _filterMeta = {
  'Retrasados': const _FilterMeta(
    label: 'Retrasados',
    icon: Icons.error_rounded,
    color: Color(0xFFD64545),
  ),
  'Vence hoy': const _FilterMeta(
    label: 'Vence hoy',
    icon: Icons.today_rounded,
    color: Color(0xFFE4A620),
  ),
  'Pendientes': const _FilterMeta(
    label: 'Pendientes',
    icon: Icons.pending_outlined,
    color: Color(0xFF98A3B3),
  ),
  'En proceso': const _FilterMeta(
    label: 'En proceso',
    icon: Icons.timelapse_rounded,
    color: Color(0xFFF0A11E),
  ),
  'Finalizados': const _FilterMeta(
    label: 'Finalizados',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF1B8E5A),
  ),
  'Todas': _FilterMeta(
    label: 'Todas',
    icon: Icons.apps_rounded,
    color: AppTheme.brandBlue,
  ),
};

final _statusFilters = [
  _FilterMeta(
    label: 'Retrasados',
    icon: Icons.error_rounded,
    color: Color(0xFFD64545),
  ),
  _FilterMeta(
    label: 'Vence hoy',
    icon: Icons.today_rounded,
    color: Color(0xFFE4A620),
  ),
  _FilterMeta(
    label: 'Pendientes',
    icon: Icons.pending_outlined,
    color: Color(0xFF98A3B3),
  ),
  _FilterMeta(
    label: 'En proceso',
    icon: Icons.timelapse_rounded,
    color: Color(0xFFF0A11E),
  ),
  _FilterMeta(
    label: 'Finalizados',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF1B8E5A),
  ),
  // _FilterMeta(
  //   label: 'Area',
  //   icon: Icons.domain_verification_outlined,
  //   color: AppTheme.brandBlue,
  // ),
  _FilterMeta(
    label: 'Todas',
    icon: Icons.apps_rounded,
    color: AppTheme.brandBlue,
  ),
];

