class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
    this.password,
    this.phone,
    this.company,
    this.hubStyle,
  });

  final int id;
  final String name;
  final String lastName;
  final String email;
  final String role;
  final String? password;
  final String? phone;
  final String? company;

  /// Ruta del hub seleccionado por el usuario (ej: '/hub-modelo-k').
  /// Null = vista por defecto.
  final String? hubStyle;

  String get fullName => '$name $lastName'.trim();
}

class UserSession {
  const UserSession({
    required this.userId,
    required this.token,
    required this.keepSignedIn,
    required this.isActive,
  });

  final int userId;
  final String token;
  final bool keepSignedIn;
  final bool isActive;
}

class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.name,
    required this.company,
    required this.address,
    required this.roleLabel,
    required this.isLastSelected,
    this.restrictionsEnabled = true,
  });

  final int id;
  final String name;
  final String company;
  final String address;
  final String roleLabel;
  final bool isLastSelected;
  /// false cuando anares_analysis.codEstado != 0 para este proyecto.
  final bool restrictionsEnabled;
}

class RestrictionRecord {
  const RestrictionRecord({
    required this.id,
    required this.projectId,
    required this.frontId,
    required this.phaseId,
    required this.areaCode,
    required this.front,
    required this.phase,
    required this.area,
    required this.activity,
    required this.description,
    required this.typeId,
    required this.type,
    required this.requiredDate,
    required this.conciliatedDate,
    required this.responsibleId,
    required this.responsible,
    required this.statusCode,
    required this.statusLabel,
    required this.statusColor,
    required this.requester,
    required this.isCompleted,
    required this.isOverdue,
    required this.isDueToday,
    required this.isPending,
    required this.isInProgress,
    required this.priorityOrder,
    required this.syncStatus,
    required this.updatedAt,
  });

  final int id;
  final int projectId;
  final int? frontId;
  final int? phaseId;
  final String? areaCode;
  final String front;
  final String phase;
  final String area;
  final String activity;
  final String description;
  final int? typeId;
  final String type;
  final DateTime requiredDate;
  final DateTime? conciliatedDate;
  final int? responsibleId;
  final String responsible;
  final String statusCode;
  final String statusLabel;
  final String statusColor;
  final String requester;
  final bool isCompleted;
  final bool isOverdue;
  final bool isDueToday;
  final bool isPending;
  final bool isInProgress;
  final int priorityOrder;
  final String syncStatus;
  final DateTime updatedAt;

  bool get isSynced => syncStatus == 'synced';

  RestrictionRecord copyWith({
    int? id,
    int? projectId,
    int? frontId,
    int? phaseId,
    String? areaCode,
    String? front,
    String? phase,
    String? area,
    String? activity,
    String? description,
    int? typeId,
    String? type,
    DateTime? requiredDate,
    DateTime? conciliatedDate,
    int? responsibleId,
    String? responsible,
    String? statusCode,
    String? statusLabel,
    String? statusColor,
    String? requester,
    bool? isCompleted,
    bool? isOverdue,
    bool? isDueToday,
    bool? isPending,
    bool? isInProgress,
    int? priorityOrder,
    String? syncStatus,
    DateTime? updatedAt,
  }) {
    return RestrictionRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      frontId: frontId ?? this.frontId,
      phaseId: phaseId ?? this.phaseId,
      areaCode: areaCode ?? this.areaCode,
      front: front ?? this.front,
      phase: phase ?? this.phase,
      area: area ?? this.area,
      activity: activity ?? this.activity,
      description: description ?? this.description,
      typeId: typeId ?? this.typeId,
      type: type ?? this.type,
      requiredDate: requiredDate ?? this.requiredDate,
      conciliatedDate: conciliatedDate ?? this.conciliatedDate,
      responsibleId: responsibleId ?? this.responsibleId,
      responsible: responsible ?? this.responsible,
      statusCode: statusCode ?? this.statusCode,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      requester: requester ?? this.requester,
      isCompleted: isCompleted ?? this.isCompleted,
      isOverdue: isOverdue ?? this.isOverdue,
      isDueToday: isDueToday ?? this.isDueToday,
      isPending: isPending ?? this.isPending,
      isInProgress: isInProgress ?? this.isInProgress,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RestrictionSummary {
  const RestrictionSummary({
    required this.total,
    required this.completed,
    required this.overdue,
    required this.inProgress,
    required this.pending,
    required this.compliancePercent,
  });

  final int total;
  final int completed;
  final int overdue;
  final int inProgress;
  final int pending;
  final double compliancePercent;
}

class MilestoneDocumentRecord {
  const MilestoneDocumentRecord({
    required this.id,
    required this.milestoneId,
    required this.name,
    required this.path,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  final int id;
  final int milestoneId;
  final String name;
  final String path;
  final DateTime? uploadedAt;
  final String uploadedBy;
}

class MilestoneExtensionRecord {
  const MilestoneExtensionRecord({
    required this.id,
    required this.milestoneId,
    required this.justification,
    required this.previousTargetDate,
    required this.newTargetDate,
    required this.newContractualDate,
    required this.requestedAt,
    required this.createdBy,
    required this.supportDocument,
    required this.dateType,
  });

  final int id;
  final int milestoneId;
  final String justification;
  final DateTime previousTargetDate;
  final DateTime newTargetDate;
  final DateTime? newContractualDate;
  final DateTime? requestedAt;
  final String createdBy;
  final String supportDocument;
  final String dateType;

  String get title => justification.isEmpty ? 'Ampliacion' : justification;
}

class MilestoneRecord {
  const MilestoneRecord({
    required this.id,
    required this.controlId,
    required this.generalId,
    required this.projectId,
    required this.code,
    required this.order,
    required this.description,
    required this.typeCode,
    required this.typeLabel,
    required this.classificationCode,
    required this.classificationLabel,
    required this.days,
    required this.isPenalizable,
    required this.penaltyPercent,
    required this.contractualDate,
    required this.targetDate,
    required this.actualDate,
    required this.contractualExtensionCount,
    required this.targetExtensionCount,
    required this.contractualStatusCode,
    required this.internalStatusCode,
    required this.penaltyAmount,
    required this.createdAt,
    required this.modifiedAt,
    required this.extendedContractualDate,
    required this.extendedTargetDate,
    required this.syncStatus,
    required this.documents,
    required this.extensions,
  });

  final int id;
  final int controlId;
  final int generalId;
  final int projectId;
  final String code;
  final int order;
  final String description;
  final int? typeCode;
  final String typeLabel;
  final int? classificationCode;
  final String classificationLabel;
  final int? days;
  final bool isPenalizable;
  final double penaltyPercent;
  final DateTime contractualDate;
  final DateTime targetDate;
  final DateTime? actualDate;
  final int contractualExtensionCount;
  final int targetExtensionCount;
  final String contractualStatusCode;
  final String internalStatusCode;
  final double penaltyAmount;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final DateTime? extendedContractualDate;
  final DateTime? extendedTargetDate;
  final String syncStatus;
  final List<MilestoneDocumentRecord> documents;
  final List<MilestoneExtensionRecord> extensions;

  String get statusCode => contractualStatusCode;
  DateTime get effectiveTargetDate =>
      extendedTargetDate ??
      (extensions.isEmpty ? targetDate : extensions.last.newTargetDate);
  DateTime get effectiveContractualDate =>
      extendedContractualDate ?? contractualDate;
  int get extensionCount => extensions.length;
  bool get isCompleted =>
      contractualStatusCode == '3' || contractualStatusCode == 'completed';
  bool get isDelayed =>
      contractualStatusCode == '2' || contractualStatusCode == 'delayed';
  bool get isInProgress => !isCompleted && !isDelayed;
  bool get isSynced => syncStatus == 'synced';
  String get notes => description;
  String get statusLabel {
    if (contractualStatusCode == '3' || contractualStatusCode == 'completed') {
      return 'Completado';
    }
    if (contractualStatusCode == '2' || contractualStatusCode == 'delayed') {
      return 'Retrasado';
    }
    return 'En progreso';
  }

  String get contractualStatusLabel {
    if (isCompleted) { return 'Completado'; }
    if (isDelayed) { return 'Retrasado'; }
    return 'En progreso';
  }

  String get internalStatusLabel {
    if (internalStatusCode == '3' || internalStatusCode == 'completed') {
      return 'Completado';
    }
    if (internalStatusCode == '2' || internalStatusCode == 'delayed') {
      return 'Retrasado';
    }
    return 'En progreso';
  }

  int get delayDays {
    final comparisonDate = actualDate ?? DateTime.now();
    final current = DateTime(
      comparisonDate.year,
      comparisonDate.month,
      comparisonDate.day,
    );
    final target = DateTime(
      effectiveContractualDate.year,
      effectiveContractualDate.month,
      effectiveContractualDate.day,
    );
    final diff = current.difference(target).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class MilestoneGeneralRecord {
  const MilestoneGeneralRecord({
    required this.projectId,
    required this.controlId,
    required this.generalId,
    required this.startDate,
    required this.totalDays,
    required this.totalAmount,
    required this.controversyDays,
    required this.statusCode,
    required this.appliesToGeneral,
  });

  final int projectId;
  final int controlId;
  final int generalId;
  final DateTime? startDate;
  /// numDiasPlazoTotal — plazo total de la obra
  final int totalDays;
  /// mntTotal — monto total de la obra
  final double totalAmount;
  /// numDias — días de controversia
  final int controversyDays;
  final String statusCode;
  /// flgAplicaHitoGeneral — indica si se aplican datos generales para indicadores
  final bool appliesToGeneral;
}

class MilestoneGeneralDraft {
  const MilestoneGeneralDraft({
    required this.projectId,
    required this.controlId,
    required this.generalId,
    required this.startDate,
    required this.totalDays,
    required this.totalAmount,
    required this.controversyDays,
    required this.appliesToGeneral,
  });

  final int projectId;
  final int controlId;
  final int generalId;
  final DateTime? startDate;
  /// numDiasPlazoTotal — plazo total de la obra
  final int totalDays;
  /// numDias — días de controversia
  final int controversyDays;
  final double totalAmount;
  /// flgAplicaHitoGeneral — indica si se aplican datos generales para indicadores
  final bool appliesToGeneral;
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

class MilestoneLookupOption {
  const MilestoneLookupOption({
    required this.code,
    required this.label,
    this.order,
  });

  final String code;
  final String label;
  final int? order;
}

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.label,
    this.colorHex,
    this.parentId,
    this.referenceId,
    this.projectId,
    this.isLocal = false,
  });

  final String id;
  final String label;
  final String? colorHex;
  final String? parentId;
  final String? referenceId;
  final int? projectId;
  final bool isLocal;
}

class RestrictionCatalogs {
  const RestrictionCatalogs({
    required this.fronts,
    required this.phases,
    required this.areas,
    required this.types,
    required this.responsibles,
    required this.statuses,
  });

  final List<CatalogOption> fronts;
  final List<CatalogOption> phases;
  final List<CatalogOption> areas;
  final List<CatalogOption> types;
  final List<CatalogOption> responsibles;
  final List<CatalogOption> statuses;
}

// ── Sync change events (used to trigger notifications) ───────

class SyncChangeEvent {
  const SyncChangeEvent({
    required this.module,
    required this.entityId,
    required this.description,
    required this.oldStatus,
    required this.newStatus,
  });

  /// 'restrictions' | 'actreu'
  final String module;
  final int entityId;
  final String description;
  final String oldStatus;
  final String newStatus;
}

enum ModuleInsightModule { restrictions, actaReuniones }

enum ModuleInsightSeverity { warning, critical }

class ModuleInsightRecord {
  const ModuleInsightRecord({
    required this.projectId,
    required this.module,
    required this.key,
    required this.severity,
    required this.title,
    required this.message,
    required this.iconName,
    required this.isResolved,
    required this.updatedAt,
  });

  final int projectId;
  final ModuleInsightModule module;
  final String key;
  final ModuleInsightSeverity severity;
  final String title;
  final String message;
  final String iconName;
  final bool isResolved;
  final DateTime? updatedAt;

  String get severityLabel =>
      severity == ModuleInsightSeverity.critical ? 'Critico' : 'Alerta';
}

class InsightRuleConfigRecord {
  const InsightRuleConfigRecord({
    required this.userId,
    required this.module,
    required this.ruleKey,
    required this.isEnabled,
    required this.thresholds,
  });

  final int userId;
  final ModuleInsightModule module;
  final String ruleKey;
  final bool isEnabled;
  final Map<String, int> thresholds;

  /// Returns the configured value for [name], or [defaultValue] if not set.
  int threshold(String name, int defaultValue) =>
      thresholds[name] ?? defaultValue;
}

class ActreuStatusRecord {
  const ActreuStatusRecord({required this.code, required this.label});

  final int code;
  final String label;
}

class ActreuSummaryRecord {
  const ActreuSummaryRecord({
    required this.projectId,
    required this.totalSessions,
    required this.scheduledSessions,
    required this.activeSessions,
    required this.overdueAgreements,
    required this.pendingAgreements,
    required this.informativeAgreements,
    required this.categoriesCount,
    required this.subcategoriesCount,
    required this.compliancePercent,
    required this.updatedAt,
  });

  final int projectId;
  final int totalSessions;
  final int scheduledSessions;
  final int activeSessions;
  final int overdueAgreements;
  final int pendingAgreements;
  final int informativeAgreements;
  final int categoriesCount;
  final int subcategoriesCount;
  final double compliancePercent;
  final DateTime? updatedAt;
}

class ActreuActaRecord {
  const ActreuActaRecord({
    required this.id,
    required this.projectId,
    required this.statusCode,
    required this.createdAt,
    required this.createdBy,
  });

  final int id;
  final int projectId;
  final int? statusCode;
  final DateTime? createdAt;
  final String createdBy;
}

class ActreuCategoriaRecord {
  const ActreuCategoriaRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.statusCode,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int actaId;
  final int? statusCode;
  final String name;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuSubcategoriaRecord {
  const ActreuSubcategoriaRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.statusCode,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int actaId;
  final int categoriaId;
  final int? statusCode;
  final String name;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuReunionRecord {
  const ActreuReunionRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.statusCode,
    required this.name,
    required this.meetingDate,
    required this.closeDate,
    required this.startHour,
    required this.endHour,
    required this.link,
    required this.groupedData,
    required this.generatedFileName,
    required this.generatedSignedFileName,
    required this.generatedFileUrl,
    required this.generatedSignedFileUrl,
    required this.groupsOrder,
    required this.previousGroupsOrder,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int? actaId;
  final int? categoriaId;
  final int subcategoriaId;
  final int? statusCode;
  final String name;
  final DateTime? meetingDate;
  final DateTime? closeDate;
  final String startHour;
  final String endHour;
  final String link;
  final String groupedData;
  final String generatedFileName;
  final String generatedSignedFileName;
  final String generatedFileUrl;
  final String generatedSignedFileUrl;
  final String groupsOrder;
  final String previousGroupsOrder;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuIntegranteRecord {
  const ActreuIntegranteRecord({
    required this.projectId,
    required this.actaId,
    required this.projectMemberId,
    required this.statusCode,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int projectId;
  final int actaId;
  final int projectMemberId;
  final int? statusCode;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuParticipanteRecord {
  const ActreuParticipanteRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.name,
    required this.areaCode,
    required this.email,
    required this.userId,
    required this.projectMemberId,
    required this.isGuest,
    required this.statusCode,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int? actaId;
  final int? categoriaId;
  final int subcategoriaId;
  final String name;
  final String areaCode;
  final String email;
  final int? userId;
  final int? projectMemberId;
  final bool isGuest;
  final int statusCode;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuGrupoAcuerdoRecord {
  const ActreuGrupoAcuerdoRecord({
    required this.id,
    required this.projectId,
    required this.name,
    required this.colorHex,
    required this.optionalAreaCode,
  });

  final int id;
  final int? projectId;
  final String name;
  final String colorHex;
  final int? optionalAreaCode;
}

class ActreuAcuerdoRecord {
  const ActreuAcuerdoRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.reunionId,
    required this.description,
    required this.agreementDate,
    required this.postponedDate,
    required this.resolvedDate,
    required this.postponements,
    required this.responsibleUserId,
    required this.statusCode,
    required this.order,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
    required this.groupId,
    required this.previousOrder,
  });

  final int id;
  final int projectId;
  final int? actaId;
  final int? categoriaId;
  final int? subcategoriaId;
  final int reunionId;
  final String description;
  final DateTime? agreementDate;
  final DateTime? postponedDate;
  final DateTime? resolvedDate;
  final int? postponements;
  final int? responsibleUserId;
  final int? statusCode;
  final String order;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
  final int? groupId;
  final int? previousOrder;

  bool get isInformative => statusCode == 6;
}

class ActreuAcuerdoFotoRecord {
  const ActreuAcuerdoFotoRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.acuerdoId,
    required this.reunionId,
    required this.description,
    required this.agreementDate,
    required this.postponedDate,
    required this.resolvedDate,
    required this.postponements,
    required this.responsibleUserId,
    required this.groupId,
    required this.statusCode,
    required this.order,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int? actaId;
  final int? categoriaId;
  final int? subcategoriaId;
  final int? acuerdoId;
  final int? reunionId;
  final String description;
  final DateTime? agreementDate;
  final DateTime? postponedDate;
  final DateTime? resolvedDate;
  final int? postponements;
  final int? responsibleUserId;
  final int? groupId;
  final int? statusCode;
  final String order;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuComentarioAcuerdoRecord {
  const ActreuComentarioAcuerdoRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.reunionId,
    required this.acuerdoId,
    required this.parentCommentId,
    required this.userId,
    required this.message,
    required this.commentDate,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int? actaId;
  final int? categoriaId;
  final int? subcategoriaId;
  final int? reunionId;
  final int acuerdoId;
  final int? parentCommentId;
  final int? userId;
  final String message;
  final DateTime? commentDate;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class ActreuAsistenciaRecord {
  const ActreuAsistenciaRecord({
    required this.id,
    required this.projectId,
    required this.actaId,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.reunionId,
    required this.statusCode,
    required this.name,
    required this.email,
    required this.userId,
    required this.projectMemberId,
    required this.participanteId,
    required this.justification,
    required this.createdAt,
    required this.createdBy,
    required this.modifiedAt,
    required this.modifiedBy,
  });

  final int id;
  final int projectId;
  final int? actaId;
  final int? categoriaId;
  final int? subcategoriaId;
  final int reunionId;
  final int? statusCode;
  final String name;
  final String email;
  final int? userId;
  final int? projectMemberId;
  final int? participanteId;
  final String justification;
  final DateTime? createdAt;
  final String createdBy;
  final DateTime? modifiedAt;
  final String modifiedBy;
}

class AppPreferences {
  const AppPreferences({
    required this.keepSignedIn,
    required this.isDarkMode,
    required this.isOfflineMode,
    required this.isOfflineForced,
    required this.hasNetwork,
    required this.apiConfigured,
    required this.remoteSyncEnabled,
    required this.isDeviceLinked,
    required this.linkedDeviceId,
    required this.linkedDeviceLabel,
    required this.deviceLinkedAt,
    required this.currentProjectId,
    required this.lastSyncAt,
    required this.lastDailyFullSyncBusinessDate,
    this.notificationsEnabled = true,
    this.notificationsRestrictionsEnabled = true,
    this.notificationsActreuEnabled = true,
    this.indicatorsEnabled = true,
    this.indicatorsRestrictionsEnabled = true,
    this.indicatorsMilestonesEnabled = true,
    this.indicatorsActreuEnabled = true,
  });

  final bool keepSignedIn;
  final bool isDarkMode;
  final bool isOfflineMode;
  final bool isOfflineForced;
  final bool hasNetwork;
  final bool apiConfigured;
  final bool remoteSyncEnabled;
  final bool isDeviceLinked;
  final String? linkedDeviceId;
  final String? linkedDeviceLabel;
  final DateTime? deviceLinkedAt;
  final int? currentProjectId;
  final DateTime? lastSyncAt;
  final String? lastDailyFullSyncBusinessDate;
  final bool notificationsEnabled;
  final bool notificationsRestrictionsEnabled;
  final bool notificationsActreuEnabled;
  final bool indicatorsEnabled;
  final bool indicatorsRestrictionsEnabled;
  final bool indicatorsMilestonesEnabled;
  final bool indicatorsActreuEnabled;

  bool get isOfflineEffective => isOfflineMode || isOfflineForced;
}

class LocationAccessState {
  const LocationAccessState({
    required this.permissionStatus,
    required this.serviceEnabled,
    required this.hasRequestedConsent,
  });

  final String permissionStatus;
  final bool serviceEnabled;
  final bool hasRequestedConsent;

  bool get isPermissionGranted =>
      permissionStatus == 'whileInUse' || permissionStatus == 'always';

  bool get needsPermissionGuidance =>
      hasRequestedConsent && !isPermissionGranted;

  bool get needsServiceGuidance => isPermissionGranted && !serviceEnabled;

  bool get shouldShowGuidance =>
      needsPermissionGuidance || needsServiceGuidance;

  String get guidanceKey =>
      '$permissionStatus|$serviceEnabled|$hasRequestedConsent';
}

class DeviceBindingState {
  const DeviceBindingState({
    required this.isLinked,
    required this.deviceId,
    required this.deviceLabel,
    required this.linkedAt,
  });

  final bool isLinked;
  final String? deviceId;
  final String? deviceLabel;
  final DateTime? linkedAt;
}

class SyncQueueRecord {
  const SyncQueueRecord({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.status,
    required this.retryCount,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String entityType;
  final String entityId;
  final String operationType;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class SyncOverview {
  const SyncOverview({
    required this.pendingCount,
    required this.failedCount,
    required this.lastSyncAt,
    required this.lastDailyFullSyncBusinessDate,
    required this.isOfflineMode,
    required this.isOfflineForced,
    required this.hasNetwork,
    required this.apiConfigured,
    required this.remoteSyncEnabled,
    this.lastError,
    this.isSyncing = false,
  });

  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncAt;
  final String? lastDailyFullSyncBusinessDate;
  final bool isOfflineMode;
  final bool isOfflineForced;
  final bool hasNetwork;
  final bool apiConfigured;
  final bool remoteSyncEnabled;
  final String? lastError;
  final bool isSyncing;

  bool get isOfflineEffective => isOfflineMode || isOfflineForced;

  SyncOverview copyWith({
    int? pendingCount,
    int? failedCount,
    DateTime? lastSyncAt,
    String? lastDailyFullSyncBusinessDate,
    bool? isOfflineMode,
    bool? isOfflineForced,
    bool? hasNetwork,
    bool? apiConfigured,
    bool? remoteSyncEnabled,
    String? lastError,
    bool? isSyncing,
  }) {
    return SyncOverview(
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastDailyFullSyncBusinessDate:
          lastDailyFullSyncBusinessDate ?? this.lastDailyFullSyncBusinessDate,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isOfflineForced: isOfflineForced ?? this.isOfflineForced,
      hasNetwork: hasNetwork ?? this.hasNetwork,
      apiConfigured: apiConfigured ?? this.apiConfigured,
      remoteSyncEnabled: remoteSyncEnabled ?? this.remoteSyncEnabled,
      lastError: lastError ?? this.lastError,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class ProjectSnapshot {
  const ProjectSnapshot({
    required this.summary,
    required this.restrictions,
    required this.completedRestrictions,
    required this.catalogs,
    required this.milestoneTypes,
    required this.milestoneClassifications,
    required this.milestoneGeneral,
    required this.milestoneSummary,
    required this.milestones,
    required this.restrictionInsights,
    required this.actaReunionesInsights,
    this.actreuSummary,
  });

  final RestrictionSummary summary;
  final List<RestrictionRecord> restrictions;
  final List<RestrictionRecord> completedRestrictions;
  final RestrictionCatalogs catalogs;
  final List<MilestoneLookupOption> milestoneTypes;
  final List<MilestoneLookupOption> milestoneClassifications;
  final MilestoneGeneralRecord? milestoneGeneral;
  final MilestoneDashboardSummary milestoneSummary;
  final List<MilestoneRecord> milestones;
  final List<ModuleInsightRecord> restrictionInsights;
  final List<ModuleInsightRecord> actaReunionesInsights;
  final ActreuSummaryRecord? actreuSummary;
}

class AppBootstrapData {
  const AppBootstrapData({
    required this.session,
    required this.user,
    required this.projects,
    required this.currentProject,
    required this.snapshot,
    required this.preferences,
    required this.syncQueue,
    required this.syncOverview,
    this.indicatorPrefs,
    this.syncChangeEvents,
  });

  final UserSession? session;
  final UserProfile? user;
  final List<ProjectRecord> projects;
  final ProjectRecord? currentProject;
  final ProjectSnapshot? snapshot;
  final AppPreferences preferences;
  final List<SyncQueueRecord> syncQueue;
  final SyncOverview syncOverview;
  final List<HubIndicatorPref>? indicatorPrefs;
  /// State changes detected during this sync cycle — used to fire notifications.
  final List<SyncChangeEvent>? syncChangeEvents;
}

class RestrictionDraft {
  const RestrictionDraft({
    this.id,
    required this.frontId,
    required this.phaseId,
    required this.areaCode,
    required this.activity,
    required this.description,
    required this.typeId,
    required this.requiredDate,
    this.conciliatedDate,
    required this.responsibleId,
    required this.statusCode,
  });

  final int? id;
  final String frontId;
  final String phaseId;
  final String areaCode;
  final String activity;
  final String description;
  final String typeId;
  final DateTime requiredDate;
  final DateTime? conciliatedDate;
  final String responsibleId;
  final String statusCode;
}

class MilestoneDraft {
  const MilestoneDraft({
    this.id,
    required this.description,
    required this.typeCode,
    required this.classificationCode,
    required this.contractualDate,
    required this.targetDate,
    required this.actualDate,
    required this.isPenalizable,
    required this.penaltyPercent,
    required this.internalStatusCode,
  });

  final int? id;
  final String description;
  final String typeCode;
  final String classificationCode;
  final DateTime contractualDate;
  final DateTime targetDate;
  final DateTime? actualDate;
  final bool isPenalizable;
  final double penaltyPercent;
  final String internalStatusCode;
}

class MilestoneExtensionDraft {
  const MilestoneExtensionDraft({
    required this.milestoneId,
    required this.justification,
    required this.newContractualDate,
    required this.newTargetDate,
    required this.supportDocument,
    required this.dateType,
  });

  final int milestoneId;
  final String justification;
  final DateTime? newContractualDate;
  final DateTime? newTargetDate;
  final String supportDocument;
  final String dateType;
}

class MilestoneDocumentDraft {
  const MilestoneDocumentDraft({
    required this.milestoneId,
    required this.name,
    required this.path,
  });

  final int milestoneId;
  final String name;
  final String path;
}

class ActreuHubSubcategoryItem {
  const ActreuHubSubcategoryItem({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.categoryName,
    required this.overdueCount,
    required this.pendingCount,
    required this.nextSessionDate,
    required this.hasActiveSession,
    required this.activeSessionId,
  });

  final int subcategoryId;
  final String subcategoryName;
  final String categoryName;
  final int overdueCount;
  final int pendingCount;
  final DateTime? nextSessionDate;
  final bool hasActiveSession;
  final int? activeSessionId;
}

class ActreuOverdueAgreementItem {
  const ActreuOverdueAgreementItem({
    required this.agreementId,
    required this.description,
    required this.responsible,
    required this.group,
    required this.groupColorHex,
    required this.dueDate,
    required this.daysOverdue,
    required this.commentsCount,
    required this.deferralsCount,
    required this.sessionLabel,
  });

  final int agreementId;
  final String description;
  final String responsible;
  final String group;
  final String? groupColorHex;
  final DateTime dueDate;
  final int daysOverdue;
  final int commentsCount;
  final int deferralsCount;
  final String sessionLabel;
}

class ActreuSessionBannerItem {
  const ActreuSessionBannerItem({
    required this.sessionId,
    required this.subcategoryId,
    required this.title,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.attendancePresent,
    required this.attendanceTotal,
  });

  final int sessionId;
  final int subcategoryId;
  final String title;
  final DateTime? sessionDate;
  final String startTime;
  final String endTime;
  final int attendancePresent;
  final int attendanceTotal;
}

class ActreuHubViewData {
  const ActreuHubViewData({
    required this.hasSubcategories,
    required this.activeSession,
    required this.overdueAgreements,
    required this.subcategories,
  });

  final bool hasSubcategories;
  final ActreuSessionBannerItem? activeSession;
  final List<ActreuOverdueAgreementItem> overdueAgreements;
  final List<ActreuHubSubcategoryItem> subcategories;
}

class ActreuCategoryTreeItem {
  const ActreuCategoryTreeItem({
    required this.categoryId,
    required this.categoryName,
    required this.subcategories,
  });

  final int categoryId;
  final String categoryName;
  final List<ActreuSubcategoryTreeItem> subcategories;
}

class ActreuSubcategoryTreeItem {
  const ActreuSubcategoryTreeItem({
    required this.subcategoryId,
    required this.subcategoryName,
  });

  final int subcategoryId;
  final String subcategoryName;
}

class ActreuSubcategorySessionItem {
  const ActreuSubcategorySessionItem({
    required this.sessionId,
    required this.title,
    required this.date,
    required this.statusCode,
    required this.attendedCount,
    required this.totalCount,
    required this.agreementsCount,
    required this.overdueCount,
  });

  final int sessionId;
  final String title;
  final DateTime? date;
  final int statusCode;
  final int attendedCount;
  final int totalCount;
  final int agreementsCount;
  final int overdueCount;
}

class ActreuSubcategoryParticipantItem {
  const ActreuSubcategoryParticipantItem({
    required this.participantId,
    required this.name,
    required this.area,
    required this.role,
    required this.userId,
    required this.projectMemberId,
  });

  final int participantId;
  final String name;
  final String area;
  final String role;
  final int? userId;
  final int? projectMemberId;
}

class ActreuSubcategoryRecommendationItem {
  const ActreuSubcategoryRecommendationItem({
    required this.projectMemberId,
    required this.label,
  });

  final int projectMemberId;
  final String label;
}

class ActreuSubcategoryAgreementItem {
  const ActreuSubcategoryAgreementItem({
    required this.agreementId,
    required this.description,
    required this.responsible,
    required this.responsibleParticipantId,
    required this.dueDate,
    required this.statusCode,
    required this.groupId,
    required this.group,
    required this.groupColorHex,
    required this.sessionLabel,
    required this.commentsCount,
    required this.deferralsCount,
    required this.lockedByActiveSession,
  });

  final int agreementId;
  final String description;
  final String responsible;
  final int? responsibleParticipantId;
  final DateTime? dueDate;
  final int statusCode;
  final int? groupId;
  final String group;
  final String? groupColorHex;
  final String sessionLabel;
  final int commentsCount;
  final int deferralsCount;
  final bool lockedByActiveSession;
}

class ActreuGroupOptionItem {
  const ActreuGroupOptionItem({
    required this.groupId,
    required this.groupName,
    required this.groupColorHex,
  });

  final int groupId;
  final String groupName;
  final String? groupColorHex;
}

class ActreuSubcategoryViewData {
  const ActreuSubcategoryViewData({
    required this.subcategoryId,
    required this.subcategoryName,
    required this.categoryName,
    required this.agreements,
    required this.sessions,
    required this.participants,
    required this.recommendations,
    required this.groupOptions,
  });

  final int subcategoryId;
  final String subcategoryName;
  final String categoryName;
  final List<ActreuSubcategoryAgreementItem> agreements;
  final List<ActreuSubcategorySessionItem> sessions;
  final List<ActreuSubcategoryParticipantItem> participants;
  final List<ActreuSubcategoryRecommendationItem> recommendations;
  final List<ActreuGroupOptionItem> groupOptions;
}

class ActreuAgreementCommentItem {
  const ActreuAgreementCommentItem({
    required this.commentId,
    required this.agreementId,
    required this.parentCommentId,
    required this.userId,
    required this.message,
    required this.createdAt,
    required this.author,
  });

  final int commentId;
  final int agreementId;
  final int? parentCommentId;
  final int? userId;
  final String message;
  final DateTime? createdAt;
  final String author;
}

class ActreuSessionAgreementItem {
  const ActreuSessionAgreementItem({
    required this.agreementId,
    required this.description,
    required this.responsible,
    required this.responsibleParticipantId,
    required this.agreementDate,
    required this.dueDate,
    required this.statusCode,
    required this.groupId,
    required this.group,
    required this.groupColorHex,
    required this.commentsCount,
    required this.deferralsCount,
    required this.isFromPrevious,
  });

  final int agreementId;
  final String description;
  final String responsible;
  final int? responsibleParticipantId;
  final DateTime? agreementDate;
  final DateTime? dueDate;
  final int statusCode;
  final int? groupId;
  final String group;
  final String? groupColorHex;
  final int commentsCount;
  final int deferralsCount;
  final bool isFromPrevious;
}

class ActreuSessionAttendanceItem {
  const ActreuSessionAttendanceItem({
    required this.participantId,
    required this.name,
    required this.area,
    required this.present,
  });

  final int participantId;
  final String name;
  final String area;
  final bool present;
}

class ActreuSessionViewData {
  const ActreuSessionViewData({
    required this.sessionId,
    required this.subcategoryId,
    required this.sessionTitle,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.attendance,
    required this.agreements,
    required this.groupNames,
    required this.groupOptions,
  });

  final int sessionId;
  final int subcategoryId;
  final String sessionTitle;
  final DateTime? sessionDate;
  final String startTime;
  final String endTime;
  final List<ActreuSessionAttendanceItem> attendance;
  final List<ActreuSessionAgreementItem> agreements;
  final List<String> groupNames;
  final List<ActreuGroupOptionItem> groupOptions;
}

class HubIndicatorPref {
  const HubIndicatorPref({
    required this.key,
    required this.userId,
    required this.isEnabled,
    required this.displayType,
    this.customParam,
    required this.sortOrder,
  });

  final String key;
  final int userId;
  final bool isEnabled;
  final String displayType; // 'card' | 'chart_donut' | 'chart_bar'
  final String? customParam;
  final int sortOrder;

  HubIndicatorPref copyWith({
    bool? isEnabled,
    String? displayType,
    String? customParam,
    int? sortOrder,
  }) =>
      HubIndicatorPref(
        key: key,
        userId: userId,
        isEnabled: isEnabled ?? this.isEnabled,
        displayType: displayType ?? this.displayType,
        customParam: customParam ?? this.customParam,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
