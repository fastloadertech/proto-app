import 'product.dart';

enum CatalogSort { recommended, priceLow, priceHigh, name, popular, topRated }

/// Catalog reads used by the customer UI. An API source can replace the local
/// source through AppController without changing discovery screens.
abstract class CatalogRepository {
  List<ProductCategory> get categories;
  List<Product> get products;
  List<Product> get featuredProducts;
  List<Product> get popularProducts;
  Product? getById(String id);
  List<Product> byCategory(String categoryId);
  List<Product> browse({
    String query = '',
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductForm? form,
    bool availableOnly = false,
    CatalogSort sort = CatalogSort.recommended,
  });
}

/// Async operations exposed only by a live catalog. Existing synchronous
/// reads and the local catalog remain unchanged.
abstract interface class RemoteCatalogRepository {
  bool get isLoaded;
  Future<void> refresh();
  Future<Product?> loadById(String id);
  Future<List<Product>> searchProducts({
    String query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    ProductForm? form,
    bool availableOnly,
    CatalogSort sort,
  });
}

class CatalogLoadException implements Exception {
  const CatalogLoadException(this.message, {this.notFound = false});
  final String message;
  final bool notFound;
  @override
  String toString() => message;
}
