import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppTab {
  home(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    color: Color(0xFF00BCD4), // Cyan for home
  ),
  medications(
    label: 'Medications',
    icon: Icons.medication_outlined,
    activeIcon: Icons.medication_rounded,
    color: Color(0xFFE91E63), // Red for medications
  ),
  aiInsights(
    label: 'AI Insights',
    icon: Icons.psychology_outlined,
    activeIcon: Icons.psychology_rounded,
    color: Color(0xFFFFB300), // Orange for AI insights
  );

  const AppTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color color;
}

class MedicalBottomNavigation extends StatelessWidget {
  final AppTab currentTab;
  final Function(AppTab) onTabChanged;

  const MedicalBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: isDark ? MedicalTheme.darkCard : MedicalTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: AppTab.values.map((tab) {
            final isActive = tab == currentTab;
            return _buildNavItem(
              context,
              tab,
              isActive,
              () => onTabChanged(tab),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AppTab tab,
    bool isActive,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color iconColor;
    Color labelColor;
    
    if (isActive) {
      iconColor = tab.color;
      labelColor = tab.color;
    } else {
      iconColor = isDark ? Colors.white70 : Colors.black54;
      labelColor = isDark ? Colors.white70 : Colors.black54;
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}