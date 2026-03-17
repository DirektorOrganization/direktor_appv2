import 'package:flutter/material.dart';

class MilestoneDocumentRecord {
  const MilestoneDocumentRecord({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  final int id;
  final String name;
  final String typeLabel;
  final DateTime uploadedAt;
  final String uploadedBy;
}

class MilestoneExtensionRecord {
  const MilestoneExtensionRecord({
    required this.id,
    required this.title,
    required this.justification,
    required this.previousTargetDate,
    required this.newTargetDate,
    required this.requestedAt,
    required this.approvedBy,
    required this.statusLabel,
    required this.supportDocument,
  });

  final int id;
  final String title;
  final String justification;
  final DateTime previousTargetDate;
  final DateTime newTargetDate;
  final DateTime requestedAt;
  final String approvedBy;
  final String statusLabel;
  final String supportDocument;
}

class MilestoneRecord {
  const MilestoneRecord({
    required this.id,
    required this.projectId,
    required this.code,
    required this.description,
    required this.typeLabel,
    required this.classificationLabel,
    required this.contractualDate,
    required this.targetDate,
    required this.actualDate,
    required this.statusCode,
    required this.statusLabel,
    required this.isPenalizable,
    required this.penaltyPercent,
    required this.penaltyAmount,
    required this.responsible,
    required this.contractAmount,
    required this.isSynced,
    required this.extensions,
    required this.documents,
    required this.notes,
  });

  final int id;
  final int projectId;
  final String code;
  final String description;
  final String typeLabel;
  final String classificationLabel;
  final DateTime contractualDate;
  final DateTime targetDate;
  final DateTime? actualDate;
  final String statusCode;
  final String statusLabel;
  final bool isPenalizable;
  final double penaltyPercent;
  final double penaltyAmount;
  final String responsible;
  final double contractAmount;
  final bool isSynced;
  final List<MilestoneExtensionRecord> extensions;
  final List<MilestoneDocumentRecord> documents;
  final String notes;

  bool get isCompleted => statusCode == 'completed';
  bool get isDelayed => statusCode == 'delayed';
  bool get isInProgress => statusCode == 'in_progress';
  int get extensionCount => extensions.length;
  DateTime get effectiveTargetDate => extensions.isEmpty ? targetDate : extensions.last.newTargetDate;
  int get delayDays {
    final comparisonDate = actualDate ?? DateTime.now();
    final diff = comparisonDate.difference(effectiveTargetDate).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class MilestoneDashboardSummary {
  const MilestoneDashboardSummary({
    required this.compliance,
    required this.completedCount,
    required this.inProgressCount,
    required this.delayedCount,
    required this.activeDelayCount,
    required this.accumulatedPenalty,
    required this.potentialPenalty,
    required this.activeExtensions,
  });

  final double compliance;
  final int completedCount;
  final int inProgressCount;
  final int delayedCount;
  final int activeDelayCount;
  final double accumulatedPenalty;
  final double potentialPenalty;
  final int activeExtensions;
}

class MilestoneGeneralRecord {
  const MilestoneGeneralRecord({
    required this.projectId,
    required this.startDate,
    required this.totalDays,
    required this.totalAmount,
  });

  final int projectId;
  final DateTime startDate;
  final int totalDays;
  final double totalAmount;
}

class MilestoneStatusOption {
  const MilestoneStatusOption({required this.code, required this.label});

  final String code;
  final String label;
}

abstract final class ControlHitosDemoStore {
  static final List<MilestoneRecord> _records = [
    MilestoneRecord(
      id: 202603160001,
      projectId: 76,
      code: 'HT-001',
      description: 'Entrega de expediente tecnico definitivo',
      typeLabel: 'Entregable',
      classificationLabel: 'Contractual',
      contractualDate: DateTime(2026, 3, 5),
      targetDate: DateTime(2026, 3, 12),
      actualDate: DateTime(2026, 3, 11),
      statusCode: 'completed',
      statusLabel: 'Completado',
      isPenalizable: true,
      penaltyPercent: 0.0125,
      penaltyAmount: 1250,
      responsible: 'Consorcio Delta',
      contractAmount: 125000,
      isSynced: true,
      documents: [
        MilestoneDocumentRecord(
          id: 1,
          name: 'expediente-tecnico-vfinal.pdf',
          typeLabel: 'Entregable',
          uploadedAt: DateTime(2026, 3, 11, 9, 10),
          uploadedBy: 'Ana Romero',
        ),
      ],
      extensions: [],
      notes: 'Cierre validado por supervision. No genero penalidad por entrega anticipada.',
    ),
    MilestoneRecord(
      id: 202603160002,
      projectId: 76,
      code: 'HT-002',
      description: 'Inicio de montaje electromecanico de nave principal',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Critico',
      contractualDate: DateTime(2026, 3, 9),
      targetDate: DateTime(2026, 3, 15),
      actualDate: null,
      statusCode: 'in_progress',
      statusLabel: 'En progreso',
      isPenalizable: true,
      penaltyPercent: 0.015,
      penaltyAmount: 2480,
      responsible: 'Consorcio Delta',
      contractAmount: 165300,
      isSynced: true,
      documents: [
        MilestoneDocumentRecord(
          id: 2,
          name: 'acta-inicio-montaje.pdf',
          typeLabel: 'Acta',
          uploadedAt: DateTime(2026, 3, 14, 16, 45),
          uploadedBy: 'Luis Prada',
        ),
      ],
      extensions: [
        MilestoneExtensionRecord(
          id: 10,
          title: 'Ampliacion por reprogramacion de suministro',
          justification: 'El proveedor principal confirmo un desfase logistico de 72 horas.',
          previousTargetDate: DateTime(2026, 3, 15),
          newTargetDate: DateTime(2026, 3, 18),
          requestedAt: DateTime(2026, 3, 13, 11, 30),
          approvedBy: 'Jefatura de Proyecto',
          statusLabel: 'Aprobada',
          supportDocument: 'sustento-ampliacion-logistica.pdf',
        ),
      ],
      notes: 'Se mantiene en seguimiento diario por impacto en ruta critica.',
    ),
    MilestoneRecord(
      id: 202603160003,
      projectId: 76,
      code: 'HT-003',
      description: 'Pruebas SAT del sistema de climatizacion',
      typeLabel: 'Prueba',
      classificationLabel: 'Calidad',
      contractualDate: DateTime(2026, 3, 8),
      targetDate: DateTime(2026, 3, 10),
      actualDate: null,
      statusCode: 'delayed',
      statusLabel: 'Retrasado',
      isPenalizable: true,
      penaltyPercent: 0.02,
      penaltyAmount: 3900,
      responsible: 'HVAC Integraciones SAC',
      contractAmount: 195000,
      isSynced: false,
      documents: [
        MilestoneDocumentRecord(
          id: 3,
          name: 'reporte-no-conformidad-sat.pdf',
          typeLabel: 'Sustento',
          uploadedAt: DateTime(2026, 3, 12, 10, 00),
          uploadedBy: 'Marcos Ruiz',
        ),
      ],
      extensions: [],
      notes: 'Pendiente reprogramar con comisionamiento. Genera penalidad potencial.',
    ),
    MilestoneRecord(
      id: 202603160005,
      projectId: 76,
      code: 'HT-005',
      description: 'Movimiento de tierras',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Contractual',
      contractualDate: DateTime(2026, 2, 10),
      targetDate: DateTime(2026, 2, 15),
      actualDate: DateTime(2026, 2, 15),
      statusCode: 'completed',
      statusLabel: 'Completado',
      isPenalizable: false,
      penaltyPercent: 0,
      penaltyAmount: 0,
      responsible: 'Consorcio Delta',
      contractAmount: 98000,
      isSynced: true,
      documents: [],
      extensions: [],
      notes: 'Primer hito completado sin desviaciones.',
    ),
    MilestoneRecord(
      id: 202603160006,
      projectId: 76,
      code: 'HT-006',
      description: 'Cimentacion nave principal',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Critico',
      contractualDate: DateTime(2026, 2, 20),
      targetDate: DateTime(2026, 3, 2),
      actualDate: null,
      statusCode: 'in_progress',
      statusLabel: 'En progreso',
      isPenalizable: true,
      penaltyPercent: 0.012,
      penaltyAmount: 2100,
      responsible: 'Consorcio Delta',
      contractAmount: 175000,
      isSynced: true,
      documents: [],
      extensions: [
        MilestoneExtensionRecord(
          id: 11,
          title: 'Ampliacion por interferencia de redes',
          justification: 'Se detectaron interferencias no previstas en campo.',
          previousTargetDate: DateTime(2026, 3, 2),
          newTargetDate: DateTime(2026, 3, 6),
          requestedAt: DateTime(2026, 3, 1, 9, 00),
          approvedBy: 'Jefatura de Proyecto',
          statusLabel: 'Aprobada',
          supportDocument: 'ampliacion-redes.pdf',
        ),
      ],
      notes: 'Hito critico con ampliacion ya aprobada.',
    ),
    MilestoneRecord(
      id: 202603160007,
      projectId: 76,
      code: 'HT-007',
      description: 'Estructura metalica sector A',
      typeLabel: 'Entregable',
      classificationLabel: 'Critico',
      contractualDate: DateTime(2026, 3, 3),
      targetDate: DateTime(2026, 3, 18),
      actualDate: null,
      statusCode: 'delayed',
      statusLabel: 'Retrasado',
      isPenalizable: true,
      penaltyPercent: 0.025,
      penaltyAmount: 5812,
      responsible: 'Metalworks SAC',
      contractAmount: 232500,
      isSynced: true,
      documents: [],
      extensions: [
        MilestoneExtensionRecord(
          id: 12,
          title: 'Ampliacion por cambio de ingenieria',
          justification: 'Se recalculo la modulacion del sector A.',
          previousTargetDate: DateTime(2026, 3, 18),
          newTargetDate: DateTime(2026, 3, 22),
          requestedAt: DateTime(2026, 3, 16, 14, 10),
          approvedBy: 'Gerencia de Proyecto',
          statusLabel: 'En revision',
          supportDocument: 'cambio-ingenieria.pdf',
        ),
      ],
      notes: 'Retraso visible en ruta critica.',
    ),
    MilestoneRecord(
      id: 202603160008,
      projectId: 76,
      code: 'HT-008',
      description: 'Instalacion sanitaria torre A',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Calidad',
      contractualDate: DateTime(2026, 3, 12),
      targetDate: DateTime(2026, 3, 30),
      actualDate: null,
      statusCode: 'in_progress',
      statusLabel: 'En progreso',
      isPenalizable: true,
      penaltyPercent: 0.010,
      penaltyAmount: 1600,
      responsible: 'Sanipro',
      contractAmount: 160000,
      isSynced: false,
      documents: [],
      extensions: [],
      notes: 'Avance parcial por sectores.',
    ),
    MilestoneRecord(
      id: 202603160009,
      projectId: 76,
      code: 'HT-009',
      description: 'Acabados torre A',
      typeLabel: 'Entregable',
      classificationLabel: 'Administrativo',
      contractualDate: DateTime(2026, 3, 14),
      targetDate: DateTime(2026, 4, 10),
      actualDate: null,
      statusCode: 'in_progress',
      statusLabel: 'En progreso',
      isPenalizable: false,
      penaltyPercent: 0,
      penaltyAmount: 0,
      responsible: 'Acabados Prime',
      contractAmount: 142000,
      isSynced: false,
      documents: [],
      extensions: [],
      notes: 'Hito con avance estable.',
    ),
    MilestoneRecord(
      id: 202603160010,
      projectId: 76,
      code: 'HT-010',
      description: 'Entrega de dossier de calidad',
      typeLabel: 'Entregable',
      classificationLabel: 'Calidad',
      contractualDate: DateTime(2026, 3, 1),
      targetDate: DateTime(2026, 3, 8),
      actualDate: null,
      statusCode: 'delayed',
      statusLabel: 'Retrasado',
      isPenalizable: true,
      penaltyPercent: 0.008,
      penaltyAmount: 950,
      responsible: 'QA Bureau',
      contractAmount: 118750,
      isSynced: false,
      documents: [],
      extensions: [],
      notes: 'Pendiente conformidad final del proveedor.',
    ),
    MilestoneRecord(
      id: 202603160004,
      projectId: 1,
      code: 'HT-004',
      description: 'Entrega de matriz de riesgos contractual',
      typeLabel: 'Entregable',
      classificationLabel: 'Administrativo',
      contractualDate: DateTime(2026, 3, 7),
      targetDate: DateTime(2026, 3, 9),
      actualDate: DateTime(2026, 3, 9),
      statusCode: 'completed',
      statusLabel: 'Completado',
      isPenalizable: false,
      penaltyPercent: 0,
      penaltyAmount: 0,
      responsible: 'Oficina Tecnica',
      contractAmount: 78000,
      isSynced: false,
      documents: [
        MilestoneDocumentRecord(
          id: 4,
          name: 'matriz-riesgos.xlsx',
          typeLabel: 'Anexo',
          uploadedAt: DateTime(2026, 3, 9, 8, 25),
          uploadedBy: 'Milagros Leon',
        ),
      ],
      extensions: [],
      notes: 'Documento compartido con el cliente y validado el mismo dia.',
    ),
    MilestoneRecord(
      id: 202603160011,
      projectId: 1,
      code: 'HT-011',
      description: 'Liberacion de frente logistico',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Contractual',
      contractualDate: DateTime(2026, 2, 8),
      targetDate: DateTime(2026, 2, 15),
      actualDate: DateTime(2026, 2, 16),
      statusCode: 'completed',
      statusLabel: 'Completado',
      isPenalizable: true,
      penaltyPercent: 0.005,
      penaltyAmount: 320,
      responsible: 'Oficina Tecnica',
      contractAmount: 64000,
      isSynced: true,
      documents: [],
      extensions: [],
      notes: 'Liberacion concluida con un dia de desfase.',
    ),
    MilestoneRecord(
      id: 202603160012,
      projectId: 1,
      code: 'HT-012',
      description: 'Cimentacion de plataforma norte',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Critico',
      contractualDate: DateTime(2026, 2, 18),
      targetDate: DateTime(2026, 3, 5),
      actualDate: null,
      statusCode: 'in_progress',
      statusLabel: 'En progreso',
      isPenalizable: true,
      penaltyPercent: 0.012,
      penaltyAmount: 1860,
      responsible: 'Consorcio Base',
      contractAmount: 155000,
      isSynced: true,
      documents: [],
      extensions: [
        MilestoneExtensionRecord(
          id: 13,
          title: 'Ampliacion por interferencias de terreno',
          justification: 'El frente norte tuvo interferencias no liberadas.',
          previousTargetDate: DateTime(2026, 3, 5),
          newTargetDate: DateTime(2026, 3, 8),
          requestedAt: DateTime(2026, 3, 4, 10, 30),
          approvedBy: 'Jefatura',
          statusLabel: 'Aprobada',
          supportDocument: 'interferencias-terreno.pdf',
        ),
      ],
      notes: 'Avance sostenido con ampliacion contractual.',
    ),
    MilestoneRecord(
      id: 202603160013,
      projectId: 1,
      code: 'HT-013',
      description: 'Montaje de cobertura ligera',
      typeLabel: 'Entregable',
      classificationLabel: 'Critico',
      contractualDate: DateTime(2026, 3, 1),
      targetDate: DateTime(2026, 3, 18),
      actualDate: null,
      statusCode: 'delayed',
      statusLabel: 'Retrasado',
      isPenalizable: true,
      penaltyPercent: 0.018,
      penaltyAmount: 2400,
      responsible: 'Coberturas SAC',
      contractAmount: 133000,
      isSynced: false,
      documents: [],
      extensions: [],
      notes: 'Retraso por reprogramacion del proveedor.',
    ),
    MilestoneRecord(
      id: 202603160014,
      projectId: 1,
      code: 'HT-014',
      description: 'Instalacion electrica de patio',
      typeLabel: 'Hito de obra',
      classificationLabel: 'Calidad',
      contractualDate: DateTime(2026, 3, 10),
      targetDate: DateTime(2026, 3, 24),
      actualDate: null,
      statusCode: 'in_progress',
      statusLabel: 'En progreso',
      isPenalizable: false,
      penaltyPercent: 0,
      penaltyAmount: 0,
      responsible: 'Electro Red',
      contractAmount: 89000,
      isSynced: false,
      documents: [],
      extensions: [],
      notes: 'Trabajo por sectores con cuadrillas paralelas.',
    ),
    MilestoneRecord(
      id: 202603160015,
      projectId: 1,
      code: 'HT-015',
      description: 'Entrega de dossier de cierre parcial',
      typeLabel: 'Entregable',
      classificationLabel: 'Administrativo',
      contractualDate: DateTime(2026, 3, 6),
      targetDate: DateTime(2026, 3, 14),
      actualDate: null,
      statusCode: 'delayed',
      statusLabel: 'Retrasado',
      isPenalizable: true,
      penaltyPercent: 0.007,
      penaltyAmount: 540,
      responsible: 'QA Bureau',
      contractAmount: 77000,
      isSynced: false,
      documents: [],
      extensions: [],
      notes: 'Pendiente cierre documental con supervision.',
    ),
  ];

  static final List<MilestoneGeneralRecord> _generalRecords = [
    MilestoneGeneralRecord(
      projectId: 76,
      startDate: DateTime(2026, 1, 10),
      totalDays: 240,
      totalAmount: 1250000,
    ),
    MilestoneGeneralRecord(
      projectId: 1,
      startDate: DateTime(2026, 2, 1),
      totalDays: 210,
      totalAmount: 980000,
    ),
  ];

  static List<MilestoneRecord> milestonesForProject(int? projectId) {
    final matches = projectId == null ? _records : _records.where((item) => item.projectId == projectId).toList();
    return matches.isEmpty ? _records : matches;
  }

  static MilestoneRecord? milestoneById(int milestoneId) {
    for (final item in _records) {
      if (item.id == milestoneId) return item;
    }
    return null;
  }

  static MilestoneDashboardSummary summaryForProject(int? projectId) {
    final records = milestonesForProject(projectId);
    final completed = records.where((item) => item.isCompleted).length;
    final inProgress = records.where((item) => item.isInProgress).length;
    final delayed = records.where((item) => item.isDelayed).length;
    final activeDelay = records.where((item) {
      if (item.isCompleted) return false;
      final today = DateTime.now();
      final current = DateTime(today.year, today.month, today.day);
      final target = DateTime(item.effectiveTargetDate.year, item.effectiveTargetDate.month, item.effectiveTargetDate.day);
      return item.isDelayed || current.isAfter(target);
    }).length;
    final compliance = records.isEmpty ? 0.0 : completed / records.length;
    final accumulatedPenalty = records.where((item) => item.isCompleted && item.delayDays > 0).fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final potentialPenalty = records.where((item) => !item.isCompleted && item.isPenalizable).fold<double>(0, (sum, item) => sum + item.penaltyAmount);
    final activeExtensions = records.where((item) => item.extensions.isNotEmpty && !item.isCompleted).length;

    return MilestoneDashboardSummary(
      compliance: compliance,
      completedCount: completed,
      inProgressCount: inProgress,
      delayedCount: delayed,
      activeDelayCount: activeDelay,
      accumulatedPenalty: accumulatedPenalty,
      potentialPenalty: potentialPenalty,
      activeExtensions: activeExtensions,
    );
  }

  static MilestoneGeneralRecord generalForProject(int? projectId) {
    for (final item in _generalRecords) {
      if (item.projectId == projectId) return item;
    }
    return _generalRecords.first;
  }

  static List<MilestoneStatusOption> get statusOptions => const [
        MilestoneStatusOption(code: 'in_progress', label: 'En progreso'),
        MilestoneStatusOption(code: 'delayed', label: 'Retrasado'),
        MilestoneStatusOption(code: 'completed', label: 'Completado'),
      ];

  static List<String> get typeOptions => const ['Entregable', 'Hito de obra', 'Prueba', 'Administrativo'];
  static List<String> get classificationOptions => const ['Contractual', 'Critico', 'Calidad', 'Administrativo'];
}

Color milestoneStatusColor(String statusCode) {
  switch (statusCode) {
    case 'completed':
      return const Color(0xFF1B8E5A);
    case 'delayed':
      return const Color(0xFFD64545);
    default:
      return const Color(0xFFF0A11E);
  }
}

IconData milestoneStatusIcon(String statusCode) {
  switch (statusCode) {
    case 'completed':
      return Icons.check_circle_rounded;
    case 'delayed':
      return Icons.warning_amber_rounded;
    default:
      return Icons.timelapse_rounded;
  }
}
