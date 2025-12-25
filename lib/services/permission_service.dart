import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all permissions needed by the app on startup
  static Future<void> requestAllPermissions(BuildContext context) async {
    final androidInfo = Platform.isAndroid ? await DeviceInfoPlugin().androidInfo : null;
    final androidVersion = androidInfo?.version.sdkInt ?? 0;
    
    // Build permission list based on Android version and device capabilities
    List<Permission> permissions = [
      Permission.activityRecognition, // For step counting
    ];

    // Add notification permission for Android 13+
    if (androidVersion >= 33) {
      permissions.add(Permission.notification);
    }

    // Add location permissions for some devices that need it for step counting
    if (androidVersion >= 23) {
      permissions.add(Permission.locationWhenInUse);
    }

    // Add sensors permission for some manufacturers
    permissions.add(Permission.sensors);

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    // Handle denied permissions
    List<Permission> deniedPermissions = [];
    statuses.forEach((permission, status) {
      if (status.isDenied || status.isPermanentlyDenied) {
        deniedPermissions.add(permission);
      }
    });

    // Only show dialog for critical permissions
    List<Permission> criticalDenied = deniedPermissions.where((p) => 
      p == Permission.activityRecognition || 
      p == Permission.notification
    ).toList();

    if (criticalDenied.isNotEmpty && context.mounted) {
      _showPermissionDialog(context, criticalDenied);
    }
  }

  /// Check if activity recognition permission is granted
  static Future<bool> isActivityPermissionGranted() async {
    final status = await Permission.activityRecognition.status;
    
    // Also check alternative permissions that might be needed
    if (status.isGranted) return true;
    
    // Check sensors permission as fallback
    final sensorsStatus = await Permission.sensors.status;
    if (sensorsStatus.isGranted) return true;
    
    // Check location permission (some devices require this)
    final locationStatus = await Permission.locationWhenInUse.status;
    return locationStatus.isGranted;
  }

  /// Request activity recognition permission specifically
  static Future<bool> requestActivityPermission() async {
    // Try activity recognition first
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) return true;
    
    // Try sensors permission as fallback
    status = await Permission.sensors.request();
    if (status.isGranted) return true;
    
    // Try location permission for devices that need it
    status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Check device compatibility for step counting
  static Future<bool> isStepCountingSupported() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final model = androidInfo.model.toLowerCase();
      
      // Known problematic devices/manufacturers
      final problematicDevices = [
        'emulator',
        'sdk_gphone',
        'android sdk built for',
      ];
      
      for (final device in problematicDevices) {
        if (model.contains(device)) return false;
      }
      
      // Most modern Android devices support step counting
      return androidInfo.version.sdkInt >= 19; // KitKat+
    } catch (e) {
      return false;
    }
  }

  /// Show dialog explaining why permissions are needed
  static void _showPermissionDialog(BuildContext context, List<Permission> deniedPermissions) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DiaCare needs the following permissions to work properly:'),
            const SizedBox(height: 12),
            ...deniedPermissions.map((permission) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(_getPermissionIcon(permission), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_getPermissionDescription(permission))),
                ],
              ),
            )),
            const SizedBox(height: 8),
            const Text(
              'You can always change these permissions later in your device settings.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Without'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings(); // Open system settings
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static IconData _getPermissionIcon(Permission permission) {
    if (permission == Permission.activityRecognition) {
      return Icons.directions_run;
    } else if (permission == Permission.notification) {
      return Icons.notifications;
    } else if (permission == Permission.locationWhenInUse) {
      return Icons.location_on;
    } else if (permission == Permission.sensors) {
      return Icons.sensors;
    } else {
      return Icons.security;
    }
  }

  static String _getPermissionDescription(Permission permission) {
    if (permission == Permission.activityRecognition) {
      return 'Physical Activity - Track your daily steps and movement';
    } else if (permission == Permission.notification) {
      return 'Notifications - Remind you about medications and health goals';
    } else if (permission == Permission.locationWhenInUse) {
      return 'Location - Required by some devices for step counting';
    } else if (permission == Permission.sensors) {
      return 'Sensors - Access motion sensors for activity tracking';
    } else {
      return 'Required for app functionality';
    }
  }
}