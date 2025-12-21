import 'package:diacare/models/medication_reminder.dart';
import 'package:diacare/providers/medication_log_provider.dart';
import 'package:diacare/providers/medication_provider.dart';
import 'package:diacare/screens/add_medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh when screen is first shown to sync with notification updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationLogProvider>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app resumes to sync with notification updates
      context.read<MedicationLogProvider>().refresh();
    }
  }

  void _navigateAndRefresh(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final medProv = context.watch<MedicationProvider>();
    final logProv = context.watch<MedicationLogProvider>();

    // 1. Flatten all reminders into a single list of {med, time}
    final allReminders = medProv.reminders.expand((med) {
      // TODO: If your MedicationReminder has a 'weekdays' list, filter here:
      // if (!med.weekdays[_selectedDate.weekday - 1]) return [];
      return med.times.map((time) => {'medication': med, 'time': time});
    }).toList();

    // 2. Sort by time
    allReminders.sort((a, b) {
      final t1 = a['time'] as TimeOfDay;
      final t2 = b['time'] as TimeOfDay;
      return (t1.hour * 60 + t1.minute).compareTo(t2.hour * 60 + t2.minute);
    });

    // 3. Calculate Progress for the selected date
    int takenCount = 0;
    for (var item in allReminders) {
      final m = item['medication'] as MedicationReminder;
      final t = item['time'] as TimeOfDay;
      // Use the selected date instead of always using today
      if (logProv.isDoseTaken(m.id, t, _selectedDate)) {
        takenCount++;
      }
    }
    double progress = allReminders.isEmpty ? 0 : takenCount / allReminders.length;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Schedule', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. Calendar Strip
          _buildCalendarStrip(theme),

          const SizedBox(height: 10),

          // 2. Progress Summary
          _buildProgressCard(theme, progress, takenCount, allReminders.length),

          const SizedBox(height: 10),

          // 3. Timeline List
          Expanded(
            child: allReminders.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: allReminders.length + 1, // +1 for the "Add" button at bottom
              itemBuilder: (ctx, index) {
                if (index == allReminders.length) {
                  return const SizedBox(height: 80); // Bottom spacer
                }

                final item = allReminders[index];
                final med = item['medication'] as MedicationReminder;
                final time = item['time'] as TimeOfDay;
                final isLast = index == allReminders.length - 1;

                return _buildTimelineItem(
                    context, med, time, logProv, theme, isLast
                );
              },
            ),
          ),
        ],
      ),
      // Floating "Add" Button (Alternative to the card in the list)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(const AddMedicationScreen()),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text("Add Med"),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCalendarStrip(ThemeData theme) {
    // Generate dates for current week (Monday start) or sliding window
    final now = DateTime.now();
    // Start from 3 days ago to show some context
    final startDate = now.subtract(const Duration(days: 3));
    final dates = List.generate(14, (index) => startDate.add(Duration(days: index)));

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          final cs = theme.colorScheme;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: 55,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
                border: isToday && !isSelected
                    ? Border.all(color: cs.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date), // Mon, Tue
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, double progress, int taken, int total) {
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Progress', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? 'No meds today' : '$taken of $total taken',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: total == 0 ? 0 : progress,
                strokeWidth: 6,
                backgroundColor: cs.surface.withOpacity(0.5),
                color: cs.primary,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, MedicationReminder med, TimeOfDay time, MedicationLogProvider logProv, ThemeData theme, bool isLast) {
    // Use the selected date to check if dose was taken
    final isTaken = logProv.isDoseTaken(med.id, time, _selectedDate);
    final cs = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Time Column
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                time.format(context).replaceAll(' ', '\n'), // Stack AM/PM
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isTaken ? cs.onSurfaceVariant.withOpacity(0.5) : cs.onSurface,
                ),
              ),
            ),
          ),

          // 2. Timeline Line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTaken ? cs.primary : cs.surfaceContainerHighest,
                  border: Border.all(color: cs.primary, width: 2),
                ),
              ),
              Expanded(
                child: isLast ? const SizedBox.shrink() : Container(
                  width: 2,
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // 3. Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMedicationCard(context, med, time, isTaken, logProv, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, MedicationReminder med, TimeOfDay time, bool isTaken, MedicationLogProvider logProv, ThemeData theme) {
    final cs = theme.colorScheme;

    return InkWell(
      onLongPress: () => _navigateAndRefresh(AddMedicationScreen(reminder: med)),
      onTap: () => logProv.logDose(med.id, time, !isTaken),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isTaken ? cs.surfaceContainerLowest : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTaken ? Colors.transparent : cs.outlineVariant.withOpacity(0.4),
          ),
          boxShadow: isTaken
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isTaken ? cs.surfaceContainerHighest : cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_liquid_rounded,
                color: isTaken ? cs.onSurfaceVariant : cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                      color: isTaken ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${med.pillsPerDose} pill(s)',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTaken ? cs.primary : Colors.transparent,
                border: Border.all(color: isTaken ? cs.primary : cs.outline, width: 2),
              ),
              child: isTaken
                  ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: theme.colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No meds scheduled.",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap '+' to add a reminder.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}