import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/firebase_constants.dart';

class EventModel {
  final String eventId;
  final String groupId;
  final String creatorId;
  final String title;
  final String description;
  final DateTime eventDate;
  final List<String> participants;

  EventModel({
    required this.eventId,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.participants,
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
