// lib/screens/list_screen.dart
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros'),
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
            icon: const Icon(Icons.filter_alt_off_outlined),
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
              );
              if (picked != null) {
                final month = DateTime(picked.year, picked.month, 1);
                setState(() => _selectedMonth = month);
                ref.read(registroProvider.notifier).filterByMonth(month);
              }
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono o ID…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(registroProvider.notifier).setQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (q) => ref.read(registroProvider.notifier).setQuery(q.trim()),
              onSubmitted: (q) => ref.read(registroProvider.notifier).applySearch(),
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
              onRefresh: () => ref.read(registroProvider.notifier).refresh(),
              child: Builder(
                builder: (context) {
                  if (prov.isLoading && prov.items.isEmpty) {
                    return const _CenteredLoader(label: 'Cargando…');
                  }

                  if (prov.errorMessage != null && prov.items.isEmpty) {
                    return _ErrorState(
                      message: prov.errorMessage!,
                      onRetry: () => ref.read(registroProvider.notifier).fetchInitial(),
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
                        ref.read(registroProvider.notifier).fetchNextPage();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount: prov.items.length + (prov.isPaginating ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= prov.items.length) {
                          return const _BottomLoader();
                        }
                        final r = prov.items[index];
                        return _RegistroTile(registro: r);
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
        tooltip: 'Arriba',
        onPressed: () => _scroll.animateTo(0,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut),
        child: const Icon(Icons.arrow_upward_rounded),
      ),
    );
  }
}

class _RegistroTile extends ConsumerWidget {
  final dynamic registro;
  const _RegistroTile({required this.registro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = registro.id?.toString() ?? '-';
    final nombre = (registro.nombreCompleto ?? registro.nombre ?? '').toString();
    final telefono = (registro.telefono ?? '').toString();
    final programa = (registro.programa ?? '').toString();
    final folio = id.padLeft(3, '0');


    DateTime? fecha;
    try {
      final raw = registro.fechaRegistro ?? registro.createdAt ?? registro.fecha ?? null;
      if (raw is DateTime) {
        fecha = raw;
      } else if (raw is String && raw.isNotEmpty) {
        fecha = DateTime.tryParse(raw);
      }
    } catch (_) {}

    final df = DateFormat('dd/MM/yyyy HH:mm');
    final fechaStr = fecha != null ? df.format(fecha) : '—';

    final confirmado = (registro.confirmado ?? false) == true;
    final asistio = (registro.asistio == true || registro.asistio == 1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          child: Text(
            (nombre.isNotEmpty ? nombre[0] : '#').toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          nombre.isNotEmpty ? nombre : 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (telefono.isNotEmpty) Text(telefono),
            Wrap(
              spacing: 8,
              runSpacing: -4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (programa.isNotEmpty)
                  Chip(
                    label: Text(programa, overflow: TextOverflow.ellipsis),
                    visualDensity: VisualDensity.compact,
                  ),
                if (folio.isNotEmpty)
                  Chip(
                    label: Text('ID: $folio'),
                    avatar: const Icon(Icons.confirmation_number_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  label: Text(fechaStr),
                  avatar: const Icon(Icons.schedule, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Badge(
              label: confirmado ? 'Confirmado' : 'Sin confirmar',
              color: confirmado ? Colors.green : Colors.orange,
              icon: confirmado ? Icons.verified_outlined : Icons.error_outline,
            ),
            const SizedBox(height: 6),
            _Badge(
              label: asistio ? 'Asistió' : 'Pendiente',
              color: asistio ? Colors.blue : Colors.grey,
              icon: asistio ? Icons.event_available_outlined : Icons.hourglass_bottom,
            ),
          ],
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Confirmar asistencia'),
              content: Text('¿Confirmar asistencia de "$nombre"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, confirmar')),
              ],
            ),
          );
          if (confirmed == true) {
            await ref.read(registroProvider.notifier).update(
              registro.id,
              {'asistio': 1},
            );
            await ref.read(registroProvider.notifier).refresh();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asistencia confirmada')),
              );
            }
          }
        },
      ),
    );
  }
}

class _FiltersSummary extends StatelessWidget {
  final DateTime? month;
  final int? total;
  final int visibles;
  const _FiltersSummary({required this.month, required this.total, required this.visibles});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMMM yyyy', 'es_MX');
    final chips = <Widget>[];

    if (month != null) {
      chips.add(Chip(
        label: Text('Mes: ${df.format(month!)}'),
        avatar: const Icon(Icons.calendar_today, size: 18),
      ));
    }

    chips.add(Chip(
      label: Text('Mostrados: $visibles' + (total != null ? ' / $total' : '')),
      avatar: const Icon(Icons.list_alt, size: 18),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
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
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
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
        children: [
          const Icon(Icons.inbox_outlined, size: 40),
          const SizedBox(height: 8),
          const Text('Sin resultados'),
          const SizedBox(height: 4),
          Text(
            'Ajusta tu búsqueda o filtros',
            style: Theme.of(context).textTheme.bodySmall,
          )
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
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            )
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
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 8),
          Text('Cargando más…'),
        ],
      ),
    );
  }
}