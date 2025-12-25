import 'package:collection/collection.dart';
import 'package:diacare/models/blood_pressure_entry.dart';
import 'package:diacare/providers/blood_pressure_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class BloodPressureHistoryScreen extends StatefulWidget {
  const BloodPressureHistoryScreen({super.key});

  @override
  State<BloodPressureHistoryScreen> createState() => _BloodPressureHistoryScreenState();
}

class _BloodPressureHistoryScreenState extends State<BloodPressureHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _targetSysMin = 90;
  int _targetSysMax = 130;
  int _targetDiaMin = 60;
  int _targetDiaMax = 90;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BloodPressureProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final entries = prov.entries;
    final monthlyEntries = entries.where((e) => e.timestamp.year == _focusedDay.year && e.timestamp.month == _focusedDay.month).toList();
    final stats = _computeStats(monthlyEntries);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('Blood Pressure Overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
              targetMin: _targetSysMin,
              targetMax: _targetSysMax,
              onPageChanged: (day) => setState(() => _focusedDay = day),
              onDaySelected: (sel, foc) {
                setState(() { _selectedDay = sel; _focusedDay = foc; });
                _showDayDetailsSheet(context, sel, prov);
              },
            ),

            const SizedBox(height: 16),

            // Add card (compact)
            _AddBPCard(onTap: () => _showAddEntrySheet(context)),

            const SizedBox(height: 24),

            // Stats
            _StatsDashboardBP(
              stats: stats,
              sysTargetMin: _targetSysMin,
              sysTargetMax: _targetSysMax,
              diaTargetMin: _targetDiaMin,
              diaTargetMax: _targetDiaMax,
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent History', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),

            _RecentListViewBP(
              entries: entries,
              onEdit: (e) => _showAddEntrySheet(context, existing: e),
              onDelete: (e) => prov.deleteEntry(e.id),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  _BPStats _computeStats(List<BloodPressureEntry> list) {
    if (list.isEmpty) return _BPStats.empty();
    double sumSys = 0;
    int minS = list.first.systolic;
    int maxS = list.first.systolic;
    for (var e in list) {
      sumSys += e.systolic;
      if (e.systolic < minS) minS = e.systolic;
      if (e.systolic > maxS) maxS = e.systolic;
    }
    // compute diastolic stats
    double sumDia = 0;
    int minD = list.first.diastolic;
    int maxD = list.first.diastolic;
    for (var e in list) {
      sumDia += e.diastolic;
      if (e.diastolic < minD) minD = e.diastolic;
      if (e.diastolic > maxD) maxD = e.diastolic;
    }

    return _BPStats(
      avgSystolic: sumSys / list.length,
      minSystolic: minS,
      maxSystolic: maxS,
      avgDiastolic: sumDia / list.length,
      minDiastolic: minD,
      maxDiastolic: maxD,
      last: list.first,
      count: list.length,
    );
  }

  Future<void> _showAddEntrySheet(BuildContext context, {BloodPressureEntry? existing}) async {
    final prov = context.read<BloodPressureProvider>();
    int systolic = existing?.systolic ?? 120;
    int diastolic = existing?.diastolic ?? 80;
    final notesCtrl = TextEditingController(text: existing?.context ?? '—');
    DateTime time = existing?.timestamp ?? DateTime.now();
    const int sysMin = 60;
    const int sysMax = 220;
    const int diaMin = 40;
    const int diaMax = 140;
    final sysController = FixedExtentScrollController(initialItem: (systolic - sysMin).clamp(0, sysMax - sysMin));
    final diaController = FixedExtentScrollController(initialItem: (diastolic - diaMin).clamp(0, diaMax - diaMin));

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
              Text(existing == null ? 'Log Blood Pressure' : 'Edit Log', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Swipe to select values (mmHg)", style: TextStyle(color: Theme.of(ctx).colorScheme.secondary)),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Systolic', style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: sysController,
                              itemExtent: 44,
                              magnification: 1.1,
                              useMagnifier: true,
                              onSelectedItemChanged: (int idx) {
                                final val = sysMin + idx;
                                setModalState(() => systolic = val);
                              },
                              children: List<Widget>.generate(sysMax - sysMin + 1, (int index) {
                                final val = sysMin + index;
                                return Center(
                                  child: Text(
                                    val.toString(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: val == systolic ? const Color(0xFFE91E63) : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6), // Red for selected systolic
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Diastolic', style: TextStyle(fontWeight: FontWeight.w600)),
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: diaController,
                              itemExtent: 44,
                              magnification: 1.1,
                              useMagnifier: true,
                              onSelectedItemChanged: (int idx) {
                                final val = diaMin + idx;
                                setModalState(() => diastolic = val);
                              },
                              children: List<Widget>.generate(diaMax - diaMin + 1, (int index) {
                                final val = diaMin + index;
                                return Center(
                                  child: Text(
                                    val.toString(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: val == diastolic ? const Color(0xFFE91E63) : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6), // Red for selected diastolic
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: InputDecoration(labelText: 'Notes (e.g. Resting)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                trailing: Chip(label: Text(DateFormat.jm().format(time)), avatar: const Icon(Icons.access_time, size: 16)),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(time));
                  if (t != null) setModalState(() => time = DateTime(time.year, time.month, time.day, t.hour, t.minute));
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    final notes = notesCtrl.text.isEmpty ? '—' : notesCtrl.text;
                    if (existing == null) {
                      prov.addEntry(systolic, diastolic, notes, time);
                    } else {
                      prov.upsertEntry(BloodPressureEntry(id: existing.id, systolic: systolic, diastolic: diastolic, context: notes, timestamp: time));
                    }
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _getBPSeverityColor(systolic, _targetSysMin, _targetSysMax),
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

  void _showDayDetailsSheet(BuildContext context, DateTime day, BloodPressureProvider prov) {
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
            ...dayEntries.map((e) => _EntryTileBP(entry: e, simple: true)),
        ],
      ),
    );
  }

  Future<void> _showTargetRangeDialog(BuildContext context) async {
    final minCtrl = TextEditingController(text: _targetSysMin.toString());
    final maxCtrl = TextEditingController(text: _targetSysMax.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Systolic Targets'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min (mmHg)')),
            TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max (mmHg)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final min = int.tryParse(minCtrl.text);
            final max = int.tryParse(maxCtrl.text);
            if (min != null && max != null) {
              setState(() { _targetSysMin = min; _targetSysMax = max; });
              Navigator.pop(ctx);
            }
          }, child: const Text('Save'))
        ],
      ),
    );
  }
}

class _BPStats {
  final double avgSystolic;
  final int minSystolic;
  final int maxSystolic;
  final double avgDiastolic;
  final int minDiastolic;
  final int maxDiastolic;
  final BloodPressureEntry? last;
  final int count;
  const _BPStats({
    required this.avgSystolic,
    required this.minSystolic,
    required this.maxSystolic,
    required this.avgDiastolic,
    required this.minDiastolic,
    required this.maxDiastolic,
    this.last,
    required this.count,
  });
  factory _BPStats.empty() => const _BPStats(avgSystolic: 0, minSystolic: 0, maxSystolic: 0, avgDiastolic: 0, minDiastolic: 0, maxDiastolic: 0, count: 0);
}

class _AddBPCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBPCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 28, color: const Color(0xFFE91E63)), // Red add icon
              const SizedBox(width: 12),
              Text('Log New Blood Pressure', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFFE91E63), fontWeight: FontWeight.bold)), // Red text
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsDashboardBP extends StatelessWidget {
  final _BPStats stats;
  final int sysTargetMin;
  final int sysTargetMax;
  final int diaTargetMin;
  final int diaTargetMax;

  const _StatsDashboardBP({required this.stats, required this.sysTargetMin, required this.sysTargetMax, required this.diaTargetMin, required this.diaTargetMax});

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
          _buildCompactStat(context, 'Average', '${stats.avgSystolic.toStringAsFixed(0)}/${stats.avgDiastolic.toStringAsFixed(0)}', const Color(0xFFE91E63)), // Red for average
          _buildDivider(context),
          _buildCompactStat(context, 'Lowest', '${stats.minSystolic}/${stats.minDiastolic}', _getBPSeverityColor(stats.minSystolic, sysTargetMin, sysTargetMax)),
          _buildDivider(context),
          _buildCompactStat(context, 'Highest', '${stats.maxSystolic}/${stats.maxDiastolic}', _getBPSeverityColor(stats.maxSystolic, sysTargetMin, sysTargetMax)),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant);
  }

  Widget _buildCompactStat(BuildContext context, String label, String value, Color color) {
    final parts = value.split('/');
    final sys = parts.isNotEmpty ? parts[0] : '';
    final dia = parts.length > 1 ? parts[1] : '';
    return Column(
      children: [
        Text(sys, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(dia, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _RecentListViewBP extends StatelessWidget {
  final List<BloodPressureEntry> entries;
  final Function(BloodPressureEntry) onEdit;
  final Function(BloodPressureEntry) onDelete;

  const _RecentListViewBP({required this.entries, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Center(child: Text('No recent history.', style: TextStyle(color: Colors.grey)));
    final recentEntries = entries.take(5).toList();
    return Column(
      children: recentEntries.map((e) => _EntryTileBP(entry: e, simple: false)).toList(),
    );
  }
}

class _EntryTileBP extends StatelessWidget {
  final BloodPressureEntry entry;
  final bool simple;

  const _EntryTileBP({required this.entry, this.simple = false});

  @override
  Widget build(BuildContext context) {
    final color = _getBPSeverityColor(entry.systolic, 90, 130);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        title: Text('${entry.systolic}/${entry.diastolic} mmHg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: simple ? null : Text('${DateFormat.MMMd().format(entry.timestamp)} • ${entry.context}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(DateFormat.jm().format(entry.timestamp), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  final List<BloodPressureEntry> entries;
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0,4))],
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
        headerStyle: const HeaderStyle(titleCentered: true, formatButtonVisible: false, titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final dayEntries = entries.where((e) => isSameDay(e.timestamp, date)).toList();
            if (dayEntries.isEmpty) return null;
            final avgSys = dayEntries.map((e) => e.systolic).average;
            final color = _getBPSeverityColor(avgSys.round(), targetMin, targetMax);
            return Positioned(bottom: 6, child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)));
          },
        ),
      ),
    );
  }
}

Color _getBPSeverityColor(int level, int min, int max) {
  if (level == 0) return Colors.grey;
  if (level < min) return const Color(0xFFFFA000); // low-ish
  if (level > max) return const Color(0xFFD32F2F); // high
  return const Color(0xFF00C853); // good
}

class _NumberField extends StatefulWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _NumberField({required this.label, required this.value, required this.onChanged});

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: widget.label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      onChanged: (s) {
        final v = int.tryParse(s) ?? 0;
        widget.onChanged(v);
      },
    );
  }
}

