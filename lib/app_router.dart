// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/app_theme.dart';
import 'providers/app_event_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/evento_activo_provider.dart';
import 'providers/registro_conferencia_provider.dart';
import 'screens/event_selector_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/show_info_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router notifier – bridges Riverpod auth state to GoRouter's refreshListenable
// ─────────────────────────────────────────────────────────────────────────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final eventConfirmed = _ref.read(eventConfirmedProvider);
    final isInitial = auth.status == AuthStatus.initial;
    final isAuthenticated = auth.status == AuthStatus.authenticated;
    final loc = state.matchedLocation;

    // Must pick an event before anything else.
    if (!eventConfirmed) {
      return loc == '/event-selector' ? null : '/event-selector';
    }
    if (loc == '/event-selector') return '/splash';

    if (isInitial || loc == '/splash') return null;
    if (!isAuthenticated && loc != '/login') return '/login';
    if (isAuthenticated && loc == '/login') return '/home';
    return null;
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.listen<AuthState>(authProvider, (_, __) => notifier.notifyListeners());
  ref.listen<bool>(eventConfirmedProvider, (_, __) => notifier.notifyListeners());
  ref.onDispose(notifier.dispose);
  return notifier;
});

// ─────────────────────────────────────────────────────────────────────────────
// Router provider
// ─────────────────────────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/event-selector',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EventSelectorScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
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
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
          GoRoute(path: '/list', builder: (c, s) => const ListScreen()),
          GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
          GoRoute(path: '/reportes', builder: (c, s) => const ReportesScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
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
const _tabPaths = [
  '/home',
  '/list',
  '/register',
  '/scanner',
  '/reportes',
  '/settings',
];

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithNavBar({required this.child, super.key});

  int _locationToIndex(String location) {
    // /show-info sub-route belongs to the list tab
    if (location.startsWith('/show-info')) return 1;
    final idx = _tabPaths.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    final currentIndex = _locationToIndex(current);

    final activeEvent = ref.watch(appEventProvider);
    final isHalloween = activeEvent == AppEvent.halloween;

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thin event indicator strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: activeEvent == AppEvent.halloween
                ? const Color(0xFF1A0A2E)
                : AppColors.primaryDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  activeEvent == AppEvent.halloween
                      ? Icons.whatshot_rounded
                      : Icons.event_rounded,
                  size: 12,
                  color: activeEvent == AppEvent.halloween
                      ? const Color(0xFFFF6D00)
                      : Colors.white70,
                ),
                const SizedBox(width: 5),
                Text(
                  activeEvent.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    color: activeEvent == AppEvent.halloween
                        ? const Color(0xFFE8D5FF)
                        : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          final path = _tabPaths[i];
          if (current != path) GoRouter.of(context).go(path);
          // Refresh registros whenever home tab is selected (stale data).
          if (i == 0) {
            final evento = ref.read(eventoActivoProvider).eventoSeleccionado;
            if (evento.isNotEmpty) {
              ref.read(registroConferenciaProvider.notifier).refresh();
            }
          }
        },
        backgroundColor:
            isHalloween ? HalloweenColors.surface : AppColors.card,
        indicatorColor: isHalloween
            ? HalloweenColors.secondary.withValues(alpha: 0.2)
            : AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Registros',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1_outlined),
            selectedIcon: Icon(Icons.person_add_alt_1_rounded),
            label: 'Registrar',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg_rounded),
            label: 'Asistencias',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
        ], // Column children end
      ), // Column end
    );
  }
}
