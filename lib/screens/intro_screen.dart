// lib/screens/intro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _ctrl = AnimationController(vsync: this);
  }

  void _onLoaded(LottieComposition composition) {
    _ctrl
      ..duration = composition.duration
      ..forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    context.go('/splash');
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0118),
      body: GestureDetector(
        onTap: _finish,
        child: SizedBox.expand(
          child: Lottie.asset(
            'lib/assets/animations/welcom-android.json',
            controller: _ctrl,
            onLoaded: _onLoaded,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              Future.delayed(const Duration(seconds: 2), _finish);
              return const SizedBox.expand(
                child: ColoredBox(color: Color(0xFF0D0118)),
              );
            },
          ),
        ),
      ),
    );
  }
}
