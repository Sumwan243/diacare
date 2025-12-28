import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/samsung_optimization_service.dart';
import '../theme/app_theme.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final SamsungOptimizationService _samsungService = SamsungOptimizationService();
  
  bool _isLoading = false;
  bool? _isSamsungDevice;
  String? _deviceInfo;
  List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _checkDevice();
  }

  Future<void> _checkDevice() async {
    setState(() => _isLoading = true);
    
    try {
      final isSamsung = await _samsungService.isSamsungDevice();
      setState(() {
        _isSamsungDevice = isSamsung;
        _deviceInfo = isSamsung ? 'Samsung Device Detected' : 'Non-Samsung Device';
      });
    } catch (e) {
      setState(() {
        _deviceInfo = 'Unable to detect device type';
      });
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testNotification() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationService.showTestNotification();
      _addTestResult('✅ Test notification sent successfully');
      
      // Wait a moment then check if user saw it
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showNotificationCheckDialog();
      }
    } catch (e) {
      _addTestResult('❌ Failed to send test notification: $e');
    }
    
    setState(() => _isLoading = false);
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.insert(0, '${DateTime.now().toString().substring(11, 19)}: $result');
      if (_testResults.length > 10) {
        _testResults.removeLast();
      }
    });
  }

  void _showNotificationCheckDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Did you see the notification?'),
        content: const Text(
          'A test notification should have appeared. If you didn\'t see it, your device may need additional setup for reliable notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addTestResult('❌ User did not see test notification');
              _samsungService.showOptimizationDialog(context);
            },
            child: const Text('No, I didn\'t see it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addTestResult('✅ User confirmed test notification was visible');
            },
            child: const Text('Yes, I saw it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSamsungDevice == true ? Icons.phone_android : Icons.devices,
                          color: MedicalTheme.activityPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Device Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else if (_deviceInfo != null)
                      Text(_deviceInfo!)
                    else
                      const Text('Unknown device'),
                    
                    if (_isSamsungDevice == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          '⚠️ Samsung devices require special setup for reliable notifications.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Notification Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: MedicalTheme.activityPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Test Notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Test if notifications are working properly on your device. This will send a test notification immediately.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testNotification,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                        label: Text(_isLoading ? 'Sending...' : 'Send Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedicalTheme.activityPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Setup Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: MedicalTheme.activityPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Device Setup',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Get device-specific instructions for optimal notification delivery.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _samsungService.showOptimizationDialog(context),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Show Setup Instructions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Results Card
            if (_testResults.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: MedicalTheme.activityPurple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Results',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._testResults.map((result) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          result,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      )),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _testResults.clear()),
                        child: const Text('Clear Results'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}