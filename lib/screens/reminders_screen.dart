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
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers
    final medProv = context.watch<MedicationProvider>();
    final logProv = context.watch<MedicationLogProvider>();

    final allReminders = medProv.reminders.expand((med) {
      return med.times.map((time) => {'medication': med, 'time': time});
    }).toList();

    final groupedReminders = groupBy(allReminders, (reminder) => (reminder['time'] as TimeOfDay).format(context));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Today', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined, color: Colors.black)),
        ],
      ),
      body: Column(
        children: [
          _buildAddReminderCard(),
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
                        child: Text(entry.key, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...entry.value.map((r) => _buildReminderCard(r['medication'] as MedicationReminder, r['time'] as TimeOfDay, logProv)).toList(),
                    ],
                  );
                }).toList(),
                if (groupedReminders.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  // Confirm all button can be added back here if needed
                  const SizedBox(height: 40),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReminderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateAndRefresh(const AddMedicationScreen()),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.redAccent, size: 28),
                SizedBox(width: 16),
                Text('Add Medication Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(MedicationReminder medication, TimeOfDay time, MedicationLogProvider logProv) {
    final isChecked = logProv.isDoseTaken(medication.id, time);

    return Opacity(
      opacity: isChecked ? 0.6 : 1.0,
      child: Card(
        elevation: isChecked ? 1 : 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: isChecked ? Colors.grey.shade200 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: () => logProv.logDose(medication.id, time, !isChecked),
          onLongPress: () => _navigateAndRefresh(AddMedicationScreen(reminder: medication)),
          leading: Icon(Icons.medication, color: Colors.redAccent.withOpacity(isChecked ? 0.5 : 1.0)),
          title: Text(
            medication.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isChecked ? Colors.black54 : Colors.redAccent,
              decoration: isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('${medication.pillsPerDose} tablet(s)'),
          trailing: Checkbox(
            value: isChecked,
            onChanged: (val) => logProv.logDose(medication.id, time, val ?? false),
            activeColor: Colors.redAccent,
            shape: const CircleBorder(),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 2),
          ),
        ),
      ),
    );
  }
}
