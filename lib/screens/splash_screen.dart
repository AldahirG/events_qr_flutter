// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _startSplash();
  }

  Future<void> _startSplash() async {
    // Start auth check and animation in parallel – TickerFuture can't go in
    // Future.wait, so kick off the animation and await each separately.
    final authFuture = ref.read(authProvider.notifier).initialize();
    _fadeController.forward(); // fire-and-forget (TickerFuture)
    await authFuture;
    _navigateAway();
  }

  void _navigateAway() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Redirect guard in GoRouter will intercept and send to /login if needed.
    context.go('/home');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF0F0D1B);

    return Scaffold(
      backgroundColor: darkBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Lottie.asset(
              'lib/assets/animations/pamkinscreen.json',
              fit: BoxFit.cover,
              repeat: false,
              onLoaded: (composition) {
                // Fallback: navigate when animation ends if _startSplash hasn't yet.
                Future.delayed(composition.duration, _navigateAway);
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Text(
                        'Halloween Fest 🎃',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.orangeAccent.withOpacity(value),
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.orangeAccent.withOpacity(0.8),
                              blurRadius: 20 * value,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
