// ============================================================
// Shared Style Picker — bottom sheet to switch hub views.
// Used by ProjectsHubScreen and all hub model screens.
// ============================================================

import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';

/// Opens the style-picker bottom sheet from any hub screen.
/// Saves the selection and navigates to the chosen style.
Future<void> showStylePicker(BuildContext context) async {
  final controller = AppScope.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => StylePickerSheet(
      currentStyle: controller.hubStyle,
      onSelect: (route) async {
        await controller.saveHubStyle(route);
        if (!context.mounted) return;
        Navigator.pop(context);
        if (route != null) {
          Navigator.pushNamed(context, route);
        }
      },
    ),
  );
}

// ── Sheet ──────────────────────────────────────────────────────
class StylePickerSheet extends StatelessWidget {
  const StylePickerSheet({
    super.key,
    required this.currentStyle,
    required this.onSelect,
  });

  final String? currentStyle;
  final void Function(String? route) onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) => SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar Estilo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'El estilo elegido se guardará para tu próxima sesión',
                style: TextStyle(fontSize: 12, color: Color(0xFF62748A)),
              ),
              const SizedBox(height: 10),
              // ── Vista por Defecto ──────────────────────────
              StylePickerTile(
                label: 'Vista por Defecto',
                description:
                    'ARCTIC — Scandinavian minimal · ice blue + indigo · estilo base',
                color: const Color(0xFF0891B2),
                icon: Icons.home_rounded,
                routeName: RouteNames.hubDefault,
                isSelected: currentStyle == RouteNames.hubDefault ||
                    currentStyle == null,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              // ── VERSION 1 ──────────────────────────────────
              StylePickerTile(
                label: 'VERSION 1',
                description:
                    'Hub original · datos reales · sincronización operativa',
                color: const Color(0xFF374151),
                icon: Icons.history_rounded,
                routeName: null,
                isSelected: false,
                onSelect: onSelect,
              ),
              const SizedBox(height: 14),
              const StylePickerCategoryLabel(
                label: 'GERENCIALES — Insights & decisiones',
              ),
              const SizedBox(height: 8),
              StylePickerTile(
                label: 'G — NORTH STAR',
                description:
                    'Health score · Insights auto · Tabla RAG · Exposición financiera',
                color: const Color(0xFF1D6FE8),
                icon: Icons.star_rounded,
                routeName: RouteNames.hubModeloG,
                isSelected: currentStyle == RouteNames.hubModeloG,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'J — ATLAS',
                description:
                    '4 arcos dark · Feed de insights · Premium oscuro',
                color: const Color(0xFF4B9EFF),
                icon: Icons.donut_large_rounded,
                routeName: RouteNames.hubModeloJ,
                isSelected: currentStyle == RouteNames.hubModeloJ,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'F — EJECUTIVO',
                description:
                    'Ring chart · Timeline de hitos · Penalidades · Board-room',
                color: const Color(0xFF084C8D),
                icon: Icons.business_center_rounded,
                routeName: RouteNames.hubModeloF,
                isSelected: currentStyle == RouteNames.hubModeloF,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'D — ANALYTICS',
                description:
                    'Navy oscuro · Donut + barra de distribución · Datos primero',
                color: const Color(0xFF1A7FE8),
                icon: Icons.analytics_rounded,
                routeName: RouteNames.hubModeloD,
                isSelected: currentStyle == RouteNames.hubModeloD,
                onSelect: onSelect,
              ),
              const SizedBox(height: 14),
              const StylePickerCategoryLabel(
                label: 'OPERATIVOS — Acceso directo & acción',
              ),
              const SizedBox(height: 8),
              StylePickerTile(
                label: 'H — COMMAND CENTER',
                description:
                    'Bottom nav · Quick actions · Swipe tabs · Campo operativo',
                color: const Color(0xFF0A66B7),
                icon: Icons.space_dashboard_rounded,
                routeName: RouteNames.hubModeloH,
                isSelected: currentStyle == RouteNames.hubModeloH,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'I — PULSE',
                description:
                    'Navy top + swipe cards de módulos · Híbrido gerencial-operativo',
                color: const Color(0xFF00C49A),
                icon: Icons.swipe_rounded,
                routeName: RouteNames.hubModeloI,
                isSelected: currentStyle == RouteNames.hubModeloI,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'E — CAMPO',
                description:
                    'Header naranja · Grid 2×2 acciones grandes · Alta visibilidad',
                color: const Color(0xFFE8941A),
                icon: Icons.construction_rounded,
                routeName: RouteNames.hubModeloE,
                isSelected: currentStyle == RouteNames.hubModeloE,
                onSelect: onSelect,
              ),
              const SizedBox(height: 14),
              const StylePickerCategoryLabel(
                label: 'MIXTOS — Balance info + acceso',
              ),
              const SizedBox(height: 8),
              StylePickerTile(
                label: 'A — DIREKTOR PRO',
                description:
                    'Wave header · KPIs flotantes · Tarjetas con acento lateral',
                color: const Color(0xFF0A66B7),
                icon: Icons.dashboard_rounded,
                routeName: RouteNames.hubModeloA,
                isSelected: currentStyle == RouteNames.hubModeloA,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'C — BREEZE',
                description:
                    'Minimalista · Pills de proyecto · Gráfico gerencial inline',
                color: const Color(0xFFF5A623),
                icon: Icons.view_stream_rounded,
                routeName: RouteNames.hubModeloC,
                isSelected: currentStyle == RouteNames.hubModeloC,
                onSelect: onSelect,
              ),
              const SizedBox(height: 14),
              const StylePickerCategoryLabel(label: 'NUEVOS — Iteración reciente'),
              const SizedBox(height: 8),
              StylePickerTile(
                label: 'O — VELVET',
                description:
                    'Ejecutivo oscuro · Teal profundo + violeta · CFO dashboard',
                color: const Color(0xFF005F73),
                icon: Icons.auto_awesome_rounded,
                routeName: RouteNames.hubModeloO,
                isSelected: currentStyle == RouteNames.hubModeloO,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'N — FIELDWORK',
                description:
                    'Dark earthy · Teal + coral · Supervisores de obra · Alto contraste',
                color: const Color(0xFF2A9D8F),
                icon: Icons.engineering_rounded,
                routeName: RouteNames.hubModeloN,
                isSelected: currentStyle == RouteNames.hubModeloN,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'M — ARCTIC',
                description:
                    'Scandinavian minimal · Ice blue + indigo · Enterprise SaaS',
                color: const Color(0xFF0891B2),
                icon: Icons.ac_unit_rounded,
                routeName: RouteNames.hubModeloM,
                isSelected: currentStyle == RouteNames.hubModeloM,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'K — BOTANICAL',
                description:
                    'Verde profundo + teal + púrpura · Nature = growth = progress',
                color: const Color(0xFF0F766E),
                icon: Icons.eco_rounded,
                routeName: RouteNames.hubModeloK,
                isSelected: currentStyle == RouteNames.hubModeloK,
                onSelect: onSelect,
              ),
              const SizedBox(height: 14),
              const StylePickerCategoryLabel(
                label: 'ESTILO LIBRE — Bosquejos creativos',
              ),
              const SizedBox(height: 8),
              StylePickerTile(
                label: 'V — VAPOR',
                description:
                    'Vaporwave · purple/pink/cyan glassmorphism · grid retrowave',
                color: const Color(0xFFFF2D78),
                icon: Icons.waves_rounded,
                routeName: RouteNames.hubModeloV,
                isSelected: currentStyle == RouteNames.hubModeloV,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'P — PRISM',
                description:
                    'Glassmorphism · gradient mesh · indigo violeta · iOS vibe',
                color: const Color(0xFF7B61FF),
                icon: Icons.lens_blur_rounded,
                routeName: RouteNames.hubModeloP,
                isSelected: currentStyle == RouteNames.hubModeloP,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'U — ULTRA',
                description:
                    'Tipografía dominante · números enormes · B&W + naranja',
                color: const Color(0xFFFF4D00),
                icon: Icons.format_size_rounded,
                routeName: RouteNames.hubModeloU,
                isSelected: currentStyle == RouteNames.hubModeloU,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'S — SOLAR',
                description:
                    'Sunset naranja → ámbar → gold · energía y acción',
                color: const Color(0xFFFF6B2B),
                icon: Icons.wb_sunny_rounded,
                routeName: RouteNames.hubModeloS,
                isSelected: currentStyle == RouteNames.hubModeloS,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'T — TIDE',
                description: 'Ocean blues · wave animations · calma y profundidad',
                color: const Color(0xFF0284C7),
                icon: Icons.water_rounded,
                routeName: RouteNames.hubModeloT,
                isSelected: currentStyle == RouteNames.hubModeloT,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'R — ROUGE',
                description:
                    'Crimson + gold · editorial lujo · Bloomberg/FT aesthetic',
                color: const Color(0xFFC0392B),
                icon: Icons.auto_stories_rounded,
                routeName: RouteNames.hubModeloR,
                isSelected: currentStyle == RouteNames.hubModeloR,
                onSelect: onSelect,
              ),
              const SizedBox(height: 6),
              StylePickerTile(
                label: 'Q — QUANTUM',
                description:
                    'Terminal hacker · monospace · neon verde · GitHub dark',
                color: const Color(0xFF39FF14),
                icon: Icons.terminal_rounded,
                routeName: RouteNames.hubModeloQ,
                isSelected: currentStyle == RouteNames.hubModeloQ,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────
class StylePickerTile extends StatelessWidget {
  const StylePickerTile({
    super.key,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.routeName,
    required this.isSelected,
    required this.onSelect,
  });

  final String label;
  final String description;
  final Color color;
  final IconData icon;
  final String? routeName;
  final bool isSelected;
  final void Function(String? route) onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(routeName),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF62748A),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20)
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF62748A),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Category label ────────────────────────────────────────────
class StylePickerCategoryLabel extends StatelessWidget {
  const StylePickerCategoryLabel({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF62748A),
        letterSpacing: 0.8,
      ),
    );
  }
}
