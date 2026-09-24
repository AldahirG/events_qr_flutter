// lib/providers/evento_activo_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';
import 'app_event_provider.dart';

class EventoActivoState {
  final String mes; // YYYY-MM
  final String eventoSeleccionado; // conferencista name
  final List<String> conferencistasDisponibles;
  final bool isLoading;
  final String? error;

  const EventoActivoState({
    this.mes = '',
    this.eventoSeleccionado = '',
    this.conferencistasDisponibles = const [],
    this.isLoading = false,
    this.error,
  });

  bool get tieneEvento => eventoSeleccionado.isNotEmpty;

  EventoActivoState copyWith({
    String? mes,
    String? eventoSeleccionado,
    List<String>? conferencistasDisponibles,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return EventoActivoState(
      mes: mes ?? this.mes,
      eventoSeleccionado: eventoSeleccionado ?? this.eventoSeleccionado,
      conferencistasDisponibles:
          conferencistasDisponibles ?? this.conferencistasDisponibles,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EventoActivoNotifier extends StateNotifier<EventoActivoState> {
  final Dio _dio;
  final AppEvent _appEvent;
  static const _box = 'settings';
  static const _keyEvento = 'eventoSeleccionado';
  static const _keyMes = 'mesSeleccionado';

  EventoActivoNotifier(this._dio, this._appEvent)
      : super(const EventoActivoState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final box = await Hive.openBox(_box);
    final evento = (box.get(_keyEvento, defaultValue: '') as String?) ?? '';
    final mes = (box.get(_keyMes, defaultValue: '') as String?) ?? '';

    final mesActual = mes.isNotEmpty
        ? mes
        : DateFormat('yyyy-MM').format(DateTime.now());

    state = state.copyWith(mes: mesActual, eventoSeleccionado: evento);
    await fetchConferencistasPorMes(mesActual);
  }

  Future<void> fetchConferencistasPorMes(String mes) async {

    state = state.copyWith(isLoading: true, clearError: true, mes: mes);
    try {
      // Path without leading slash — Dio resolves relative to base URL
      // GET /registros/eventos/por-mes?mes=YYYY-MM
      final res = await _dio.get(
        'eventos/por-mes',
        queryParameters: {'mes': mes},
      );
      final list = _parseConferencistas(res.data);
      // Halloween: auto-select the first artista so screens don't require manual selection.
      final autoSelect = _appEvent == AppEvent.halloween &&
          state.eventoSeleccionado.isEmpty &&
          list.isNotEmpty;
      state = state.copyWith(
        isLoading: false,
        conferencistasDisponibles: list,
        eventoSeleccionado: autoSelect ? list.first : null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? 'Error al cargar eventos').toString()
          : 'Error al cargar eventos';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión');
    }
  }

  Future<void> setMes(String mes) async {
    final box = await Hive.openBox(_box);
    await box.put(_keyMes, mes);
    // Fetch conferencistas for new month
    await fetchConferencistasPorMes(mes);
  }

  Future<void> setEvento(String conferencista) async {
    final box = await Hive.openBox(_box);
    await box.put(_keyEvento, conferencista);
    state = state.copyWith(eventoSeleccionado: conferencista);
  }

  Future<void> clearEvento() async {
    final box = await Hive.openBox(_box);
    await box.put(_keyEvento, '');
    state = state.copyWith(eventoSeleccionado: '');
  }

  List<String> _parseConferencistas(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      if (e is String) return e;
      if (e is Map) {
        // Supports both Conferencias (conferencista) and Halloween (artista) backends
        return (e['conferencista'] ?? e['Conferencista'] ??
                e['artista'] ?? e['Artista'] ?? e['nombre'] ?? '')
            .toString();
      }
      return e.toString();
    }).where((s) => s.trim().isNotEmpty).toList();
  }
}

final eventoActivoProvider =
    StateNotifierProvider<EventoActivoNotifier, EventoActivoState>((ref) {
  final appEvent = ref.watch(appEventProvider);
  return EventoActivoNotifier(ref.watch(dioProvider), appEvent);
});
