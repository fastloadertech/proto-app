import 'package:flutter/material.dart';

import '../../features/catalog/domain/product.dart';
import '../state/app_controller.dart';
import '../theme/proto_theme.dart';
import 'product_artwork.dart';

/// A compact catalog card shared by the home feed and product listings.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final quantity = controller.quantityFor(product.id);
        return Material(
          color: ProtoColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: ProtoColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.06,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: const Color(0xFFECEEE7),
                          child: LayoutBuilder(
                            builder: (context, constraints) => Center(
                              child: ProductArtwork(
                                product: product,
                                size: constraints.maxWidth * .85,
                                showGlow: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (product.badge.isNotEmpty)
                        Positioned(
                          left: 10,
                          right: 45,
                          top: 10,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 110),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF181B15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.badge.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ProtoColors.lime,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 7,
                        top: 6,
                        child: IconButton(
                          tooltip: controller.isSaved(product.id)
                              ? 'Remove from saved'
                              : 'Save product',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: .7),
                            minimumSize: const Size.square(32),
                            maximumSize: const Size.square(32),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => controller.toggleSaved(product),
                          icon: Icon(
                            controller.isSaved(product.id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 17,
                            color: const Color(0xFF20251B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 35,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ProtoColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.weightLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: ProtoColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                                if (product.originalPrice > product.price) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '₹${product.originalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: ProtoColors.muted,
                                      fontSize: 10,
                                      decoration: TextDecoration.lineThrough,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (quantity == 0)
                            SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () => controller.add(product),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ProtoColors.lime,
                                  side: const BorderSide(
                                    color: ProtoColors.lime,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.add_rounded, size: 15),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: ProtoColors.lime,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QuantityButton(
                                    label: 'Remove one ${product.name}',
                                    icon: Icons.remove_rounded,
                                    onPressed: () => controller.remove(product),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      color: ProtoColors.background,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  _QuantityButton(
                                    label: 'Add one ${product.name}',
                                    icon: Icons.add_rounded,
                                    onPressed: () => controller.add(product),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 26, height: 32),
    style: IconButton.styleFrom(
      minimumSize: const Size(26, 32),
      maximumSize: const Size(26, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: Icon(icon, size: 15, color: ProtoColors.background),
  );
}
