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
      child: MaterialApp(
        title: 'Direktor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.initialRoute,
      ),
    );
  }
}
