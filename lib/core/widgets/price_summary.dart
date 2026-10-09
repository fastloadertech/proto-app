import 'package:flutter/material.dart';
import '../formatters/currency.dart';
import '../theme/proto_theme.dart';

/// A single price breakdown shared by bag, checkout, and order screens.
class PriceSummary extends StatelessWidget {
  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    this.savings = 0,
    this.discount = 0,
    this.title = 'Price breakdown',
  });
  final double subtotal;
  final double deliveryFee;
  final double savings;
  final double discount;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        _PriceRow(label: 'Subtotal', value: formatPrice(subtotal)),
        const SizedBox(height: 14),
        _PriceRow(
          label: 'Delivery fee',
          value: deliveryFee == 0 ? 'FREE' : formatPrice(deliveryFee),
          accent: deliveryFee == 0,
        ),
        if (savings > 0) ...[
          const SizedBox(height: 14),
          _PriceRow(
            label: 'You’re saving',
            value: formatPrice(savings),
            accent: true,
          ),
        ],
        if (discount > 0) ...[
          const SizedBox(height: 14),
          _PriceRow(
            label: 'Coupon discount',
            value: '−${formatPrice(discount)}',
            accent: true,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 17),
          child: Divider(height: 1),
        ),
        _PriceRow(
          label: 'Total',
          value: formatPrice(subtotal + deliveryFee - discount),
          total: true,
        ),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.accent = false,
    this.total = false,
  });
  final String label, value;
  final bool accent, total;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: total ? 17 : 13,
            fontWeight: total ? FontWeight.w700 : FontWeight.w400,
            color: total ? ProtoColors.text : ProtoColors.muted,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: total ? 23 : 13,
            fontWeight: FontWeight.w700,
            color: accent ? ProtoColors.lime : ProtoColors.text,
          ),
        ),
      ),
    ],
  );
}
