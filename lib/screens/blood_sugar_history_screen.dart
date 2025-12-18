import 'package:collection/collection.dart';
import 'package:diacare/models/blood_sugar_entry.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BloodSugarHistoryScreen extends StatefulWidget {
  const BloodSugarHistoryScreen({super.key});

  @override
  State<BloodSugarHistoryScreen> createState() => _BloodSugarHistoryScreenState();
}

class _BloodSugarHistoryScreenState extends State<BloodSugarHistoryScreen> {
  int _targetMin = 70;
  int _targetMax = 180;
  bool _showStats = true;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BloodSugarProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entries = prov.entries; // your provider already sorts newest-first
    final groupedEntries =
    groupBy(entries, (BloodSugarEntry e) => DateUtils.dateOnly(e.timestamp));

    // Ensure stable, newest-first day ordering (don’t rely on map insertion order)
    final dates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

    final stats = _computeStats(entries, _targetMin, _targetMax);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Sugar Diary'),
        actions: [
          IconButton(
            tooltip: _showStats ? 'Hide stats' : 'Show stats',
            icon: Icon(_showStats ? Icons.insights_rounded : Icons.insights_outlined),
            onPressed: () => setState(() => _showStats = !_showStats),
          ),
          IconButton(
            tooltip: 'Target range',
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
      body: entries.isEmpty
          ? Center(
        child: Text(
          'No readings yet',
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        itemCount: dates.length + (_showStats ? 1 : 0),
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

          final dateIndex = index - (_showStats ? 1 : 0);
          final date = dates[dateIndex];
          final dayEntries = groupedEntries[date] ?? const <BloodSugarEntry>[];

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

    final existingNotes = existing?.context ?? '';
    final notesCtrl = TextEditingController(
      text: existingNotes == '—' ? '' : existingNotes,
    );

    DateTime selectedDateTime = existing?.timestamp ?? DateTime.now();

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'Add Reading' : 'Edit Reading',
                      style: Theme.of(ctx).textTheme.titleLarge,
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
                    const SizedBox(height: 12),

                    Card(
                      child: ListTile(
                        title: const Text('Time'),
                        trailing: Text(
                          DateFormat.yMd().add_jm().format(selectedDateTime),
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (date == null) return;

                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (time == null) return;

                          setModalState(() {
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
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
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

                          Navigator.pop(ctx, {
                            'level': level,
                            'notes': notes,
                            'timestamp': selectedDateTime,
                          });
                        },
                        child: Text(existing == null ? 'Save' : 'Update'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    levelCtrl.dispose();
    notesCtrl.dispose();

    if (result != null && mounted) {
      if (existing == null) {
        await prov.addEntry(result['level'], result['notes'], result['timestamp']);
      } else {
        final updated = BloodSugarEntry(
          id: existing.id,
          level: result['level'],
          context: result['notes'],
          timestamp: result['timestamp'],
        );
        await prov.upsertEntry(updated);
      }
    }
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

  Future<void> _showTargetRangeDialog(BuildContext context) async {
    final minCtrl = TextEditingController(text: _targetMin.toString());
    final maxCtrl = TextEditingController(text: _targetMax.toString());

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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
      last: entries.first,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final last = stats.last;
    final inRangePct =
    stats.count == 0 ? 0 : (stats.inRange * 100 / stats.count);

    final Color chipColor;
    if (inRangePct >= 70) {
      chipColor = cs.primary; // THEME-AWARE
    } else if (inRangePct >= 50) {
      chipColor = cs.tertiary; // THEME-AWARE
    } else {
      chipColor = cs.error;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculator', style: theme.textTheme.titleMedium),
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
              const SizedBox(height: 16),
              Text(
                'Last: ${last.level} mg/dL • ${TimeOfDay.fromDateTime(last.timestamp).format(context)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                last.context,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
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
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: c),
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
    final theme = Theme.of(context);
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
            style: theme.textTheme.titleLarge,
          ),
        ),
        Text(
          '${avg.toStringAsFixed(0)} avg • $minV–$maxV • $inRange/${dayEntries.length} in range',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final time = TimeOfDay.fromDateTime(entry.timestamp).format(context);

    final Color statusColor;
    final String statusText;

    if (entry.level < targetMin) {
      statusColor = cs.error; // THEME-AWARE
      statusText = 'Low';
    } else if (entry.level > targetMax) {
      statusColor = cs.tertiary; // THEME-AWARE
      statusText = 'High';
    } else {
      statusColor = cs.primary; // THEME-AWARE
      statusText = 'In range';
    }

    return Card(
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
                FilledButton(
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
        title: Text('${entry.level} mg/dL', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.context),
            const SizedBox(height: 2),
            Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor.withOpacity(0.9)),
            ),
          ],
        ),
        trailing: Text(time),
      ),
    );
  }
}
