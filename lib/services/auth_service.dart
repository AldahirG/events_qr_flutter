// lib/services/auth_service.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user';
  static const _acessoKey = 'acceso';

  final FlutterSecureStorage _storage;
  late final Dio _authDio;

  AuthService() : _storage = const FlutterSecureStorage() {
    final rawBase = dotenv.isInitialized
        ? (dotenv.env['BASE_URL']?.trim() ?? '')
        : '';
    final authBase = _deriveAuthBase(rawBase);
    _authDio = Dio(BaseOptions(
      baseUrl: authBase,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // Derives auth base from BASE_URL.
  // Handles both "http://host/api/qr" and "http://host/api/qr/registros/".
  // Always returns a URL ending with "/" so Dio resolves relative paths correctly.
  String _deriveAuthBase(String baseUrl) {
    if (baseUrl.isEmpty) return 'http://10.0.2.2:3002/api/qr/';
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return 'http://10.0.2.2:3002/api/qr/';
    // Strip /registros/ suffix if present
    var path = uri.path.replaceAll(RegExp(r'registros/?$'), '');
    // Ensure trailing slash — critical for Dio relative path resolution
    if (!path.endsWith('/')) path = '$path/';
    return uri.replace(path: path).toString();
  }

  // ── Local JWT decode (no network call, no extra package) ─────────────

  /// Decodes the JWT payload (middle segment) without verifying signature.
  Map<String, dynamic>? _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // Base64url → padded Base64 → bytes → JSON string
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the token's `exp` claim is in the future.
  bool _tokenStillValid(String token) {
    final payload = _decodePayload(token);
    if (payload == null) return false;
    final exp = payload['exp'];
    if (exp == null) return false;
    final expSeconds = (exp as num).toInt();
    final nowSeconds =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // 30-second buffer so we refresh slightly early
    return expSeconds > nowSeconds + 30;
  }

  // ── Auth calls ────────────────────────────────────────────────────────

  Future<void> login(String user, String password) async {
    final res = await _authDio.post(
      'registros/login',
      data: {'user': user, 'password': password},
    );
    final token = res.data['token'] as String?;
    final refreshToken = res.data['refreshToken'] as String?;
    if (token == null || refreshToken == null) {
      throw Exception('Respuesta inválida del servidor');
    }
    await saveTokens(token: token, refreshToken: refreshToken);

    // Persist user info from JWT payload
    final payload = _decodePayload(token);
    if (payload != null) {
      await Future.wait([
        _storage.write(key: _userKey, value: payload['user']?.toString() ?? ''),
        _storage.write(
            key: _acessoKey,
            value: payload['acceso']?.toString() ?? '0'),
      ]);
    }
  }

  /// Tries to get a new access token. Returns the new token or null on failure.
  Future<String?> tryRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final res = await _authDio.post(
        'registros/refresh',
        data: {'refreshToken': refreshToken},
      );
      final newToken = res.data['token'] as String?;
      if (newToken != null) {
        await _storage.write(key: _tokenKey, value: newToken);
        return newToken;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() => _storage.deleteAll();

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  Future<String?> getStoredUser() => _storage.read(key: _userKey);

  /// Returns true if a stored token exists AND has not expired locally.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    return _tokenStillValid(token);
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
