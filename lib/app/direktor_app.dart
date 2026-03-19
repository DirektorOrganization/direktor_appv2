import 'package:flutter/material.dart';

import 'router.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';
import 'theme/app_theme.dart';

class DirektorApp extends StatefulWidget {
  const DirektorApp({super.key});

  @override
  State<DirektorApp> createState() => _DirektorAppState();
}

class _DirektorAppState extends State<DirektorApp> {
  late final AppController _controller;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _showingLocationDialog = false;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _controller.ensureInitialized();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          _scheduleLocationGuidanceIfNeeded();
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Direktor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.initialRoute,
          );
        },
      ),
    );
  }

  void _scheduleLocationGuidanceIfNeeded() {
    final locationState = _controller.locationAccessState;
    if (_showingLocationDialog || !_controller.shouldShowLocationGuidance || locationState == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _navigatorKey.currentContext;
      if (context == null || !mounted || _showingLocationDialog) return;
      _showingLocationDialog = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final isPermissionIssue = locationState.needsPermissionGuidance;
          final title = isPermissionIssue ? 'Permite la ubicacion' : 'Activa el GPS';
          final body = isPermissionIssue
              ? 'Direktor necesita acceso a la ubicacion para adjuntar coordenadas en las actualizaciones. Te llevamos a la configuracion de la aplicacion para habilitarlo.'
              : 'Direktor ya tiene permiso de ubicacion, pero el GPS del telefono esta apagado. Activalo para que las actualizaciones se envien con coordenadas.';
          final actionLabel = isPermissionIssue ? 'Abrir permisos' : 'Abrir ubicacion';
          return AlertDialog(
            title: Text(title),
            content: Text(body, style: theme.textTheme.bodyMedium),
            actions: [
              TextButton(
                onPressed: () {
                  _controller.dismissLocationGuidance();
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _controller.openLocationGuidanceSettings();
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      );
      _showingLocationDialog = false;
      if (mounted) {
        _controller.dismissLocationGuidance();
      }
    });
  }
}
