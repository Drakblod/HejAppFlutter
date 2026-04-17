class UserProfile {
  final String uid;
  final String username;
  final String fullName;
  final String? email;
  final String? bio;
  final String? photoUrl;
  final int? createdAt;
  final int? updatedAt;

  UserProfile({
    required this.uid,
    required this.username,
    required this.fullName,
    this.email,
    this.bio,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(String uid, Map<dynamic, dynamic> json) {
    return UserProfile(
      uid: uid,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'],
      bio: json['bio'],
      photoUrl: json['photoUrl'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'fullName': fullName,
      'email': email,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
