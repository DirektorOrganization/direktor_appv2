class RestrictionDetailArgs {
  const RestrictionDetailArgs({required this.restrictionId});

  final int restrictionId;
}

class RestrictionFormArgs {
  const RestrictionFormArgs({this.restrictionId});

  final int? restrictionId;

  bool get isEdit => restrictionId != null;
}

class MilestoneDetailArgs {
  const MilestoneDetailArgs({required this.milestoneId});

  final int milestoneId;
}

class MilestoneFormArgs {
  const MilestoneFormArgs({this.milestoneId});

  final int? milestoneId;

  bool get isEdit => milestoneId != null;
}

class MilestoneDocumentsArgs {
  const MilestoneDocumentsArgs({required this.milestoneId});

  final int milestoneId;
}

class MilestoneExtensionsArgs {
  const MilestoneExtensionsArgs({required this.milestoneId});

  final int milestoneId;
}

class MilestoneExtensionFormArgs {
  const MilestoneExtensionFormArgs({required this.milestoneId});

  final int milestoneId;
}
