import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/blood_sugar_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/blood_pressure_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/user_profile_provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with WidgetsBindingObserver {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {}); // Trigger rebuild to get fresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final recommendationProv = context.watch<RecommendationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Assistant'),
            Text(
              'Ask follow-up questions',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: cs.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: recommendationProv.chatHistory.isEmpty
                ? null
                : () => _showClearChatDialog(context, recommendationProv),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: recommendationProv.chatHistory.isEmpty
                  ? _buildEmptyChatState(context, theme, cs, recommendationProv)
                  : _buildChatList(context, theme, cs, recommendationProv),
            ),

            // Quick suggestion chips
            if (recommendationProv.chatHistory.isEmpty)
              _buildQuickSuggestions(context, theme, cs, recommendationProv),

            // Input area
            _buildInputArea(context, theme, cs, recommendationProv),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    RecommendationProvider recommendationProv,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Personal Health Assistant',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ask questions about your health data, get personalized recommendations, or clarify your recent readings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: recommendationProv.isLoading
                    ? null
                    : () => _fetchInitialRecommendation(context, recommendationProv),
                icon: recommendationProv.isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                  ),
                )
                    : const Icon(Icons.lightbulb_outlined),
                label: Text(
                  recommendationProv.isLoading ? 'Analyzing...' : 'Get Initial Recommendation',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    RecommendationProvider recommendationProv,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: recommendationProv.chatHistory.length,
      itemBuilder: (context, index) {
        final message = recommendationProv.chatHistory[index];
        return _ChatBubble(
          message: message,
          isUser: message.role == 'user',
        );
      },
    );
  }

  Widget _buildQuickSuggestions(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    RecommendationProvider recommendationProv,
  ) {
    // Get current health data to make suggestions more relevant
    final bloodSugarProv = context.watch<BloodSugarProvider>();
    final mealProv = context.watch<MealProvider>();
    final bpProv = context.watch<BloodPressureProvider>();
    
    final hasRecentGlucose = bloodSugarProv.entries.isNotEmpty;
    final hasRecentMeals = mealProv.meals.isNotEmpty;
    final hasRecentBP = bpProv.entries.isNotEmpty;
    
    List<String> suggestions = [];
    
    // Dynamic suggestions based on available data
    if (hasRecentGlucose) {
      final latestLevel = bloodSugarProv.entries.first.level;
      if (latestLevel > 140) {
        suggestions.add('Why is my glucose ${latestLevel} mg/dL?');
        suggestions.add('What should I do about high glucose?');
      } else if (latestLevel < 80) {
        suggestions.add('Is ${latestLevel} mg/dL too low?');
        suggestions.add('What should I eat for low glucose?');
      } else {
        suggestions.add('What does my glucose trend show?');
        suggestions.add('How can I maintain good control?');
      }
    } else {
      suggestions.add('When should I check my glucose?');
      suggestions.add('What are normal glucose ranges?');
    }
    
    if (hasRecentMeals) {
      suggestions.add('How did my last meal affect glucose?');
      suggestions.add('What foods should I avoid?');
    } else {
      suggestions.add('What should I eat for breakfast?');
      suggestions.add('How many carbs should I have per meal?');
    }
    
    if (hasRecentBP) {
      final latestBP = bpProv.getLatestEntry();
      if (latestBP != null && (latestBP.systolic > 130 || latestBP.diastolic > 80)) {
        suggestions.add('Is my blood pressure ${latestBP.systolic}/${latestBP.diastolic} concerning?');
      } else {
        suggestions.add('How does blood pressure relate to diabetes?');
      }
    } else {
      suggestions.add('How often should I check blood pressure?');
    }
    
    // Always include some general helpful suggestions
    suggestions.addAll([
      'What exercises are best for diabetes?',
      'How can I improve my sleep?',
      'What are signs of complications?',
    ]);
    
    // Limit to 6 suggestions and shuffle for variety
    suggestions.shuffle();
    final displaySuggestions = suggestions.take(6).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: displaySuggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                suggestion,
                style: const TextStyle(fontSize: 13),
              ),
              avatar: const Icon(Icons.lightbulb_outline, size: 16),
              onPressed: () {
                _questionController.text = suggestion;
                _sendQuestion(context);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
    RecommendationProvider recommendationProv,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a follow-up question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: 3,
              enabled: !_isSending && recommendationProv.chatHistory.isNotEmpty,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _isSending || recommendationProv.chatHistory.isEmpty
                ? null
                : () => _sendQuestion(context),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            child: _isSending
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
              ),
            )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchInitialRecommendation(
    BuildContext context,
    RecommendationProvider recommendationProv,
  ) async {
    setState(() => _isSending = true);

    final bloodSugarProv = context.read<BloodSugarProvider>();
    final mealProv = context.read<MealProvider>();
    final medProv = context.read<MedicationProvider>();
    final bpProv = context.read<BloodPressureProvider>();
    final activityProv = context.read<ActivityProvider>();
    final profileProv = context.read<UserProfileProvider>();

    // Gather data
    final glucose = bloodSugarProv.entries
        .take(10)
        .map((e) => {'level': e.level, 'context': e.context, 'timestamp': e.timestamp.toIso8601String()})
        .toList();

    final meals = mealProv.meals
        .take(5)
        .map((m) => {'name': m.name, 'calories': m.totalNutrients.caloriesKcal, 'carbs': m.totalNutrients.carbsG})
        .toList();

    final meds = medProv.reminders
        .map((m) => {'id': m.id, 'name': m.name})
        .toList();

    final latestBp = bpProv.getLatestEntry();
    final bpMap = latestBp != null ? {'systolic': latestBp.systolic, 'diastolic': latestBp.diastolic} : null;

    final activity = activityProv.getTodaySummary();

    final userName = profileProv.userProfile?.name ?? 'User';

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
      userName: userName,
      force: true,
    );

    if (mounted) {
      setState(() => _isSending = false);
      // Scroll to bottom after message is added
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendQuestion(BuildContext context) async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    _questionController.clear();
    setState(() => _isSending = true);

    final recommendationProv = context.read<RecommendationProvider>();
    final bloodSugarProv = context.read<BloodSugarProvider>();
    final mealProv = context.read<MealProvider>();
    final medProv = context.read<MedicationProvider>();
    final bpProv = context.read<BloodPressureProvider>();
    final activityProv = context.read<ActivityProvider>();
    final profileProv = context.read<UserProfileProvider>();

    // Gather data
    final glucose = bloodSugarProv.entries
        .take(10)
        .map((e) => {'level': e.level, 'context': e.context, 'timestamp': e.timestamp.toIso8601String()})
        .toList();

    final meals = mealProv.meals
        .take(5)
        .map((m) => {'name': m.name, 'calories': m.totalNutrients.caloriesKcal, 'carbs': m.totalNutrients.carbsG})
        .toList();

    final meds = medProv.reminders
        .map((m) => {'id': m.id, 'name': m.name})
        .toList();

    final latestBp = bpProv.getLatestEntry();
    final bpMap = latestBp != null ? {'systolic': latestBp.systolic, 'diastolic': latestBp.diastolic} : null;

    final activity = activityProv.getTodaySummary();

    final userName = profileProv.userProfile?.name ?? 'User';

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
      userName: userName,
      followUpQuestion: question,
      force: true,
    );

    if (mounted) {
      setState(() => _isSending = false);
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showClearChatDialog(BuildContext context, RecommendationProvider recommendationProv) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('This will delete all messages in this conversation. Your health data will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              recommendationProv.clearChatHistory();
              Navigator.pop(ctx, true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: isUser ? null : Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'You' : 'AI Assistant',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isUser ? cs.onPrimary : cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? cs.onPrimary : cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: (isUser ? cs.onPrimary : cs.onSurfaceVariant).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final difference = today.difference(messageDay).inDays;

    final timeStr = DateFormat('h:mm a').format(timestamp);

    if (difference == 0) {
      return timeStr;
    } else if (difference == 1) {
      return 'Yesterday, $timeStr';
    } else {
      return DateFormat('MMM d').format(timestamp) + ', $timeStr';
    }
  }
}