import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ActivityProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: ListView.builder(
        itemCount: prov.entries.length,
        itemBuilder: (context, index) {
          final entry = prov.entries[index];
          return ListTile(
            title: Text(entry.type),
            subtitle: Text(
              '${entry.durationMinutes} minutes - ${entry.caloriesBurned} kcal - ${MaterialLocalizations.of(context).formatFullDate(entry.timestamp)}',
            ),
            trailing: Text(TimeOfDay.fromDateTime(entry.timestamp).format(context)),
          );
        },
      ),
    );
  }
}
