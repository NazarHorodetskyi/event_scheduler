import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/models/database_event_model.dart';

class EventService {
  EventService({required FirebaseFirestore db}) : _db = db;
  final FirebaseFirestore _db;

  Future<void> createEvent({
    required String groupId,
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
      creatorId: creatorId,
      title: title,
      description: description,
      eventDate: eventDate,
      participants: [creatorId],
    );

    WriteBatch batch = _db.batch();
    batch.set(eventDocRef, newEvent.toMap());
    DocumentReference userDocRef = _db
        .collection(FirebaseConstants.usersCollection)
        .doc(creatorId);
    batch.update(userDocRef, {
      FirebaseConstants.acceptedEvents: FieldValue.arrayUnion([eventDocRef.id]),
    });

    await batch.commit().timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ConnectionErrorException(),
    );
  }

  Future<List<EventModel>> getAllEvents({required String groupId}) async {
    try {
      final snapshot = await _db
          .collection(FirebaseConstants.eventsCollection)
          .where(FirebaseConstants.eventGroupId, isEqualTo: groupId)
          .get();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent({
    required String eventId,
    required String currentUserId,
  }) async {
    try {
      final eventRef = _db
          .collection(FirebaseConstants.eventsCollection)
          .doc(eventId);
      final eventDoc = await eventRef.get();

      if (!eventDoc.exists) {
        throw Exception("Event not found");
      }

      final eventData = eventDoc.data()!;
      final String ownerId = eventData[FirebaseConstants.eventCreatorId];

      if (ownerId != currentUserId) {
        throw Exception("Only owner can delete an event!");
      }

      WriteBatch batch = _db.batch();
      batch.delete(eventRef); //delete event document

      final participantsQuery = await _db
          .collection(FirebaseConstants.usersCollection)
          .where(FirebaseConstants.acceptedEvents, arrayContains: eventId)
          .get();

      for (var userDoc in participantsQuery.docs) {
        batch.update(userDoc.reference, {
          FirebaseConstants.acceptedEvents: FieldValue.arrayRemove([eventId]),
        });
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
