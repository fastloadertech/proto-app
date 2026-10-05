import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_models.dart';
import '../../../core/api/api_routes.dart';
import '../../../core/api/shared_backend_contract.dart';
import '../domain/catalog_repository.dart';
import '../domain/product.dart';

/// Opt-in, cache-backed catalog adapter. Screens keep their synchronous
/// CatalogRepository reads; a future app bootstrap can explicitly await
/// refresh() and show loading/error UI before exposing this repository.
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this.client);
  final ApiClient client;
  List<ProductCategory> _categories = const [];
  List<Product> _products = const [];
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> refresh() async {
    final responses = await Future.wait([
      client.get(ApiRoutes.categories),
      client.get(ApiRoutes.products),
    ]);
    final categoryDtos = ApiClient.objects(
      responses[0],
    ).map(CategoryDto.fromJson).toList();
    final productDtos = ApiClient.objects(responses[1])
        .map(
          (json) => json.containsKey('price')
              ? SharedBackendContract.product(json)
              : ProductDto.fromJson(json),
        )
        .toList();
    final nextCategories = categoryDtos
        .where((dto) => dto.isActive != false)
        .map(_categoryFromDto)
        .toList(growable: false);
    final activeCategoryIds = nextCategories.map((item) => item.id).toSet();
    final nextProducts = productDtos
        .where((dto) => activeCategoryIds.contains(dto.categoryId))
        .map(_productFromDto)
        .toList(growable: false);
    // Publish only after both responses and mappings succeed.
    _categories = List.unmodifiable(nextCategories);
    _products = List.unmodifiable(nextProducts);
    _isLoaded = true;
  }

  ProductCategory _categoryFromDto(CategoryDto dto) => ProductCategory(
    id: dto.id,
    title: dto.name,
    subtitle: dto.description ?? '',
    icon: Icons.category_outlined,
    accentColor: const Color(0xFFB9ED54),
  );

  Product _productFromDto(ProductDto dto) => Product(
    id: dto.id,
    name: dto.name,
    brand: 'PROTO',
    categoryId: dto.categoryId,
    price: dto.pricePaise / 100,
    originalPrice: dto.pricePaise / 100,
    weightLabel: '',
    subtitle: dto.description,
    description: dto.description,
    proteinGrams: 0,
    servings: 0,
    rating: 0,
    reviewCount: 0,
    badge: '',
    accentColor: const Color(0xFFB9ED54),
    form: ProductForm.values.firstWhere(
      (form) => form.name == dto.type,
      orElse: () => ProductForm.pouch,
    ),
    flavors: dto.flavors,
    isAvailable: dto.available,
  );

  @override
  List<ProductCategory> get categories => _categories;
  @override
  List<Product> get products => _products;
  @override
  List<Product> get featuredProducts => List.unmodifiable(_products.take(6));
  @override
  List<Product> get popularProducts =>
      List.unmodifiable(browse(sort: CatalogSort.popular).take(4));
  @override
  Product? getById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  List<Product> byCategory(String categoryId) => browse(categoryId: categoryId);

  @override
  List<Product> browse({
    String query = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductForm? form,
    bool availableOnly = false,
    CatalogSort sort = CatalogSort.recommended,
  }) {
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final results = _products.where((product) {
      if (availableOnly && !product.isAvailable) return false;
      if (categoryId != null &&
          categoryId != 'all' &&
          categoryId.isNotEmpty &&
          product.categoryId != categoryId)
        return false;
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;
      if (form != null && product.form != form) return false;
      if (query.trim().isEmpty) return true;
      final category = _categories
          .where((item) => item.id == product.categoryId)
          .map((item) => item.title)
          .firstOrNull;
      final text = [
        product.name,
        product.brand,
        product.subtitle,
        product.categoryId,
        if (category != null) category,
        ...product.flavors,
      ].join(' ').toLowerCase();
      return terms.every(text.contains);
    }).toList();
    switch (sort) {
      case CatalogSort.recommended:
        break;
      case CatalogSort.priceLow:
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CatalogSort.priceHigh:
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CatalogSort.name:
        results.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CatalogSort.popular:
        results.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case CatalogSort.topRated:
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return List.unmodifiable(results);
  }
}
