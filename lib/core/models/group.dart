class Group {
  final String id;
  final String name;
  final String icon;
  final String theme;
  final String ownerId;
  final String? backgroundImage;
  final String? boardLabel;
  final String? chatLabel;
  final String? filesLabel;
  final String? fontFamily;
  final int createdAt;

  Group({
    required this.id,
    required this.name,
    required this.icon,
    required this.theme,
    required this.ownerId,
    this.backgroundImage,
    this.boardLabel,
    this.chatLabel,
    this.filesLabel,
    this.fontFamily,
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
      boardLabel: json['boardLabel'],
      chatLabel: json['chatLabel'],
      filesLabel: json['filesLabel'],
      fontFamily: json['fontFamily'],
      createdAt: json['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'theme': theme,
      'ownerId': ownerId,
      'backgroundImage': backgroundImage,
      'boardLabel': boardLabel,
      'chatLabel': chatLabel,
      'filesLabel': filesLabel,
      'fontFamily': fontFamily,
      'createdAt': createdAt,
    };
  }
}
