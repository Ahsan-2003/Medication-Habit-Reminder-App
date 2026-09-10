import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';

class EditReminderScreen extends StatefulWidget {
  final ReminderModel reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  late ReminderType _selectedType;
  late ReminderFrequency _selectedFrequency;
  late List<String> _selectedTimes;
  late List<int> _selectedDays;
  late int _intervalDays;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reminder.name);
    _dosageController = TextEditingController(
      text: widget.reminder.dosage ?? '',
    );
    _notesController = TextEditingController(text: widget.reminder.notes ?? '');
    _selectedType = widget.reminder.type;
    _selectedFrequency = widget.reminder.frequency;
    _selectedTimes = List.from(widget.reminder.times);
    _selectedDays = widget.reminder.daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];
    _intervalDays = widget.reminder.intervalDays ?? 2;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _selectedTimes.add(timeString);
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  Future<void> _updateReminder() async {
    if (_formKey.currentState!.validate()) {
      final reminderProvider = context.read<ReminderProvider>();

      final updatedReminder = ReminderModel(
        id: widget.reminder.id,
        userId: widget.reminder.userId,
        name: _nameController.text.trim(),
        type: _selectedType,
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        times: _selectedTimes,
        frequency: _selectedFrequency,
        daysOfWeek: _selectedFrequency == ReminderFrequency.specificDays
            ? _selectedDays
            : null,
        intervalDays: _selectedFrequency == ReminderFrequency.customInterval
            ? _intervalDays
            : null,
        isActive: widget.reminder.isActive,
        createdAt: widget.reminder.createdAt,
        updatedAt: DateTime.now(),
      );

      print('✏️ Updating reminder: ${updatedReminder.id}');
      print('📝 New name: ${updatedReminder.name}');
      print('⏰ New times: ${updatedReminder.times}');

      bool success = await reminderProvider.updateReminder(updatedReminder);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reminderProvider.errorMessage ?? 'Failed to update reminder',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reminder'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reminder Type Selection
              const Text(
                'Reminder Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      type: ReminderType.medication,
                      icon: '💊',
                      label: 'Medication',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeCard(
                      type: ReminderType.habit,
                      icon: '🎯',
                      label: 'Habit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _selectedType == ReminderType.medication
                      ? 'Medication Name'
                      : 'Habit Name',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dosage Field (only for medication)
              if (_selectedType == ReminderType.medication) ...[
                TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage (e.g., 500mg)',
                    prefixIcon: const Icon(Icons.medication),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Frequency Selection
              const Text(
                'Frequency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ReminderFrequency>(
                value: _selectedFrequency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.repeat),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ReminderFrequency.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: ReminderFrequency.specificDays,
                    child: Text('Specific Days'),
                  ),
                  DropdownMenuItem(
                    value: ReminderFrequency.customInterval,
                    child: Text('Custom Interval'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Specific Days Selection
              if (_selectedFrequency == ReminderFrequency.specificDays) ...[
                const Text(
                  'Select Days',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildDayChip(1, 'Mon'),
                    _buildDayChip(2, 'Tue'),
                    _buildDayChip(3, 'Wed'),
                    _buildDayChip(4, 'Thu'),
                    _buildDayChip(5, 'Fri'),
                    _buildDayChip(6, 'Sat'),
                    _buildDayChip(7, 'Sun'),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Time Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder Times',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTimes.asMap().entries.map((entry) {
                  return Chip(
                    label: Text(entry.value),
                    onDeleted: _selectedTimes.length > 1
                        ? () => _removeTime(entry.key)
                        : null,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    backgroundColor: Colors.teal.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _updateReminder,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Reminder',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required ReminderType type,
    required String icon,
    required String label,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.teal : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(int day, String label) {
    final isSelected = _selectedDays.contains(day);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
            _selectedDays.sort();
          } else {
            _selectedDays.remove(day);
          }
        });
      },
      selectedColor: Colors.teal.withOpacity(0.2),
      checkmarkColor: Colors.teal,
    );
  }
}
