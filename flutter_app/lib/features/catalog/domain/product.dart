import 'package:flutter/material.dart';

enum ProductForm { tub, pouch, bar, bottle }

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.price,
    required this.originalPrice,
    required this.weightLabel,
    required this.subtitle,
    required this.description,
    required this.proteinGrams,
    required this.servings,
    required this.rating,
    required this.reviewCount,
    required this.badge,
    required this.accentColor,
    required this.form,
    required this.flavors,
    this.isAvailable = true,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String brand;
  final String categoryId;
  final double price;
  final double originalPrice;
  final String weightLabel;
  final String subtitle;
  final String description;
  final int proteinGrams;
  final int servings;
  final double rating;
  final int reviewCount;
  final String badge;
  final Color accentColor;
  final ProductForm form;
  final List<String> flavors;
  final String? imageUrl;

  /// Local catalog availability until live inventory is connected.
  final bool isAvailable;

  Product withAvailability(bool available) => Product(
    id: id,
    name: name,
    brand: brand,
    categoryId: categoryId,
    price: price,
    originalPrice: originalPrice,
    weightLabel: weightLabel,
    subtitle: subtitle,
    description: description,
    proteinGrams: proteinGrams,
    servings: servings,
    rating: rating,
    reviewCount: reviewCount,
    badge: badge,
    accentColor: accentColor,
    form: form,
    flavors: flavors,
    isAvailable: available,
    imageUrl: imageUrl,
  );

  int get discountPercent => originalPrice > price && originalPrice > 0
      ? ((originalPrice - price) / originalPrice * 100).round()
      : 0;
}

@immutable
class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
}
