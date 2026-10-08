import 'package:flutter/material.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/price_summary.dart';
import '../../../core/widgets/proto_button.dart';
import '../domain/order.dart';
import 'order_status_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  void _continueShopping(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/shop', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final order = AppScope.of(context).orderById(orderId);
    return Scaffold(
      appBar: AppBar(title: const Text('Order placed')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: order == null
                  ? _missingOrder(context)
                  : _confirmation(context, order),
            ),
          ),
        ),
      ),
    );
  }

  Widget _missingOrder(BuildContext context) => Column(
    children: [
      const Icon(
        Icons.receipt_long_outlined,
        size: 48,
        color: ProtoColors.lime,
      ),
      const SizedBox(height: 22),
      const Text(
        'This order isn’t here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        AppScope.of(context).liveOrders
            ? 'Open your order history to load it from your account.'
            : 'Orders are kept locally for this demo.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ProtoColors.muted,
          fontSize: 13,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      ProtoButton(
        label: 'Continue shopping',
        onPressed: () => _continueShopping(context),
      ),
    ],
  );

  Widget _confirmation(BuildContext context, ProtoOrder order) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: ProtoColors.lime.withValues(alpha: .1),
            shape: BoxShape.circle,
            border: Border.all(color: ProtoColors.lime.withValues(alpha: .25)),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: ProtoColors.lime,
            size: 42,
          ),
        ),
      ),
      const SizedBox(height: 25),
      const Text(
        'YOU’RE ALL SET.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ProtoColors.lime,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Good fuel. Great choice.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 31,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Thanks, ${order.contact.name.split(' ').first}. Your ${order.isLive ? 'order is saved to your account' : 'demo order was placed'}.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ProtoColors.muted,
          fontSize: 13,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ProtoColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ORDER DETAILS',
              style: TextStyle(
                color: ProtoColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _ConfirmationDetail(label: 'Order ID', value: order.id),
            const SizedBox(height: 14),
            _ConfirmationDetail(label: 'Status', value: order.status.label),
            if (!order.isLive) ...[
              const SizedBox(height: 14),
              _ConfirmationDetail(
                label: 'Payment',
                value: order.paymentMethod.label,
              ),
              const SizedBox(height: 14),
              _ConfirmationDetail(
                label: 'Payment status',
                value: order.paymentStatus.label,
              ),
            ],
            const SizedBox(height: 14),
            _ConfirmationDetail(label: 'Items', value: '${order.itemCount}'),
            const SizedBox(height: 14),
            _ConfirmationDetail(
              label: 'Delivery fee',
              value: order.deliveryFee == 0
                  ? 'FREE'
                  : formatPrice(order.deliveryFee),
            ),
            const SizedBox(height: 14),
            _ConfirmationDetail(
              label: 'Discount',
              value: order.discount == 0
                  ? formatPrice(0)
                  : '−${formatPrice(order.discount)}',
            ),
            if (order.promoCode != null) ...[
              const SizedBox(height: 14),
              _ConfirmationDetail(label: 'Promo code', value: order.promoCode!),
            ],
            const SizedBox(height: 14),
            _ConfirmationDetail(
              label: 'Final amount',
              value: formatPrice(order.total),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: ProtoColors.lime,
                  size: 23,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.isLive
                            ? 'Order placed · awaiting confirmation'
                            : 'Demo ETA · about ${order.estimatedDeliveryAt.difference(order.createdAt).inMinutes} min',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.isLive
                            ? 'Delivery timing and tracking are not available yet.'
                            : 'A preview of the Proto delivery experience.',
                        style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 11,
                          height: 1.5,
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
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ProtoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ProtoColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your fuel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < order.items.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ProtoColors.elevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${order.items[i].quantity}×',
                      style: const TextStyle(
                        color: ProtoColors.lime,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items[i].productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (order.items[i].flavor != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            order.items[i].flavor!,
                            style: const TextStyle(
                              color: ProtoColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          '${formatPrice(order.items[i].unitPrice)} each',
                          style: const TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatPrice(order.items[i].total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: ProtoColors.lime,
                  size: 19,
                ),
                SizedBox(width: 8),
                Text(
                  'Delivering to',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              order.address.formatted,
              style: const TextStyle(
                color: ProtoColors.muted,
                fontSize: 12,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      PriceSummary(
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        discount: order.discount,
        title: 'Order total',
      ),
      const SizedBox(height: 24),
      ProtoButton(
        label: 'Track order',
        icon: Icons.arrow_forward_rounded,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/order-status'),
            builder: (_) => OrderStatusScreen(orderId: order.id),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ProtoButton(
        label: 'Continue shopping',
        outlined: true,
        onPressed: () => _continueShopping(context),
      ),
      const SizedBox(height: 20),
      Text(
        order.isLive
            ? 'Saved to the shared backend · No payment or delivery dispatch yet.'
            : 'Local demo · No real payment or delivery takes place.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ProtoColors.muted,
          fontSize: 10,
          height: 1.6,
        ),
      ),
    ],
  );
}

class _ConfirmationDetail extends StatelessWidget {
  const _ConfirmationDetail({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: ProtoColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
