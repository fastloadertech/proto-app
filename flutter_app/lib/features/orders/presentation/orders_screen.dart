import 'package:flutter/material.dart';

import '../../../core/formatters/currency.dart';
import '../../../core/formatters/order_date.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/proto_button.dart';
import '../domain/order.dart';
import 'order_status_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The repository keeps newest orders first, including orders placed in
    // the same clock tick. Keep that ordering instead of re-sorting ties.
    final orders = AppScope.of(context).orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FUEL. REPEAT.',
                          style: TextStyle(
                            color: ProtoColors.lime,
                            fontSize: 10,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Your momentum,\non record.',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          orders.isEmpty
                              ? 'Your next routine starts with your first bag.'
                              : '${orders.length} ${orders.length == 1 ? 'order' : 'orders'} in this local session.',
                          style: const TextStyle(
                            color: ProtoColors.muted,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ProtoColors.lime.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ProtoColors.lime.withValues(alpha: .15),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.science_outlined,
                                color: ProtoColors.lime,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Local demo orders. No payment is collected or delivery arranged.',
                                  style: TextStyle(
                                    color: ProtoColors.lime,
                                    fontSize: 11,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (orders.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyOrders())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: SliverList.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _OrderCard(order: orders[index]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: ProtoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ProtoColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: ProtoColors.lime.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: ProtoColors.lime,
              size: 34,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'A fresh start.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Place a demo order from your bag to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ProtoColors.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 26),
          ProtoButton(
            label: 'Explore the shop',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/shop', (_) => false),
          ),
        ],
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ProtoOrder order;

  @override
  Widget build(BuildContext context) => Material(
    color: ProtoColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: ProtoColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderStatusScreen(orderId: order.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ProtoColors.lime.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: const TextStyle(
                      color: ProtoColors.lime,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              formatOrderDate(order.createdAt),
              style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 19),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (final item in order.items.take(3))
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEEE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ProductArtwork(
                      product: item.product,
                      size: 60,
                      showGlow: false,
                    ),
                  ),
                if (order.items.length > 3)
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ProtoColors.elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${order.items.length - 3}',
                      style: const TextStyle(
                        color: ProtoColors.lime,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order.items.map((item) => item.product.name).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatPrice(order.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'} · ${order.paymentMethod.label}',
                        style: const TextStyle(
                          color: ProtoColors.muted,
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View details',
                      style: TextStyle(
                        color: ProtoColors.lime,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: ProtoColors.lime,
                      size: 21,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
