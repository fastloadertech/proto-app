import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../domain/product.dart';
import 'product_listing_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _openCategory(BuildContext context, [String? categoryId]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductListingScreen(categoryId: categoryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth.clamp(0.0, 1120.0).toDouble();
        final columns = contentWidth >= 820 ? 3 : 2;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURATED FOR YOUR ROUTINE',
                          style: TextStyle(
                            color: ProtoColors.lime,
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Find your fuel.',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.3,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Good ingredients. Better performance.\nEverything your next rep needs.',
                          style: TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Material(
                          color: ProtoColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: ProtoColors.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProductListingScreen(
                                  focusSearch: true,
                                ),
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: ProtoColors.muted,
                                    size: 21,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Search protein, snacks & more',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: ProtoColors.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Shop the essentials',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.4,
                                ),
                              ),
                            ),
                            Text(
                              '${AppScope.of(context).catalog.categories.length} categories',
                              style: const TextStyle(
                                color: ProtoColors.muted,
                                fontSize: 11,
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
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: (constraints.maxWidth - contentWidth) / 2 + 24,
              ),
              sliver: SliverGrid.builder(
                itemCount: AppScope.of(context).catalog.categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 194,
                ),
                itemBuilder: (context, index) {
                  final category = AppScope.of(
                    context,
                  ).catalog.categories[index];
                  final count = AppScope.of(context).catalog.products
                      .where((product) => product.categoryId == category.id)
                      .length;
                  return _CategoryTile(
                    category: category,
                    count: count,
                    onTap: () => _openCategory(context, category.id),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Material(
                      color: ProtoColors.lime,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: () => _openCategory(context),
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: ProtoColors.background,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your routine, restocked.',
                                      style: TextStyle(
                                        color: ProtoColors.background,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Explore the complete Proto edit',
                                      style: TextStyle(
                                        color: Color(0xFF515D34),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: ProtoColors.background,
                                size: 21,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.onTap,
  });

  final ProductCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ProtoColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: ProtoColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: category.accentColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.accentColor,
                    size: 27,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.north_east_rounded,
                  color: ProtoColors.muted,
                  size: 18,
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              category.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Text(
              '$count products',
              style: TextStyle(
                color: category.accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
