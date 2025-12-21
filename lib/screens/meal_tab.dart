import 'package:diacare/models/meal.dart';
import 'package:diacare/providers/meal_provider.dart';
// AI auto-fill removed — users can enter macros manually
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:diacare/data/ethiopian_meals.dart';
import 'package:diacare/models/meal_preset.dart';
import 'package:diacare/services/preset_service.dart';
import 'package:diacare/models/nutrition_summary.dart';

class MealTab extends StatefulWidget {
  const MealTab({super.key});

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prov = context.watch<MealProvider>();

    // 1. Filter data for the selected day
    final allMeals = prov.mealsByDay.entries
        .firstWhere(
          (e) => DateUtils.isSameDay(e.key, _selectedDate),
      orElse: () => MapEntry(_selectedDate, []),
    )
        .value;

    // We use dynamic here to handle the data safely whether you used the class below or your own
    final dynamic dailyNutrition = prov.getNutritionForDay(_selectedDate);

    // 2. Group by MealType for the UI
    final breakfast = allMeals.where((m) => m.mealType == MealType.breakfast).toList();
    final lunch = allMeals.where((m) => m.mealType == MealType.lunch).toList();
    final dinner = allMeals.where((m) => m.mealType == MealType.dinner).toList();
    final snack = allMeals.where((m) => m.mealType == MealType.snack).toList();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Nutrition', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {}, // Future: Show weekly charts
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Calendar Strip
          _buildCalendarStrip(theme),

          const SizedBox(height: 16),

          // 2. Nutrition Summary Card
          _buildNutritionSummary(dailyNutrition, theme),

          const SizedBox(height: 16),

          // 3. Meal List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                if (allMeals.isEmpty)
                  _buildEmptyState(theme),

                if (breakfast.isNotEmpty) _buildSection(context, "Breakfast", breakfast, prov),
                if (lunch.isNotEmpty) _buildSection(context, "Lunch", lunch, prov),
                if (dinner.isNotEmpty) _buildSection(context, "Dinner", dinner, prov),
                if (snack.isNotEmpty) _buildSection(context, "Snacks", snack, prov),

                const SizedBox(height: 24),
                // 4. Add Food Card (at bottom of list)
                _buildAddFoodCard(context),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCalendarStrip(ThemeData theme) {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 3));
    final dates = List.generate(14, (index) => startDate.add(Duration(days: index)));
    final cs = theme.colorScheme;

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: 55,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [BoxShadow(color: cs.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
                border: isToday && !isSelected
                    ? Border.all(color: cs.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionSummary(dynamic totals, ThemeData theme) {
    final cs = theme.colorScheme;

    // Safety check for dynamic values
    final kcal = (totals?.caloriesKcal ?? 0).toDouble();
    final carbs = (totals?.carbsG ?? 0).toDouble();
    double protein = 0;
    double fat = 0;
    try {
      protein = (totals?.proteinG ?? 0).toDouble();
      fat = (totals?.fatG ?? 0).toDouble();
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Calories', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        kcal.toStringAsFixed(0),
                        style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text('kcal', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.local_fire_department_rounded, color: cs.primary.withOpacity(0.2), size: 40),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem(context, 'Carbs', '${carbs.toStringAsFixed(0)}g', Colors.blue),
              _buildMacroItem(context, 'Protein', '${protein.toStringAsFixed(0)}g', Colors.green),
              _buildMacroItem(context, 'Fat', '${fat.toStringAsFixed(0)}g', Colors.orange),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacroItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Meal> meals, MealProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        ...meals.map((meal) => _buildMealTile(context, meal, prov)),
      ],
    );
  }

  Widget _buildMealTile(BuildContext context, Meal meal, MealProvider prov) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String calText = '—';
    String carbText = '—';
    String proteinText = '—';
    String fatText = '—';
    // Accessing your model's nutrition properties
    // Check if meal has nutrition data (not zero)
    if (meal.totalNutrients.caloriesKcal > 0 || meal.totalNutrients.carbsG > 0) {
      try {
        calText = meal.totalNutrients.caloriesKcal.toStringAsFixed(0);
        carbText = meal.totalNutrients.carbsG.toStringAsFixed(0);
        proteinText = meal.totalNutrients.proteinG.toStringAsFixed(0);
        fatText = meal.totalNutrients.fatG.toStringAsFixed(0);
      } catch (e) {
        // Fallback if structure is different
      }
    }

    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: cs.errorContainer,
        child: Icon(Icons.delete, color: cs.onErrorContainer),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Food?'),
            content: Text('Remove ${meal.name} from your log?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) => prov.deleteMeal(meal.id),
      child: InkWell(
        onTap: () async {
          final grams = await _pickGrams(context, initial: meal.grams);
          if (grams != null) prov.updateMeal(meal.copyWith(grams: grams));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIconForType(meal.mealType), color: cs.onSecondaryContainer, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${meal.grams.toStringAsFixed(0)}g', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$calText kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('$carbText g carbs · $proteinText g protein · $fatText g fat', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.no_meals_outlined, size: 48, color: theme.colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No meals logged for this day.", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildAddFoodCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showQuickLogSheet(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: cs.primary.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerLow.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: cs.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              "Log Food",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(MealType type) {
    switch (type) {
      case MealType.breakfast: return Icons.wb_twilight_rounded;
      case MealType.lunch: return Icons.wb_sunny_rounded;
      case MealType.dinner: return Icons.nights_stay_rounded;
      case MealType.snack: return Icons.cookie_rounded;
    }
  }

  Future<void> _showQuickLogSheet(BuildContext context) async {
    final prov = context.read<MealProvider>();
    
    
    // ensure presets service is ready and load presets
    await PresetService().init();
    final userPresets = PresetService().getPresets();
    final allPresets = <MealPreset>[...ethiopianPresets, ...userPresets];
    MealPreset? selectedPreset;

    final nameCtrl = TextEditingController();
    final gramsCtrl = TextEditingController();
    final calsCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final injeraGramsCtrl = TextEditingController();
    bool injeraIncluded = false;
    bool injeraApplied = false; // prevents double-applying nutrients

    MealType selectedType = _defaultMealType();
    

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log Food', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Custom Chip Selector for Meal Type
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MealType.values.map((type) {
                      final isSelected = selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                          selected: isSelected,
                          onSelected: (val) => setModalState(() => selectedType = type),
                          checkmarkColor: Theme.of(ctx).colorScheme.onPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Preset selector (autocomplete)
                Autocomplete<MealPreset>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return allPresets;
                    return allPresets.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase())).toList();
                  },
                  displayStringForOption: (p) => p.name,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // keep our own controller in sync
                    controller.text = nameCtrl.text;
                    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                    controller.addListener(() => nameCtrl.text = controller.text);
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Food Name or select preset',
                        hintText: 'e.g., Injera with Wot',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.restaurant),
                      ),
                    );
                  },
                  onSelected: (MealPreset p) {
                    setModalState(() {
                      selectedPreset = p;
                      nameCtrl.text = p.name;
                      gramsCtrl.text = p.defaultGrams.toStringAsFixed(0);
                      calsCtrl.text = p.nutrition.caloriesKcal.toStringAsFixed(1);
                      carbsCtrl.text = p.nutrition.carbsG.toStringAsFixed(1);
                      proteinCtrl.text = p.nutrition.proteinG.toStringAsFixed(1);
                      fatCtrl.text = p.nutrition.fatG.toStringAsFixed(1);
                      // reset injera applied flag — user can re-apply if needed
                      injeraApplied = false;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Estimates only — adjust for recipes/portion sizes. Sources: Wikipedia, Food AI Scanner.',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog<void>(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Preset guidance'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Diabetes-aware interpretation:'),
                                  SizedBox(height: 8),
                                  Text('• Injera + legume stews are complex carbohydrates with fiber — expect slower glucose rise.'),
                                  Text('• Vegetables add fiber with minimal carbs.'),
                                  Text('• Meat stews are low-carb but higher fat; balance portions.'),
                                  SizedBox(height: 8),
                                  Text('These are estimates. Adjust for added fats (niter kibbeh), oil, or recipe variations.'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Close')),
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      onPressed: () async {
                        // Manage presets: show user presets and allow delete
                        await showModalBottomSheet<void>(
                          context: ctx,
                          builder: (mctx) {
                            final users = PresetService().getPresets();
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text('Manage presets', style: Theme.of(mctx).textTheme.headlineSmall),
                                  ),
                                  if (users.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text('No saved presets')),
                                  ...users.map((p) => ListTile(
                                        title: Text(p.name),
                                        subtitle: Text('${p.defaultGrams.toStringAsFixed(0)} g — Source: ${p.source}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () async {
                                            await PresetService().deletePreset(p.id);
                                            Navigator.pop(mctx);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset deleted')));
                                          },
                                        ),
                                      ))
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final initial = double.tryParse(gramsCtrl.text.trim()) ?? 200.0;
                    final picked = await _pickGrams(context, initial: initial);
                    if (picked != null) setModalState(() => gramsCtrl.text = picked.toStringAsFixed(0));
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: gramsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (grams)',
                        hintText: '200',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.scale),
                        suffixIcon: Icon(Icons.unfold_more),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Injera (Ethiopian bread) quick-card (tap to include/remove)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setModalState(() {
                        injeraIncluded = !injeraIncluded;
                        // default injera grams to 68g when included
                        if (injeraIncluded && (injeraGramsCtrl.text.trim().isEmpty)) {
                          injeraGramsCtrl.text = '68';
                        }

                        // auto-apply or remove immediately when toggling
                        final injeraG = double.tryParse(injeraGramsCtrl.text.trim()) ?? 0;
                        final factor = injeraG / 68.0;
                        final injeraCals = 63.0 * factor;
                        final injeraCarbs = 13.19 * factor;
                        final injeraProtein = 1.73 * factor;
                        final injeraFat = 0.462 * factor;

                        if (injeraIncluded && !injeraApplied && injeraG > 0) {
                          final baseCals = double.tryParse(calsCtrl.text.trim()) ?? 0;
                          final baseCarbs = double.tryParse(carbsCtrl.text.trim()) ?? 0;
                          final baseProtein = double.tryParse(proteinCtrl.text.trim()) ?? 0;
                          final baseFat = double.tryParse(fatCtrl.text.trim()) ?? 0;
                          calsCtrl.text = (baseCals + injeraCals).toStringAsFixed(1);
                          carbsCtrl.text = (baseCarbs + injeraCarbs).toStringAsFixed(1);
                          proteinCtrl.text = (baseProtein + injeraProtein).toStringAsFixed(1);
                          fatCtrl.text = (baseFat + injeraFat).toStringAsFixed(2);
                          injeraApplied = true;
                        } else if (!injeraIncluded && injeraApplied) {
                          // remove previously applied injera values
                          final baseCals = double.tryParse(calsCtrl.text.trim()) ?? 0;
                          final baseCarbs = double.tryParse(carbsCtrl.text.trim()) ?? 0;
                          final baseProtein = double.tryParse(proteinCtrl.text.trim()) ?? 0;
                          final baseFat = double.tryParse(fatCtrl.text.trim()) ?? 0;
                          calsCtrl.text = (baseCals - injeraCals).clamp(0, double.infinity).toStringAsFixed(1);
                          carbsCtrl.text = (baseCarbs - injeraCarbs).clamp(0, double.infinity).toStringAsFixed(1);
                          proteinCtrl.text = (baseProtein - injeraProtein).clamp(0, double.infinity).toStringAsFixed(1);
                          fatCtrl.text = (baseFat - injeraFat).clamp(0, double.infinity).toStringAsFixed(2);
                          injeraApplied = false;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(ctx).colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bakery_dining, color: Theme.of(ctx).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Tap to include Injera (Ethiopian bread)')),
                          if (injeraIncluded) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Included', style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (injeraIncluded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: injeraGramsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Injera amount (grams)',
                            hintText: 'e.g. 68',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            prefixIcon: const Icon(Icons.bakery_dining),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(builder: (_) {
                          final injeraG = double.tryParse(injeraGramsCtrl.text.trim()) ?? 68.0;
                          final factor = injeraG / 68.0;
                          final injeraCals = 63.0 * factor;
                          final injeraCarbs = 13.19 * factor;
                          final injeraProtein = 1.73 * factor;
                          final injeraFat = 0.462 * factor;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Injera adds: ${injeraCals.toStringAsFixed(0)} kcal · ${injeraCarbs.toStringAsFixed(1)} g carbs · ${injeraProtein.toStringAsFixed(1)} g protein · ${injeraFat.toStringAsFixed(2)} g fat'),
                              ),
                              TextButton(
                                onPressed: injeraApplied
                                    ? null
                                    : () {
                                        setModalState(() {
                                          final baseCals = double.tryParse(calsCtrl.text.trim()) ?? 0;
                                          final baseCarbs = double.tryParse(carbsCtrl.text.trim()) ?? 0;
                                          final baseProtein = double.tryParse(proteinCtrl.text.trim()) ?? 0;
                                          final baseFat = double.tryParse(fatCtrl.text.trim()) ?? 0;
                                          calsCtrl.text = (baseCals + injeraCals).toStringAsFixed(1);
                                          carbsCtrl.text = (baseCarbs + injeraCarbs).toStringAsFixed(1);
                                          proteinCtrl.text = (baseProtein + injeraProtein).toStringAsFixed(1);
                                          fatCtrl.text = (baseFat + injeraFat).toStringAsFixed(2);
                                          injeraApplied = true;
                                        });
                                      },
                                child: Text(injeraApplied ? 'Applied' : 'Apply'),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Manual Nutrition Inputs
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: calsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Calories (kcal)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.local_fire_department),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: carbsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.grass),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Protein & Fat inputs
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: proteinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.fitness_center),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: fatCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          prefixIcon: const Icon(Icons.oil_barrel),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final pname = nameCtrl.text.trim();
                            final pgrams = double.tryParse(gramsCtrl.text.trim()) ?? 100;
                            final pcals = double.tryParse(calsCtrl.text.trim()) ?? 0;
                            final pcarbs = double.tryParse(carbsCtrl.text.trim()) ?? 0;
                            final pprotein = double.tryParse(proteinCtrl.text.trim()) ?? 0;
                            final pfat = double.tryParse(fatCtrl.text.trim()) ?? 0;
                            if (pname.isEmpty) return;
                            final preset = MealPreset(
                              id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                              name: pname,
                              defaultGrams: pgrams,
                              nutrition: NutritionSummary(caloriesKcal: pcals, carbsG: pcarbs, proteinG: pprotein, fatG: pfat),
                              notes: 'User saved preset',
                              source: 'User',
                            );
                            await PresetService().savePreset(preset);
                            setModalState(() {
                              allPresets.add(preset);
                              selectedPreset = preset;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset saved')));
                          },
                          child: const Text('Save as preset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final grams = double.tryParse(gramsCtrl.text.trim());
                      double cals = double.tryParse(calsCtrl.text.trim()) ?? 0;
                      double carbs = double.tryParse(carbsCtrl.text.trim()) ?? 0;
                      double protein = double.tryParse(proteinCtrl.text.trim()) ?? 0;
                      double fat = double.tryParse(fatCtrl.text.trim()) ?? 0;

                      if (name.isEmpty || grams == null || grams <= 0) return;

                      // If user indicated Injera is included and/or a preset was selected, build a full NutritionSummary including micros.
                      final Map<String, double> micros = {};
                      double fiber = 0.0;

                      // If a preset was selected, include its micros scaled to the chosen grams
                      if (selectedPreset != null) {
                        final presetFactor = grams / (selectedPreset!.defaultGrams == 0 ? grams : selectedPreset!.defaultGrams);
                        // add preset micros (if any)
                        for (final e in selectedPreset!.nutrition.micros.entries) {
                          micros[e.key] = (micros[e.key] ?? 0) + e.value * presetFactor;
                        }
                        fiber += selectedPreset!.nutrition.fiberG * presetFactor;
                        // If preset provides macros, prefer using scaled preset macros unless user overwrote via fields — we keep user-edited controllers already
                      }

                      // Injera micronutrient map per 68g (from provided spreadsheet)
                      const Map<String, double> injeraMicrosPer68 = {
                        'Vitamin A, RAE': 0.00,
                        'Carotene, alpha': 0.00,
                        'Carotene, beta': 0.00,
                        'Lutein + zeaxanthin': 33.32,
                        'Thiamin': 0.095,
                        'Riboflavin': 0.047,
                        'Niacin': 0.812,
                        'Vitamin B6': 0.035,
                        'Vitamin B12': 0.00,
                        'Folate, DFE': 19.72,
                        'Vitamin C': 0.0,
                        'Vitamin E': 0.05,
                        'Vitamin K': 1.2,
                        'Choline': 8.9,
                        'Calcium': 7.48,
                        'Copper': 0.10,
                        'Iron': 0.67,
                        'Magnesium': 29.24,
                        'Phosphorus': 51.00,
                        'Potassium': 69.36,
                        'Selenium': 2.72,
                        'Sodium': 153.68,
                        'Zinc': 0.35,
                        'Sugars': 0.70,
                        'Water': 51.86,
                      };

                      if (injeraIncluded) {
                        final injeraG = double.tryParse(injeraGramsCtrl.text.trim()) ?? 0;
                        if (injeraG > 0) {
                          final factor = injeraG / 68.0;
                          // add injera micros
                          for (final e in injeraMicrosPer68.entries) {
                            micros[e.key] = (micros[e.key] ?? 0) + e.value * factor;
                          }
                          // add injera fiber if present in preset or dataset (use fiber ~1.90 g per 68g -> from spreadsheet)
                          fiber += 1.90 * (injeraG / 68.0);
                          // also add basic macros from injera to totals (if not already applied)
                          if (!injeraApplied) {
                            final per68_cal = 63.0;
                            final per68_carbs = 13.19;
                            final per68_protein = 1.73;
                            final per68_fat = 0.462;
                            final f = factor;
                            cals += per68_cal * f;
                            carbs += per68_carbs * f;
                            protein += per68_protein * f;
                            fat += per68_fat * f;
                          }
                        }
                      }

                      final nutritionToSave = NutritionSummary(
                        caloriesKcal: cals,
                        carbsG: carbs,
                        proteinG: protein,
                        fatG: fat,
                        fiberG: fiber,
                        micros: micros,
                      );

                      // Save meal with full nutrition summary
                      prov.addMeal(
                        name: name,
                        grams: grams,
                        mealType: selectedType,
                        nutrition: nutritionToSave,
                      );
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Add Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MealType _defaultMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 16) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  Future<double?> _pickGrams(BuildContext context, {required double initial}) async {
    const int min = 1;
    const int max = 2000;
    final initialInt = initial.clamp(min.toDouble(), max.toDouble()).toInt();
    final controller = FixedExtentScrollController(initialItem: (initialInt - min).clamp(0, max - min));

    int selected = initialInt;
    return showModalBottomSheet<double>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SizedBox(
        height: 260,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select grams', style: Theme.of(ctx).textTheme.titleMedium),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: controller,
                itemExtent: 36,
                magnification: 1.05,
                useMagnifier: true,
                onSelectedItemChanged: (idx) => selected = min + idx,
                children: List<Widget>.generate(max - min + 1, (index) {
                  final val = min + index;
                  return Center(
                    child: Text(
                      val.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: val == selected ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected.toDouble()),
                  child: const Text('Set'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NutritionInfo is imported from meal_provider.dart to avoid duplication