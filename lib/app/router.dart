import 'package:flutter/material.dart';

import '../features/analysis_restrictions/presentation/screens/completed_restrictions_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restriction_detail_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restriction_form_screen.dart';
import '../features/analysis_restrictions/presentation/screens/restrictions_list_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/meetings/presentation/screens/meeting_tracking_screen.dart';
import '../features/meetings/presentation/screens/meetings_list_screen.dart';
import '../features/projects/presentation/screens/projects_hub_screen.dart';
import '../features/shell/presentation/screens/splash_screen.dart';
import 'routes/route_names.dart';

class AppRouter {
  static const String initialRoute = RouteNames.splash;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case RouteNames.projects:
        return MaterialPageRoute(builder: (_) => const ProjectsHubScreen(), settings: settings);
      case RouteNames.restrictionsList:
        return MaterialPageRoute(builder: (_) => const RestrictionsListScreen(), settings: settings);
      case RouteNames.completedRestrictions:
        return MaterialPageRoute(builder: (_) => const CompletedRestrictionsScreen(), settings: settings);
      case RouteNames.restrictionDetail:
        return MaterialPageRoute(builder: (_) => const RestrictionDetailScreen(), settings: settings);
      case RouteNames.restrictionCreate:
        return MaterialPageRoute(builder: (_) => const RestrictionFormScreen(title: 'Nueva Restriccion'), settings: settings);
      case RouteNames.restrictionEdit:
        return MaterialPageRoute(builder: (_) => const RestrictionFormScreen(title: 'Editar Restriccion'), settings: settings);
      case RouteNames.meetingsList:
        return MaterialPageRoute(builder: (_) => const MeetingsListScreen(), settings: settings);
      case RouteNames.meetingTracking:
        return MaterialPageRoute(builder: (_) => const MeetingTrackingScreen(), settings: settings);
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(body: Center(child: Text('Ruta no encontrada: ${settings.name}'))),
          settings: settings,
        );
    }
  }
}
