import 'package:flutter/material.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/formatters/order_date.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/price_summary.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/proto_button.dart';
import '../domain/order.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final order = app.orderById(orderId);

    return Scaffold(
      appBar: AppBar(title: const Text('Order status')),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: order == null
                  ? const _UnknownOrder()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusHero(order: order),
                        const SizedBox(height: 24),
                        _StatusTimeline(status: order.status),
                        const SizedBox(height: 18),
                        ProtoButton(
                          label: 'Advance demo status',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: order.status == OrderStatus.delivered
                              ? null
                              : () => app.advanceOrderStatus(order.id),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          order.status == OrderStatus.delivered
                              ? 'Demo timeline complete. No real delivery was made.'
                              : 'You control this demo timeline. No live tracking is connected.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 10,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _OrderContents(order: order),
                        const SizedBox(height: 18),
                        _DeliveryDetails(order: order),
                        const SizedBox(height: 18),
                        PriceSummary(
                          subtotal: order.subtotal,
                          deliveryFee: order.deliveryFee,
                          discount: order.discount,
                          title: 'Order summary',
                        ),
                        const SizedBox(height: 24),
                        ProtoButton(
                          label: 'Continue shopping',
                          outlined: true,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/shop', (_) => false),
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

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.order});

  final ProtoOrder order;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ProtoColors.lime.withValues(alpha: .10), ProtoColors.surface],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: ProtoColors.lime.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.id,
                style: const TextStyle(
                  color: ProtoColors.lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: ProtoColors.lime.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'LOCAL DEMO',
                style: TextStyle(
                  color: ProtoColors.lime,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Placed ${formatOrderDate(order.createdAt)}',
          style: const TextStyle(color: ProtoColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 28),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: ProtoColors.lime,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            _statusIcon(order.status),
            color: ProtoColors.background,
            size: 32,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          order.status.label,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          order.status.description,
          style: const TextStyle(
            color: ProtoColors.muted,
            fontSize: 13,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 22),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.schedule_rounded,
              color: ProtoColors.lime,
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Sample arrival: ${_arrivalTime(order.estimatedDeliveryAt)}\nNo payment is collected or delivery arranged.',
                style: const TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 11,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demo timeline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        for (final step in OrderStatus.values)
          _TimelineStep(
            step: step,
            completed: step.index < status.index,
            active: step == status,
            last: step == OrderStatus.delivered,
          ),
      ],
    ),
  );
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.completed,
    required this.active,
    required this.last,
  });

  final OrderStatus step;
  final bool completed, active, last;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: active || completed
                      ? ProtoColors.lime
                      : ProtoColors.elevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active || completed
                        ? ProtoColors.lime
                        : ProtoColors.border,
                  ),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : _statusIcon(step),
                  color: active || completed
                      ? ProtoColors.background
                      : ProtoColors.muted,
                  size: 17,
                ),
              ),
              if (!last) ...[
                const SizedBox(height: 6),
                Container(
                  width: 2,
                  height: 26,
                  color: completed ? ProtoColors.lime : ProtoColors.border,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                step.label,
                style: TextStyle(
                  color: active || completed
                      ? ProtoColors.text
                      : ProtoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                active
                    ? 'Current demo stage'
                    : completed
                    ? 'Completed in demo'
                    : 'Next in the demo timeline',
                style: TextStyle(
                  color: active ? ProtoColors.lime : ProtoColors.muted,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OrderContents extends StatelessWidget {
  const _OrderContents({required this.order});

  final ProtoOrder order;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your fuel · ${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < order.items.length; index++) ...[
          _ItemRow(item: order.items[index]),
          if (index < order.items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
        ],
      ],
    ),
  );
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 68,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFECEEE7),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: ProductArtwork(product: item.product, size: 64, showGlow: false),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.product.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              [
                if (item.flavor != null) item.flavor!,
                'Qty ${item.quantity}',
              ].join(' · '),
              style: const TextStyle(
                color: ProtoColors.muted,
                fontSize: 10,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatPrice(item.total),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.order});

  final ProtoOrder order;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on_outlined, color: ProtoColors.lime, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delivery details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '${order.contact.name} · ${order.address.label}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          order.address.formatted,
          style: const TextStyle(
            color: ProtoColors.muted,
            fontSize: 12,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          order.contact.phone,
          style: const TextStyle(color: ProtoColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: ProtoColors.muted,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${order.paymentMethod.label}\nDemo selection · No charge made',
                style: const TextStyle(
                  fontSize: 11,
                  color: ProtoColors.muted,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _UnknownOrder extends StatelessWidget {
  const _UnknownOrder();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          color: ProtoColors.lime,
          size: 40,
        ),
        const SizedBox(height: 24),
        const Text(
          'Order unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This local order could not be found. Demo orders are available only in the current session.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: ProtoColors.muted,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 26),
        ProtoButton(
          label: 'Return to shop',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/shop', (_) => false),
        ),
      ],
    ),
  );
}

IconData _statusIcon(OrderStatus status) => switch (status) {
  OrderStatus.orderPlaced => Icons.receipt_long_outlined,
  OrderStatus.confirmed => Icons.verified_outlined,
  OrderStatus.preparing => Icons.inventory_2_outlined,
  OrderStatus.outForDelivery => Icons.delivery_dining_rounded,
  OrderStatus.delivered => Icons.check_rounded,
};

String _arrivalTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
