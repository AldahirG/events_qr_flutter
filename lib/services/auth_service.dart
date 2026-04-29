// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';

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

  // Strips /registros/ from the end of BASE_URL to get the auth root.
  // e.g. https://sicel.com.mx/api/qr/registros/ → https://sicel.com.mx/api/qr/
  String _deriveAuthBase(String baseUrl) {
    if (baseUrl.isEmpty) return 'http://10.0.2.2:3000/api/qr/';
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return 'http://10.0.2.2:3000/api/qr/';
    final newPath = uri.path.replaceAll(RegExp(r'registros/?$'), '');
    return uri.replace(path: newPath).toString();
  }

  Future<void> login(String user, String password) async {
    final res = await _authDio.post(
      'users/login',
      data: {'user': user, 'password': password},
    );
    final token = res.data['token'] as String?;
    final refreshToken = res.data['refreshToken'] as String?;
    if (token == null || refreshToken == null) {
      throw Exception('Respuesta inválida del servidor');
    }
    await saveTokens(token: token, refreshToken: refreshToken);
  }

  /// Tries to get a new access token using the stored refresh token.
  /// Returns the new token on success, null on failure.
  Future<String?> tryRefresh() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final res = await _authDio.post(
        'users/refresh',
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

  Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
