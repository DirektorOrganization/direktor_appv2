import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/route_arguments.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../control_hitos_demo_store.dart';

enum _MilestoneViewMode { list, timeline }

class ControlHitosScreen extends StatefulWidget {
  const ControlHitosScreen({super.key});

  @override
  State<ControlHitosScreen> createState() => _ControlHitosScreenState();
}

class _ControlHitosScreenState extends State<ControlHitosScreen> {
  final _searchController = TextEditingController();
  final Set<int> _dismissedMilestoneIds = <int>{};
  _MilestoneViewMode _viewMode = _MilestoneViewMode.timeline;
  String _filter = 'Retrasados';
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
        final allItems = controller.milestones;
        final general = controller.milestoneGeneral ??
            MilestoneGeneralRecord(
              projectId: project?.id ?? 0,
              controlId: 0,
              generalId: 0,
              startDate: null,
              totalDays: 0,
              totalAmount: 0,
              statusCode: '1',
            );
        final summary = controller.milestoneSummary;
        final query = _viewMode == _MilestoneViewMode.timeline ? '' : _searchController.text.trim().toLowerCase();
        final visibleItems = allItems.where((item) {
          if (_dismissedMilestoneIds.contains(item.id)) return false;
          final haystack = [
            item.code,
            item.description,
            item.typeLabel,
            item.classificationLabel,
            item.contractualStatusLabel,
            item.internalStatusLabel,
          ].join(' ').toLowerCase();
          final matchesSearch = query.isEmpty || haystack.contains(query);
          final matchesFilter = _filter == 'Todas' || _matchesFilter(item, _filter);
          return matchesSearch && matchesFilter;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Control de Hitos')),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      children: [
                        _HitosHeader(
                          projectName: project?.name ?? 'Proyecto',
                          general: general,
                          summary: summary,
                          viewMode: _viewMode,
                          expanded: _headerExpanded,
                          selectedFilter: _filter,
                          searchController: _searchController,
                          onSearchChanged: (_) => setState(() {}),
                          onClearSearch: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          onFilterChanged: (value) => setState(() => _filter = value),
                          onViewModeChanged: (mode) => setState(() => _viewMode = mode),
                          onToggleExpanded: () => setState(() => _headerExpanded = !_headerExpanded),
                          onEditGeneral: () => _showEditGeneralSheet(context, general),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: visibleItems.isEmpty
                              ? const _EmptyMilestones()
                              : _viewMode == _MilestoneViewMode.list
                                  ? ListView.separated(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      itemCount: visibleItems.length,
                                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = visibleItems[index];
                                        return Dismissible(
                                          key: ValueKey('milestone-${item.id}'),
                                          direction: DismissDirection.endToStart,
                                          background: const SizedBox.shrink(),
                                          secondaryBackground: const _DeleteMilestoneBackground(),
                                          onDismissed: (_) {
                                            setState(() {
                                              _dismissedMilestoneIds.add(item.id);
                                            });
                                            controller.deleteMilestone(item.id);
                                          },
                                          child: _MilestoneCard(
                                            item: item,
                                            onView: () => Navigator.pushNamed(
                                              context,
                                              RouteNames.controlHitosDetail,
                                              arguments: MilestoneDetailArgs(milestoneId: item.id),
                                            ),
                                            onAmpliar: () => Navigator.pushNamed(
                                              context,
                                              RouteNames.controlHitosExtensionCreate,
                                              arguments: MilestoneExtensionFormArgs(milestoneId: item.id),
                                            ),
                                            onSubir: () => _showUploadSheet(context, item),
                                          ),
                                        );
                                      },
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      children: [
                                        _TimelinePanel(
                                          records: visibleItems,
                                          general: general,
                                          onViewDetail: (milestoneId) => Navigator.pushNamed(
                                            context,
                                            RouteNames.controlHitosDetail,
                                            arguments: MilestoneDetailArgs(milestoneId: milestoneId),
                                          ),
                                        ),
                                      ],
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
                        onPressed: () => Navigator.pushNamed(context, RouteNames.controlHitosCreate),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nuevo hito'),
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

  bool _matchesFilter(MilestoneRecord item, String filter) {
    switch (filter) {
      case 'Retrasados':
        return item.isDelayed;
      case 'En progreso':
        return item.isInProgress;
      case 'Completados':
        return item.isCompleted;
      default:
        return true;
    }
  }

  Future<void> _showUploadSheet(BuildContext context, MilestoneRecord record) async {
    final controller = AppScope.of(context);
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    var isSaving = false;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subir documento', style: Theme.of(sheetContext).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(record.description, style: Theme.of(sheetContext).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre del documento')),
                  const SizedBox(height: 12),
                  TextField(controller: pathController, readOnly: true, decoration: const InputDecoration(labelText: 'Archivo seleccionado')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            try {
                              final result = await FilePicker.platform.pickFiles(type: FileType.any);
                              if (!sheetContext.mounted) return;
                              final file = (result == null || result.files.isEmpty) ? null : result.files.first;
                              if (file == null) return;
                              if (!_isAllowedDocument(file.name)) {
                                _showUploadMessage(sheetContext, 'Selecciona un PDF, Word o imagen.');
                                return;
                              }
                              pathController.text = file.path ?? file.name;
                              if (nameController.text.trim().isEmpty) {
                                nameController.text = file.name;
                              }
                              setModalState(() {});
                            } on MissingPluginException {
                              if (!sheetContext.mounted) return;
                              _showUploadMessage(sheetContext, 'Debes cerrar y volver a abrir la app para habilitar la carga de archivos.');
                            }
                          },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Seleccionar archivo'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final navigator = Navigator.of(sheetContext);
                              setModalState(() => isSaving = true);
                              try {
                                await controller.saveMilestoneDocument(
                                  MilestoneDocumentDraft(
                                    milestoneId: record.id,
                                    name: nameController.text.trim(),
                                    path: pathController.text.trim(),
                                  ),
                                );
                                if (!sheetContext.mounted) return;
                                navigator.pop();
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSaving = false);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Subir'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    pathController.dispose();
  }

  Future<void> _showEditGeneralSheet(BuildContext context, MilestoneGeneralRecord general) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _EditMilestoneGeneralSheet(general: general),
    );
  }

  bool _isAllowedDocument(String fileName) {
    final normalized = fileName.toLowerCase();
    return normalized.endsWith('.pdf') ||
        normalized.endsWith('.doc') ||
        normalized.endsWith('.docx') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.png') ||
        normalized.endsWith('.webp');
  }

  void _showUploadMessage(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HitosHeader extends StatelessWidget {
  const _HitosHeader({
    required this.projectName,
    required this.general,
    required this.summary,
    required this.viewMode,
    required this.expanded,
    required this.selectedFilter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
    required this.onViewModeChanged,
    required this.onToggleExpanded,
    required this.onEditGeneral,
  });

  final String projectName;
  final MilestoneGeneralRecord general;
  final MilestoneDashboardSummary summary;
  final _MilestoneViewMode viewMode;
  final bool expanded;
  final String selectedFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<_MilestoneViewMode> onViewModeChanged;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEditGeneral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;

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
                child: Icon(Icons.flag_circle_rounded, size: 20, color: AppTheme.brandBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(projectName, style: theme.textTheme.titleMedium?.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(
                      viewMode == _MilestoneViewMode.list ? 'Control de hitos - lista' : 'Control de hitos - timeline',
                      style: theme.textTheme.bodySmall,
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
                  child: _ModeChip(
                    label: 'Timeline',
                    icon: Icons.timeline_rounded,
                    selected: viewMode == _MilestoneViewMode.timeline,
                    onTap: () => onViewModeChanged(_MilestoneViewMode.timeline),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ModeChip(
                    label: 'Lista',
                    icon: Icons.view_list_rounded,
                    selected: viewMode == _MilestoneViewMode.list,
                    onTap: () => onViewModeChanged(_MilestoneViewMode.list),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (viewMode == _MilestoneViewMode.list)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _HeaderMetric(
                      label: 'Inicio C.',
                      fullLabel: 'Inicio contractual',
                      value: _formatDate(general.startDate),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _HeaderMetric(
                      label: 'Plazo T.',
                      fullLabel: 'Plazo total',
                      value: '${general.totalDays} d.',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _HeaderMetric(
                            label: 'Monto T.',
                            fullLabel: 'Monto total',
                            value: _formatAmount(general.totalAmount),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: onEditGeneral,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          splashRadius: 16,
                          tooltip: 'Editar datos generales',
                          icon: const Icon(Icons.edit_outlined, size: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ,
            const SizedBox(height: 12),
            if (viewMode == _MilestoneViewMode.list) ...[
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.8, height: 1.1),
                decoration: InputDecoration(
                  hintText: 'Buscar hitos...',
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
            ],
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final selected = selectedFilter == filter.label;
                  final labelColor = theme.brightness == Brightness.dark
                      ? Colors.white
                      : (selected ? AppTheme.text : AppTheme.muted);
                  return ChoiceChip(
                    selected: selected,
                    avatar: Icon(filter.icon, size: 15, color: selected ? filter.color : AppTheme.muted),
                    label: Text(filter.label),
                    labelStyle: TextStyle(fontSize: 10.8, fontWeight: FontWeight.w700, color: labelColor),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                    onSelected: (_) => onFilterChanged(filter.label),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatAmount(double value) {
    final digits = value.round().toString();
    final parts = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = (end - 3).clamp(0, digits.length);
      parts.insert(0, digits.substring(start, end));
    }
    return 'S/ ${parts.join(',')}';
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.item,
    required this.onView,
    required this.onAmpliar,
    required this.onSubir,
  });

  final MilestoneRecord item;
  final VoidCallback onView;
  final VoidCallback onAmpliar;
  final VoidCallback onSubir;

  @override
  Widget build(BuildContext context) {
    final color = milestoneStatusColor(item.statusCode);
    final surfaceColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF16202B)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flag_outlined, size: 16, color: AppTheme.brandBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hito: ${item.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12.8),
                    ),
                    const SizedBox(height: 2),
                    Text(item.code, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.6, color: AppTheme.brandBlue)),
                  ],
                ),
              ),
              _SyncIndicator(synced: item.isSynced),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  icon: Icons.event_outlined,
                  text: 'Meta: ${_formatDate(item.effectiveTargetDate)}',
                ),
              ),
              Expanded(
                child: _MiniInfo(
                  icon: Icons.payments_outlined,
                  text: '${(item.penaltyPercent * 100).toStringAsFixed(2)}% | S/ ${item.penaltyAmount.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(
                  icon: Icons.schedule_send_outlined,
                  text: 'Ampliaciones: ${item.extensionCount}',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(milestoneStatusIcon(item.statusCode), size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      item.statusLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onAmpliar,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                icon: const Icon(Icons.add_chart_rounded, size: 15),
                label: const Text('Ampliar'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onView,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                icon: const Icon(Icons.visibility_outlined, size: 15),
                label: const Text('Detalle'),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: onSubir,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                icon: const Icon(Icons.attach_file_rounded, size: 15),
                label: const Text('Subir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DeleteMilestoneBackground extends StatelessWidget {
  const _DeleteMilestoneBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD64545),
        borderRadius: BorderRadius.circular(16),
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

class _EditMilestoneGeneralSheet extends StatefulWidget {
  const _EditMilestoneGeneralSheet({required this.general});

  final MilestoneGeneralRecord general;

  @override
  State<_EditMilestoneGeneralSheet> createState() => _EditMilestoneGeneralSheetState();
}

class _EditMilestoneGeneralSheetState extends State<_EditMilestoneGeneralSheet> {
  late final TextEditingController _startDateController;
  late final TextEditingController _totalDaysController;
  late final TextEditingController _totalAmountController;
  DateTime? _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.general.startDate;
    _startDateController = TextEditingController(text: _formatDate(widget.general.startDate));
    _totalDaysController = TextEditingController(
      text: widget.general.totalDays == 0 ? '' : '${widget.general.totalDays}',
    );
    _totalAmountController = TextEditingController(
      text: widget.general.totalAmount == 0 ? '' : widget.general.totalAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _totalDaysController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar datos generales', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Inicio contractual, plazo total y monto total.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _startDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Inicio contractual',
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked == null || !mounted) return;
              setState(() {
                _selectedDate = picked;
                _startDateController.text = _formatDate(picked);
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Plazo total (dias)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto total'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      final navigator = Navigator.of(context);
                      setState(() => _saving = true);
                      try {
                        await controller.saveMilestoneGeneral(
                          MilestoneGeneralDraft(
                            projectId: widget.general.projectId,
                            controlId: widget.general.controlId,
                            generalId: widget.general.generalId,
                            startDate: _selectedDate,
                            totalDays: int.tryParse(_totalDaysController.text.trim()) ?? 0,
                            totalAmount: double.tryParse(_totalAmountController.text.trim().replaceAll(',', '')) ?? 0,
                          ),
                        );
                        if (!mounted) return;
                        navigator.pop();
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
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
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.8, color: AppTheme.muted),
          ),
        ),
      ],
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
    required this.records,
    required this.general,
    required this.onViewDetail,
  });

  final List<MilestoneRecord> records;
  final MilestoneGeneralRecord general;
  final ValueChanged<int> onViewDetail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;
    final sorted = [...records]..sort((a, b) => a.effectiveTargetDate.compareTo(b.effectiveTargetDate));
    final accumulated = sorted.where((item) => item.isCompleted && item.delayDays > 0).fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final extended = sorted.fold<int>(0, (sum, item) => sum + item.extensionCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surfaceColor,
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
          Text('Timeline del proyecto', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Inicio de obra: ${_shortDate(general.startDate)}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          ...sorted.asMap().entries.map(
            (entry) => _TimelineRow(
              item: entry.value,
              isLast: entry.key == sorted.length - 1,
              onViewDetail: () => onViewDetail(entry.value.id),
            ),
          ),
          const Divider(height: 28),
          _FooterInfo(label: 'Inicio obra', value: _formatDate(general.startDate)),
          const SizedBox(height: 6),
          _FooterInfo(label: 'Penalidad acumulada', value: 'S/ ${accumulated.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _FooterInfo(label: 'Ampliaciones', value: '$extended'),
        ],
      ),
    );
  }

  String _shortDate(DateTime? value) {
    if (value == null) return '--/--';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.onViewDetail,
  });

  final MilestoneRecord item;
  final bool isLast;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final color = milestoneStatusColor(item.statusCode);
    final mutedSurface = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B2733)
        : AppTheme.background;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _shortDate(item.effectiveTargetDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 8)],
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 3, margin: const EdgeInsets.symmetric(vertical: 6), color: color.withValues(alpha: 0.24))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mutedSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.stroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13.2)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(item.statusLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                        if (item.extensionCount > 0) Text('${item.extensionCount} ampliaciones', style: Theme.of(context).textTheme.bodySmall),
                        if (item.isDelayed) Text('${(item.penaltyPercent * 100).toStringAsFixed(1)}% penalidad', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onViewDetail,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text('Ver detalle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.fullLabel,
    required this.value,
  });

  final String label;
  final String fullLabel;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showFullLabel(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.2)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13.2, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _showFullLabel(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(fullLabel),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FooterInfo extends StatelessWidget {
  const _FooterInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
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

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedSurface = isDark ? const Color(0xFF1B2733) : AppTheme.background;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandBlue.withValues(alpha: 0.10) : unselectedSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.brandBlue.withValues(alpha: 0.18) : AppTheme.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? AppTheme.brandBlue : AppTheme.muted),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white
                    : (selected ? AppTheme.brandBlue : AppTheme.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMilestones extends StatelessWidget {
  const _EmptyMilestones();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'No se tienen hitos para el filtro o busqueda actual.',
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

final _filters = [
  _FilterMeta(label: 'Retrasados', icon: Icons.error_rounded, color: const Color(0xFFD64545)),
  _FilterMeta(label: 'En progreso', icon: Icons.timelapse_rounded, color: const Color(0xFFF0A11E)),
  _FilterMeta(label: 'Completados', icon: Icons.check_circle_rounded, color: const Color(0xFF1B8E5A)),
  _FilterMeta(label: 'Todas', icon: Icons.apps_rounded, color: AppTheme.brandBlue),
];
