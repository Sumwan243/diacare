import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../models/meal_log_item.dart';
import '../models/food_nutrients.dart';
import '../providers/meal_provider.dart';
import '../services/usda_nutrition_service.dart';

class MealTab extends StatefulWidget {
  const MealTab({super.key});

  @override
  State<MealTab> createState() => _MealTabState();
}

class _MealTabState extends State<MealTab> {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MealProvider>();

    // Build "meals by day" from provider logs.
    final groupedByDay = groupBy(
      prov.allLogs,
          (MealLogItem e) => DateUtils.dateOnly(e.timestamp),
    );

    final days = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMenu(context),
        label: const Text('Log Food'),
        icon: const Icon(Icons.add),
      ),
      body: days.isEmpty
          ? const Center(child: Text('No meals logged yet.'))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final date = days[i];
          final meals = groupedByDay[date]!..sort(
                (a, b) => a.timestamp.compareTo(b.timestamp),
          );
          final total = prov.totalsForDate(date);

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
                          '${meal.gramsEaten.toStringAsFixed(0)}g • ${meal.mealType.name}',
                        ),
                        trailing: Text(
                          '${meal.totals.caloriesKcal.toStringAsFixed(0)} kcal',
                        ),
                        onTap: () async {
                          final newGrams =
                          await _pickGrams(context, initial: meal.gramsEaten);
                          if (newGrams == null) return;
                          await prov.updateLog(meal.copyWith(gramsEaten: newGrams));
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
                            await prov.deleteLog(meal.id);
                          }
                        },
                      ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${total.caloriesKcal.toStringAsFixed(0)} kcal • '
                                '${total.carbsG.toStringAsFixed(0)}g carbs',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Ethiopian dishes (templates)'),
                subtitle: const Text('Tier B: computed from ingredients (USDA)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickEthiopianDish(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search ingredients (USDA)'),
                subtitle: const Text('Tier B: pick an ingredient and log grams'),
                onTap: () {
                  Navigator.pop(ctx);
                  _searchUsdaIngredient(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Custom foods'),
                subtitle: const Text('Tier C: create your own items'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCustomFood(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  MealType _defaultMealType() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 16) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }

  Future<void> _pickEthiopianDish(BuildContext context) async {
    final prov = context.read<MealProvider>();
    final mealType = await _pickMealType(context, initial: _defaultMealType());
    if (mealType == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final templates = prov.ethiopianTemplates;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Ethiopian dishes', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...templates.map(
                    (t) => Card(
                  child: ListTile(
                    title: Text(t.name),
                    subtitle: Text(t.vegan ? 'Vegan template' : 'Template'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final grams = await _pickGrams(context, initial: 250);
                      if (grams == null) return;

                      try {
                        await prov.logDishTemplate(
                          template: t,
                          mealType: mealType,
                          timestamp: DateTime.now(),
                          gramsEaten: grams,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not compute dish: $e')),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _searchUsdaIngredient(BuildContext context) async {
    final prov = context.read<MealProvider>();
    final mealType = await _pickMealType(context, initial: _defaultMealType());
    if (mealType == null) return;

    final ctrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Search USDA ingredients',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                        labelText: 'Search (e.g., red lentils, cabbage, onion)',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<UsdaSearchResult>>(
                      future: ctrl.text.trim().isEmpty
                          ? Future.value(const [])
                          : prov.searchUsda(ctrl.text.trim()),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'USDA error: ${snap.error}\n'
                                  'Tip: run with --dart-define=USDA_API_KEY=YOUR_KEY',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          );
                        }

                        final results = snap.data ?? const [];
                        if (results.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Type a query and press Enter.'),
                          );
                        }

                        return Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final r = results[i];
                              return ListTile(
                                title: Text(r.description),
                                subtitle: Text(r.dataType ?? ''),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final grams = await _pickGrams(context, initial: 100);
                                  if (grams == null) return;

                                  try {
                                    await prov.logUsdaFood(
                                      fdcId: r.fdcId,
                                      name: r.description,
                                      mealType: mealType,
                                      timestamp: DateTime.now(),
                                      gramsEaten: grams,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not log: $e')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    ctrl.dispose();
  }

  Future<void> _pickCustomFood(BuildContext context) async {
    final prov = context.read<MealProvider>();
    final mealType = await _pickMealType(context, initial: _defaultMealType());
    if (mealType == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final foods = prov.customFoods;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Custom foods',
                          style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _addCustomFoodDialog(context);
                        if (context.mounted) _pickCustomFood(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (foods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No custom foods yet. Tap “New”.'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: foods.length,
                      itemBuilder: (ctx, i) {
                        final f = foods[i];
                        return Card(
                          child: ListTile(
                            title: Text(f.name),
                            subtitle: Text(
                              '${f.per100g.caloriesKcal.toStringAsFixed(0)} kcal/100g • '
                                  '${f.per100g.carbsG.toStringAsFixed(0)}g carbs/100g',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await prov.deleteCustomFood(f.id);
                              },
                            ),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final grams = await _pickGrams(context, initial: 150);
                              if (grams == null) return;
                              await prov.logCustomFood(
                                food: f,
                                mealType: mealType,
                                timestamp: DateTime.now(),
                                gramsEaten: grams,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addCustomFoodDialog(BuildContext context) async {
    final prov = context.read<MealProvider>();

    final nameCtrl = TextEditingController();
    final kcalCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fiberCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add custom food (per 100g)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: kcalCtrl,
                  decoration: const InputDecoration(labelText: 'Calories/100g'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: carbsCtrl,
                  decoration: const InputDecoration(labelText: 'Carbs/100g'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: fiberCtrl,
                  decoration: const InputDecoration(labelText: 'Fiber/100g'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: proteinCtrl,
                  decoration: const InputDecoration(labelText: 'Protein/100g'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: fatCtrl,
                  decoration: const InputDecoration(labelText: 'Fat/100g'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                double p(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

                await prov.addCustomFood(
                  name: name,
                  per100g: FoodNutrients(
                    caloriesKcal: p(kcalCtrl),
                    carbsG: p(carbsCtrl),
                    fiberG: p(fiberCtrl),
                    proteinG: p(proteinCtrl),
                    fatG: p(fatCtrl),
                  ),
                );

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    kcalCtrl.dispose();
    carbsCtrl.dispose();
    fiberCtrl.dispose();
    proteinCtrl.dispose();
    fatCtrl.dispose();
  }

  Future<MealType?> _pickMealType(BuildContext context,
      {required MealType initial}) async {
    return showDialog<MealType>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select meal type'),
          children: MealType.values
              .map(
                (t) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t.name[0].toUpperCase() + t.name.substring(1)),
            ),
          )
              .toList(),
        );
      },
    );
  }

  Future<double?> _pickGrams(BuildContext context, {required double initial}) async {
    final ctrl = TextEditingController(text: initial.toStringAsFixed(0));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Enter grams eaten'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Grams'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      final v = double.tryParse(ctrl.text.trim());
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }
}