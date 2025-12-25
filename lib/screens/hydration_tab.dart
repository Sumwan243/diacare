import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hydration_provider.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class HydrationTab extends StatefulWidget {
  const HydrationTab({super.key});

  @override
  State<HydrationTab> createState() => _HydrationTabState();
}

class _HydrationTabState extends State<HydrationTab> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _waveAnimation;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_waveController);
    
    _fillAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HydrationProvider(),
      child: Consumer<HydrationProvider>(
        builder: (context, hydrationProv, child) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          final progress = hydrationProv.dailyProgress;
          _fillController.animateTo(progress);
          
          return Scaffold(
            backgroundColor: cs.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              title: Text('Hydration Tracker', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Water Animation Card
                  _buildWaterAnimationCard(context, hydrationProv, progress),
                  
                  const SizedBox(height: 16),
                  
                  // Quick Add Buttons
                  _buildQuickAddButtons(context, hydrationProv),
                  
                  const SizedBox(height: 16),
                  
                  // Daily Stats
                  _buildDailyStatsCard(context, hydrationProv),
                  
                  const SizedBox(height: 16),
                  
                  // Hydration Tips
                  _buildHydrationTipsCard(context),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Intake Log
                  _buildRecentIntakeCard(context, hydrationProv),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWaterAnimationCard(BuildContext context, HydrationProvider hydrationProv, double progress) {
    final theme = Theme.of(context);
    final currentIntake = hydrationProv.currentIntake;
    final dailyGoal = hydrationProv.dailyGoal;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Daily Hydration',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: MedicalTheme.hydrationCyan,
              ),
            ),
            const SizedBox(height: 20),
            
            // Animated Water Glass
            SizedBox(
              width: 200,
              height: 300,
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveAnimation, _fillAnimation]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: WaterGlassPainter(
                      fillLevel: _fillAnimation.value,
                      waveOffset: _waveAnimation.value,
                      waterColor: MedicalTheme.hydrationCyan,
                    ),
                    size: const Size(200, 300),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress Text
            Text(
              '${currentIntake}ml / ${dailyGoal}ml',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: MedicalTheme.hydrationCyan,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '${(progress * 100).toInt()}% of daily goal',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(MedicalTheme.hydrationCyan),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButtons(BuildContext context, HydrationProvider hydrationProv) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Add',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddButton(context, hydrationProv, 250, 'Glass', Icons.local_drink),
                _buildQuickAddButton(context, hydrationProv, 500, 'Bottle', Icons.sports_bar),
                _buildQuickAddButton(context, hydrationProv, 750, 'Large', Icons.local_cafe),
              ],
            ),
            const SizedBox(height: 12),
            
            // Custom Amount
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Custom amount (ml)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (value) {
                      final amount = int.tryParse(value);
                      if (amount != null && amount > 0) {
                        hydrationProv.addIntake(amount);
                        _showIntakeAddedSnackBar(context, amount);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Handle custom amount submission
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MedicalTheme.hydrationCyan,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton(BuildContext context, HydrationProvider hydrationProv, int amount, String label, IconData icon) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            hydrationProv.addIntake(amount);
            _showIntakeAddedSnackBar(context, amount);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: MedicalTheme.hydrationCyan.withValues(alpha: 0.1),
            foregroundColor: MedicalTheme.hydrationCyan,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 0,
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${amount}ml',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showIntakeAddedSnackBar(BuildContext context, int amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${amount}ml to your daily intake!'),
        backgroundColor: MedicalTheme.hydrationCyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDailyStatsCard(BuildContext context, HydrationProvider hydrationProv) {
    final theme = Theme.of(context);
    final remaining = math.max(0, hydrationProv.dailyGoal - hydrationProv.currentIntake);
    final intakeCount = hydrationProv.todayIntakeCount;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Stats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(child: _buildStatItem(context, Icons.water_drop, '${remaining}ml', 'Remaining')),
                Flexible(child: _buildStatItem(context, Icons.format_list_numbered, '$intakeCount', 'Times')),
                Flexible(child: _buildStatItem(context, Icons.schedule, _getNextReminderTime(), 'Next Reminder')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: MedicalTheme.hydrationCyan, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getNextReminderTime() {
    final now = DateTime.now();
    final nextHour = now.add(const Duration(hours: 1));
    return '${nextHour.hour.toString().padLeft(2, '0')}:00';
  }

  Widget _buildHydrationTipsCard(BuildContext context) {
    final theme = Theme.of(context);
    
    final tips = [
      'Start your day with a glass of water',
      'Drink water before, during, and after exercise',
      'Keep a water bottle with you throughout the day',
      'Set regular reminders to drink water',
      'Eat water-rich foods like fruits and vegetables',
    ];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: MedicalTheme.hydrationCyan),
                const SizedBox(width: 8),
                Text(
                  'Hydration Tips',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: MedicalTheme.hydrationCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIntakeCard(BuildContext context, HydrationProvider hydrationProv) {
    final theme = Theme.of(context);
    final recentIntakes = hydrationProv.todayIntakes.take(5).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Intake',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (recentIntakes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No water intake logged today. Start hydrating!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...recentIntakes.map((intake) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: MedicalTheme.hydrationCyan.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.water_drop,
                    color: MedicalTheme.hydrationCyan,
                    size: 20,
                  ),
                ),
                title: Text('${intake.amount}ml'),
                trailing: Text(
                  TimeOfDay.fromDateTime(intake.timestamp).format(context),
                  style: theme.textTheme.bodySmall,
                ),
                contentPadding: EdgeInsets.zero,
              )),
          ],
        ),
      ),
    );
  }
}

class WaterGlassPainter extends CustomPainter {
  final double fillLevel;
  final double waveOffset;
  final Color waterColor;

  WaterGlassPainter({
    required this.fillLevel,
    required this.waveOffset,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw glass outline
    final glassRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
      const Radius.circular(20),
    );
    canvas.drawRRect(glassRect, paint);

    // Draw water
    if (fillLevel > 0) {
      final waterPaint = Paint()
        ..color = waterColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      final waterHeight = (size.height - 60) * fillLevel;
      final waterTop = size.height - 30 - waterHeight;

      // Create wave path
      final wavePath = Path();
      wavePath.moveTo(25, waterTop);

      for (double x = 25; x <= size.width - 25; x += 2) {
        final waveY = waterTop + math.sin((x / 20) + waveOffset) * 3;
        wavePath.lineTo(x, waveY);
      }

      wavePath.lineTo(size.width - 25, size.height - 30);
      wavePath.lineTo(25, size.height - 30);
      wavePath.close();

      canvas.drawPath(wavePath, waterPaint);
    }

    // Draw glass bottom
    final bottomPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, size.height - 30, size.width - 40, 10),
        const Radius.circular(5),
      ),
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}