import 'package:flutter/material.dart';

import '../core/state/app_controller.dart';
import '../core/theme/proto_theme.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/bag/presentation/bag_screen.dart';
import '../features/catalog/presentation/categories_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.liveAuth = false});
  final bool liveAuth;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final cartCount = AppScope.of(context).cartCount;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: IndexedStack(
              index: _index,
              children: [
                HomeScreen(
                  onBrowseCategories: () => _select(1),
                  onOpenProfile: () => _select(3),
                ),
                const CategoriesScreen(),
                BagScreen(onBrowse: () => _select(0)),
                ProfileScreen(
                  onBrowse: () => _select(0),
                  onSignIn: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => LoginScreen(
                        liveAuth: widget.liveAuth,
                        onDemoSignIn: AppScope.of(context).signInDemo,
                        onApiSignIn: (phone, code) =>
                            AppScope.of(context).signIn(phone, code: code),
                        onContinue: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  onLogout: () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (_) => false),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: MainShellNavigationBar(
        selectedIndex: _index,
        cartCount: cartCount,
        onSelect: _select,
      ),
    );
  }
}

class MainShellNavigationBar extends StatelessWidget {
  const MainShellNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.cartCount,
    required this.onSelect,
  });

  final int selectedIndex;
  final int cartCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: ProtoColors.background,
      border: Border(top: BorderSide(color: ProtoColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavItem(
                  label: 'Shop',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  selected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _NavItem(
                  label: 'Categories',
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                  selected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                _NavItem(
                  label: 'Bag',
                  icon: Icons.shopping_bag_outlined,
                  selectedIcon: Icons.shopping_bag_rounded,
                  selected: selectedIndex == 2,
                  onTap: () => onSelect(2),
                  count: cartCount,
                ),
                _NavItem(
                  label: 'You',
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  selected: selectedIndex == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.count = 0,
  });
  final String label;
  final IconData icon, selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? ProtoColors.lime.withValues(alpha: .1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      selected ? selectedIcon : icon,
                      color: selected ? ProtoColors.lime : ProtoColors.muted,
                      size: 23,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 9,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: ProtoColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: ProtoColors.background,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? ProtoColors.lime : ProtoColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
