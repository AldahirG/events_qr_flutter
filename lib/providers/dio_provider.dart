import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Provider base para obtener el Dio configurado con la URL del backend.
/// Esto unifica las peticiones de reportes, registros, etc.
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3002/api/registros/';
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
    },
    // ✅ Esta línea permite que cualquier código 2xx sea tratado como éxito
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  ));

  return dio;
});
