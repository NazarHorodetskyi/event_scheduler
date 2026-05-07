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
}

// Actual provider which provides a notifier
final eventWizardNotifierProvider =
    NotifierProvider<EventWizardNotifier, EventWizard>(
      () => EventWizardNotifier(),
    );

class EventWizardScreen extends StatefulWidget {
  const EventWizardScreen({super.key});

  @override
  State<EventWizardScreen> createState() => _EventWizardScreenState();
}

class _EventWizardScreenState extends State<EventWizardScreen> {
  final PageController _pageController = PageController();

  // ТЕПЕР СТАРТУЄМО З 1
  int _currentPage = 1;
  final int _totalPages = 3;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDateTime;

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

    setState(() {
      _selectedDateTime = combinedDateTime;
    });
  }

  void _nextPage() {
    if (_currentPage == 1) {
      if (_titleController.text.trim().length <= 3) {
        _showError('Назва має містити більше 3 символів');
        return;
      }
    }
    if (_currentPage == 2) {}

    if (_currentPage < _totalPages) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _submitEvent() {
    if (_selectedDateTime == null) {
      _showError('Будь ласка, оберіть дату та час події');
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      _showError('Час події вже минув. Оберіть майбутній час!');
      return;
    }

    print("УСПІХ! Назва: ${_titleController.text}, Дата: $_selectedDateTime");
    Navigator.pop(context);
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
                    _selectedDateTime == null
                        ? 'Час ще не обрано'
                        : 'Обрано: ${_selectedDateTime.toString().substring(0, 16)}',
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
