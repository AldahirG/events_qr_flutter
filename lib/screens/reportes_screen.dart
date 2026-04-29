import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/reportes_provider.dart';
import 'dart:async';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  final Map<String, bool> _sortDescending = {};
  bool _showCharts = false;

  // 🔢 Animación del contador
  int _displayedCount = 0;
  int _lastConfirmedCount = 0;
  Timer? _counterTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(reportesProvider.notifier).fetchReportes());
  }

  @override
  void dispose() {
    _counterTimer?.cancel();
    super.dispose();
  }

  void _animateCount(int target) {
    if (target == _lastConfirmedCount) return; // ✅ evita reanimar innecesariamente
    _counterTimer?.cancel();
    _lastConfirmedCount = target;

    const duration = Duration(milliseconds: 1200);
    const steps = 40;
    int step = 0;
    final increment = (target / steps).clamp(1, double.infinity);

    _counterTimer = Timer.periodic(duration ~/ steps, (timer) {
      step++;
      final value = (step * increment).clamp(0, target.toDouble()).toInt();
      setState(() => _displayedCount = value);
      if (step >= steps) {
        _displayedCount = target;
        timer.cancel();
      }
    });
  }

  void _toggleSort(String key) {
    setState(() => _sortDescending[key] = !(_sortDescending[key] ?? true));
  }

  @override
  Widget build(BuildContext context) {
    final reportesAsync = ref.watch(reportesProvider);
    final notifier = ref.read(reportesProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Reportes HalloweenFest 🎃'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: Colors.orangeAccent),
            onPressed: () => notifier.fetchReportes(),
          ),
          IconButton(
            tooltip: _showCharts ? 'Mostrar Tablas 👁️' : 'Mostrar Gráficas 📊',
            icon: Icon(
              _showCharts ? Icons.table_chart_outlined : Icons.pie_chart_rounded,
              color: Colors.orangeAccent,
            ),
            onPressed: () => setState(() => _showCharts = !_showCharts),
          ),
        ],
      ),
      body: reportesAsync.when(
        data: (data) {
          if (data.isEmpty) return _buildEmptyState(notifier);

          final confirmed = data['confirmedAssistances'];
          int totalConfirmadas = 0;
          if (confirmed is List) {
            totalConfirmadas = confirmed.fold<int>(
              0,
              (sum, e) => sum + ((e['total'] ?? 0) as num).toInt(),
            );
          }

          // ✅ animar solo después de renderizar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateCount(totalConfirmadas);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTotalCard(
                  _displayedCount,
                  title: 'Total de asistencias confirmadas',
                  color: const Color(0xFFFF6C00),
                  icon: Icons.verified_user_rounded,
                ),
                const SizedBox(height: 18),
                _buildSection('Promotores', data['assistances'], 'assistances'),
                _buildSection('Asistencias Confirmadas', data['confirmedAssistances'], 'confirmedAssistances'),
                _buildSection('Asistencias por Programa', data['assistancesByPrograma'], 'assistancesByPrograma'),
                _buildSection('Cómo se enteraron', data['assistancesByEnteroEvento'], 'assistancesByEnteroEvento'),
                _buildSection('Por Edad', data['porEdad'], 'porEdad'),
                _buildSection('Por Artista', data['porArtista'], 'porArtista'),
                _buildSection('Por Disfraz', data['porDisfraz'], 'porDisfraz'),
                _buildSection('Internos vs Externos', data['internosExternos'], 'internosExternos'),
                const SizedBox(height: 40),
                _buildExportButton(notifier, data),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orangeAccent),
              SizedBox(height: 12),
              Text('Cargando reportes...',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
        error: (err, st) => _buildErrorState(err, notifier),
      ),
    );
  }

  // 🔹 Sección (tabla o gráfica según modo)
  Widget _buildSection(String title, dynamic list, String key) {
    if (list == null || list is! List || list.isEmpty) return const SizedBox.shrink();

    final isDesc = _sortDescending[key] ?? true;
    final sortedList = [...list]
      ..sort((a, b) =>
          isDesc
              ? ((b['total'] ?? 0) as num).compareTo((a['total'] ?? 0) as num)
              : ((a['total'] ?? 0) as num).compareTo((b['total'] ?? 0) as num));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: !_showCharts
          ? _buildSortableTableSection(title, sortedList, key, isDesc)
          : _buildAdaptiveChart(title, sortedList),
    );
  }

  // 🔸 Tabla ordenable
  Widget _buildSortableTableSection(String title, List<dynamic> list, String key, bool isDesc) {
    final total = list.fold<int>(0, (p, e) => p + ((e['total'] ?? 0) as num).toInt());

    return Card(
      color: const Color(0xFF1A1A2E),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  tooltip: 'Ordenar ${isDesc ? "ascendente" : "descendente"}',
                  onPressed: () => _toggleSort(key),
                  icon: Icon(
                    isDesc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  for (var e in list)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${e.values.first}',
                              style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                        Text('${e['total']}',
                            style: const TextStyle(
                                color: Color(0xFF00FF9C),
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                  const Divider(color: Colors.white12, thickness: 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:',
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                      Text('$total',
                          style: const TextStyle(
                              color: Color(0xFF00FF9C),
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

  // 📊 Gráfica adaptativa (pastel o barras)
  Widget _buildAdaptiveChart(String title, List<dynamic> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    final total = list.fold<num>(0, (sum, e) => sum + ((e['total'] ?? 0) as num));
    final isMany = list.length > 5;

    final colors = [
      const Color(0xFFFF6C00),
      const Color(0xFF00FF9C),
      const Color(0xFF9B59B6),
      const Color(0xFFFF007F),
      const Color(0xFF00CFFF),
      const Color(0xFFFFD60A),
      const Color(0xFF2ECC71),
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
    ];

    return Card(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            if (isMany)
              SizedBox(
                height: (list.length * 38).clamp(180, 400).toDouble(),
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= list.length) return const SizedBox();
                            final label = list[i].values.first.toString();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label.length > 10 ? '${label.substring(0, 10)}…' : label,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(list.length, (i) {
                      final e = list[i];
                      final valor = (e['total'] ?? 0) as num;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: valor.toDouble(),
                            color: colors[i % colors.length],
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 45,
                    sections: List.generate(list.length, (i) {
                      final e = list[i];
                      final valor = (e['total'] ?? 0) as num;
                      final label = e.values.first.toString();
                      final porcentaje = total == 0 ? 0 : (valor / total * 100);
                      return PieChartSectionData(
                        color: colors[i % colors.length],
                        value: valor.toDouble(),
                        title:
                            '${label.length > 10 ? label.substring(0, 10) + "…" : label}\n${porcentaje.toStringAsFixed(1)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                            color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                      );
                    }),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: List.generate(list.length, (i) {
                final e = list[i];
                final label = e.values.first.toString();
                final valor = (e['total'] ?? 0) as num;
                final porcentaje = total == 0 ? 0 : (valor / total * 100);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$label (${valor.toInt()} / ${porcentaje.toStringAsFixed(1)}%)',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Total: ${total.toInt()}',
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Tarjeta total (animada)
  Widget _buildTotalCard(int total,
      {String title = 'Total de asistentes',
      Color color = Colors.orangeAccent,
      IconData icon = Icons.people_alt_rounded}) {
    return Card(
      color: const Color(0xFF1A1A2E),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$title: $total',
                key: ValueKey(total),
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(ReportesNotifier notifier, Map<String, dynamic> data) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.download_rounded, color: Colors.black),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: () async {
        final path = await notifier.exportToExcel(data);
        Fluttertoast.showToast(msg: 'Excel exportado 🎃');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Reporte exportado. ¿Abrir archivo?'),
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.orangeAccent,
              onPressed: () => OpenFilex.open(path),
            ),
          ));
        }
      },
      label: const Text('Exportar a Excel'),
    );
  }

  Widget _buildErrorState(Object err, ReportesNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 10),
          Text('Error al cargar reportes:\n$err',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            onPressed: () => notifier.fetchReportes(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ReportesNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 60, color: Colors.orangeAccent),
          const SizedBox(height: 12),
          const Text('Sin datos aún',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => notifier.fetchReportes(),
            label: const Text('Actualizar reportes'),
          ),
        ],
      ),
    );
  }
}
