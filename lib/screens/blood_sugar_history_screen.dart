import 'package:collection/collection.dart';
import 'package:diacare/models/blood_sugar_entry.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class BloodSugarHistoryScreen extends StatefulWidget {
  const BloodSugarHistoryScreen({super.key});

  @override
  State<BloodSugarHistoryScreen> createState() => _BloodSugarHistoryScreenState();
}

class _BloodSugarHistoryScreenState extends State<BloodSugarHistoryScreen> {
  int _targetMin = 70;
  int _targetMax = 180;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BloodSugarProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entries = prov.entries;
    final monthlyStatsEntries = entries.where((e) => e.timestamp.year == _focusedDay.year && e.timestamp.month == _focusedDay.month).toList();
    final stats = _computeStats(monthlyStatsEntries, _targetMin, _targetMax);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Glucose Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Targets',
            onPressed: () => _showTargetRangeDialog(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _CalendarView(
              entries: entries,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              targetMin: _targetMin,
              targetMax: _targetMax,
              onPageChanged: (day) => setState(() => _focusedDay = day),
              onDaySelected: (sel, foc) {
                setState(() { _selectedDay = sel; _focusedDay = foc; });
                _showDayDetailsSheet(context, sel, prov);
              },
            ),
            const SizedBox(height: 16),

            // 1. Slimmer Add Card
            _AddGlucoseCard(onTap: () => _showAddEntrySheet(context)),

            const SizedBox(height: 24),

            // 2. Compact Stats Dashboard (Single Row)
            _StatsDashboard(stats: stats, targetMin: _targetMin, targetMax: _targetMax),

            const SizedBox(height: 24),

            // 3. Header for History with "View All" (Visual only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent History', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () { /* Navigate to full history list */ },
                    child: const Text("View All")
                )
              ],
            ),
            const SizedBox(height: 8),

            // 4. Compact List View
            _RecentListView(
              entries: entries,
              targetMin: _targetMin,
              targetMax: _targetMax,
              onEdit: (e) => _showAddEntrySheet(context, existing: e),
              onDelete: (e) => prov.deleteEntry(e.id),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ... (Keep existing _computeStats, _showAddEntrySheet, _showDayDetailsSheet, _showTargetRangeDialog logic exactly as is)
  _Stats _computeStats(List<BloodSugarEntry> list, int min, int max) {
    if (list.isEmpty) return _Stats.empty();
    double sum = 0;
    int minV = list.first.level;
    int maxV = list.first.level;
    for (var e in list) {
      sum += e.level;
      if (e.level < minV) minV = e.level;
      if (e.level > maxV) maxV = e.level;
    }
    return _Stats(
      avg: sum / list.length,
      min: minV,
      max: maxV,
      last: list.first,
      count: list.length,
    );
  }

  Future<void> _showAddEntrySheet(BuildContext context, {BloodSugarEntry? existing}) async {
    final prov = context.read<BloodSugarProvider>();
    int selectedLevel = existing?.level ?? 100;
    final notesCtrl = TextEditingController(text: existing?.context.replaceAll('—', '') ?? '');
    DateTime time = existing?.timestamp ?? DateTime.now();
    final scrollController = FixedExtentScrollController(initialItem: selectedLevel);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'Log Glucose' : 'Edit Log',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Swipe to select level (mg/dL)", style: TextStyle(color: Theme.of(ctx).colorScheme.secondary)),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: CupertinoPicker(
                  scrollController: scrollController,
                  itemExtent: 50,
                  magnification: 1.2,
                  useMagnifier: true,
                  onSelectedItemChanged: (int value) {
                    setModalState(() => selectedLevel = value);
                  },
                  children: List<Widget>.generate(600, (int index) {
                    return Center(
                      child: Text(
                        index.toString(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: index == selectedLevel
                              ? const Color(0xFF4CAF50) // Green for glucose
                              : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes (e.g. Fasting, After meal)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                trailing: Chip(
                  label: Text(DateFormat.jm().format(time)),
                  avatar: const Icon(Icons.access_time, size: 16),
                ),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(time));
                  if (t != null) {
                    setModalState(() => time = DateTime(time.year, time.month, time.day, t.hour, t.minute));
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    if (selectedLevel <= 0) return;
                    final notes = notesCtrl.text.isEmpty ? '—' : notesCtrl.text;
                    if (existing == null) {
                      prov.addEntry(selectedLevel, notes, time);
                    } else {
                      prov.upsertEntry(BloodSugarEntry(id: existing.id, level: selectedLevel, context: notes, timestamp: time));
                    }
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _getSeverityColor(selectedLevel, _targetMin, _targetMax),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetailsSheet(BuildContext context, DateTime day, BloodSugarProvider prov) {
    final dayEntries = prov.entries.where((e) => DateUtils.isSameDay(e.timestamp, day)).toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(DateFormat.yMMMMEEEEd().format(day), style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (dayEntries.isEmpty)
            const Text('No records for this day.')
          else
            ...dayEntries.map((e) =>
                _EntryTile(entry: e, targetMin: _targetMin, targetMax: _targetMax, simple: true)),
        ],
      ),
    );
  }

  Future<void> _showTargetRangeDialog(BuildContext context) async {
    final minCtrl = TextEditingController(text: _targetMin.toString());
    final maxCtrl = TextEditingController(text: _targetMax.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Targets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min (mg/dL)')),
            TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max (mg/dL)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final min = int.tryParse(minCtrl.text);
              final max = int.tryParse(maxCtrl.text);
              if (min != null && max != null) {
                setState(() { _targetMin = min; _targetMax = max; });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

class _Stats {
  final double avg;
  final int min;
  final int max;
  final BloodSugarEntry? last;
  final int count;
  const _Stats({required this.avg, required this.min, required this.max, this.last, required this.count});
  factory _Stats.empty() => const _Stats(avg: 0, min: 0, max: 0, count: 0);
}

class _AddGlucoseCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddGlucoseCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.4), // Softer Look
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Reduced padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 28, color: const Color(0xFF4CAF50)), // Green add icon
              const SizedBox(width: 12),
              Text('Log New Glucose Level', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF4CAF50), fontWeight: FontWeight.bold)), // Green text
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW COMPACT DASHBOARD ---
class _StatsDashboard extends StatelessWidget {
  final _Stats stats;
  final int targetMin;
  final int targetMax;

  const _StatsDashboard({required this.stats, required this.targetMin, required this.targetMax});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (stats.count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCompactStat(context, 'Average', stats.avg.toStringAsFixed(0), const Color(0xFF4CAF50)), // Green for average glucose
          _buildDivider(context),
          _buildCompactStat(context, 'Lowest', stats.min.toString(), _getSeverityColor(stats.min, targetMin, targetMax)),
          _buildDivider(context),
          _buildCompactStat(context, 'Highest', stats.max.toString(), _getSeverityColor(stats.max, targetMin, targetMax)),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant);
  }

  Widget _buildCompactStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// --- REFACTORED COMPACT HISTORY ---
class _RecentListView extends StatelessWidget {
  final List<BloodSugarEntry> entries;
  final int targetMin;
  final int targetMax;
  final Function(BloodSugarEntry) onEdit;
  final Function(BloodSugarEntry) onDelete;

  const _RecentListView({
    required this.entries,
    required this.targetMin,
    required this.targetMax,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Center(child: Text('No recent history.', style: TextStyle(color: Colors.grey)));

    // Only take the last 5 entries to save space
    final recentEntries = entries.take(5).toList();

    return Column(
      children: recentEntries.map((e) => _EntryTile(
        entry: e,
        targetMin: targetMin,
        targetMax: targetMax,
        onTap: () => onEdit(e),
      )).toList(),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final BloodSugarEntry entry;
  final int targetMin;
  final int targetMax;
  final VoidCallback? onTap;
  final bool simple;

  const _EntryTile({
    required this.entry,
    required this.targetMin,
    required this.targetMax,
    this.onTap,
    this.simple = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor(entry.level, targetMin, targetMax);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow, // Lighter background than before
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)), // Subtle border
      ),
      child: ListTile(
        onTap: onTap,
        dense: true, // Makes the tile more compact vertically
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Text(
          '${entry.level} mg/dL',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: simple ? null : Text(
            "${DateFormat.MMMd().format(entry.timestamp)} • ${entry.context}",
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis
        ),
        trailing: Text(
          DateFormat.jm().format(entry.timestamp),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ... (Keep existing _CalendarView and _getSeverityColor)

class _CalendarView extends StatelessWidget {
  final List<BloodSugarEntry> entries;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final int targetMin;
  final int targetMax;
  final ValueChanged<DateTime> onPageChanged;
  final Function(DateTime, DateTime) onDaySelected;

  const _CalendarView({
    required this.entries,
    required this.focusedDay,
    required this.selectedDay,
    required this.targetMin,
    required this.targetMax,
    required this.onPageChanged,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        // 1. Calendar Edge & Shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Lighter shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final dayEntries = entries.where((e) => isSameDay(e.timestamp, date)).toList();
            if (dayEntries.isEmpty) return null;

            final avg = dayEntries.map((e) => e.level).average;
            final color = _getSeverityColor(avg.round(), targetMin, targetMax);

            return Positioned(
              bottom: 6,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          },
        ),
      ),
    );
  }
}

Color _getSeverityColor(int level, int min, int max) {
  if (level == 0) return Colors.grey;
  if (level < min) return const Color(0xFFFF5252);
  if (level > max) return const Color(0xFFFF5252);
  return const Color(0xFF00C853);
}