import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/providers/blood_pressure_provider.dart';
import 'package:diacare/screens/blood_sugar_history_screen.dart';
import 'package:diacare/screens/blood_pressure_history_screen.dart';
import 'package:diacare/screens/meal_tab.dart';
import 'package:diacare/screens/profile_screen.dart';
import 'package:diacare/screens/activity_tab.dart';
import 'package:diacare/screens/hydration_tab.dart';
import 'package:diacare/widgets/ai_insights_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _kSmallCardHeight = 112;
  static const double _kInnerGap = 12;
  static const double _kTallCardHeight = (_kSmallCardHeight * 2) + _kInnerGap;

  @override
  Widget build(BuildContext context) {
    final bloodSugarProv = context.watch<BloodSugarProvider>();
    final profile = context.watch<UserProfileProvider>().userProfile;

    final latest = bloodSugarProv.getLatestEntry();
    final bpProv = context.watch<BloodPressureProvider>();
    final latestBP = bpProv.getLatestEntry();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DiaCare',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface, // Use theme color for proper contrast
              ),
            ),
            Text(
              profile != null ? 'Welcome, ${profile.name}' : 'Welcome',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        toolbarHeight: 80, // Increased height to accommodate both titles
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Main health tracking cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: _kTallCardHeight,
                      child: _DashboardCard(
                        title: 'Meals',
                        subtitle: 'Log todays intake',
                        icon: Icons.restaurant_rounded,
                        color: const Color(0xFF2196F3), // Medical blue for nutrition
                        verticalLayout: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MealTab()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: _kSmallCardHeight,
                          child: _DashboardCard(
                            title: 'Glucose Tracker',
                            subtitle: latest != null
                                ? '${latest.level} mg/dL'
                                : 'No readings',
                            icon: Icons.water_drop_rounded,
                            color: const Color(0xFF4CAF50), // Medical green for glucose
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BloodSugarHistoryScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _kInnerGap),
                        SizedBox(
                          height: _kSmallCardHeight,
                          child: _DashboardCard(
                            title: 'Physical Activity',
                            subtitle: 'Track steps',
                            icon: Icons.directions_run_rounded,
                            color: const Color(0xFF9C27B0), // Medical purple for activity
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ActivityTab()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Health monitoring cards
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 160,
                      child: _DashboardCard(
                        title: 'Hydration',
                        subtitle: 'Track daily water intake',
                        icon: Icons.local_drink_rounded,
                        color: const Color(0xFF00BCD4), // Cyan for hydration
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HydrationTab()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 160,
                      child: _DashboardCard(
                        title: 'Blood Pressure',
                        subtitle: latestBP != null ? '${latestBP.systolic}/${latestBP.diastolic} mmHg' : 'No readings',
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFE91E63), // Medical red for heart/blood pressure
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BloodPressureHistoryScreen()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // AI Health Insights Card
              const AIInsightsCard(isCompact: true),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? accentColor;

  const _SurfaceCard({
    required this.child,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Base card color
    Color cardColor = isDark
        ? Color.alphaBlend(cs.onSurface.withValues(alpha: 0.06), cs.surface)
        : cs.surface;

    // Add subtle accent color tint to the card background
    if (accentColor != null) {
      cardColor = Color.alphaBlend(
        accentColor!.withValues(alpha: isDark ? 0.08 : 0.04), // Very subtle tint
        cardColor,
      );
    }

    // Use accent color for border if provided, otherwise use default
    final borderColor = accentColor != null 
        ? accentColor!.withValues(alpha: isDark ? 0.3 : 0.2)
        : cs.outline.withValues(alpha: isDark ? 0.35 : 0.18);

    final side = BorderSide(
      color: borderColor,
      width: accentColor != null ? 1.5 : 1, // Slightly thicker border for accent
    );

    return Material(
      color: cardColor,
      elevation: isDark ? 1.5 : 2.5,
      shadowColor: cs.shadow.withValues(alpha: isDark ? 0.55 : 0.14),
      surfaceTintColor: Colors.transparent, // Disable surface tint to avoid unwanted colors
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: side,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool verticalLayout;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.verticalLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _SurfaceCard(
      onTap: onTap,
      accentColor: color, // Pass accent color to surface card
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: verticalLayout ? _buildVertical(context, cs) : _buildHorizontal(context, cs),
      ),
    );
  }

  Widget _buildVertical(BuildContext context, ColorScheme cs) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.1), // Accent color background
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? null : color.withValues(alpha: 0.9), // Subtle accent on title in light mode
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildHorizontal(BuildContext context, ColorScheme cs) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark ? null : color.withValues(alpha: 0.9), // Subtle accent on title in light mode
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.1), // Accent color background
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ],
    );
  }
}