import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.mood), label: 'Mood'),
          NavigationDestination(icon: Icon(Icons.book), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/mood')) return 1;
    if (location.startsWith('/journal')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/home');
      case 1: context.go('/mood');
      case 2: context.go('/journal');
      case 3: context.go('/reports');
      case 4: context.go('/settings');
    }
  }
}
