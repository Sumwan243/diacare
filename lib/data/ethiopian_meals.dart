import 'package:diacare/models/meal_preset.dart';
import 'package:diacare/models/nutrition_summary.dart';

const ethiopianPresets = <MealPreset>[
  MealPreset(
    id: 'injera_100',
    name: 'Injera (100 g cooked)',
    defaultGrams: 100,
    nutrition: NutritionSummary(caloriesKcal: 110, carbsG: 18.0, proteinG: 3.5, fatG: 0.8, fiberG: 2.5),
    notes: 'Teff-based flatbread; slow-releasing carbs.',
    source: 'Wikipedia',
  ),
  MealPreset(
    id: 'misir_wot',
    name: 'Misir Wot (red lentil stew) - 1 portion',
    defaultGrams: 200,
    nutrition: NutritionSummary(caloriesKcal: 180, carbsG: 25.0, proteinG: 10.0, fatG: 3.0, fiberG: 8.0),
    notes: 'Lentil-based stew, high in plant protein and fiber.',
    source: 'Food AI Scanner',
  ),
  MealPreset(
    id: 'gomen',
    name: 'Gomen (greens) - 100 g cooked',
    defaultGrams: 100,
    nutrition: NutritionSummary(caloriesKcal: 60, carbsG: 10.0, proteinG: 3.0, fatG: 1.0, fiberG: 5.0),
    notes: 'Collard/garden greens — vitamin-rich, low calories.',
    source: 'Food AI Scanner',
  ),
  MealPreset(
    id: 'shiro_wot',
    name: 'Shiro Wot (chickpea stew) - 1 cup',
    defaultGrams: 240,
    nutrition: NutritionSummary(caloriesKcal: 250, carbsG: 30.0, proteinG: 10.0, fatG: 12.0, fiberG: 6.0),
    notes: 'Chickpea/pea flour stew, rich in protein and fiber.',
    source: 'Default estimate',
  ),
  MealPreset(
    id: 'kik_alicha',
    name: 'Kik Alicha (split pea stew) - 1 portion',
    defaultGrams: 200,
    nutrition: NutritionSummary(caloriesKcal: 120, carbsG: 20.0, proteinG: 6.0, fatG: 2.0, fiberG: 6.0),
    notes: 'Yellow split pea stew; milder and lower fat.',
    source: 'Scribd',
  ),
  MealPreset(
    id: 'atakilt_wat',
    name: 'Atakilt Wat (veg stew) - 1 cup',
    defaultGrams: 140,
    nutrition: NutritionSummary(caloriesKcal: 170, carbsG: 30.0, proteinG: 4.0, fatG: 3.0, fiberG: 6.0),
    notes: 'Cabbage, carrot, potato mix; fiber-rich.',
    source: 'Estimate',
  ),
  MealPreset(
    id: 'doro_wot',
    name: 'Doro Wat (chicken stew) - 1 portion',
    defaultGrams: 300,
    nutrition: NutritionSummary(caloriesKcal: 380, carbsG: 8.0, proteinG: 30.0, fatG: 18.0, fiberG: 1.0),
    notes: 'Hearty protein-rich stew; higher fat content.',
    source: 'MeatChefTools',
  ),
];
