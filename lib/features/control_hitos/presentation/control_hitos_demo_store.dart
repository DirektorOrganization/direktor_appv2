import 'package:flutter/material.dart';

export '../../../data/models/app_models.dart';

class MilestoneStatusOption {
  const MilestoneStatusOption({required this.code, required this.label});

  final String code;
  final String label;
}

abstract final class ControlHitosDemoStore {
  static List<MilestoneStatusOption> get statusOptions => const [
        MilestoneStatusOption(code: '1', label: 'En progreso'),
        MilestoneStatusOption(code: '2', label: 'Retrasado'),
        MilestoneStatusOption(code: '3', label: 'Completado'),
      ];

  static List<String> get typeOptions => const ['Entregable', 'Hito de obra', 'Prueba', 'Administrativo'];
  static List<String> get classificationOptions => const ['Contractual', 'Critico', 'Calidad', 'Administrativo'];

  static String typeLabelForCode(String? code) {
    switch (code) {
      case '1':
        return 'Entregable';
      case '2':
        return 'Hito de obra';
      case '3':
        return 'Prueba';
      case '4':
        return 'Administrativo';
      default:
        return 'Hito';
    }
  }

  static String classificationLabelForCode(String? code) {
    switch (code) {
      case '1':
        return 'Contractual';
      case '2':
        return 'Critico';
      case '3':
        return 'Calidad';
      case '4':
        return 'Administrativo';
      default:
        return 'General';
    }
  }

  static String typeCodeForLabel(String? label) {
    switch (label) {
      case 'Entregable':
        return '1';
      case 'Hito de obra':
        return '2';
      case 'Prueba':
        return '3';
      case 'Administrativo':
        return '4';
      default:
        return '1';
    }
  }

  static String classificationCodeForLabel(String? label) {
    switch (label) {
      case 'Contractual':
        return '1';
      case 'Critico':
        return '2';
      case 'Calidad':
        return '3';
      case 'Administrativo':
        return '4';
      default:
        return '1';
    }
  }
}

Color milestoneStatusColor(String statusCode) {
  switch (statusCode) {
    case '3':
    case 'completed':
      return const Color(0xFF1B8E5A);
    case '2':
    case 'delayed':
      return const Color(0xFFD64545);
    default:
      return const Color(0xFFF0A11E);
  }
}

IconData milestoneStatusIcon(String statusCode) {
  switch (statusCode) {
    case '3':
    case 'completed':
      return Icons.check_circle_rounded;
    case '2':
    case 'delayed':
      return Icons.warning_amber_rounded;
    default:
      return Icons.timelapse_rounded;
  }
}
