import 'package:diacare/models/user_profile.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/screens/notification_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _apiKeyController = TextEditingController();
  DiabeticType _selectedType = DiabeticType.type2;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    // Load existing profile data into the form
    final profile = context.read<UserProfileProvider>().userProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _selectedType = profile.diabeticType;
      _apiKeyController.text = profile.geminiApiKey ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your age';
                  if (int.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DiabeticType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Diabetes Type'),
                items: DiabeticType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toString().split('.').last));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 24),
              
              // AI Settings Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'AI Health Insights',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'To get personalized diabetes recommendations, you need a Gemini API key from Google AI Studio.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'Gemini API Key (Optional)',
                          hintText: 'AIzaSy...',
                          suffixIcon: IconButton(
                            icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showApiKey = !_showApiKey),
                          ),
                          helperText: 'Get your free API key from ai.google.dev',
                        ),
                        obscureText: !_showApiKey,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !value.startsWith('AIza')) {
                            return 'API key should start with "AIza"';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notification Settings Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Notification Settings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Test and optimize notification delivery for your device.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationTestScreen()),
                          ),
                          icon: const Icon(Icons.notifications_outlined),
                          label: const Text('Test Notifications'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<UserProfileProvider>().saveProfile(
                          name: _nameController.text,
                          age: int.parse(_ageController.text),
                          type: _selectedType,
                          geminiApiKey: _apiKeyController.text.trim().isEmpty ? null : _apiKeyController.text.trim(),
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
