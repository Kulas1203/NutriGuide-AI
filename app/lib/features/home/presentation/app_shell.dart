import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/motion.dart';

/// Bottom-navigation shell for the five primary destinations. Tab changes use
/// a fade-through so switching feels seamless rather than jarring.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (
      path: '/home',
      icon: Icons.home_outlined,
      selected: Icons.home_rounded,
      label: 'Home',
    ),
    (
      path: '/plan',
      icon: Icons.restaurant_menu_outlined,
      selected: Icons.restaurant_menu,
      label: 'Plan',
    ),
    (
      path: '/log',
      icon: Icons.edit_note_outlined,
      selected: Icons.edit_note,
      label: 'Log',
    ),
    (
      path: '/coach',
      icon: Icons.forum_outlined,
      selected: Icons.forum_rounded,
      label: 'Coach',
    ),
    (
      path: '/progress',
      icon: Icons.insights_outlined,
      selected: Icons.insights_rounded,
      label: 'Progress',
    ),
  ];

  int _indexFor(String location) {
    final i = _destinations.indexWhere((d) => location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    return Scaffold(
      body: FadeThroughSwitcher(switchKey: index, child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
