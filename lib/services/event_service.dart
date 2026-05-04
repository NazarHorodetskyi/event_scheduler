import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/models/database_event_model.dart';

class EventService {
  EventService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Future<void> createEvent(
    String groupId,
    String creatorId,
    String title,
    String description,
    DateTime eventDate,
  ) async {
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
}
