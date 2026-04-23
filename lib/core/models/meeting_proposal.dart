
class MeetingProposal {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String creatorId;
  final List<DateTime> proposedDates;
  final Map<int, List<String>> votes; // dateIndex -> list of userIds
  final DateTime? finalDate;
  final int createdAt;

  MeetingProposal({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.proposedDates,
    required this.votes,
    this.finalDate,
    required this.createdAt,
  });

  bool get isConfirmed => finalDate != null;

  factory MeetingProposal.fromJson(String id, Map<dynamic, dynamic> json) {
    final rawDates = json['proposedDates'] as List<dynamic>? ?? [];
    final proposedDates = rawDates.map((d) => DateTime.parse(d as String)).toList();

    final rawVotes = json['votes'];
    final votes = <int, List<String>>{};
    if (rawVotes is Map) {
      rawVotes.forEach((key, value) {
        final index = int.tryParse(key.toString()) ?? 0;
        final userIds = (value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        votes[index] = userIds;
      });
    } else if (rawVotes is List) {
      for (int i = 0; i < rawVotes.length; i++) {
        if (rawVotes[i] != null) {
          final userIds = (rawVotes[i] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          votes[i] = userIds;
        }
      }
    }

    return MeetingProposal(
      id: id,
      groupId: json['groupId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId'] ?? '',
      proposedDates: proposedDates,
      votes: votes,
      finalDate: json['finalDate'] != null ? DateTime.parse(json['finalDate'] as String) : null,
      createdAt: json['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final votesMap = <String, dynamic>{};
    votes.forEach((key, value) {
      votesMap[key.toString()] = value;
    });

    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'proposedDates': proposedDates.map((d) => d.toIso8601String()).toList(),
      'votes': votesMap,
      'finalDate': finalDate?.toIso8601String(),
      'createdAt': createdAt,
    };
  }
}
