import 'package:flutter/material.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/price_summary.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/proto_button.dart';
import '../../catalog/presentation/product_detail_screen.dart';

class BagScreen extends StatelessWidget {
  const BagScreen({super.key, required this.onBrowse, this.standalone = false});

  final VoidCallback onBrowse;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 400 ? 20.0 : 24.0;
        final lines = app.bagLines;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(padding, 28, padding, 24),
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
                        Expanded(
                          child: Text(
                            standalone ? 'Good fuel, ready to go.' : 'Your bag',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${app.cartCount} ${app.cartCount == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: ProtoColors.muted,
                          ),
                        ),
                      ],
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _DeliveryLocation(location: app.location),
                    ],
                  ],
                ),
              ),
            ),
            if (lines.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyBag(onBrowse: onBrowse),
              )
            else ...[
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                sliver: SliverList.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _BagRow(line: lines[index]),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DeliveryProgress(
                        subtotal: app.subtotal,
                        deliveryFee: app.deliveryFee,
                      ),
                      const SizedBox(height: 24),
                      PriceSummary(
                        subtotal: app.subtotal,
                        deliveryFee: app.deliveryFee,
                        savings: app.savings,
                        discount: app.couponDiscount,
                        title: 'Bag summary',
                      ),
                      const SizedBox(height: 24),
                      ProtoButton(
                        label: 'Checkout',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (app.bagLines.isNotEmpty) {
                            Navigator.of(context).pushNamed('/checkout');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your delivery address and payment choice come next.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: ProtoColors.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: onBrowse,
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('Keep shopping'),
                        style: TextButton.styleFrom(
                          foregroundColor: ProtoColors.lime,
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );

    if (!standalone) return content;
    return Scaffold(
      backgroundColor: ProtoColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('Your bag'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _DeliveryLocation extends StatelessWidget {
  const _DeliveryLocation({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      border: Border.all(color: ProtoColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: ProtoColors.lime,
          size: 21,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivering to',
                style: TextStyle(fontSize: 10, color: ProtoColors.muted),
              ),
              const SizedBox(height: 5),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Confirm your full address at checkout.',
                style: TextStyle(
                  fontSize: 10,
                  color: ProtoColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EmptyBag extends StatelessWidget {
  const _EmptyBag({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: ProtoColors.lime.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: ProtoColors.lime.withValues(alpha: .12)),
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
          style: TextStyle(fontSize: 13, color: ProtoColors.muted, height: 1.6),
        ),
        const SizedBox(height: 28),
        ProtoButton(
          label: 'Find your fuel',
          icon: Icons.arrow_forward_rounded,
          onPressed: onBrowse,
        ),
        const SizedBox(height: 16),
        Text(
          'Free delivery on bags ${formatPrice(499)}+',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: ProtoColors.muted),
        ),
      ],
    ),
  );
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.subtotal, required this.deliveryFee});
  final double subtotal;
  final double deliveryFee;

  @override
  Widget build(BuildContext context) {
    const threshold = 499.0;
    final remaining = (threshold - subtotal).clamp(0.0, threshold).toDouble();
    final freeDelivery = deliveryFee == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProtoColors.lime.withValues(alpha: .06),
        border: Border.all(color: ProtoColors.lime.withValues(alpha: .15)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: ProtoColors.lime, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  freeDelivery
                      ? 'Free delivery unlocked'
                      : '${formatPrice(deliveryFee)} delivery',
                  style: const TextStyle(
                    fontSize: 13,
                    color: ProtoColors.lime,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (freeDelivery)
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: ProtoColors.lime,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            freeDelivery
                ? 'Your delivery fee is on us.'
                : 'Add ${formatPrice(remaining)} to your bag for free delivery.',
            style: const TextStyle(
              fontSize: 11,
              color: ProtoColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: (subtotal / threshold).clamp(0.0, 1.0).toDouble(),
            backgroundColor: ProtoColors.lime.withValues(alpha: .12),
            color: ProtoColors.lime,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: freeDelivery
                ? 'Free delivery unlocked'
                : '${formatPrice(remaining)} more for free delivery',
          ),
          const SizedBox(height: 9),
          Text(
            'Free delivery on bags ${formatPrice(threshold)}+',
            style: const TextStyle(fontSize: 10, color: ProtoColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BagRow extends StatelessWidget {
  const _BagRow({required this.line});
  final BagLine line;

  void _openProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: line.product,
          initialFlavor: line.flavor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final product = line.product;
    return Material(
      color: ProtoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ProtoColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'View ${product.name} details',
                  button: true,
                  child: InkWell(
                    onTap: () => _openProduct(context),
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      width: 68,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EBE4),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: ProductArtwork(
                          product: product,
                          showGlow: false,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.brand.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 8,
                                color: ProtoColors.muted,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Tooltip(
                            message:
                                'Remove item ${product.name} ${line.flavor ?? ''}',
                            child: Semantics(
                              label:
                                  'Remove all ${product.name} ${line.flavor ?? ''} from your bag',
                              child: TextButton.icon(
                                onPressed: () => app.removeLine(
                                  product,
                                  flavor: line.flavor,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: ProtoColors.muted,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 32),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 15,
                                ),
                                label: const Text('Remove'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _openProduct(context),
                        borderRadius: BorderRadius.circular(5),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.weightLabel}${line.flavor == null ? '' : ' · ${line.flavor}'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProtoColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${formatPrice(product.price)} each',
                        style: const TextStyle(
                          fontSize: 10,
                          color: ProtoColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item total',
                      style: TextStyle(fontSize: 10, color: ProtoColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(product.price * line.quantity),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
                _QuantityStepper(
                  line: line,
                  onDecrease: () => app.remove(product, flavor: line.flavor),
                  onIncrease: () => app.add(product, flavor: line.flavor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.line,
    required this.onDecrease,
    required this.onIncrease,
  });
  final BagLine line;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: ProtoColors.lime.withValues(alpha: .04),
      border: Border.all(color: ProtoColors.lime.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDecrease,
          tooltip: 'Remove ${line.product.name}',
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            maximumSize: const Size(40, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.remove_rounded,
            size: 17,
            color: ProtoColors.lime,
          ),
        ),
        Semantics(
          liveRegion: true,
          label: '${line.quantity} units in bag',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${line.quantity}',
              style: const TextStyle(
                color: ProtoColors.lime,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onIncrease,
          tooltip: 'Add another ${line.product.name}',
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            maximumSize: const Size(40, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.add_rounded,
            size: 17,
            color: ProtoColors.lime,
          ),
        ),
      ],
    ),
  );
}
