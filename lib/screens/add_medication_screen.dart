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

  // State for Times
  List<TimeOfDay> _selectedTimes = [];

  // State for Weekdays (Mon-Sun) - Default to all true
  List<bool> _selectedWeekdays = List.generate(7, (index) => true);

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

    // TODO: If your MedicationReminder model supports days, load them here.
    // Example: _selectedWeekdays = widget.reminder?.weekdays ?? List.generate(7, (index) => true);
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
    _addTime(picked);
  }

  void _addTime(TimeOfDay time) {
    setState(() {
      if (_selectedTimes.any((t) => _timeEquals(t, time))) return;
      _selectedTimes.add(time);
      _selectedTimes.sort(_compareTimes);
    });
  }

  void _removeTime(int index) {
    setState(() => _selectedTimes.removeAt(index));
  }

  void _toggleWeekday(int index) {
    setState(() {
      _selectedWeekdays[index] = !_selectedWeekdays[index];
    });
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one reminder time')),
      );
      return;
    }

    // Optional: Validation to ensure at least one day is selected
    if (!_selectedWeekdays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day of the week')),
      );
      return;
    }

    try {
      final provider = context.read<MedicationProvider>();
      final name = _nameController.text.trim();
      final pills = int.tryParse(_pillsController.text.trim()) ?? 1;

      // Note: You need to update your MedicationReminder model to accept 'weekdays'
      // For now, this code assumes the existing structure but implies where to add it.

      if (_isEditing) {
        final updated = widget.reminder!.copyWith(
          name: name,
          pillsPerDose: pills,
          times: _selectedTimes,
          isEnabled: _isEnabled,
          // weekdays: _selectedWeekdays, // Add this to your model
        );
        await provider.updateMedication(updated);
      } else {
        await provider.addMedication(
          name: name,
          pills: pills,
          times: _selectedTimes,
          isEnabled: _isEnabled,
          // weekdays: _selectedWeekdays, // Add this to your model
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
    // ... (Keep existing delete logic)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      await context.read<MedicationProvider>().deleteReminder(widget.reminder!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'New Schedule'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _deleteReminder,
              icon: Icon(Icons.delete_rounded, color: cs.error),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Basic Info Section
              _buildSectionHeader(context, 'Medication Details'),
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g., Metformin',
                        filled: true,
                        fillColor: cs.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.medication, color: cs.primary),
                      ),
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pillsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Pills/Dose',
                              hintText: '1',
                              filled: true,
                              fillColor: cs.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              prefixIcon: Icon(Icons.numbers, color: cs.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SwitchListTile(
                              title: const Text('Active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              value: _isEnabled,
                              onChanged: (v) => setState(() => _isEnabled = v),
                              dense: true,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Frequency / Days Section
              _buildSectionHeader(context, 'Frequency'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('Tap to toggle specific days', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final isSelected = _selectedWeekdays[index];
                        return GestureDetector(
                          onTap: () => _toggleWeekday(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary : cs.surface,
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: cs.primary.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))]
                                  : null,
                              border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              days[index],
                              style: TextStyle(
                                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Schedule / Times Section
              _buildSectionHeader(context, 'Schedule'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Add Buttons
                    const Text('Quick Add', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickAddChip(context, 'Morning', const TimeOfDay(hour: 8, minute: 0), Icons.wb_sunny_outlined),
                        _buildQuickAddChip(context, 'Lunch', const TimeOfDay(hour: 12, minute: 0), Icons.restaurant_menu),
                        _buildQuickAddChip(context, 'Night', const TimeOfDay(hour: 20, minute: 0), Icons.bedtime_outlined),
                      ],
                    ),
                    const Divider(height: 24),

                    // Selected Times Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Selected Times', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Custom'),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_selectedTimes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No times set.', style: TextStyle(color: cs.onSurfaceVariant)),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_selectedTimes.length, (index) {
                          final time = _selectedTimes[index];
                          return InputChip(
                            label: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                            onDeleted: () => _removeTime(index),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: cs.primaryContainer,
                            labelStyle: TextStyle(color: cs.onPrimaryContainer),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                          );
                        }),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _saveReminder,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Start Schedule',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickAddChip(BuildContext context, String label, TimeOfDay time, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () => _addTime(time),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}