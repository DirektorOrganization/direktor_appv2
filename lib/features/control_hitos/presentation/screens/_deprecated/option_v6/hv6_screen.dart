// ignore_for_file: lines_longer_than_80_chars
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/routes/route_arguments.dart';
import '../../../../../app/routes/route_names.dart';
import '../../../../../app/state/app_scope.dart';
import '../../../../../data/models/app_models.dart';

// ─── Paleta ───────────────────────────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7);
  static const accent      = Color(0xFF1167C8);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const red         = Color(0xFFEF4444);
  static const green       = Color(0xFF10B981);
  static const yellow      = Color(0xFFF59E0B);
  static const white       = Colors.white;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
Color _statusColor(MilestoneRecord m) {
  if (m.isCompleted)  return _D.green;
  if (m.isDelayed)    return _D.red;
  if (m.isInProgress) return _D.accent;
  return _D.mutedLight;
}

IconData _statusIcon(MilestoneRecord m) {
  if (m.isCompleted)  return Icons.check_circle_rounded;
  if (m.isDelayed)    return Icons.warning_amber_rounded;
  if (m.isInProgress) return Icons.timelapse_rounded;
  return Icons.radio_button_unchecked_rounded;
}

String _fmtShort(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

Color _classColor(String? label) {
  switch (label?.toLowerCase()) {
    case 'contractual': return _D.primary;
    case 'crítico':
    case 'critico':     return _D.red;
    case 'calidad':     return const Color(0xFF7C3AED);
    default:            return _D.muted;
  }
}

/// Ordena hitos: primero en progreso/retrasados (por fecha más próxima),
/// luego pendientes (por fecha más próxima), luego completados (más recientes arriba).
List<MilestoneRecord> _sortByProximity(List<MilestoneRecord> all) {
  final active   = all.where((m) => m.isInProgress || m.isDelayed).toList()
    ..sort((a, b) => a.effectiveContractualDate.compareTo(b.effectiveContractualDate));
  final pending  = all.where((m) => !m.isCompleted && !m.isInProgress && !m.isDelayed).toList()
    ..sort((a, b) => a.effectiveContractualDate.compareTo(b.effectiveContractualDate));
  final completed = all.where((m) => m.isCompleted).toList()
    ..sort((a, b) => (b.actualDate ?? b.effectiveContractualDate).compareTo(a.actualDate ?? a.effectiveContractualDate));
  return [...active, ...pending, ...completed];
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class Hv6Screen extends StatefulWidget {
  const Hv6Screen({super.key});
  @override
  State<Hv6Screen> createState() => _Hv6ScreenState();
}

class _Hv6ScreenState extends State<Hv6Screen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final TextEditingController _searchCtrl;
  bool _showGantt = false;
  bool _showSearch = false;
  bool _generalEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: 0);
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext ctx, int id) =>
      Navigator.of(ctx).pushNamed(RouteNames.controlHitosV2Detail, arguments: MilestoneDetailArgs(milestoneId: id));

  void _toggleSearch() => setState(() {
    _showSearch = !_showSearch;
    if (!_showSearch) {
      _searchCtrl.clear();
    }
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = AppScope.of(context);
    return AnimatedBuilder(
      animation: ctrl,
      builder: (ctx, _) {
        final milestones  = ctrl.milestones;
        final summary     = ctrl.milestoneSummary;
        final project     = ctrl.currentProject;
        final byDate      = [...milestones]..sort((a, b) => a.effectiveContractualDate.compareTo(b.effectiveContractualDate));
        final query = _searchCtrl.text.trim().toLowerCase();
        final filteredByDate = query.isEmpty
            ? byDate
            : byDate.where((m) {
                final haystack = '${m.code} ${m.description} ${m.typeLabel} ${m.classificationLabel}'.toLowerCase();
                return haystack.contains(query);
              }).toList();
        final filteredByProximity = _sortByProximity(filteredByDate);
        final general = ctrl.milestoneGeneral ??
            MilestoneGeneralRecord(
              projectId: project?.id ?? 0,
              controlId: byDate.isNotEmpty ? byDate.first.controlId : 0,
              generalId: byDate.isNotEmpty ? byDate.first.generalId : 0,
              startDate: null,
              totalDays: 0,
              totalAmount: 0,
              controversyDays: 0,
              statusCode: '1',
              appliesToGeneral: false,
            );

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(project, ctrl, general),
          bottomSheet: _showSearch
              ? _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  onClose: _toggleSearch,
                )
              : null,
          body: Stack(
            children: [
              Column(
                children: [
                  // ── Stats strip ──────────────────────────────────────────
                  _StatsStrip(summary: summary, total: milestones.length),
                  // ── Tabs ─────────────────────────────────────────────────
                  Container(
                    color: _D.white,
                    child: TabBar(
                      controller: _tabCtrl,
                      labelColor: _D.primary,
                      unselectedLabelColor: _D.muted,
                      indicatorColor: _D.primary,
                      indicatorWeight: 2.5,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_view_rounded,  size: 16), text: 'Matriz'),
                        Tab(icon: Icon(Icons.table_rows_rounded, size: 16), text: 'Datos'),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _D.stroke),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Tab 1 — Datos (lista compacta)
                        _MatrizTab(milestones: filteredByProximity, onTap: (m) => _openDetail(ctx, m.id)),
                        // Tab 2 — Matriz de proximidad
                        _DataTab(milestones: filteredByDate, onTap: (m) => _openDetail(ctx, m.id)),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Gantt overlay ─────────────────────────────────────────────
              if (_showGantt)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _GanttPanel(
                    milestones: filteredByDate,
                    onClose: () => setState(() => _showGantt = false),
                  ),
                ),
              // ── FAB diagrama (bottom-left) ────────────────────────────────
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton.small(
                  heroTag: 'diagram_hv6',
                  backgroundColor: _showGantt ? _D.primary : _D.surface,
                  foregroundColor: _showGantt ? _D.white : _D.muted,
                  elevation: 2,
                  onPressed: () => setState(() => _showGantt = !_showGantt),
                  child: const Icon(Icons.bar_chart_rounded),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            heroTag: 'add_hv6',
            backgroundColor: _D.primary,
            foregroundColor: _D.white,
            elevation: 2,
            onPressed: _showSearch
                ? null
                : () => Navigator.of(ctx).pushNamed(RouteNames.controlHitosCreate),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(dynamic project, dynamic ctrl, MilestoneGeneralRecord general) {
    return AppBar(
      backgroundColor: _D.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Control de Hitos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _D.text)),
          if (project != null)
            Text(project.name ?? '', style: const TextStyle(fontSize: 11, color: _D.muted)),
        ],
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: IconButton(
            key: ValueKey(_showSearch),
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearch ? _D.primary : _D.muted,
            ),
            onPressed: _toggleSearch,
          ),
        ),
        IconButton(
          icon: Icon(
            _generalEnabled ? Icons.dataset_rounded : Icons.dataset_outlined,
            color: _generalEnabled ? _D.primary : _D.muted,
          ),
          tooltip: 'Datos generales',
          onPressed: () => _showGeneralSheet(context, ctrl, general),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _D.stroke)),
    );
  }

  Future<void> _showGeneralSheet(
    BuildContext context,
    dynamic controller,
    MilestoneGeneralRecord general,
  ) async {
    var enabled = _generalEnabled;
    final startDate = ValueNotifier<DateTime?>(general.startDate);
    final daysCtrl = TextEditingController(
      text: general.totalDays == 0 ? '' : '${general.totalDays}',
    );
    final amountCtrl = TextEditingController(
      text: general.totalAmount == 0 ? '' : general.totalAmount.toStringAsFixed(0),
    );
    final controversyCtrl = TextEditingController(
      text: general.controversyDays == 0 ? '' : '${general.controversyDays}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _D.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header con toggle ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: enabled
                              ? _D.primary.withValues(alpha: 0.1)
                              : _D.stroke.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.dataset_rounded,
                            color: enabled ? _D.primary : _D.mutedLight, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Detalle general',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _D.text)),
                            Text(
                              enabled ? 'Activo · indicadores y penalización habilitados' : 'Inactivo · solo se muestran los hitos',
                              style: TextStyle(fontSize: 11, color: enabled ? _D.primary : _D.mutedLight),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: enabled,
                        onChanged: (value) => setSheetState(() => enabled = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ── Aviso contextual ────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: enabled
                        ? Container(
                            key: const ValueKey('on'),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _D.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _D.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline_rounded, size: 14, color: _D.primary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Los datos ingresados se usarán para calcular penalización e indicadores del proyecto.',
                                    style: TextStyle(fontSize: 11, color: _D.primary, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            key: const ValueKey('off'),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _D.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _D.stroke),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline_rounded, size: 14, color: _D.mutedLight),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Al activar, podrás ingresar los datos del contrato para habilitar indicadores y cálculo de penalización.',
                                    style: TextStyle(fontSize: 11, color: _D.muted, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  // ── Campos (solo si habilitado) ─────────────────────────
                  if (enabled) ...[
                    const SizedBox(height: 16),
                    const Text('DATOS DEL CONTRATO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _D.muted, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: startDate,
                      builder: (context, value, _) {
                        return InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: value ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              startDate.value = picked;
                              setSheetState(() {});
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _D.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _D.stroke),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_rounded, size: 18, color: _D.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Fecha de inicio contractual',
                                          style: TextStyle(fontSize: 11, color: _D.muted)),
                                      Text(_fmtDate(value),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _D.text)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 18, color: _D.mutedLight),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _GeneralField(
                            controller: daysCtrl,
                            label: 'Plazo total (días)',
                            icon: Icons.calendar_month_rounded,
                            color: _D.primary,
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GeneralField(
                            controller: amountCtrl,
                            label: 'Monto total',
                            icon: Icons.attach_money_rounded,
                            color: _D.green,
                            onChanged: (_) => setSheetState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _GeneralField(
                      controller: controversyCtrl,
                      label: 'Días de controversia',
                      icon: Icons.gavel_rounded,
                      color: _D.yellow,
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: startDate,
                      builder: (context, dateVal, _) {
                        return Row(
                          children: [
                            _GeneralMetricCard(icon: Icons.event_rounded,          label: 'F. Inicio', value: _fmtShort(dateVal),                                              color: _D.accent),
                            const SizedBox(width: 6),
                            _GeneralMetricCard(icon: Icons.calendar_month_rounded, label: 'Plazo',     value: daysCtrl.text.isEmpty       ? '—' : '${daysCtrl.text}d',        color: _D.primary),
                            const SizedBox(width: 6),
                            _GeneralMetricCard(icon: Icons.attach_money_rounded,   label: 'Monto',     value: amountCtrl.text.isEmpty     ? '—' : amountCtrl.text,             color: _D.green),
                            const SizedBox(width: 6),
                            _GeneralMetricCard(icon: Icons.gavel_rounded,          label: 'Controv.',  value: controversyCtrl.text.isEmpty ? '—' : '${controversyCtrl.text}d', color: _D.yellow),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  // ── Botones ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _generalEnabled = enabled);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _D.stroke),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: enabled
                              ? () async {
                                  setState(() => _generalEnabled = true);
                                  await controller.saveMilestoneGeneral(
                                    MilestoneGeneralDraft(
                                      projectId: general.projectId,
                                      controlId: general.controlId,
                                      generalId: general.generalId,
                                      startDate: startDate.value,
                                      totalDays: int.tryParse(daysCtrl.text.trim()) ?? 0,
                                      totalAmount: double.tryParse(amountCtrl.text.trim()) ?? 0,
                                      controversyDays: int.tryParse(controversyCtrl.text.trim()) ?? 0,
                                      appliesToGeneral: enabled,
                                    ),
                                  );
                                  if (mounted) Navigator.pop(context); // ignore: use_build_context_synchronously
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _D.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

  }
}

// ─── Stats Strip ─────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.summary, required this.total});
  final MilestoneDashboardSummary? summary;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s   = summary;
    final pct = s?.compliance ?? 0.0;
    return Container(
      color: _D.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          _Strip('Total',       '$total',                    _D.primary),
          _StripDiv(),
          _Strip('Completados', '${s?.completedCount ?? 0}', _D.green),
          _StripDiv(),
          _Strip('En proceso',  '${s?.inProgressCount ?? 0}', _D.accent),
          _StripDiv(),
          _Strip('Retrasados',  '${s?.delayedCount ?? 0}',   _D.red),
          _StripDiv(),
          _Strip('Cumpl.',      '${pct.toStringAsFixed(0)}%', pct >= 80 ? _D.green : pct >= 50 ? _D.yellow : _D.red),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, height: 1)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: _D.muted, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _StripDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 26, color: _D.stroke, margin: const EdgeInsets.symmetric(horizontal: 3));
}

class _GeneralField extends StatelessWidget {
  const _GeneralField({required this.controller, required this.label, required this.icon, required this.color, required this.onChanged});
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: color),
        filled: true,
        fillColor: _D.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _D.stroke)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _D.stroke)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _D.primary)),
      ),
    );
  }
}

class _GeneralMetricCard extends StatelessWidget {
  const _GeneralMetricCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _D.muted)),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: _D.white,
          border: Border(top: BorderSide(color: _D.stroke)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                style: const TextStyle(fontSize: 13, color: _D.text),
                decoration: InputDecoration(
                  hintText: 'Código, descripción, tipo...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: _D.mutedLight,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _D.stroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _D.stroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: _D.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close_rounded, size: 18, color: _D.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — DATOS (lista compacta, orden cronológico)
// ═══════════════════════════════════════════════════════════════════════════════
class _DataTab extends StatelessWidget {
  const _DataTab({required this.milestones, required this.onTap});
  final List<MilestoneRecord> milestones;
  final void Function(MilestoneRecord) onTap;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const Center(child: Text('No hay hitos registrados', style: TextStyle(color: _D.muted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: milestones.length,
      itemBuilder: (_, i) {
        final m     = milestones[i];
        final color = _statusColor(m);
        return GestureDetector(
          onTap: () => onTap(m),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: _D.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 3.5)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(m), size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.description, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _D.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(m.code, style: const TextStyle(fontSize: 10, color: _D.mutedLight)),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_rounded, size: 10, color: _D.mutedLight),
                        const SizedBox(width: 3),
                        Text(_fmtShort(m.effectiveContractualDate), style: const TextStyle(fontSize: 10, color: _D.muted)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    m.isDelayed && m.delayDays > 0 ? '+${m.delayDays}d' : m.contractualStatusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 16, color: _D.mutedLight),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — MATRIZ (orden por proximidad, secciones)
// ═══════════════════════════════════════════════════════════════════════════════
class _MatrizTab extends StatelessWidget {
  const _MatrizTab({required this.milestones, required this.onTap});
  final List<MilestoneRecord> milestones;
  final void Function(MilestoneRecord) onTap;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_view_rounded, size: 44, color: _D.mutedLight),
          SizedBox(height: 12),
          Text('Sin hitos registrados', style: TextStyle(color: _D.muted, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ));
    }

    // Separate into sections: active, pending, completed
    final active    = milestones.where((m) => m.isInProgress || m.isDelayed).toList();
    final pending   = milestones.where((m) => !m.isCompleted && !m.isInProgress && !m.isDelayed).toList();
    final completed = milestones.where((m) => m.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.timelapse_rounded,
            label: 'TRABAJANDO AHORA',
            color: _D.accent,
            count: active.length,
          ),
          const SizedBox(height: 8),
          ...active.map((m) => _MatrizCard(milestone: m, onTap: () => onTap(m), highlight: true)),
          const SizedBox(height: 16),
        ],
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.schedule_rounded,
            label: 'PRÓXIMOS',
            color: _D.muted,
            count: pending.length,
          ),
          const SizedBox(height: 8),
          ...pending.map((m) => _MatrizCard(milestone: m, onTap: () => onTap(m))),
          const SizedBox(height: 16),
        ],
        if (completed.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.check_circle_rounded,
            label: 'COMPLETADOS',
            color: _D.green,
            count: completed.length,
          ),
          const SizedBox(height: 8),
          ...completed.map((m) => _MatrizCard(milestone: m, onTap: () => onTap(m))),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, required this.color, required this.count});
  final IconData icon;
  final String label;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.7)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }
}

class _MatrizCard extends StatelessWidget {
  const _MatrizCard({required this.milestone, required this.onTap, this.highlight = false});
  final MilestoneRecord milestone;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final m          = milestone;
    final color      = _statusColor(m);
    final classColor = _classColor(m.classificationLabel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlight ? color.withValues(alpha: 0.40) : _D.stroke, width: highlight ? 1.5 : 1),
          boxShadow: highlight ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Column(
          children: [
            // ── Top row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 10, 0),
              child: Row(
                children: [
                  // Status circle
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.isCompleted ? color : color.withValues(alpha: 0.10),
                      border: Border.all(color: color, width: highlight ? 2.5 : 2),
                    ),
                    child: Icon(_statusIcon(m), size: 15, color: m.isCompleted ? _D.white : color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(m.code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                            if (highlight && (m.isInProgress || m.isDelayed)) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  m.isDelayed ? 'RETRASADO' : 'EN PROCESO',
                                  style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: _D.white, letterSpacing: 0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          m.description,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _D.text, height: 1.2),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: _D.mutedLight),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Fecha matrix row ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _D.stroke))),
              child: Row(
                children: [
                  _MatrizDateCell(label: 'Contractual', date: m.effectiveContractualDate, color: _D.primary, icon: Icons.gavel_rounded),
                  _MatrizDivider(),
                  _MatrizDateCell(label: 'Meta',        date: m.effectiveTargetDate,      color: _D.accent,  icon: Icons.flag_rounded),
                  _MatrizDivider(),
                  m.actualDate != null
                      ? _MatrizDateCell(label: 'Real', date: m.actualDate, color: _D.green, icon: Icons.check_circle_rounded)
                      : _MatrizEmptyCell(isDelayed: m.isDelayed, delayDays: m.delayDays),
                ],
              ),
            ),

            // ── Tags row ─────────────────────────────────────────────────
            if (m.classificationLabel.isNotEmpty || m.typeLabel.isNotEmpty || m.isPenalizable)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: [
                    if (m.classificationLabel.isNotEmpty)
                      _Tag(label: m.classificationLabel, color: classColor),
                    if (m.typeLabel.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      _Tag(label: m.typeLabel, color: _D.muted, outlined: true),
                    ],
                    if (m.isPenalizable) ...[
                      const SizedBox(width: 5),
                      const _Tag(label: 'Penalizable', color: _D.red, outlined: true),
                    ],
                    const Spacer(),
                    if (m.extensionCount > 0)
                      Row(children: [
                        const Icon(Icons.update_rounded, size: 11, color: _D.yellow),
                        const SizedBox(width: 3),
                        Text('${m.extensionCount} amp.', style: const TextStyle(fontSize: 10, color: _D.yellow, fontWeight: FontWeight.w600)),
                      ]),
                  ],
                ),
              )
            else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _MatrizDateCell extends StatelessWidget {
  const _MatrizDateCell({required this.label, required this.date, required this.color, required this.icon});
  final String label;
  final DateTime? date;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2)),
        ]),
        const SizedBox(height: 3),
        Text(_fmtShort(date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    ),
  );
}

class _MatrizEmptyCell extends StatelessWidget {
  const _MatrizEmptyCell({required this.isDelayed, required this.delayDays});
  final bool isDelayed;
  final int delayDays;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isDelayed ? Icons.warning_amber_rounded : Icons.hourglass_empty_rounded, size: 9, color: isDelayed ? _D.red : _D.mutedLight),
          const SizedBox(width: 3),
          Text('Real', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: isDelayed ? _D.red : _D.mutedLight)),
        ]),
        const SizedBox(height: 3),
        Text(
          isDelayed && delayDays > 0 ? '+${delayDays}d' : '—',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDelayed ? _D.red : _D.mutedLight),
        ),
      ],
    ),
  );
}

class _MatrizDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 30, color: _D.stroke, margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.outlined = false});
  final String label;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: outlined ? Colors.transparent : color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: outlined ? 0.30 : 0)),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// GANTT PANEL — media pantalla, compartido con hv5
// ═══════════════════════════════════════════════════════════════════════════════
class _GanttPanel extends StatelessWidget {
  const _GanttPanel({required this.milestones, required this.onClose});
  final List<MilestoneRecord> milestones;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final active = milestones.where((m) => m.isInProgress || m.isDelayed).isNotEmpty
        ? milestones.firstWhere((m) => m.isInProgress || m.isDelayed)
        : (milestones.isNotEmpty ? milestones.first : null);
    final elapsedDays = active == null
        ? 0
        : DateTime.now().difference(active.effectiveContractualDate).inDays.abs();
    final remainingDays = active == null
        ? 0
        : active.effectiveTargetDate.difference(DateTime.now()).inDays;
    return Container(
      height: screenH * 0.50,
      decoration: BoxDecoration(
        color: _D.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: _D.stroke, borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                const Icon(Icons.bar_chart_rounded, size: 15, color: _D.muted),
                const SizedBox(width: 5),
                const Text('DIAGRAMA DE HITOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _D.muted, letterSpacing: 0.6)),
                const Spacer(),
                GestureDetector(onTap: onClose, child: const Icon(Icons.close_rounded, size: 20, color: _D.muted)),
              ],
            ),
          ),
          Container(height: 1, color: _D.stroke),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _Legend(_D.green,     'Completado'),
                const SizedBox(width: 10),
                _Legend(_D.accent,   'En proceso'),
                const SizedBox(width: 10),
                _Legend(_D.red,      'Retrasado'),
                const SizedBox(width: 10),
                _Legend(_D.mutedLight, 'Pendiente'),
                const Spacer(),
                const Icon(Icons.vertical_align_center_rounded, size: 12, color: _D.red),
                const SizedBox(width: 3),
                const Text('Hoy', style: TextStyle(fontSize: 9, color: _D.red, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (active != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetricChip(label: 'Hito', value: '#${active.order}'),
                  _MetricChip(label: 'Avance', value: '$elapsedDays d'),
                  _MetricChip(
                    label: 'Restantes',
                    value: '${remainingDays < 0 ? 0 : remainingDays} d',
                  ),
                ],
              ),
            ),
          Expanded(
            child: milestones.isEmpty
                ? const Center(child: Text('Sin hitos', style: TextStyle(color: _D.muted)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _GanttChart(milestones: milestones),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 9, color: _D.muted)),
  ]);
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _D.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          color: _D.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Gantt Chart (mismo painter que hv5) ─────────────────────────────────────
class _GanttChart extends StatelessWidget {
  const _GanttChart({required this.milestones});
  final List<MilestoneRecord> milestones;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();
    final first    = milestones.first.effectiveContractualDate;
    final last     = milestones.last.effectiveContractualDate;
    final spanDays = math.max(1, last.difference(first).inDays);
    return LayoutBuilder(
      builder: (_, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _GanttPainter(milestones: milestones, first: first, spanDays: spanDays, now: DateTime.now()),
      ),
    );
  }
}

class _GanttPainter extends CustomPainter {
  const _GanttPainter({required this.milestones, required this.first, required this.spanDays, required this.now});
  final List<MilestoneRecord> milestones;
  final DateTime first;
  final int spanDays;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final trackPaint = Paint()
      ..color = _D.stroke
      ..strokeWidth = 2;
    final trackY = h * 0.55;
    canvas.drawLine(Offset(0, trackY), Offset(w, trackY), trackPaint);

    final lastDate = first.add(Duration(days: spanDays));
    for (var d = DateTime(first.year, first.month, 1);
        !d.isAfter(lastDate);
        d = DateTime(d.year, d.month + 1, 1)) {
      final x = _x(d, w);
      canvas.drawLine(
        Offset(x, trackY - 52),
        Offset(x, trackY + 52),
        Paint()
          ..color = _D.stroke.withValues(alpha: 0.7)
          ..strokeWidth = 1,
      );
      final monthTp = TextPainter(
        text: TextSpan(
          text: _monthLabel(d),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: _D.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 48);
      monthTp.paint(
        canvas,
        Offset((x - monthTp.width / 2).clamp(0.0, w - monthTp.width), 6),
      );
    }

    MilestoneRecord? lastDone;
    for (final m in milestones) {
      if (m.isCompleted) {
        lastDone = m;
      }
    }
    if (lastDone != null) {
      canvas.drawLine(
        Offset(0, trackY),
        Offset(_x(lastDone.effectiveContractualDate, w), trackY),
        Paint()
          ..color = _D.green.withValues(alpha: 0.28)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    _vMarker(
      canvas,
      0,
      trackY,
      size,
      _D.primary.withValues(alpha: 0.5),
      'INICIO',
      above: true,
    );
    _vMarker(canvas, w, trackY, size, _D.mutedLight, 'FIN', above: true);

    if (now.isAfter(first) &&
        now.isBefore(first.add(Duration(days: spanDays + 1)))) {
      _vMarker(canvas, _x(now, w), trackY, size, _D.red, 'HOY', above: false);
    }

    for (int i = 0; i < milestones.length; i++) {
      final m = milestones[i];
      final mx = _x(m.effectiveContractualDate, w);
      final color = m.isCompleted
          ? _D.green
          : m.isDelayed
              ? _D.red
              : m.isInProgress
                  ? _D.accent
                  : _D.mutedLight;
      final r = (m.isInProgress || m.isDelayed) ? 8.0 : 6.0;

      canvas.drawCircle(Offset(mx, trackY), r, Paint()..color = color);
      if (!m.isCompleted) {
        canvas.drawCircle(Offset(mx, trackY), r - 2.5, Paint()..color = _D.white);
      }

      final labelY = i.isEven ? trackY - r - 22 : trackY + r + 14;
      final lbl = m.code.isNotEmpty ? m.code.replaceFirst('HT-', '') : '${m.order}';
      final tp = TextPainter(
        text: TextSpan(
          text: lbl,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mx - tp.width / 2, labelY));

      final shortDesc = m.description.length > 16
          ? '${m.description.substring(0, 16)}…'
          : m.description;
      final descTp = TextPainter(
        text: TextSpan(
          text: shortDesc,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: _D.text,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 86);
      final descY = i.isEven ? labelY - 12 : labelY + 10;
      descTp.paint(
        canvas,
        Offset((mx - descTp.width / 2).clamp(0.0, w - descTp.width), descY),
      );

      canvas.drawLine(
        Offset(mx, trackY - r),
        Offset(mx, i.isEven ? trackY - r - 14 : trackY + r),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );
    }
  }

  double _x(DateTime d, double w) => (d.difference(first).inDays / spanDays * w).clamp(0.0, w);

  String _monthLabel(DateTime d) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[d.month - 1];
  }

  void _vMarker(Canvas canvas, double x, double trackY, Size size, Color color, String label, {required bool above}) {
    canvas.drawLine(Offset(x, trackY - 12), Offset(x, trackY + 12), Paint()..color = color..strokeWidth = 1.5);
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    final lx = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
    tp.paint(canvas, Offset(lx, above ? trackY - 26 : trackY + 14));
  }

  @override
  bool shouldRepaint(_GanttPainter o) => true;
}
