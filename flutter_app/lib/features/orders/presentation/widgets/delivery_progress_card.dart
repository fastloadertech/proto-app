import 'package:flutter/material.dart';

import '../../../../core/formatters/order_date.dart';
import '../../../../core/theme/proto_theme.dart';
import '../../../../core/widgets/proto_button.dart';
import '../../domain/delivery_status.dart';
import '../../domain/order.dart';

/// Read-only customer view of the linked backend delivery job.
class DeliveryProgressCard extends StatelessWidget {
  const DeliveryProgressCard({
    super.key,
    required this.order,
    required this.onRetry,
  });

  final ProtoOrder order;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final delivery = order.delivery;
    final issue = order.deliveryIssue;
    const stages = DeliveryStatus.day12Stages;
    final currentIndex = delivery == null
        ? -1
        : stages.indexOf(delivery.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProtoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProtoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Delivery progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (delivery == null) ...[
            Text(
              order.status == OrderStatus.cancelled
                  ? 'This order is cancelled. No delivery is linked.'
                  : order.status == OrderStatus.delivered
                  ? 'This order is marked delivered, but no delivery record is linked.'
                  : 'No delivery has been linked to this order yet.',
              style: const TextStyle(color: ProtoColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            ProtoButton(
              label: 'Check again',
              outlined: true,
              onPressed: onRetry,
            ),
          ] else ...[
            Text(
              issue != null
                  ? delivery.hasDetails
                        ? 'Last confirmed delivery status'
                        : 'Status from order detail'
                  : 'Current backend delivery status',
              style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 5),
            Text(
              delivery.status.label,
              style: const TextStyle(
                color: ProtoColors.lime,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              delivery.status.description,
              style: const TextStyle(
                color: ProtoColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delivery ID · ${delivery.id}',
              style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
            ),
            if (delivery.hasDetails && delivery.updatedAt != null) ...[
              const SizedBox(height: 5),
              Text(
                'Updated ${formatOrderDate(delivery.updatedAt!)}',
                style: const TextStyle(color: ProtoColors.muted, fontSize: 11),
              ),
            ],
            if (issue != null) ...[
              const SizedBox(height: 15),
              Text(
                _issueMessage(issue, hasDetails: delivery.hasDetails),
                style: const TextStyle(
                  color: ProtoColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ProtoButton(
                label: issue == DeliveryIssue.authentication
                    ? 'Sign in again'
                    : 'Retry delivery status',
                outlined: true,
                onPressed: issue == DeliveryIssue.authentication
                    ? () => Navigator.of(context).pushNamed('/login')
                    : onRetry,
              ),
            ],
            if (currentIndex >= 0) ...[
              const SizedBox(height: 18),
              for (var index = 0; index < stages.length; index++)
                _DeliveryStage(
                  stage: stages[index],
                  current: index == currentIndex,
                  earlier: index < currentIndex,
                  confirmedAt: _confirmedAt(delivery, stages[index]),
                  stale: issue != null,
                  hasDetails: delivery.hasDetails,
                ),
            ],
            const SizedBox(height: 5),
            const Text(
              'Status refreshes when you open this order or tap Refresh. No live location is available.',
              style: TextStyle(
                color: ProtoColors.muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _confirmedAt(DeliverySnapshot delivery, DeliveryStatus stage) =>
      switch (stage) {
        DeliveryStatus.accepted => delivery.acceptedAt,
        DeliveryStatus.pickedUp => delivery.pickedUpAt,
        DeliveryStatus.delivered => delivery.deliveredAt,
        _ => null,
      };

  String _issueMessage(DeliveryIssue issue, {required bool hasDetails}) {
    final retained = hasDetails
        ? 'Last loaded delivery details are shown.'
        : 'The status from the order detail is shown.';
    return switch (issue) {
      DeliveryIssue.authentication =>
        'Delivery details require a valid customer session. $retained Sign in again, then retry.',
      DeliveryIssue.missing =>
        'This delivery could not be found. $retained Try refreshing.',
      DeliveryIssue.network =>
        'Could not reach the delivery service. $retained Check your connection and retry.',
      DeliveryIssue.server =>
        'Delivery details are temporarily unavailable. $retained Try again.',
      DeliveryIssue.invalid =>
        'Delivery details could not be read. $retained Try again.',
    };
  }
}

class _DeliveryStage extends StatelessWidget {
  const _DeliveryStage({
    required this.stage,
    required this.current,
    required this.earlier,
    required this.confirmedAt,
    required this.stale,
    required this.hasDetails,
  });

  final DeliveryStatus stage;
  final bool current, earlier;
  final DateTime? confirmedAt;
  final bool stale, hasDetails;

  @override
  Widget build(BuildContext context) {
    final confirmed = confirmedAt != null && (earlier || current);
    final caption = current
        ? stale
              ? hasDetails
                    ? 'Last confirmed delivery status'
                    : 'Status from order detail'
              : 'Current backend status'
        : earlier
        ? confirmed
              ? 'Confirmed by delivery record'
              : 'Earlier stage inferred from current status'
        : 'Not reported yet';
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            current
                ? Icons.radio_button_checked_rounded
                : confirmed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 19,
            color: current || confirmed ? ProtoColors.lime : ProtoColors.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.label,
                  style: TextStyle(
                    color: current || earlier
                        ? ProtoColors.text
                        : ProtoColors.muted,
                    fontSize: 12,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  confirmed
                      ? '$caption · ${formatOrderDate(confirmedAt!)}'
                      : caption,
                  style: const TextStyle(
                    color: ProtoColors.muted,
                    fontSize: 10,
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
}
