// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException(\$statusCode): \$message';
}

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    String? baseUrlFromEnv,
    Duration? timeoutOverride,
  })  : baseUrl = (baseUrlFromEnv ?? dotenv.env['BASE_URL'] ?? '').trim(),
        timeout = timeoutOverride ??
            Duration(seconds: int.tryParse(dotenv.env['TIMEOUT'] ?? '') ?? 15) {
    if (!dotenv.isInitialized || (dotenv.env['BASE_URL']?.isEmpty ?? true)) {
      throw ApiException('🌐 BASE_URL no está configurada o .env no se cargó');
    }
  }

  Uri _uri(String path) {
    var b = baseUrl;
    if (b.isEmpty) {
      throw ApiException('BASE_URL no está configurada en .env');
    }
    if (!b.endsWith('/')) b = '\$b/';
    final p = (path.startsWith('/')) ? path.substring(1) : path;
    return Uri.parse(b + p);
  }

  Future<dynamic> getRaw(String path) async {
    try {
      final res = await http.get(_uri(path)).timeout(timeout);
      return _processResponse(res);
    } on SocketException catch (e) {
      throw ApiException('No hay conexión: \${e.message}');
    } on TimeoutException {
      throw ApiException('La petición tardó demasiado (timeout)');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> postRaw(String path, {Object? body}) async {
    try {
      final res = await http
          .post(_uri(path),
              headers: {'Content-Type': 'application/json'},
              body: body == null ? null : json.encode(body))
          .timeout(timeout);
      return _processResponse(res);
    } on SocketException catch (e) {
      throw ApiException('No hay conexión: \${e.message}');
    } on TimeoutException {
      throw ApiException('La petición tardó demasiado (timeout)');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> putRaw(String path, {Object? body}) async {
    try {
      final res = await http
          .put(_uri(path),
              headers: {'Content-Type': 'application/json'},
              body: body == null ? null : json.encode(body))
          .timeout(timeout);
      return _processResponse(res);
    } on SocketException catch (e) {
      throw ApiException('No hay conexión: \${e.message}');
    } on TimeoutException {
      throw ApiException('La petición tardó demasiado (timeout)');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> deleteRaw(String path) async {
    try {
      final res = await http.delete(_uri(path)).timeout(timeout);
      return _processResponse(res);
    } on SocketException catch (e) {
      throw ApiException('No hay conexión: \${e.message}');
    } on TimeoutException {
      throw ApiException('La petición tardó demasiado (timeout)');
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<dynamic>> getAll() async {
    final res = await getRaw('');
    if (res is List) return res;
    if (res is Map && res['data'] is List) return res['data'] as List;
    return [];
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final res = await getRaw('get/\$id');
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  Future<Map<String, dynamic>?> create(Map<String, dynamic> payload) async {
    final res = await postRaw('create', body: payload);
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  Future<Map<String, dynamic>?> update(int id, Map<String, dynamic> payload) async {
    final res = await putRaw('update/\$id', body: payload);
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  Future<bool> delete(int id) async {
    await deleteRaw('delete/\$id');
    return true;
  }

  Future<List<Map<String, dynamic>>> getAssistances() async {
    final res = await getRaw('assistances');
    if (res is List) return List<Map<String, dynamic>>.from(res);
    return [];
  }

  Future<List<Map<String, dynamic>>> getConfirmedAssistances() async {
    final res = await getRaw('confirmedAssistances');
    if (res is List) return List<Map<String, dynamic>>.from(res);
    return [];
  }

  Future<List<Map<String, dynamic>>> getAssistancesByPrograma() async {
    final res = await getRaw('assistancesByPrograma');
    if (res is List) return List<Map<String, dynamic>>.from(res);
    return [];
  }

  Future<List<Map<String, dynamic>>> getAssistancesByEnteroEvento() async {
    final res = await getRaw('getAssistancesByEnteroEvento');
    if (res is List) return List<Map<String, dynamic>>.from(res);
    return [];
  }

  dynamic _processResponse(http.Response res) {
    final code = res.statusCode;
    final body = res.body;
    if (code >= 200 && code < 300) {
      if (body.isEmpty) return null;
      try {
        return json.decode(body);
      } catch (_) {
        return body;
      }
    } else {
      String message = 'Error \${res.statusCode}';
      try {
        final parsed = json.decode(body);
        if (parsed is Map && parsed['message'] != null) {
          message = parsed['message'].toString();
        } else if (parsed is Map && parsed['error'] != null) {
          message = parsed['error'].toString();
        }
      } catch (_) {}
      throw ApiException(message, code);
    }
  }
}
