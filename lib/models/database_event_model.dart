import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/firebase_constants.dart';

class EventModel {
  final String eventId;
  final String groupId;
  final String groupName;
  final String creatorId;
  final String title;
  final String description;
  final DateTime eventDate;
  final List<String> participants;
  final List<String> decliners;
  final DateTime? editTime;

  EventModel({
    required this.eventId,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.participants,
    required this.decliners,
    required this.groupName,
    this.editTime,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      eventId: documentId,
      groupId: map[FirebaseConstants.eventGroupId] ?? '',
      groupName: map[FirebaseConstants.eventGroupName] ?? "",
      creatorId: map[FirebaseConstants.eventOwnerId] ?? '',
      title: map[FirebaseConstants.eventTitle] ?? '',
      description: map[FirebaseConstants.eventDescription] ?? '',
      eventDate: (map[FirebaseConstants.eventDate] as Timestamp).toDate(),
      participants: List<String>.from(
        map[FirebaseConstants.eventParticipants] ?? [],
      ),
      decliners: List<String>.from(map[FirebaseConstants.eventDecliners] ?? []),

      editTime: map[FirebaseConstants.eventEditTime] != null
          ? (map[FirebaseConstants.eventEditTime] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.eventId: eventId,
      FirebaseConstants.eventGroupId: groupId,
      FirebaseConstants.eventGroupName: groupName,
      FirebaseConstants.eventOwnerId: creatorId,
      FirebaseConstants.eventTitle: title,
      FirebaseConstants.eventDescription: description,
      FirebaseConstants.eventDate: Timestamp.fromDate(eventDate),
      FirebaseConstants.eventParticipants: participants,
      FirebaseConstants.eventDecliners: decliners,

      FirebaseConstants.eventEditTime: editTime != null
          ? Timestamp.fromDate(editTime!)
          : null,
    };
  }
}
