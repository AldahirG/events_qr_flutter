// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'config.dart';

final baseUrlProvider = Provider<String>((ref) {
  if (!dotenv.isInitialized) return 'http://10.0.2.2:3002/api/registros/';
  return dotenv.env['BASE_URL']?.trim().isNotEmpty == true
      ? dotenv.env['BASE_URL']!.trim()
      : 'http://10.0.2.2:3002/api/registros/';
});

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final timeoutSeconds = Env.timeout;
  final authService = ref.watch(authServiceProvider);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: Duration(seconds: timeoutSeconds),
    receiveTimeout: Duration(seconds: timeoutSeconds),
    sendTimeout: Duration(seconds: timeoutSeconds),
    responseType: ResponseType.json,
    headers: {'Content-Type': 'application/json'},
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  ));

  dio.interceptors.add(_AuthInterceptor(
    dio: dio,
    authService: authService,
    onForceLogout: () => ref.read(authProvider.notifier).logout(),
  ));

  return dio;
});

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final AuthService _authService;
  final Future<void> Function() _onForceLogout;

  _AuthInterceptor({
    required Dio dio,
    required AuthService authService,
    required Future<void> Function() onForceLogout,
  })  : _dio = dio,
        _authService = authService,
        _onForceLogout = onForceLogout;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if ((status == 401 || status == 403) && !alreadyRetried) {
      final newToken = await _authService.tryRefresh();
      if (newToken != null) {
        // Retry the original request with the fresh token.
        final opts = err.requestOptions;
        opts.extra['retried'] = true;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {}
      }
      // Refresh failed → clear session, GoRouter redirect handles /login.
      await _onForceLogout();
    }

    handler.next(err);
  }
}
