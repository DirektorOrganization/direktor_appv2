import 'package:flutter/foundation.dart';

@immutable
abstract final class SyncRules {
  // Loop de empuje de cola pendiente.
  static const Duration pushLoopInterval = Duration(seconds: 30);

  // Loop que evalua si corresponde ejecutar operational.
  static const Duration operationalCheckInterval = Duration(minutes: 1);

  // Cadencia minima entre dos pulls operational.
  static const Duration operationalMinInterval = Duration(minutes: 30);

  // Ventana horaria (Lima) para sincronizaciones automaticas.
  static const int syncWindowStartHour = 6; // 06:00 inclusive
  static const int syncWindowEndHour = 19; // 19:00 exclusive

  // Regla para permitir full diario automatico.
  static const int dailyFullEarliestHour = 6; // 06:00 inclusive
}
