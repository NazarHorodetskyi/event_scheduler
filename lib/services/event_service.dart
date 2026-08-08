import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/models/database_event_model.dart';

class EventService {
  EventService({required FirebaseFirestore db}) : _db = db;
  final FirebaseFirestore _db;

  Future<void> createEvent({
    required String groupId,
    required String groupName,
    required String creatorId,
    required String title,
    required String description,
    required DateTime eventDate,
  }) async {
    DocumentReference eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc();

    EventModel newEvent = EventModel(
      eventId: eventDocRef.id,
      groupId: groupId,
      groupName: groupName,
      creatorId: creatorId,
      title: title,
      description: description,
      eventDate: eventDate,
      participants: [creatorId],
      decliners: [],
    );

    await eventDocRef
        .set(newEvent.toMap())
        .timeout(
          Duration(seconds: 10),
          onTimeout: () => throw ConnectionErrorException(),
        );
  }

  Future<void> updateEvent({
    required String currentUserId,
    required String groupOwnerId,
    required String eventOwnerId,
    required String eventId,
    required Map<String, dynamic> newEventData,
  }) async {
    if (currentUserId != groupOwnerId && currentUserId != eventOwnerId) {
      throw Exception("You do not have enough rights for this operation");
    }

    Map<String, dynamic> updates = {
      ...newEventData,
      FirebaseConstants.eventEditTime: FieldValue.serverTimestamp(),
    };

    await _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId)
        .update(updates);
  }

  Future<List<EventModel>> getGroupEvents({required String groupId}) async {
    try {
      final snapshot = await _db
          .collection(FirebaseConstants.eventsCollection)
          .where(FirebaseConstants.eventGroupId, isEqualTo: groupId)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EventModel>> getUserEvents(List<String> groupsId) async {
    if (groupsId.isEmpty) {
      return [];
    }

    final snapshot = await _db
        .collection(FirebaseConstants.eventsCollection)
        .where(FirebaseConstants.eventGroupId, whereIn: groupsId)
        .orderBy(FirebaseConstants.eventDate)
        .get();

    return snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
  }

  Future<void> deleteEvent({
    required String currentUserId,
    required String eventOwnerId,
    required String groupOwnerId,
    required String eventId,
  }) async {
    try {
      if (currentUserId != eventOwnerId && currentUserId != groupOwnerId) {
        throw Exception("Only owner can delete an event!");
      }

      final eventRef = _db
          .collection(FirebaseConstants.eventsCollection)
          .doc(eventId);
      final eventDoc = await eventRef.get();

      if (!eventDoc.exists) {
        throw Exception("Event not found");
      }

      await eventRef.delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> agreeToEvent(String userId, String eventId) async {
    final eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId);

    await eventDocRef.update({
      FirebaseConstants.eventParticipants: FieldValue.arrayUnion([userId]),
      FirebaseConstants.eventDecliners: FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> declineTheEvent(String userId, String eventId) async {
    final eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId);

    await eventDocRef.update({
      FirebaseConstants.eventParticipants: FieldValue.arrayRemove([userId]),
      FirebaseConstants.eventDecliners: FieldValue.arrayUnion([userId]),
    });
  }
}
