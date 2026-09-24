// lib/core/app_animations.dart
//
// Single source of truth for all Lottie animation paths.
// Drop .json files into lib/assets/animations/ and update paths here.
// All slots have a per-event variant — Halloween vs Conferencias.
//
// Usage:
//   Lottie.asset(AppAnimations.header(event), ...)
//   Lottie.asset(AppAnimations.success(event), ...)

import '../providers/app_event_provider.dart';

class AppAnimations {
  AppAnimations._();

  static const _base = 'lib/assets/animations';

  // ────────────────────────────────────────────────────────────────────────────
  // SLOTS — change paths here when you drop new files
  // ────────────────────────────────────────────────────────────────────────────

  /// Large hero animation — login header + home screen hero.
  static String header(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/pamkin.json',
        AppEvent.conferencias => '$_base/welcome.json',
      };

  /// Subtle looping background overlay on login screen.
  /// Returns null → no background animation for that mode.
  static String? loginBg(AppEvent e) => switch (e) {
        AppEvent.halloween => null,
        AppEvent.conferencias => null,
      };

  /// Splash / loading screen animation.
  static String splash(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/pamkinscreen.json',
        AppEvent.conferencias => '$_base/splash.json',
      };

  /// Event-selector card animation (inside each card).
  static String selector(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/pamkin.json',
        AppEvent.conferencias => '$_base/hi.json',
      };

  /// Success / attendance-confirmed animation.
  static String success(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/success_pumpkin.json',
        AppEvent.conferencias => '$_base/success.json',
      };

  /// Done / checkmark animation (after save, etc.).
  static String done(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/success_pumpkin.json',
        AppEvent.conferencias => '$_base/done.json',
      };

  /// Greeting / welcome animation shown after login.
  static String welcome(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/Welcum.json',
        AppEvent.conferencias => '$_base/welcome.json',
      };

  /// Idle / ambient loop (home screen, can be same as header).
  static String ambient(AppEvent e) => switch (e) {
        AppEvent.halloween => '$_base/goshh.json',
        AppEvent.conferencias => '$_base/welcome.json',
      };
}
