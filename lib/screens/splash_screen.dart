import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

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
    await _fadeController.forward();

    // 🎬 Esperar a que la animación Lottie termine o máximo 5s
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) context.go('/home');
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
            // 🎃 Lottie de pantalla completa
            Lottie.asset(
              'lib/assets/animations/pamkinscreen.json',
              fit: BoxFit.cover,
              repeat: false, // 👈 que se reproduzca solo una vez
              onLoaded: (composition) {
                // ⏱️ Sincroniza la duración del Lottie con la transición
                Future.delayed(composition.duration, () {
                  if (mounted) context.go('/home');
                });
              },
            ),

            // ✨ Texto inferior con glow animado
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
