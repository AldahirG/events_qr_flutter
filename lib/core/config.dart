// lib/core/config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:3002/api/registros/';

  static int get timeout =>
      int.tryParse(dotenv.env['TIMEOUT'] ?? '') ?? 20;
}
