import 'package:flutter/material.dart';

import '../features/analysis_restrictions/presentation/screens/restriction_detail_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restriction_form_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/graphic_progress/presentation/screens/avance_grafico_screen.dart';
import '../features/graphic_progress/presentation/screens/avance_grafico_campo_screen.dart';
import '../features/graphic_progress/presentation/screens/avance_grafico_resumen_screen.dart';
import '../features/graphic_progress/presentation/screens/avance_grafico_tablero_screen.dart';
import '../features/control_hitos/presentation/screens/hito_detail_screen.dart';
import '../features/control_hitos/presentation/screens/option_v7/hv7_screen.dart';
import '../features/analysis_restrictions/presentation/screens/option_v2/rv2_tablero_screen.dart';
import '../features/control_hitos/presentation/screens/hito_documents_screen.dart';
import '../features/control_hitos/presentation/screens/hito_extension_form_screen.dart';
import '../features/control_hitos/presentation/screens/hito_extensions_screen.dart';
import '../features/control_hitos/presentation/screens/hito_form_screen.dart';
import '../features/insights/presentation/screens/insights_entry_gate_screen.dart';
import '../features/meetings/presentation/screens/option9/o9_hub_screen.dart';
import '../features/projects/presentation/screens/hub_default_screen.dart';
import '../features/projects/presentation/screens/indicator_manager_screen.dart';
import '../features/projects/presentation/screens/hub_modelo_a.dart';
import '../features/projects/presentation/screens/hub_modelo_c.dart';
import '../features/projects/presentation/screens/hub_modelo_d.dart';
import '../features/projects/presentation/screens/hub_modelo_e.dart';
import '../features/projects/presentation/screens/hub_modelo_f.dart';
import '../features/projects/presentation/screens/hub_modelo_g.dart';
import '../features/projects/presentation/screens/hub_modelo_h.dart';
import '../features/projects/presentation/screens/hub_modelo_i.dart';
import '../features/projects/presentation/screens/hub_modelo_j.dart';
import '../features/projects/presentation/screens/hub_modelo_k.dart';
import '../features/projects/presentation/screens/hub_modelo_m.dart';
import '../features/projects/presentation/screens/hub_modelo_n.dart';
import '../features/projects/presentation/screens/hub_modelo_o.dart';
import '../features/projects/presentation/screens/hub_modelo_p.dart';
import '../features/projects/presentation/screens/hub_modelo_q.dart';
import '../features/projects/presentation/screens/hub_modelo_r.dart';
import '../features/projects/presentation/screens/hub_modelo_s.dart';
import '../features/projects/presentation/screens/hub_modelo_t.dart';
import '../features/projects/presentation/screens/hub_modelo_u.dart';
import '../features/projects/presentation/screens/hub_modelo_v.dart';
import '../features/projects/presentation/screens/profile_screen.dart';
import '../features/shell/presentation/screens/splash_screen.dart';
import '../data/models/app_models.dart';
import 'routes/route_arguments.dart';
import 'routes/route_names.dart';

class AppRouter {
  static const String initialRoute = RouteNames.splash;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case RouteNames.projects:
        return MaterialPageRoute(
          builder: (_) => const HubDefaultScreen(),
          settings: settings,
        );
      case RouteNames.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case RouteNames.restrictionsList:
      case RouteNames.completedRestrictions:
        return MaterialPageRoute(
          builder: (_) => InsightsEntryGateScreen(
            module: ModuleInsightModule.restrictions,
            moduleBuilder: (_) => const Rv2TableroScreen(),
          ),
          settings: settings,
        );
      case RouteNames.restrictionDetail:
        final args = settings.arguments as RestrictionDetailArgs;
        return MaterialPageRoute(
          builder: (_) =>
              RestrictionDetailScreen(restrictionId: args.restrictionId),
          settings: settings,
        );
      case RouteNames.restrictionCreate:
        return MaterialPageRoute(
          builder: (_) => const RestrictionFormScreen(
            title: 'Nueva Restriccion',
            args: RestrictionFormArgs(),
          ),
          settings: settings,
        );
      case RouteNames.restrictionEdit:
        final args = settings.arguments as RestrictionFormArgs;
        return MaterialPageRoute(
          builder: (_) =>
              RestrictionFormScreen(title: 'Editar Restriccion', args: args),
          settings: settings,
        );
      case RouteNames.avanceGrafico:
        return MaterialPageRoute(
          builder: (_) => const AvanceGraficoScreen(),
          settings: settings,
        );
      case RouteNames.avanceGraficoResumen:
        return MaterialPageRoute(
          builder: (_) => const AvanceGraficoResumenScreen(),
          settings: settings,
        );
      case RouteNames.avanceGraficoCampo:
        final initialTab = settings.arguments is int ? settings.arguments as int : 0;
        return MaterialPageRoute(
          builder: (_) => AvanceGraficoCampoScreen(initialTab: initialTab),
          settings: settings,
        );
      case RouteNames.avanceGraficoTablero:
        return MaterialPageRoute(
          builder: (_) => const AvanceGraficoTableroScreen(),
          settings: settings,
        );
      case RouteNames.controlHitos:
        return MaterialPageRoute(
          builder: (_) => const Hv7Screen(),
          settings: settings,
        );
      case RouteNames.actaReuniones:
        return MaterialPageRoute(
          builder: (_) => InsightsEntryGateScreen(
            module: ModuleInsightModule.actaReuniones,
            moduleBuilder: (_) => const O9HubScreen(),
          ),
          settings: settings,
        );
      case RouteNames.controlHitosDetail:
      case RouteNames.controlHitosV2Detail:
        final args = settings.arguments as MilestoneDetailArgs;
        return MaterialPageRoute(
          builder: (_) => HitoDetailScreen(milestoneId: args.milestoneId),
          settings: settings,
        );
      case RouteNames.controlHitosCreate:
        return MaterialPageRoute(
          builder: (_) => const HitoFormScreen(title: 'Nuevo Hito'),
          settings: settings,
        );
      case RouteNames.controlHitosEdit:
        final args = settings.arguments as MilestoneFormArgs;
        return MaterialPageRoute(
          builder: (_) => HitoFormScreen(
            title: 'Editar Hito',
            milestoneId: args.milestoneId,
          ),
          settings: settings,
        );
      case RouteNames.controlHitosDocuments:
        final args = settings.arguments as MilestoneDocumentsArgs;
        return MaterialPageRoute(
          builder: (_) => HitoDocumentsScreen(milestoneId: args.milestoneId),
          settings: settings,
        );
      case RouteNames.controlHitosExtensions:
        final args = settings.arguments as MilestoneExtensionsArgs;
        return MaterialPageRoute(
          builder: (_) => HitoExtensionsScreen(milestoneId: args.milestoneId),
          settings: settings,
        );
      case RouteNames.controlHitosExtensionCreate:
        final args = settings.arguments as MilestoneExtensionFormArgs;
        return MaterialPageRoute(
          builder: (_) =>
              HitoExtensionFormScreen(milestoneId: args.milestoneId),
          settings: settings,
        );
      case RouteNames.indicatorManager:
        return MaterialPageRoute(
          builder: (_) => const IndicatorManagerScreen(),
          settings: settings,
        );
      // ── Vista por Defecto ─────────────────────────────────
      case RouteNames.hubDefault:
        return MaterialPageRoute(
          builder: (_) => const HubDefaultScreen(),
          settings: settings,
        );
      // ── Rediseños ─────────────────────────────────────────
      case RouteNames.hubModeloA:
        return MaterialPageRoute(
          builder: (_) => const HubModeloA(),
          settings: settings,
        );
      case RouteNames.hubModeloC:
        return MaterialPageRoute(
          builder: (_) => const HubModeloC(),
          settings: settings,
        );
      case RouteNames.hubModeloD:
        return MaterialPageRoute(
          builder: (_) => const HubModeloD(),
          settings: settings,
        );
      case RouteNames.hubModeloE:
        return MaterialPageRoute(
          builder: (_) => const HubModeloE(),
          settings: settings,
        );
      case RouteNames.hubModeloF:
        return MaterialPageRoute(
          builder: (_) => const HubModeloF(),
          settings: settings,
        );
      case RouteNames.hubModeloG:
        return MaterialPageRoute(
          builder: (_) => const HubModeloG(),
          settings: settings,
        );
      case RouteNames.hubModeloH:
        return MaterialPageRoute(
          builder: (_) => const HubModeloH(),
          settings: settings,
        );
      case RouteNames.hubModeloI:
        return MaterialPageRoute(
          builder: (_) => const HubModeloI(),
          settings: settings,
        );
      case RouteNames.hubModeloJ:
        return MaterialPageRoute(
          builder: (_) => const HubModeloJ(),
          settings: settings,
        );
      case RouteNames.hubModeloK:
        return MaterialPageRoute(
          builder: (_) => const HubModeloK(),
          settings: settings,
        );
      case RouteNames.hubModeloM:
        return MaterialPageRoute(
          builder: (_) => const HubModeloM(),
          settings: settings,
        );
      case RouteNames.hubModeloN:
        return MaterialPageRoute(
          builder: (_) => const HubModeloN(),
          settings: settings,
        );
      case RouteNames.hubModeloO:
        return MaterialPageRoute(
          builder: (_) => const HubModeloO(),
          settings: settings,
        );
      case RouteNames.hubModeloP:
        return MaterialPageRoute(
          builder: (_) => const HubModeloP(),
          settings: settings,
        );
      case RouteNames.hubModeloQ:
        return MaterialPageRoute(
          builder: (_) => const HubModeloQ(),
          settings: settings,
        );
      case RouteNames.hubModeloR:
        return MaterialPageRoute(
          builder: (_) => const HubModeloR(),
          settings: settings,
        );
      case RouteNames.hubModeloS:
        return MaterialPageRoute(
          builder: (_) => const HubModeloS(),
          settings: settings,
        );
      case RouteNames.hubModeloT:
        return MaterialPageRoute(
          builder: (_) => const HubModeloT(),
          settings: settings,
        );
      case RouteNames.hubModeloU:
        return MaterialPageRoute(
          builder: (_) => const HubModeloU(),
          settings: settings,
        );
      case RouteNames.hubModeloV:
        return MaterialPageRoute(
          builder: (_) => const HubModeloV(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }
}
