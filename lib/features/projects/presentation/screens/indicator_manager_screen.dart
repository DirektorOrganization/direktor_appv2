// ============================================================
// INDICATOR MANAGER — MIS INDICADORES
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';

// ── Palette (matches hub_default_screen) ─────────────────────
abstract final class _D {
  static const bg = Color(0xFFF5FAFE);
  static const surface = Colors.white;
  static const stroke = Color(0xFFE0EAF6);
  static const primary = Color(0xFF0A66B7);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const mutedLight = Color(0xFF94A3B8);
}

// ── Catalog definition ────────────────────────────────────────

class _IndicatorDef {
  const _IndicatorDef({
    required this.key,
    required this.label,
    required this.module,
    required this.recommendedType,
    this.configurableParam,
    this.configurableParamDefault,
    required this.availableTypes,
  });

  final String key;
  final String label;
  final String module;

  /// The recommended display_type
  final String recommendedType;

  /// null = not configurable
  final String? configurableParam;
  final String? configurableParamDefault;
  final List<String> availableTypes;
}

// Keys que arrancan habilitados por defecto (los 4 del grid principal)
const _kDefaultActiveKeys = {
  'res_cumplimiento',
  'res_vencidas',
  'res_en_proceso',
  'hit_activos',
};

const _catalog = [
  // ── Restricciones ────────────────────────────────
  _IndicatorDef(
    key: 'res_cumplimiento',
    label: 'Cumplimiento general',
    module: 'Restricciones',
    recommendedType: 'chart_donut',
    availableTypes: ['card', 'chart_donut'],
  ),
  _IndicatorDef(
    key: 'res_vencidas',
    label: 'Restricciones vencidas',
    module: 'Restricciones',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'res_en_proceso',
    label: 'En proceso',
    module: 'Restricciones',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'res_vencen_hoy',
    label: 'Vencen hoy',
    module: 'Restricciones',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'res_distribucion',
    label: 'Distribucion por estado',
    module: 'Restricciones',
    recommendedType: 'chart_bar',
    availableTypes: ['card', 'chart_bar'],
  ),
  _IndicatorDef(
    key: 'res_dias_criticos',
    label: 'Con retraso > N dias',
    module: 'Restricciones',
    recommendedType: 'card',
    availableTypes: ['card'],
    configurableParam: 'Umbral dias',
    configurableParamDefault: '3',
  ),
  // ── Control de Hitos ─────────────────────────────
  _IndicatorDef(
    key: 'hit_activos',
    label: 'Hitos activos',
    module: 'Control de Hitos',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'hit_cumplimiento',
    label: 'Cumplimiento de hitos',
    module: 'Control de Hitos',
    recommendedType: 'chart_donut',
    availableTypes: ['card', 'chart_donut'],
  ),
  _IndicatorDef(
    key: 'hit_vencidos',
    label: 'Hitos vencidos',
    module: 'Control de Hitos',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'hit_penalidad_acum',
    label: 'Penalidad acumulada',
    module: 'Control de Hitos',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'hit_penalidad_potencial',
    label: 'Penalidad potencial',
    module: 'Control de Hitos',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'hit_ampliaciones',
    label: 'Ampliaciones activas',
    module: 'Control de Hitos',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'hit_distribucion',
    label: 'Distribucion de hitos',
    module: 'Control de Hitos',
    recommendedType: 'chart_bar',
    availableTypes: ['card', 'chart_bar'],
  ),
  // ── Acta de Reuniones ────────────────────────────
  _IndicatorDef(
    key: 'act_vencidos',
    label: 'Acuerdos vencidos',
    module: 'Acta de Reuniones',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'act_pendientes',
    label: 'Acuerdos pendientes',
    module: 'Acta de Reuniones',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'act_cumplimiento',
    label: 'Cumplimiento de acuerdos',
    module: 'Acta de Reuniones',
    recommendedType: 'chart_donut',
    availableTypes: ['card', 'chart_donut'],
  ),
  _IndicatorDef(
    key: 'act_sesiones_activas',
    label: 'Sesiones activas',
    module: 'Acta de Reuniones',
    recommendedType: 'card',
    availableTypes: ['card'],
  ),
  _IndicatorDef(
    key: 'act_distribucion',
    label: 'Distribucion de acuerdos',
    module: 'Acta de Reuniones',
    recommendedType: 'chart_bar',
    availableTypes: ['card', 'chart_bar'],
  ),
];

// ── Helpers ───────────────────────────────────────────────────

HubIndicatorPref _defaultPref(int userId, _IndicatorDef def) {
  return HubIndicatorPref(
    key: def.key,
    userId: userId,
    isEnabled: _kDefaultActiveKeys.contains(def.key),
    displayType: def.recommendedType,
    customParam: def.configurableParamDefault,
    sortOrder: _catalog.indexOf(def),
  );
}

String _typeLabel(String type) {
  switch (type) {
    case 'chart_donut':
      return 'Grafico Donut';
    case 'chart_bar':
      return 'Grafico Barras';
    default:
      return 'Tarjeta';
  }
}

IconData _typeIcon(String type) {
  switch (type) {
    case 'chart_donut':
      return Icons.donut_large_rounded;
    case 'chart_bar':
      return Icons.bar_chart_rounded;
    default:
      return Icons.crop_square_rounded;
  }
}

// ── Screen ────────────────────────────────────────────────────

class IndicatorManagerScreen extends StatefulWidget {
  const IndicatorManagerScreen({super.key});

  @override
  State<IndicatorManagerScreen> createState() => _IndicatorManagerScreenState();
}

class _IndicatorManagerScreenState extends State<IndicatorManagerScreen> {
  // Local state for configurable param text controllers
  final Map<String, TextEditingController> _paramControllers = {};

  @override
  void dispose() {
    for (final c in _paramControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _paramCtrl(String key, String defaultVal) {
    return _paramControllers.putIfAbsent(
      key,
      () => TextEditingController(text: defaultVal),
    );
  }

  HubIndicatorPref _resolvedPref(
    List<HubIndicatorPref> prefs,
    _IndicatorDef def,
    int userId,
  ) {
    try {
      return prefs.firstWhere((p) => p.key == def.key);
    } catch (_) {
      return _defaultPref(userId, def);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        final userId = user?.id ?? 0;
        final prefs = controller.indicatorPrefs;

        bool isModulePreferenceEnabled(String module) {
          switch (module) {
            case 'Restricciones':
              return controller.indicatorsRestrictionsEnabled;
            case 'Control de Hitos':
              return controller.indicatorsMilestonesEnabled;
            case 'Acta de Reuniones':
              return controller.indicatorsActreuEnabled;
            default:
              return true;
          }
        }

        bool isModuleSubscriptionEnabled(String module) {
          switch (module) {
            case 'Restricciones':
              return controller.isSubscriptionModuleEnabled('ANARES');
            case 'Control de Hitos':
              return controller.isSubscriptionModuleEnabled('CONHIT');
            case 'Acta de Reuniones':
              return controller.isSubscriptionModuleEnabled('ACTAREU');
            default:
              return true;
          }
        }

        const modules = [
          'Restricciones',
          'Control de Hitos',
          'Acta de Reuniones',
        ];

        return Scaffold(
          backgroundColor: _D.bg,
          appBar: AppBar(
            backgroundColor: _D.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _D.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Mis Indicadores',
              style: TextStyle(
                color: _D.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: _D.stroke),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Activa o desactiva indicadores y elige como visualizarlos en el hub.',
                  style: const TextStyle(color: _D.muted, fontSize: 12),
                ),
              ),
              for (final module in modules) ...[
                _SectionHeader(
                  title: module,
                  isSubscriptionEnabled: isModuleSubscriptionEnabled(module),
                ),
                for (final def in _catalog.where((d) => d.module == module))
                  _IndicatorTile(
                    def: def,
                    pref: _resolvedPref(prefs, def, userId),
                    isLocked: !isModuleSubscriptionEnabled(module),
                    paramCtrl: def.configurableParam != null
                        ? _paramCtrl(
                            def.key,
                            _resolvedPref(prefs, def, userId).customParam ??
                                (def.configurableParamDefault ?? ''),
                          )
                        : null,
                    onToggle: (enabled) {
                      if (!isModuleSubscriptionEnabled(module) ||
                          !isModulePreferenceEnabled(module)) {
                        return;
                      }
                      final current = _resolvedPref(prefs, def, userId);
                      controller.saveIndicatorPref(
                        current.copyWith(isEnabled: enabled),
                      );
                    },
                    onTypeChanged: (type) {
                      if (!isModuleSubscriptionEnabled(module) ||
                          !isModulePreferenceEnabled(module)) {
                        return;
                      }
                      final current = _resolvedPref(prefs, def, userId);
                      controller.saveIndicatorPref(
                        current.copyWith(displayType: type),
                      );
                    },
                    onParamChanged: (val) {
                      if (!isModuleSubscriptionEnabled(module) ||
                          !isModulePreferenceEnabled(module)) {
                        return;
                      }
                      final current = _resolvedPref(prefs, def, userId);
                      controller.saveIndicatorPref(
                        current.copyWith(customParam: val),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Section Header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isSubscriptionEnabled,
  });

  final String title;
  final bool isSubscriptionEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _D.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          if (!isSubscriptionEnabled) ...[
            const SizedBox(width: 8),
            const Text(
              'Modulo deshabilitado',
              style: TextStyle(
                color: _D.mutedLight,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Indicator Tile ────────────────────────────────────────────

class _IndicatorTile extends StatelessWidget {
  const _IndicatorTile({
    required this.def,
    required this.pref,
    required this.onToggle,
    required this.onTypeChanged,
    required this.onParamChanged,
    required this.isLocked,
    this.paramCtrl,
  });

  final _IndicatorDef def;
  final HubIndicatorPref pref;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onParamChanged;
  final bool isLocked;
  final TextEditingController? paramCtrl;

  @override
  Widget build(BuildContext context) {
    final enabledForEditing = pref.isEnabled && !isLocked;
    return Opacity(
      opacity: isLocked ? 0.62 : 1,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: _D.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pref.isEnabled
                ? _D.primary.withValues(alpha: 0.25)
                : _D.stroke,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.label,
                          style: TextStyle(
                            color: pref.isEnabled ? _D.text : _D.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLocked
                              ? 'Modulo deshabilitado por suscripcion activa'
                              : 'Recomendado: ${_typeLabel(def.recommendedType)}',
                          style: const TextStyle(
                            color: _D.mutedLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: pref.isEnabled,
                    onChanged: isLocked ? null : onToggle,
                    activeThumbColor: _D.primary,
                    activeTrackColor: _D.primary.withValues(alpha: 0.45),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            if (enabledForEditing) ...[
              const Divider(color: _D.stroke, height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (def.availableTypes.length > 1) ...[
                      const Text(
                        'Visualizacion',
                        style: TextStyle(
                          color: _D.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final type in def.availableTypes)
                            _TypeChip(
                              label: _typeLabel(type),
                              icon: _typeIcon(type),
                              selected: pref.displayType == type,
                              onTap: () => onTypeChanged(type),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (def.configurableParam != null && paramCtrl != null) ...[
                      Text(
                        def.configurableParam!,
                        style: const TextStyle(
                          color: _D.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: paramCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: _D.text, fontSize: 13),
                          onChanged: onParamChanged,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: _D.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _D.stroke),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _D.stroke),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: _D.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Type Chip ─────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _D.primary.withValues(alpha: 0.10) : _D.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _D.primary : _D.stroke,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? _D.primary : _D.muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? _D.primary : _D.muted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
