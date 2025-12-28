import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SamsungOptimizationService {
  static final SamsungOptimizationService _instance = SamsungOptimizationService._internal();
  factory SamsungOptimizationService() => _instance;
  SamsungOptimizationService._internal();

  static const MethodChannel _channel = MethodChannel('diacare/samsung_optimization');

  bool? _isSamsungDevice;
  String? _deviceModel;

  /// Check if the current device is a Samsung device
  Future<bool> isSamsungDevice() async {
    if (_isSamsungDevice != null) return _isSamsungDevice!;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      _deviceModel = androidInfo.model;
      _isSamsungDevice = androidInfo.manufacturer.toLowerCase() == 'samsung';
      
      debugPrint('Device: ${androidInfo.manufacturer} ${androidInfo.model}');
      debugPrint('Is Samsung: $_isSamsungDevice');
      
      return _isSamsungDevice!;
    } catch (e) {
      debugPrint('Error checking device info: $e');
      _isSamsungDevice = false;
      return false;
    }
  }

  /// Get device-specific optimization instructions
  Future<String> getOptimizationInstructions() async {
    final isSamsung = await isSamsungDevice();
    
    if (!isSamsung) {
      return _getGenericInstructions();
    }

    // Samsung-specific instructions based on device model
    if (_deviceModel?.toLowerCase().contains('s10') == true) {
      return _getSamsungS10Instructions();
    } else {
      return _getSamsungGenericInstructions();
    }
  }

  String _getSamsungS10Instructions() {
    return '''
Samsung Galaxy S10 Plus Notification Setup:

🔋 BATTERY OPTIMIZATION (CRITICAL):
1. Settings → Device care → Battery
2. Tap "App power management"
3. Tap "Apps that won't be put to sleep"
4. Tap "+" and add "DiaCare"

📱 APP SETTINGS:
1. Settings → Apps → DiaCare
2. Battery → "Allow background activity" ON
3. Notifications → "Allow notifications" ON
4. Permissions → Enable all requested permissions

⚡ ADAPTIVE BATTERY (DISABLE):
1. Settings → Device care → Battery
2. More battery settings → Adaptive battery OFF
3. Put unused apps to sleep → Remove DiaCare if listed

🔔 NOTIFICATION CHANNELS:
1. Settings → Notifications → DiaCare
2. Enable all notification categories
3. Set importance to "High" or "Urgent"

🚀 AUTO-START:
1. Settings → Apps → DiaCare
2. Battery → "Allow background activity"
3. Mobile data → "Allow background data usage"

⚠️ IMPORTANT: Samsung's aggressive battery management can block notifications even with these settings. If notifications still don't work, try disabling "Adaptive battery" completely.
    ''';
  }

  String _getSamsungGenericInstructions() {
    return '''
Samsung Device Notification Setup:

🔋 BATTERY OPTIMIZATION:
1. Settings → Apps → DiaCare → Battery
2. "Allow background activity" ON
3. "Optimize battery usage" OFF

📱 DEVICE CARE:
1. Settings → Device care → Battery
2. App power management → Apps that won't be put to sleep
3. Add DiaCare to the list

🔔 NOTIFICATIONS:
1. Settings → Notifications → DiaCare
2. Enable all notification categories
3. Set to highest importance level

⚡ POWER SAVING:
1. Disable power saving mode when expecting notifications
2. Or add DiaCare to power saving exceptions

🚀 BACKGROUND ACTIVITY:
1. Settings → Apps → Special access
2. Optimize battery usage → All apps
3. Find DiaCare → Don't optimize
    ''';
  }

  String _getGenericInstructions() {
    return '''
Android Notification Setup:

🔔 NOTIFICATIONS:
1. Settings → Apps → DiaCare → Notifications
2. Enable all notification categories
3. Set importance to "High"

🔋 BATTERY:
1. Settings → Apps → DiaCare → Battery
2. "Battery optimization" → Don't optimize
3. "Background activity" → Allow

⏰ ALARMS & REMINDERS:
1. Settings → Apps → Special app access
2. "Alarms & reminders" → DiaCare → Allow

📱 DO NOT DISTURB:
1. Settings → Sound → Do Not Disturb
2. Add DiaCare to exceptions if needed
    ''';
  }

  /// Show optimization dialog with device-specific instructions
  Future<void> showOptimizationDialog(BuildContext context) async {
    final instructions = await getOptimizationInstructions();
    final isSamsung = await isSamsungDevice();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSamsung ? Icons.battery_alert : Icons.notifications_active,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isSamsung 
                  ? 'Samsung Device Setup Required'
                  : 'Notification Setup',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSamsung) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '⚠️ Samsung devices require special setup for reliable notifications. Please follow these steps carefully.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                instructions,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Open app settings (works on most Android versions)
  Future<void> _openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      // Fallback - this might not work on all devices
      try {
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    }
  }

  /// Check if battery optimization is disabled for the app
  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } catch (e) {
      debugPrint('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request to disable battery optimization
  Future<void> requestDisableBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestDisableBatteryOptimization');
    } catch (e) {
      debugPrint('Error requesting battery optimization disable: $e');
    }
  }
}