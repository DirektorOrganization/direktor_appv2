// ============================================================
// MODELO G — "NORTH STAR"
// Panel gerencial minimalista inspirado en Stripe Dashboard
// + Linear. Responde UNA pregunta: "¿Qué necesita mi
// atención ahora mismo?". Cero ruido visual, máxima densidad
// de información relevante.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';
import '../widgets/style_picker_sheet.dart';

// ── Palette ──────────────────────────────────────────────────
abstract final class _G {
  static const bg           = Color(0xFFFAFBFD);
  static const surface      = Colors.white;
  static const stroke       = Color(0xFFE8EDF5);
  static const text         = Color(0xFF111827);
  static const muted        = Color(0xFF6B7A90);
  static const blue         = Color(0xFF1D6FE8);
  static const blueSoft     = Color(0xFFEBF2FF);
  static const red          = Color(0xFFDC3545);
  static const redSoft      = Color(0xFFFFF0F0);
  static const green        = Color(0xFF18825A);
  static const greenSoft    = Color(0xFFECFAF4);
  static const yellow       = Color(0xFFCA8A04);
  static const yellowSoft   = Color(0xFFFFFBEB);
  static const orange       = Color(0xFFEA6B10);
}

// ── Health level ─────────────────────────────────────────────
enum _HealthLevel { healthy, warning, critical }

Color _healthColor(_HealthLevel level, {bool soft = false}) {
  switch (level) {
    case _HealthLevel.healthy:
      return soft ? _G.greenSoft : _G.green;
    case _HealthLevel.warning:
      return soft ? _G.yellowSoft : _G.yellow;
    case _HealthLevel.critical:
      return soft ? _G.redSoft : _G.red;
  }
}

String _healthLabel(_HealthLevel level) {
  switch (level) {
    case _HealthLevel.healthy:  return 'Saludable';
    case _HealthLevel.warning:  return 'En Alerta';
    case _HealthLevel.critical: return 'Acción Urgente';
  }
}

String _healthDesc(_HealthLevel level, int overdueCount, double compliance) {
  final pct = (compliance * 100).round();
  switch (level) {
    case _HealthLevel.healthy:
      return 'El proyecto avanza dentro de los parámetros esperados.';
    case _HealthLevel.warning:
      return 'Hay $overdueCount restricciones vencidas que requieren seguimiento.';
    case _HealthLevel.critical:
      return 'Cumplimiento crítico ($pct%). Se requiere intervención inmediata.';
  }
}

IconData _healthIcon(_HealthLevel level) {
  switch (level) {
    case _HealthLevel.healthy:  return Icons.check_circle_rounded;
    case _HealthLevel.warning:  return Icons.warning_rounded;
    case _HealthLevel.critical: return Icons.error_rounded;
  }
}

String _healthShort(_HealthLevel level) {
  switch (level) {
    case _HealthLevel.healthy:  return 'OK';
    case _HealthLevel.warning:  return 'ALERTA';
    case _HealthLevel.critical: return 'CRÍTICO';
  }
}

// ── Insight model ─────────────────────────────────────────────
class _Insight {
  const _Insight(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
}

// ── Today helper ─────────────────────────────────────────────
String _today() {
  const months = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];
  final now = DateTime.now();
  return '${now.day} ${months[now.month - 1]} ${now.year}';
}

// ── Main screen ───────────────────────────────────────────────
class HubModeloG extends StatelessWidget {
  const HubModeloG({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user    = controller.user;
        final project = controller.currentProject;

        if (project == null || user == null) {
          return const Scaffold(
            backgroundColor: _G.bg,
            body: Center(child: CircularProgressIndicator(color: _G.blue)),
          );
        }

        final summary      = controller.restrictionSummary;
        final restrictions = controller.restrictions;
        final milestones   = controller.milestoneSummary;
        final sync         = controller.syncOverview;
        final projects     = controller.projects;

        // ── Computed data vars ─────────────────────────────
        final overdueCount    = restrictions.where((r) => r.isOverdue && !r.isCompleted).length;
        final inProgressCount = restrictions.where((r) => r.isInProgress && !r.isOverdue).length;
        final pendingCount    = restrictions.where((r) => r.isPending && !r.isOverdue).length;
        final compliance      = summary.compliancePercent;
        final pct             = (compliance * 100).round();

        // ── Health score ───────────────────────────────────
        final penaltyRisk = milestones.accumulatedPenalty > 0 || milestones.delayedCount > 0;
        final _HealthLevel health;
        if (overdueCount > 2 || compliance < 0.4 || penaltyRisk) {
          health = _HealthLevel.critical;
        } else if (overdueCount > 0 || compliance < 0.7 || milestones.inProgressCount > 3) {
          health = _HealthLevel.warning;
        } else {
          health = _HealthLevel.healthy;
        }

        // ── Insights ───────────────────────────────────────
        final List<_Insight> insights = [];
        if (overdueCount > 0) {
          insights.add(_Insight(
            Icons.schedule_rounded,
            '$overdueCount restricciones vencidas están impactando el avance del proyecto.',
            _G.red,
          ));
        }
        if (milestones.delayedCount > 0) {
          insights.add(_Insight(
            Icons.flag_rounded,
            '${milestones.delayedCount} hito(s) vencido(s) con riesgo de penalidad contractual.',
            _G.red,
          ));
        }
        if (milestones.accumulatedPenalty > 0) {
          insights.add(_Insight(
            Icons.payments_outlined,
            'Penalidad acumulada de S/ ${milestones.accumulatedPenalty.toStringAsFixed(0)} en el contrato.',
            _G.orange,
          ));
        }
        if (compliance < 0.5) {
          insights.add(_Insight(
            Icons.trending_down_rounded,
            'Cumplimiento por debajo del 50% — revisar restricciones críticas.',
            _G.red,
          ));
        }
        if (compliance >= 0.8) {
          insights.add(_Insight(
            Icons.verified_rounded,
            'Cumplimiento superior al $pct% — el equipo supera el objetivo.',
            _G.green,
          ));
        }
        if (inProgressCount > 0) {
          insights.add(_Insight(
            Icons.timelapse_rounded,
            '$inProgressCount restricciones en proceso. Verificar fechas de cierre.',
            _G.yellow,
          ));
        }
        if (milestones.activeExtensions > 0) {
          insights.add(_Insight(
            Icons.schedule_send_rounded,
            '${milestones.activeExtensions} ampliación(es) activas afectan el cronograma contractual.',
            _G.orange,
          ));
        }
        if (insights.isEmpty) {
          insights.add(const _Insight(
            Icons.check_circle_rounded,
            'Sin alertas activas. El proyecto opera dentro de los parámetros.',
            _G.green,
          ));
        }
        final displayInsights = insights.take(4).toList();

        // ── Financial exposure ─────────────────────────────
        final accPenalty = milestones.accumulatedPenalty;
        final potPenalty = milestones.potentialPenalty;
        final showFinancial = accPenalty > 0 || potPenalty > 0;

        // ── Sync text ──────────────────────────────────────
        final isOffline  = sync.isOfflineEffective || !sync.hasNetwork;
        final canSync    = !isOffline && sync.apiConfigured && sync.remoteSyncEnabled;
        final lastSyncAt = sync.lastSyncAt;
        String syncText;
        if (isOffline) {
          syncText = 'Sin conexión';
        } else if (lastSyncAt != null) {
          final hh = lastSyncAt.hour.toString().padLeft(2, '0');
          final mm = lastSyncAt.minute.toString().padLeft(2, '0');
          syncText = 'Sync: $hh:$mm';
        } else {
          syncText = '$pendingCount pendientes';
        }

        return Scaffold(
          backgroundColor: _G.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SECTION 1: Slim Header ───────────────
                  Row(
                    children: [
                      const DirektorLogo(size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'DIREKTOR',
                        style: TextStyle(
                          color: _G.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _today(),
                        style: const TextStyle(
                          color: _G.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'logout') {
                            await controller.logout();
                            if (!context.mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context, RouteNames.login, (_) => false,
                            );
                          } else if (v == 'profile') {
                            if (!context.mounted) return;
                            Navigator.pushNamed(context, RouteNames.profile);
                          } else if (v == 'styles') {
                            if (!context.mounted) return;
                            await showStylePicker(context);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
                          PopupMenuItem(
                            value: 'styles',
                            child: Row(
                              children: const [
                                Icon(Icons.palette_rounded, size: 16, color: Color(0xFFE8941A)),
                                SizedBox(width: 8),
                                Text('Cambiar Estilo'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(value: 'logout',  child: Text('Cerrar sesión')),
                        ],
                        padding: EdgeInsets.zero,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: _G.blueSoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: _G.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showProjectSelector(context, controller, projects),
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        color: _G.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${user.name} · ${project.roleLabel}',
                    style: const TextStyle(color: _G.muted, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 2: Health Score Card ─────────
                  Container(
                    decoration: BoxDecoration(
                      color: _healthColor(health, soft: true),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _healthColor(health)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTADO DEL PROYECTO',
                                style: TextStyle(
                                  color: _G.muted,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _healthLabel(health),
                                style: TextStyle(
                                  color: _healthColor(health),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _healthDesc(health, overdueCount, compliance),
                                style: const TextStyle(
                                  color: _G.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _HealthBadge(health),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 3: Insights ───────────────────
                  const Text(
                    'INSIGHTS',
                    style: TextStyle(
                      color: _G.muted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(displayInsights.length, (i) {
                    final ins = displayInsights[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < displayInsights.length - 1 ? 10 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: ins.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(ins.icon, color: ins.color, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ins.text,
                              style: const TextStyle(
                                color: _G.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // ── SECTION 4: Modules RAG ────────────────
                  const Text(
                    'MÓDULOS',
                    style: TextStyle(
                      color: _G.muted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _G.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _G.stroke),
                    ),
                    child: Column(
                      children: [
                        _ModuleRow(
                          label: 'Análisis restricciones',
                          dotColor: overdueCount > 0
                              ? _G.red
                              : compliance >= 0.7
                                  ? _G.green
                                  : _G.yellow,
                          keyValue: '$pct%',
                          ragColor: overdueCount > 0
                              ? _G.red
                              : compliance >= 0.7
                                  ? _G.green
                                  : _G.yellow,
                          onTap: () => Navigator.pushNamed(
                              context, RouteNames.restrictionsList),
                        ),
                        Divider(height: 1, color: _G.stroke),
                        _ModuleRow(
                          label: 'Control de hitos',
                          dotColor: milestones.delayedCount > 0
                              ? _G.red
                              : milestones.inProgressCount > 0
                                  ? _G.yellow
                                  : _G.green,
                          keyValue: '${milestones.inProgressCount} activos',
                          ragColor: milestones.delayedCount > 0
                              ? _G.red
                              : milestones.inProgressCount > 0
                                  ? _G.yellow
                                  : _G.green,
                          onTap: () => Navigator.pushNamed(
                              context, RouteNames.controlHitos),
                        ),
                        Divider(height: 1, color: _G.stroke),
                        _ModuleRow(
                          label: 'Acta de reuniones',
                          dotColor: _G.yellow,
                          keyValue: 'Option 9',
                          ragColor: _G.yellow,
                          onTap: () => Navigator.pushNamed(
                              context, RouteNames.actaReuniones),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 5: Financial Exposure ─────────
                  if (showFinancial) ...[
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, RouteNames.controlHitos),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _G.redSoft,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: _G.red.withValues(alpha: 0.20)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined,
                                    color: _G.red, size: 18),
                                const SizedBox(width: 10),
                                const Text(
                                  'Exposición financiera',
                                  style: TextStyle(
                                    color: _G.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: _G.red.withValues(alpha: 0.60),
                                    size: 12),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  'Penalidad acumulada',
                                  style: TextStyle(
                                      color: _G.muted, fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  'S/ ${accPenalty.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: _G.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Penalidad potencial',
                                  style: TextStyle(
                                      color: _G.muted, fontSize: 12),
                                ),
                                const Spacer(),
                                Text(
                                  'S/ ${potPenalty.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: _G.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── SECTION 6: Compliance Ring + Bar ──────
                  Row(
                    children: [
                      _MiniRing(compliance, size: 72, strokeWidth: 10),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cumplimiento general',
                              style: TextStyle(
                                color: _G.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$pct% de ${summary.total} restricciones',
                              style: const TextStyle(
                                  color: _G.muted, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: compliance.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: _G.stroke,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  compliance >= 0.7
                                      ? _G.green
                                      : compliance >= 0.4
                                          ? _G.yellow
                                          : _G.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION 7: Sync Footer ────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_sync_rounded,
                              color: _G.muted, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            syncText,
                            style: const TextStyle(
                                color: _G.muted, fontSize: 11),
                          ),
                        ],
                      ),
                      if (canSync)
                        TextButton(
                          onPressed: controller.syncNow,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sincronizar',
                            style: TextStyle(
                              color: _G.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProjectSelector(
    BuildContext context,
    dynamic controller,
    List<ProjectRecord> projects,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _G.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Seleccionar proyecto',
                  style: TextStyle(
                    color: _G.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1, color: _G.stroke),
              ...projects.map((p) {
                final isCurrent = controller.currentProject?.id == p.id;
                return ListTile(
                  title: Text(
                    p.name,
                    style: TextStyle(
                      color: _G.text,
                      fontSize: 13,
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    p.roleLabel,
                    style: const TextStyle(
                        color: _G.muted, fontSize: 11),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_rounded,
                          color: _G.blue, size: 18)
                      : null,
                  onTap: () {
                    controller.changeProject(p);
                    Navigator.pop(ctx);
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
}

// ── Health Badge ──────────────────────────────────────────────
class _HealthBadge extends StatelessWidget {
  const _HealthBadge(this.health);
  final _HealthLevel health;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _healthColor(health),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_healthIcon(health), color: Colors.white, size: 20),
          const SizedBox(width: 4),
          Text(
            _healthShort(health),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Module Row ────────────────────────────────────────────────
class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.label,
    required this.dotColor,
    required this.keyValue,
    required this.ragColor,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final String keyValue;
  final Color ragColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _G.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              keyValue,
              style: TextStyle(
                color: ragColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _G.muted, size: 12),
          ],
        ),
      ),
    );
  }
}

// ── Mini Ring ─────────────────────────────────────────────────
class _MiniRing extends StatelessWidget {
  const _MiniRing(this.value, {required this.size, required this.strokeWidth});

  final double value;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniRingPainter(
          value: value.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: _G.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  const _MiniRingPainter({
    required this.value,
    required this.strokeWidth,
  });

  final double value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = _G.stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressColor = value >= 0.7
        ? _G.green
        : value >= 0.4
            ? _G.yellow
            : _G.red;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.value != value || old.strokeWidth != strokeWidth;
}
