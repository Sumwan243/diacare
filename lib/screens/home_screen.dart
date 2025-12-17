import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/screens/activity_history_screen.dart';
import 'package:diacare/screens/add_blood_sugar_screen.dart';
import 'package:diacare/screens/blood_sugar_history_screen.dart';
import 'package:diacare/screens/meal_tab.dart';
import 'package:diacare/screens/profile_screen.dart';
import 'package:diacare/screens/reminders_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- CONSTANTS FOR LAYOUT ---
  static const double _kSmallCardMinHeight = 80;
  static const double _kInnerGap = 12;
  static const double _kTallCardMinHeight =
      (_kSmallCardMinHeight * 2) + _kInnerGap;

  @override
  Widget build(BuildContext context) {
    final bloodSugarProv = context.watch<BloodSugarProvider>();
    final activityProv = context.watch<ActivityProvider>();
    final profile = context.watch<UserProfileProvider>().userProfile;

    final primaryColor = Colors.redAccent;
    final backgroundColor = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          profile != null ? 'Welcome, ${profile.name}' : 'Welcome',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _DashboardCard(
                      title: 'Medication',
                      subtitle: 'View & manage reminders',
                      icon: Icons.medication,
                      color: primaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RemindersScreen()),
                      ),
                      minHeight: 120,
                      wide: true,
                    ),
                    const SizedBox(height: 16),
                    // --- MIDDLE GRID ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meals – tall left card (match right stack height)
                        Expanded(
                          child: _DashboardCard(
                            title: 'Meals',
                            subtitle: 'Log today’s intake',
                            icon: Icons.soup_kitchen,
                            color: Colors.orangeAccent,
                            minHeight: _kTallCardMinHeight,
                            verticalLayout: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MealTab()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 18),

                        // Right column – Blood Tracker + Physical Activity
                        Expanded(
                          child: Column(
                            children: [
                              _DashboardCard(
                                title: 'Blood Tracker',
                                subtitle: bloodSugarProv.getLatestEntry() != null
                                    ? '${bloodSugarProv.getLatestEntry()!.level} mg/dL'
                                    : 'No readings',
                                icon: Icons.water_drop,
                                color: Colors.blueAccent,
                                minHeight: _kSmallCardMinHeight,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BloodSugarHistoryScreen()),
                                ),
                              ),
                              const SizedBox(height: _kInnerGap),
                              _DashboardCard(
                                title: 'Physical Activity',
                                subtitle: activityProv.getTodaySummary()['duration']! > 0
                                    ? '${activityProv.getTodaySummary()['duration']} mins'
                                    : 'Log activity',
                                icon: Icons.directions_run,
                                color: Colors.green,
                                minHeight: _kSmallCardMinHeight,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ActivityHistoryScreen()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DashboardCard(
                      title: 'Personal Assistant',
                      subtitle: 'Ask about meals, symptoms, exercise',
                      icon: Icons.auto_awesome,
                      color: Colors.red,
                      minHeight: 90,
                      wide: true,
                      isAi: true,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    _WeeklyProgressCard(),
                  ],
                ),
              ),
            ),
          ],
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

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
              const Flexible(
                child: Text(
                  'Consistency is key. Keep up the great work!',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
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
            border: Border.all(color: isCompleted ? Colors.transparent : Colors.grey.shade300, width: 2),
          ),
          child: Icon(
            Icons.check,
            color: isCompleted ? Colors.white : Colors.transparent,
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(day.toUpperCase(), style: TextStyle(color: isCompleted ? Colors.black : Colors.grey, fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
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
  final double minHeight;
  final bool wide;
  final bool verticalLayout;
  final bool isAi;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.minHeight = 0,
    this.wide = false,
    this.verticalLayout = false,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
    // Removed the incorrect Expanded widget from here
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: isAi ? Border.all(color: color.withOpacity(0.5), width: 1) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: verticalLayout ? _buildVertical() : _buildHorizontal(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVertical() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHorizontal() {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: wide ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: isAi ? Colors.black : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isAi ? Colors.black : Colors.grey[500],
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
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ],
    );
  }
}
