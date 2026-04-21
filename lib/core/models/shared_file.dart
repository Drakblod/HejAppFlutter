class SharedFile {
  final String id;
  final String groupId;
  final String name;
  final String url;
  final String type;
  final int size;
  final String senderId;
  final String senderName;
  final int ts;

  SharedFile({
    required this.id,
    required this.groupId,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.senderId,
    required this.senderName,
    required this.ts,
  });

  factory SharedFile.fromJson(String id, Map<dynamic, dynamic> json) {
    return SharedFile(
      id: id,
      groupId: json['groupId'] ?? '',
      name: json['name'] ?? 'Untitled',
      url: json['url'] ?? '',
      type: json['type'] ?? 'unknown',
      size: (json['size'] as num?)?.toInt() ?? 0,
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      ts: (json['ts'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'senderId': senderId,
      'senderName': senderName,
      'ts': ts,
    };
  }
}
