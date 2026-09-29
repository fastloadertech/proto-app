import 'package:flutter/material.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_artwork.dart';
import '../domain/product.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.initialFlavor,
  });

  final Product product;
  final String? initialFlavor;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _flavor;
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.flavors.isNotEmpty) {
      _flavor = widget.product.flavors.contains(widget.initialFlavor)
          ? widget.initialFlavor
          : widget.product.flavors.first;
    }
  }

  void _selectFlavor(String flavor) {
    if (_flavor == flavor) return;
    setState(() {
      _flavor = flavor;
      _selectedQuantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        backgroundColor: ProtoColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          titleSpacing: 20,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
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
                  const Text(
                    'THE GOOD STUFF',
                    style: TextStyle(
                      color: ProtoColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: controller.isSaved(product.id)
                        ? 'Remove from saved'
                        : 'Save product',
                    onPressed: () => controller.toggleSaved(product),
                    style: IconButton.styleFrom(
                      backgroundColor: ProtoColors.surface,
                      side: const BorderSide(color: ProtoColors.border),
                    ),
                    icon: Icon(
                      controller.isSaved(product.id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: controller.isSaved(product.id)
                          ? ProtoColors.lime
                          : ProtoColors.text,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _PurchaseBar(
          product: product,
          flavor: _flavor,
          selectedQuantity: _selectedQuantity,
          onIncrease: () => setState(() => _selectedQuantity++),
          onDecrease: _selectedQuantity > 1
              ? () => setState(() => _selectedQuantity--)
              : null,
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final information = _ProductInformation(
                            product: product,
                            flavor: _flavor,
                            onFlavorSelected: _selectFlavor,
                          );
                          if (constraints.maxWidth >= 850) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ProductVisual(product: product),
                                ),
                                const SizedBox(width: 40),
                                Expanded(child: information),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProductVisual(product: product),
                              const SizedBox(height: 26),
                              information,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.08,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: ColoredBox(
        color: const Color(0xFFECEEE7),
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: ProductArtwork(
                    product: product,
                    size: constraints.maxWidth * .82,
                    showGlow: false,
                  ),
                ),
              ),
            ),
            if (product.badge.isNotEmpty)
              Positioned(
                left: 18,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: ProtoColors.background,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    product.badge.toUpperCase(),
                    style: const TextStyle(
                      color: ProtoColors.lime,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.weightLabel,
                  style: const TextStyle(
                    color: Color(0xFF414938),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({
    required this.product,
    required this.flavor,
    required this.onFlavorSelected,
  });

  final Product product;
  final String? flavor;
  final ValueChanged<String> onFlavorSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              product.brand.toUpperCase(),
              style: const TextStyle(
                color: ProtoColors.lime,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, color: Color(0xFFE6C76B), size: 16),
          const SizedBox(width: 4),
          Text(
            product.rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 5),
          Text(
            '(${product.reviewCount})',
            style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        product.name,
        style: const TextStyle(
          fontSize: 31,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
          height: 1.16,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        product.subtitle,
        style: const TextStyle(
          color: ProtoColors.muted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: ProtoColors.lime.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ProtoColors.lime.withValues(alpha: .15)),
        ),
        child: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: ProtoColors.lime, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'At your door in 12 min',
                style: TextStyle(
                  color: ProtoColors.lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      if (product.flavors.isNotEmpty) ...[
        const SizedBox(height: 26),
        Row(
          children: [
            const Text(
              'Pick your flavour',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                flavor ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in product.flavors)
              ChoiceChip(
                label: Text(option),
                selected: option == flavor,
                onSelected: (_) => onFlavorSelected(option),
                showCheckmark: false,
                backgroundColor: ProtoColors.surface,
                selectedColor: ProtoColors.lime.withValues(alpha: .12),
                side: BorderSide(
                  color: option == flavor
                      ? ProtoColors.lime
                      : ProtoColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                labelStyle: TextStyle(
                  color: option == flavor
                      ? ProtoColors.lime
                      : ProtoColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: 26),
      Container(
        decoration: BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProtoColors.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _NutritionStat(
                  value: '${product.proteinGrams}g',
                  label: 'PROTEIN',
                ),
              ),
              const VerticalDivider(color: ProtoColors.border, width: 1),
              Expanded(
                child: _NutritionStat(
                  value: '${product.servings}',
                  label: 'SERVINGS',
                ),
              ),
              const VerticalDivider(color: ProtoColors.border, width: 1),
              const Expanded(
                child: _NutritionStat(value: '100%', label: 'AUTHENTIC'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
      const Text(
        'Made for your momentum.',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -.4,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        product.description,
        style: const TextStyle(
          color: ProtoColors.muted,
          fontSize: 13,
          height: 1.75,
        ),
      ),
      const SizedBox(height: 24),
      const Divider(color: ProtoColors.border, height: 1),
      const SizedBox(height: 20),
      const Row(
        children: [
          Icon(Icons.verified_outlined, color: ProtoColors.muted, size: 19),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Handpicked brands. Sealed, fresh, and ready to go.',
              style: TextStyle(
                color: ProtoColors.muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _NutritionStat extends StatelessWidget {
  const _NutritionStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        label,
        style: const TextStyle(
          color: ProtoColors.muted,
          fontSize: 8,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
}

class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.product,
    required this.flavor,
    required this.selectedQuantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  final Product product;
  final String? flavor;
  final int selectedQuantity;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final bagQuantity = controller.quantityFor(product.id, flavor: flavor);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ProtoColors.surface,
        border: Border(top: BorderSide(color: ProtoColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  formatPrice(product.price),
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.6,
                                  ),
                                ),
                                if (product.originalPrice > product.price) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      formatPrice(product.originalPrice),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ProtoColors.muted,
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  bagQuantity > 0
                                      ? '$bagQuantity in bag'
                                      : 'per item',
                                  style: TextStyle(
                                    color: bagQuantity > 0
                                        ? ProtoColors.lime
                                        : ProtoColors.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (flavor != null)
                                  Expanded(
                                    child: Text(
                                      ' · $flavor',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: ProtoColors.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'QUANTITY',
                            style: TextStyle(
                              color: ProtoColors.muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 124,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ProtoColors.elevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ProtoColors.border),
                            ),
                            child: Row(
                              children: [
                                _SelectionButton(
                                  tooltip: 'Decrease quantity',
                                  icon: Icons.remove_rounded,
                                  onPressed: onDecrease,
                                ),
                                Expanded(
                                  child: Semantics(
                                    label: 'Selected quantity',
                                    value: '$selectedQuantity',
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$selectedQuantity',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _SelectionButton(
                                  tooltip: 'Increase quantity',
                                  icon: Icons.add_rounded,
                                  onPressed: onIncrease,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => controller.add(
                              product,
                              flavor: flavor,
                              quantity: selectedQuantity,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: ProtoColors.lime,
                              foregroundColor: ProtoColors.background,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                            ),
                            label: const Text(
                              'Add to bag',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/bag'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ProtoColors.text,
                            side: const BorderSide(color: ProtoColors.border),
                            minimumSize: const Size(106, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'View bag',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    color: ProtoColors.lime,
    disabledColor: ProtoColors.muted.withValues(alpha: .4),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    style: IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      maximumSize: const Size(40, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
