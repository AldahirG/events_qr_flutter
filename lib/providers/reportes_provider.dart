import 'package:events_qr_flutter/core/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:excel/excel.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../providers/app_event_provider.dart';
import '../providers/evento_activo_provider.dart';

final reportesProvider =
    StateNotifierProvider<ReportesNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) {
    final dio = ref.watch(dioProvider);
    final appEvent = ref.watch(appEventProvider);
    final conferencista =
        ref.watch(eventoActivoProvider.select((s) => s.eventoSeleccionado));
    return ReportesNotifier(dio, conferencista, isHalloween: appEvent == AppEvent.halloween);
  },
);

class ReportesNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Dio _dio;
  final String _conferencista;
  final bool _isHalloween;

  ReportesNotifier(this._dio, this._conferencista, {bool isHalloween = false})
      : _isHalloween = isHalloween,
        super(const AsyncValue.data({}));

  Map<String, dynamic> get _q => _conferencista.isNotEmpty
      ? {_isHalloween ? 'artista' : 'conferencista': _conferencista}
      : {};

  Future<void> fetchReportes() async {
    if (_conferencista.isEmpty) {
      state = const AsyncValue.data({});
      return;
    }
    try {
      state = const AsyncValue.loading();

      // Halloween uses its own stats endpoints (no conferencista filter).
      // Conferencias uses the shared endpoints filtered by ?conferencista=.
      final endpoints = _isHalloween
          ? {
              'promotores': 'estadisticas/promotor',
              'promotoresConf': 'estadisticas/promotor/confirmados',
              'programas': 'estadisticas/programa',
              'programasConf': 'estadisticas/programa/confirmados',
              'comoEntero': 'estadisticas/entero-evento',
              'totalAsistencia': 'estadisticas/total-asistencia',
            }
          : {
              'promotores': 'estadisticas/nombre-invito',
              'promotoresConf': 'estadisticas/nombre-invito/confirmados',
              'programas': 'estadisticas/programa-interes',
              'programasConf': 'estadisticas/programa-interes/confirmados',
              'comoEntero': 'estadisticas/entero-evento',
              'totalAsistencia': 'estadisticas/total-asistencia',
            };

      final responses = await Future.wait(
        endpoints.entries.map((e) async {
          try {
            final res = await _dio.get(e.value, queryParameters: _q);
            return MapEntry(e.key, res.data);
          } catch (_) {
            return MapEntry(e.key, <dynamic>[]);
          }
        }),
      );

      final result = <String, dynamic>{};
      for (final entry in responses) {
        final value = entry.value;
        if (value is List) {
          final sorted = [...value]
            ..sort((a, b) =>
                ((b['total'] ?? 0) as num)
                    .compareTo((a['total'] ?? 0) as num));
          result[entry.key] = sorted;
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
      backgroundColorHex: ExcelColor.fromHexString('FF1A52A8'), // institution blue
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellRow = CellStyle(
      fontColorHex: ExcelColor.fromHexString('FF1A2340'),
      backgroundColorHex: ExcelColor.fromHexString('FFF0F5FC'),
    );

    final cellTotal = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('FF1A52A8'),
      backgroundColorHex: ExcelColor.fromHexString('FFE3EDF9'),
      horizontalAlign: HorizontalAlign.Center,
    );

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
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: sheet.maxRows - 1))
              .cellStyle = cellHeader;
        }

        for (var row in value) {
          sheet.appendRow(
              keys.map((k) => TextCellValue('${row[k]}')).toList());
          for (var i = 0; i < keys.length; i++) {
            sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: i, rowIndex: sheet.maxRows - 1))
                .cellStyle = cellRow;
          }
        }

        final total = value.fold<int>(
            0, (p, e) => p + ((e['total'] ?? 0) as num).toInt());
        sheet.appendRow([TextCellValue('Total'), TextCellValue('$total')]);
        final r = sheet.maxRows - 1;
        for (var i = 0; i < 2; i++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: r))
              .cellStyle = cellTotal;
        }
      }
    }

    final sectionLabels = {
      'promotores': 'Promotores',
      'promotoresConf': 'Promotores Confirmados',
      'programas': 'Programas de Interés',
      'programasConf': 'Programas Confirmados',
      'comoEntero': 'Cómo se Enteraron',
    };

    for (final entry in data.entries) {
      writeSection(sectionLabels[entry.key] ?? entry.key, entry.value);
    }

    final dir = await getApplicationDocumentsDirectory();
    final label = _conferencista.replaceAll(' ', '_');
    final filePath =
        '${dir.path}/asistencias_${label}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

    final fileBytes = excel.encode();
    if (fileBytes != null) File(filePath).writeAsBytesSync(fileBytes);
    return filePath;
  }
}
