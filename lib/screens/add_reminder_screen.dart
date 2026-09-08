import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  ReminderType _selectedType = ReminderType.medication;
  ReminderFrequency _selectedFrequency = ReminderFrequency.daily;

  List<String> _selectedTimes = ['08:00'];
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Default all days
  int _intervalDays = 2;

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

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final reminderProvider = context.read<ReminderProvider>();

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first')));
        return;
      }

      final reminder = ReminderModel(
        userId: authProvider.currentUser!.id,
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success = await reminderProvider.createReminder(reminder);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminder created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reminderProvider.errorMessage ?? 'Failed to create reminder',
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
        title: const Text('Add Reminder'),
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

              // Custom Interval
              if (_selectedFrequency == ReminderFrequency.customInterval) ...[
                Row(
                  children: [
                    const Text('Repeat every', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: _intervalDays.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _intervalDays = int.tryParse(value) ?? 2;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('days'),
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
                onPressed: _saveReminder,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Reminder',
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
