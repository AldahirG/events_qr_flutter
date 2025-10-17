// lib/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config.dart';

/// Proveedor para la baseUrl, con fallback seguro
final baseUrlProvider = Provider<String>((ref) {
  // Protege contra dotenv no inicializado
  if (!dotenv.isInitialized) {
    return 'http://10.0.2.2:3002/api/registros/';
  }

  return dotenv.env['BASE_URL']?.trim().isNotEmpty == true
      ? dotenv.env['BASE_URL']!.trim()
      : 'http://10.0.2.2:3002/api/registros/';
});

/// Proveedor de Dio centralizado para toda la app
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);

  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: Duration(seconds: Env.timeout),
    receiveTimeout: Duration(seconds: Env.timeout),
    sendTimeout: Duration(seconds: Env.timeout),
    responseType: ResponseType.json,
    headers: {
      'Content-Type': 'application/json',
    },
  ));
});
