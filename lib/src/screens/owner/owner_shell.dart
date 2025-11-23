import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../controllers/restaurant_controller.dart';
import '../../core/session/session_controller.dart';
import 'owner_dashboard_screen.dart';
import 'owner_map_screen.dart';
import 'owner_profile_screen.dart';
import 'restaurant_setup_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;

  final _pages = const [
    OwnerDashboardScreen(),
    OwnerMapScreen(),
    OwnerProfileScreen(),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().state;
    final ownerId = session.profile?.id;
    final controller = context.watch<RestaurantController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (ownerId != null) {
      final restaurant = controller.getByOwnerIdOrNull(ownerId);
      if (restaurant == null) {
        return const RestaurantSetupScreen();
      }
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

