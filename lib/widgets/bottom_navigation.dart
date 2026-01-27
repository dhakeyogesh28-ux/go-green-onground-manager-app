import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    int idx = loc.startsWith('/notifications') ? 1 : loc.startsWith('/profile') ? 2 : 0;
    return BottomNavigationBar(
      currentIndex: idx,
      onTap: (i) {
        if (i == 0) {
          context.go('/dashboard');
        } else if (i == 1) {
          context.go('/notifications');
        } else if (i == 2) {
          context.go('/profile');
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.bell), label: 'Alerts'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
      ],
    );
  }
}
