// ============================================================
// PROFILE SCREEN — Rediseño 2026-04-10
// Secciones: Información · Preferencias · Herramientas · Preferencias Analíticas
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/insights/insight_rules.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_controller.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import '../../../../shared/widgets/direktor_logo.dart';

// ── Palette ───────────────────────────────────────────────────
abstract final class _D {
  static const bg          = Color(0xFFF5FAFE);
  static const surface     = Colors.white;
  static const stroke      = Color(0xFFE0EAF6);
  static const primary     = Color(0xFF0A66B7);
  static const accentLight = Color(0xFFCCDFF7);
  static const text        = Color(0xFF0F172A);
  static const muted       = Color(0xFF64748B);
  static const mutedLight  = Color(0xFF94A3B8);
  static const green       = Color(0xFF10B981);
  static const amber       = Color(0xFFF59E0B);
  static const red         = Color(0xFFEF4444);
}

// ── Indicator module catalog (keys per module) ─────────────────
const _kIndicatorModules = [
  _IndicatorModule(label: 'Restricciones',     prefix: 'res_', icon: Icons.block_rounded),
  _IndicatorModule(label: 'Control de Hitos',  prefix: 'hit_', icon: Icons.flag_rounded),
  _IndicatorModule(label: 'Acta de Reuniones', prefix: 'act_', icon: Icons.groups_rounded),
];

class _IndicatorModule {
  const _IndicatorModule({
    required this.label,
    required this.prefix,
    required this.icon,
  });
  final String label;
  final String prefix;
  final IconData icon;
}

// ── Insight modules ───────────────────────────────────────────
const _kInsightModules = [
  (module: ModuleInsightModule.restrictions,  label: 'Restricciones',     icon: Icons.block_rounded),
  (module: ModuleInsightModule.actaReuniones, label: 'Acta de Reuniones', icon: Icons.groups_rounded),
];

// ── Screen ────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Section expansions
  bool _advancedIndicators = false;
  bool _advancedInsights   = false;
  bool _advancedAlerts     = false;

  // Insight configs loaded async
  bool _insightsLoading = true;
  Map<ModuleInsightModule, List<InsightRuleConfigRecord>> _insightConfigs = {};

  // Busy flags per key (so we don't double-tap)
  final Set<String> _busyIndicators = {};
  final Set<String> _busyInsights   = {};
  final Set<String> _busyAlerts     = {};

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadInsightConfigs();
  }

  // ── Insights helpers ────────────────────────────────────────

  Future<void> _loadInsightConfigs() async {
    final controller = AppScope.of(context);
    final Map<ModuleInsightModule, List<InsightRuleConfigRecord>> configs = {};
    for (final m in ModuleInsightModule.values) {
      configs[m] = await controller.loadInsightRuleConfigs(m);
    }
    if (!mounted) return;
    setState(() {
      _insightConfigs = configs;
      _insightsLoading = false;
    });
  }

  bool _isInsightModuleEnabled(ModuleInsightModule module) {
    final configs  = _insightConfigs[module] ?? [];
    final catalog  = insightRulesCatalogForModule(module);
    final byKey    = {for (final c in configs) c.ruleKey: c};
    for (final rule in catalog) {
      final cfg = byKey[rule.key];
      if (cfg != null && !cfg.isEnabled) return false;
    }
    return true; // no explicit disable → default enabled
  }

  // Master = ON si AL MENOS UN módulo está habilitado.
  // Master = OFF solo cuando TODOS están deshabilitados.
  bool _isInsightsMasterEnabled() {
    if (_insightsLoading) return true;
    return _kInsightModules.any((m) => _isInsightModuleEnabled(m.module));
  }

  Future<void> _toggleInsightModule(
    AppController controller,
    ModuleInsightModule module,
    bool enabled,
  ) async {
    final busyKey = 'insight_${module.name}';
    if (_busyInsights.contains(busyKey)) return;
    setState(() => _busyInsights.add(busyKey));

    final records = _buildInsightRecords(module: module, enabled: enabled);
    await controller.saveInsightRuleConfigBatch(records);
    await _loadInsightConfigs();
    if (mounted) setState(() => _busyInsights.remove(busyKey));
  }

  Future<void> _toggleInsightsMaster(AppController controller, bool enabled) async {
    setState(() => _busyInsights.add('master'));
    final records = [
      for (final m in _kInsightModules)
        ..._buildInsightRecords(module: m.module, enabled: enabled),
    ];
    await controller.saveInsightRuleConfigBatch(records);
    await _loadInsightConfigs();
    if (mounted) setState(() => _busyInsights.remove('master'));
  }

  List<InsightRuleConfigRecord> _buildInsightRecords({
    required ModuleInsightModule module,
    required bool enabled,
  }) {
    final userId  = AppScope.of(context).user?.id ?? 0;
    final catalog = insightRulesCatalogForModule(module);
    final existing = {
      for (final c in (_insightConfigs[module] ?? [])) c.ruleKey: c,
    };
    return [
      for (final rule in catalog)
        InsightRuleConfigRecord(
          userId: userId,
          module: module,
          ruleKey: rule.key,
          isEnabled: enabled,
          thresholds: {
            for (final t in rule.thresholds)
              t.key: existing[rule.key]?.threshold(t.key, t.defaultValue) ?? t.defaultValue,
          },
        ),
    ];
  }

  // ── Indicator helpers ───────────────────────────────────────

  bool _isIndicatorModuleEnabled(AppController controller, String prefix) {
    switch (prefix) {
      case 'res_':
        return controller.indicatorsRestrictionsEnabled;
      case 'hit_':
        return controller.indicatorsMilestonesEnabled;
      case 'act_':
        return controller.indicatorsActreuEnabled;
      default:
        return true;
    }
  }

  Future<void> _toggleIndicatorModule(
    AppController controller,
    String prefix,
    bool enabled,
  ) async {
    if (_busyIndicators.contains(prefix)) return;
    setState(() => _busyIndicators.add(prefix));
    final key = switch (prefix) {
      'res_' => 'indicators_module_restrictions',
      'hit_' => 'indicators_module_hitos',
      'act_' => 'indicators_module_actreu',
      _ => '',
    };
    if (key.isNotEmpty) {
      await controller.saveIndicatorsModulePref(key, enabled);
    }
    if (mounted) setState(() => _busyIndicators.remove(prefix));
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user  = controller.user;
        final userId = user?.id ?? 0;
        return Scaffold(
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: const BackButton(color: _D.primary),
            title: Row(
              children: [
                const DirektorLogo(size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Mi Perfil',
                  style: TextStyle(
                    color: _D.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [

                // ── Información ──────────────────────────────
                _SectionLabel('INFORMACIÓN'),
                const SizedBox(height: 8),
                _Card(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A66B7), Color(0xFF1167C8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName.isNotEmpty == true
                                  ? user!.fullName
                                  : 'Usuario',
                              style: const TextStyle(
                                color: _D.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '-',
                              style: const TextStyle(
                                color: _D.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _D.accentLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(
                            color: _D.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Preferencias ─────────────────────────────
                const SizedBox(height: 20),
                _SectionLabel('PREFERENCIAS'),
                const SizedBox(height: 8),
                _Card(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF312E81).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.dark_mode_rounded,
                          color: Color(0xFF4338CA),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modo oscuro',
                              style: TextStyle(
                                color: _D.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cambia el aspecto general de la app',
                              style: TextStyle(color: _D.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.isDarkMode,
                        activeThumbColor: _D.primary,
                        activeTrackColor: _D.accentLight,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: controller.setDarkMode,
                      ),
                    ],
                  ),
                ),

                // ── Herramientas ─────────────────────────────
                const SizedBox(height: 20),
                _SectionLabel('HERRAMIENTAS'),
                const SizedBox(height: 8),
                _DeviceBindingCard(userId: userId),

                // ── Preferencias Analíticas ──────────────────
                const SizedBox(height: 20),
                _SectionLabel('PREFERENCIAS ANALÍTICAS'),
                const SizedBox(height: 8),

                // — Indicadores Gráficos —
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E7490).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: Color(0xFF0E7490),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Indicadores Gráficos',
                                  style: TextStyle(
                                    color: _D.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Métricas visuales en la pantalla de proyectos',
                                  style: TextStyle(color: _D.muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          _busyIndicators.contains('master')
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                                )
                              : Switch(
                                  value: controller.indicatorsEnabled,
                                  activeThumbColor: _D.primary,
                                  activeTrackColor: _D.accentLight,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) async {
                                    setState(() => _busyIndicators.add('master'));
                                    await controller.saveIndicatorsEnabled(val);
                                    if (mounted) setState(() => _busyIndicators.remove('master'));
                                  },
                                ),
                        ],
                      ),

                      // Avanzado toggle
                      if (controller.indicatorsEnabled) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _advancedIndicators = !_advancedIndicators),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Text(
                                  'Avanzado',
                                  style: TextStyle(
                                    color: _D.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  _advancedIndicators
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 16,
                                  color: _D.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_advancedIndicators) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 1, color: _D.stroke),
                          const SizedBox(height: 10),
                          ...List.generate(_kIndicatorModules.length, (i) {
                            final mod = _kIndicatorModules[i];
                            final isOn = _isIndicatorModuleEnabled(controller, mod.prefix);
                            final isBusy = _busyIndicators.contains(mod.prefix);
                            return Padding(
                              padding: EdgeInsets.only(bottom: i < _kIndicatorModules.length - 1 ? 10 : 0),
                              child: Row(
                                children: [
                                  Icon(mod.icon, size: 15, color: _D.mutedLight),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mod.label,
                                      style: TextStyle(
                                        color: isOn ? _D.text : _D.mutedLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  isBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                                        )
                                      : Switch(
                                          value: isOn,
                                          activeThumbColor: _D.primary,
                                          activeTrackColor: _D.accentLight,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) => _toggleIndicatorModule(
                                            controller, mod.prefix, val,
                                          ),
                                        ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],

                      // Administrar button
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: _D.stroke),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 14, color: _D.muted),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Configura tipo de gráfico y orden de cada indicador.',
                              style: TextStyle(color: _D.muted, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, RouteNames.indicatorManager),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _D.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Administrar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
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

                const SizedBox(height: 10),

                // — Insights —
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Color(0xFF7C3AED),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Insights de Módulos',
                                  style: TextStyle(
                                    color: _D.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Alertas automáticas al entrar a cada módulo',
                                  style: TextStyle(color: _D.muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          _insightsLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                                )
                              : _busyInsights.contains('master')
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                                    )
                                  : Switch(
                                      value: _isInsightsMasterEnabled(),
                                      activeThumbColor: _D.primary,
                                      activeTrackColor: _D.accentLight,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) async {
                                        setState(() => _busyInsights.add('master'));
                                        await _toggleInsightsMaster(controller, val);
                                        if (mounted) setState(() => _busyInsights.remove('master'));
                                      },
                                    ),
                        ],
                      ),

                      // Avanzado toggle
                      if (!_insightsLoading && _isInsightsMasterEnabled()) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _advancedInsights = !_advancedInsights),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Text(
                                  'Avanzado',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  _advancedInsights
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  size: 16,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_advancedInsights) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 1, color: _D.stroke),
                          const SizedBox(height: 10),
                          ...List.generate(_kInsightModules.length, (i) {
                            final mod = _kInsightModules[i];
                            final isOn = _isInsightModuleEnabled(mod.module);
                            final isBusy = _busyInsights.contains('insight_${mod.module.name}');
                            return Padding(
                              padding: EdgeInsets.only(bottom: i < _kInsightModules.length - 1 ? 10 : 0),
                              child: Row(
                                children: [
                                  Icon(mod.icon, size: 15, color: _D.mutedLight),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mod.label,
                                      style: TextStyle(
                                        color: isOn ? _D.text : _D.mutedLight,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  isBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                                        )
                                      : Switch(
                                          value: isOn,
                                          activeThumbColor: _D.primary,
                                          activeTrackColor: _D.accentLight,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (val) => _toggleInsightModule(controller, mod.module, val),
                                        ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],

                      // Info note for insights
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: _D.stroke),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: _D.muted),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Configura los umbrales de cada regla desde el módulo correspondiente.',
                              style: TextStyle(color: _D.muted, fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Preferencias de Alertas ──────────────────
                const SizedBox(height: 20),
                _SectionLabel('PREFERENCIAS DE ALERTAS'),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Master toggle
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notificaciones de Cambios',
                                  style: TextStyle(
                                    color: _D.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Alertas al detectar cambios en el sync',
                                  style: TextStyle(color: _D.muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          _busyAlerts.contains('master')
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                                )
                              : Switch(
                                  value: controller.notificationsEnabled,
                                  activeThumbColor: _D.primary,
                                  activeTrackColor: _D.accentLight,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) async {
                                    setState(() => _busyAlerts.add('master'));
                                    await controller.saveNotificationPref('notifications_enabled', val);
                                    if (mounted) setState(() => _busyAlerts.remove('master'));
                                  },
                                ),
                        ],
                      ),

                      // Avanzado toggle
                      if (controller.notificationsEnabled) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => setState(() => _advancedAlerts = !_advancedAlerts),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Text(
                                  'Avanzado',
                                  style: TextStyle(color: _D.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  _advancedAlerts
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: _D.primary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_advancedAlerts) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 1, color: _D.stroke),
                          const SizedBox(height: 10),
                          // Restricciones
                          _AlertModuleRow(
                            label: 'Restricciones',
                            icon: Icons.warning_amber_rounded,
                            iconColor: const Color(0xFFEA580C),
                            isBusy: _busyAlerts.contains('alert_restrictions'),
                            value: controller.notificationsRestrictionsEnabled,
                            onChanged: (val) async {
                              setState(() => _busyAlerts.add('alert_restrictions'));
                              await controller.saveNotificationPref('notifications_module_restrictions', val);
                              if (mounted) setState(() => _busyAlerts.remove('alert_restrictions'));
                            },
                          ),
                          const SizedBox(height: 10),
                          // Actas de Reuniones
                          _AlertModuleRow(
                            label: 'Actas de Reuniones',
                            icon: Icons.handshake_rounded,
                            iconColor: const Color(0xFF0284C7),
                            isBusy: _busyAlerts.contains('alert_actreu'),
                            value: controller.notificationsActreuEnabled,
                            onChanged: (val) async {
                              setState(() => _busyAlerts.add('alert_actreu'));
                              await controller.saveNotificationPref('notifications_module_actreu', val);
                              if (mounted) setState(() => _busyAlerts.remove('alert_actreu'));
                            },
                          ),
                        ],
                      ],

                      // Info note
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: _D.stroke),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: _D.muted),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'Las alertas se disparan durante el sync operacional cuando se detectan cambios de estado.',
                              style: TextStyle(color: _D.muted, fontSize: 11, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Logout ────────────────────────────────────
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await controller.logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.login,
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded, color: _D.red, size: 18),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: _D.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _D.red, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
}

// ── Alert module row ─────────────────────────────────────────

class _AlertModuleRow extends StatelessWidget {
  const _AlertModuleRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isBusy,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isBusy;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _D.text, fontSize: 13),
          ),
        ),
        isBusy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
              )
            : Switch(
                value: value,
                activeThumbColor: _D.primary,
                activeTrackColor: _D.accentLight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onChanged,
              ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: _D.mutedLight,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _D.stroke),
        ),
        child: child,
      );
}

// ── Device Binding Card ───────────────────────────────────────

class _DeviceBindingCard extends StatelessWidget {
  const _DeviceBindingCard({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final linkedAt   = controller.deviceLinkedAt;
    final linkedAtLabel = linkedAt == null
        ? 'Pendiente'
        : '${linkedAt.day.toString().padLeft(2, '0')}/'
          '${linkedAt.month.toString().padLeft(2, '0')}/'
          '${linkedAt.year}';
    final linked = controller.isDeviceLinked;
    final statusColor = linked ? _D.green : _D.amber;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  linked ? Icons.phonelink_lock_rounded : Icons.phonelink_off_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dispositivo',
                      style: TextStyle(
                        color: _D.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      linked
                          ? 'Equipo vinculado — QR habilitado'
                          : 'Sin vincular — vincula para activar QR',
                      style: const TextStyle(color: _D.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.30)),
                ),
                child: Text(
                  linked ? 'Vinculado' : 'Inactivo',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: _D.stroke),
          const SizedBox(height: 12),
          _InfoLine(label: 'Equipo',     value: controller.linkedDeviceLabel ?? '-'),
          _InfoLine(label: 'Código',     value: controller.linkedDeviceId    ?? '-'),
          _InfoLine(label: 'Vinculado',  value: linkedAtLabel),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : () async {
                            if (linked) {
                              await controller.unlinkCurrentDevice();
                            } else {
                              await controller.linkCurrentDevice();
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: linked ? _D.red.withValues(alpha: 0.85) : _D.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      linked ? Icons.link_off_rounded : Icons.link_rounded,
                      size: 16,
                    ),
                    label: Text(
                      linked ? 'Desvincular' : 'Vincular equipo',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: !linked || controller.isBusy
                        ? null
                        : () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const _AttendanceQrSheet(),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: linked ? _D.primary : _D.stroke,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      Icons.qr_code_2_rounded,
                      size: 16,
                      color: linked ? _D.primary : _D.mutedLight,
                    ),
                    label: Text(
                      'Generar QR',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: linked ? _D.primary : _D.mutedLight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: const TextStyle(color: _D.mutedLight, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: _D.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

// ── QR Sheet (unchanged logic) ────────────────────────────────

class _AttendanceQrSheet extends StatefulWidget {
  const _AttendanceQrSheet();

  @override
  State<_AttendanceQrSheet> createState() => _AttendanceQrSheetState();
}

class _AttendanceQrSheetState extends State<_AttendanceQrSheet> {
  Timer? _timer;
  bool _started = false;
  late AppController _controller;
  String? _qrData;
  DateTime? _expiresAt;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _controller = AppScope.of(context);
    _refreshQr();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshQr());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQr() async {
    final qrData = await _controller.buildAttendanceQrPayload();
    if (!mounted) return;
    setState(() {
      _qrData    = qrData;
      _loading   = false;
      _expiresAt = DateTime.now().add(const Duration(seconds: 45));
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: _D.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + mq.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _D.stroke,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'QR dinámico de asistencia',
            style: TextStyle(
              color: _D.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Identifica al usuario y al dispositivo vinculado. Se regenera automáticamente cada 45 s.',
            style: TextStyle(color: _D.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 18),
          Center(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2, color: _D.primary),
                  )
                : _qrData == null
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Primero vincula este dispositivo.', style: TextStyle(color: _D.muted)),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _D.stroke),
                          boxShadow: [
                            BoxShadow(
                              color: _D.stroke.withValues(alpha: 0.6),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black87,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black87,
                          ),
                        ),
                      ),
          ),
          const SizedBox(height: 14),
          if (_expiresAt != null)
            Center(
              child: Text(
                'Válido hasta '
                '${_expiresAt!.hour.toString().padLeft(2, '0')}:'
                '${_expiresAt!.minute.toString().padLeft(2, '0')}:'
                '${_expiresAt!.second.toString().padLeft(2, '0')}',
                style: const TextStyle(color: _D.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _refreshQr,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _D.stroke),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16, color: _D.primary),
              label: const Text(
                'Regenerar ahora',
                style: TextStyle(color: _D.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
