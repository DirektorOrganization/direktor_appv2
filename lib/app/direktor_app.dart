import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_defaults.dart';
import 'router.dart';
import 'routes/route_names.dart';
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
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _showingLocationDialog = false;
  StreamSubscription<Uri>? _deepLinkSubscription;
  Uri? _pendingDeepLink;
  String? _lastHandledDeepLink;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    unawaited(_initializeDeepLinks());
    _controller.ensureInitialized();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeDeepLinks() async {
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[DirektorApp][deeplink] stream error: $error');
        debugPrintStack(
          stackTrace: stackTrace,
          label: '[DirektorApp][deeplink] stack',
        );
      },
    );

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (error, stackTrace) {
      debugPrint('[DirektorApp][deeplink] initial link error: $error');
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[DirektorApp][deeplink] initial stack',
      );
    }
  }

  void _handleDeepLink(Uri uri) {
    final routeName = _resolveDeepLinkRoute(uri);
    if (routeName == null) {
      debugPrint('[DirektorApp][deeplink] ignored uri=$uri');
      return;
    }

    final deepLinkKey = uri.toString();
    if (_lastHandledDeepLink == deepLinkKey) {
      return;
    }
    _lastHandledDeepLink = deepLinkKey;
    _pendingDeepLink = uri;
    unawaited(_flushPendingDeepLink());
  }

  Future<void> _flushPendingDeepLink() async {
    if (!mounted) return;
    if (!_controller.isInitialized) {
      await _controller.ensureInitialized();
      if (!mounted) return;
    }

    final navigator = _navigatorKey.currentState;
    final uri = _pendingDeepLink;
    if (navigator == null || uri == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_flushPendingDeepLink()),
      );
      return;
    }

    final routeName = _resolveDeepLinkRoute(uri);
    if (routeName == null) {
      _pendingDeepLink = null;
      return;
    }

    _pendingDeepLink = null;
    debugPrint('[DirektorApp][deeplink] navigating uri=$uri route=$routeName');
    navigator.pushNamedAndRemoveUntil(routeName, (_) => false);
  }

  String? _resolveDeepLinkRoute(Uri uri) {
    if (uri.scheme.toLowerCase() != 'direktor') {
      return null;
    }

    final host = uri.host.trim().toLowerCase();
    final firstPathSegment = uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.first.trim().toLowerCase();
    final target = host.isNotEmpty ? host : firstPathSegment;

    switch (target) {
      case 'login':
        return _controller.hasActiveSession
            ? RouteNames.projects
            : RouteNames.login;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          _scheduleLocationGuidanceIfNeeded();
          _enforceLoginRedirect();
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Direktor',
            debugShowCheckedModeBanner: false,
            locale: appLocale,
            supportedLocales: const [appLocale, Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _controller.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRouter.initialRoute,
          );
        },
      ),
    );
  }

  /// Cuando el sync forzó logout (_runGuarded detectó 403 o suscripción
  /// revocada), asegura que el navegador quede en `RouteNames.login`.
  ///
  /// Lo hacemos vía `pushNamedAndRemoveUntil` para evitar quedarnos en una
  /// ruta intermedia cuando la app sigue foreground.
  void _enforceLoginRedirect() {
    if (!_controller.redirectToLoginRequested) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        return;
      }
      final currentRoute = ModalRoute.of(navigator.context)?.settings.name;
      if (currentRoute == RouteNames.login) {
        _controller.clearRedirectToLoginRequest();
        return;
      }
      debugPrint(
        '[DirektorApp] redirecting to login currentRoute=$currentRoute',
      );
      navigator.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
      _controller.clearRedirectToLoginRequest();
    });
  }

  void _scheduleLocationGuidanceIfNeeded() {
    final locationState = _controller.locationAccessState;
    if (_showingLocationDialog ||
        !_controller.shouldShowLocationGuidance ||
        locationState == null) {
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
          final title = isPermissionIssue
              ? 'Permite la ubicacion'
              : 'Activa el GPS';
          final body = isPermissionIssue
              ? 'Direktor necesita acceso a la ubicacion para adjuntar coordenadas en las actualizaciones. Te llevamos a la configuracion de la aplicacion para habilitarlo.'
              : 'Direktor ya tiene permiso de ubicacion, pero el GPS del telefono esta apagado. Activalo para que las actualizaciones se envien con coordenadas.';
          final actionLabel = isPermissionIssue
              ? 'Abrir permisos'
              : 'Abrir ubicacion';
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
