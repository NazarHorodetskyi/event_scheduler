import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/firebase_constants.dart';

class EventModel {
  final String eventId;
  final String groupId;
  final String creatorId;
  final String title;
  final String description;
  final DateTime eventDate;
  final List<String> participants;
  final List<String> decliners;

  EventModel({
    required this.eventId,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.participants,
    required this.decliners,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      eventId: documentId,
      groupId: map[FirebaseConstants.eventGroupId] ?? '',
      creatorId: map[FirebaseConstants.eventCreatorId] ?? '',
      title: map[FirebaseConstants.eventTitle] ?? '',
      description: map[FirebaseConstants.eventDescription] ?? '',
      eventDate: (map[FirebaseConstants.eventDate] as Timestamp).toDate(),
      participants: List<String>.from(
        map[FirebaseConstants.eventParticipants] ?? [],
      ),
      decliners: List<String>.from(map[FirebaseConstants.eventDecliners] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.eventGroupId: groupId,
      FirebaseConstants.eventCreatorId: creatorId,
      FirebaseConstants.eventTitle: title,
      FirebaseConstants.eventDescription: description,
      FirebaseConstants.eventDate: Timestamp.fromDate(eventDate),
      FirebaseConstants.eventParticipants: participants,
    };
  }
}
