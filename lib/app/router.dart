import 'package:flutter/material.dart';

import '../features/analysis_restrictions/presentation/screens/completed_restrictions_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restriction_detail_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restriction_form_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restrictions_list_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/control_hitos/presentation/screens/control_hitos_screen.dart';
import '../features/control_hitos/presentation/screens/hito_detail_screen.dart';
import '../features/control_hitos/presentation/screens/hito_documents_screen.dart';
import '../features/control_hitos/presentation/screens/hito_extension_form_screen.dart';
import '../features/control_hitos/presentation/screens/hito_extensions_screen.dart';
import '../features/control_hitos/presentation/screens/hito_form_screen.dart';
import '../features/projects/presentation/screens/profile_screen.dart';
import '../features/projects/presentation/screens/projects_hub_screen.dart';
import '../features/shell/presentation/screens/splash_screen.dart';
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
          builder: (_) => const ProjectsHubScreen(),
          settings: settings,
        );
      case RouteNames.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case RouteNames.restrictionsList:
        return MaterialPageRoute(
          builder: (_) => const RestrictionsListScreen(),
          settings: settings,
        );
      case RouteNames.completedRestrictions:
        return MaterialPageRoute(
          builder: (_) => const CompletedRestrictionsScreen(),
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
      case RouteNames.controlHitos:
        return MaterialPageRoute(
          builder: (_) => const ControlHitosScreen(),
          settings: settings,
        );
      case RouteNames.controlHitosDetail:
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
