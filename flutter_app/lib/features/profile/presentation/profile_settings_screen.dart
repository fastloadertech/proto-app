import 'package:flutter/material.dart';

import '../../../core/theme/proto_theme.dart';

/// Session-only preferences for the customer demo.
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.orderUpdates,
    required this.productOffers,
  });

  final ValueNotifier<bool> orderUpdates;
  final ValueNotifier<bool> productOffers;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              const Text(
                'MAKE IT YOURS',
                style: TextStyle(
                  color: ProtoColors.lime,
                  fontSize: 10,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your preferences.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These settings are a local preview and reset when you close the app.',
                style: TextStyle(color: ProtoColors.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              _PreferenceTile(
                title: 'Order updates',
                subtitle: 'Preview delivery status alerts',
                icon: Icons.local_shipping_outlined,
                value: orderUpdates,
              ),
              const SizedBox(height: 12),
              _PreferenceTile(
                title: 'Product offers',
                subtitle: 'Preview offers on your favorite fuel',
                icon: Icons.local_offer_outlined,
                value: productOffers,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ValueNotifier<bool> value;

  @override
  Widget build(BuildContext context) => Material(
    color: ProtoColors.surface,
    borderRadius: BorderRadius.circular(16),
    child: ValueListenableBuilder<bool>(
      valueListenable: value,
      builder: (context, selected, _) => SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        secondary: Icon(icon, color: ProtoColors.lime),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: ProtoColors.muted),
        ),
        value: selected,
        onChanged: (next) => value.value = next,
      ),
    ),
  );
}
