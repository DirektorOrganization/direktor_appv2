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
    required this.front,
    required this.phase,
    required this.activity,
    required this.description,
    required this.typeId,
    required this.type,
    required this.requiredDate,
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
  final String front;
  final String phase;
  final String activity;
  final String description;
  final int? typeId;
  final String type;
  final DateTime requiredDate;
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
    String? front,
    String? phase,
    String? activity,
    String? description,
    int? typeId,
    String? type,
    DateTime? requiredDate,
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
      front: front ?? this.front,
      phase: phase ?? this.phase,
      activity: activity ?? this.activity,
      description: description ?? this.description,
      typeId: typeId ?? this.typeId,
      type: type ?? this.type,
      requiredDate: requiredDate ?? this.requiredDate,
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
  final bool isOverdue;
  final bool isPending;
  final bool isCompleted;
}

class CatalogOption {
  const CatalogOption({required this.id, required this.label, this.colorHex});

  final String id;
  final String label;
  final String? colorHex;
}

class RestrictionCatalogs {
  const RestrictionCatalogs({
    required this.fronts,
    required this.phases,
    required this.types,
    required this.responsibles,
    required this.statuses,
  });

  final List<CatalogOption> fronts;
  final List<CatalogOption> phases;
  final List<CatalogOption> types;
  final List<CatalogOption> responsibles;
  final List<CatalogOption> statuses;
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
  });

  final RestrictionSummary summary;
  final List<RestrictionRecord> restrictions;
  final List<RestrictionRecord> completedRestrictions;
  final MeetingSummaryRecord meetingSummary;
  final List<MeetingRecord> meetings;
  final List<MeetingAgreementRecord> agreements;
  final RestrictionCatalogs catalogs;
}

class AppBootstrapData {
  const AppBootstrapData({
    required this.session,
    required this.user,
    required this.projects,
    required this.currentProject,
    required this.snapshot,
  });

  final UserSession? session;
  final UserProfile? user;
  final List<ProjectRecord> projects;
  final ProjectRecord? currentProject;
  final ProjectSnapshot? snapshot;
}

class RestrictionDraft {
  const RestrictionDraft({
    this.id,
    required this.frontId,
    required this.phaseId,
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
  final String activity;
  final String description;
  final String typeId;
  final DateTime requiredDate;
  final String responsibleId;
  final String statusCode;
}
