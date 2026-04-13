// ============================================================
// MODELO D — "ANALYTICS"
// Dark-navy dashboard inspirado en el banner corporativo.
// Fondo oscuro, gráficos de barras horizontales, layout
// data-first. Sin librerías externas — solo CustomPainter.
// Paleta: navy profundo + acentos verde / amarillo / rojo.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/core/app_clock.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Paleta de colores del modelo ─────────────────────────────
abstract final class _C {
  static const bg       = Color(0xFF0B1120);
  static const surface  = Color(0xFF141E2E);
  static const surface2 = Color(0xFF1C2A3E);
  static const stroke   = Color(0xFF243040);
  static const textLight= Color(0xFFF0F4FA);
  static const muted    = Color(0xFF8A9BB5);
  static const blue     = Color(0xFF1A7FE8);
  static const teal     = Color(0xFF0EC4A0);
  // AppTheme.brandOrange  → Color(0xFFF5A623)
  static const red      = Color(0xFFE05252);
  static const yellow   = Color(0xFFE4A620);
  static const green    = Color(0xFF1DB87A);
}

// ── Meses abreviados en español ───────────────────────────────
const _monthLabels = [
  '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
  'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_monthLabels[d.month]} ${d.year}';

// ── Pantalla principal ────────────────────────────────────────
class HubModeloD extends StatelessWidget {
  const HubModeloD({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    // Forzar tema oscuro exclusivamente para esta pantalla.
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _C.bg,
        colorScheme: const ColorScheme.dark(
          primary: _C.blue,
          secondary: _C.teal,
          surface: _C.surface,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: _C.surface2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(color: _C.textLight, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final user    = controller.user;
          final project = controller.currentProject;

          if (project == null || user == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: _C.blue)),
            );
          }

          final summary      = controller.restrictionSummary;
          final restrictions = controller.restrictions;
          final milestones   = controller.milestoneSummary;
          final sync         = controller.syncOverview;

          // Conteos derivados para las barras y tarjetas.
          final overdueCount    = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
          final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
          final pendingCount    = restrictions.where((r) => r.isPending).length;
          final completed3      = controller.completedRestrictions.take(3).toList();

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: _C.bg,
              body: SafeArea(
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────
                    _AnalyticsHeader(
                      user: user,
                      project: project,
                      sync: sync,
                      projects: controller.projects,
                      onProjectChange: controller.changeProject,
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
                    // ── Contenido scrollable ─────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1 · Anillo de cumplimiento
                            _ComplianceRingCard(
                              compliancePercent: summary.compliancePercent,
                            ),
                            const SizedBox(height: 16),

                            // 2 · Barra segmentada de restricciones
                            _SegmentedRestrictionCard(
                              overdue:    overdueCount,
                              inProgress: inProgressCount,
                              pending:    pendingCount,
                              completed:  summary.completed,
                              onTap: () => Navigator.pushNamed(
                                  context, RouteNames.restrictionsList),
                            ),
                            const SizedBox(height: 16),

                            // 3 · Tarjetas de módulos (fila)
                            Row(
                              children: [
                                Expanded(
                                  child: _ModuleCard(
                                    icon: Icons.flag_circle_rounded,
                                    title: 'Control de hitos',
                                    metricLabel: 'Retrasados',
                                    metricValue: '${milestones.delayedCount}',
                                    metricColor: _C.red,
                                    subLabel: 'En progreso',
                                    subValue: '${milestones.inProgressCount}',
                                    onTap: () => Navigator.pushNamed(
                                        context, RouteNames.controlHitos),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ModuleCard(
                                    icon: Icons.groups_rounded,
                                    title: 'Acta de reuniones',
                                    metricLabel: 'Panel ejecutivo',
                                    metricValue: 'Option 9',
                                    metricColor: AppTheme.brandOrange,
                                    subLabel: 'Acuerdos venc.',
                                    subValue: '—',
                                    onTap: () => Navigator.pushNamed(
                                        context, RouteNames.actaReuniones),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 4 · Actividad reciente
                            _RecentActivityCard(items: completed3),
                            const SizedBox(height: 16),

                            // 5 · Footer de sincronización
                            _SyncFooter(
                              sync: sync,
                              isBusy: controller.isBusy,
                              onSync: controller.syncNow,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.user,
    required this.project,
    required this.sync,
    required this.projects,
    required this.onProjectChange,
    required this.onMenuSelected,
  });

  final UserProfile          user;
  final ProjectRecord        project;
  final SyncOverview         sync;
  final List<ProjectRecord>  projects;
  final ValueChanged<int>    onProjectChange;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final offline = sync.isOfflineEffective;
    final today   = DateTime.now();

    return Container(
      color: _C.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barra superior: logo + controles ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                // Isotipo D
                const DirektorLogo(size: 26),
                const SizedBox(width: 10),
                const Text(
                  'DIREKTOR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.textLight,
                    letterSpacing: 1.2,
                  ),
                ),
                // Separador vertical decorativo
                Container(
                  width: 1, height: 16,
                  color: _C.stroke,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                const Text(
                  'ANALYTICS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.blue,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                // Pill de conectividad
                _ConnectivityPill(sync: sync, offline: offline),
                const SizedBox(width: 8),
                // Avatar + menú de usuario
                PopupMenuButton<String>(
                  onSelected: onMenuSelected,
                  tooltip: user.fullName,
                  offset: const Offset(0, 40),
                  child: _UserAvatarChip(user: user),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: _C.muted),
                          const SizedBox(width: 10),
                          Text(
                            user.fullName.isNotEmpty ? user.fullName : user.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'styles',
                      child: Row(
                        children: [
                          Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                          SizedBox(width: 8),
                          Text('Cambiar Estilo'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 16, color: _C.red),
                          SizedBox(width: 10),
                          Text('Cerrar sesión', style: TextStyle(color: _C.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Nombre del proyecto (tappable → project picker) ──
          GestureDetector(
            onTap: () => _showProjectSheet(context, projects, project, onProjectChange),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _C.textLight,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.unfold_more_rounded, size: 18, color: _C.muted),
                ],
              ),
            ),
          ),
          // Sub-título: rol + fecha
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            child: Text(
              '${project.roleLabel}  ·  ${_fmtDate(today)}',
              style: const TextStyle(
                fontSize: 12,
                color: _C.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Divider(height: 1, color: _C.stroke),
        ],
      ),
    );
  }
}

// ── Connectivity pill ─────────────────────────────────────────
class _ConnectivityPill extends StatelessWidget {
  const _ConnectivityPill({required this.sync, required this.offline});
  final SyncOverview sync;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    if (offline) {
      return _pill('OFFLINE', _C.red);
    }
    if (sync.pendingCount > 0) {
      return _pill('${sync.pendingCount} pend.', _C.yellow);
    }
    return _pill('ONLINE', _C.green);
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      );
}

// ── User avatar chip ──────────────────────────────────────────
class _UserAvatarChip extends StatelessWidget {
  const _UserAvatarChip({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _C.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.blue.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: _C.blue.withValues(alpha: 0.80),
            child: Text(
              initials,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _C.muted),
        ],
      ),
    );
  }

  String _initials(UserProfile u) {
    final parts = '${u.name} ${u.lastName}'.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U';
  }
}

// ── Project change bottom sheet ───────────────────────────────
void _showProjectSheet(
  BuildContext context,
  List<ProjectRecord> projects,
  ProjectRecord current,
  ValueChanged<int> onSelect,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _C.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _C.stroke,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cambiar proyecto',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _C.textLight),
                ),
              ),
            ),
            ...projects.map((p) {
              final selected = p.id == current.id;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? _C.blue : _C.muted,
                  size: 20,
                ),
                title: Text(
                  p.name,
                  style: TextStyle(
                    color: selected ? _C.textLight : _C.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(p.roleLabel, style: const TextStyle(fontSize: 11, color: _C.muted)),
                onTap: () {
                  Navigator.pop(context);
                  onSelect(p.id);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN 1 · Anillo de cumplimiento
// ─────────────────────────────────────────────────────────────
class _ComplianceRingCard extends StatelessWidget {
  const _ComplianceRingCard({required this.compliancePercent});
  final double compliancePercent;

  @override
  Widget build(BuildContext context) {
    final pct = compliancePercent.clamp(0.0, 1.0);
    final pctInt = (pct * 100).round();

    // Color del anillo según umbral
    final ringColor = pct > 0.70
        ? _C.green
        : pct > 0.40
            ? _C.yellow
            : _C.red;

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            icon: Icons.donut_large_rounded,
            text: 'Cumplimiento general',
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _RingPainter(
                  value: pct,
                  ringColor: ringColor,
                  bgColor: _C.stroke,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pctInt%',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: ringColor,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'cumplido',
                        style: TextStyle(fontSize: 10, color: _C.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Cumplimiento general',
              style: TextStyle(fontSize: 12, color: _C.muted, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainter: anillo de donut ─────────────────────────────
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.ringColor,
    required this.bgColor,
  });

  final double value;
  final Color  ringColor;
  final Color  bgColor;

  static const _strokeWidth = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    // Anillo de fondo
    final bgPaint = Paint()
      ..color       = bgColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap   = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, bgPaint);

    // Arco de valor (arranca desde la cima → -pi/2)
    if (value > 0) {
      final fgPaint = Paint()
        ..color       = ringColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap   = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.ringColor != ringColor;
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN 2 · Distribución de restricciones (barra segmentada)
// ─────────────────────────────────────────────────────────────
class _SegmentedRestrictionCard extends StatelessWidget {
  const _SegmentedRestrictionCard({
    required this.overdue,
    required this.inProgress,
    required this.pending,
    required this.completed,
    required this.onTap,
  });

  final int overdue;
  final int inProgress;
  final int pending;
  final int completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = overdue + inProgress + pending + completed;

    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _CardLabel(
                  icon: Icons.analytics_rounded,
                  text: 'Distribución de restricciones',
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Row(
                  children: [
                    Text(
                      'Ver análisis',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.brandOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.brandOrange),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra segmentada
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: CustomPaint(
                painter: _SegmentedBarPainter(
                  segments: [
                    _Segment(overdue,    _C.red),
                    _Segment(inProgress, _C.yellow),
                    _Segment(pending,    _C.muted),
                    _Segment(completed,  _C.green),
                  ],
                  total: total,
                  bgColor: _C.stroke,
                ),
                size: const Size(double.infinity, 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Leyenda
          Row(
            children: [
              _LegendDot(label: 'Retrasadas', count: overdue,    color: _C.red),
              _LegendDot(label: 'En proceso', count: inProgress, color: _C.yellow),
              _LegendDot(label: 'Pendientes', count: pending,    color: _C.muted),
              _LegendDot(label: 'Finalizadas', count: completed, color: _C.green),
            ],
          ),
        ],
      ),
    );
  }
}

// Modelo de segmento para el CustomPainter
class _Segment {
  const _Segment(this.count, this.color);
  final int   count;
  final Color color;
}

// ── CustomPainter: barra horizontal segmentada ────────────────
class _SegmentedBarPainter extends CustomPainter {
  const _SegmentedBarPainter({
    required this.segments,
    required this.total,
    required this.bgColor,
  });

  final List<_Segment> segments;
  final int   total;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo completo
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (total <= 0) return;

    double x = 0;
    for (final seg in segments) {
      if (seg.count <= 0) continue;
      final w = size.width * seg.count / total;
      final paint = Paint()..color = seg.color;
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w;
    }
  }

  @override
  bool shouldRepaint(_SegmentedBarPainter old) =>
      old.total != total || old.segments != segments;
}

// ── Ítem de leyenda ───────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int    count;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: _C.muted, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN 3 · Tarjetas de módulos (compactas, en fila)
// ─────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.metricLabel,
    required this.metricValue,
    required this.metricColor,
    required this.subLabel,
    required this.subValue,
    required this.onTap,
  });

  final IconData icon;
  final String   title;
  final String   metricLabel;
  final String   metricValue;
  final Color    metricColor;
  final String   subLabel;
  final String   subValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono + título + flecha
            Row(
              children: [
                Icon(icon, color: metricColor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.textLight,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _C.muted),
              ],
            ),
            Divider(height: 14, color: _C.stroke),
            // Métrica principal
            Text(
              metricValue,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: metricColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              metricLabel,
              style: const TextStyle(fontSize: 10, color: _C.muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            // Sub-métrica
            Row(
              children: [
                Expanded(
                  child: Text(
                    subLabel,
                    style: const TextStyle(fontSize: 10, color: _C.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  subValue,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.textLight,
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

// ─────────────────────────────────────────────────────────────
// SECCIÓN 4 · Actividad reciente (últimas 3 restricciones cerradas)
// ─────────────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});
  final List<RestrictionRecord> items;

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            icon: Icons.check_circle_outline_rounded,
            text: 'Actividad reciente',
            iconColor: _C.green,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sin actividad reciente.',
                style: TextStyle(color: _C.muted, fontSize: 12),
              ),
            )
          else
            ...items.map((item) => _ActivityRow(item: item)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final RestrictionRecord item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _C.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 14, color: _C.green),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.front,
                  style: const TextStyle(fontSize: 10, color: _C.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeDate(item.updatedAt),
            style: const TextStyle(
              fontSize: 11,
              color: _C.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeDate(DateTime v) {
    final now = AppClock.nowInDefaultZone();
    final dv = AppClock.toDefaultZone(v);
    final d = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dv.year, dv.month, dv.day))
        .inDays;
    if (d == 0) return 'Hoy';
    if (d == 1) return 'Ayer';
    if (d < 7)  return 'Hace $d d.';
    return '${dv.day.toString().padLeft(2, '0')}/${dv.month.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────
// SECCIÓN 5 · Footer de sincronización
// ─────────────────────────────────────────────────────────────
class _SyncFooter extends StatelessWidget {
  const _SyncFooter({
    required this.sync,
    required this.isBusy,
    required this.onSync,
  });

  final SyncOverview sync;
  final bool isBusy;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final offline  = sync.isOfflineEffective;
    final canSync  = !isBusy &&
        !sync.isSyncing &&
        !offline &&
        sync.remoteSyncEnabled &&
        sync.apiConfigured &&
        sync.pendingCount > 0;

    // Solo mostrar si hay pendientes o está offline
    if (!offline && sync.pendingCount == 0) return const SizedBox.shrink();

    final iconColor = offline ? _C.red : _C.yellow;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.stroke),
      ),
      child: Row(
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.cloud_sync_rounded,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              offline
                  ? 'Sin conexión — datos guardados localmente'
                  : sync.lastSyncAt != null
                      ? 'Última sync ${_hhmm(AppClock.toDefaultZone(sync.lastSyncAt!))} · ${sync.pendingCount} pend.'
                      : '${sync.pendingCount} cambios pendientes de sincronizar',
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canSync)
            GestureDetector(
              onTap: onSync,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _C.blue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.blue.withValues(alpha: 0.35)),
                ),
                child: sync.isSyncing
                    ? const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: _C.blue,
                        ),
                      )
                    : const Text(
                        'Sincronizar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.blue,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────
// Widgets de utilidad compartidos en el modelo D
// ─────────────────────────────────────────────────────────────

/// Card oscura base
class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.stroke),
      ),
      child: child,
    );
  }
}

/// Etiqueta de sección con icono
class _CardLabel extends StatelessWidget {
  const _CardLabel({
    required this.icon,
    required this.text,
    this.iconColor = _C.blue,
  });

  final IconData icon;
  final String   text;
  final Color    iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.textLight,
          ),
        ),
      ],
    );
  }
}
