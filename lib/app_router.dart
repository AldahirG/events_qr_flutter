import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens principales
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/show_info_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/splash_screen.dart';

// Índices para las pestañas
const _tabPaths = [
  '/home',
  '/scanner',
  '/list',
  '/register',
  '/reportes',
];

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // =====================================
    // 🎃 Splash Screen con animación personalizada
    // =====================================
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionDuration: const Duration(milliseconds: 900),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.1, end: 1.0)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
    ),

    // =====================================
    // 🧭 Rutas principales dentro del ShellRoute (con BottomNavigationBar)
    // =====================================
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
        GoRoute(path: '/list', builder: (c, s) => const ListScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
        GoRoute(path: '/reportes', builder: (c, s) => const ReportesScreen()),

        // 📋 Pantalla de detalle (sin tabs)
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

// =====================================================
// 🧱 Widget con el BottomNavigationBar
// =====================================================
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  int _locationToIndex(String location) {
    final idx = _tabPaths.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  void _onItemTapped(BuildContext context, int index) {
    final path = _tabPaths[index];
    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    if (currentLocation != path) {
      GoRouter.of(context).go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    final currentIndex = _locationToIndex(currentLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onItemTapped(context, i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A2E), // 🟣 tono oscuro Halloween
        selectedItemColor: Colors.orangeAccent, // 🎃 color temático
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Registros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Registrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}
