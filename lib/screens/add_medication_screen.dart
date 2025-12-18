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

  late final TextEditingController _nameController;
  late final TextEditingController _pillsController;

  List<TimeOfDay> _selectedTimes = [];
  bool _isEnabled = true;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reminder?.name ?? '');
    _pillsController = TextEditingController(
      text: (widget.reminder?.pillsPerDose ?? 1).toString(),
    );
    _selectedTimes = widget.reminder?.times.toList() ?? [];
    _selectedTimes.sort(_compareTimes);
    _isEnabled = widget.reminder?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pillsController.dispose();
    super.dispose();
  }

  int _compareTimes(TimeOfDay a, TimeOfDay b) {
    final ah = a.hour, am = a.minute;
    final bh = b.hour, bm = b.minute;
    if (ah != bh) return ah.compareTo(bh);
    return am.compareTo(bm);
  }

  bool _timeEquals(TimeOfDay a, TimeOfDay b) =>
      a.hour == b.hour && a.minute == b.minute;

  Future<void> _pickTime() async {
    final initial = _selectedTimes.isNotEmpty ? _selectedTimes.last : TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked == null) return;

    setState(() {
      // avoid duplicates
      if (_selectedTimes.any((t) => _timeEquals(t, picked))) return;
      _selectedTimes.add(picked);
      _selectedTimes.sort(_compareTimes);
    });
  }

  void _removeTime(int index) {
    setState(() => _selectedTimes.removeAt(index));
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time')),
      );
      return;
    }

    try {
      final provider = context.read<MedicationProvider>();
      final name = _nameController.text.trim();
      final pills = int.tryParse(_pillsController.text.trim()) ?? 1;

      if (_isEditing) {
        final updated = widget.reminder!.copyWith(
          name: name,
          pillsPerDose: pills,
          times: _selectedTimes,
          isEnabled: _isEnabled,
        );
        await provider.updateMedication(updated);
      } else {
        await provider.addMedication(
          name: name,
          pills: pills,
          times: _selectedTimes,
          isEnabled: _isEnabled,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  Future<void> _deleteReminder() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this medication reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<MedicationProvider>().deleteReminder(widget.reminder!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final titleText = _isEditing ? 'Edit Medication' : 'Add Medication';

    return Scaffold(
      // Let Material 3 theme control surfaces.
      appBar: AppBar(
        title: Text(titleText),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _deleteReminder,
              icon: Icon(Icons.delete_outline, color: cs.error),
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
              Text('Details', style: textTheme.titleMedium),
              const SizedBox(height: 12),

              // Medication name
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g., Metformin',
                      prefixIcon: Icon(Icons.medication_outlined, color: cs.primary),
                      border: const OutlineInputBorder(),
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
              const SizedBox(height: 12),

              // Pills per dose
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _pillsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Pills Per Dose',
                      hintText: 'e.g., 1',
                      prefixIcon: Icon(Icons.format_list_numbered, color: cs.primary),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter number of pills';
                      }
                      final pills = int.tryParse(value.trim());
                      if (pills == null || pills < 1) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Enable/disable
              Card(
                child: SwitchListTile.adaptive(
                  title: const Text('Enable reminders'),
                  subtitle: Text(_isEnabled ? 'Notifications are on' : 'Notifications are off'),
                  value: _isEnabled,
                  onChanged: (v) => setState(() => _isEnabled = v),
                  secondary: Icon(
                    _isEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: _isEnabled ? cs.primary : cs.outline,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('Reminder Times', style: textTheme.titleMedium),
              const SizedBox(height: 12),

              // Add time (tonal button to match M3)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Add reminder time'),
                ),
              ),

              const SizedBox(height: 12),

              if (_selectedTimes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'No reminder times added yet',
                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...List.generate(_selectedTimes.length, (index) {
                  final time = _selectedTimes[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: cs.primary),
                      title: Text(
                        time.format(context),
                        style: textTheme.titleMedium,
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove',
                        icon: Icon(Icons.close, color: cs.outline),
                        onPressed: () => _removeTime(index),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Save button (primary filled)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveReminder,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(_isEditing ? 'Update Medication' : 'Save Medication'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}