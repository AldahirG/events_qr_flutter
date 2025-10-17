// lib/providers/registro_provider.dart

import 'package:events_qr_flutter/core/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/registro.dart';
// ⚠️ Elimina imports que ya no usamos:
// import 'package:flutter_riverpod/legacy.dart';
// import '../core/api_client.dart';

class RegistroState {
  final bool isLoading;
  final bool isPaginating;
  final List<Registro> all;    // universo descargado
  final List<Registro> items;  // con filtros aplicados (UI)
  final String? errorMessage;
  final bool hasMore;          // sin paginar por ahora
  final int page;              // reservado por si agregas paginación
  final int pageSize;
  final int? total;            // total (post-filtro opcional)
  final String query;
  final DateTime? month;

  const RegistroState({
    this.isLoading = false,
    this.isPaginating = false,
    this.all = const [],
    this.items = const [],
    this.errorMessage,
    this.hasMore = false,
    this.page = 1,
    this.pageSize = 50,
    this.total,
    this.query = '',
    this.month,
  });

  RegistroState copyWith({
    bool? isLoading,
    bool? isPaginating,
    List<Registro>? all,
    List<Registro>? items,
    String? errorMessage,
    bool? hasMore,
    int? page,
    int? pageSize,
    int? total,
    String? query,
    DateTime? month,
    bool setMonthNull = false,
  }) {
    return RegistroState(
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      all: all ?? this.all,
      items: items ?? this.items,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      total: total ?? this.total,
      query: query ?? this.query,
      month: setMonthNull ? null : (month ?? this.month),
    );
  }
}

class RegistroNotifier extends StateNotifier<RegistroState> {
  final Dio _dio;
  final CancelToken _cancel = CancelToken();

  RegistroNotifier(this._dio) : super(const RegistroState());

  String _normalize(String s) =>
      removeDiacritics(s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim());
  String _digitsOnly(String? s) => (s ?? '').replaceAll(RegExp(r'\D+'), '');

  bool _matchesQuery(Registro r, String q) {
    if (q.trim().isEmpty) return true;
    final name = _normalize(r.nombre ?? '');
    final phone = _digitsOnly(r.telefono);
    final idStr = r.id.toString();
    final tokens = _normalize(q).split(' ').where((t) => t.isNotEmpty).toList();

    for (final tok in tokens) {
      if (!(name.contains(tok) || phone.contains(tok) || idStr.contains(tok))) {
        return false;
      }
    }
    return true;
  }

  void _applyFilters() {
    Iterable<Registro> base = state.all;

    // Filtro por mes
    if (state.month != null) {
      final start = DateTime(state.month!.year, state.month!.month, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      base = base.where((r) =>
          r.fechaRegistro.isAfter(start.subtract(const Duration(seconds: 1))) &&
          r.fechaRegistro.isBefore(end));
    }

    // Filtro por query
    if (state.query.trim().isNotEmpty) {
      base = base.where((r) => _matchesQuery(r, state.query));
    }

    final list = base.toList()
      ..sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));

    state = state.copyWith(items: list, total: state.all.length, errorMessage: null);
  }

  Future<void> fetchInitial() async => list(page: 1);
  Future<void> refresh() async => list(page: 1);

  Future<void> list({int page = 1}) async {
    final isFirstPage = page == 1;

    state = state.copyWith(
      isLoading: isFirstPage,
      isPaginating: !isFirstPage,
      errorMessage: null,
      page: page,
    );

    try {
      // GET /  → listado completo
      final r = await _dio.get('/', cancelToken: _cancel);
      List raw;
      if (r.data is List) {
        raw = r.data as List;
      } else if (r.data is Map) {
        raw = (r.data['items'] ?? r.data['data'] ?? []) as List;
      } else {
        raw = const [];
      }

      final registros = raw.map((e) => Registro.fromJson(e as Map<String, dynamic>)).toList();

      final merged = isFirstPage ? registros : [...state.all, ...registros];

      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        all: merged,
        // Total del universo descargado (no del page actual)
        total: merged.length,
        hasMore: false, // no hay paginación en backend hoy
        errorMessage: null,
        page: page,
      );

      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchNextPage() async {
    // sin paginación real, evitamos más llamadas
    if (!state.hasMore || state.isPaginating) return;
    await list(page: state.page + 1);
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _applyFilters();
  }

  void applySearch() => _applyFilters();

  void filterByMonth(DateTime month) {
    final m = DateTime(month.year, month.month, 1);
    state = state.copyWith(month: m);
    _applyFilters();
  }

  void clearFiltersAndReload() {
    state = state.copyWith(query: '', setMonthNull: true);
    _applyFilters();
  }

  // ---------- CRUD contra tu backend ----------

  Future<Registro> getById(int id) async {
    // GET /get/:id
    final r = await _dio.get('/get/$id', cancelToken: _cancel);
    return Registro.fromJson(r.data as Map<String, dynamic>);
    }

  Future<void> create(Map<String, dynamic> body) async {
    // POST /create
    await _dio.post('/create', data: body, cancelToken: _cancel);
    await fetchInitial();
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    // PUT /update/:id
    await _dio.put('/update/$id', data: body, cancelToken: _cancel);
    await refresh();
  }

  Future<void> delete(int id) async {
    // DELETE /delete/:id
    await _dio.delete('/delete/$id', cancelToken: _cancel);
    await refresh();
  }

  Future<void> confirmarAsistencia(int id) async {
    await update(id, {'asistio': 1});
  }

  @override
  void dispose() {
    if (!_cancel.isCancelled) _cancel.cancel('RegistroNotifier disposed');
    super.dispose();
  }
}

// --- Provider raíz ---
// Asegúrate de tener un dioProvider que configure baseURL = .../api/registros
final registroProvider =
    StateNotifierProvider<RegistroNotifier, RegistroState>((ref) {
  final dio = ref.watch(dioProvider);
  return RegistroNotifier(dio);
});
