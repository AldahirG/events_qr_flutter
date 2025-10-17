// // lib/services/auth_service.dart
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'api_service.dart';

// class AuthService {
//   final ApiService _api = ApiService();
//   final FlutterSecureStorage _secure = const FlutterSecureStorage();

//   Future<void> saveToken(String token) async {
//     await _secure.write(key: 'access_token', value: token);
//   }

//   Future<void> logout() async {
//     await _secure.delete(key: 'access_token');
//   }

//   Future<String?> getToken() async {
//     return _secure.read(key: 'access_token');
//   }

//   Future<void> login(String user, String password) async {
//     final res = await _api.post('/api/users/login', body: {'user': user, 'password': password});
//     // Asume que el backend responde { token: '...' }
//     if (res == null || res['token'] == null) {
//       throw Exception('Respuesta inválida del servidor al iniciar sesión');
//     }
//     await saveToken(res['token']);
//   }

//   Future<void> register(String user, String password, {String? correo}) async {
//     final body = {'user': user, 'password': password};
//     if (correo != null) body['correo'] = correo;
//     final res = await _api.post('/api/users/register', body: body);
//     return res;
//   }
// }
