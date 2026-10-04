import 'package:flutter/material.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/theme/proto_theme.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/proto_button.dart';
import '../../catalog/presentation/product_detail_screen.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onBrowse,
    required this.onSignIn,
    this.onLogout,
  });
  final VoidCallback onBrowse, onSignIn;
  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _orderUpdates = ValueNotifier<bool>(true);
  final _productOffers = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _orderUpdates.dispose();
    _productOffers.dispose();
    super.dispose();
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProfileSettingsScreen(
        orderUpdates: _orderUpdates,
        productOffers: _productOffers,
      ),
    ),
  );

  void _showAbout() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ProtoColors.surface,
      scrollable: true,
      title: const Text('About Proto'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FUEL. FAST.',
            style: TextStyle(
              color: ProtoColors.lime,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Proto brings protein, nutrition, and everyday fitness essentials '
            'together in a fast shopping experience.',
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            'This customer app is a local demo. Products, availability, '
            'payments, and deliveries are simulated.',
            style: TextStyle(color: ProtoColors.muted, height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  void _confirmLogout() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: ProtoColors.surface,
      scrollable: true,
      title: const Text('Leave the demo?'),
      content: const Text(
        'You will return to sign-in. Your bag, saved addresses, and orders '
        'stay in local memory for this demo session.',
        style: TextStyle(color: ProtoColors.muted, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Stay here'),
        ),
        TextButton(
          onPressed: () {
            AppScope.of(context).signOutDemo();
            Navigator.of(dialogContext).pop();
            (widget.onLogout ?? widget.onSignIn)();
          },
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final saved = app.catalog.products
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
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: ProtoColors.elevated,
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: ProtoColors.lime,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.contact.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+91 ${app.contact.phone} · Demo customer',
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
                      const SizedBox(height: 19),
                      ProtoButton(
                        label: 'Try demo sign-in',
                        onPressed: widget.onSignIn,
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
                      onPressed: widget.onBrowse,
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'More from Proto',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 14),
                _ProfileLink(
                  title: 'Settings',
                  subtitle: 'Preview your local preferences',
                  icon: Icons.tune_rounded,
                  onTap: _openSettings,
                ),
                const SizedBox(height: 12),
                _ProfileLink(
                  title: 'About Proto',
                  subtitle: 'Fuel your next level',
                  icon: Icons.info_outline_rounded,
                  onTap: _showAbout,
                ),
                const SizedBox(height: 12),
                _ProfileLink(
                  title: 'Log out',
                  subtitle: 'Return to demo sign-in',
                  icon: Icons.logout_rounded,
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'PROTO / DAY 5\nLocal catalog · Bag, addresses & demo orders',
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

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: ProtoColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: ProtoColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: ProtoColors.lime, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
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
  );
}
