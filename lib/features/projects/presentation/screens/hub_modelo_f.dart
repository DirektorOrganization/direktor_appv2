// ============================================================
// MODELO F — "EJECUTIVO"
// Vista gerencial — limpia, completa, directiva.
// Diseñado para directores/gerentes. Board-room quality,
// datos ricos, tipografía precisa, confianza corporativa.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
const _bg = Color(0xFFF8FAFD);
const _surface = Colors.white;
const _blue = Color(0xFF0A66B7);
// ignore: unused_element
const _blueDark = Color(0xFF084C8D);
const _orange = Color(0xFFF5A623);
const _red = Color(0xFFD64545);
const _green = Color(0xFF1B8E5A);
const _yellow = Color(0xFFE4A620);
const _text = Color(0xFF1E2B3A);
const _muted = Color(0xFF62748A);
const _stroke = Color(0xFFDDE4EF);

// ── Screen ───────────────────────────────────────────────────
class HubModeloF extends StatelessWidget {
  const HubModeloF({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(child: CircularProgressIndicator(color: _blue)),
          );
        }

        final summary = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones = controller.milestoneSummary;
        final milestoneList = controller.milestones;
        final sync = controller.syncOverview;
        final projects = controller.projects;

        final overdueCount =
            restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount =
            restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pendingCount = restrictions.where((r) => r.isPending).length;
        final completedCount = summary.completed;
        final compliancePct = summary.compliancePercent;

        final completed3 = controller.completedRestrictions.take(3).toList();

        return Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              // ── Top bar ────────────────────────────────────
              _TopBar(
                user: user,
                onMenuSelected: (v) async {
                  if (v == 'logout') {
                    await controller.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                        context, RouteNames.login, (_) => false);
                  } else if (v == 'profile') {
                    if (!context.mounted) return;
                    Navigator.pushNamed(context, RouteNames.profile);
                  } else if (v == 'styles') {
                    if (!context.mounted) return;
                    await showStylePicker(context);
                  }
                },
              ),
              // ── Project selector ───────────────────────────
              _ProjectSelectorBar(
                projects: projects,
                current: project,
                onSelect: (p) => controller.changeProject(p.id),
              ),
              // ── Body scroll ────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Hero compliance card ───────────────
                      _ComplianceCard(
                        compliancePct: compliancePct,
                        overdueCount: overdueCount,
                        inProgressCount: inProgressCount,
                        pendingCount: pendingCount,
                        completedCount: completedCount,
                        onAnalysis: () => Navigator.pushNamed(
                            context, RouteNames.restrictionsList),
                      ),
                      const SizedBox(height: 14),
                      // ── Two summary cards ──────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _HitosSummaryCard(
                              delayedCount: milestones.delayedCount,
                              accumulatedPenalty:
                                  milestones.accumulatedPenalty,
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.controlHitos),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActasSummaryCard(
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.actaReuniones),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ── Milestone timeline ─────────────────
                      _MilestoneTimelineSection(
                        milestones: milestoneList,
                        onVerTodos: () => Navigator.pushNamed(
                            context, RouteNames.controlHitos),
                      ),
                      const SizedBox(height: 20),
                      // ── Recent activity ────────────────────
                      _RecentActivitySection(
                        completed: completed3,
                        onVerTodos: () => Navigator.pushNamed(
                            context, RouteNames.completedRestrictions),
                      ),
                      const SizedBox(height: 20),
                      // ── Penalidad risk ─────────────────────
                      _PenalidadCard(
                        accumulated: milestones.accumulatedPenalty,
                        potential: milestones.potentialPenalty,
                        activeExtensions: milestones.activeExtensions,
                      ),
                      const SizedBox(height: 20),
                      // ── Sync footer ────────────────────────
                      _SyncFooter(
                        sync: sync,
                        onSync: controller.syncNow,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.user, required this.onMenuSelected});

  final UserProfile user;
  final void Function(String) onMenuSelected;

  String _todayLabel() {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final mon = months[now.month - 1];
    final yr = now.year;
    return '$day $mon $yr';
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return SafeArea(
      bottom: false,
      child: Container(
        color: _surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const DirektorLogo(size: 30),
                const SizedBox(width: 8),
                const Text(
                  'DIREKTOR',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  _todayLabel(),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  onSelected: onMenuSelected,
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 18, color: _text),
                          SizedBox(width: 10),
                          Text('Perfil', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'styles',
                      child: Row(
                        children: [
                          Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                          SizedBox(width: 8),
                          Text('Cambiar Estilo', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 18, color: _red),
                          SizedBox(width: 10),
                          Text('Cerrar sesión',
                              style: TextStyle(fontSize: 14, color: _red)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ── Project Selector Bar ──────────────────────────────────────
class _ProjectSelectorBar extends StatelessWidget {
  const _ProjectSelectorBar({
    required this.projects,
    required this.current,
    required this.onSelect,
  });

  final List<ProjectRecord> projects;
  final ProjectRecord current;
  final void Function(ProjectRecord) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF3FA),
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = projects[i];
          final selected = p.id == current.id;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? _blue : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _blue : _stroke,
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                p.name,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Hero Compliance Card ──────────────────────────────────────
class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({
    required this.compliancePct,
    required this.overdueCount,
    required this.inProgressCount,
    required this.pendingCount,
    required this.completedCount,
    required this.onAnalysis,
  });

  final double compliancePct;
  final int overdueCount;
  final int inProgressCount;
  final int pendingCount;
  final int completedCount;
  final VoidCallback onAnalysis;

  Color get _ringColor {
    if (compliancePct >= 0.70) return _green;
    if (compliancePct >= 0.40) return _yellow;
    return _red;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (compliancePct * 100).round();
    final ringColor = _ringColor;
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _stroke, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Ring chart
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _RingPainter(
                    value: compliancePct.clamp(0.0, 1.0),
                    trackColor: _stroke,
                    progressColor: ringColor,
                    strokeWidth: 18,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: ringColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const Text(
                          'cumplimiento',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Metric rows
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricRow(
                      dotColor: _red,
                      label: 'Retrasadas',
                      value: '$overdueCount',
                    ),
                    const SizedBox(height: 10),
                    _MetricRow(
                      dotColor: _yellow,
                      label: 'En proceso',
                      value: '$inProgressCount',
                    ),
                    const SizedBox(height: 10),
                    _MetricRow(
                      dotColor: _muted,
                      label: 'Pendientes',
                      value: '$pendingCount',
                    ),
                    const SizedBox(height: 10),
                    _MetricRow(
                      dotColor: _green,
                      label: 'Finalizadas',
                      value: '$completedCount',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _stroke, thickness: 1, height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Análisis de restricciones',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              FilledButton(
                onPressed: onAnalysis,
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Ver análisis →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  final Color dotColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Hitos Summary Card ────────────────────────────────────────
class _HitosSummaryCard extends StatelessWidget {
  const _HitosSummaryCard({
    required this.delayedCount,
    required this.accumulatedPenalty,
    required this.onTap,
  });

  final int delayedCount;
  final double accumulatedPenalty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final valueColor = delayedCount > 0 ? _red : _green;
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _stroke, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, color: _blue, size: 22),
          const SizedBox(height: 10),
          Text(
            '$delayedCount',
            style: TextStyle(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'hitos vencidos',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (accumulatedPenalty > 0)
            Text(
              'S/ ${accumulatedPenalty.toStringAsFixed(0)} penalidad',
              style: const TextStyle(
                color: _red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Ver →',
              style: TextStyle(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actas Summary Card ────────────────────────────────────────
class _ActasSummaryCard extends StatelessWidget {
  const _ActasSummaryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _stroke, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.groups_rounded, color: _orange, size: 22),
          const SizedBox(height: 10),
          const Text(
            '—',
            style: TextStyle(
              color: _text,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'acuerdos activos',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Option 9 panel',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'Abrir →',
              style: TextStyle(
                color: _orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Milestone Timeline Section ────────────────────────────────
class _MilestoneTimelineSection extends StatelessWidget {
  const _MilestoneTimelineSection({
    required this.milestones,
    required this.onVerTodos,
  });

  final List<MilestoneRecord> milestones;
  final VoidCallback onVerTodos;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hitos del proyecto',
              style: TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: onVerTodos,
              child: const Text(
                'Ver todos →',
                style: TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (milestones.isEmpty)
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _stroke, width: 1.2),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Sin hitos registrados',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
          )
        else
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _MilestoneCard(m: milestones[i]),
            ),
          ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.m});

  final MilestoneRecord m;

  Color get _borderColor {
    if (m.isCompleted) return _green;
    if (m.isDelayed) return _red;
    return _yellow;
  }

  Color get _badgeColor {
    if (m.isCompleted) return _green;
    if (m.isDelayed) return _red;
    return _yellow;
  }

  String get _badgeLabel {
    if (m.isCompleted) return 'OK';
    if (m.isDelayed) return 'Retrasado';
    return 'En curso';
  }

  String _fmtDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day/$mon/${d.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _stroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: _borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _badgeLabel,
                      style: TextStyle(
                        color: _badgeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtDate(m.effectiveContractualDate),
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
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

// ── Recent Activity Section ───────────────────────────────────
class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.completed,
    required this.onVerTodos,
  });

  final List<RestrictionRecord> completed;
  final VoidCallback onVerTodos;

  String _fmtDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final mon = d.month.toString().padLeft(2, '0');
    return '$day/$mon';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _stroke, width: 1.2),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cierres recientes',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (completed.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Sin cierres recientes',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            )
          else
            ...completed.map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: _green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.activity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (r.front.isNotEmpty)
                                _TagChip(r.front, _blue),
                              if (r.phase.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                _TagChip(r.phase, _muted),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fmtDate(
                          r.conciliatedDate ?? r.requiredDate),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: _stroke, height: 1, thickness: 1),
          TextButton(
            onPressed: onVerTodos,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 8),
              foregroundColor: _blue,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Ver todos los cierres →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Penalidad Risk Card ───────────────────────────────────────
class _PenalidadCard extends StatelessWidget {
  const _PenalidadCard({
    required this.accumulated,
    required this.potential,
    required this.activeExtensions,
  });

  final double accumulated;
  final double potential;
  final int activeExtensions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _stroke, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Riesgo de penalidad',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _RiskRow(
            label: 'Penalidad acumulada',
            value: 'S/ ${accumulated.toStringAsFixed(0)}',
            valueColor: _red,
          ),
          const SizedBox(height: 8),
          _RiskRow(
            label: 'Penalidad potencial',
            value: 'S/ ${potential.toStringAsFixed(0)}',
            valueColor: _red.withValues(alpha: 0.70),
          ),
          const SizedBox(height: 8),
          _RiskRow(
            label: 'Ampliaciones activas',
            value: '$activeExtensions',
            valueColor: _blue,
          ),
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Sync Footer ───────────────────────────────────────────────
class _SyncFooter extends StatelessWidget {
  const _SyncFooter({required this.sync, required this.onSync});

  final SyncOverview sync;
  final Future<void> Function() onSync;

  String _fmtTs(DateTime? dt) {
    if (dt == null) return 'Nunca';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final pending = sync.pendingCount;
    final icon = sync.isSyncing
        ? Icons.sync_rounded
        : (sync.hasNetwork ? Icons.cloud_done_rounded : Icons.cloud_off_rounded);
    final iconColor = sync.isSyncing
        ? _blue
        : (sync.hasNetwork ? _green : _muted);

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            sync.isSyncing
                ? 'Sincronizando...'
                : pending > 0
                    ? '$pending cambio${pending == 1 ? '' : 's'} pendiente${pending == 1 ? '' : 's'}'
                    : 'Actualizado · ${_fmtTs(sync.lastSyncAt)}',
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (!sync.isSyncing)
          GestureDetector(
            onTap: onSync,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Sincronizar',
                style: TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Ring Painter ──────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double value;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Full track
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    // Progress arc starting from top (-pi/2)
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
