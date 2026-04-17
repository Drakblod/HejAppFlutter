class GroupMember {
  final String uid;
  final String role;
  final int joinedAt;

  GroupMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(String uid, Map<dynamic, dynamic> json) {
    return GroupMember(
      uid: uid,
      role: json['role'] ?? 'member',
      joinedAt: json['joinedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'joinedAt': joinedAt,
  };
}
