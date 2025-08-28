import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_financas/core/constants.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget child;
  const AdaptiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;

        // Itens da navegação principal
        const navItems = <_NavItem>[
          _NavItem('dashboard', Icons.home_rounded, 'Início'),
          _NavItem('transactions', Icons.swap_horiz_rounded, 'Transações'),
          _NavItem('categories', Icons.category_rounded, 'Categorias'),
          _NavItem('budgets', Icons.flag_rounded, 'Budgets'),
          _NavItem('settings', Icons.settings_rounded, 'Ajustes'),
        ];

        // localização atual via GoRouter
        final location = GoRouterState.of(context).uri.toString();
        final selectedIndex = _indexFromRoute(location, navItems);

        if (width < Breakpoints.compact) {
          // Mobile: usa NavigationBar
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => context.goNamed(navItems[i].routeName),
              destinations: [
                for (final it in navItems)
                  NavigationDestination(icon: Icon(it.icon), label: it.label),
              ],
            ),
          );
        }

        // Tablet/Desktop: usa NavigationRail
        final extended = width >= Breakpoints.medium;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) => context.goNamed(navItems[i].routeName),
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                extended: extended,
                destinations: [
                  for (final it in navItems)
                    NavigationRailDestination(
                      icon: Icon(it.icon),
                      label: Text(it.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

int _indexFromRoute(String location, List<_NavItem> items) {
  final idx = items.indexWhere(
    (e) =>
        (location == '/' && e.routeName == 'dashboard') || location.startsWith('/${e.routeName}'),
  );
  return idx == -1 ? 0 : idx;
}

class _NavItem {
  final String routeName;
  final IconData icon;
  final String label;
  const _NavItem(this.routeName, this.icon, this.label);
}
