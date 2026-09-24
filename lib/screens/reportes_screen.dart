// lib/screens/reportes_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:open_filex/open_filex.dart';

import '../core/app_theme.dart';
import '../models/reporte_resumen.dart';
import '../providers/app_event_provider.dart';
import '../providers/evento_activo_provider.dart';
import '../providers/reportes_provider.dart';
import '../providers/reporte_resumen_provider.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Theme colors — set at top of build() ──
  Color _bg = AppColors.bg;
  Color _surface = AppColors.card;
  Color _accent = AppColors.primary;
  Color _textCol = AppColors.text;
  Color _subCol = AppColors.textSub;
  Color _divCol = AppColors.divider;
  bool _hw = false;

  // ── Tab 1: Estadísticas ──
  final Map<String, bool> _sortDescending = {};
  bool _showCharts = false;
  int _displayedCount = 0;
  int _lastTotalCount = 0;
  Timer? _counterTimer;

  // ── Tab 2: Reporte Resumen ──
  // promotores table sort: 0=name,1=inv,2=asist,3=conv
  int _promoSortCol = 2; // default: asistentes desc
  bool _promoSortDesc = true;

  final _fechaCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
        () => ref.read(reportesProvider.notifier).fetchReportes());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _counterTimer?.cancel();
    _fechaCtrl.dispose();
    _ubicacionCtrl.dispose();
    _responsableCtrl.dispose();
    super.dispose();
  }

  // ── Counter animation ──────────────────────────────────────────────────────
  void _animateCount(int target) {
    if (target == _lastTotalCount) return;
    _counterTimer?.cancel();
    _lastTotalCount = target;
    const steps = 40;
    int step = 0;
    final increment = (target / steps).clamp(1, double.infinity);
    _counterTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      (timer) {
        step++;
        setState(() =>
            _displayedCount = (step * increment).clamp(0, target.toDouble()).toInt());
        if (step >= steps) {
          _displayedCount = target;
          timer.cancel();
        }
      },
    );
  }

  void _toggleSort(String key) =>
      setState(() => _sortDescending[key] = !(_sortDescending[key] ?? true));

  // ── Date picker helper ─────────────────────────────────────────────────────
  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _fechaCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final evento = ref.watch(eventoActivoProvider);
    final appEvent = ref.watch(appEventProvider);
    _hw      = appEvent == AppEvent.halloween;
    _bg      = _hw ? HalloweenColors.bg       : AppColors.bg;
    _surface = _hw ? HalloweenColors.surface   : AppColors.card;
    _accent  = _hw ? HalloweenColors.secondary : AppColors.primary;
    _textCol = _hw ? HalloweenColors.text      : AppColors.text;
    _subCol  = _hw ? HalloweenColors.textSub   : AppColors.textSub;
    _divCol  = _hw ? HalloweenColors.divider   : AppColors.divider;

    if (!evento.tieneEvento) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _hw ? HalloweenColors.surface : null,
          elevation: _hw ? 0 : null,
          title: Text('Reportes',
              style: _hw
                  ? const TextStyle(
                      color: HalloweenColors.secondary,
                      fontWeight: FontWeight.bold)
                  : null),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 56, color: AppColors.warning),
                const SizedBox(height: 16),
                Text('Sin evento activo',
                    style: TextStyle(
                        color: _textCol,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Selecciona un evento en Ajustes\npara ver reportes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subCol),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _hw ? HalloweenColors.surface : null,
        elevation: _hw ? 0 : null,
        title: Column(
          children: [
            Text(
              _hw ? 'Reportes 🎃' : 'Reportes',
              style: _hw
                  ? const TextStyle(
                      color: HalloweenColors.secondary,
                      fontWeight: FontWeight.bold)
                  : null,
            ),
            Text(
              evento.eventoSeleccionado,
              style: TextStyle(
                  color: _hw ? HalloweenColors.secondary.withValues(alpha: 0.7) : Colors.white70,
                  fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _hw ? HalloweenColors.secondary : Colors.white,
          labelColor: _hw ? HalloweenColors.secondary : Colors.white,
          unselectedLabelColor: _hw
              ? HalloweenColors.secondary.withValues(alpha: 0.5)
              : Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.summarize_rounded), text: 'Resumen'),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (_, __) => _tabController.index == 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Actualizar',
                        icon: Icon(Icons.refresh_rounded,
                            color: _hw ? HalloweenColors.secondary : null),
                        onPressed: () =>
                            ref.read(reportesProvider.notifier).fetchReportes(),
                      ),
                      IconButton(
                        tooltip: _showCharts ? 'Tablas' : 'Gráficas',
                        icon: Icon(
                          _showCharts
                              ? Icons.table_chart_outlined
                              : Icons.pie_chart_rounded,
                          color: _hw ? HalloweenColors.secondary : null,
                        ),
                        onPressed: () =>
                            setState(() => _showCharts = !_showCharts),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEstadisticasTab(),
          _buildResumenTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — ESTADÍSTICAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEstadisticasTab() {
    final reportesAsync = ref.watch(reportesProvider);
    final notifier = ref.read(reportesProvider.notifier);

    return reportesAsync.when(
      data: (data) {
        if (data.isEmpty) return _buildEmptyState(notifier);

        // Total registrados + acompañantes
        final totalData = data['totalAsistencia'];
        int totalRegistrados = 0;
        int totalAcomp = 0;
        int totalGeneral = 0;
        if (totalData is Map) {
          totalRegistrados = (totalData['registrados'] as num?)?.toInt() ?? 0;
          totalAcomp       = (totalData['acompanantes'] as num?)?.toInt() ?? 0;
          totalGeneral     = (totalData['total'] as num?)?.toInt() ?? 0;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCount(totalGeneral);
        });

        return RefreshIndicator(
          color: _accent,
          onRefresh: () => notifier.fetchReportes(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTotalDesglosadoCard(
                  total: _displayedCount,
                  registrados: totalRegistrados,
                  acompanantes: totalAcomp,
                ),
                const SizedBox(height: 18),
                _buildSection('Promotores', data['promotores'], 'promotores'),
                _buildSection('Promotores (confirmados)',
                    data['promotoresConf'], 'promotoresConf'),
                _buildSection('Programas de interés', data['programas'],
                    'programas'),
                _buildSection('Programas (confirmados)',
                    data['programasConf'], 'programasConf'),
                _buildSection(
                    'Cómo se enteraron', data['comoEntero'], 'comoEntero'),
                const SizedBox(height: 20),
                _buildExportButton(notifier, data),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _accent),
            const SizedBox(height: 12),
            Text('Cargando estadísticas…',
                style: TextStyle(color: _subCol, fontSize: 16)),
          ],
        ),
      ),
      error: (err, _) => _buildErrorState(err, notifier),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — RESUMEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildResumenTab() {
    final resumenState = ref.watch(reporteResumenProvider);
    final notifier = ref.read(reporteResumenProvider.notifier);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Form card ──────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PARÁMETROS DEL REPORTE',
                    style: TextStyle(
                      color: _subCol,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _formLabel('Fecha del evento'),
                  TextField(
                    controller: _fechaCtrl,
                    readOnly: true,
                    onTap: _pickFecha,
                    style: TextStyle(color: _textCol),
                    decoration: _inputDecor(
                      hint: 'YYYY-MM-DD',
                      suffix: Icon(Icons.calendar_today_outlined,
                          size: 18, color: _accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _formLabel('Ubicación'),
                  TextField(
                    controller: _ubicacionCtrl,
                    style: TextStyle(color: _textCol),
                    decoration: _inputDecor(hint: 'Ej. Auditorio principal'),
                  ),
                  const SizedBox(height: 12),
                  _formLabel('Responsable'),
                  TextField(
                    controller: _responsableCtrl,
                    style: TextStyle(color: _textCol),
                    decoration: _inputDecor(hint: 'Nombre del responsable'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: resumenState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.analytics_outlined),
                      label: Text(
                        resumenState.isLoading
                            ? 'Generando…'
                            : 'Ver Resumen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: resumenState.isLoading
                          ? null
                          : () => notifier.fetchResumen(
                                fecha: _fechaCtrl.text.trim(),
                                ubicacion: _ubicacionCtrl.text.trim(),
                                responsable: _responsableCtrl.text.trim(),
                              ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Error ─────────────────────────────────────────────────
            if (resumenState.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resumenState.error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Summary data ───────────────────────────────────────────
            if (resumenState.data != null) ...[
              const SizedBox(height: 16),
              _buildResumenData(resumenState.data!, notifier),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenData(
      ReporteResumen r, ReporteResumenNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Datos generales ──────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Datos generales',
                  icon: Icons.info_outline_rounded),
              const SizedBox(height: 10),
              _infoRow('Evento', r.datosGenerales.evento),
              _infoRow('Fecha', r.datosGenerales.fecha),
              _infoRow('Ubicación', r.datosGenerales.ubicacion),
              _infoRow('Responsable', r.datosGenerales.responsable),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── KPIs ─────────────────────────────────────────────────────
        _sectionTitle('Métricas clave', icon: Icons.numbers_rounded),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _kpiCard('Registros', '${r.totalRegistros}',
                _accent, Icons.assignment_outlined),
            _kpiCard('Únicos', '${r.registrosUnicos}',
                AppColors.success, Icons.person_outlined),
            _kpiCard('Duplicados', '${r.totalDuplicados}',
                r.totalDuplicados > 0 ? AppColors.warning : AppColors.success,
                Icons.content_copy_outlined),
            _kpiCard('Asistentes', '${r.totalAsistentes}',
                _accent, Icons.people_outlined),
            _kpiCard('Confirmados', '${r.asistentesRegistrados}',
                AppColors.success, Icons.verified_outlined),
            _kpiCard('Sin registro', '${r.asistentesSinRegistro}',
                AppColors.warning, Icons.person_add_disabled_outlined),
            _kpiCard('Acompañantes', '${r.totalAcompanantes}',
                _hw ? HalloweenColors.primary : AppColors.primaryLight, Icons.group_outlined),
            _kpiCard('Asistencia total', r.pctAsistenciaTotal,
                _hw ? HalloweenColors.primary : AppColors.primaryDark, Icons.percent_rounded),
          ],
        ),
        const SizedBox(height: 12),

        // ── Funnel ───────────────────────────────────────────────────
        _card(
          child: Row(
            children: [
              Expanded(
                child: _funnelStat('Directos', r.pctDirectos, AppColors.success),
              ),
              Container(width: 1, height: 48, color: _divCol),
              Expanded(
                child: _funnelStat('Walk-ins', r.pctWalkins, AppColors.warning),
              ),
              Container(width: 1, height: 48, color: _divCol),
              Expanded(
                child: _funnelStat('Registro→Asistencia', r.pctRegistroAsistencia, _accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Insights ─────────────────────────────────────────────────
        _buildInsights(r.insights),
        const SizedBox(height: 12),

        // ── Promotores table ─────────────────────────────────────────
        if (r.desempenoPorPromotor.isNotEmpty) ...[
          _buildPromotoresTable(r.desempenoPorPromotor),
          const SizedBox(height: 12),
        ],

        // ── Duplicados ───────────────────────────────────────────────
        if (r.duplicados.isNotEmpty) ...[
          _buildDuplicados(r.duplicados),
          const SizedBox(height: 12),
        ],

        // ── Download .docx ───────────────────────────────────────────
        _buildDocxButton(notifier),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Insights chip row ──────────────────────────────────────────────────────
  Widget _buildInsights(Insights ins) {
    final chips = <Widget>[];

    // Alto desempeño — conversión ≥70% Y ≥2 invitados
    if (ins.altoDesempeno.isNotEmpty) {
      final nombres = ins.altoDesempeno.map((p) => p.promotor).join(' y ');
      final pcts = ins.altoDesempeno.map((p) => '${p.conversion}%').join(', ');
      chips.add(_insightChip(
        '🏆 Alto desempeño: $nombres ($pcts)',
        AppColors.success,
      ));
    }

    // Más invitados
    if (ins.masInvitados != null) {
      final p = ins.masInvitados!;
      chips.add(_insightChip(
        '📣 Mayor alcance: ${p.promotor} (${p.invitados} inv.)',
        _accent,
      ));
    }

    // Menos invitados (solo si hay más de 1 promotor)
    if (ins.menosInvitados != null &&
        ins.menosInvitados!.promotor != ins.masInvitados?.promotor) {
      final p = ins.menosInvitados!;
      chips.add(_insightChip(
        '👤 Menor alcance: ${p.promotor} (${p.invitados} inv.)',
        _subCol,
      ));
    }

    // Peor promotor — conversión 0%
    if (ins.peorPromotor.isNotEmpty) {
      final nombres = ins.peorPromotor.map((p) => p.promotor).join(', ');
      chips.add(_insightChip(
        '🔴 Foco: $nombres (0% conversión)',
        AppColors.error,
      ));
    }

    // Alta pérdida en funnel
    if (ins.altaPerdidaFunnel) {
      chips.add(_insightChip(
        '📉 Alta pérdida en funnel (registro→asistencia < 50%)',
        AppColors.warning,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Insights', icon: Icons.lightbulb_outline_rounded),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }

  Widget _insightChip(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            style:
                TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  // ── Promotores table ───────────────────────────────────────────────────────
  Widget _buildPromotoresTable(List<DesempenoPromotor> promotores) {
    // Sort
    final sorted = [...promotores]..sort((a, b) {
        int cmp;
        switch (_promoSortCol) {
          case 0:
            cmp = a.promotor.compareTo(b.promotor);
            break;
          case 1:
            cmp = a.invitados.compareTo(b.invitados);
            break;
          case 3:
            cmp = a.conversion.compareTo(b.conversion);
            break;
          default: // 2 = asistentes
            cmp = a.asistentes.compareTo(b.asistentes);
        }
        return _promoSortDesc ? -cmp : cmp;
      });

    Widget _headerCell(String label, int col, {int flex = 1}) {
      final active = _promoSortCol == col;
      return Expanded(
        flex: flex,
        child: GestureDetector(
          onTap: () => setState(() {
            if (_promoSortCol == col) {
              _promoSortDesc = !_promoSortDesc;
            } else {
              _promoSortCol = col;
              _promoSortDesc = true;
            }
          }),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                col == 0 ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: active ? _accent : _subCol,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  _promoSortDesc
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 11,
                  color: _accent,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Desempeño por promotor',
              icon: Icons.leaderboard_rounded),
          const SizedBox(height: 6),
          Text(
            'Toca columna para ordenar',
            style: TextStyle(color: _subCol, fontSize: 11),
          ),
          const SizedBox(height: 8),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _headerCell('Promotor', 0, flex: 3),
                _headerCell('Inv.', 1),
                _headerCell('Asist.', 2),
                _headerCell('Conv.', 3),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...sorted.map((p) {
            final Color rowColor;
            if (p.conversion == 0 || p.asistentes == 0) {
              rowColor = AppColors.error.withValues(alpha: 0.08);
            } else if (p.conversion >= 70) {
              rowColor = AppColors.success.withValues(alpha: 0.08);
            } else {
              rowColor = AppColors.warning.withValues(alpha: 0.08);
            }
            final Color convColor = p.conversion == 0 || p.asistentes == 0
                ? AppColors.error
                : p.conversion >= 70
                    ? AppColors.success
                    : AppColors.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: rowColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(p.promotor,
                          style: TextStyle(color: _textCol, fontSize: 12))),
                  Expanded(
                      child: Text('${p.invitados}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _subCol, fontSize: 12))),
                  Expanded(
                      child: Text('${p.asistentes}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _promoSortCol == 2 ? _accent : _textCol,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                  Expanded(
                      child: Text(
                          '${p.conversion.toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: convColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
          // Legend
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              _legendDot(AppColors.success, '≥70%'),
              _legendDot(AppColors.warning, '<70%'),
              _legendDot(AppColors.error, '0%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );

  // ── Duplicados ─────────────────────────────────────────────────────────────
  Widget _buildDuplicados(List<Duplicado> duplicados) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Registros duplicados (${duplicados.length})',
            icon: Icons.content_copy_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(height: 10),
          ...duplicados.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 15, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.nombre,
                              style: TextStyle(
                                  color: _textCol,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text('${d.promotor} · ${d.motivo}',
                              style: TextStyle(color: _subCol, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Download .docx button ──────────────────────────────────────────────────
  Widget _buildDocxButton(ReporteResumenNotifier notifier) {
    final isDownloading =
        ref.watch(reporteResumenProvider.select((s) => s.isDownloading));
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _accent,
        side: BorderSide(color: _accent),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isDownloading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
          : const Icon(Icons.download_rounded),
      label: Text(
        isDownloading ? 'Descargando…' : 'Descargar reporte (.docx)',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: isDownloading
          ? null
          : () async {
              final path = await notifier.descargarDocx(
                fecha: _fechaCtrl.text.trim(),
                ubicacion: _ubicacionCtrl.text.trim(),
                responsable: _responsableCtrl.text.trim(),
              );
              if (!mounted) return;
              if (path != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppColors.success,
                  content: const Text('Reporte descargado',
                      style: TextStyle(color: Colors.white)),
                  action: SnackBarAction(
                    label: 'Abrir',
                    textColor: Colors.white,
                    onPressed: () => OpenFilex.open(path),
                  ),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: AppColors.error,
                  content: Text('Error al descargar el reporte',
                      style: TextStyle(color: Colors.white)),
                ));
              }
            },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSection(String title, dynamic list, String key) {
    if (list == null || list is! List || list.isEmpty) return const SizedBox.shrink();

    final isDesc = _sortDescending[key] ?? true;
    final sortedList = [...list]
      ..sort((a, b) => isDesc
          ? ((b['total'] ?? 0) as num).compareTo((a['total'] ?? 0) as num)
          : ((a['total'] ?? 0) as num).compareTo((b['total'] ?? 0) as num));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: !_showCharts
            ? _buildSortableTableSection(title, sortedList, key, isDesc)
            : _buildAdaptiveChart(title, sortedList),
      ),
    );
  }

  Widget _buildSortableTableSection(
      String title, List<dynamic> list, String key, bool isDesc) {
    final total =
        list.fold<int>(0, (p, e) => p + ((e['total'] ?? 0) as num).toInt());
    return Card(
      color: _surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _divCol),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: _accent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'Ordenar ${isDesc ? "ascendente" : "descendente"}',
                  onPressed: () => _toggleSort(key),
                  icon: Icon(
                    isDesc
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: _accent,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (final e in list)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${e.values.first}',
                              style: TextStyle(color: _textCol, fontSize: 14)),
                        ),
                        Text('${e['total']}',
                            style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  Divider(color: _divCol, thickness: 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:',
                          style: TextStyle(
                              color: _accent, fontWeight: FontWeight.bold)),
                      Text('$total',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptiveChart(String title, List<dynamic> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    final total =
        list.fold<num>(0, (sum, e) => sum + ((e['total'] ?? 0) as num));
    final maxVal =
        list.fold<num>(0, (m, e) => ((e['total'] ?? 0) as num) > m ? (e['total'] ?? 0) as num : m);

    final colors = [
      _accent,
      AppColors.success,
      const Color(0xFF9B59B6),
      AppColors.warning,
      _hw ? HalloweenColors.primary : AppColors.primaryLight,
      const Color(0xFF2ECC71),
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
      _hw ? HalloweenColors.primary : AppColors.primaryDark,
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
      const Color(0xFF8E44AD),
    ];

    // ── Few items (≤5): donut + clean legend ──────────────────────────────
    if (list.length <= 5) {
      return Card(
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _divCol),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _accent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 50,
                    sections: List.generate(list.length, (i) {
                      final valor = (list[i]['total'] ?? 0) as num;
                      final pct = total == 0 ? 0.0 : valor / total * 100;
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: valor.toDouble(),
                        title: '${pct.toStringAsFixed(0)}%',
                        radius: 65,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                        ),
                        titlePositionPercentageOffset: 0.6,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Legend
              ...List.generate(list.length, (i) {
                final label = list[i].values.first.toString();
                final valor = (list[i]['total'] ?? 0) as num;
                final pct = total == 0 ? 0.0 : valor / total * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(color: _textCol, fontSize: 12)),
                      ),
                      Text(
                        '${valor.toInt()}  ${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Total: ${total.toInt()}',
                    style: TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    // ── Many items: horizontal bar chart ────────────────────────────────────
    return Card(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _divCol),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _accent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ...List.generate(list.length, (i) {
              final label = list[i].values.first.toString();
              final valor = (list[i]['total'] ?? 0) as num;
              final barFraction =
                  maxVal == 0 ? 0.0 : (valor / maxVal).toDouble();
              final pct = total == 0 ? 0.0 : valor / total * 100;
              final color = colors[i % colors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(color: _textCol, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${valor.toInt()} · ${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    LayoutBuilder(builder: (ctx, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Container(
                            height: 10,
                            width: constraints.maxWidth * barFraction,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Total: ${total.toInt()}',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDesglosadoCard({
    required int total,
    required int registrados,
    required int acompanantes,
  }) {
    return Card(
      color: _accent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    'Total asistencia: $total',
                    key: ValueKey(total),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniStat(Icons.assignment_outlined, 'Reg.', registrados),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.white30),
                const SizedBox(width: 16),
                _miniStat(Icons.group_outlined, 'Acomp.', acompanantes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, int value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 15),
          const SizedBox(width: 4),
          Text('$label $value',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildTotalCard(int total,
      {String title = 'Total',
      IconData icon = Icons.people_alt_rounded}) {
    return Card(
      color: _accent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$title: $total',
                key: ValueKey(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
      ReportesNotifier notifier, Map<String, dynamic> data) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.download_rounded),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: () async {
        final path = await notifier.exportToExcel(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: const Text('Excel exportado',
              style: TextStyle(color: Colors.white)),
          action: SnackBarAction(
            label: 'Abrir',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(path),
          ),
        ));
      },
      label: const Text('Exportar a Excel'),
    );
  }

  Widget _buildErrorState(Object err, ReportesNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 60),
            const SizedBox(height: 10),
            Text('$err',
                style: TextStyle(color: _subCol, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              onPressed: () => notifier.fetchReportes(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ReportesNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 60, color: _accent),
          const SizedBox(height: 12),
          Text('Sin datos aún', style: TextStyle(color: _subCol, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifier.fetchReportes(),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _card({required Widget child}) => Card(
        color: _surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _divCol),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      );

  Widget _sectionTitle(String text, {IconData? icon, Color? color}) {
    final c = color ?? _accent;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 6),
        ],
        Text(text,
            style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _formLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                color: _textCol, fontWeight: FontWeight.w600, fontSize: 13)),
      );

  InputDecoration _inputDecor({String? hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _subCol),
        suffixIcon: suffix,
        filled: true,
        fillColor: _bg,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _divCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _divCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      );

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: _subCol, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: _textCol, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style:
                    TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    color: _subCol, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _funnelStat(String label, String value, Color color) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style:
                  TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _subCol, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      );
}
