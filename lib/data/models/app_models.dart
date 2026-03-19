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
  });

  final int id;
  final String name;
  final String lastName;
  final String email;
  final String role;
  final String? password;
  final String? phone;
  final String? company;

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
  });

  final int id;
  final String name;
  final String company;
  final String address;
  final String roleLabel;
  final bool isLastSelected;
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

class MeetingSummaryRecord {
  const MeetingSummaryRecord({
    required this.overdueAgreements,
    required this.pendingAgreements,
    required this.nextMeetingDate,
  });

  final int overdueAgreements;
  final int pendingAgreements;
  final DateTime? nextMeetingDate;
}

class MeetingRecord {
  const MeetingRecord({
    required this.id,
    required this.projectId,
    required this.title,
    required this.category,
    required this.subCategory,
    required this.meetingDate,
    required this.status,
  });

  final int id;
  final int projectId;
  final String title;
  final String category;
  final String subCategory;
  final DateTime meetingDate;
  final String status;
}

class MeetingAgreementRecord {
  const MeetingAgreementRecord({
    required this.id,
    required this.meetingId,
    required this.projectId,
    required this.description,
    required this.responsible,
    required this.status,
    required this.dueDate,
    required this.isOverdue,
    required this.isPending,
    required this.isCompleted,
  });

  final int id;
  final int meetingId;
  final int projectId;
  final String description;
  final String responsible;
  final String status;
  final DateTime? dueDate;
  final bool isOverdue;
  final bool isPending;
  final bool isCompleted;

  MeetingAgreementRecord copyWith({
    int? id,
    int? meetingId,
    int? projectId,
    String? description,
    String? responsible,
    String? status,
    DateTime? dueDate,
    bool? isOverdue,
    bool? isPending,
    bool? isCompleted,
  }) {
    return MeetingAgreementRecord(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      responsible: responsible ?? this.responsible,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isOverdue: isOverdue ?? this.isOverdue,
      isPending: isPending ?? this.isPending,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
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
  DateTime get effectiveTargetDate => extendedTargetDate ?? (extensions.isEmpty ? targetDate : extensions.last.newTargetDate);
  DateTime get effectiveContractualDate => extendedContractualDate ?? contractualDate;
  int get extensionCount => extensions.length;
  bool get isCompleted => contractualStatusCode == '3' || contractualStatusCode == 'completed';
  bool get isDelayed => contractualStatusCode == '2' || contractualStatusCode == 'delayed';
  bool get isInProgress => !isCompleted && !isDelayed;
  bool get isSynced => syncStatus == 'synced';
  String get notes => description;
  String get statusLabel {
    if (contractualStatusCode == '3' || contractualStatusCode == 'completed') return 'Completado';
    if (contractualStatusCode == '2' || contractualStatusCode == 'delayed') return 'Retrasado';
    return 'En progreso';
  }

  String get contractualStatusLabel {
    if (isCompleted) return 'Completado';
    if (isDelayed) return 'Retrasado';
    return 'En progreso';
  }

  String get internalStatusLabel {
    if (internalStatusCode == '3' || internalStatusCode == 'completed') return 'Completado';
    if (internalStatusCode == '2' || internalStatusCode == 'delayed') return 'Retrasado';
    return 'En progreso';
  }

  int get delayDays {
    final comparisonDate = actualDate ?? DateTime.now();
    final current = DateTime(comparisonDate.year, comparisonDate.month, comparisonDate.day);
    final target = DateTime(effectiveContractualDate.year, effectiveContractualDate.month, effectiveContractualDate.day);
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
    required this.statusCode,
  });

  final int projectId;
  final int controlId;
  final int generalId;
  final DateTime? startDate;
  final int totalDays;
  final double totalAmount;
  final String statusCode;
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

class AppPreferences {
  const AppPreferences({
    required this.keepSignedIn,
    required this.isDarkMode,
    required this.isOfflineMode,
    required this.isOfflineForced,
    required this.hasNetwork,
    required this.apiConfigured,
    required this.remoteSyncEnabled,
    required this.currentProjectId,
    required this.lastSyncAt,
    required this.lastDailyFullSyncBusinessDate,
  });

  final bool keepSignedIn;
  final bool isDarkMode;
  final bool isOfflineMode;
  final bool isOfflineForced;
  final bool hasNetwork;
  final bool apiConfigured;
  final bool remoteSyncEnabled;
  final int? currentProjectId;
  final DateTime? lastSyncAt;
  final String? lastDailyFullSyncBusinessDate;

  bool get isOfflineEffective => isOfflineMode || isOfflineForced;
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
      lastDailyFullSyncBusinessDate: lastDailyFullSyncBusinessDate ?? this.lastDailyFullSyncBusinessDate,
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
    required this.meetingSummary,
    required this.meetings,
    required this.agreements,
    required this.catalogs,
    required this.milestoneGeneral,
    required this.milestoneSummary,
    required this.milestones,
  });

  final RestrictionSummary summary;
  final List<RestrictionRecord> restrictions;
  final List<RestrictionRecord> completedRestrictions;
  final MeetingSummaryRecord meetingSummary;
  final List<MeetingRecord> meetings;
  final List<MeetingAgreementRecord> agreements;
  final RestrictionCatalogs catalogs;
  final MilestoneGeneralRecord? milestoneGeneral;
  final MilestoneDashboardSummary milestoneSummary;
  final List<MilestoneRecord> milestones;
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
  });

  final UserSession? session;
  final UserProfile? user;
  final List<ProjectRecord> projects;
  final ProjectRecord? currentProject;
  final ProjectSnapshot? snapshot;
  final AppPreferences preferences;
  final List<SyncQueueRecord> syncQueue;
  final SyncOverview syncOverview;
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
