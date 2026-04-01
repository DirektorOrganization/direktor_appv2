import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';

abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7); // Direktor brand blue
  static const accent      = Color(0xFF1167C8);
  static const accentLight = Color(0xFFCCDFF7);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const red         = Color(0xFFEF4444);
  static const green       = Color(0xFF10B981);
  static const yellow      = Color(0xFFF59E0B);
}

enum _HealthLevel { healthy, warning, critical }

class InsightsModuleScreen extends StatefulWidget {
  const InsightsModuleScreen({
    super.key,
    required this.module,
    required this.moduleBuilder,
  });

  final ModuleInsightModule module;
  final WidgetBuilder moduleBuilder;

  @override
  State<InsightsModuleScreen> createState() => _InsightsModuleScreenState();
}

class _InsightsModuleScreenState extends State<InsightsModuleScreen> {
  final Set<String> _updating = <String>{};

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final allInsights = controller.insightsForModule(widget.module);
        final insights = allInsights
            .where(
              (item) =>
                  item.severity == ModuleInsightSeverity.warning ||
                  item.severity == ModuleInsightSeverity.critical,
            )
            .toList();
        final unresolved = insights.where((item) => !item.isResolved).toList();
        final unresolvedAlerts = unresolved
            .where((item) => item.severity == ModuleInsightSeverity.warning)
            .length;
        final unresolvedCritical = unresolved
            .where((item) => item.severity == ModuleInsightSeverity.critical)
            .length;

        if (unresolved.isEmpty) return widget.moduleBuilder(context);

        final total = insights.length;
        final resolvedCount = insights.where((item) => item.isResolved).length;
        final pendingCount = total - resolvedCount;

        final health = unresolvedCritical > 0
            ? _HealthLevel.critical
            : _HealthLevel.warning;
        final healthColor = _healthColor(health);
        final healthSoft = _healthColor(health, soft: true);
        final title = health == _HealthLevel.critical
            ? 'Accion Urgente ($unresolvedCritical)'
            : 'Accion Preventiva ($unresolvedAlerts)';
        final subtitle = health == _HealthLevel.critical
            ? 'Tenemos $unresolvedCritical insights que necesitan accion inmediata y $unresolvedAlerts insight(s) que necesitan revision preventiva.'
            : 'Revisar estos insights y dar acciones preventivas.';

        return Scaffold(
          backgroundColor: _D.bg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estructura tipo G: cabecera slim
                  Row(
                    children: [
                      const DirektorLogo(size: 26),
                      const SizedBox(width: 8),
                      const Text(
                        'DIREKTOR',
                        style: TextStyle(
                          color: _D.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      _TopPill(
                        color: healthColor,
                        label: health == _HealthLevel.critical
                            ? 'Critico'
                            : 'Alerta',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Insights - ${_moduleLabel(widget.module)}',
                    style: const TextStyle(color: _D.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Sección 1: forma G (tarjeta estado + badge)
                  Container(
                    decoration: BoxDecoration(
                      color: healthSoft,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: healthColor),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'ESTADO DEL PROYECTO',
                              style: TextStyle(
                                color: _D.mutedLight,
                                fontSize: 10,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Spacer(),
                            _HealthBadge(level: health),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: healthColor,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _D.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sección 2: forma G (lista compacta sin cajas grandes)
                  const _SectionTitle('LISTA DE INSIGHTS'),
                  const SizedBox(height: 8),
                  ...List.generate(unresolved.length, (index) {
                    final insight = unresolved[index];
                    final isBusy = _updating.contains(insight.key);
                    final itemColor =
                        insight.severity == ModuleInsightSeverity.critical
                        ? _D.red
                        : _D.yellow;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < unresolved.length - 1 ? 6 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _D.accentLight.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForInsight(insight.iconName),
                              color: _D.accent,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  insight.title,
                                  style: const TextStyle(
                                    color: _D.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        insight.message,
                                        style: const TextStyle(
                                          color: _D.muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _SeverityPill(
                                      label: insight.severityLabel,
                                      color: itemColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                if (index < unresolved.length - 1)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _D.stroke,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Checkbox(
                            value: insight.isResolved,
                            onChanged: isBusy
                                ? null
                                : (value) async {
                                    if (value == null) return;
                                    setState(() => _updating.add(insight.key));
                                    await controller.setModuleInsightResolved(
                                      module: widget.module,
                                      insightKey: insight.key,
                                      resolved: value,
                                    );
                                    if (mounted) {
                                      setState(
                                        () => _updating.remove(insight.key),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  const _SectionTitle('INDICADORES'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _D.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _D.stroke),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _MetricBar(
                          label: 'Resueltos',
                          value: resolvedCount,
                          total: total,
                          color: _D.green,
                        ),
                        const SizedBox(height: 10),
                        _MetricBar(
                          label: 'Pendientes',
                          value: pendingCount,
                          total: total,
                          color: _D.red,
                        ),
                        const SizedBox(height: 10),
                        _MetricBar(
                          label: 'Criticos pendientes',
                          value: unresolvedCritical,
                          total: total,
                          color: _D.red,
                        ),
                        const SizedBox(height: 10),
                        _MetricBar(
                          label: 'Alertas pendientes',
                          value: unresolvedAlerts,
                          total: total,
                          color: _D.yellow,
                        ),
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
  }

  String _moduleLabel(ModuleInsightModule module) {
    switch (module) {
      case ModuleInsightModule.restrictions:
        return 'Analisis de Restricciones';
      case ModuleInsightModule.actaReuniones:
        return 'Acta de Reuniones';
    }
  }

  IconData _iconForInsight(String iconName) {
    switch (iconName) {
      case 'schedule':
        return Icons.schedule_rounded;
      case 'priority_high':
        return Icons.priority_high_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'report_problem':
        return Icons.report_problem_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'event_busy':
        return Icons.event_busy_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'crisis_alert':
        return Icons.crisis_alert_rounded;
      case 'schedule_send':
        return Icons.schedule_send_rounded;
      case 'event_repeat':
        return Icons.event_repeat_rounded;
      case 'restart_alt':
        return Icons.restart_alt_rounded;
      case 'dangerous':
        return Icons.dangerous_rounded;
      default:
        return Icons.insights_rounded;
    }
  }
}

Color _healthColor(_HealthLevel level, {bool soft = false}) {
  switch (level) {
    case _HealthLevel.healthy:
      return soft ? _D.green.withValues(alpha: 0.10) : _D.green;
    case _HealthLevel.warning:
      return soft ? _D.yellow.withValues(alpha: 0.10) : _D.yellow;
    case _HealthLevel.critical:
      return soft ? _D.red.withValues(alpha: 0.10) : _D.red;
  }
}

IconData _healthIcon(_HealthLevel level) {
  switch (level) {
    case _HealthLevel.healthy:
      return Icons.check_circle_rounded;
    case _HealthLevel.warning:
      return Icons.warning_rounded;
    case _HealthLevel.critical:
      return Icons.error_rounded;
  }
}

String _healthShort(_HealthLevel level) {
  switch (level) {
    case _HealthLevel.healthy:
      return 'OK';
    case _HealthLevel.warning:
      return 'ALERTA';
    case _HealthLevel.critical:
      return 'CRITICO';
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.level});

  final _HealthLevel level;

  @override
  Widget build(BuildContext context) {
    final color = _healthColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_healthIcon(level), color: Colors.white, size: 14),
          const SizedBox(width: 3),
          Text(
            _healthShort(level),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _D.mutedLight,
        fontSize: 10,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (value / safeTotal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _D.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: _D.stroke,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
