class GalleryItem {
  final String id;
  final String groupId;
  final String imageUrl;
  final String caption;
  final String uploaderId;
  final String uploaderName;
  final int createdAt;

  GalleryItem({
    required this.id,
    required this.groupId,
    required this.imageUrl,
    required this.caption,
    required this.uploaderId,
    required this.uploaderName,
    required this.createdAt,
  });

  factory GalleryItem.fromJson(String id, Map<dynamic, dynamic> json) {
    return GalleryItem(
      id: id,
      groupId: json['groupId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'] ?? '',
      uploaderId: json['uploaderId'] ?? '',
      uploaderName: json['uploaderName'] ?? 'Anonymous',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'imageUrl': imageUrl,
      'caption': caption,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'createdAt': createdAt,
    };
  }
}
