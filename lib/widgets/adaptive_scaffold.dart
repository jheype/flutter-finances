import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  const AdaptiveScaffold({super.key, required this.child});

  static const _items = [
    _NavItem(icon: Icons.home_outlined, route: '/'),
    _NavItem(icon: Icons.receipt_long_outlined, route: '/transactions'),
    _NavItem(icon: Icons.category_outlined, route: '/categories'),
    _NavItem(icon: Icons.flag_outlined, route: '/budgets'),
  ];

  String _currentLocation(BuildContext context) {
    final provider = GoRouter.of(context).routeInformationProvider;
    return provider.value.uri.toString();
  }

  int _indexFromLocation(String loc) {
    final idx = _items.indexWhere((e) => e.route == loc);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _indexFromLocation(_currentLocation(context));

    return Scaffold(
      extendBody: true,
      body: SafeArea(child: child),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(height: 66)),
              Container(
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xCC141416),
                  borderRadius: BorderRadius.circular(26),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_items.length, (i) {
                    final it = _items[i];
                    final isSel = i == selected;
                    return _BottomItem(
                      icon: it.icon,
                      selected: isSel,
                      onTap: () {
                        if (!isSel) context.go(it.route);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _BottomItem({required this.icon, required this.selected, required this.onTap});

  static const _kAnim = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    const inactive = Color(0xFF9E9E9E);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: _kAnim,
              curve: Curves.easeOut,
              scale: selected ? 1.18 : 1.0,
              child: Icon(icon, size: 24, color: selected ? Colors.white : inactive),
            ),
            AnimatedContainer(
              duration: _kAnim,
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(top: 6),
              width: selected ? 5 : 0,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String route;
  const _NavItem({required this.icon, required this.route});
}
