import 'package:flutter/material.dart';

import '../../../../app/state/app_scope.dart';
import '../../../../data/models/app_models.dart';
import 'insights_module_screen.dart';

class InsightsEntryGateScreen extends StatelessWidget {
  const InsightsEntryGateScreen({
    super.key,
    required this.module,
    required this.moduleBuilder,
  });

  final ModuleInsightModule module;
  final WidgetBuilder moduleBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.shouldShowInsights(module)) {
          return InsightsModuleScreen(
            module: module,
            moduleBuilder: moduleBuilder,
          );
        }
        return moduleBuilder(context);
      },
    );
  }
}
