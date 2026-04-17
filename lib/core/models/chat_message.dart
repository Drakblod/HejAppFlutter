class ChatMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final String? photoUrl;
  final String? contentType;
  final int ts;
  final String? replyToId;
  final String? replySenderName;
  final String? replyPreview;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    this.photoUrl,
    this.contentType,
    required this.ts,
    this.replyToId,
    this.replySenderName,
    this.replyPreview,
  });

  factory ChatMessage.fromJson(String id, Map<dynamic, dynamic> json) {
    return ChatMessage(
      id: id,
      groupId: json['groupId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'User',
      senderPhotoUrl: json['senderPhotoUrl'],
      text: json['text'] ?? '',
      photoUrl: json['photoUrl'],
      contentType: json['contentType'],
      ts: json['ts'] ?? 0,
      replyToId: json['replyToId'],
      replySenderName: json['replySenderName'],
      replyPreview: json['replyPreview'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'photoUrl': photoUrl,
      'contentType': contentType,
      'ts': ts,
      'replyToId': replyToId,
      'replySenderName': replySenderName,
      'replyPreview': replyPreview,
    };
  }
}
