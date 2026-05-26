class Suggestion {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String status; // 'new' | 'in_progress' | 'done'
  final int createdAt;

  Suggestion({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.createdAt,
  });

  factory Suggestion.fromJson(String id, Map<dynamic, dynamic> json) {
    return Suggestion(
      id: id,
      groupId: json['groupId'] ?? '',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? 'Anonymous',
      status: json['status'] ?? 'new',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
