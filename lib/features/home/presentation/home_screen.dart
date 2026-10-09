import 'package:flutter/material.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/proto_brand.dart';
import '../../../core/widgets/section_heading.dart';
import '../../catalog/domain/product.dart';
import '../../catalog/presentation/product_detail_screen.dart';
import '../../catalog/presentation/product_listing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onBrowseCategories,
    required this.onOpenProfile,
  });
  final VoidCallback onBrowseCategories;
  final VoidCallback onOpenProfile;

  void _browse(BuildContext context, {String? category, bool search = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductListingScreen(categoryId: category, focusSearch: search),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final categories = app.catalog.categories;
    final proteinCategory =
        categories
            .where(
              (category) =>
                  category.id == 'protein' ||
                  category.title.toLowerCase().contains('whey'),
            )
            .firstOrNull ??
        categories
            .where(
              (category) => category.title.toLowerCase().contains('protein'),
            )
            .firstOrNull ??
        categories.firstOrNull;
    final proteinProduct = proteinCategory == null
        ? app.catalog.products.firstOrNull
        : app.catalog.byCategory(proteinCategory.id).firstOrNull ??
              app.catalog.products.firstOrNull;
    final hydrationCategory = categories
        .where(
          (category) =>
              category.id == 'hydration' ||
              category.title.toLowerCase().contains('hydration'),
        )
        .firstOrNull;
    final hydrationProduct = hydrationCategory == null
        ? null
        : app.catalog.byCategory(hydrationCategory.id).firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        final padding = constraints.maxWidth < 500 ? 20.0 : 32.0;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 22, padding, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          flex: 3,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ProtoBrand(size: 33),
                          ),
                        ),
                        if (wide) ...[
                          const SizedBox(width: 22),
                          const Text(
                            'PERFORMANCE, ON DEMAND.',
                            style: TextStyle(
                              color: ProtoColors.muted,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: ProtoColors.lime.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 15,
                                color: ProtoColors.lime,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '12 MIN',
                                style: TextStyle(
                                  color: ProtoColors.lime,
                                  fontSize: 11,
                                  letterSpacing: .8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: onOpenProfile,
                          tooltip: 'Your profile',
                          style: IconButton.styleFrom(
                            backgroundColor: ProtoColors.elevated,
                          ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _chooseLocation(context, app),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 19,
                              color: ProtoColors.lime,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Deliver to ',
                              style: TextStyle(
                                color: ProtoColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                app.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    InkWell(
                      onTap: () => _browse(context, search: true),
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: ProtoColors.surface,
                          border: Border.all(color: ProtoColors.border),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: ProtoColors.muted,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search protein, creatine, snacks…',
                                style: TextStyle(
                                  color: ProtoColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.tune_rounded,
                              color: ProtoColors.muted,
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: ProtoColors.lime.withValues(alpha: .055),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: ProtoColors.lime.withValues(alpha: .16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: ProtoColors.lime,
                            size: 17,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              app.liveCatalog
                                  ? 'LIVE CATALOG · Orders and delivery are simulated'
                                  : 'LOCAL DEMO · Orders and delivery are simulated',
                              style: const TextStyle(
                                color: ProtoColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (app.liveCatalog && app.catalogLoading) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    if (app.catalogError != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            app.catalogError!,
                            style: const TextStyle(color: ProtoColors.muted),
                          ),
                          TextButton(
                            onPressed: app.refreshCatalog,
                            child: const Text('Retry catalog'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 27),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BUILT FOR YOUR EVERYDAY',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: ProtoColors.lime,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                'Fuel your next level.',
                                style: TextStyle(
                                  fontSize: wide ? 35 : 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (wide)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Small habits. Stronger you.',
                              style: TextStyle(
                                color: ProtoColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 23),
                    if (proteinProduct != null &&
                        wide &&
                        hydrationProduct != null)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _FuelHero(
                              product: proteinProduct,
                              onTap: () => _browse(
                                context,
                                category: proteinCategory?.id,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _HydrationHero(
                              product: hydrationProduct,
                              onTap: () => _browse(
                                context,
                                category: hydrationCategory?.id,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (proteinProduct != null)
                      _FuelHero(
                        product: proteinProduct,
                        onTap: () =>
                            _browse(context, category: proteinCategory?.id),
                      ),
                    if (app.catalog.products.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No products are available right now. Try again later.',
                          style: TextStyle(color: ProtoColors.muted),
                        ),
                      ),
                    const SizedBox(height: 13),
                    const _TrustStrip(),
                    const SizedBox(height: 30),
                    SectionHeading(
                      title: 'Find your fuel',
                      actionLabel: 'View all',
                      onAction: onBrowseCategories,
                    ),
                    if (categories.isNotEmpty)
                      SizedBox(
                        height: 125,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: app.catalog.categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 13),
                          itemBuilder: (context, index) {
                            final category = app.catalog.categories[index];
                            final product = app.catalog
                                .byCategory(category.id)
                                .firstOrNull;
                            return _CategoryShortcut(
                              category: category,
                              product: product,
                              onTap: () =>
                                  _browse(context, category: category.id),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 30),
                    if (app.catalog.products.isNotEmpty)
                      SectionHeading(
                        title: 'Featured products',
                        subtitle: 'The good stuff. Ready when you are.',
                        actionLabel: 'Shop all',
                        onAction: () => _browse(context),
                      ),
                  ],
                ),
              ),
            ),
            if (app.catalog.products.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                sliver: _ProductGrid(products: app.catalog.featuredProducts),
              ),
            if (app.catalog.products.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 30, padding, 0),
                sliver: SliverToBoxAdapter(
                  child: SectionHeading(
                    title: 'Popular right now',
                    subtitle: 'Community favorites for a stronger routine.',
                    actionLabel: 'Explore',
                    onAction: () => _browse(context),
                  ),
                ),
              ),
            if (app.catalog.products.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                sliver: _ProductGrid(products: app.catalog.popularProducts),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 30, padding, 32),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: ProtoColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ProtoColors.border),
                      ),
                      child: const Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 32,
                            color: ProtoColors.lime,
                          ),
                          const SizedBox(width: 18),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Only the good stuff.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.4,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'A curated local catalog for every part of your routine.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ProtoColors.muted,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'KEEP SHOWING UP.',
                      style: TextStyle(
                        color: ProtoColors.border,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We’ll bring the fuel.   •   Proto Day 2 / Local demo',
                      style: TextStyle(color: ProtoColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _chooseLocation(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your delivery neighborhood',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a sample location to explore Proto.',
                  style: TextStyle(fontSize: 12, color: ProtoColors.muted),
                ),
                const SizedBox(height: 16),
                for (final location in [
                  'Indiranagar, Bengaluru',
                  'Koramangala, Bengaluru',
                  'HSR Layout, Bengaluru',
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: ProtoColors.lime,
                    ),
                    title: Text(location, style: const TextStyle(fontSize: 14)),
                    trailing: app.location == location
                        ? const Icon(
                            Icons.check_rounded,
                            color: ProtoColors.lime,
                          )
                        : null,
                    onTap: () {
                      app.setLocation(location);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.crossAxisExtent >= 900
          ? 4
          : constraints.crossAxisExtent >= 600
          ? 3
          : 2;
      final cardWidth =
          (constraints.crossAxisExtent - (columns - 1) * 14) / columns;
      return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
          mainAxisExtent: ProductCard.gridExtent(context, cardWidth),
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(product: products[index]),
            ),
          ),
        ),
      );
    },
  );
}

class _FuelHero extends StatelessWidget {
  const _FuelHero({required this.onTap, required this.product});
  final VoidCallback onTap;
  final Product product;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 450;
      final narrow = constraints.maxWidth < 330;
      final titleSize = narrow
          ? 28.0
          : compact
          ? 31.0
          : 40.0;
      final scaledTitleSize = MediaQuery.textScalerOf(context).scale(titleSize);
      final textHeight = (scaledTitleSize - titleSize).clamp(0.0, 100.0) * 2.5;
      return ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: SizedBox(
          height: (compact ? 238.0 : 263.0) + textHeight,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: ProtoColors.lime)),
              Positioned(
                right: -65,
                top: -63,
                child: Container(
                  width: 310,
                  height: 310,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBFE354),
                      width: 35,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: narrow
                    ? -36
                    : compact
                    ? -31
                    : -8,
                bottom: -18,
                child: Transform.rotate(
                  angle: .13,
                  child: SizedBox(
                    width: narrow
                        ? 154
                        : compact
                        ? 177
                        : 244,
                    height: narrow
                        ? 195
                        : compact
                        ? 212
                        : 275,
                    child: ProductArtwork(product: product, showGlow: false),
                  ),
                ),
              ),
              Positioned(
                left: compact ? 21 : 27,
                top: 24,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THE DAILY EDGE',
                      style: TextStyle(
                        color: Color(0xFF39451B),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Good fuel.\nGreat form.',
                      style: TextStyle(
                        color: ProtoColors.background,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                        height: 1.03,
                      ),
                    ),
                    const SizedBox(height: 11),
                    const Text(
                      'Protein that keeps up with you.',
                      style: TextStyle(
                        color: Color(0xFF39451B),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: ProtoColors.background,
                        foregroundColor: ProtoColors.text,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop protein',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 14),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HydrationHero extends StatelessWidget {
  const _HydrationHero({required this.onTap, required this.product});
  final VoidCallback onTap;
  final Product product;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFDFE5DE),
    borderRadius: BorderRadius.circular(19),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 263,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -28,
              child: Transform.rotate(
                angle: -.2,
                child: SizedBox(
                  width: 191,
                  height: 232,
                  child: ProductArtwork(product: product, showGlow: false),
                ),
              ),
            ),
            const Positioned(
              left: 23,
              top: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SWEAT. RESET. REPEAT.',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: Color(0xFF515C51),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Stay\nin your\nelement.',
                    style: TextStyle(
                      color: ProtoColors.background,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.03,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 23,
              bottom: 24,
              child: CircleAvatar(
                radius: 19,
                backgroundColor: ProtoColors.background,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: ProtoColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({
    required this.category,
    required this.product,
    required this.onTap,
  });
  final ProductCategory category;
  final Product? product;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 104,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Container(
            height: 88,
            width: 104,
            decoration: BoxDecoration(
              color: category.accentColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: category.accentColor.withValues(alpha: .12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: product == null
                  ? Icon(category.icon, color: category.accentColor, size: 37)
                  : ProductArtwork(product: product!, showGlow: false),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            category.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final item in [
          (Icons.bolt_rounded, 'Fast delivery'),
          (Icons.verified_outlined, 'Curated quality'),
          (Icons.favorite_border_rounded, 'Goal approved'),
        ])
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 14, color: ProtoColors.muted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      fontSize: 9,
                      color: ProtoColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
