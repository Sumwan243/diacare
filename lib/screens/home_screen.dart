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

  // Fixed heights to prevent text scaling from breaking alignment.
  static const double _kSmallCardHeight = 112;
  static const double _kInnerGap = 12;
  static const double _kTallCardHeight = (_kSmallCardHeight * 2) + _kInnerGap;

  static const double _kWideCardHeight = 128;

  @override
  Widget build(BuildContext context) {
    final bloodSugarProv = context.watch<BloodSugarProvider>();
    final activityProv = context.watch<ActivityProvider>();
    final profile = context.watch<UserProfileProvider>().userProfile;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          profile != null ? 'Welcome, ${profile.name}' : 'Welcome',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
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
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  ),
                  wide: true,
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
                        color: Colors.orangeAccent,
                        verticalLayout: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MealTab()),
                          );
                        },
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
                            subtitle: bloodSugarProv.getLatestEntry() != null
                                ? '${bloodSugarProv.getLatestEntry()!.level} mg/dL'
                                : 'No readings',
                            icon: Icons.water_drop,
                            color: Colors.blueAccent,
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
                            subtitle: activityProv.getTodaySummary()['duration']! > 0
                                ? '${activityProv.getTodaySummary()['duration']} mins'
                                : 'Log activity',
                            icon: Icons.directions_run,
                            color: Colors.green,
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
                  color: Colors.teal,
                  wide: true,
                  isAi: true,
                  onTap: () {},
                ),
              ),

              const SizedBox(height: 16),
              _WeeklyProgressCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activityProv = context.watch<ActivityProvider>();
    final completedDays = activityProv.getDaysWithActivityThisWeek();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
                .map((day) => _buildDayCheck(day, completedDays.contains(day)))
                .toList(),
          ),
          const Divider(height: 32, thickness: 0.5, indent: 16, endIndent: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_florist_outlined, color: Colors.green.shade300, size: 28),
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
    );
  }

  Widget _buildDayCheck(String day, bool isCompleted) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : Colors.transparent,
            border: Border.all(
              color: isCompleted ? Colors.transparent : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.check,
            color: isCompleted ? Colors.white : Colors.transparent,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.toUpperCase(),
          style: TextStyle(
            color: isCompleted ? Colors.black87 : Colors.grey,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // keep consistent background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: isAi ? Border.all(color: color.withOpacity(0.45), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: verticalLayout ? _buildVertical(context) : _buildHorizontal(context),
          ),
        ),
      ),
    );
  }

  Widget _buildVertical(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 14),

        // Keep title stable under large text scale
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
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    final theme = Theme.of(context);

    // Smaller, more stable typography for dashboard cards
    final titleStyle = (wide ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
        ?.copyWith(fontWeight: FontWeight.bold);

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ],
    );
  }
}