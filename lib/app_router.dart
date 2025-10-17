// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/show_info_screen.dart';
import 'screens/settings_screen.dart';

// indices para las pestañas
const _tabPaths = [
  '/home',
  '/scanner',
  '/list',
  '/register',
  '/settings',
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Scaffold con BottomNavigationBar
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
        GoRoute(path: '/list', builder: (c, s) => const ListScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        // ruta con parámetro (detalle) fuera de las pestañas pero accesible
        GoRoute(
          path: '/show-info/:id',
          builder: (c, s) {
            final idStr = s.pathParameters['id']!;
            final id = int.tryParse(idStr) ?? 0;
            return ShowInfoScreen(id: id);
          },
        ),
      ],
    ),
  ],
);

// Widget que renderiza el BottomNavigationBar
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  int _locationToIndex(String location) {
    final idx = _tabPaths.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  void _onItemTapped(BuildContext context, int index) {
    final path = _tabPaths[index];
    final currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    if (currentLocation != path) {
      GoRouter.of(context).go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final currentIndex = _locationToIndex(currentLocation);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onItemTapped(context, i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Registros'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Registrar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
