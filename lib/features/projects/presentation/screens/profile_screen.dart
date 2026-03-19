import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_scope.dart';
import '../../../../app/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final user = controller.user;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final surfaceColor = isDark ? const Color(0xFF16202B) : Colors.white;
        final titleColor = isDark ? Colors.white : AppTheme.text;
        final subtitleColor = isDark ? const Color(0xFFD7E1EC) : AppTheme.muted;

        return Scaffold(
          appBar: AppBar(title: const Text('Mi perfil')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Card(
                  color: surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.brandBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: AppTheme.brandBlue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName
                                    : 'Usuario',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '-',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  color: surfaceColor,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: controller.isDarkMode,
                        onChanged: controller.setDarkMode,
                        title: Text(
                          'Modo oscuro',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: titleColor,
                          ),
                        ),
                        subtitle: Text(
                          'Cambia el aspecto general de la app',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                        secondary: Icon(
                          Icons.dark_mode_outlined,
                          color: isDark ? Colors.white : AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesion'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
