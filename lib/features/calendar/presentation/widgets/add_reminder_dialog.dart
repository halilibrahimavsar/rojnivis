import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';

class AddReminderDialog extends StatefulWidget {
  const AddReminderDialog({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  ImportanceLevel _importance = ImportanceLevel.low;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurpleAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2D2D44),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add Reminder',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Title',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Time:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => _selectTime(context),
                              icon: const Icon(
                                Icons.access_time,
                                color: Colors.deepPurpleAccent,
                              ),
                              label: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.05,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Importance:',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              ImportanceLevel.values.map((level) {
                                final isSelected = _importance == level;
                                Color color;
                                String label;
                                switch (level) {
                                  case ImportanceLevel.low:
                                    color = Colors.green;
                                    label = 'Low';
                                    break;
                                  case ImportanceLevel.medium:
                                    color = Colors.orange;
                                    label = 'Medium';
                                    break;
                                  case ImportanceLevel.high:
                                    color = Colors.red;
                                    label = 'High';
                                    break;
                                }

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _importance = level;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? color.withValues(alpha: 0.25)
                                              : Colors.white.withValues(
                                                alpha: 0.05,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? color
                                                : Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final reminderDate = DateTime(
                                  widget.selectedDate.year,
                                  widget.selectedDate.month,
                                  widget.selectedDate.day,
                                  _selectedTime.hour,
                                  _selectedTime.minute,
                                );

                                final reminder = Reminder(
                                  id:
                                      DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                  title: _titleController.text.trim(),
                                  description:
                                      _descController.text.trim().isEmpty
                                          ? null
                                          : _descController.text.trim(),
                                  date: reminderDate,
                                  importanceLevel: _importance,
                                );

                                Navigator.of(context).pop(reminder);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Reminder',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
