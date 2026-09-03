import 'package:flutter/material.dart';
import '../services/app_store.dart';
import 'home_screen.dart';
import 'appointments_screen.dart';
import 'portfolio_screen.dart';
import 'aftercare_screen.dart';
import 'account_screen.dart';

class AppShell extends StatefulWidget {
  final AppStore store;
  const AppShell({super.key, required this.store});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(store: widget.store, onAppointments: () => setState(() => index = 1)),
      AppointmentsScreen(store: widget.store),
      const PortfolioScreen(),
      const AftercareScreen(),
      AccountScreen(store: widget.store),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Afspraken'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Portfolio'),
          NavigationDestination(icon: Icon(Icons.healing_outlined), selectedIcon: Icon(Icons.healing), label: 'Nazorg'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
