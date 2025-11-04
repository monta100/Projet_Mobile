class UserPlanAssignment {
  final int userId;
  final int planId;
  final DateTime assignedAt;

  UserPlanAssignment({
    required this.userId,
    required this.planId,
    required this.assignedAt,
  });
}
