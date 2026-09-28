import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/proto_button.dart';
import '../../catalog/presentation/product_detail_screen.dart';

class BagScreen extends StatelessWidget {
  const BagScreen({super.key, required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR NEXT LEVEL, PACKED.',
                  style: TextStyle(
                    fontSize: 9,
                    color: ProtoColors.lime,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Your bag',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${app.cartCount} ${app.cartCount == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ProtoColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (app.cartProducts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: ProtoColors.lime.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: ProtoColors.lime,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Make room for good fuel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your bag is empty. Find something\nthat moves you forward.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: ProtoColors.muted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ProtoButton(
                    label: 'Find your fuel',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onBrowse,
                  ),
                ],
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.separated(
              itemCount: app.bagLines.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) =>
                  _BagRow(line: app.bagLines[index]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: ProtoColors.lime.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          color: ProtoColors.lime,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Your fuel, delivered to ${app.location}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ProtoColors.lime,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bag summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  _SummaryRow(
                    label: 'Subtotal',
                    value: '₹${app.subtotal.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  const _SummaryRow(
                    label: 'Delivery',
                    value: 'FREE',
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'You’re saving',
                    value: '₹${app.savings.toStringAsFixed(0)}',
                    highlight: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  _SummaryRow(
                    label: 'Total',
                    value: '₹${app.subtotal.toStringAsFixed(0)}',
                    bold: true,
                  ),
                  const SizedBox(height: 25),
                  ProtoButton(
                    label: 'Review bag',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => _review(context, app),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Local demo • Checkout and payments arrive in a later build.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: ProtoColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _review(BuildContext context, AppController app) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: ProtoColors.lime,
                  size: 40,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your bag looks good.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${app.cartCount} items · ₹${app.subtotal.toStringAsFixed(0)}\nThis is a local preview. No order will be placed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ProtoColors.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                ProtoButton(
                  label: 'Keep exploring',
                  onPressed: () {
                    Navigator.pop(context);
                    onBrowse();
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

class _BagRow extends StatelessWidget {
  const _BagRow({required this.line});
  final BagLine line;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final product = line.product;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProtoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProtoColors.border),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailScreen(
                  product: product,
                  initialFlavor: line.flavor,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 75,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EBE4),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ProductArtwork(product: product, showGlow: false),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: ProtoColors.muted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.weightLabel}${line.flavor == null ? '' : ' · ${line.flavor}'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: ProtoColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: ProtoColors.lime.withValues(alpha: .35),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                app.remove(product, flavor: line.flavor),
                            tooltip: 'Remove ${product.name}',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.remove_rounded,
                              size: 15,
                              color: ProtoColors.lime,
                            ),
                          ),
                          Text(
                            '${line.quantity}',
                            style: const TextStyle(
                              color: ProtoColors.lime,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                app.add(product, flavor: line.flavor),
                            tooltip: 'Add another ${product.name}',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              size: 15,
                              color: ProtoColors.lime,
                            ),
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.bold = false,
  });
  final String label, value;
  final bool highlight, bold;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: bold ? 17 : 13,
            color: bold ? ProtoColors.text : ProtoColors.muted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: bold ? 22 : 13,
          color: highlight ? ProtoColors.lime : ProtoColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
