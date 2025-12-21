import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _selectedType = 'Walking';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Activity Type'),
              items: ['Walking', 'Running', 'Gym', 'Cycling', 'Other']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v ?? 'Walking'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories Burned (optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final duration = int.tryParse(_durationController.text);
                final calories = int.tryParse(_caloriesController.text) ?? 0;

                if (duration == null) return; 

                context.read<ActivityProvider>().addActivity(
                      _selectedType,
                      duration,
                      calories,
                    );
                Navigator.pop(context);
              },
              child: const Text('Save Activity'),
            ),
          ],
        ),
      ),
    );
  }
}
