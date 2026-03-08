class RestrictionDetailArgs {
  const RestrictionDetailArgs({required this.restrictionId});

  final int restrictionId;
}

class RestrictionFormArgs {
  const RestrictionFormArgs({this.restrictionId});

  final int? restrictionId;

  bool get isEdit => restrictionId != null;
}
