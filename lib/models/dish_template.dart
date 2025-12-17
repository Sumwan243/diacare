class DishTemplate {
  final String id;
  final String name;
  final bool vegan;

  /// Cooked yield (grams). Include water weight here for realistic per-100g results.
  final double yieldGrams;

  final List<TemplateIngredient> ingredients;

  const DishTemplate({
    required this.id,
    required this.name,
    required this.vegan,
    required this.yieldGrams,
    required this.ingredients,
  });
}

class TemplateIngredient {
  /// USDA search query (e.g., "red lentils dry", "onion raw").
  /// Special-case: "__water__" will be treated as 0 nutrients.
  final String query;
  final double grams;

  const TemplateIngredient({
    required this.query,
    required this.grams,
  });
}

/// Starter Ethiopian vegan templates (tweak grams/yields anytime).
const List<DishTemplate> defaultEthiopianVeganTemplates = [
  DishTemplate(
    id: 'misir_wot',
    name: 'Misir Wot (Red Lentil Stew)',
    vegan: true,
    yieldGrams: 1400, // includes water
    ingredients: [
      TemplateIngredient(query: 'red lentils dry', grams: 250),
      TemplateIngredient(query: 'onion raw', grams: 250),
      TemplateIngredient(query: 'tomato paste canned', grams: 60),
      TemplateIngredient(query: 'garlic raw', grams: 12),
      TemplateIngredient(query: 'vegetable oil', grams: 30),
      TemplateIngredient(query: '__water__', grams: 798),
    ],
  ),
  DishTemplate(
    id: 'shiro_wot',
    name: 'Shiro Wot (Chickpea Stew)',
    vegan: true,
    yieldGrams: 1400,
    ingredients: [
      TemplateIngredient(query: 'chickpea flour', grams: 220),
      TemplateIngredient(query: 'onion raw', grams: 250),
      TemplateIngredient(query: 'tomato paste canned', grams: 50),
      TemplateIngredient(query: 'garlic raw', grams: 10),
      TemplateIngredient(query: 'vegetable oil', grams: 25),
      TemplateIngredient(query: '__water__', grams: 845),
    ],
  ),
  DishTemplate(
    id: 'gomen',
    name: 'Gomen (Collard Greens)',
    vegan: true,
    yieldGrams: 900,
    ingredients: [
      TemplateIngredient(query: 'collards cooked', grams: 500),
      TemplateIngredient(query: 'onion raw', grams: 120),
      TemplateIngredient(query: 'garlic raw', grams: 8),
      TemplateIngredient(query: 'vegetable oil', grams: 18),
      TemplateIngredient(query: '__water__', grams: 254),
    ],
  ),
  DishTemplate(
    id: 'atekilt_wot',
    name: 'Atekilt Wot (Cabbage + Potato + Carrot)',
    vegan: true,
    yieldGrams: 1400,
    ingredients: [
      TemplateIngredient(query: 'cabbage raw', grams: 500),
      TemplateIngredient(query: 'potato raw', grams: 350),
      TemplateIngredient(query: 'carrot raw', grams: 180),
      TemplateIngredient(query: 'onion raw', grams: 150),
      TemplateIngredient(query: 'vegetable oil', grams: 20),
      TemplateIngredient(query: '__water__', grams: 200),
    ],
  ),
];