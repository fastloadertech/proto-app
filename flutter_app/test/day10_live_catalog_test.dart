import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proto/app/proto_app.dart';
import 'package:proto/core/api/api_client.dart';
import 'package:proto/core/api/api_models.dart';
import 'package:proto/core/api/api_routes.dart';
import 'package:proto/core/api/shared_backend_contract.dart';
import 'package:proto/core/state/app_controller.dart';
import 'package:proto/features/catalog/data/api_catalog_repository.dart';
import 'package:proto/features/catalog/data/local_catalog_repository.dart';
import 'package:proto/features/catalog/domain/catalog_repository.dart';
import 'package:proto/features/catalog/presentation/product_detail_screen.dart';

const _categoryId = '109b0a33-1bd2-4f2c-8355-d26f195e4c57';
const _productId = '824e02b0-e13d-4250-9b62-08544f0367ca';
const _category = {
  'id': _categoryId,
  'name': 'Whey Protein',
  'slug': 'whey-protein',
  'description': null,
  'isActive': true,
  'createdAt': '2026-10-07T04:00:00.000Z',
  'updatedAt': '2026-10-07T04:00:00.000Z',
};
const _product = {
  'id': _productId,
  'sku': 'PROTO-WHEY-01',
  'name': 'Backend Whey',
  'description': 'Clean protein from the API.',
  'price': '1499.95',
  'currency': 'INR',
  'imageUrl': null,
  'stockQuantity': 12,
  'isActive': true,
  'available': true,
  'category': _category,
  'createdAt': '2026-10-07T04:00:00.000Z',
  'updatedAt': '2026-10-07T04:00:00.000Z',
};

void main() {
  test(
    'live adapter loads nested category, decimal price and nullable image',
    () async {
      final transport = _Transport(
        (request) async => ApiResponse(
          200,
          request.uri.path == ApiRoutes.categories
              ? [_category]
              : [
                  _product,
                  {
                    ..._product,
                    'id': 'out-of-stock',
                    'stockQuantity': 0,
                    'available': false,
                  },
                ],
        ),
      );
      final catalog = ApiCatalogRepository(ApiClient(transport: transport));
      expect(catalog.isLoaded, isFalse);
      expect(
        catalog.products,
        isNotEmpty,
      ); // Offline fallback before first load.
      await catalog.refresh();
      expect(catalog.isLoaded, isTrue);
      expect(catalog.categories.single.id, _categoryId);
      expect(catalog.products, hasLength(2));
      expect(catalog.products.first.price, 1499.95);
      expect(catalog.products.first.categoryId, _categoryId);
      expect(catalog.products.first.imageUrl, isNull);
      expect(catalog.browse(availableOnly: true), hasLength(1));
      expect(catalog.browse(query: 'backend'), hasLength(2));
      final dto = SharedBackendContract.product(_product);
      expect(ProductDto.fromJson(dto.toJson()).pricePaise, 149995);
      expect(
        transport.requests.map((request) => request.uri.path),
        containsAll([ApiRoutes.categories, ApiRoutes.products]),
      );
    },
  );

  test(
    'product detail requests /products/:id and refreshes its snapshot',
    () async {
      final transport = _Transport((request) async {
        if (request.uri.path == ApiRoutes.categories)
          return const ApiResponse(200, [_category]);
        if (request.uri.path == ApiRoutes.products)
          return const ApiResponse(200, [_product]);
        return ApiResponse(200, Map.of(_product)..['price'] = '1599.00');
      });
      final catalog = ApiCatalogRepository(ApiClient(transport: transport));
      await catalog.refresh();
      final detail = await catalog.loadById(_productId);
      expect(detail?.price, 1599);
      expect(catalog.getById(_productId)?.price, 1599);
      expect(transport.requests.last.uri.path, ApiRoutes.product(_productId));
    },
  );

  test(
    'search maps category, availability and sort to backend query',
    () async {
      final transport = _Transport(
        (request) async => ApiResponse(
          200,
          request.uri.path == ApiRoutes.categories ? [_category] : [_product],
        ),
      );
      final catalog = ApiCatalogRepository(ApiClient(transport: transport));
      await catalog.refresh();
      final found = await catalog.searchProducts(
        query: ' Backend  ',
        categoryId: _categoryId,
        availableOnly: true,
        sort: CatalogSort.priceHigh,
        minPrice: 1000,
        maxPrice: 2000,
      );
      expect(found.single.name, 'Backend Whey');
      expect(transport.requests.last.uri.queryParameters, {
        'active': 'true',
        'category': _categoryId,
        'search': 'Backend',
        'available': 'true',
        'sort': 'price_desc',
      });
      await catalog.searchProducts(sort: CatalogSort.priceLow);
      expect(transport.requests.last.uri.queryParameters['sort'], 'price_asc');
      await catalog.searchProducts(sort: CatalogSort.name);
      expect(transport.requests.last.uri.queryParameters['sort'], 'name_asc');
    },
  );

  test(
    'failed refresh keeps local fallback or last complete snapshot',
    () async {
      var failing = true;
      final transport = _Transport(
        (request) async => failing
            ? const ApiResponse(500, {'message': 'internal detail'})
            : ApiResponse(
                200,
                request.uri.path == ApiRoutes.categories
                    ? [_category]
                    : [_product],
              ),
      );
      final catalog = ApiCatalogRepository(ApiClient(transport: transport));
      final app = AppController(catalogRepository: catalog);
      addTearDown(app.dispose);
      await app.refreshCatalog();
      expect(app.catalogError, contains('demo products'));
      expect(
        catalog.products.first.id,
        LocalCatalogRepository.products.first.id,
      );
      failing = false;
      await app.refreshCatalog();
      expect(app.catalogError, isNull);
      expect(catalog.products.single.name, 'Backend Whey');
      failing = true;
      await app.refreshCatalog();
      expect(app.catalogError, contains('last loaded'));
      expect(catalog.products.single.name, 'Backend Whey');
    },
  );

  test('empty live response stays empty and does not fall back', () async {
    final catalog = ApiCatalogRepository(
      ApiClient(
        transport: _Transport((request) async => const ApiResponse(200, [])),
      ),
    );
    await catalog.refresh();
    expect(catalog.categories, isEmpty);
    expect(catalog.products, isEmpty);
  });

  test(
    'catalog failures map safely, including timeout and auth statuses',
    () async {
      for (final status in [400, 401, 403, 404, 409, 500]) {
        final app = AppController(
          catalogRepository: ApiCatalogRepository(
            ApiClient(
              transport: _Transport(
                (request) async => ApiResponse(status, {
                  'statusCode': status,
                  'message': 'raw server detail',
                }),
              ),
            ),
          ),
        );
        await expectLater(
          app.searchCatalog(query: 'whey'),
          throwsA(
            isA<CatalogLoadException>().having(
              (error) => error.message,
              'message',
              isNot(contains('raw server detail')),
            ),
          ),
        );
        app.dispose();
      }
      for (final error in [StateError('offline'), TimeoutException('slow')]) {
        final app = AppController(
          catalogRepository: ApiCatalogRepository(
            ApiClient(transport: _Transport((request) async => throw error)),
          ),
        );
        await expectLater(
          app.searchCatalog(),
          throwsA(
            isA<CatalogLoadException>().having(
              (e) => e.message,
              'message',
              contains('connection'),
            ),
          ),
        );
        app.dispose();
      }
    },
  );

  test(
    'backend product bag and order snapshots survive catalog updates',
    () async {
      var price = '1499.95';
      final transport = _Transport(
        (request) async => ApiResponse(
          200,
          request.uri.path == ApiRoutes.categories
              ? [_category]
              : [
                  {..._product, 'price': price},
                ],
        ),
      );
      final catalog = ApiCatalogRepository(ApiClient(transport: transport));
      final app = AppController(catalogRepository: catalog);
      addTearDown(app.dispose);
      await app.refreshCatalog();
      final first = catalog.products.single;
      app.add(first, quantity: 2);
      expect(app.cartCount, 2);
      expect(app.subtotal, 2999.90);
      price = '1999.00';
      await app.refreshCatalog();
      expect(catalog.products.single.price, 1999);
      expect(app.bagLines.single.product.price, 1499.95);
      expect(app.subtotal, 2999.90);
      final order = await app.submitOrder(
        address: app.deliveryAddress,
        contact: app.contact,
        paymentMethod: app.paymentMethod,
      );
      expect(order.items.single.quantity, 2);
      expect(order.items.single.unitPrice, 1499.95);
      expect(app.cartCount, 0);
    },
  );

  testWidgets(
    'live catalog displays backend product and preserves bag navigation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final transport = _Transport(
        (request) async => ApiResponse(
          200,
          request.uri.path == ApiRoutes.categories
              ? [_category]
              : request.uri.path == ApiRoutes.product(_productId)
              ? _product
              : [_product],
        ),
      );
      await tester.pumpWidget(
        ProtoApp(
          liveCatalog: true,
          catalogRepository: ApiCatalogRepository(
            ApiClient(transport: transport),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore as guest'));
      await tester.tap(find.text('Explore as guest'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Search protein'));
      await tester.pumpAndSettle();
      expect(find.text('Backend Whey'), findsWidgets);
      await tester.ensureVisible(find.text('Backend Whey').first);
      await tester.tap(find.text('Backend Whey').first);
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(
        transport.requests.map((request) => request.uri.path),
        contains(ApiRoutes.product(_productId)),
      );
      await tester.ensureVisible(find.text('Add to bag'));
      await tester.tap(find.text('Add to bag'));
      await tester.pumpAndSettle();
      expect(find.text('1 in bag'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Transport implements ApiTransport {
  _Transport(this.handler);
  final Future<ApiResponse> Function(ApiRequest) handler;
  final List<ApiRequest> requests = [];
  @override
  Future<ApiResponse> send(ApiRequest request) {
    requests.add(request);
    return handler(request);
  }
}
