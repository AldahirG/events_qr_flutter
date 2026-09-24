// lib/services/reporte_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reporte_resumen.dart';

class ReporteService {
  final Dio _dio;
  ReporteService(this._dio);

  Map<String, dynamic> _params(
    String conferencista, {
    String paramKey = 'conferencista',
    String? fecha,
    String? ubicacion,
    String? responsable,
  }) {
    final p = <String, dynamic>{};
    if (conferencista.isNotEmpty) p[paramKey] = conferencista;
    if (fecha != null && fecha.isNotEmpty) p['fecha'] = fecha;
    if (ubicacion != null && ubicacion.isNotEmpty) p['ubicacion'] = ubicacion;
    if (responsable != null && responsable.isNotEmpty) p['responsable'] = responsable;
    return p;
  }

  /// GET reporte/resumen
  Future<ReporteResumen> obtenerResumen({
    required String conferencista,
    bool isHalloween = false,
    String? fecha,
    String? ubicacion,
    String? responsable,
  }) async {
    final res = await _dio.get(
      'reporte/resumen',
      queryParameters: _params(
        conferencista,
        paramKey: isHalloween ? 'artista' : 'conferencista',
        fecha: fecha,
        ubicacion: ubicacion,
        responsable: responsable,
      ),
    );
    return ReporteResumen.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET reporte/docx  — returns local file path after saving
  Future<String> descargarDocx({
    required String conferencista,
    bool isHalloween = false,
    String? fecha,
    String? ubicacion,
    String? responsable,
  }) async {
    final res = await _dio.get(
      'reporte/docx',
      queryParameters: _params(
        conferencista,
        paramKey: isHalloween ? 'artista' : 'conferencista',
        fecha: fecha,
        ubicacion: ubicacion,
        responsable: responsable,
      ),
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = await getTemporaryDirectory();
    final safe = conferencista.replaceAll(RegExp(r'[^\w]'), '_');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/reporte_${safe}_$ts.docx';
    await File(path).writeAsBytes(res.data as List<int>);
    return path;
  }
}
