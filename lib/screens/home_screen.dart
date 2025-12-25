import 'package:flutter/material.dart';
import '../l10n/gen/app_localizations.dart';
import 'detect_screen.dart';
import 'weather_screen.dart';
import 'map_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DetectScreen(),
    const WeatherScreen(),
    const MapScreen(),
    const InfoScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.diagnosis,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud),
            label: l10n.weather,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map),
            label: l10n.map,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_books),
            label: l10n.info,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
