// ============================================================
// NOTIFICATION SERVICE — Direktor App
// Heads-up notifications (estilo WhatsApp) con vibración.
// Sólo se disparan dentro de la ventana del sync operacional.
// ============================================================

import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId    = 'direktor_alerts';
  static const _channelName  = 'Alertas Direktor';
  static const _channelDesc  = 'Cambios de estado en restricciones y acuerdos de reunión';

  final _plugin = FlutterLocalNotificationsPlugin();
  int _nextId = 0;
  bool _initialized = false;

  // ── Inicialización ──────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    await _ensureAndroidChannel();
    _initialized = true;
  }

  Future<void> _ensureAndroidChannel() async {
    final vibrationPattern = Int64List.fromList([0, 300, 200, 300]);
    final channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Permisos ────────────────────────────────────────────────
  /// Solicita permisos en Android 13+ e iOS. Retorna true si concedidos.
  Future<bool> requestPermissions() async {
    // Android 13+ (API 33)
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission() ?? true;

    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted;
  }

  // ── Mostrar notificación ────────────────────────────────────
  Future<void> showAlert({
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    final id = _nextId++;
    final vibrationPattern = Int64List.fromList([0, 300, 200, 300]);
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          // BigText style: muestra el cuerpo completo al expandir
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Cancelar todas ──────────────────────────────────────────
  Future<void> cancelAll() async => _plugin.cancelAll();
}
