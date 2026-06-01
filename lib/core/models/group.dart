class Group {
  final String id;
  final String name;
  final String icon;
  final String theme;
  final String ownerId;
  final String? backgroundImage;
  final String? description;
  final String? boardLabel;
  final String? chatLabel;
  final String? filesLabel;
  final String? ocrLabel;
  final String? galleryLabel;
  final String? fontFamily;
  final String baseColor;
  final Map<String, bool> enabledModules;
  final int createdAt;

  Group({
    required this.id,
    required this.name,
    required this.icon,
    required this.theme,
    required this.ownerId,
    this.backgroundImage,
    this.description,
    this.boardLabel,
    this.chatLabel,
    this.filesLabel,
    this.ocrLabel,
    this.galleryLabel,
    this.fontFamily,
    required this.baseColor,
    required this.enabledModules,
    required this.createdAt,
  });

  factory Group.fromJson(String id, Map<dynamic, dynamic> json) {
    // Default modules if not present
    final rawModules = json['enabledModules'] as Map<dynamic, dynamic>?;
    final enabledModules = <String, bool>{
      'board': rawModules?['board'] ?? true,
      'chat': rawModules?['chat'] ?? true,
      'files': rawModules?['files'] ?? true,
      'calendar': rawModules?['calendar'] ?? true,
      'ocr': rawModules?['ocr'] ?? false,
      'gallery': rawModules?['gallery'] ?? false,
    };

    return Group(
      id: id,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '👥',
      theme: json['theme'] ?? 'Default',
      ownerId: json['ownerId'] ?? '',
      backgroundImage: json['backgroundImage'],
      description: json['description'],
      boardLabel: json['boardLabel'],
      chatLabel: json['chatLabel'],
      filesLabel: json['filesLabel'],
      ocrLabel: json['ocrLabel'],
      galleryLabel: json['galleryLabel'],
      fontFamily: json['fontFamily'],
      baseColor: json['baseColor'] ?? '0xFF2F7D32',
      enabledModules: enabledModules,
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
      'description': description,
      'boardLabel': boardLabel,
      'chatLabel': chatLabel,
      'filesLabel': filesLabel,
      'ocrLabel': ocrLabel,
      'galleryLabel': galleryLabel,
      'fontFamily': fontFamily,
      'baseColor': baseColor,
      'enabledModules': enabledModules,
      'createdAt': createdAt,
    };
  }
}
