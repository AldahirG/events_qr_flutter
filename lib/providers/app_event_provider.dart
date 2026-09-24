// lib/providers/app_event_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum AppEvent { conferencias, halloween }

extension AppEventX on AppEvent {
  String get displayName => switch (this) {
        AppEvent.conferencias => 'Conferencias UNINTER',
        AppEvent.halloween => 'Halloween Fest',
      };
}

/// Which event type is active (conferencias vs halloween).
final appEventProvider = StateProvider<AppEvent>((ref) => AppEvent.conferencias);

/// True once the user has tapped a card on EventSelectorScreen.
/// Resets to false on app restart (session-only).
final eventConfirmedProvider = StateProvider<bool>((ref) => false);
