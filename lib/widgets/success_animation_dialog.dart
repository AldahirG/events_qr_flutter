import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/app_animations.dart';
import '../core/app_theme.dart';
import '../providers/app_event_provider.dart';

class SuccessAnimationDialog extends StatefulWidget {
  final String message;
  final AppEvent? event;
  const SuccessAnimationDialog({
    super.key,
    this.message = '¡Registro exitoso!',
    this.event,
  });

  @override
  State<SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // Safety fallback: close after 3 s if animation doesn't trigger
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
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                AppAnimations.success(widget.event ?? AppEvent.conferencias),
                controller: _controller,
                width: 140,
                height: 140,
                repeat: false,
                onLoaded: (composition) async {
                  _controller.duration = composition.duration;
                  await _controller.forward();
                  await Future.delayed(const Duration(milliseconds: 600));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
