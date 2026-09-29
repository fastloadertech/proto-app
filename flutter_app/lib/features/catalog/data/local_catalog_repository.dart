import 'package:flutter/material.dart';

import '../domain/product.dart';

/// A local, deterministic catalog for the customer experience.
///
/// Prices, ratings, and nutritional information are illustrative demo data.
/// The domain model can be reused by a remote repository when a backend exists.
class LocalCatalogRepository {
  LocalCatalogRepository._();

  static const categories = <ProductCategory>[
    ProductCategory(
      id: 'protein',
      title: 'Protein',
      subtitle: 'Build & recover',
      icon: Icons.fitness_center_rounded,
      accentColor: Color(0xFFB9ED54),
    ),
    ProductCategory(
      id: 'snacks',
      title: 'Smart snacks',
      subtitle: 'Better between meals',
      icon: Icons.cookie_outlined,
      accentColor: Color(0xFFF1AB65),
    ),
    ProductCategory(
      id: 'creatine',
      title: 'Creatine',
      subtitle: 'Power every rep',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFF87D5DC),
    ),
    ProductCategory(
      id: 'preworkout',
      title: 'Pre-workout',
      subtitle: 'Find your focus',
      icon: Icons.local_fire_department_outlined,
      accentColor: Color(0xFFAB9DEF),
    ),
    ProductCategory(
      id: 'essentials',
      title: 'Essentials',
      subtitle: 'Your daily baseline',
      icon: Icons.spa_outlined,
      accentColor: Color(0xFF74C7A4),
    ),
    ProductCategory(
      id: 'hydration',
      title: 'Hydration',
      subtitle: 'Refill & reset',
      icon: Icons.water_drop_outlined,
      accentColor: Color(0xFF7BBEF3),
    ),
  ];

  static const products = <Product>[
    Product(
      id: 'whey-isolate',
      name: 'Whey Isolate',
      brand: 'PROTO FUEL',
      categoryId: 'protein',
      price: 2499,
      originalPrice: 2999,
      weightLabel: '1 kg',
      subtitle: '27 g protein · Smooth, clean recovery',
      description:
          'A smooth whey isolate for the work you put in. Each serving delivers '
          '27 g of protein in a light, easy-mixing shake. Add one scoop to '
          '250 ml of water or milk and shake well. Contains milk.',
      proteinGrams: 27,
      servings: 30,
      rating: 4.9,
      reviewCount: 248,
      badge: 'BESTSELLER',
      accentColor: Color(0xFFB9ED54),
      form: ProductForm.tub,
      flavors: ['Chocolate', 'Vanilla', 'Unflavoured'],
    ),
    Product(
      id: 'everyday-whey',
      name: 'Everyday Whey',
      brand: 'PROTO FUEL',
      categoryId: 'protein',
      price: 1799,
      originalPrice: 2299,
      weightLabel: '1 kg',
      subtitle: '24 g protein · Your everyday training partner',
      description:
          'Rich, creamy whey concentrate made for your daily routine. Mix one '
          'scoop with 250 ml of water or milk after training, or blend into '
          'your breakfast smoothie. Contains milk.',
      proteinGrams: 24,
      servings: 30,
      rating: 4.8,
      reviewCount: 196,
      badge: 'DAILY FAVOURITE',
      accentColor: Color(0xFFF1AB65),
      form: ProductForm.tub,
      flavors: ['Dark chocolate', 'Cold coffee', 'Vanilla'],
    ),
    Product(
      id: 'plant-protein',
      name: 'Plant Protein Blend',
      brand: 'PROTO FUEL',
      categoryId: 'protein',
      price: 1499,
      originalPrice: 1799,
      weightLabel: '750 g',
      subtitle: '24 g protein · Pea & brown rice blend',
      description:
          'A balanced blend of pea and brown rice protein with a gentle cocoa '
          'finish. Made without dairy. Shake one scoop with 300 ml of water or '
          'your favourite plant milk.',
      proteinGrams: 24,
      servings: 25,
      rating: 4.7,
      reviewCount: 84,
      badge: 'PLANT POWERED',
      accentColor: Color(0xFF74C7A4),
      form: ProductForm.pouch,
      flavors: ['Cacao', 'Vanilla'],
    ),
    Product(
      id: 'crunch-protein-bar',
      name: 'Crunch Protein Bar',
      brand: 'PROTO KITCHEN',
      categoryId: 'snacks',
      price: 99,
      originalPrice: 129,
      weightLabel: '60 g',
      subtitle: '20 g protein · Big crunch, zero fuss',
      description:
          'A crisp, chocolate-coated protein bar for busy days, gym bags, and '
          'the space between meals. Individually wrapped and ready when you '
          'are. Contains milk, peanuts, and soy.',
      proteinGrams: 20,
      servings: 1,
      rating: 4.8,
      reviewCount: 324,
      badge: '20 G PROTEIN',
      accentColor: Color(0xFFF1AB65),
      form: ProductForm.bar,
      flavors: ['Chocolate peanut', 'Cookies & cream'],
    ),
    Product(
      id: 'protein-bites',
      name: 'Peanut Butter Bites',
      brand: 'PROTO KITCHEN',
      categoryId: 'snacks',
      price: 299,
      originalPrice: 349,
      weightLabel: '150 g',
      subtitle: '14 g protein · A little bite of better',
      description:
          'Soft peanut butter bites with oats, cocoa, and a satisfying crunch. '
          'A resealable pouch makes these an easy desk or post-training snack. '
          'Protein shown is per 30 g serving. Contains peanuts and milk.',
      proteinGrams: 14,
      servings: 5,
      rating: 4.6,
      reviewCount: 72,
      badge: 'SNACK SMART',
      accentColor: Color(0xFFECC15C),
      form: ProductForm.pouch,
      flavors: ['Peanut cacao', 'Salted caramel'],
    ),
    Product(
      id: 'creatine-monohydrate',
      name: 'Creatine Monohydrate',
      brand: 'PROTO LABS',
      categoryId: 'creatine',
      price: 699,
      originalPrice: 899,
      weightLabel: '250 g',
      subtitle: '3 g creatine · Pure, simple performance',
      description:
          'Single-ingredient, micronized creatine monohydrate with no added '
          'flavours or fillers. Stir one 3 g serving into water or your usual '
          'shake. A simple addition to a consistent training routine.',
      proteinGrams: 0,
      servings: 83,
      rating: 4.9,
      reviewCount: 215,
      badge: 'PURE PERFORMANCE',
      accentColor: Color(0xFF87D5DC),
      form: ProductForm.tub,
      flavors: ['Unflavoured'],
    ),
    Product(
      id: 'ignite-preworkout',
      name: 'Ignite Pre-workout',
      brand: 'PROTO LABS',
      categoryId: 'preworkout',
      price: 999,
      originalPrice: 1299,
      weightLabel: '200 g',
      subtitle: '150 mg caffeine · Switch into training mode',
      description:
          'A bright, refreshing pre-workout with caffeine and citrulline. '
          'Mix one serving with 250 ml of cold water before training. Each '
          'serving contains 150 mg caffeine; avoid taking near bedtime.',
      proteinGrams: 0,
      servings: 30,
      rating: 4.7,
      reviewCount: 119,
      badge: 'WORKOUT READY',
      accentColor: Color(0xFFF18F7D),
      form: ProductForm.tub,
      flavors: ['Watermelon', 'Orange rush'],
    ),
    Product(
      id: 'focus-preworkout',
      name: 'Focus Pre-workout',
      brand: 'PROTO LABS',
      categoryId: 'preworkout',
      price: 1299,
      originalPrice: 1599,
      weightLabel: '250 g',
      subtitle: '100 mg caffeine · A focused start',
      description:
          'A clean-tasting pre-workout with 100 mg caffeine per serving. '
          'Designed for the days you want a measured lift before your session. '
          'Mix with 250 ml of water. Contains caffeine.',
      proteinGrams: 0,
      servings: 30,
      rating: 4.8,
      reviewCount: 91,
      badge: 'FIND YOUR FOCUS',
      accentColor: Color(0xFFAB9DEF),
      form: ProductForm.tub,
      flavors: ['Blue raspberry', 'Lemon lime'],
    ),
    Product(
      id: 'daily-greens',
      name: 'Daily Greens',
      brand: 'PROTO DAILY',
      categoryId: 'essentials',
      price: 899,
      originalPrice: 1099,
      weightLabel: '200 g',
      subtitle: '30 servings · Make a little room for greens',
      description:
          'A daily greens blend with spinach, moringa, and a light citrus '
          'flavour. Mix one scoop into 250 ml of cold water or a smoothie. '
          'An easy companion to a varied, balanced diet.',
      proteinGrams: 3,
      servings: 30,
      rating: 4.6,
      reviewCount: 68,
      badge: 'DAILY ESSENTIAL',
      accentColor: Color(0xFF74C7A4),
      form: ProductForm.pouch,
      flavors: ['Citrus greens', 'Apple mint'],
    ),
    Product(
      id: 'omega-3',
      name: 'Omega 3 Softgels',
      brand: 'PROTO DAILY',
      categoryId: 'essentials',
      price: 499,
      originalPrice: 649,
      weightLabel: '60 softgels',
      subtitle: 'Fish oil · A simple daily essential',
      description:
          'Easy-to-take fish oil softgels for your daily routine. The pack '
          'contains 60 softgels. Follow the serving guidance on the pack and '
          'take with a meal. Contains fish.',
      proteinGrams: 0,
      servings: 30,
      rating: 4.8,
      reviewCount: 142,
      badge: 'EVERYDAY WELLNESS',
      accentColor: Color(0xFFECC15C),
      form: ProductForm.bottle,
      flavors: ['Original'],
    ),
    Product(
      id: 'electrolyte-mix',
      name: 'Electrolyte Mix',
      brand: 'PROTO HYDRATE',
      categoryId: 'hydration',
      price: 599,
      originalPrice: 749,
      weightLabel: '15 sachets',
      subtitle: 'On-the-go electrolytes · Just add water',
      description:
          'Pocket-ready electrolyte sachets with sodium, potassium, and '
          'magnesium. Mix one sachet with 500 ml of cold water after a sweaty '
          'session, or whenever your day calls for a refresh.',
      proteinGrams: 0,
      servings: 15,
      rating: 4.7,
      reviewCount: 103,
      badge: 'REFILL & RESET',
      accentColor: Color(0xFF7BBEF3),
      form: ProductForm.pouch,
      flavors: ['Lemon lime', 'Mixed berry'],
    ),
    Product(
      id: 'hydration-water',
      name: 'Hydration Water',
      brand: 'PROTO HYDRATE',
      categoryId: 'hydration',
      price: 89,
      originalPrice: 109,
      weightLabel: '500 ml',
      subtitle: 'Electrolyte water · Open, sip, go',
      description:
          'A refreshing, ready-to-drink electrolyte water with a light '
          'lemon-lime finish. Keep it chilled for your next session or take '
          'it with you for an easy refresh on the move.',
      proteinGrams: 0,
      servings: 1,
      rating: 4.8,
      reviewCount: 186,
      badge: 'READY TO REFRESH',
      accentColor: Color(0xFF7BBEF3),
      form: ProductForm.bottle,
      flavors: ['Lemon lime', 'Berry'],
    ),
  ];

  static List<Product> get featuredProducts => List<Product>.unmodifiable([
    products[0],
    products[3],
    products[5],
    products[6],
    products[10],
    products[8],
  ]);

  static Product? getById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  static List<Product> get popularProducts {
    final ranked = List<Product>.of(products)
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return List.unmodifiable(ranked.take(4));
  }

  static List<Product> byCategory(String categoryId) {
    if (categoryId == 'all' || categoryId.isEmpty) return products;
    return List<Product>.unmodifiable(
      products.where((product) => product.categoryId == categoryId),
    );
  }

  static List<Product> search(String query) {
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    if (query.trim().isEmpty) return products;
    return List<Product>.unmodifiable(
      products.where((product) {
        final text = [
          product.name,
          product.brand,
          product.subtitle,
          product.categoryId,
          ...product.flavors,
        ].join(' ').toLowerCase();
        return terms.every(text.contains);
      }),
    );
  }
}
