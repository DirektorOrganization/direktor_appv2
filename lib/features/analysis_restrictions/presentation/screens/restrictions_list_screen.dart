import 'package:flutter/material.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';

enum _RestrictionViewMode { calendar, list }

class RestrictionsListScreen extends StatefulWidget {
  const RestrictionsListScreen({super.key});

  @override
  State<RestrictionsListScreen> createState() => _RestrictionsListScreenState();
}

class _RestrictionsListScreenState extends State<RestrictionsListScreen> {
  final _searchController = TextEditingController();
  final Set<int> _dismissedRestrictionIds = <int>{};
  _RestrictionViewMode _viewMode = _RestrictionViewMode.list;
  String _filter = 'Retrasados';
  String? _selectedAreaCode;
  bool _headerExpanded = true;

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
          if (_dismissedRestrictionIds.contains(item.id)) return false;
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
                          expanded: _headerExpanded,
                          viewMode: _viewMode,
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
                          onViewModeChanged: (value) =>
                              setState(() => _viewMode = value),
                          onToggleExpanded: () =>
                              setState(() => _headerExpanded = !_headerExpanded),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: visibleItems.isEmpty
                              ? const _EmptyRestrictions()
                              : _viewMode == _RestrictionViewMode.list
                              ? ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: visibleItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final item = visibleItems[index];
                                    return Dismissible(
                                      key: ValueKey('restriction-${item.id}'),
                                      direction: DismissDirection.endToStart,
                                      background: const SizedBox.shrink(),
                                      secondaryBackground:
                                          const _DeleteRestrictionBackground(),
                                      onDismissed: (_) {
                                        setState(() {
                                          _dismissedRestrictionIds.add(item.id);
                                        });
                                        controller.deleteRestriction(item.id);
                                      },
                                      child: _RestrictionCard(
                                        item: item,
                                        statuses: catalogs.statuses,
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
                                      ),
                                    );
                                  },
                                )
                              : _RestrictionsCalendarView(
                                  items: visibleItems,
                                  statuses: catalogs.statuses,
                                  onStatusChanged: (restrictionId, statusCode) =>
                                      controller.updateRestrictionStatus(
                                        restrictionId,
                                        statusCode,
                                      ),
                                  onView: (restrictionId) =>
                                      Navigator.pushNamed(
                                        context,
                                        RouteNames.restrictionDetail,
                                        arguments: RestrictionDetailArgs(
                                          restrictionId: restrictionId,
                                        ),
                                      ),
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
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar por area',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
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
                ],
              ),
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
        return item.isPending;
      case 'En proceso':
        return item.isInProgress;
      case 'Finalizados':
        return item.isCompleted;
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
    if (item.isCompleted) return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final effectiveDate = item.conciliatedDate ?? item.requiredDate;
    final required = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    return current.isAfter(required);
  }

  bool _isDueToday(RestrictionRecord item) {
    if (item.isCompleted) return false;
    final today = DateTime.now();
    final effectiveDate = item.conciliatedDate ?? item.requiredDate;
    return effectiveDate.year == today.year &&
        effectiveDate.month == today.month &&
        effectiveDate.day == today.day;
  }

  String _normalizedStatusLabel(RestrictionRecord item) {
    return item.statusLabel;
  }
}

class _RestrictionsHeader extends StatelessWidget {
  const _RestrictionsHeader({
    required this.projectName,
    required this.expanded,
    required this.viewMode,
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
    required this.onViewModeChanged,
    required this.onToggleExpanded,
  });

  final String projectName;
  final bool expanded;
  final _RestrictionViewMode viewMode;
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
  final ValueChanged<_RestrictionViewMode> onViewModeChanged;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;
    final mutedSurface = isDark ? const Color(0xFF1B2733) : const Color(0xFFF6F8FB);
    final selectedAreaLabel = catalogs.areas
        .firstWhere(
          (item) => item.id == selectedAreaCode,
          orElse: () => const CatalogOption(id: '', label: 'Todas las areas'),
        )
        .label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue.withValues(alpha: 0.10),
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
              IconButton(
                onPressed: onToggleExpanded,
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                icon: Icon(
                  expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                  color: AppTheme.brandBlue,
                ),
                tooltip: expanded ? 'Comprimir cabecera' : 'Expandir cabecera',
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RestrictionModeChip(
                    label: 'Calendario',
                    icon: Icons.calendar_month_rounded,
                    selected: viewMode == _RestrictionViewMode.calendar,
                    onTap: () => onViewModeChanged(
                      _RestrictionViewMode.calendar,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _RestrictionModeChip(
                    label: 'Lista',
                    icon: Icons.view_list_rounded,
                    selected: viewMode == _RestrictionViewMode.list,
                    onTap: () => onViewModeChanged(_RestrictionViewMode.list),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.8, height: 1.1),
              decoration: InputDecoration(
                hintText: 'Buscar por area, frente, fase, responsable o estado',
                hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 10.6),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 6),
                  child: Icon(Icons.search_rounded, size: 15),
                ),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                        tooltip: 'Limpiar',
                      ),
                prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 28),
                suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.stroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.stroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.brandBlue, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _statusFilters[index];
                  final selected = selectedFilter == filter.label;
                  final labelColor = isDark
                      ? Colors.white
                      : (selected ? AppTheme.text : AppTheme.muted);
                  return ChoiceChip(
                    selected: selected,
                    avatar: Icon(
                      filter.icon,
                      size: 15,
                      color: selected ? filter.color : AppTheme.muted,
                    ),
                    label: Text(filter.label),
                    labelStyle: TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: mutedSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.stroke),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.domain_verification_outlined,
                            size: 15,
                            color: AppTheme.brandBlue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selectedAreaCode == null
                                  ? 'Area: todas'
                                  : 'Area: $selectedAreaLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.8,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                          ),
                          if (selectedAreaCode != null)
                            GestureDetector(
                              onTap: onClearArea,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.close_rounded, size: 15),
                              ),
                            ),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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

class _RestrictionModeChip extends StatelessWidget {
  const _RestrictionModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.brandBlue : AppTheme.muted;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white
        : (selected ? AppTheme.brandBlue : AppTheme.muted);
    return Material(
      color: selected
          ? AppTheme.brandBlue.withValues(alpha: 0.08)
          : (isDark ? const Color(0xFF1B2733) : const Color(0xFFF6F8FB)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.brandBlue : AppTheme.stroke,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestrictionsCalendarView extends StatelessWidget {
  const _RestrictionsCalendarView({
    required this.items,
    required this.statuses,
    required this.onStatusChanged,
    required this.onView,
  });

  final List<RestrictionRecord> items;
  final List<CatalogOption> statuses;
  final void Function(int restrictionId, String statusCode) onStatusChanged;
  final ValueChanged<int> onView;

  @override
  Widget build(BuildContext context) {
    final groupedByYear = <int, Map<DateTime, List<RestrictionRecord>>>{};
    for (final item in items) {
      final effectiveDate = item.conciliatedDate ?? item.requiredDate;
      final key = DateTime(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
      );
      final yearBucket = groupedByYear.putIfAbsent(
        key.year,
        () => <DateTime, List<RestrictionRecord>>{},
      );
      yearBucket.putIfAbsent(key, () => <RestrictionRecord>[]).add(item);
    }
    final years = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: years.map((year) {
        final dates = groupedByYear[year]!.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CalendarYearHeader(year: year),
            const SizedBox(height: 10),
            ...dates.map((date) {
              final dayItems = groupedByYear[year]![date]!
                ..sort(
                  (a, b) => (b.conciliatedDate ?? b.requiredDate).compareTo(
                    a.conciliatedDate ?? a.requiredDate,
                  ),
                );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CalendarDaySection(
                  date: date,
                  items: dayItems,
                  statuses: statuses,
                  onStatusChanged: onStatusChanged,
                  onView: onView,
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

class _CalendarYearHeader extends StatelessWidget {
  const _CalendarYearHeader({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2733) : const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.brandBlue),
          const SizedBox(width: 6),
          Text(
            '$year',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDaySection extends StatelessWidget {
  const _CalendarDaySection({
    required this.date,
    required this.items,
    required this.statuses,
    required this.onStatusChanged,
    required this.onView,
  });

  final DateTime date;
  final List<RestrictionRecord> items;
  final List<CatalogOption> statuses;
  final void Function(int restrictionId, String statusCode) onStatusChanged;
  final ValueChanged<int> onView;

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(date, DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayColor = isDark
        ? Colors.white
        : (isToday ? AppTheme.brandBlue : AppTheme.text);
    final monthColor = isDark
        ? Colors.white
        : (isToday ? AppTheme.brandBlue : AppTheme.muted);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.brandBlue.withValues(alpha: 0.10)
                      : (isDark ? const Color(0xFF1B2733) : const Color(0xFFF6F8FB)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday ? AppTheme.brandBlue : AppTheme.stroke,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      date.day.toString().padLeft(2, '0'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: dayColor,
                      ),
                    ),
                    Text(
                      _monthLabel(date.month),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.6,
                        fontWeight: FontWeight.w700,
                        color: monthColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 3,
                height: items.length * 94,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppTheme.stroke,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RestrictionAgendaCard(
                      item: item,
                      statuses: statuses,
                      onStatusChanged: (statusCode) =>
                          onStatusChanged(item.id, statusCode),
                      onView: () => onView(item.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _RestrictionAgendaCard extends StatelessWidget {
  const _RestrictionAgendaCard({
    required this.item,
    required this.statuses,
    required this.onStatusChanged,
    required this.onView,
  });

  final RestrictionRecord item;
  final List<CatalogOption> statuses;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedStatus = _calendarStatusKind(item);
    final statusStyle = _statusMeta[normalizedStatus] ?? _statusMeta['pending']!;
    final selectedStatusValue = _resolveSelectedStatusValue();
    final availableStatuses = statuses.isEmpty
        ? _statusOptions
              .map(
                (status) => CatalogOption(
                  id: status,
                  label: _statusMeta[status]!.label,
                ),
              )
              .toList()
        : statuses;
    final effectiveDate = item.conciliatedDate ?? item.requiredDate;
    final overdue = _calendarOverdue(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0817324D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 112,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: statusStyle.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: SizedBox(
                    height: 28,
                    child: DropdownButton<String>(
                      value: selectedStatusValue,
                      isDense: true,
                      itemHeight: 48,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: statusStyle.color,
                        size: 15,
                      ),
                      dropdownColor: isDark ? const Color(0xFF16202B) : Colors.white,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 10.0,
                        color: statusStyle.color,
                      ),
                      selectedItemBuilder: (context) {
                        return availableStatuses.map((status) {
                          final meta =
                              _statusMeta[_statusKindForOption(status)] ??
                              statusStyle;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              status.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontSize: 10.0,
                                    color: meta.color,
                                  ),
                            ),
                          );
                        }).toList();
                      },
                      items: availableStatuses.map((status) {
                        final meta =
                            _statusMeta[_statusKindForOption(status)] ??
                            statusStyle;
                        return DropdownMenuItem<String>(
                          value: status.id,
                          child: Row(
                            children: [
                              Icon(meta.icon, size: 13, color: meta.color),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  status.label,
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
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _MiniInfo(icon: Icons.apartment_rounded, text: item.front),
              _MiniInfo(icon: Icons.layers_outlined, text: item.phase),
              _MiniInfo(
                icon: Icons.event_outlined,
                text: _formatAgendaDate(effectiveDate),
              ),
              if (overdue) const _InlineDueBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AgendaMiniInfo(
                  icon: Icons.person_outline_rounded,
                  text: item.responsible,
                ),
              ),
              TextButton.icon(
                onPressed: onView,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Detalle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _calendarOverdue(RestrictionRecord item) {
    if (item.isCompleted) return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final effectiveDate = item.conciliatedDate ?? item.requiredDate;
    final target = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    return current.isAfter(target);
  }

  String _calendarStatusKind(RestrictionRecord item) {
    if (item.isCompleted) return 'completed';
    if (item.isInProgress) return 'in_progress';
    return 'pending';
  }

  String _statusKindForOption(CatalogOption option) {
    final label = option.label.trim().toLowerCase();
    if (label.contains('complet') || label.contains('final')) {
      return 'completed';
    }
    if (label.contains('proceso') || label.contains('progress')) {
      return 'in_progress';
    }
    return 'pending';
  }

  String _resolveSelectedStatusValue() {
    for (final status in statuses) {
      if (status.id == item.statusCode) return status.id;
    }
    for (final status in statuses) {
      if (status.label.trim().toLowerCase() ==
          item.statusLabel.trim().toLowerCase()) {
        return status.id;
      }
    }
    return item.statusCode;
  }
}

class _RestrictionCard extends StatelessWidget {
  const _RestrictionCard({
    required this.item,
    required this.statuses,
    required this.onStatusChanged,
    required this.onView,
    required this.onEdit,
  });

  final RestrictionRecord item;
  final List<CatalogOption> statuses;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = _statusKind(item);
    final statusStyle = _statusMeta[normalizedStatus] ?? _statusMeta['pending']!;
    final selectedStatusValue = _resolveSelectedStatusValue();
    final availableStatuses = statuses.isEmpty
        ? _statusOptions
            .map((status) => CatalogOption(id: status, label: _statusMeta[status]!.label))
            .toList()
        : statuses;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final overdue = _isOverdue(item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202B) : Colors.white,
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
          const SizedBox(height: 8),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.2, height: 1.25),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MiniInfo(
                icon: Icons.person_outline_rounded,
                text: item.responsible,
                compact: true,
                maxWidth: 92,
              ),
              _MiniInfo(
                icon: Icons.event_outlined,
                text: _formatDate(item.conciliatedDate ?? item.requiredDate),
              ),
              if (overdue) const _InlineDueBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 112,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: statusStyle.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: SizedBox(
                      height: 32,
                      child: DropdownButton<String>(
                        value: selectedStatusValue,
                        isDense: true,
                        itemHeight: 48,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: statusStyle.color,
                          size: 16,
                        ),
                        dropdownColor: isDark ? const Color(0xFF16202B) : Colors.white,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 10.4,
                          color: statusStyle.color,
                        ),
                        selectedItemBuilder: (context) {
                          return availableStatuses.map((status) {
                            final meta = _statusMeta[_statusKindForOption(status)] ?? statusStyle;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                status.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 10.4,
                                  color: meta.color,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: availableStatuses.map((status) {
                          final meta = _statusMeta[_statusKindForOption(status)] ?? statusStyle;
                          return DropdownMenuItem<String>(
                            value: status.id,
                            child: Row(
                              children: [
                                Icon(meta.icon, size: 14, color: meta.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    status.label,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 2),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isOverdue(RestrictionRecord item) {
    if (item.isCompleted) return false;
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final effectiveDate = item.conciliatedDate ?? item.requiredDate;
    final required = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );
    return current.isAfter(required);
  }

  String _statusKind(RestrictionRecord item) {
    if (item.isCompleted) return 'completed';
    if (item.isInProgress) return 'in_progress';
    return 'pending';
  }

  String _resolveSelectedStatusValue() {
    for (final status in statuses) {
      if (status.id == item.statusCode) {
        return status.id;
      }
    }
    for (final status in statuses) {
      if (status.label.trim().toLowerCase() == item.statusLabel.trim().toLowerCase()) {
        return status.id;
      }
    }
    return item.statusCode;
  }

  String _statusKindForOption(CatalogOption option) {
    final label = option.label.trim().toLowerCase();
    if (label.contains('complet') || label.contains('final')) return 'completed';
    if (label.contains('proceso') || label.contains('progress')) return 'in_progress';
    return 'pending';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _DeleteRestrictionBackground extends StatelessWidget {
  const _DeleteRestrictionBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD64545),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _CompactTag extends StatelessWidget {
  const _CompactTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? Colors.white : AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.text,
    this.compact = false,
    this.maxWidth,
  });

  final IconData icon;
  final String text;
  final bool compact;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 12 : 13, color: AppTheme.muted),
        SizedBox(width: compact ? 4 : 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: compact ? 10.2 : 10.9,
              color: AppTheme.muted,
            ),
          ),
        ),
      ],
    );
    if (maxWidth != null) {
      return SizedBox(width: maxWidth, child: content);
    }
    return content;
  }
}

class _AgendaMiniInfo extends StatelessWidget {
  const _AgendaMiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10.9,
              color: AppTheme.muted,
            ),
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
              fontSize: 10.2,
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

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _monthLabel(int month) {
  const labels = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OCT',
    'NOV',
    'DIC',
  ];
  return labels[month - 1];
}

String _formatAgendaDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}


