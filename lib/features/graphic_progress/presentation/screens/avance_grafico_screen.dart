import 'package:flutter/material.dart';

import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE0EAF6);
  static const primary = Color(0xFF0A66B7);
  static const primaryDark = Color(0xFF0852A3);
  static const accentLight = Color(0xFFDCEAFB);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
  static const green = Color(0xFF10B981);
  static const yellow = Color(0xFFF59E0B);
}

class AvanceGraficoScreen extends StatefulWidget {
  const AvanceGraficoScreen({super.key});

  @override
  State<AvanceGraficoScreen> createState() => _AvanceGraficoScreenState();
}

class _AvanceGraficoScreenState extends State<AvanceGraficoScreen> {
  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      AppScope.of(context).ensureAvanceGraficoDemoData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final project = controller.currentProject;
        final data = controller.avanceGraficoData;

        if (project == null) {
          return const Scaffold(
            backgroundColor: _D.bg,
            body: Center(child: CircularProgressIndicator(color: _D.primary)),
          );
        }

        if (data == null) {
          return Scaffold(
            backgroundColor: _D.bg,
            appBar: _buildAppBar(project.name, null),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _D.accentLight,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: _D.primary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Avance Grafico aun no tiene datos en este proyecto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _D.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: _D.muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: _buildAppBar(project.name, data),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeroCard(projectName: project.name, data: data),
              const SizedBox(height: 16),
              _PhaseSelector(
                index: _phaseIndex,
                onChanged: (value) => setState(() => _phaseIndex = value),
              ),
              const SizedBox(height: 16),
              if (_phaseIndex == 0 && data.phase1 != null)
                _Phase1View(
                  data: data.phase1!,
                  controller: controller,
                )
              else if (_phaseIndex == 1 && data.phase2 != null)
                _Phase2View(data: data.phase2!)
              else if (_phaseIndex == 2 && data.phase3 != null)
                _Phase3View(data: data.phase3!)
              else
                const _EmptyPhaseCard(),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String projectName, AvanceGraficoData? data) {
    final summary = data?.summary;
    final overall = summary == null
        ? null
        : (((summary.phase1Completion +
                        summary.phase2Completion +
                        summary.phase3Completion) /
                    3) *
                100)
            .round();
    return AppBar(
      backgroundColor: _D.surface,
      foregroundColor: _D.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Avance Grafico',
            style: TextStyle(
              fontSize: 10,
              color: _D.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            projectName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _D.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        if (overall != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _D.accentLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _D.stroke),
            ),
            child: Text(
              '$overall% General',
              style: const TextStyle(
                color: _D.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _D.stroke),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.projectName, required this.data});

  final String projectName;
  final AvanceGraficoData data;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final viewLabel = summary.selectedView == 1
        ? 'Vista por aprobados / calidad'
        : 'Vista por completados';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_D.primary, _D.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0A66B7),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control visual en obra',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      projectName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _TopPill(
                icon: summary.isActive
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                label: summary.isActive ? 'Activo' : 'Inactivo',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            viewLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Integrantes con acceso',
                  value: '${summary.enabledMembers}/${summary.totalMembers}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Promedio visual',
                  value:
                      '${(((summary.phase1Completion + summary.phase2Completion + summary.phase3Completion) / 3) * 100).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PhaseProgressRow(summary: summary),
        ],
      ),
    );
  }
}

class _PhaseSelector extends StatelessWidget {
  const _PhaseSelector({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = ['Fase 1', 'Fase 2', 'Fase 3'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.stroke),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? _D.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : _D.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Phase1View extends StatelessWidget {
  const _Phase1View({
    required this.data,
    required this.controller,
  });

  final AvanceGraficoPhase1Data data;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final grouped = _Phase1Groups.from(data.sections);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;
        final graphicCard = _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grid_view_rounded,
                        color: _D.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Manejador grafico',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _D.text,
                        ),
                      ),
                    ],
                  ),
                  _Tag(label: data.shapeLabel),
                  _Tag(label: data.directionLabel),
                ],
              ),
              const SizedBox(height: 18),
              _Phase1GraphicManager(
                data: data,
                groups: grouped,
                onCellTap: (cell) =>
                    controller.cycleAvanceGraficoPhase1PositionStatus(cell.id),
                onDeleteSection: (sectionId) =>
                    controller.deleteAvanceGraficoPhase1Section(sectionId),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: data.title,
              subtitle: 'Manejador grafico de lados, niveles y panos',
            ),
            const SizedBox(height: 12),
            _Phase1Toolbar(
              onAddSection: () =>
                  _showAddPhase1SectionDialog(context, controller),
            ),
            const SizedBox(height: 12),
            if (isCompact) ...[
              graphicCard,
              const SizedBox(height: 12),
              _Phase1Sidebar(data: data),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: graphicCard),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: _Phase1Sidebar(data: data),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _NarrativeCard(
              title: 'Configuracion base',
              icon: Icons.route_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(label: '${data.sections.length} secciones activas'),
                  _Tag(label: '${data.notApplicablePositions} no aplica'),
                  _Tag(label: '${data.documentsCount} documentos'),
                  _Tag(label: '${data.completedPositions} listas'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _NarrativeCard(
              title: 'Comentario operativo',
              icon: Icons.notes_rounded,
              child: Text(
                data.comments.isEmpty
                    ? 'Sin comentarios registrados.'
                    : data.comments,
                style:
                    const TextStyle(fontSize: 13, color: _D.text, height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            _Phase1SectionTable(
              sections: data.sections,
              onCellTap: (cell) =>
                  controller.cycleAvanceGraficoPhase1PositionStatus(cell.id),
              onDeleteSection: (sectionId) =>
                  controller.deleteAvanceGraficoPhase1Section(sectionId),
            ),
          ],
        );
      },
    );
  }
}

class _Phase1Toolbar extends StatelessWidget {
  const _Phase1Toolbar({required this.onAddSection});

  final VoidCallback onAddSection;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ModeChip(
          icon: Icons.grid_view_rounded,
          label: 'Manejador Grafico',
          active: true,
        ),
        const _ModeChip(
          icon: Icons.table_chart_rounded,
          label: 'Formato Tabla',
        ),
        const _ModeChip(
          icon: Icons.edit_rounded,
          label: 'Edicion',
        ),
        const _ModeChip(
          icon: Icons.ads_click_rounded,
          label: 'Seleccion',
        ),
        _ActionChip(
          icon: Icons.add_circle_outline_rounded,
          label: 'Agregar Seccion',
          onTap: onAddSection,
        ),
      ],
    );
  }
}

class _Phase1Sidebar extends StatelessWidget {
  const _Phase1Sidebar({required this.data});

  final AvanceGraficoPhase1Data data;

  @override
  Widget build(BuildContext context) {
    final progress = data.totalPositions == 0
        ? 0.0
        : data.completedPositions / data.totalPositions;
    final levelItems = _buildLevelProgress(data.sections);
    return Column(
      children: [
        _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Avance Fase 1',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: _D.stroke,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_D.primary),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _D.text,
                            ),
                          ),
                          const Text(
                            'Completado',
                            style: TextStyle(fontSize: 11, color: _D.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SidebarMetric(
                      value: '${data.completedPositions}',
                      label: 'LISTOS',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SidebarMetric(
                      value: '${data.totalPositions}',
                      label: 'TOTAL',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SidebarMetric(
                      value: '${levelItems.length}',
                      label: 'NIVELES',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Niveles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
              const SizedBox(height: 10),
              ...levelItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Nivel ${item.level}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _D.text,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(item.progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _D.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.completed}/${item.total}',
                        style: const TextStyle(fontSize: 11, color: _D.muted),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 6,
                          backgroundColor: _D.stroke,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _D.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Phase1GraphicManager extends StatelessWidget {
  const _Phase1GraphicManager({
    required this.data,
    required this.groups,
    required this.onCellTap,
    required this.onDeleteSection,
  });

  final AvanceGraficoPhase1Data data;
  final _Phase1Groups groups;
  final ValueChanged<AvanceGraficoPhase1Cell> onCellTap;
  final ValueChanged<int> onDeleteSection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 860,
        child: Column(
          children: [
            if (groups.top.isNotEmpty)
              _Phase1SectionStrip(
                label: 'Superior',
                sections: groups.top,
                axis: Axis.horizontal,
                onCellTap: onCellTap,
                onDeleteSection: onDeleteSection,
              ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: groups.left.isEmpty
                      ? const SizedBox.shrink()
                      : _Phase1SectionStrip(
                          label: 'Izquierda',
                          sections: groups.left,
                          axis: Axis.vertical,
                          onCellTap: onCellTap,
                          onDeleteSection: onDeleteSection,
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _Phase1CenterBadge(data: data),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: groups.right.isEmpty
                      ? const SizedBox.shrink()
                      : _Phase1SectionStrip(
                          label: 'Derecha',
                          sections: groups.right,
                          axis: Axis.vertical,
                          onCellTap: onCellTap,
                          onDeleteSection: onDeleteSection,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (groups.bottom.isNotEmpty)
              _Phase1SectionStrip(
                label: 'Inferior',
                sections: groups.bottom,
                axis: Axis.horizontal,
                onCellTap: onCellTap,
                onDeleteSection: onDeleteSection,
              ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _LegendItem(label: 'Pendiente', color: Color(0xFFBEBEB9)),
                _LegendItem(label: 'Completado', color: Color(0xFF6ECC77)),
                _LegendItem(label: 'Programado sem. actual', color: Color(0xFF0190DC)),
                _LegendItem(label: 'No Aplica', color: Color(0xFF111827)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Phase1SectionStrip extends StatelessWidget {
  const _Phase1SectionStrip({
    required this.label,
    required this.sections,
    required this.axis,
    required this.onCellTap,
    required this.onDeleteSection,
  });

  final String label;
  final List<AvanceGraficoPhase1Section> sections;
  final Axis axis;
  final ValueChanged<AvanceGraficoPhase1Cell> onCellTap;
  final ValueChanged<int> onDeleteSection;

  @override
  Widget build(BuildContext context) {
    final children = sections
        .map(
          (section) => _Phase1GraphicSectionCard(
            section: section,
            onCellTap: onCellTap,
            onDelete: () => onDeleteSection(section.id),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: _D.muted,
          ),
        ),
        const SizedBox(height: 8),
        axis == Axis.horizontal
            ? Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: children,
              )
            : Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const SizedBox(height: 14),
                  ],
                ],
              ),
      ],
    );
  }
}

class _Phase1GraphicSectionCard extends StatelessWidget {
  const _Phase1GraphicSectionCard({
    required this.section,
    required this.onCellTap,
    required this.onDelete,
  });

  final AvanceGraficoPhase1Section section;
  final ValueChanged<AvanceGraficoPhase1Cell> onCellTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                section.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: _D.mutedLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: _buildRows(section),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRows(AvanceGraficoPhase1Section section) {
    final byLevel = <int, List<AvanceGraficoPhase1Cell>>{};
    for (final cell in section.cells) {
      byLevel.putIfAbsent(cell.level, () => []).add(cell);
    }
    final levels = byLevel.keys.toList()..sort((a, b) => b.compareTo(a));
    return levels
        .map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: (byLevel[level]!..sort((a, b) => a.bay.compareTo(b.bay)))
                  .map(
                    (cell) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _Phase1CellTile(
                        cell: cell,
                        onTap: () => onCellTap(cell),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        )
        .toList();
  }
}

class _Phase1CellTile extends StatelessWidget {
  const _Phase1CellTile({required this.cell, required this.onTap});

  final AvanceGraficoPhase1Cell cell;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _hex(cell.colorHex);
    final dark = cell.statusCode == 4;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${cell.level}.${cell.bay}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : _D.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _Phase1CenterBadge extends StatelessWidget {
  const _Phase1CenterBadge({required this.data});

  final AvanceGraficoPhase1Data data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: _D.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220A66B7),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'FASE 1',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${data.completedPositions} / ${data.totalPositions}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.directionLabel} · ${data.shapeLabel}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Phase1SectionTable extends StatelessWidget {
  const _Phase1SectionTable({
    required this.sections,
    required this.onCellTap,
    required this.onDeleteSection,
  });

  final List<AvanceGraficoPhase1Section> sections;
  final ValueChanged<AvanceGraficoPhase1Cell> onCellTap;
  final ValueChanged<int> onDeleteSection;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Secciones',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _D.text,
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Phase1SectionCard(
                section: section,
                onCellTap: onCellTap,
                onDeleteSection: onDeleteSection,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMetric extends StatelessWidget {
  const _SidebarMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _D.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _D.muted),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _D.muted),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? _D.primary : _D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? _D.primary : _D.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: active ? Colors.white : _D.muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : _D.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A00),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Agregar Seccion',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelProgressItem {
  const _LevelProgressItem({
    required this.level,
    required this.completed,
    required this.total,
  });

  final int level;
  final int completed;
  final int total;

  double get progress => total == 0 ? 0 : completed / total;
}

class _Phase1Groups {
  const _Phase1Groups({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  final List<AvanceGraficoPhase1Section> top;
  final List<AvanceGraficoPhase1Section> bottom;
  final List<AvanceGraficoPhase1Section> left;
  final List<AvanceGraficoPhase1Section> right;

  factory _Phase1Groups.from(List<AvanceGraficoPhase1Section> sections) {
    final top = <AvanceGraficoPhase1Section>[];
    final bottom = <AvanceGraficoPhase1Section>[];
    final left = <AvanceGraficoPhase1Section>[];
    final right = <AvanceGraficoPhase1Section>[];
    for (final section in sections) {
      final side = section.sideLabel.toLowerCase();
      if (side.contains('super')) {
        top.add(section);
      } else if (side.contains('infer')) {
        bottom.add(section);
      } else if (side.contains('izq')) {
        left.add(section);
      } else if (side.contains('der')) {
        right.add(section);
      } else {
        top.add(section);
      }
    }
    return _Phase1Groups(top: top, bottom: bottom, left: left, right: right);
  }
}

List<_LevelProgressItem> _buildLevelProgress(
  List<AvanceGraficoPhase1Section> sections,
) {
  final counts = <int, List<int>>{};
  for (final section in sections) {
    for (final cell in section.cells) {
      if (cell.statusCode == 4) {
        continue;
      }
      final bucket = counts.putIfAbsent(cell.level, () => [0, 0]);
      bucket[1]++;
      if (cell.statusCode == 2) {
        bucket[0]++;
      }
    }
  }
  final levels = counts.keys.toList()..sort();
  return levels
      .map(
        (level) => _LevelProgressItem(
          level: level,
          completed: counts[level]![0],
          total: counts[level]![1],
        ),
      )
      .toList();
}

Future<void> _showAddPhase1SectionDialog(
  BuildContext context,
  AppController controller,
) async {
  final nameCtrl = TextEditingController();
  final abbrCtrl = TextEditingController();
  int sideCode = 1;
  int levels = 3;
  int bays = 4;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Agregar Seccion'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: abbrCtrl,
                    decoration: const InputDecoration(labelText: 'Abreviatura'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: sideCode,
                    decoration: const InputDecoration(labelText: 'Lado'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Superior')),
                      DropdownMenuItem(value: 2, child: Text('Inferior')),
                      DropdownMenuItem(value: 3, child: Text('Izquierda')),
                      DropdownMenuItem(value: 4, child: Text('Derecha')),
                    ],
                    onChanged: (value) => setState(() => sideCode = value ?? 1),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: levels,
                          decoration: const InputDecoration(labelText: 'Niveles'),
                          items: List.generate(
                            6,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => levels = value ?? 3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: bays,
                          decoration: const InputDecoration(labelText: 'Panos'),
                          items: List.generate(
                            8,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => bays = value ?? 4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final abbr = abbrCtrl.text.trim();
                  if (name.isEmpty || abbr.isEmpty) {
                    return;
                  }
                  await controller.addAvanceGraficoPhase1Section(
                    name: name,
                    abbreviation: abbr,
                    sideCode: sideCode,
                    levels: levels,
                    bays: bays,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _Phase2View extends StatelessWidget {
  const _Phase2View({required this.data});

  final AvanceGraficoPhase2Data data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: data.title,
          subtitle: 'Control matricial por pisos y sectores',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Matriz total',
                value: '${data.totalCells}',
                caption: 'celdas validas',
                color: _D.primary,
                icon: Icons.grid_on_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Completado',
                value: '${data.completedCount}',
                caption: 'terminadas',
                color: _D.green,
                icon: Icons.task_alt_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Calidad',
                value: '${data.approvedCount}',
                caption: 'aprobadas',
                color: const Color(0xFF0B7A43),
                icon: Icons.verified_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NarrativeCard(
          title: 'Regla de pisos',
          icon: Icons.layers_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                label: data.uniformFloorsEnabled
                    ? 'Pisos uniformes activos'
                    : 'Pisos variables por actividad',
              ),
              if (data.uniformFloorsEnabled)
                _Tag(label: '${data.uniformFloorsCount} pisos referencia'),
              _Tag(label: '${data.documentsCount} evidencias fase 2'),
              _Tag(label: '${data.pendingCount} pendientes'),
              _Tag(label: '${data.inProgressCount} en proceso'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _NarrativeCard(
          title: 'Comentario operativo',
          icon: Icons.notes_rounded,
          child: Text(
            data.comments.isEmpty ? 'Sin comentarios registrados.' : data.comments,
            style: const TextStyle(fontSize: 13, color: _D.text, height: 1.45),
          ),
        ),
        const SizedBox(height: 12),
        ...data.activities.map(
          (activity) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Phase2ActivityCard(activity: activity),
          ),
        ),
      ],
    );
  }
}

class _Phase3View extends StatelessWidget {
  const _Phase3View({required this.data});

  final AvanceGraficoPhase3Data data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: data.title,
          subtitle: 'Detalle por piso, sector y actividad',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Pisos',
                value: '${data.floorCount}',
                caption: 'con plano o lectura',
                color: _D.primary,
                icon: Icons.apartment_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Sectores',
                value: '${data.sectorCount}',
                caption: 'mapeados',
                color: _D.yellow,
                icon: Icons.select_all_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Actividades',
                value: '${data.activityCount}',
                caption: 'cruzadas',
                color: _D.green,
                icon: Icons.view_in_ar_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NarrativeCard(
          title: 'Estado agregado',
          icon: Icons.auto_graph_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: '${data.completedCount} completadas'),
              _Tag(label: '${data.approvedCount} aprobadas'),
              _Tag(label: '${data.inProgressCount} en proceso'),
              _Tag(label: '${data.pendingCount} pendientes'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _NarrativeCard(
          title: 'Comentario operativo',
          icon: Icons.notes_rounded,
          child: Text(
            data.comments.isEmpty ? 'Sin comentarios registrados.' : data.comments,
            style: const TextStyle(fontSize: 13, color: _D.text, height: 1.45),
          ),
        ),
        const SizedBox(height: 12),
        ...data.floors.map(
          (floor) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Phase3FloorCard(floor: floor),
          ),
        ),
      ],
    );
  }
}

class _Phase1SectionCard extends StatelessWidget {
  const _Phase1SectionCard({
    required this.section,
    required this.onCellTap,
    required this.onDeleteSection,
  });

  final AvanceGraficoPhase1Section section;
  final ValueChanged<AvanceGraficoPhase1Cell> onCellTap;
  final ValueChanged<int> onDeleteSection;

  @override
  Widget build(BuildContext context) {
    final percent = section.totalCount == 0
        ? 0.0
        : section.completedCount / section.totalCount;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _D.accentLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  section.sideLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _D.primary,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => onDeleteSection(section.id),
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: _D.mutedLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  color: _D.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.name,
            style: const TextStyle(
              color: _D.text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${section.levels} niveles · ${section.bays} panos · ${section.completedCount}/${section.totalCount}',
            style: const TextStyle(color: _D.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: section.cells
                .map(
                  (cell) => _Phase1CellTile(
                    cell: cell,
                    onTap: () => onCellTap(cell),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Phase2ActivityCard extends StatelessWidget {
  const _Phase2ActivityCard({required this.activity});

  final AvanceGraficoPhase2Activity activity;

  @override
  Widget build(BuildContext context) {
    final progress = activity.totalCells == 0
        ? 0.0
        : (activity.completedCount + activity.approvedCount) / activity.totalCells;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _D.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity.abbreviation.isEmpty ? 'AG' : activity.abbreviation,
                  style: const TextStyle(
                    color: _D.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        color: _D.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${activity.floors} pisos · ${activity.basements} sotanos · ${activity.sectors} sectores',
                      style: const TextStyle(color: _D.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _D.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _D.stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(_D.primary),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: '${activity.pendingCount} pendientes'),
              _Tag(label: '${activity.inProgressCount} en proceso'),
              _Tag(label: '${activity.completedCount} completadas'),
              _Tag(label: '${activity.approvedCount} aprobadas'),
            ],
          ),
          const SizedBox(height: 12),
          _MiniGrid(
            colors: activity.cells.map((cell) => _hex(cell.colorHex)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Phase3FloorCard extends StatelessWidget {
  const _Phase3FloorCard({required this.floor});

  final AvanceGraficoPhase3Floor floor;

  @override
  Widget build(BuildContext context) {
    final progress = floor.totalCells == 0
        ? 0.0
        : (floor.completedCount + floor.approvedCount) / floor.totalCells;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _D.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  floor.abbreviation.isEmpty ? floor.name : floor.abbreviation,
                  style: const TextStyle(
                    color: _D.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floor.name,
                      style: const TextStyle(
                        color: _D.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      floor.planName ?? 'Sin plano cargado',
                      style: const TextStyle(color: _D.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _D.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _D.stroke,
              valueColor: const AlwaysStoppedAnimation<Color>(_D.primary),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: '${floor.activitiesCount} actividades'),
              _Tag(label: '${floor.completedCount} completadas'),
              _Tag(label: '${floor.approvedCount} aprobadas'),
              _Tag(label: '${floor.inProgressCount} en proceso'),
            ],
          ),
          const SizedBox(height: 12),
          ...floor.sectors.map(
            (sector) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sector.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _D.text,
                          ),
                        ),
                        Text(
                          '${sector.stateLabel} · ${(sector.completedPercent * 100).round()}% completo · ${(sector.approvedPercent * 100).round()}% calidad',
                          style: const TextStyle(fontSize: 11, color: _D.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 84,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: sector.completedPercent,
                        minHeight: 8,
                        backgroundColor: _D.stroke,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_D.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _D.text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _D.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _D.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _D.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            caption,
            style: const TextStyle(color: _D.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _D.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _D.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _D.stroke),
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _D.stroke),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _D.muted,
        ),
      ),
    );
  }
}

class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final preview = colors.take(18).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: preview
          .map(
            (color) => Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PhaseProgressRow extends StatelessWidget {
  const _PhaseProgressRow({required this.summary});

  final AvanceGraficoSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProgressPill(
            label: 'F1',
            value: summary.phase1Completion,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ProgressPill(
            label: 'F2',
            value: summary.phase2Completion,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ProgressPill(
            label: 'F3',
            value: summary.phase3Completion,
          ),
        ),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhaseCard extends StatelessWidget {
  const _EmptyPhaseCard();

  @override
  Widget build(BuildContext context) {
    return const _CardShell(
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: _D.mutedLight, size: 30),
          SizedBox(height: 10),
          Text(
            'No hay configuracion cargada para esta fase.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _D.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Color _hex(String value) {
  final cleaned = value.replaceAll('#', '').trim();
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(normalized, radix: 16) ?? 0xFF94A3B8);
}
