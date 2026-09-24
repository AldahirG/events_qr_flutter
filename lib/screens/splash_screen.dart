// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../core/app_animations.dart';
import '../core/app_theme.dart';
import '../providers/app_event_provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _startSplash();
  }

  Future<void> _startSplash() async {
    _fadeCtrl.forward();
    // Run auth init and a minimum display time in parallel
    await Future.wait([
      ref.read(authProvider.notifier).initialize(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    _navigateAway();
  }

  void _navigateAway() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/home');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(appEventProvider);
    final isHalloween = event == AppEvent.halloween;

    final bgColor = isHalloween ? HalloweenColors.bg : AppColors.primary;
    final textColor = isHalloween ? HalloweenColors.secondary : Colors.white;
    final subColor = isHalloween
        ? HalloweenColors.secondary.withValues(alpha: 0.6)
        : Colors.white70;

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fade,
        child: isHalloween
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Lottie.asset(
                    AppAnimations.splash(event),
                    fit: BoxFit.cover,
                    repeat: true,
                    errorBuilder: (_, __, ___) => Container(
                      color: HalloweenColors.bg,
                      child: const Icon(Icons.whatshot_rounded,
                          size: 120, color: HalloweenColors.secondary),
                    ),
                  ),
                  // Dark overlay so text is readable
                  Container(color: Colors.black.withValues(alpha: 0.35)),
                  SafeArea(
                    child: Column(
                      children: [
                        const Spacer(),
                        Text(
                          'Halloween Fest 23',
                          style: TextStyle(
                            fontSize: 28,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sistema de registro y asistencia',
                          style: TextStyle(color: subColor, fontSize: 14),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: HalloweenColors.secondary.withValues(alpha: 0.7),
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('v2.0',
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.35),
                                fontSize: 12)),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'lib/assets/images/uninterlogo.png',
                            width: 130,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.school_rounded,
                              size: 90,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'CheckQR UNINTER',
                            style: TextStyle(
                              fontSize: 26,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Control de asistencia a eventos',
                            style: TextStyle(
                                color: subColor, fontSize: 14, letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 52),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Text(
                      'v2.0',
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.35), fontSize: 12),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
