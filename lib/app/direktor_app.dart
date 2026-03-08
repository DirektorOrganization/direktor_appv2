import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class DirektorApp extends StatelessWidget {
  const DirektorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Direktor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
    );
  }
}
