import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/state/app_controller.dart';
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
                                user?.fullName.isNotEmpty == true ? user!.fullName : 'Usuario',
                                style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '-',
                                style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
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
                  child: SwitchListTile(
                    value: controller.isDarkMode,
                    onChanged: controller.setDarkMode,
                    title: Text(
                      'Modo oscuro',
                      style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
                    ),
                    subtitle: Text(
                      'Cambia el aspecto general de la app',
                      style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
                    ),
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                      color: isDark ? Colors.white : AppTheme.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _DeviceBindingCard(
                  surfaceColor: surfaceColor,
                  titleColor: titleColor,
                  subtitleColor: subtitleColor,
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

class _DeviceBindingCard extends StatelessWidget {
  const _DeviceBindingCard({
    required this.surfaceColor,
    required this.titleColor,
    required this.subtitleColor,
  });

  final Color surfaceColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final linkedAt = controller.deviceLinkedAt;
    final linkedAtLabel = linkedAt == null
        ? 'Pendiente'
        : '${linkedAt.day.toString().padLeft(2, '0')}/${linkedAt.month.toString().padLeft(2, '0')}/${linkedAt.year}';

    return Card(
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  controller.isDeviceLinked ? Icons.phonelink_lock_rounded : Icons.phonelink_off_rounded,
                  color: controller.isDeviceLinked ? const Color(0xFF1B8E5A) : const Color(0xFFE4A620),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispositivo vinculado',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: titleColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.isDeviceLinked
                            ? 'Este equipo ya puede identificarse y generar QR dinamico.'
                            : 'Vincula este equipo para habilitar el QR unico de asistencia.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoLine(label: 'Estado', value: controller.isDeviceLinked ? 'Vinculado' : 'Sin vincular', valueColor: titleColor),
            _InfoLine(label: 'Equipo', value: controller.linkedDeviceLabel ?? '-', valueColor: titleColor),
            _InfoLine(label: 'Codigo', value: controller.linkedDeviceId ?? '-', valueColor: titleColor),
            _InfoLine(label: 'Vinculado', value: linkedAtLabel, valueColor: titleColor),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : () async {
                            if (controller.isDeviceLinked) {
                              await controller.unlinkCurrentDevice();
                            } else {
                              await controller.linkCurrentDevice();
                            }
                          },
                    icon: Icon(controller.isDeviceLinked ? Icons.link_off_rounded : Icons.link_rounded),
                    label: Text(controller.isDeviceLinked ? 'Desvincular equipo' : 'Vincular este equipo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: !controller.isDeviceLinked || controller.isBusy
                    ? null
                    : () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Theme.of(context).cardColor,
                          builder: (_) => const _AttendanceQrSheet(),
                        );
                      },
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Generar QR dinamico'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceQrSheet extends StatefulWidget {
  const _AttendanceQrSheet();

  @override
  State<_AttendanceQrSheet> createState() => _AttendanceQrSheetState();
}

class _AttendanceQrSheetState extends State<_AttendanceQrSheet> {
  Timer? _timer;
  bool _started = false;
  late AppController _controller;
  String? _qrData;
  DateTime? _expiresAt;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _controller = AppScope.of(context);
    _refreshQr();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refreshQr());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQr() async {
    final qrData = await _controller.buildAttendanceQrPayload();
    if (!mounted) return;
    setState(() {
      _qrData = qrData;
      _loading = false;
      _expiresAt = DateTime.now().add(const Duration(seconds: 45));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final qrForeground = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('QR dinamico de asistencia', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Este codigo identifica al usuario y al dispositivo vinculado. Se regenera automaticamente.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Center(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  : _qrData == null
                      ? const Text('Primero vincula este dispositivo.')
                      : Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111820) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: qrForeground,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: qrForeground,
                            ),
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            if (_expiresAt != null)
              Center(
                child: Text(
                  'Valido hasta ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}:${_expiresAt!.second.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _refreshQr,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Regenerar ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
