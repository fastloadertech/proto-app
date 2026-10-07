import 'package:flutter/material.dart';

import '../../../../core/theme/proto_theme.dart';
import '../../domain/order.dart';

/// Renders repository-provided progress without owning or advancing status.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final ProtoOrder order;

  @override
  Widget build(BuildContext context) {
    final steps = order.status == OrderStatus.cancelled
        ? [
            ...order.statusHistory.where(
              (step) => step != OrderStatus.cancelled,
            ),
            OrderStatus.cancelled,
          ]
        : OrderStatus.deliveryStages;
    return Container(
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
            'Delivery progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < steps.length; index++)
            _TimelineStep(
              step: steps[index],
              completed: index < steps.indexOf(order.status),
              active: steps[index] == order.status,
              last: index == steps.length - 1,
            ),
        ],
      ),
    );
  }
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
                  completed ? Icons.check_rounded : orderStatusIcon(step),
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

IconData orderStatusIcon(OrderStatus status) => switch (status) {
  OrderStatus.pending => Icons.receipt_long_outlined,
  OrderStatus.confirmed => Icons.verified_outlined,
  OrderStatus.preparing => Icons.inventory_2_outlined,
  OrderStatus.outForDelivery => Icons.delivery_dining_rounded,
  OrderStatus.delivered => Icons.check_rounded,
  OrderStatus.cancelled => Icons.close_rounded,
};
