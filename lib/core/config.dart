// lib/core/config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static int get timeout {
    if (!dotenv.isInitialized) return 20;
    return int.tryParse(dotenv.env['TIMEOUT'] ?? '') ?? 20;
  }
}
