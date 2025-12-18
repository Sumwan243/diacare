import 'package:diacare/models/medication_reminder.dart';
import 'package:diacare/providers/medication_log_provider.dart';
import 'package:diacare/screens/add_medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/medication_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  void _navigateAndRefresh(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medProv = context.watch<MedicationProvider>();
    final logProv = context.watch<MedicationLogProvider>();

    final allReminders = medProv.reminders.expand((med) {
      return med.times.map((time) => {'medication': med, 'time': time});
    }).toList();

    final groupedReminders = groupBy(allReminders, (reminder) => (reminder['time'] as TimeOfDay).format(context));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Today', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined)),
        ],
      ),
      body: Column(
        children: [
          _buildAddReminderCard(theme),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                if (groupedReminders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Center(child: Text("Press \"Add Medication Reminder\" to begin.")),
                  ),
                ...groupedReminders.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(entry.key, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                      ...entry.value.map((r) => _buildReminderCard(r['medication'] as MedicationReminder, r['time'] as TimeOfDay, logProv, theme)).toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReminderCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: InkWell(
          onTap: () => _navigateAndRefresh(const AddMedicationScreen()),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 16),
                Text('Add Medication Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(MedicationReminder medication, TimeOfDay time, MedicationLogProvider logProv, ThemeData theme) {
    final isChecked = logProv.isDoseTaken(medication.id, time);

    return Card(
      color: isChecked ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
      elevation: isChecked ? 0 : 2,
      child: ListTile(
        onTap: () => logProv.logDose(medication.id, time, !isChecked),
        onLongPress: () => _navigateAndRefresh(AddMedicationScreen(reminder: medication)),
        leading: Icon(Icons.medication, color: theme.colorScheme.primary),
        title: Text(
          medication.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isChecked ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
            decoration: isChecked ? TextDecoration.lineThrough : null,
            decorationThickness: 2,
          ),
        ),
        subtitle: Text('${medication.pillsPerDose} tablet(s)'),
        trailing: Checkbox(
          value: isChecked,
          onChanged: (val) => logProv.logDose(medication.id, time, val ?? false),
          activeColor: theme.colorScheme.primary,
          shape: const CircleBorder(),
          side: BorderSide(color: theme.colorScheme.outline, width: 2),
        ),
      ),
    );
  }
}
