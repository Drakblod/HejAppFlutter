class GroupTask {
  final String id;
  final String groupId;
  final String title;
  final String? assigneeId;
  final String creatorId;
  final int createdAt;
  final int? dueAt;
  final bool isDone;

  const GroupTask({
    required this.id,
    required this.groupId,
    required this.title,
    this.assigneeId,
    required this.creatorId,
    required this.createdAt,
    this.dueAt,
    required this.isDone,
  });

  factory GroupTask.fromJson(String id, Map<dynamic, dynamic> json) =>
      GroupTask(
        id: id,
        groupId: json['groupId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        assigneeId: json['assigneeId']?.toString(),
        creatorId: json['creatorId']?.toString() ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
        dueAt: json['dueAt'] as int?,
        isDone: json['isDone'] == true,
      );
}
