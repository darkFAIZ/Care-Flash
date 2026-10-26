import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../account/profile_tab.dart';
import '../earnings/earnings_tab.dart';
import '../feedback/feedback_tab.dart';
import 'home_tab.dart';

/// The signed-in shell with bottom navigation: Requests, Earnings, Feedback,
/// Profile.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  static const String route = '/home';

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingRequestProvider, (previous, next) {
      final booking = next.value;
      if (booking == null || previous?.value?.id == booking.id) return;

      setState(() => _index = 0);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('New care request ${booking.requestReference}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => setState(() => _index = 0),
            ),
            duration: const Duration(seconds: 8),
          ),
        );
    });
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeTab(),
          EarningsTab(),
          FeedbackTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox_rounded),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Feedback',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
