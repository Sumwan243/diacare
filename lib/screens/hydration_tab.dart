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
    final isApproachingLimit = hydrationProv.isApproachingLimit();
    final hasReachedLimit = hydrationProv.hasReachedMaxLimit();
    
    // Determine card color based on safety status
    Color cardColor = theme.cardColor;
    Color progressColor = MedicalTheme.hydrationCyan;
    
    if (hasReachedLimit) {
      cardColor = Colors.red.shade50;
      progressColor = Colors.red;
    } else if (isApproachingLimit) {
      cardColor = Colors.orange.shade50;
      progressColor = Colors.orange;
    }
    
    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Daily Hydration',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
            
            // Safety warning banner
            if (hasReachedLimit || isApproachingLimit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasReachedLimit ? Colors.red.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasReachedLimit ? Colors.red : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasReachedLimit ? Icons.dangerous : Icons.warning,
                      color: hasReachedLimit ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasReachedLimit 
                          ? 'MAXIMUM SAFE LIMIT REACHED'
                          : 'APPROACHING SAFE LIMIT',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasReachedLimit ? Colors.red.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
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
                      waterColor: progressColor,
                    ),
                    size: const Size(200, 300),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress Text with safety info
            Text(
              '${currentIntake}ml / ${dailyGoal}ml',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              'Safe limit: ${HydrationProvider.maxDailyIntake}ml (${(HydrationProvider.maxDailyIntake/1000).toStringAsFixed(1)}L)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
            
            // Safety progress bar (showing progress toward max limit)
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (currentIntake / HydrationProvider.maxDailyIntake).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                currentIntake >= HydrationProvider.warningThreshold 
                  ? (hasReachedLimit ? Colors.red : Colors.orange)
                  : Colors.green,
              ),
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Text(
              'Safety: ${currentIntake}ml / ${HydrationProvider.maxDailyIntake}ml',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
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
                      helperText: 'Max: ${HydrationProvider.maxSingleIntake}ml per intake',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (value) {
                      final amount = int.tryParse(value);
                      if (amount != null && amount > 0) {
                        _addIntakeWithValidation(context, hydrationProv, amount);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Handle custom amount submission with validation
                    _showCustomAmountDialog(context, hydrationProv);
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
    // Check if this amount would be safe to add
    final validation = hydrationProv.validateIntakeAmount(amount);
    final isValid = validation['isValid'] as bool;
    final validationType = validation['type'] as String;
    
    // Determine button appearance based on safety
    Color buttonColor = MedicalTheme.hydrationCyan;
    Color backgroundColor = MedicalTheme.hydrationCyan.withValues(alpha: 0.1);
    
    if (!isValid) {
      buttonColor = Colors.red;
      backgroundColor = Colors.red.withValues(alpha: 0.1);
    } else if (validationType == 'warning') {
      buttonColor = Colors.orange;
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
    }
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: isValid ? () {
            _addIntakeWithValidation(context, hydrationProv, amount);
          } : () {
            _showSafetyWarning(context, validation['message'] as String);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: buttonColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 0,
          ),
          child: Icon(
            isValid ? icon : Icons.block,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isValid ? null : Colors.red,
          ),
        ),
        Text(
          '${amount}ml',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isValid 
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Colors.red,
          ),
        ),
        if (!isValid) ...[
          const SizedBox(height: 2),
          Icon(
            Icons.warning,
            size: 12,
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  Future<void> _addIntakeWithValidation(BuildContext context, HydrationProvider hydrationProv, int amount) async {
    try {
      await hydrationProv.addIntake(amount);
      _showIntakeAddedSnackBar(context, amount);
    } catch (e) {
      if (e is HydrationException) {
        _showSafetyWarning(context, e.message);
      } else {
        _showErrorSnackBar(context, 'Failed to add water intake: $e');
      }
    }
  }

  void _showSafetyWarning(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Safety Warning'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, HydrationProvider hydrationProv) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (ml)',
                helperText: 'Max: ${HydrationProvider.maxSingleIntake}ml per intake',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Remaining safe intake today: ${hydrationProv.getRemainingIntake()}ml',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                Navigator.pop(ctx);
                _addIntakeWithValidation(context, hydrationProv, amount);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
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
    final safeRemaining = hydrationProv.getRemainingIntake();
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
                Flexible(child: _buildStatItem(context, Icons.water_drop, '${remaining}ml', 'To Goal')),
                Flexible(child: _buildStatItem(context, Icons.shield, '${safeRemaining}ml', 'Safe Remaining')),
                Flexible(child: _buildStatItem(context, Icons.format_list_numbered, '$intakeCount', 'Times')),
              ],
            ),
            
            // Safety status message
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hydrationProv.hasReachedMaxLimit() 
                  ? Colors.red.shade50
                  : hydrationProv.isApproachingLimit()
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hydrationProv.hasReachedMaxLimit() 
                    ? Colors.red.shade200
                    : hydrationProv.isApproachingLimit()
                      ? Colors.orange.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hydrationProv.hasReachedMaxLimit() 
                      ? Icons.dangerous
                      : hydrationProv.isApproachingLimit()
                        ? Icons.warning
                        : Icons.check_circle,
                    color: hydrationProv.hasReachedMaxLimit() 
                      ? Colors.red
                      : hydrationProv.isApproachingLimit()
                        ? Colors.orange
                        : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hydrationProv.getHydrationStatus(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hydrationProv.hasReachedMaxLimit() 
                          ? Colors.red.shade800
                          : hydrationProv.isApproachingLimit()
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildHydrationTipsCard(BuildContext context) {
    final theme = Theme.of(context);
    
    final tips = [
      'Start your day with a glass of water',
      'Drink water before, during, and after exercise',
      'Keep a water bottle with you throughout the day',
      'Set regular reminders to drink water',
      'Eat water-rich foods like fruits and vegetables',
    ];
    
    final safetyTips = [
      '⚠️ Don\'t exceed 4L (4000ml) of water per day',
      '⚠️ Limit single intake to 1L (1000ml) or less',
      '⚠️ Spread water intake throughout the day',
      '⚠️ Stop if you feel nauseous or dizzy from water',
      '⚠️ Consult a doctor if you have kidney issues',
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
                  'Hydration Tips & Safety',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Regular tips
            Text(
              'Healthy Habits:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            
            // Safety tips
            Text(
              'Safety Guidelines:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 4),
            ...safetyTips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                      ),
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