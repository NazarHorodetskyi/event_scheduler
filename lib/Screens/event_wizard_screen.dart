import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scheduler/models/database_event_model.dart';
import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/other/firebase_constants.dart';
import 'package:event_scheduler/providers/auth_service_provider.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Data saving model
class EventWizard {
  String title;
  String description;
  DateTime? time;

  EventWizard({this.title = '', this.description = '', this.time});

  EventWizard copyWith({String? title, String? description, DateTime? time}) {
    return EventWizard(
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
    );
  }
}

// A notifier with methods to change state
class EventWizardNotifier extends Notifier<EventWizard> {
  @override
  EventWizard build() {
    return EventWizard();
  }

  void updateTitle(String newTitle) {
    state = state.copyWith(title: newTitle);
  }

  void updateTime(DateTime newTime) {
    state = state.copyWith(time: newTime);
  }

  void updateDescription(String newDescription) {
    state = state.copyWith(description: newDescription);
  }

  Future<void> submitEvent({
    required String groupId,
    required String groupName,
    String? eventId,
    String? eventOwnerId,
    String? groupOwnerId,
  }) async {
    try {
      final eventService = ref.read(eventServiceProvider);
      final authService = ref.read(authServiceProvider);

      final currentUser = authService.currentUser;
      if (currentUser == null) throw UserNotAuthenticatedException();

      // Event editing block
      if (eventId != null && eventOwnerId != null && groupOwnerId != null) {
        final newEventData = {
          FirebaseConstants.eventTitle: state.title,
          FirebaseConstants.eventDescription: state.description,
          FirebaseConstants.eventDate: Timestamp.fromDate(state.time!),
          FirebaseConstants.eventEditTime: FieldValue.serverTimestamp(),
        };

        await eventService.updateEvent(
          currentUserId: currentUser.uid,
          eventOwnerId: eventOwnerId,
          groupOwnerId: groupOwnerId,
          eventId: eventId,
          newEventData: newEventData,
        );
        state = EventWizard();
        return;
      }

      // Default creating block
      await eventService.createEvent(
        groupId: groupId,
        groupName: groupName,
        creatorId: currentUser.uid,
        title: state.title,
        description: state.description,
        eventDate: state.time!,
      );

      state = EventWizard();
    } catch (e) {
      rethrow;
    }
  }
}

// Actual provider which provides a notifier
final eventWizardNotifierProvider =
    NotifierProvider.autoDispose<EventWizardNotifier, EventWizard>(
      () => EventWizardNotifier(),
    );

// if event and group owner id provided - update
class EventWizardScreen extends ConsumerStatefulWidget {
  const EventWizardScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.existingEvent,
    this.groupOwnerId,
  });

  final String groupId; // required data
  final String groupName;
  // optional data for update
  final EventModel? existingEvent;
  final String? groupOwnerId;

  @override
  ConsumerState<EventWizardScreen> createState() => _EventWizardScreenState();
}

class _EventWizardScreenState extends ConsumerState<EventWizardScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 1;
  final int _totalPages = 3;
  bool _isLoading = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final event = widget.existingEvent;

    if (event != null) {
      _titleController.text = event.title;
      _descController.text = event.description;

      Future.microtask(() {
        final notifier = ref.read(eventWizardNotifierProvider.notifier);
        notifier.updateTitle(event.title);
        notifier.updateDescription(event.description);
        notifier.updateTime(event.eventDate);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    ref.read(eventWizardNotifierProvider.notifier).updateTime(combinedDateTime);
  }

  void _nextPage() {
    if (_currentPage == 1) {
      if (_titleController.text.trim().length <= 3) {
        _showError('Event name should have at least 3 symbols');
        return;
      }
      ref
          .read(eventWizardNotifierProvider.notifier)
          .updateTitle(_titleController.text);
    }

    if (_currentPage == 2) {
      ref
          .read(eventWizardNotifierProvider.notifier)
          .updateDescription(_descController.text);
    }

    if (_currentPage < _totalPages) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitEvent() async {
    final wizardState = ref.read(eventWizardNotifierProvider);

    if (wizardState.time == null) {
      _showError('Pick date and time!');
      return;
    }

    if (wizardState.time!.isBefore(DateTime.now())) {
      _showError('Pick future time!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(eventWizardNotifierProvider.notifier)
          .submitEvent(
            groupId: widget.groupId,
            groupName: widget.groupName,
            eventId: widget.existingEvent?.eventId,
            eventOwnerId: widget.existingEvent?.creatorId,
            groupOwnerId: widget.groupOwnerId,
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError("Event creation error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(eventWizardNotifierProvider);
    final bool isCreating = widget.existingEvent == null ? true : false;

    return Scaffold(
      appBar: AppBar(
        title: isCreating
            ? const Text('Event creation')
            : const Text("Event editing"),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int index) => setState(() => _currentPage = index + 1),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event name',
                  border: OutlineInputBorder(),
                  hintText: 'At leat 4 symbols...',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Event description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wizardState.time == null
                        ? 'Time is not picked'
                        : 'Picked: ${wizardState.time!.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Pick time'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Тепер перевіряємо чи це крок 1
            if (_currentPage == 1)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )
            else
              TextButton(
                onPressed: _previousPage,
                child: const Text('Previous'),
              ),
            // Перевіряємо чи дійшли до кінця (3 == 3)
            if (_currentPage == _totalPages)
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: isCreating
                          ? const Text('Create')
                          : const Text('Edit'),
                    )
            else
              ElevatedButton(onPressed: _nextPage, child: const Text('Next')),
          ],
        ),
      ),
    );
  }
}
