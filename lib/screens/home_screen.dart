import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/screens/activity_history_screen.dart';
import 'package:diacare/screens/blood_sugar_history_screen.dart';
import 'package:diacare/screens/meal_tab.dart';
import 'package:diacare/screens/profile_screen.dart';
import 'package:diacare/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _kSmallCardHeight = 112;
  static const double _kInnerGap = 12;
  static const double _kTallCardHeight = (_kSmallCardHeight * 2) + _kInnerGap;
  static const double _kWideCardHeight = 128;

  @override
  Widget build(BuildContext context) {
    final bloodSugarProv = context.watch<BloodSugarProvider>();
    final activityProv = context.watch<ActivityProvider>();
    final profile = context.watch<UserProfileProvider>().userProfile;

    final latest = bloodSugarProv.getLatestEntry();
    final todaySummary = activityProv.getTodaySummary();
    final int duration = todaySummary['duration'] ?? 0;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(profile != null ? 'Welcome, ${profile.name}' : 'Welcome'),
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
              SizedBox(
                height: _kWideCardHeight,
                child: _DashboardCard(
                  title: 'Medication',
                  subtitle: 'View & manage reminders',
                  icon: Icons.medication,
                  color: cs.primary,
                  wide: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: _kTallCardHeight,
                      child: _DashboardCard(
                        title: 'Meals',
                        subtitle: 'Log today’s intake',
                        icon: Icons.soup_kitchen,
                        color: cs.tertiary,
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
                            title: 'Blood Tracker',
                            subtitle: latest != null
                                ? '${latest.level} mg/dL'
                                : 'No readings',
                            icon: Icons.water_drop,
                            color: cs.secondary,
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
                            subtitle: duration > 0 ? '$duration mins' : 'Log activity',
                            icon: Icons.directions_run,
                            color: cs.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ActivityHistoryScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 112,
                child: _DashboardCard(
                  title: 'Personal Assistant',
                  subtitle: 'Ask about meals, symptoms, exercise',
                  icon: Icons.auto_awesome,
                  color: cs.primary,
                  wide: true,
                  isAi: true,
                  onTap: () {},
                ),
              ),

              const SizedBox(height: 16),
              const _WeeklyProgressCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard();

  @override
  Widget build(BuildContext context) {
    final activityProv = context.watch<ActivityProvider>();
    final completedDays = activityProv.getDaysWithActivityThisWeek();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
                  .map((day) => _DayCheck(day: day, isCompleted: completedDays.contains(day)))
                  .toList(),
            ),
            const Divider(height: 32, thickness: 0.5, indent: 16, endIndent: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_florist_outlined, color: cs.tertiary, size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Consistency is key. Keep up the great work!',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _DayCheck extends StatelessWidget {
  final String day;
  final bool isCompleted;

  const _DayCheck({required this.day, this.isCompleted = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final borderColor = isCompleted ? Colors.transparent : cs.outline.withOpacity(0.6);
    final fillColor = isCompleted ? cs.primary : Colors.transparent;
    final labelColor = isCompleted ? cs.onSurface : cs.onSurfaceVariant;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Icon(
            Icons.check,
            color: isCompleted ? cs.onPrimary : Colors.transparent,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.toUpperCase(),
          style: TextStyle(
            color: labelColor,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderSide? extraSide;

  const _SurfaceCard({
    required this.child,
    this.onTap,
    this.extraSide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color cardColor = isDark
        ? Color.alphaBlend(cs.onSurface.withOpacity(0.06), cs.surface)
        : cs.surface;

    final side = extraSide ??
        BorderSide(
          color: cs.outline.withOpacity(isDark ? 0.35 : 0.18),
          width: 1,
        );

    return Material(
      color: cardColor,
      elevation: isDark ? 1.5 : 2.5,
      shadowColor: cs.shadow.withOpacity(isDark ? 0.55 : 0.14),
      surfaceTintColor: cs.surfaceTint.withOpacity(isDark ? 0.18 : 0.08),
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
  final bool wide;
  final bool verticalLayout;
  final bool isAi;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
    this.verticalLayout = false,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final aiSide = isAi
        ? BorderSide(color: color.withOpacity(0.55), width: 1.2)
        : null;

    return _SurfaceCard(
      onTap: onTap,
      extraSide: aiSide,
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
            color: cs.secondaryContainer, // THEME-AWARE FIX
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 1,
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
                style: (wide ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
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
          padding: EdgeInsets.all(wide ? 16 : 12),
          decoration: BoxDecoration(
            color: cs.secondaryContainer, // THEME-AWARE FIX
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ],
    );
  }
}
