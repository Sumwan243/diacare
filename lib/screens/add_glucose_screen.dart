import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/glucose_provider.dart';

class AddGlucoseScreen extends StatefulWidget {
  const AddGlucoseScreen({Key? key}) : super(key: key);

  @override
  State<AddGlucoseScreen> createState() => _AddGlucoseScreenState();
}

class _AddGlucoseScreenState extends State<AddGlucoseScreen> {
  final _controller = TextEditingController();
  String _context = 'Fasting';

  @override
  Widget build(BuildContext context) {
    final glucoseProv = Provider.of<GlucoseProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Glucose')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'mg/dL'),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _context,
              items: ['Fasting', 'Pre-meal', 'Post-meal', 'Random']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _context = v ?? 'Fasting'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final mg = double.tryParse(_controller.text);
                if (mg == null) return;
                glucoseProv.addEntry(mg, _context);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
