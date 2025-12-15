import 'package:diacare/models/blood_sugar_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../providers/blood_sugar_provider.dart';

class BloodSugarHistoryScreen extends StatelessWidget {
  const BloodSugarHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BloodSugarProvider>(context);
    final groupedEntries = groupBy(prov.entries, (BloodSugarEntry e) => DateUtils.dateOnly(e.timestamp));

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Sugar History')),
      body: ListView.builder(
        itemCount: groupedEntries.length,
        itemBuilder: (context, index) {
          final date = groupedEntries.keys.elementAt(index);
          final entries = groupedEntries[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  MaterialLocalizations.of(context).formatFullDate(date),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...entries.map((entry) => ListTile(
                    title: Text('${entry.level} mg/dL'),
                    subtitle: Text(entry.context),
                    trailing: Text(TimeOfDay.fromDateTime(entry.timestamp).format(context)),
                  )),
            ],
          );
        },
      ),
    );
  }
}
