class Group {
  final String id;
  final String name;
  final String icon;
  final String theme;
  final String ownerId;
  final String? backgroundImage;
  final int createdAt;

  Group({
    required this.id,
    required this.name,
    required this.icon,
    required this.theme,
    required this.ownerId,
    this.backgroundImage,
    required this.createdAt,
  });

  factory Group.fromJson(String id, Map<dynamic, dynamic> json) {
    return Group(
      id: id,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '👥',
      theme: json['theme'] ?? 'Default',
      ownerId: json['ownerId'] ?? '',
      backgroundImage: json['backgroundImage'],
      createdAt: json['createdAt'] ?? 0,
    );
  }
}
