import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/notifications/notification_service.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../shared/widgets/direktor_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigated) return;
    _navigated = true;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final controller = AppScope.of(context);
    await controller.ensureInitialized();
    if (!mounted) return;
    await NotificationService.instance.requestPermissions();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      controller.hasActiveSession ? RouteNames.projects : RouteNames.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final loadingLabel = controller.isSyncing
            ? 'Sincronizando informacion...'
            : controller.isBusy
                ? 'Preparando datos del proyecto...'
                : 'Cargando...';

        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8FBFF), Color(0xFFEFF5FB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DirektorLogo(size: 132, showLabel: true),
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(loadingLabel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
