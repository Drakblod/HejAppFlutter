class DirectConversation {
  final String id;
  final List<String> participantIds;
  final int updatedAt;
  final String? lastMessage;

  const DirectConversation({
    required this.id,
    required this.participantIds,
    required this.updatedAt,
    this.lastMessage,
  });

  factory DirectConversation.fromJson(String id, Map<dynamic, dynamic> json) {
    final participants =
        (json['participants'] as Map<dynamic, dynamic>?)?.keys
            .map((key) => key.toString())
            .toList() ??
        const <String>[];
    final timestamp = json['updatedAt'];
    return DirectConversation(
      id: id,
      participantIds: participants,
      updatedAt: timestamp is int ? timestamp : 0,
      lastMessage: json['lastMessage']?.toString(),
    );
  }

  String? otherParticipant(String currentUid) {
    for (final uid in participantIds) {
      if (uid != currentUid) return uid;
    }
    return null;
  }
}
