class DatabaseUser {
  final String uid;
  final String email;
  final String nickname;
  final List<String> groupIds;

  DatabaseUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.groupIds,
  });

  Map<String, dynamic> toMap() {
    return {'email': email, 'nickname': nickname, 'groupIds': groupIds};
  }

  factory DatabaseUser.fromMap(Map<String, dynamic> map, String documentId) {
    return DatabaseUser(
      uid: documentId,
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? 'User',
      groupIds: List<String>.from(map['groupIds'] ?? []),
    );
  }
}
