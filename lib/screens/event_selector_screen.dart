// lib/screens/event_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../core/app_animations.dart';
import '../providers/app_event_provider.dart';

class EventSelectorScreen extends ConsumerWidget {
  const EventSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Selecciona tu evento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'El acceso y los datos varían según el evento',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 40),
              // ── Conferencias card ───────────────────────────────────────────
              Expanded(
                child: _EventCard(
                  onTap: () => _select(context, ref, AppEvent.conferencias),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A52A8), Color(0xFF2E86AB)],
                  ),
                  border: BorderSide.none,
                  glow: const Color(0xFF1A52A8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _lottieOrIcon(
                        AppAnimations.selector(AppEvent.conferencias),
                        Icons.mic_rounded,
                        Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Conferencias UNINTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sistema de registro y asistencia',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Halloween card ──────────────────────────────────────────────
              Expanded(
                child: _EventCard(
                  onTap: () => _select(context, ref, AppEvent.halloween),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D0118), Color(0xFF1A0A2E)],
                  ),
                  border: const BorderSide(
                      color: Color(0xFF9C27B0), width: 1.5),
                  glow: const Color(0xFF9C27B0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _lottieOrIcon(
                        AppAnimations.selector(AppEvent.halloween),
                        Icons.whatshot_rounded,
                        Color(0xFFFF6D00),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Halloween Fest 2026',
                        style: TextStyle(
                          color: Color(0xFFE8D5FF),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Registro de asistencia al evento',
                        style: TextStyle(
                            color: Color(0xFFFF6D00), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, AppEvent event) {
    ref.read(appEventProvider.notifier).state = event;
    // Setting eventConfirmedProvider triggers GoRouter redirect → /splash.
    // Do NOT also call context.go() — that would create a duplicate history entry.
    ref.read(eventConfirmedProvider.notifier).state = true;
  }

  Widget _lottieOrIcon(String asset, IconData fallback, Color color) {
    return Lottie.asset(
      asset,
      height: 130,
      width: 130,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(fallback, size: 80, color: color),
    );
  }
}

class _EventCard extends StatelessWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  final BorderSide border;
  final Color glow;
  final Widget child;

  const _EventCard({
    required this.onTap,
    required this.gradient,
    required this.border,
    required this.glow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(border),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
