import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_card.dart';
import '../data/local_catalog_repository.dart';
import '../domain/product.dart';
import 'product_detail_screen.dart';

enum _PriceBand {
  under500('Under ₹500', null, 499.99),
  from500to999('₹500–₹999', 500, 999.99),
  from1000to1999('₹1,000–₹1,999', 1000, 1999.99),
  over2000('₹2,000+', 2000, null);

  const _PriceBand(this.label, this.min, this.max);

  final String label;
  final double? min;
  final double? max;
}

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
  CatalogSort _sort = CatalogSort.recommended;
  _PriceBand? _priceBand;
  ProductForm? _form;
  bool _availableOnly = false;

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
    for (final category in AppScope.of(context).catalog.categories) {
      if (category.id == _categoryId) return category.title;
    }
    return 'The Proto store';
  }

  List<Product> get _products => AppScope.of(context).catalog.browse(
    query: _search.text,
    categoryId: _categoryId,
    minPrice: _priceBand?.min,
    maxPrice: _priceBand?.max,
    form: _form,
    availableOnly: _availableOnly,
    sort: _sort,
  );

  String _sortLabel(CatalogSort sort) => switch (sort) {
    CatalogSort.recommended => 'Recommended',
    CatalogSort.priceLow => 'Price: low to high',
    CatalogSort.priceHigh => 'Price: high to low',
    CatalogSort.name => 'Name: A to Z',
    CatalogSort.popular => 'Most popular',
    CatalogSort.topRated => 'Top rated',
  };

  String _formLabel(ProductForm form) => switch (form) {
    ProductForm.tub => 'Tubs',
    ProductForm.pouch => 'Pouches',
    ProductForm.bar => 'Bars',
    ProductForm.bottle => 'Bottles',
  };

  int get _activeFilterCount =>
      (_priceBand == null ? 0 : 1) +
      (_form == null ? 0 : 1) +
      (_availableOnly ? 1 : 0);

  Future<void> _showSort() async {
    final selected = await showModalBottomSheet<CatalogSort>(
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
                for (final sort in CatalogSort.values)
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

  Future<void> _showFilters() async {
    var selectedCategory = _categoryId;
    var selectedPrice = _priceBand;
    var selectedForm = _form;
    var selectedAvailableOnly = _availableOnly;
    final result =
        await showModalBottomSheet<
          ({
            String? category,
            _PriceBand? price,
            ProductForm? form,
            bool availableOnly,
          })
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: ProtoColors.surface,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => StatefulBuilder(
            builder: (context, updateSheet) => SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Refine your fuel',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose a category, availability, price and type.',
                        style: TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'CATEGORY',
                        style: TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All categories',
                            selected: selectedCategory == null,
                            onTap: () =>
                                updateSheet(() => selectedCategory = null),
                          ),
                          for (final category in AppScope.of(
                            context,
                          ).catalog.categories)
                            _FilterChip(
                              label: category.title,
                              selected: selectedCategory == category.id,
                              onTap: () => updateSheet(
                                () => selectedCategory = category.id,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available only'),
                        subtitle: const Text(
                          'Show products ready to order',
                          style: TextStyle(color: ProtoColors.muted),
                        ),
                        value: selectedAvailableOnly,
                        activeThumbColor: ProtoColors.lime,
                        onChanged: (value) =>
                            updateSheet(() => selectedAvailableOnly = value),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PRICE RANGE',
                        style: TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'Any price',
                            selected: selectedPrice == null,
                            onTap: () =>
                                updateSheet(() => selectedPrice = null),
                          ),
                          for (final band in _PriceBand.values)
                            _FilterChip(
                              label: band.label,
                              selected: selectedPrice == band,
                              onTap: () =>
                                  updateSheet(() => selectedPrice = band),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'PRODUCT TYPE',
                        style: TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All types',
                            selected: selectedForm == null,
                            onTap: () => updateSheet(() => selectedForm = null),
                          ),
                          for (final form in ProductForm.values)
                            _FilterChip(
                              label: _formLabel(form),
                              selected: selectedForm == form,
                              onTap: () =>
                                  updateSheet(() => selectedForm = form),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => updateSheet(() {
                              selectedCategory = null;
                              selectedPrice = null;
                              selectedForm = null;
                              selectedAvailableOnly = false;
                            }),
                            child: const Text('Clear filters'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop((
                                category: selectedCategory,
                                price: selectedPrice,
                                form: selectedForm,
                                availableOnly: selectedAvailableOnly,
                              )),
                              style: FilledButton.styleFrom(
                                backgroundColor: ProtoColors.lime,
                                foregroundColor: ProtoColors.background,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: const Text('Show products'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    if (result != null && mounted) {
      setState(() {
        _categoryId = result.category;
        _priceBand = result.price;
        _form = result.form;
        _availableOnly = result.availableOnly;
      });
    }
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _categoryId = null;
      _sort = CatalogSort.recommended;
      _priceBand = null;
      _form = null;
      _availableOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    final controller = AppScope.of(context);
    return Scaffold(
      backgroundColor: ProtoColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: ProtoColors.surface,
                    side: const BorderSide(color: ProtoColors.border),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Tooltip(
                    message: 'View bag',
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/bag'),
                      style: TextButton.styleFrom(
                        foregroundColor: ProtoColors.text,
                        backgroundColor: ProtoColors.surface,
                        side: const BorderSide(color: ProtoColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(112, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: ProtoColors.lime,
                        size: 17,
                      ),
                      label: Text(
                        '${controller.cartCount} in bag',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
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
                              for (final category in AppScope.of(
                                context,
                              ).catalog.categories) ...[
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ProtoColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _showFilters,
                              icon: const Icon(
                                Icons.filter_list_rounded,
                                size: 16,
                              ),
                              label: Text(
                                _activeFilterCount == 0
                                    ? 'Filters'
                                    : 'Filters ($_activeFilterCount)',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _activeFilterCount == 0
                                    ? ProtoColors.text
                                    : ProtoColors.lime,
                                side: BorderSide(
                                  color: _activeFilterCount == 0
                                      ? ProtoColors.border
                                      : ProtoColors.lime,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(0, 38),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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
                          icon: const Icon(Icons.sort_rounded, size: 16),
                          label: Text(
                            _sortLabel(_sort),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_priceBand != null)
                                InputChip(
                                  label: Text(_priceBand!.label),
                                  onDeleted: () =>
                                      setState(() => _priceBand = null),
                                  deleteIcon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                ),
                              if (_form != null)
                                InputChip(
                                  label: Text(_formLabel(_form!)),
                                  onDeleted: () => setState(() => _form = null),
                                  deleteIcon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                ),
                              if (_availableOnly)
                                InputChip(
                                  label: const Text('Available only'),
                                  onDeleted: () =>
                                      setState(() => _availableOnly = false),
                                  deleteIcon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ],
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
                          Text(
                            _search.text.trim().isEmpty &&
                                    _activeFilterCount > 0
                                ? 'Try another price or type, or clear your filters.'
                                : 'Try another search or explore\nthe rest of the Proto store.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                        mainAxisExtent: ProductCard.gridExtent(
                          context,
                          cardWidth,
                        ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    backgroundColor: ProtoColors.elevated,
    selectedColor: ProtoColors.lime.withValues(alpha: .15),
    side: BorderSide(color: selected ? ProtoColors.lime : ProtoColors.border),
    labelStyle: TextStyle(
      color: selected ? ProtoColors.lime : ProtoColors.text,
      fontSize: 12,
    ),
  );
}
