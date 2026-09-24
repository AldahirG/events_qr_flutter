// lib/core/constants/api_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get _base =>
      dotenv.env['BASE_URL']?.trim().isNotEmpty == true
          ? dotenv.env['BASE_URL']!.trim()
          : 'http://10.0.2.2:3002/api/qr/registros/';

  // Auth — public (baseUrl without /registros/)
  static String get authBase {
    final uri = Uri.tryParse(_base);
    if (uri == null) return 'http://10.0.2.2:3002/api/qr/';
    final newPath = uri.path.replaceAll(RegExp(r'registros/?$'), '');
    return uri.replace(path: newPath).toString();
  }

  static String get login    => '${authBase}registros/login';
  static String get refresh  => '${authBase}registros/refresh';

  // Registros — all protected with JWT
  static String get registros       => _base;
  static String get eventosPorMes   => '${_base}eventos/por-mes';
  static String get exportarExcel   => '${_base}export/excel';
  static String get statNombreInvito => '${_base}estadisticas/nombre-invito';
  static String get statPrograma     => '${_base}estadisticas/programa-interes';
  static String get statEnteroEvento => '${_base}estadisticas/entero-evento';

  // Reporte endpoints
  static String get reporteResumen => '${_base}reporte/resumen';
  static String get reporteDocx    => '${_base}reporte/docx';
  static String acompanantes(int id) => '${_base}$id/acompanantes';
}
