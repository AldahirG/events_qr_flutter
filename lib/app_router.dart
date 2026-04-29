// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/show_info_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/splash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router notifier – bridges Riverpod auth state to GoRouter's refreshListenable
// ─────────────────────────────────────────────────────────────────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final isInitial = auth.status == AuthStatus.initial;
    final isAuthenticated = auth.status == AuthStatus.authenticated;
    final isOnSplash = state.matchedLocation == '/splash';
    final isOnLogin = state.matchedLocation == '/login';

    if (isInitial || isOnSplash) return null;
    if (!isAuthenticated && !isOnLogin) return '/login';
    if (isAuthenticated && isOnLogin) return '/home';
    return null;
  }
}

// Provider (not ChangeNotifierProvider) – ref.listen is the Riverpod-3-safe way
// to wire auth state changes to GoRouter's refreshListenable.
final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.listen<AuthState>(authProvider, (_, __) => notifier.notifyListeners());
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// Router provider – single GoRouter instance for the entire app
// ─────────────────────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.1, end: 1.0).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              ),
        ),
      ),

      // ── Protected routes (with BottomNavigationBar) ──────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
          GoRoute(path: '/list', builder: (c, s) => const ListScreen()),
          GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
          GoRoute(path: '/reportes', builder: (c, s) => const ReportesScreen()),
          GoRoute(
            path: '/show-info/:id',
            builder: (c, s) {
              final id = int.tryParse(s.pathParameters['id']!) ?? 0;
              return ShowInfoScreen(id: id);
            },
          ),
        ],
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation scaffold
// ─────────────────────────────────────────────────────────────────────────────
const _tabPaths = ['/home', '/scanner', '/list', '/register', '/reportes'];

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  int _locationToIndex(String location) {
    final idx = _tabPaths.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  void _onItemTapped(BuildContext context, int index) {
    final path = _tabPaths[index];
    final current = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    if (current != path) GoRouter.of(context).go(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    final currentIndex = _locationToIndex(current);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onItemTapped(context, i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scanner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded), label: 'Registros'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_add_alt_1_rounded), label: 'Registrar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded), label: 'Reportes'),
        ],
      ),
    );
  }
}
