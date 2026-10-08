import 'package:flutter/material.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/formatters/order_date.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/price_summary.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/proto_button.dart';
import '../domain/order.dart';
import 'widgets/order_timeline.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key, required this.orderId});

  final String orderId;

  void _advance(BuildContext context, AppController app, String id) {
    try {
      app.advanceOrderStatus(id);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _cancel(
    BuildContext context,
    AppController app,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
          'This local demo order will stay in your history as cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      app.cancelOrder(id);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

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
              child: _OrderLoader(
                orderId: orderId,
                builder: (order, refresh) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusHero(order: order),
                    const SizedBox(height: 24),
                    OrderTimeline(order: order),
                    const SizedBox(height: 18),
                    if (order.isLive)
                      ProtoButton(
                        label: 'Refresh status',
                        icon: Icons.refresh_rounded,
                        onPressed: refresh,
                      )
                    else
                      ProtoButton(
                        label: 'Advance demo status',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: order.status.isTerminal
                            ? null
                            : () => _advance(context, app, order.id),
                      ),
                    if (!order.isLive && order.status.canCancel) ...[
                      const SizedBox(height: 10),
                      ProtoButton(
                        label: 'Cancel order',
                        outlined: true,
                        onPressed: () => _cancel(context, app, order.id),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      order.isLive
                          ? 'Status comes from your order in the shared backend. Live location is not available yet.'
                          : order.status.isTerminal
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
                    if (order.deliveryAssignment != null) ...[
                      const SizedBox(height: 18),
                      _DriverDetails(assignment: order.deliveryAssignment!),
                    ],
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
      ),
    );
  }
}

class _OrderLoader extends StatefulWidget {
  const _OrderLoader({required this.orderId, required this.builder});

  final String orderId;
  final Widget Function(ProtoOrder, VoidCallback) builder;

  @override
  State<_OrderLoader> createState() => _OrderLoaderState();
}

class _OrderLoaderState extends State<_OrderLoader> {
  Future<ProtoOrder?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).loadOrder(widget.orderId);
  }

  @override
  void didUpdateWidget(covariant _OrderLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      _future = AppScope.of(context).loadOrder(widget.orderId);
    }
  }

  void _retry() {
    setState(() {
      _future = AppScope.of(context).loadOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ProtoOrder?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const _OrderLoading();
      }
      if (snapshot.hasError) return _OrderError(onRetry: _retry);
      final order = AppScope.of(context).orderById(widget.orderId);
      return order == null
          ? const _UnknownOrder()
          : widget.builder(order, _retry);
    },
  );
}

class _OrderLoading extends StatelessWidget {
  const _OrderLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 76),
    child: Column(
      children: [
        CircularProgressIndicator(color: ProtoColors.lime),
        SizedBox(height: 22),
        Text(
          'Finding your order…',
          style: TextStyle(color: ProtoColors.muted, fontSize: 13),
        ),
      ],
    ),
  );
}

class _OrderError extends StatelessWidget {
  const _OrderError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.border),
    ),
    child: Column(
      children: [
        const Icon(Icons.wifi_off_rounded, color: ProtoColors.lime, size: 36),
        const SizedBox(height: 16),
        const Text(
          'Order details are unavailable right now.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your bag and order history are safe in this session.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ProtoColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        ProtoButton(label: 'Try again', onPressed: onRetry),
      ],
    ),
  );
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
            orderStatusIcon(order.status),
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
          order.isLive
              ? switch (order.status) {
                  OrderStatus.pending => 'Your order was received by Proto.',
                  OrderStatus.confirmed => 'Your order is confirmed.',
                  OrderStatus.preparing => 'Your order is being prepared.',
                  OrderStatus.readyForPickup => 'Ready for a delivery partner.',
                  OrderStatus.pickedUp => 'Your order was picked up.',
                  OrderStatus.outForDelivery =>
                    'Your order is out for delivery.',
                  OrderStatus.delivered => 'Your order was delivered.',
                  OrderStatus.cancelled => 'Your order was cancelled.',
                }
              : order.status.description,
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
                order.isLive
                    ? 'Updated ${formatOrderDate(order.updatedAt ?? order.createdAt)}. Delivery ETA and driver location are not available yet.'
                    : order.status == OrderStatus.cancelled
                    ? 'Delivery cancelled · No driver was dispatched.'
                    : 'Sample arrival: ${_arrivalTime(order.estimatedDeliveryAt)}\nNo payment is collected or delivery arranged.',
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
              item.productName,
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
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(
                  '${formatPrice(item.unitPrice)} each',
                  style: const TextStyle(
                    color: ProtoColors.muted,
                    fontSize: 11,
                  ),
                ),
                Text(
                  formatPrice(item.subtotal),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.paymentMethod.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Payment status · ${order.paymentStatus.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ProtoColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DriverDetails extends StatelessWidget {
  const _DriverDetails({required this.assignment});

  final DeliveryAssignment assignment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ProtoColors.lime.withValues(alpha: .25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.delivery_dining_rounded, color: ProtoColors.lime),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Driver assigned',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          assignment.driverName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '${assignment.vehicleType} · ${assignment.vehicleDetails}',
          style: const TextStyle(color: ProtoColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Text(
          'Estimated arrival · ${_arrivalTime(assignment.estimatedArrivalAt)}',
          style: const TextStyle(fontSize: 12, color: ProtoColors.lime),
        ),
        const SizedBox(height: 6),
        Text(
          'Demo contact · ${assignment.contactNumber}',
          style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
        ),
        if (assignment.deliveryJobId != null) ...[
          const SizedBox(height: 6),
          Text(
            'Delivery ID · ${assignment.deliveryJobId}',
            style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
          ),
        ],
        const SizedBox(height: 18),
        ProtoButton(
          label: 'Contact driver',
          outlined: true,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Driver contact is a local preview. No call was placed.',
              ),
            ),
          ),
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
        Text(
          AppScope.of(context).liveOrders
              ? 'This order could not be found in your account.'
              : 'This local order could not be found. Demo orders are available only in the current session.',
          textAlign: TextAlign.center,
          style: const TextStyle(
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

String _arrivalTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
