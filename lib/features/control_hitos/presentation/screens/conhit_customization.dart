// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';

import '../../../../app/state/app_controller.dart';

/// Column keys used for `CONHIT` personalization flows. They reuse the
/// `anares_restriction` column semantics so far; the backend can map any
/// `columna.nombreOriginal` it sends into the same key.
class ConHitColumns {
  ConHitColumns._();

  static const description = 'desDescripcion';
  static const type = 'codTipoHito';
  static const classification = 'codTipoClasificacion';
  static const days = 'numplazo';
  static const contractualDate = 'dayFechaContractual';
  static const targetDate = 'dayFechaMeta';
  static const actualDate = 'dayFechaReal';
  static const contractualStatus = 'codEstadoContractual';
  static const internalStatus = 'codEstadoInternos';
  static const responsible = 'idUsuarioResponsable';
  static const penaltyPercent = 'porPenalidad';
  static const consecutiveDays = 'numDiasPlazoTotal';
  static const totalAmount = 'mntTotal';
  static const controversyDays = 'numDias';
  static const startDate = 'dayFechaInicioContractual';
}

bool conhitColumnVisible(AppController controller, String columnKey) {
  return controller.isCustomizedColumnVisible('CONHITHIT', columnKey);
}

String conhitColumnLabel(
  AppController controller,
  String columnKey,
  String fallback,
) {
  return controller.customizedColumnLabel('CONHITHIT', columnKey, fallback);
}

String conhitStatusLabel(
  AppController controller,
  String baseStatusCode,
  String fallback,
) {
  return controller
          .customizedStatusByBaseCode('CONHITHIT', baseStatusCode)
          ?.label ??
      fallback;
}

Color conhitStatusColor(
  AppController controller,
  String baseStatusCode,
  Color fallback,
) {
  final hex = controller
      .customizedStatusByBaseCode('CONHITHIT', baseStatusCode)
      ?.colorHex;
  return _parseColorHex(hex) ?? fallback;
}

Color? _parseColorHex(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final normalized = value.replaceAll('#', '').trim();
  final argb = normalized.length == 6 ? 'FF$normalized' : normalized;
  if (argb.length != 8) {
    return null;
  }
  return Color(int.parse(argb, radix: 16));
}
