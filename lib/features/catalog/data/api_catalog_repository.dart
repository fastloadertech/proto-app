import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_models.dart';
import '../../../core/api/api_routes.dart';
import '../../../core/api/shared_backend_contract.dart';
import 'local_catalog_repository.dart';
import '../domain/catalog_repository.dart';
import '../domain/product.dart';

/// Cache-backed live adapter. Existing synchronous UI reads use the latest
/// complete snapshot; the local catalog covers first-load API failures.
class ApiCatalogRepository
    implements CatalogRepository, RemoteCatalogRepository {
  ApiCatalogRepository(
    this.client, {
    CatalogRepository fallback = const LocalCatalogSource(),
  }) : _fallback = fallback;
  final ApiClient client;
  final CatalogRepository _fallback;
  List<ProductCategory> _categories = const [];
  List<Product> _products = const [];
  bool _isLoaded = false;
  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> refresh() async {
    final responses = await Future.wait([
      client.get(ApiRoutes.categories),
      client.get(ApiRoutes.products),
    ]);
    final categoryDtos = ApiClient.objects(
      responses[0],
    ).map(CategoryDto.fromJson).toList();
    final productDtos = ApiClient.objects(
      responses[1],
    ).map(_decodeProduct).toList();
    final nextCategories = categoryDtos
        .where((dto) => dto.isActive != false)
        .map(_categoryFromDto)
        .toList(growable: false);
    final activeCategoryIds = nextCategories.map((item) => item.id).toSet();
    final nextProducts = productDtos
        .where((dto) => activeCategoryIds.contains(dto.categoryId))
        .map((dto) => _productFromDto(dto, categories: nextCategories))
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
    icon: switch (dto.slug) {
      'whey-protein' => Icons.fitness_center_rounded,
      'protein-bars' => Icons.cookie_outlined,
      'protein-drinks' || 'milk' => Icons.local_drink_outlined,
      'eggs' => Icons.egg_outlined,
      'paneer' => Icons.restaurant_outlined,
      'gym-essentials' => Icons.sports_gymnastics_outlined,
      _ => Icons.category_outlined,
    },
    accentColor: switch (dto.slug) {
      'protein-bars' => const Color(0xFFF1AB65),
      'protein-drinks' || 'milk' => const Color(0xFF7BBEF3),
      'eggs' || 'paneer' => const Color(0xFF74C7A4),
      'gym-essentials' => const Color(0xFFAB9DEF),
      _ => const Color(0xFFB9ED54),
    },
  );

  Product _productFromDto(
    ProductDto dto, {
    List<ProductCategory>? categories,
  }) => Product(
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
    accentColor:
        (categories ?? _categories)
            .where((category) => category.id == dto.categoryId)
            .map((category) => category.accentColor)
            .firstOrNull ??
        const Color(0xFFB9ED54),
    form: _formFor(dto),
    flavors: dto.flavors,
    isAvailable: dto.available,
    imageUrl: dto.imageUrl,
  );

  ProductForm _formFor(ProductDto dto) {
    final label = '${dto.sku ?? ''} ${dto.name}'.toLowerCase();
    if (label.contains('bar')) return ProductForm.bar;
    if (label.contains('shake') ||
        label.contains('drink') ||
        label.contains('milk') ||
        label.contains('shaker')) {
      return ProductForm.bottle;
    }
    if (label.contains('whey')) return ProductForm.tub;
    return ProductForm.pouch;
  }

  @override
  List<ProductCategory> get categories =>
      _isLoaded ? _categories : _fallback.categories;
  @override
  List<Product> get products => _isLoaded ? _products : _fallback.products;
  @override
  List<Product> get featuredProducts => List.unmodifiable(products.take(6));
  @override
  List<Product> get popularProducts =>
      List.unmodifiable(browse(sort: CatalogSort.popular).take(4));
  @override
  Product? getById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  List<Product> byCategory(String categoryId) => browse(categoryId: categoryId);

  @override
  Future<Product?> loadById(String id) async {
    // A fallback item is not a backend UUID. Keep the offline demo usable.
    if (!_products.any((product) => product.id == id) &&
        _fallback.getById(id) != null) {
      return _fallback.getById(id);
    }
    final json = ApiClient.object(await client.get(ApiRoutes.product(id)));
    final product = _productFromDto(_decodeProduct(json));
    final index = _products.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final updated = [..._products];
      updated[index] = product;
      _products = List.unmodifiable(updated);
    }
    return product;
  }

  @override
  Future<List<Product>> searchProducts({
    String query = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductForm? form,
    bool availableOnly = false,
    CatalogSort sort = CatalogSort.recommended,
  }) async {
    final parameters = <String, String>{'active': 'true'};
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      parameters['category'] = categoryId;
    }
    if (query.trim().isNotEmpty) parameters['search'] = query.trim();
    if (availableOnly) parameters['available'] = 'true';
    parameters['sort'] = switch (sort) {
      CatalogSort.priceLow => 'price_asc',
      CatalogSort.priceHigh => 'price_desc',
      CatalogSort.name => 'name_asc',
      _ => 'newest',
    };
    final path = Uri(
      path: ApiRoutes.products,
      queryParameters: parameters,
    ).toString();
    final results = ApiClient.objects(await client.get(path))
        .map((json) => _productFromDto(_decodeProduct(json)))
        .toList(growable: false);
    return _filter(
      results,
      query: query,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      form: form,
      availableOnly: availableOnly,
      sort: sort,
    );
  }

  ProductDto _decodeProduct(Map<String, dynamic> json) =>
      json.containsKey('price')
      ? SharedBackendContract.product(json)
      : ProductDto.fromJson(json);

  @override
  List<Product> browse({
    String query = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductForm? form,
    bool availableOnly = false,
    CatalogSort sort = CatalogSort.recommended,
  }) => !_isLoaded
      ? _fallback.browse(
          query: query,
          categoryId: categoryId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          form: form,
          availableOnly: availableOnly,
          sort: sort,
        )
      : _filter(
          _products,
          query: query,
          categoryId: categoryId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          form: form,
          availableOnly: availableOnly,
          sort: sort,
        );

  List<Product> _filter(
    List<Product> source, {
    String query = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductForm? form,
    bool availableOnly = false,
    CatalogSort sort = CatalogSort.recommended,
  }) {
    final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    final results = source.where((product) {
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
