// lib/providers/auth_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  /// Called once on app start (from SplashScreen) to check stored tokens.
  Future<void> initialize() async {
    final loggedIn = await _service.isLoggedIn();
    if (!loggedIn) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    // Try refresh to validate / renew the access token.
    final newToken = await _service.tryRefresh();
    if (newToken != null) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      // Both tokens expired → force re-login.
      await _service.clearTokens();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String user, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.login(user, password);
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
    } on DioException catch (e) {
      final raw = e.response?.data;
      final msg = (raw is Map)
          ? (raw['message'] ?? 'Credenciales incorrectas').toString()
          : 'Credenciales incorrectas';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión');
    }
  }

  Future<void> logout() async {
    await _service.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
