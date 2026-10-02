import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/proto_button.dart';
import '../../catalog/data/local_catalog_repository.dart';
import '../../catalog/presentation/product_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onBrowse,
    required this.onSignIn,
  });
  final VoidCallback onBrowse, onSignIn;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final saved = LocalCatalogRepository.products
        .where((product) => app.isSaved(product.id))
        .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROGRESS IS PERSONAL.',
                  style: TextStyle(
                    color: ProtoColors.lime,
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your corner.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: ProtoColors.surface,
                    border: Border.all(color: ProtoColors.border),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: ProtoColors.elevated,
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: ProtoColors.lime,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proto explorer',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Every good routine starts somewhere.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ProtoColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 19),
                      ProtoButton(
                        label: 'Try demo sign-in',
                        onPressed: onSignIn,
                        outlined: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Material(
                  color: ProtoColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: ProtoColors.border),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/orders'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: ProtoColors.lime,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your orders',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${app.orders.length} local demo ${app.orders.length == 1 ? 'order' : 'orders'}',
                                  style: const TextStyle(
                                    color: ProtoColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: ProtoColors.muted,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: ProtoColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: ProtoColors.border),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/addresses'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: ProtoColors.lime,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saved addresses',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${app.savedAddresses.length} local ${app.savedAddresses.length == 1 ? 'address' : 'addresses'} · Delivering to ${app.deliveryAddress.label}',
                                  style: const TextStyle(
                                    color: ProtoColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: ProtoColors.muted,
                            size: 19,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 29),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Saved for later',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${saved.length}',
                      style: const TextStyle(
                        color: ProtoColors.lime,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the heart on a product to keep it close.',
                  style: TextStyle(color: ProtoColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (saved.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: ProtoColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 34,
                      color: ProtoColors.muted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your favorites live here.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ProtoButton(
                      label: 'Explore the catalog',
                      onPressed: onBrowse,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent > 850
                    ? 4
                    : constraints.crossAxisExtent > 600
                    ? 3
                    : 2;
                final cardWidth =
                    (constraints.crossAxisExtent - (columns - 1) * 14) /
                    columns;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: ProductCard.gridExtent(context, cardWidth),
                  ),
                  itemCount: saved.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: saved[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ProductDetailScreen(product: saved[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'PROTO / DAY 4\nLocal catalog · Bag, addresses & demo orders',
              style: TextStyle(
                fontSize: 10,
                color: ProtoColors.muted,
                height: 1.8,
                letterSpacing: .5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
