// lib/providers/registro_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../core/api_client.dart';
import '../models/registro.dart';

class RegistroState {
  final bool isLoading;
  final bool isPaginating;
  final List<Registro> all;
  final List<Registro> items;
  final String? errorMessage;
  final bool hasMore;
  final int page;
  final int pageSize;
  final int? total;
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

  String _normalize(String s) => removeDiacritics(s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim());
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D+'), '');

  bool _matchesQuery(Registro r, String q) {
    if (q.trim().isEmpty) return true;
    final name = _normalize(r.nombre ?? '');
    final phone = _digitsOnly(r.telefono ?? '');
    final id = r.id.toString();
    final tokens = _normalize(q).split(' ').where((t) => t.isNotEmpty).toList();

    for (final tok in tokens) {
      if (!(name.contains(tok) || phone.contains(tok) || id.contains(tok))) {
        return false;
      }
    }
    return true;
  }

  void _applyFilters() {
    Iterable<Registro> base = state.all;

    if (state.month != null) {
      final start = DateTime(state.month!.year, state.month!.month, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      base = base.where((r) => r.fechaRegistro != null && r.fechaRegistro!.isAfter(start.subtract(const Duration(seconds: 1))) && r.fechaRegistro!.isBefore(end));
    }

    if (state.query.trim().isNotEmpty) {
      base = base.where((r) => _matchesQuery(r, state.query));
    }

    final list = base.toList()..sort((a, b) => (b.fechaRegistro ?? DateTime(0)).compareTo(a.fechaRegistro ?? DateTime(0)));
    state = state.copyWith(items: list, errorMessage: null);
  }

  Future<void> fetchInitial() async => await list(page: 1);
  Future<void> refresh() async => await list(page: 1);

  Future<void> list({int page = 1}) async {
    final isFirstPage = page == 1;
    if (isFirstPage) {
      state = state.copyWith(isLoading: true, errorMessage: null, page: 1);
    } else {
      state = state.copyWith(isPaginating: true, errorMessage: null, page: page);
    }

    try {
      final r = await _dio.get('', cancelToken: _cancel);
      final data = r.data;
      List listRaw;

      if (data is List) {
        listRaw = data;
      } else if (data is Map) {
        listRaw = (data['items'] ?? data['data'] ?? []) as List;
      } else {
        listRaw = [];
      }

      final registros = listRaw.map((e) => Registro.fromJson(e)).toList();
      final merged = isFirstPage ? registros : [...state.all, ...registros];

      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        all: merged,
        total: registros.length,
        hasMore: false,
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

  Future<Registro> getById(dynamic id) async {
    final r = await _dio.get('$id', cancelToken: _cancel);
    return Registro.fromJson(r.data);
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post('create', data: body, cancelToken: _cancel);
    await fetchInitial();
  }

  Future<void> update(dynamic id, Map<String, dynamic> body) async {
    await _dio.put('$id', data: body, cancelToken: _cancel);
    await refresh();
  }

  Future<void> confirmarAsistencia(int id) async {
    await update(id, { 'asistio': 1 });
  }

  @override
  void dispose() {
    if (!_cancel.isCancelled) _cancel.cancel('RegistroNotifier disposed');
    super.dispose();
  }
}

final registroProvider = StateNotifierProvider<RegistroNotifier, RegistroState>((ref) {
  final dio = ref.watch(dioProvider); // ← CAMBIO AQUÍ
  return RegistroNotifier(dio);
});
