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
      decliners: [],
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

  Future<void> agreeToEvent(String userId, String eventId) async {
    final userDocRef = _db
        .collection(FirebaseConstants.usersCollection)
        .doc(userId);
    final eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId);

    WriteBatch batch = _db.batch();

    // Add event to user
    batch.update(userDocRef, {
      FirebaseConstants.acceptedEvents: FieldValue.arrayUnion([eventId]),
    });

    // Add user to event participants and remove from decliners
    batch.update(eventDocRef, {
      FirebaseConstants.eventParticipants: FieldValue.arrayUnion([userId]),
      FirebaseConstants.eventDecliners: FieldValue.arrayRemove([userId]),
    });

    await batch.commit();
  }

  Future<void> declineTheEvent(String userId, String eventId) async {
    final userDocRef = _db
        .collection(FirebaseConstants.usersCollection)
        .doc(userId);
    final eventDocRef = _db
        .collection(FirebaseConstants.eventsCollection)
        .doc(eventId);

    WriteBatch batch = _db.batch();

    // Remove event from user
    batch.update(userDocRef, {
      FirebaseConstants.acceptedEvents: FieldValue.arrayRemove([eventId]),
    });

    // Add user to decliners and remove from participants
    batch.update(eventDocRef, {
      FirebaseConstants.eventParticipants: FieldValue.arrayRemove([userId]),
      FirebaseConstants.eventDecliners: FieldValue.arrayUnion([userId]),
    });

    await batch.commit();
  }
}
