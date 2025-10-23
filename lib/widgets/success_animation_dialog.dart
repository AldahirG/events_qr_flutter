import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessAnimationDialog extends StatefulWidget {
  final String message;
  const SuccessAnimationDialog({
    super.key,
    this.message = '¡Registro exitoso!',
  });

  @override
  State<SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _animationLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Seguridad: cerrar automáticamente por si falla la animación
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🟠 Intenta cargar animación; si falla, muestra PNG
                FutureBuilder(
                  future: _tryLoadLottie(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data == true) {
                      return Lottie.asset(
                        'assets/animations/success_pumpkin.json',
                        controller: _controller,
                        width: 160,
                        height: 160,
                        repeat: false,
                        onLoaded: (composition) async {
                          setState(() => _animationLoaded = true);
                          _controller.duration = composition.duration;
                          await _controller.forward();
                          await Future.delayed(const Duration(milliseconds: 800));
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    } else {
                      // 🎃 fallback si no existe la animación JSON
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/animations/success_pumpkin.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        color: Color(0xFFFFA500),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _tryLoadLottie() async {
    try {
      await DefaultAssetBundle.of(context)
          .loadString('assets/animations/success_pumpkin.json');
      return true;
    } catch (_) {
      return false;
    }
  }
}
