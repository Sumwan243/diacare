import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/blood_sugar_provider.dart';

class AddBloodSugarScreen extends StatefulWidget {
  const AddBloodSugarScreen({super.key});

  @override
  State<AddBloodSugarScreen> createState() => _AddBloodSugarScreenState();
}

class _AddBloodSugarScreenState extends State<AddBloodSugarScreen> {
  final _levelController = TextEditingController();
  String _selectedContext = 'Fasting';
  DateTime _selectedTimestamp = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Blood Sugar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _levelController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Blood Sugar Level (mg/dL)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedContext,
              decoration: const InputDecoration(labelText: 'Context'),
              items: ['Fasting', 'Post-meal', 'Pre-meal', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedContext = v ?? 'Fasting'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Timestamp'),
              subtitle: Text(_selectedTimestamp.toString()),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedTimestamp,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date == null) return;

                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedTimestamp),
                );
                if (time == null) return;

                setState(() {
                  _selectedTimestamp = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final level = int.tryParse(_levelController.text);
                if (level == null) return; // Add validation feedback

                context.read<BloodSugarProvider>().addEntry(
                      level,
                      _selectedContext,
                      _selectedTimestamp,
                    );
                Navigator.pop(context);
              },
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
