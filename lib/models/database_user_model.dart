import 'package:event_scheduler/firebase_constants.dart';

class DatabaseUser {
  final String uid;
  final String email;
  final String nickname;
  final List<String> groupIds;
  final List<String> acceptedEvents;

  DatabaseUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.groupIds,
    required this.acceptedEvents,
  });

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.email: email,
      FirebaseConstants.nickname: nickname,
      FirebaseConstants.userGroups: groupIds,
      FirebaseConstants.acceptedEvents: acceptedEvents,
    };
  }

  factory DatabaseUser.fromMap(Map<String, dynamic> map, String documentId) {
    return DatabaseUser(
      uid: documentId,
      email: map[FirebaseConstants.email] ?? '',
      nickname: map[FirebaseConstants.nickname] ?? 'User',
      groupIds: List<String>.from(map[FirebaseConstants.userGroups] ?? []),
      acceptedEvents: List<String>.from(
        (map[FirebaseConstants.acceptedEvents] ?? []),
      ),
    );
  }
}
