import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/user_profile_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/ai_insights_screen.dart';
import '../screens/blood_sugar_history_screen.dart';
import '../screens/meal_tab.dart';
import '../screens/blood_pressure_history_screen.dart';
import '../theme/medical_icons.dart';
import 'package:hive/hive.dart';

class AIInsightsCard extends StatefulWidget {
  final bool isCompact; // For home screen vs full AI insights screen
  
  const AIInsightsCard({
    super.key,
    this.isCompact = false,
  });

  @override
  State<AIInsightsCard> createState() => _AIInsightsCardState();
}

class _AIInsightsCardState extends State<AIInsightsCard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fetch recommendations if user has API key and no recent recommendation
    if (!widget.isCompact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userProfile = context.read<UserProfileProvider>().userProfile;
        final hasApiKey = userProfile?.geminiApiKey?.isNotEmpty == true;
        final recommendationProv = context.read<RecommendationProvider>();
        
        if (hasApiKey && recommendationProv.recommendation.isEmpty) {
          debugPrint('AI Insights: Auto-fetching recommendations on screen load');
          _fetchRecommendations();
        }
      });
    }
  }

  Future<void> _fetchRecommendations({bool force = false}) async {
    debugPrint('AI Insights Card - _fetchRecommendations called with force: $force');
    
    if (_isLoading) {
      debugPrint('AI Insights Card - Already loading, returning early');
      return;
    }
    
    // Check if user has API key
    final userProfile = context.read<UserProfileProvider>().userProfile;
    final hasApiKey = userProfile?.geminiApiKey?.isNotEmpty == true;
    
    debugPrint('AI Insights Card - Has API key: $hasApiKey');
    
    if (!hasApiKey) {
      debugPrint('AI Insights Card - No API key, not fetching');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final recommendationProv = context.read<RecommendationProvider>();
      final bloodSugarProv = context.read<BloodSugarProvider>();
      final mealProv = context.read<MealProvider>();
      final medProv = context.read<MedicationProvider>();
      final bpProv = context.read<BloodPressureProvider>();
      final activityProv = context.read<ActivityProvider>();

      // Gather comprehensive health data with weekly analysis
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final userProfileProv = context.read<UserProfileProvider>();
      final userProfile = userProfileProv.userProfile;
      
      // Glucose - Weekly analysis
      final allGlucoseEntries = bloodSugarProv.entries;
      final weeklyGlucose = allGlucoseEntries
          .where((e) => e.timestamp.isAfter(weekAgo))
          .toList();
      
      final glucose = weeklyGlucose
          .take(20) // More entries for better analysis
          .map((e) => {
                'level': e.level,
                'context': e.context,
                'timestamp': e.timestamp.toIso8601String()
              })
          .toList();

      // Calculate glucose statistics
      final glucoseStats = weeklyGlucose.isNotEmpty ? {
        'weeklyCount': weeklyGlucose.length,
        'averageLevel': weeklyGlucose.map((e) => e.level).reduce((a, b) => a + b) / weeklyGlucose.length,
        'highReadings': weeklyGlucose.where((e) => e.level > (userProfile?.hyperThreshold ?? 300)).length,
        'lowReadings': weeklyGlucose.where((e) => e.level < (userProfile?.hypoThreshold ?? 70)).length,
        'inRangeReadings': weeklyGlucose.where((e) => 
          e.level >= (userProfile?.hypoThreshold ?? 70) && 
          e.level <= (userProfile?.hyperThreshold ?? 300)).length,
      } : null;

      // Meals - Weekly analysis  
      final allMeals = mealProv.meals;
      final weeklyMeals = allMeals
          .where((m) => m.timestamp.isAfter(weekAgo))
          .toList();
          
      final meals = weeklyMeals
          .take(15) // More meals for pattern analysis
          .map((m) => {
                'name': m.name,
                'calories': m.totalNutrients.caloriesKcal,
                'carbs': m.totalNutrients.carbsG,
                'protein': m.totalNutrients.proteinG,
                'fat': m.totalNutrients.fatG,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList();

      // Calculate meal statistics
      final mealStats = weeklyMeals.isNotEmpty ? {
        'weeklyCount': weeklyMeals.length,
        'avgDailyMeals': weeklyMeals.length / 7,
        'totalCalories': weeklyMeals.fold<double>(0, (sum, m) => sum + m.totalNutrients.caloriesKcal),
        'totalCarbs': weeklyMeals.fold<double>(0, (sum, m) => sum + m.totalNutrients.carbsG),
        'avgCaloriesPerMeal': weeklyMeals.fold<double>(0, (sum, m) => sum + m.totalNutrients.caloriesKcal) / weeklyMeals.length,
        'avgCarbsPerMeal': weeklyMeals.fold<double>(0, (sum, m) => sum + m.totalNutrients.carbsG) / weeklyMeals.length,
      } : null;

      // Medications with adherence tracking
      final meds = medProv.reminders
          .map((m) => {'id': m.id, 'name': m.name})
          .toList();

      // Blood Pressure - Weekly entries
      final weeklyBP = bpProv.entries
          .where((e) => e.timestamp.isAfter(weekAgo))
          .toList();
      
      final latestBp = bpProv.getLatestEntry();
      final bpMap = latestBp != null ? {
        'systolic': latestBp.systolic, 
        'diastolic': latestBp.diastolic,
        'weeklyCount': weeklyBP.length,
        'avgSystolic': weeklyBP.isNotEmpty ? weeklyBP.map((e) => e.systolic).reduce((a, b) => a + b) / weeklyBP.length : null,
        'avgDiastolic': weeklyBP.isNotEmpty ? weeklyBP.map((e) => e.diastolic).reduce((a, b) => a + b) / weeklyBP.length : null,
      } : null;

      // Activity - Weekly summary
      final activity = activityProv.getTodaySummary();
      // TODO: Add weekly activity analysis when available in provider

      // Get user profile for personalized recommendations
      final profileMap = userProfile != null ? {
        'diabeticType': userProfile.diabeticType.toString().split('.').last,
        'age': userProfile.age,
        'hypoThreshold': userProfile.hypoThreshold,
        'hyperThreshold': userProfile.hyperThreshold,
        'name': userProfile.name,
        'geminiApiKey': userProfile.geminiApiKey,
      } : null;

      debugPrint('AI Insights Card - Weekly data summary:');
      debugPrint('  - Glucose entries (week): ${weeklyGlucose.length}');
      debugPrint('  - Meals (week): ${weeklyMeals.length}');
      debugPrint('  - BP readings (week): ${weeklyBP.length}');
      debugPrint('  - Medications tracked: ${meds.length}');
      debugPrint('  - Activity: ${activity.isNotEmpty ? "Available" : "None"}');
      debugPrint('  - User profile: ${profileMap != null ? "Available" : "None"}');

      // Read recent intake logs from Hive
      List<Map<String, dynamic>> intakeLogs = [];
      try {
        final box = Hive.box('med_intake_log_box');
        for (final v in box.values.take(20)) {
          if (v is Map) intakeLogs.add(Map<String, dynamic>.from(v));
        }
      } catch (_) {
        intakeLogs = [];
      }

      await recommendationProv.fetchRecommendation(
        glucose: glucose,
        meals: meals,
        medications: meds,
        bloodPressure: bpMap,
        activity: activity,
        intakeLogs: intakeLogs,
        userProfile: profileMap,
        glucoseStats: glucoseStats,
        mealStats: mealStats,
        force: force,
      );
      
      debugPrint('AI Insights Card - Fetch completed. New recommendation: "${recommendationProv.recommendation.isEmpty ? "EMPTY" : recommendationProv.recommendation.substring(0, recommendationProv.recommendation.length > 50 ? 50 : recommendationProv.recommendation.length)}..."');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint('AI Insights Card - Loading state set to false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendationProv = context.watch<RecommendationProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    final hasApiKey = userProfile?.geminiApiKey?.isNotEmpty == true;
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: widget.isCompact ? () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIInsightsScreen()),
        ) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.15 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: MedicalIcons.ai(size: widget.isCompact ? 20 : 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isCompact ? 'AI Health Insights' : 'Personalized Health Recommendations',
                          style: (widget.isCompact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? null : const Color(0xFFFFB300).withValues(alpha: 0.9),
                          ),
                        ),
                        if (widget.isCompact) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tap for detailed analysis',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!widget.isCompact && hasApiKey)
                    IconButton(
                      onPressed: !_isLoading ? () => _fetchRecommendations(force: true) : null,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  if (widget.isCompact)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Content
              if (!hasApiKey)
                _buildNoApiKeyContent(context, theme, isDark)
              else if (_isLoading || recommendationProv.isLoading)
                _buildLoadingContent(context, theme)
              else if (recommendationProv.recommendation.isNotEmpty)
                _buildRecommendationContent(context, recommendationProv, theme, isDark)
              else
                _buildReadyContent(context, theme, isDark),
              
              // Daily logging prompts (only on home screen)
              if (widget.isCompact && hasApiKey)
                _buildDailyPrompts(context, theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoApiKeyContent(BuildContext context, ThemeData theme, bool isDark) {
    if (widget.isCompact) {
      return Text(
        'Set up your API key to get personalized diabetes recommendations',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    return Column(
      children: [
        Icon(
          Icons.key_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'API Key Required',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'To get personalized diabetes recommendations, please add your Gemini API key in profile settings.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          icon: const Icon(Icons.settings),
          label: const Text('Open Profile Settings'),
        ),
      ],
    );
  }

  Widget _buildLoadingContent(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.isCompact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analyzing your health data...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyContent(BuildContext context, ThemeData theme, bool isDark) {
    if (widget.isCompact) {
      return Text(
        'Ready to analyze your health data. Tap to get AI insights.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    return Column(
      children: [
        MedicalIcons.info(size: 48),
        const SizedBox(height: 16),
        Text(
          'Ready to analyze your health data',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Get personalized diabetes recommendations based on your logged glucose, meals, medications, and activity data.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _fetchRecommendations(force: true),
          icon: MedicalIcons.analytics(),
          label: const Text('Get AI Insights'),
        ),
      ],
    );
  }

  Widget _buildRecommendationContent(BuildContext context, RecommendationProvider provider, ThemeData theme, bool isDark) {
    // Check different states of the recommendation
    final isOutdated = _isRecommendationOutdated(provider.recommendation);
    final isNetworkError = _isNetworkError(provider.recommendation);
    final isNoData = _isNoDataAvailable(provider.recommendation);
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.recommendation,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.6,
          ),
          maxLines: widget.isCompact ? 3 : null,
          overflow: widget.isCompact ? TextOverflow.ellipsis : null,
        ),
        if (!widget.isCompact && provider.lastUpdatedDisplay != null) ...[
          const SizedBox(height: 12),
          Text(
            'Last updated: ${provider.lastUpdatedDisplay}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ],
        // Warranty disclaimer (only on full screen)
        if (!widget.isCompact) ...[
          const SizedBox(height: 16),
          Text(
            '⚠️ Disclaimer: This AI analysis is for informational purposes only and should not replace professional medical advice. Always consult your healthcare provider for medical decisions.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
    
    // Apply blur effect and overlay for different states (only on full screen)
    if (!widget.isCompact && (isOutdated || isNetworkError || isNoData)) {
      String overlayTitle;
      String overlayMessage;
      IconData overlayIcon;
      Color overlayColor;
      
      if (isNetworkError) {
        overlayTitle = 'Connection Issue';
        overlayMessage = 'Check internet connection and tap refresh';
        overlayIcon = Icons.wifi_off_rounded;
        overlayColor = Colors.red;
      } else if (isNoData) {
        overlayTitle = 'No Health Data';
        overlayMessage = 'Log some health data first, then refresh';
        overlayIcon = Icons.data_usage_rounded;
        overlayColor = Colors.blue;
      } else {
        overlayTitle = 'Outdated Analysis';
        overlayMessage = 'Tap refresh for comprehensive health insights';
        overlayIcon = Icons.refresh_rounded;
        overlayColor = Colors.orange;
      }
      
      return Stack(
        children: [
          // Blurred content
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Opacity(
              opacity: 0.6,
              child: content,
            ),
          ),
          // Overlay with appropriate message
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      overlayIcon,
                      size: 32,
                      color: overlayColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overlayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      overlayMessage,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return content;
  }

  bool _isRecommendationOutdated(String recommendation) {
    final outdatedPhrases = [
      'Excellent glucose control!',
      'Keep up your current diabetes management routine',
      'Your glucose is in a good range',
      'Continue monitoring and maintaining your healthy habits',
      'Start logging your glucose readings',
      'Begin tracking your meals',
      'Keep tracking your health data',
    ];
    
    return outdatedPhrases.any((phrase) => 
      recommendation.toLowerCase().contains(phrase.toLowerCase()));
  }

  bool _isNetworkError(String recommendation) {
    final networkErrorPhrases = [
      'no internet connection',
      'network error',
      'connection failed',
      'request timed out',
      'failed to connect',
    ];
    
    return networkErrorPhrases.any((phrase) => 
      recommendation.toLowerCase().contains(phrase.toLowerCase()));
  }

  bool _isNoDataAvailable(String recommendation) {
    final noDataPhrases = [
      'no glucose readings recorded',
      'no meals logged',
      'no recent activity logged',
      'no medications tracked',
      'start logging',
      'begin tracking',
    ];
    
    return noDataPhrases.any((phrase) => 
      recommendation.toLowerCase().contains(phrase.toLowerCase()));
  }

  Widget _buildDailyPrompts(BuildContext context, ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check what data has been logged today
    final bloodSugarProv = context.watch<BloodSugarProvider>();
    final mealProv = context.watch<MealProvider>();
    final bpProv = context.watch<BloodPressureProvider>();
    
    final todayGlucose = bloodSugarProv.entries
        .where((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day) == today)
        .length;
    
    final todayMeals = mealProv.meals
        .where((m) => DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day) == today)
        .length;
    
    final todayBP = bpProv.entries
        .where((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day) == today)
        .length;

    List<Widget> prompts = [];
    
    // Glucose prompt (if less than 2 readings today)
    if (todayGlucose < 2) {
      prompts.add(_buildPromptChip(
        context,
        icon: Icons.water_drop_rounded,
        label: 'Log Glucose',
        color: const Color(0xFF4CAF50),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BloodSugarHistoryScreen()),
        ),
      ));
    }
    
    // Meal prompt (if less than 2 meals today)
    if (todayMeals < 2) {
      prompts.add(_buildPromptChip(
        context,
        icon: Icons.restaurant_rounded,
        label: 'Log Meal',
        color: const Color(0xFF2196F3),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MealTab()),
        ),
      ));
    }
    
    // BP prompt (if no reading today)
    if (todayBP == 0) {
      prompts.add(_buildPromptChip(
        context,
        icon: Icons.favorite_rounded,
        label: 'Log BP',
        color: const Color(0xFFE91E63),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BloodPressureHistoryScreen()),
        ),
      ));
    }
    
    if (prompts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Quick Log Today',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: prompts,
        ),
      ],
    );
  }

  Widget _buildPromptChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}