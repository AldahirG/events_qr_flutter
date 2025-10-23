import 'package:events_qr_flutter/models/registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/registro_provider.dart';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(registroProvider.notifier).fetchInitial());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = ref.watch(registroProvider);

    // 🎃 Colores HalloweenFest
    final darkBg = const Color(0xFF12101C);
    final cardColor = const Color(0xFF1E1B2D);
    final orange = const Color(0xFFFF6B00);
    final accent = const Color(0xFFFFAE42);
    final green = const Color(0xFF64FF6A);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: const Text(
          'Registros 🎃',
          style: TextStyle(
            color: Color(0xFFFF6B00),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Limpiar filtros',
            onPressed: () {
              setState(() {
                _selectedMonth = null;
                _searchCtrl.clear();
              });
              ref.read(registroProvider.notifier).clearFiltersAndReload();
            },
            icon: const Icon(Icons.filter_alt_off_outlined,
                color: Color(0xFFFFAE42)),
          ),
          IconButton(
            tooltip: 'Elegir mes',
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth ?? DateTime(now.year, now.month, 1),
                firstDate: DateTime(now.year - 3, 1, 1),
                lastDate: DateTime(now.year + 3, 12, 31),
                helpText: 'Selecciona una fecha del mes a filtrar',
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: orange,
                      surface: cardColor,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                final month = DateTime(picked.year, picked.month, 1);
                setState(() => _selectedMonth = month);
                ref.read(registroProvider.notifier).filterByMonth(month);
              }
            },
            icon:
                const Icon(Icons.calendar_month_outlined, color: Colors.orange),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, teléfono o ID…',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    isDense: true,
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: orange.withOpacity(0.6), width: 1),
                    ),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(registroProvider.notifier).setQuery('');
                            },
                            icon:
                                const Icon(Icons.close, color: Colors.orange),
                          ),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (q) =>
                      ref.read(registroProvider.notifier).setQuery(q.trim()),
                  onSubmitted: (_) =>
                      ref.read(registroProvider.notifier).applySearch(),
                );
              },
            ),
          ),
          _FiltersSummary(
            month: _selectedMonth,
            total: prov.total,
            visibles: prov.items.length,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              color: orange,
              onRefresh: () => ref.read(registroProvider.notifier).refresh(),
              child: Builder(
                builder: (context) {
                  if (prov.isLoading && prov.items.isEmpty) {
                    return const _CenteredLoader(label: 'Cargando…');
                  }

                  if (prov.errorMessage != null && prov.items.isEmpty) {
                    return _ErrorState(
                      message: prov.errorMessage!,
                      onRetry: () => ref
                          .read(registroProvider.notifier)
                          .fetchInitial(),
                    );
                  }

                  if (prov.items.isEmpty) {
                    return const _EmptyState();
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notif) {
                      if (notif.metrics.pixels >=
                              notif.metrics.maxScrollExtent - 200 &&
                          !prov.isPaginating &&
                          prov.hasMore) {
                        ref
                            .read(registroProvider.notifier)
                            .fetchNextPage();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount:
                          prov.items.length + (prov.isPaginating ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= prov.items.length) {
                          return const _BottomLoader();
                        }
                        final r = prov.items[index];
                        return _RegistroTile(
                          registro: r,
                          cardColor: cardColor,
                          orange: orange,
                          accent: accent,
                          green: green,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: orange,
        tooltip: 'Arriba',
        onPressed: () => _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.black),
      ),
    );
  }
}

class _RegistroTile extends ConsumerWidget {
  final Registro registro;
  final Color cardColor;
  final Color orange;
  final Color accent;
  final Color green;

  const _RegistroTile({
    required this.registro,
    required this.cardColor,
    required this.orange,
    required this.accent,
    required this.green,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = registro.nombreCompleto;
    final telefono = (registro.telefono ?? '').trim();
    final programa = (registro.programa ?? '').trim();
    final folio = registro.folio;
    final fecha = registro.fechaRegistro;
    final df = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');
    final fechaStr = df.format(fecha);
    final asistio = registro.asistio == true;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: orange.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: orange.withOpacity(0.9),
          child: Text(
            (nombre.isNotEmpty ? nombre[0] : '#').toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        title: Text(
          nombre.isNotEmpty ? nombre : 'Sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (telefono.isNotEmpty)
              Text(
                telefono,
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: -4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (programa.isNotEmpty)
                  Chip(
                    backgroundColor: orange.withOpacity(0.15),
                    label: Text(
                      programa,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: orange.withOpacity(0.4)),
                  ),
                Chip(
                  backgroundColor: accent.withOpacity(0.15),
                  label: Text(
                    'ID: $folio',
                    style: TextStyle(color: accent),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  backgroundColor: green.withOpacity(0.12),
                  label: Text(
                    fechaStr,
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: Icon(Icons.schedule, size: 16, color: green),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: green.withOpacity(0.3)),
                ),
              ],
            ),
          ],
        ),
        trailing: _Badge(
          label: asistio ? 'Asistió' : 'Pendiente',
          color: asistio ? green : orange,
          icon: asistio
              ? Icons.event_available_outlined
              : Icons.hourglass_bottom_outlined,
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            useRootNavigator: false,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: cardColor,
              title: Text('Confirmar asistencia',
                  style: TextStyle(color: orange)),
              content: Text(
                '¿Confirmar asistencia de "$nombre"?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Sí, confirmar'),
                ),
              ],
            ),
          );

          if (confirmed != true) return;

          await ref.read(registroProvider.notifier).update(
            registro.id,
            {'asistio': 1},
          );

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: cardColor,
              content: Text(
                '✅ Asistencia confirmada',
                style: TextStyle(color: green),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Badge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersSummary extends StatelessWidget {
  final DateTime? month;
  final int? total;
  final int visibles;
  const _FiltersSummary({
    required this.month,
    required this.total,
    required this.visibles,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMMM yyyy', 'es_MX');
    final orange = const Color(0xFFFF6B00);

    final chips = <Widget>[];

    if (month != null) {
      chips.add(
        Chip(
          backgroundColor: orange.withOpacity(0.15),
          label: Text('Mes: ${df.format(month!)}',
              style: const TextStyle(color: Colors.orangeAccent)),
          avatar: const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
        ),
      );
    }

    chips.add(
      Chip(
        backgroundColor: orange.withOpacity(0.1),
        label: Text('Mostrados: $visibles${total != null ? ' / $total' : ''}',
            style: const TextStyle(color: Colors.orangeAccent)),
        avatar: const Icon(Icons.list_alt, size: 18, color: Colors.orange),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: chips
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: c,
                ))
            .toList(),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  final String label;
  const _CenteredLoader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.orangeAccent),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.orangeAccent),
          SizedBox(height: 8),
          Text('Sin resultados', style: TextStyle(color: Colors.white)),
          SizedBox(height: 4),
          Text(
            'Ajusta tu búsqueda o filtros',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: const [
          CircularProgressIndicator(
              strokeWidth: 2, color: Colors.orangeAccent),
          SizedBox(height: 8),
          Text('Cargando más…', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
