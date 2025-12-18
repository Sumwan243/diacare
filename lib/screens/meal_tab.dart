import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meal.dart';
import '../providers/meal_provider.dart';

class MealTab extends StatefulWidget {
  const MealTab({super.key});

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MealProvider>();
    final mealsByDay = prov.mealsByDay;

    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _quickLog(context),
        label: const Text('Log Food'),
        icon: const Icon(Icons.add),
      ),
      body: mealsByDay.isEmpty
          ? const Center(child: Text('No meals logged yet.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: mealsByDay.length,
              itemBuilder: (ctx, i) {
                final entry = mealsByDay.entries.elementAt(i);
                final date = entry.key;
                final meals = entry.value;
                final total = prov.getNutritionForDay(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.yMMMEd().format(date),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          for (final meal in meals)
                            ListTile(
                              title: Text(
                                meal.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${meal.grams.toStringAsFixed(0)}g • ${meal.mealType.name}',
                              ),
                              trailing: _EstimateTrailing(meal: meal),
                              onTap: () async {
                                final grams = await _pickGrams(context, initial: meal.grams);
                                if (grams == null) return;
                                await prov.updateMeal(meal.copyWith(grams: grams));
                              },
                              onLongPress: () async {
                                final delete = await showDialog<bool>(
                                  context: context,
                                  builder: (dctx) => AlertDialog(
                                    title: const Text('Delete entry?'),
                                    content: Text('Delete ${meal.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(dctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (delete == true) {
                                  await prov.deleteMeal(meal.id);
                                }
                              },
                            ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${total.caloriesKcal.toStringAsFixed(0)} kcal • ' 
                                  '${total.carbsG.toStringAsFixed(0)}g carbs',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _quickLog(BuildContext context) async {
    final prov = context.read<MealProvider>();

    final nameCtrl = TextEditingController();
    final gramsCtrl = TextEditingController();
    MealType type = _defaultMealType();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Quick log', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Food (e.g., Misir wot)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: gramsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Grams eaten',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<MealType>(
                      initialValue: type,
                      items: MealType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                              ))
                          .toList(),
                      onChanged: (v) => setModalState(() => type = v ?? type),
                      decoration: const InputDecoration(
                        labelText: 'Meal type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final grams = double.tryParse(gramsCtrl.text.trim());

                          if (name.isEmpty || grams == null || grams <= 0) return;

                          await prov.addMeal(
                            name: name,
                            grams: grams,
                            mealType: type,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nutrition shown is an estimate.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    nameCtrl.dispose();
    gramsCtrl.dispose();
  }

  MealType _defaultMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 16) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  Future<double?> _pickGrams(BuildContext context, {required double initial}) async {
    final ctrl = TextEditingController(text: initial.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit grams'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Grams'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok == true) {
      final v = double.tryParse(ctrl.text.trim());
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }
}

class _EstimateTrailing extends StatelessWidget {
  final Meal meal;
  const _EstimateTrailing({required this.meal});

  @override
  Widget build(BuildContext context) {
    final styleMain = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );

    final styleSub = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey[600],
        );

    if (meal.isEstimating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('— kcal', style: styleMain?.copyWith(color: Colors.grey[500])),
          Text('Estimating', style: styleSub),
        ],
      );
    }

    if (meal.estimateError != null && !meal.hasEstimate) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('— kcal', style: styleMain?.copyWith(color: Colors.grey[500])),
          Text('No estimate', style: styleSub),
        ],
      );
    }

    final totals = meal.totalNutrients;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${totals.caloriesKcal.toStringAsFixed(0)} kcal', style: styleMain),
        Text('${totals.carbsG.toStringAsFixed(0)}g carbs • Est.', style: styleSub),
      ],
    );
  }
}
