import 'package:events_qr_flutter/core/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final reportesProvider =
    StateNotifierProvider<ReportesNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) {
    final dio = ref.watch(dioProvider); // usa tu dioProvider
    return ReportesNotifier(dio);
  },
);

class ReportesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Dio _dio;
  ReportesNotifier(this._dio) : super(const AsyncValue.data({}));

  Future<void> fetchReportes() async {
    try {
      state = const AsyncValue.loading();

      final endpoints = {
        'assistances': 'assistances',
        'confirmedAssistances': 'confirmedAssistances',
        'assistancesByPrograma': 'assistancesByPrograma',
        'assistancesByEnteroEvento': 'getAssistancesByEnteroEvento',
        'porEdad': 'estadisticas/por-edad',
        'porArtista': 'estadisticas/por-artista',
        'porDisfraz': 'estadisticas/por-disfraz',
        'internosExternos': 'estadisticas/internos-externos',
        'totalAsistentes': 'estadisticas/total-asistentes',
      };

      final responses = await Future.wait(endpoints.entries.map((e) async {
        final res = await _dio.get(e.value);
        return MapEntry(e.key, res.data);
      }));

      // Convertimos todo a Map y ordenamos (mayor a menor)
      final result = <String, dynamic>{};
      for (var entry in responses) {
        final value = entry.value;
        if (value is List) {
          value.sort((a, b) =>
              ((b['total'] ?? 0) as num).compareTo((a['total'] ?? 0) as num));
          result[entry.key] = value;
        } else {
          result[entry.key] = value;
        }
      }

      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> exportToExcel(Map<String, dynamic> data) async {
    final excel = Excel.createExcel();

    final cellHeader = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('FFFF6C00'), // naranja
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellRow = CellStyle(
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('FF1A1A2E'),
    );

    final cellTotal = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FF00FF9C'),
      backgroundColorHex: ExcelColor.fromHexString('FF0D0D0D'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // 🔹 Crear una hoja por sección
    void writeSection(String sheetName, dynamic value) {
      final sheet = excel[sheetName];
      sheet.appendRow([TextCellValue(sheetName)]);
      final lastRow = sheet.maxRows - 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: lastRow))
        ..cellStyle = cellHeader;

      if (value is List && value.isNotEmpty) {
        final keys = (value.first as Map).keys.toList();
        sheet.appendRow(keys.map((k) => TextCellValue(k.toString())).toList());
        for (var i = 0; i < keys.length; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheet.maxRows - 1))
              .cellStyle = cellHeader;
        }

        for (var row in value) {
          sheet.appendRow(keys.map((k) => TextCellValue('${row[k]}')).toList());
          for (var i = 0; i < keys.length; i++) {
            sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: sheet.maxRows - 1))
                .cellStyle = cellRow;
          }
        }

        final total = value.fold<int>(0, (p, e) => p + ((e['total'] ?? 0) as num).toInt());
        sheet.appendRow([TextCellValue('Total'), TextCellValue('$total')]);
        final r = sheet.maxRows - 1;
        for (var i = 0; i < 2; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: r))
            ..cellStyle = cellTotal;
        }
      } else if (value is Map) {
        value.forEach((k, v) {
          sheet.appendRow([TextCellValue(k.toString()), TextCellValue(v.toString())]);
        });
      }
    }

    for (final entry in data.entries) {
      writeSection(entry.key, entry.value);
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/reporte_halloweenfest_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    final fileBytes = excel.encode();
    if (fileBytes != null) File(filePath).writeAsBytesSync(fileBytes);
    return filePath;
  }
}
