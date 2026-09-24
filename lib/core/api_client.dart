// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_event_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'config.dart';

final baseUrlProvider = Provider<String>((ref) {
  final event = ref.watch(appEventProvider);

  String _normalize(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/') ? trimmed : '$trimmed/';
  }

  if (event == AppEvent.halloween) {
    final url = dotenv.isInitialized
        ? (dotenv.env['HALLOWEEN_URL']?.trim() ?? '')
        : '';
    return url.isNotEmpty
        ? _normalize(url)
        : 'http://10.0.11.75:3000/api/halloween/registros/';
  }

  // Conferencias — use BASE_URL as-is (backward compatible)
  final url = dotenv.isInitialized
      ? (dotenv.env['BASE_URL']?.trim() ?? '')
      : '';
  return url.isNotEmpty
      ? _normalize(url)
      : 'http://10.0.11.75:3000/api/qr/registros/';
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
