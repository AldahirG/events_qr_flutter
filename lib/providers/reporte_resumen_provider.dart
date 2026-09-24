// lib/providers/reporte_resumen_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/api_client.dart';
import '../models/reporte_resumen.dart';
import '../services/reporte_service.dart';
import 'app_event_provider.dart';
import 'evento_activo_provider.dart';

class ReporteResumenState {
  final bool isLoading;
  final bool isDownloading;
  final ReporteResumen? data;
  final String? error;

  const ReporteResumenState({
    this.isLoading = false,
    this.isDownloading = false,
    this.data,
    this.error,
  });

  ReporteResumenState copyWith({
    bool? isLoading,
    bool? isDownloading,
    ReporteResumen? data,
    String? error,
    bool clearError = false,
    bool clearData = false,
  }) {
    return ReporteResumenState(
      isLoading: isLoading ?? this.isLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      data: clearData ? null : (data ?? this.data),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReporteResumenNotifier extends StateNotifier<ReporteResumenState> {
  final ReporteService _service;
  final String _conferencista;
  final bool _isHalloween;

  ReporteResumenNotifier(this._service, this._conferencista,
      {bool isHalloween = false})
      : _isHalloween = isHalloween,
        super(const ReporteResumenState());

  Future<void> fetchResumen({
    String? fecha,
    String? ubicacion,
    String? responsable,
  }) async {
    if (_conferencista.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _service.obtenerResumen(
        conferencista: _conferencista,
        isHalloween: _isHalloween,
        fecha: fecha,
        ubicacion: ubicacion,
        responsable: responsable,
      );
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Returns the local path of the downloaded file, or null on error.
  Future<String?> descargarDocx({
    String? fecha,
    String? ubicacion,
    String? responsable,
  }) async {
    if (_conferencista.isEmpty) return null;
    state = state.copyWith(isDownloading: true, clearError: true);
    try {
      final path = await _service.descargarDocx(
        conferencista: _conferencista,
        isHalloween: _isHalloween,
        fecha: fecha,
        ubicacion: ubicacion,
        responsable: responsable,
      );
      state = state.copyWith(isDownloading: false);
      return path;
    } catch (e) {
      state = state.copyWith(isDownloading: false, error: e.toString());
      return null;
    }
  }
}

final reporteServiceProvider = Provider<ReporteService>((ref) {
  return ReporteService(ref.watch(dioProvider));
});

final reporteResumenProvider =
    StateNotifierProvider<ReporteResumenNotifier, ReporteResumenState>((ref) {
  final conferencista =
      ref.watch(eventoActivoProvider.select((s) => s.eventoSeleccionado));
  final appEvent = ref.watch(appEventProvider);
  return ReporteResumenNotifier(
    ref.watch(reporteServiceProvider),
    conferencista,
    isHalloween: appEvent == AppEvent.halloween,
  );
});
