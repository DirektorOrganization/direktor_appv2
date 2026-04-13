import 'package:flutter/foundation.dart';

@immutable
abstract final class SyncRules {
  // Loop de empuje de cola pendiente.
  static const Duration pushLoopInterval = Duration(seconds: 5);

  // Loop que evalua si corresponde ejecutar operational.
  static const Duration operationalCheckInterval = Duration(minutes: 1);

  // Cadencia minima entre dos pulls operational.
  static const Duration operationalMinInterval = Duration(minutes: 5);

  // Cursor `since` con solape para evitar perder registros en bordes de tiempo.
  static const bool enableSinceOverlap = true;
  static const Duration sinceOverlapDuration = Duration(minutes: 3);

  // Ventana horaria (Lima) para sincronizaciones automaticas.
  static const int syncWindowStartHour = 7; // 02:00 inclusive
  static const int syncWindowEndHour = 19; // 19:00 exclusive

  // Regla para permitir full diario automatico.
  static const int dailyFullEarliestHour = 6; // 06:00 inclusive

  // Al recuperar conectividad, intenta empujar cola pendiente inmediatamente.
  static const bool pushOnReconnectEnabled = true;

  // Al recuperar conectividad, intenta un operational inmediato (sin esperar
  // operationalMinInterval).
  static const bool operationalOnReconnectEnabled = true;

  // Si operationalOnReconnectEnabled = true, define si respeta la ventana
  // horaria operacional (syncWindowStartHour/syncWindowEndHour).
  static const bool reconnectOperationalRespectsWindow = true;
}
