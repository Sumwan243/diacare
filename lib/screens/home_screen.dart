import 'package:diacare/providers/activity_provider.dart';
import 'package:diacare/providers/blood_sugar_provider.dart';
import 'package:diacare/providers/user_profile_provider.dart';
import 'package:diacare/providers/medication_provider.dart';
import 'package:diacare/screens/activity_history_screen.dart';
import 'package:diacare/screens/blood_sugar_history_screen.dart';
import 'package:diacare/screens/profile_screen.dart';
import 'package:diacare/screens/reminders_screen.dart';
import 'package:diacare/screens/ai_assistant_screen.dart';
import 'package:diacare/screens/meal_tab.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medication_reminder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // TOP IN-APP NOTIFICATION BANNER
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TopNotificationBanner(),
            ),

            // Scrollable main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Medication – wide top card
                    _DashboardCard(
                      title: 'Medication',
                      subtitle: 'View & manage reminders',
                      icon: Icons.medication,
                      color: primaryColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RemindersScreen(),
                        ),
                      ),
                      minHeight: 120,
                      wide: true,
                    ),
                    const SizedBox(height: 16),

                    // Middle grid: Meals + (Blood Tracker & Activity)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meals – tall left card
                        Expanded(
                          child: _DashboardCard(
                            title: 'Meals',
                            subtitle: 'Log today’s intake',
                            icon: Icons.soup_kitchen,
                            color: Colors.orangeAccent,
                            minHeight: 175,
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
                                minHeight: 80,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const BloodSugarHistoryScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _DashboardCard(
                                title: 'Physical Activity',
                                subtitle:
                                activityProv.getTodaySummary()['duration']! >
                                    0
                                    ? '${activityProv.getTodaySummary()['duration']} mins'
                                    : 'Log activity',
                                icon: Icons.directions_run,
                                color: Colors.green,
                                minHeight: 80,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const ActivityHistoryScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // AI / Personal Assistant card
                    _DashboardCard(
                      title: 'Personal Assistant',
                      subtitle: 'Ask about meals, symptoms, exercise',
                      icon: Icons.auto_awesome,
                      color: Colors.red,
                      minHeight: 90,
                      wide: true,
                      isAi: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Weekly progress
                    const _WeeklyProgressCard(),
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

/// Sleek, dismissible top banner showing the next upcoming reminder.
/// Currently uses MedicationProvider; later you can extend to activity/blood sugar.
class TopNotificationBanner extends StatefulWidget {
  const TopNotificationBanner({super.key});

  @override
  State<TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final medProv = context.watch<MedicationProvider>();
    final meds = medProv.reminders;

    final next = _findNextMedication(meds);
    final theme = Theme.of(context);

    // If there is nothing upcoming at all, you can either hide the banner
    // or show a neutral message. Here we show a subtle info state.
    if (next == null) {
      return Dismissible(
        key: const ValueKey('banner-none'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => setState(() => _dismissed = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_none,
                    color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No upcoming reminders. You’re all caught up!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeString = DateFormat.jm().format(next.dateTime);

    return Dismissible(
      key: const ValueKey('banner-next'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => setState(() => _dismissed = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active,
                  color: Colors.orangeAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next reminder',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${next.medication.name} • $timeString',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_left,
                color: Colors.orange.shade400, size: 20),
            Icon(Icons.chevron_right,
                color: Colors.orange.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  _NextEvent? _findNextMedication(List<MedicationReminder> meds) {
    final now = DateTime.now();
    final List<_NextEvent> events = [];

    for (final med in meds.where((m) => m.isEnabled)) {
      for (final t in med.times) {
        var dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
        if (dt.isBefore(now)) {
          dt = dt.add(const Duration(days: 1));
        }
        events.add(_NextEvent(medication: med, dateTime: dt));
      }
    }

    if (events.isEmpty) return null;
    events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return events.first;
  }
}

class _NextEvent {
  final MedicationReminder medication;
  final DateTime dateTime;

  _NextEvent({required this.medication, required this.dateTime});
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard();

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
                .map(
                  (day) =>
                  _buildDayCheck(day, completedDays.contains(day)),
            )
                .toList(),
          ),
          const Divider(
            height: 32,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_florist_outlined,
                color: Colors.green.shade300,
                size: 28,
              ),
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
            border: Border.all(
              color:
              isCompleted ? Colors.transparent : Colors.grey.shade300,
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
            color: isCompleted ? Colors.black : Colors.grey,
            fontWeight:
            isCompleted ? FontWeight.bold : FontWeight.normal,
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
    this.minHeight = 100,
    this.wide = false,
    this.verticalLayout = false,
    this.isAi = false,
  });

  @override
  Widget build(BuildContext context) {
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
          border: isAi
              ? Border.all(color: color.withOpacity(0.5), width: 1)
              : null,
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
      mainAxisSize: MainAxisSize.min,
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
          style:
          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisAlignment:
            MainAxisAlignment.center,
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