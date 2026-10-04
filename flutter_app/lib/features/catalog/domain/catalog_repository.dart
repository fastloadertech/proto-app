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
