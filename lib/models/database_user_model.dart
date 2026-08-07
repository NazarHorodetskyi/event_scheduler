import 'package:event_scheduler/other/firebase_constants.dart';

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
    return {
      FirebaseConstants.userId: uid,
      FirebaseConstants.email: email,
      FirebaseConstants.nickname: nickname,
      FirebaseConstants.userGroups: groupIds,
    };
  }

  factory DatabaseUser.fromMap(Map<String, dynamic> map) {
    return DatabaseUser(
      uid: map[FirebaseConstants.userId] ?? "",
      email: map[FirebaseConstants.email] ?? '',
      nickname: map[FirebaseConstants.nickname] ?? 'User',
      groupIds: List<String>.from(map[FirebaseConstants.userGroups] ?? []),
    );
  }
}
