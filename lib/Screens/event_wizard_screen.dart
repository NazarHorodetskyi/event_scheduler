import 'package:event_scheduler/other/exceptions.dart';
import 'package:event_scheduler/providers/event_service_provider.dart';
import 'package:event_scheduler/providers/firebase_providers.dart';
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

  Future<void> submitEvent(String groupId) async {
    try {
      final eventService = ref.read(eventServiceProvider);
      final firebaseAuth = ref.read(firebaseAuthProvider);

      final currentUser = firebaseAuth.currentUser;
      if (currentUser == null) throw UserNotAuthenticatedException();

      await eventService.createEvent(
        groupId: groupId,
        creatorId: firebaseAuth.currentUser!.uid,
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
    NotifierProvider<EventWizardNotifier, EventWizard>(
      () => EventWizardNotifier(),
    );

class EventWizardScreen extends ConsumerStatefulWidget {
  const EventWizardScreen({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<EventWizardScreen> createState() => _EventWizardScreenState();
}

class _EventWizardScreenState extends ConsumerState<EventWizardScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 1;
  final int _totalPages = 3;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

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
        _showError('Назва має містити більше 3 символів');
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
      _showError('Будь ласка, оберіть дату та час події');
      return;
    }

    if (wizardState.time!.isBefore(DateTime.now())) {
      _showError('Час події вже минув. Оберіть майбутній час!');
      return;
    }

    await ref
        .read(eventWizardNotifierProvider.notifier)
        .submitEvent(widget.groupId);

    if (mounted) {
      Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(title: const Text('Створення події')),
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
                  labelText: 'Назва події',
                  border: OutlineInputBorder(),
                  hintText: 'Мінімум 4 символи...',
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
                  labelText: 'Опис події (опціонально)',
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
                        ? 'Час ще не обрано'
                        : 'Обрано: ${wizardState.time!.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Обрати дату та час'),
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
                child: const Text('Відміна'),
              )
            else
              TextButton(onPressed: _previousPage, child: const Text('Назад')),
            // Перевіряємо чи дійшли до кінця (3 == 3)
            if (_currentPage == _totalPages)
              ElevatedButton(
                onPressed: _submitEvent,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Створити'),
              )
            else
              ElevatedButton(onPressed: _nextPage, child: const Text('Далі')),
          ],
        ),
      ),
    );
  }
}
