import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_card.dart';
import '../data/local_catalog_repository.dart';
import '../domain/product.dart';
import 'product_detail_screen.dart';

enum _CatalogSort { recommended, priceLow, priceHigh, topRated }

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({
    super.key,
    this.categoryId,
    this.initialQuery,
    this.focusSearch = false,
  });

  final String? categoryId;
  final String? initialQuery;
  final bool focusSearch;

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  late final TextEditingController _search;
  String? _categoryId;
  _CatalogSort _sort = _CatalogSort.recommended;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    _categoryId = widget.categoryId;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title {
    for (final category in LocalCatalogRepository.categories) {
      if (category.id == _categoryId) return category.title;
    }
    return 'The Proto store';
  }

  List<Product> get _products {
    final products = LocalCatalogRepository.search(_search.text)
        .where(
          (product) => _categoryId == null || product.categoryId == _categoryId,
        )
        .toList();
    switch (_sort) {
      case _CatalogSort.recommended:
        break;
      case _CatalogSort.priceLow:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _CatalogSort.priceHigh:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _CatalogSort.topRated:
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return products;
  }

  String _sortLabel(_CatalogSort sort) => switch (sort) {
    _CatalogSort.recommended => 'Recommended',
    _CatalogSort.priceLow => 'Price: low to high',
    _CatalogSort.priceHigh => 'Price: high to low',
    _CatalogSort.topRated => 'Top rated',
  };

  Future<void> _showSort() async {
    final selected = await showModalBottomSheet<_CatalogSort>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ProtoColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find your perfect pick',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sort the essentials your way.',
                  style: TextStyle(color: ProtoColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                for (final sort in _CatalogSort.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_sortLabel(sort)),
                    trailing: Icon(
                      sort == _sort
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: sort == _sort
                          ? ProtoColors.lime
                          : ProtoColors.muted,
                    ),
                    onTap: () => Navigator.of(context).pop(sort),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _sort = selected);
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _categoryId = null;
      _sort = _CatalogSort.recommended;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    final controller = AppScope.of(context);
    return Scaffold(
      backgroundColor: ProtoColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth
                .clamp(0.0, 1240.0)
                .toDouble();
            final horizontalPadding =
                (constraints.maxWidth - contentWidth) / 2 + 20;
            final gridWidth = contentWidth - 40;
            final columns = (gridWidth / 190).floor().clamp(2, 6).toInt();
            final cardWidth = (gridWidth - (columns - 1) * 14) / columns;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: ProtoColors.surface,
                                side: const BorderSide(
                                  color: ProtoColors.border,
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ProtoColors.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: ProtoColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: ProtoColors.lime,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      '${controller.cartCount} in bag',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'GOOD FUEL. ON DEMAND.',
                          style: TextStyle(
                            color: ProtoColors.lime,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _search,
                          autofocus: widget.focusSearch,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search protein, snacks & more',
                            hintStyle: const TextStyle(
                              color: ProtoColors.muted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: ProtoColors.surface,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: ProtoColors.muted,
                              size: 21,
                            ),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                  ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: ProtoColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: ProtoColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: ProtoColors.lime,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _CategoryChip(
                                label: 'All products',
                                selected: _categoryId == null,
                                onTap: () => setState(() => _categoryId = null),
                              ),
                              for (final category
                                  in LocalCatalogRepository.categories) ...[
                                const SizedBox(width: 8),
                                _CategoryChip(
                                  label: category.title,
                                  selected: _categoryId == category.id,
                                  onTap: () =>
                                      setState(() => _categoryId = category.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${products.length} ${products.length == 1 ? 'essential' : 'essentials'}',
                                style: const TextStyle(
                                  color: ProtoColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _showSort,
                              style: TextButton.styleFrom(
                                foregroundColor: ProtoColors.text,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: Text(
                                _sortLabel(_sort),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                if (products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 30, 32, 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: const BoxDecoration(
                              color: ProtoColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              color: ProtoColors.lime,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'No fuel found just yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Try another search or explore\nthe rest of the Proto store.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ProtoColors.muted,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: _clearFilters,
                            child: const Text('View all products'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      28,
                    ),
                    sliver: SliverGrid.builder(
                      itemCount: products.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: cardWidth / 1.06 + 168,
                      ),
                      itemBuilder: (context, index) => ProductCard(
                        product: products[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProductDetailScreen(product: products[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? ProtoColors.lime : ProtoColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: selected ? ProtoColors.lime : ProtoColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? ProtoColors.background : ProtoColors.muted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}
