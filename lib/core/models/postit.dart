class PostIt {
  final String id;
  final String groupId;
  final String senderId;
  final String text;
  final String textColor;
  final int ts;

  PostIt({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.textColor,
    required this.ts,
  });

  factory PostIt.fromJson(String id, Map<dynamic, dynamic> json) {
    return PostIt(
      id: id,
      groupId: json['groupId'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      textColor: json['textColor'] ?? 'Black',
      ts: json['ts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'text': text,
      'textColor': textColor,
      'ts': ts,
    };
  }
}
