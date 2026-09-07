class GroupPoll {
  final String id;
  final String groupId;
  final String question;
  final List<String> options;
  final Map<String, String> votes;
  final String creatorId;
  final int createdAt;
  final int closesAt;
  final bool isClosed;

  const GroupPoll({
    required this.id,
    required this.groupId,
    required this.question,
    required this.options,
    required this.votes,
    required this.creatorId,
    required this.createdAt,
    required this.closesAt,
    required this.isClosed,
  });

  bool get isOpen =>
      !isClosed && DateTime.now().millisecondsSinceEpoch < closesAt;
  int votesFor(int option) =>
      votes.values.where((value) => value == '$option').length;

  factory GroupPoll.fromJson(String id, Map<dynamic, dynamic> json) =>
      GroupPoll(
        id: id,
        groupId: json['groupId']?.toString() ?? '',
        question: json['question']?.toString() ?? '',
        options: (json['options'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList(),
        votes: (json['votes'] as Map<dynamic, dynamic>? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
        creatorId: json['creatorId']?.toString() ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
        closesAt: json['closesAt'] as int? ?? 0,
        isClosed: json['isClosed'] == true,
      );
}
