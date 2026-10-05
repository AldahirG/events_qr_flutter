// lib/providers/registro_conferencia_provider.dart
import 'package:diacritic/diacritic.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/api_client.dart';
import '../models/registro_conferencia.dart';
import 'app_event_provider.dart';
import 'evento_activo_provider.dart';

class RegistroConferenciaState {
  final bool isLoading;
  final bool isPaginating;
  final List<RegistroConferencia> all;
  final List<RegistroConferencia> items;
  final String? errorMessage;
  final String query;
  final int? total;

  const RegistroConferenciaState({
    this.isLoading = false,
    this.isPaginating = false,
    this.all = const [],
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.total,
  });

  RegistroConferenciaState copyWith({
    bool? isLoading,
    bool? isPaginating,
    List<RegistroConferencia>? all,
    List<RegistroConferencia>? items,
    String? errorMessage,
    bool clearError = false,
    String? query,
    int? total,
  }) {
    return RegistroConferenciaState(
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      all: all ?? this.all,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      query: query ?? this.query,
      total: total ?? this.total,
    );
  }
}

class RegistroConferenciaNotifier
    extends StateNotifier<RegistroConferenciaState> {
  final Dio _dio;
  final String _conferencista;
  final bool _isHalloween;
  final CancelToken _cancel = CancelToken();

  RegistroConferenciaNotifier(this._dio, this._conferencista,
      {bool isHalloween = false})
      : _isHalloween = isHalloween,
        super(const RegistroConferenciaState()) {
    // Halloween: fetch all records immediately (no conferencista needed).
    // Conferencias: fetch only when an event is selected.
    if (_isHalloween || _conferencista.isNotEmpty) {
      Future.microtask(_fetchList);
    }
  }

  // NOTE: Paths are intentionally WITHOUT leading slash.
  // Dio resolves paths starting with '/' as absolute from host root,
  // which would break the /api/qr/registros/ base URL.
  // Empty string '' resolves to the base URL itself.

  // Halloween: no filter, return all records from the single event table.
  // Conferencias: filter by conferencista name.
  Map<String, dynamic> get _q {
    if (_isHalloween || _conferencista.isEmpty) return {};
    return {'conferencista': _conferencista};
  }

  String _normalize(String s) =>
      removeDiacritics(s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim());

  void _applyFilters() {
    Iterable<RegistroConferencia> base = state.all;
    if (state.query.trim().isNotEmpty) {
      final q = _normalize(state.query);
      base = base.where((r) {
        final nombre = _normalize(r.nombreCompleto);
        final tel = (r.telefono ?? '').replaceAll(RegExp(r'\D'), '');
        final id = r.id.toString();
        return nombre.contains(q) || tel.contains(q) || id.contains(q);
      });
    }
    state = state.copyWith(items: base.toList(), total: state.all.length);
  }

  Future<void> fetchInitial() {
    state = state.copyWith(query: '');
    return _fetchList();
  }

  Future<void> refresh() => _fetchList();

  Future<void> _fetchList() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // GET /registros/?conferencista=X
      final res = await _dio.get('', queryParameters: _q, cancelToken: _cancel);
      final raw = res.data is List
          ? res.data as List
          : ((res.data is Map)
              ? ((res.data['items'] ?? res.data['data'] ?? []) as List)
              : <dynamic>[]);

      final list = raw
          .map((e) => RegistroConferencia.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        all: list,
        total: list.length,
        clearError: true,
      );
      _applyFilters();
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _applyFilters();
  }

  void clearQuery() {
    state = state.copyWith(query: '');
    _applyFilters();
  }

  // GET /registros/:id?conferencista=X
  Future<RegistroConferencia> getById(int id) async {
    final res = await _dio.get('$id', queryParameters: _q, cancelToken: _cancel);
    return RegistroConferencia.fromJson(res.data as Map<String, dynamic>);
  }

  // POST /registros/create?conferencista=X
  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post('create', data: body, queryParameters: _q, cancelToken: _cancel);
    await refresh();
  }

  // PUT /registros/:id?conferencista=X
  Future<void> update(int id, Map<String, dynamic> body) async {
    await _dio.put('$id', data: body, queryParameters: _q, cancelToken: _cancel);
    await refresh();
  }

  // PUT /registros/:id  {asistio: 'SI'} (conferencias) or {asistio: 1} (halloween tinyint)
  Future<String> confirmarAsistencia(int id) async {
    try {
      final res = await _dio.put(
        '$id',
        data: {'asistio': _isHalloween ? 1 : 'SI'},
        queryParameters: _q,
        cancelToken: _cancel,
      );
      if ((res.statusCode ?? 0) == 200) {
        await refresh();
        return 'ok';
      }
      return 'error';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('ya confirmada')) return 'ya_confirmada';
      rethrow;
    }
  }

  // PATCH /registros/:id/acompanantes
  Future<void> actualizarAcompanantes(int id, int cantidad) async {
    await _dio.patch(
      '$id/acompanantes',
      data: {'cantidad': cantidad},
      cancelToken: _cancel,
    );
    await refresh();
  }

  // DELETE /registros/:id?conferencista=X
  Future<void> delete(int id) async {
    await _dio.delete('$id', queryParameters: _q, cancelToken: _cancel);
    await refresh();
  }

  @override
  void dispose() {
    if (!_cancel.isCancelled) _cancel.cancel('provider disposed');
    super.dispose();
  }
}

/// Auto-rebuilds when the active evento changes.
final registroConferenciaProvider = StateNotifierProvider<
    RegistroConferenciaNotifier, RegistroConferenciaState>((ref) {
  final appEvent = ref.watch(appEventProvider);
  final evento =
      ref.watch(eventoActivoProvider.select((s) => s.eventoSeleccionado));
  final dio = ref.watch(dioProvider);
  final isHalloween = appEvent == AppEvent.halloween;
  // Halloween: pass empty string — no filter applied, all records fetched.
  return RegistroConferenciaNotifier(
    dio,
    isHalloween ? '' : evento,
    isHalloween: isHalloween,
  );
});
