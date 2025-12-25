import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Medical colors - aliases to MedicalTheme for compatibility
class MedicalColors {
  static const Color activityPurple = MedicalTheme.activityPurple;
  static const Color hydrationCyan = MedicalTheme.hydrationCyan;
  static const Color glucoseGreen = MedicalTheme.glucoseGreen;
  static const Color heartRed = MedicalTheme.heartRed;
  static const Color nutritionBlue = MedicalTheme.nutritionBlue;
  static const Color medicationOrange = MedicalTheme.medicationOrange;
  
  // Dark mode variants
  static const Color darkActivityPurple = MedicalTheme.darkActivityPurple;
  static const Color darkHydrationCyan = MedicalTheme.darkHydrationCyan;
}

/// Medical icons with appropriate colors for healthcare applications
class MedicalIcons {
  // Navigation Icons
  static const IconData home = Icons.home_rounded;
  static const IconData medications = Icons.medication_rounded;
  static const IconData aiInsights = Icons.psychology_rounded;
  
  // Health Category Icons with Colors
  static Widget glucose({double size = 24}) => Icon(
    Icons.water_drop_rounded,
    color: MedicalTheme.glucoseGreen,
    size: size,
  );
  
  static Widget medication({double size = 24}) => Icon(
    Icons.medication_liquid_rounded,
    color: MedicalTheme.medicationOrange,
    size: size,
  );
  
  static Widget activity({double size = 24}) => Icon(
    Icons.directions_run_rounded,
    color: MedicalTheme.activityPurple,
    size: size,
  );
  
  static Widget ai({double size = 24}) => Icon(
    Icons.auto_awesome_rounded,
    color: MedicalTheme.aiGold,
    size: size,
  );
  
  static Widget bloodPressure({double size = 24}) => Icon(
    Icons.favorite_rounded,
    color: MedicalTheme.heartRed,
    size: size,
  );
  
  static Widget nutrition({double size = 24}) => Icon(
    Icons.restaurant_rounded,
    color: MedicalTheme.nutritionBlue,
    size: size,
  );
  
  // Status Icons
  static Widget success({double size = 24}) => Icon(
    Icons.check_circle_rounded,
    color: MedicalTheme.successGreen,
    size: size,
  );
  
  static Widget warning({double size = 24}) => Icon(
    Icons.warning_rounded,
    color: MedicalTheme.warningAmber,
    size: size,
  );
  
  static Widget error({double size = 24}) => Icon(
    Icons.error_rounded,
    color: MedicalTheme.errorRed,
    size: size,
  );
  
  static Widget info({double size = 24}) => Icon(
    Icons.info_rounded,
    color: MedicalTheme.infoBlue,
    size: size,
  );
  
  // Medical Action Icons
  static Widget add({double size = 24}) => Icon(
    Icons.add_circle_rounded,
    color: MedicalTheme.primaryMedicalBlue,
    size: size,
  );
  
  static Widget edit({double size = 24}) => Icon(
    Icons.edit_rounded,
    color: MedicalTheme.primaryMedicalBlue,
    size: size,
  );
  
  static Widget delete({double size = 24}) => Icon(
    Icons.delete_rounded,
    color: MedicalTheme.errorRed,
    size: size,
  );
  
  static Widget analytics({double size = 24}) => Icon(
    Icons.analytics_rounded,
    color: MedicalTheme.primaryMedicalBlue,
    size: size,
  );
  
  static Widget export({double size = 24}) => Icon(
    Icons.file_download_rounded,
    color: MedicalTheme.primaryMedicalBlue,
    size: size,
  );
}