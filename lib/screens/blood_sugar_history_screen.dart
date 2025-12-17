
import 'package:diacare/models/blood_sugar_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/blood_sugar_provider.dart';
import 'package:intl/intl.dart';

class BloodSugarHistoryScreen extends StatefulWidget {
  const BloodSugarHistoryScreen({super.key});

  @override
  State<BloodSugarHistoryScreen> createState() =>
      _BloodSugarHistoryScreenState();
}

class _BloodSugarHistoryScreenState extends State<BloodSugarHistoryScreen> {
  int _targetMin = 70;
  int _targetMax = 180;
  bool _showStats = true;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BloodSugarProvider>();
    final entries = prov.entries;
    final groupedEntries =
    groupBy(entries, (BloodSugarEntry e) => DateUtils.dateOnly(e.timestamp));
    final stats = _computeStats(entries, _targetMin, _targetMax);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Diary'),
        actions: [
          IconButton(
            icon: Icon(
              _showStats ? Icons.insights_rounded : Icons.insights_outlined,
            ),
            onPressed: () => setState(() => _showStats = !_showStats),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showTargetRangeDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        label: const Text('Add Reading'),
        icon: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: groupedEntries.length + (_showStats ? 1 : 0),
        itemBuilder: (context, index) {
          if (_showStats && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CalculatorCard(
                stats: stats,
                targetMin: _targetMin,
                targetMax: _targetMax,
              ),
            );
          }

          final date =
          groupedEntries.keys.elementAt(index - (_showStats ? 1 : 0));
          final dayEntries = groupedEntries[date]!;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DayHeader(
                  date: date,
                  dayEntries: dayEntries,
                  targetMin: _targetMin,
                  targetMax: _targetMax,
                ),
                const SizedBox(height: 8),
                ...dayEntries.map(
                      (entry) => _EntryTile(
                    entry: entry,
                    targetMin: _targetMin,
                    targetMax: _targetMax,
                    onEdit: () => _showAddEntryDialog(context, existing: entry),
                    onDelete: () => _deleteEntry(context, entry),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddEntryDialog(
      BuildContext context, {
        BloodSugarEntry? existing,
      }) async {
    final prov = context.read<BloodSugarProvider>();
    final levelCtrl =
    TextEditingController(text: existing?.level.toString() ?? '');
    final notesCtrl =
    TextEditingController(text: existing?.context.replaceFirst('—', '') ?? '');
    DateTime selectedDateTime = existing?.timestamp ?? DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null ? 'Add Reading' : 'Edit Reading',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: levelCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Blood Sugar (mg/dL)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Context / Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    title: const Text('Time'),
                    trailing: Text(
                      DateFormat.yMd().add_jm().format(selectedDateTime),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time == null) return;
                      setState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final level = int.tryParse(levelCtrl.text.trim());
                        if (level == null || level <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter a valid value.')),
                          );
                          return;
                        }

                        final notes = notesCtrl.text.trim().isEmpty
                            ? '—'
                            : notesCtrl.text.trim();

                        if (existing == null) {
                          await prov.addEntry(level, notes, selectedDateTime);
                        } else {
                          // Preserve id when editing
                          final updated = BloodSugarEntry(
                            id: existing.id,
                            level: level,
                            context: notes,
                            timestamp: selectedDateTime,
                          );
                          await prov.upsertEntry(updated);
                        }

                        if (mounted) Navigator.pop(ctx);
                      },
                      child: Text(existing == null ? 'Save' : 'Update'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    levelCtrl.dispose();
    notesCtrl.dispose();
  }

  void _deleteEntry(BuildContext context, BloodSugarEntry entry) {
    final prov = context.read<BloodSugarProvider>();

    prov.deleteEntry(entry.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reading deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => prov.upsertEntry(entry),
        ),
      ),
    );
  }

  // --- THIS IS THE CORRECTED METHOD ---
  Future<void> _showTargetRangeDialog(BuildContext context) async {
    final minCtrl = TextEditingController(text: _targetMin.toString());
    final maxCtrl = TextEditingController(text: _targetMax.toString());

    // The dialog now returns a Map of the new values, or null if cancelled.
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Target range (mg/dL)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min'),
              ),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), // Returns null
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final minV = int.tryParse(minCtrl.text.trim());
                final maxV = int.tryParse(maxCtrl.text.trim());

                if (minV == null ||
                    maxV == null ||
                    minV <= 0 ||
                    maxV <= 0 ||
                    minV >= maxV) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid range.')),
                  );
                  return;
                }
                // Instead of calling setState, we pop with the new values.
                Navigator.pop(ctx, {'min': minV, 'max': maxV});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    minCtrl.dispose();
    maxCtrl.dispose();

    // Safely call setState *after* the dialog has been closed.
    if (result != null && mounted) {
      setState(() {
        _targetMin = result['min']!;
        _targetMax = result['max']!;
      });
    }
  }

  _Stats _computeStats(List<BloodSugarEntry> entries, int min, int max) {
    if (entries.isEmpty) return _Stats.empty();

    int inRange = 0;
    int low = 0;
    int high = 0;
    int sum = 0;

    int minVal = entries.first.level;
    int maxVal = entries.first.level;

    for (final e in entries) {
      final v = e.level;
      sum += v;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;

      if (v < min) {
        low++;
      } else if (v > max) {
        high++;
      } else {
        inRange++;
      }
    }

    return _Stats(
      count: entries.length,
      average: sum / entries.length,
      min: minVal,
      max: maxVal,
      inRange: inRange,
      low: low,
      high: high,
      last: entries.first, // newest
    );
  }
}

class _Stats {
  final int count;
  final double average;
  final int min;
  final int max;
  final int inRange;
  final int low;
  final int high;
  final BloodSugarEntry? last;

  const _Stats({
    required this.count,
    required this.average,
    required this.min,
    required this.max,
    required this.inRange,
    required this.low,
    required this.high,
    required this.last,
  });

  factory _Stats.empty() => const _Stats(
    count: 0,
    average: 0,
    min: 0,
    max: 0,
    inRange: 0,
    low: 0,
    high: 0,
    last: null,
  );
}

class _CalculatorCard extends StatelessWidget {
  final _Stats stats;
  final int targetMin;
  final int targetMax;

  const _CalculatorCard({
    required this.stats,
    required this.targetMin,
    required this.targetMax,
  });

  @override
  Widget build(BuildContext context) {
    final last = stats.last;
    final inRangePct =
    stats.count == 0 ? 0 : (stats.inRange * 100 / stats.count);

    final Color chipColor = inRangePct >= 70
        ? Colors.green
        : (inRangePct >= 50 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calculator', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(label: 'Avg', value: stats.average.toStringAsFixed(0)),
              _MetricChip(label: 'Min', value: '${stats.min}'),
              _MetricChip(label: 'Max', value: '${stats.max}'),
              _MetricChip(
                label: 'In range',
                value: '${inRangePct.toStringAsFixed(0)}%',
                color: chipColor,
              ),
              _MetricChip(label: 'Range', value: '$targetMin–$targetMax'),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last: ${last.level} mg/dL • ${TimeOfDay.fromDateTime(last.timestamp).format(context)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              last.context,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricChip({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final List<BloodSugarEntry> dayEntries;
  final int targetMin;
  final int targetMax;

  const _DayHeader({
    required this.date,
    required this.dayEntries,
    required this.targetMin,
    required this.targetMax,
  });

  @override
  Widget build(BuildContext context) {
    int sum = 0;
    int minV = dayEntries.first.level;
    int maxV = dayEntries.first.level;
    int inRange = 0;

    for (final e in dayEntries) {
      final v = e.level;
      sum += v;
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
      if (v >= targetMin && v <= targetMax) inRange++;
    }

    final avg = sum / dayEntries.length;

    return Row(
      children: [
        Expanded(
          child: Text(
            MaterialLocalizations.of(context).formatFullDate(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text(
          '${avg.toStringAsFixed(0)} avg • $minV–$maxV • $inRange/${dayEntries.length}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final BloodSugarEntry entry;
  final int targetMin;
  final int targetMax;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.targetMin,
    required this.targetMax,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(entry.timestamp).format(context);

    final Color statusColor;
    final String statusText;

    if (entry.level < targetMin) {
      statusColor = Colors.red;
      statusText = 'Low';
    } else if (entry.level > targetMax) {
      statusColor = Colors.orange;
      statusText = 'High';
    } else {
      statusColor = Colors.green;
      statusText = 'In range';
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onEdit,
        onLongPress: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete reading?'),
              content: const Text('This will remove the reading from your diary.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (ok == true) onDelete();
        },
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        title: Text('${entry.level} mg/dL'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.context),
            const SizedBox(height: 2),
            Text(
              statusText,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Text(time),
      ),
    );
  }
}
