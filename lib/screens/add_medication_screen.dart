import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication_reminder.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  final MedicationReminder? reminder;

  const AddMedicationScreen({super.key, this.reminder});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pillsController;
  List<TimeOfDay> _selectedTimes = [];
  bool _isEnabled = true;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reminder?.name ?? '');
    _pillsController = TextEditingController(
      text: widget.reminder?.pillsPerDose.toString() ?? '1',
    );
    _selectedTimes = widget.reminder?.times.toList() ?? [];
    _isEnabled = widget.reminder?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pillsController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTimes.add(picked);
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time')),
      );
      return;
    }

    try {
      final provider = context.read<MedicationProvider>();
      final name = _nameController.text.trim();
      final pills = int.tryParse(_pillsController.text) ?? 1;

      debugPrint('Saving medication: $name, pills: $pills, times: $_selectedTimes');

      if (_isEditing) {
        final updatedReminder = widget.reminder!.copyWith(
          name: name,
          pillsPerDose: pills,
          times: _selectedTimes,
          isEnabled: _isEnabled,
        );
        await provider.updateMedication(updatedReminder);
        debugPrint('Medication updated successfully');
      } else {
        await provider.addMedication(
          name: name,
          pills: pills,
          times: _selectedTimes,
          isEnabled: _isEnabled,
        );
        debugPrint('Medication added successfully');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving medication: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this medication reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<MedicationProvider>().deleteReminder(widget.reminder!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Medication' : 'Add Medication',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _deleteReminder,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication Name
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g., Metformin',
                      prefixIcon: Icon(Icons.medication, color: Colors.redAccent),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter medication name';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pills Per Dose
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _pillsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pills Per Dose',
                      hintText: 'e.g., 1',
                      prefixIcon: Icon(Icons.format_list_numbered, color: Colors.redAccent),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of pills';
                      }
                      final pills = int.tryParse(value);
                      if (pills == null || pills < 1) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Enable/Disable Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Enable Reminders'),
                  subtitle: Text(
                    _isEnabled ? 'Notifications are on' : 'Notifications are off',
                  ),
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.redAccent,
                  secondary: Icon(
                    _isEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: _isEnabled ? Colors.redAccent : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reminder Times Section
              const Text(
                'Reminder Times',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Add Time Button
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_alarm, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text(
                          'Add Reminder Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // List of Selected Times
              if (_selectedTimes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No reminder times added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...List.generate(_selectedTimes.length, (index) {
                  final time = _selectedTimes[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.redAccent),
                      title: Text(
                        time.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => _removeTime(index),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Update Medication' : 'Save Medication',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}