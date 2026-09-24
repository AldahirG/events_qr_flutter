// lib/screens/list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../models/registro_conferencia.dart';
import '../providers/app_event_provider.dart';
import '../providers/evento_activo_provider.dart';
import '../providers/registro_conferencia_provider.dart';
import '../widgets/dialogs.dart';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      _searchCtrl.clear();
      ref.read(registroConferenciaProvider.notifier).fetchInitial();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _confirmAsistencia(
    BuildContext context,
    int id,
    String nombre,
    bool yaConfirmado,
    int acompanantesCurrent,
  ) async {
    if (yaConfirmado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          content: Text(
            'Ya confirmada: ${nombre.isNotEmpty ? nombre : "ID $id"}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar asistencia',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre.isNotEmpty ? nombre : 'ID: $id',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text('¿Marcar asistencia como confirmada?',
                style: TextStyle(color: AppColors.textSub, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final result = await ref
        .read(registroConferenciaProvider.notifier)
        .confirmarAsistencia(id);

    if (!mounted) return;
    if (result == 'ok') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Asistencia confirmada: ${nombre.isNotEmpty ? nombre : "ID $id"}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      // Ask for companion count — start stepper at existing value
      if (mounted) {
        await showAcompanantesDialog(
          context,
          ref,
          registroId: id,
          nombre: nombre,
          initialCount: acompanantesCurrent,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Ya estaba confirmada',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep text field in sync when query is reset externally (provider rebuild, fetchInitial, etc.)
    ref.listen(
      registroConferenciaProvider.select((s) => s.query),
      (_, next) {
        if (next.isEmpty && _searchCtrl.text.isNotEmpty) _searchCtrl.clear();
      },
    );

    final prov = ref.watch(registroConferenciaProvider);
    final evento = ref.watch(eventoActivoProvider);
    final appEvent = ref.watch(appEventProvider);
    final isHalloween = appEvent == AppEvent.halloween;

    final bg = isHalloween ? HalloweenColors.bg : AppColors.bg;
    final accent = isHalloween ? HalloweenColors.secondary : AppColors.primary;
    final cardFill = isHalloween ? HalloweenColors.surface : AppColors.card;
    final dividerColor =
        isHalloween ? HalloweenColors.divider : AppColors.divider;
    final textColor = isHalloween ? HalloweenColors.text : AppColors.text;
    final subColor = isHalloween ? HalloweenColors.textSub : AppColors.textSub;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isHalloween ? HalloweenColors.surface : null,
        elevation: isHalloween ? 0 : null,
        centerTitle: isHalloween,
        title: isHalloween
            ? const Text(
                'Registros 🎃',
                style: TextStyle(
                    color: HalloweenColors.secondary,
                    fontWeight: FontWeight.bold),
              )
            : Column(
                children: [
                  const Text('Registros'),
                  if (evento.tieneEvento)
                    Text(
                      evento.eventoSeleccionado,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            onPressed: () =>
                ref.read(registroConferenciaProvider.notifier).refresh(),
            icon: Icon(Icons.refresh_rounded,
                color: isHalloween ? HalloweenColors.secondary : null),
          ),
          if (isHalloween)
            IconButton(
              tooltip: 'Filtros',
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded,
                  color: HalloweenColors.secondary),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (_, value, __) => TextField(
                controller: _searchCtrl,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o ID…',
                  hintStyle: TextStyle(color: subColor),
                  prefixIcon: Icon(Icons.search_rounded, color: accent),
                  filled: true,
                  fillColor: cardFill,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(registroConferenciaProvider.notifier)
                                .clearQuery();
                          },
                          icon: Icon(Icons.close_rounded, color: subColor),
                        ),
                ),
                onChanged: (q) => ref
                    .read(registroConferenciaProvider.notifier)
                    .setQuery(q.trim()),
              ),
            ),
          ),

          // ── Summary chip ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                backgroundColor:
                    isHalloween ? HalloweenColors.surface : AppColors.surface,
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                label: Text(
                  'Mostrados: ${prov.items.length}${prov.total != null ? " / ${prov.total}" : ""}',
                  style: TextStyle(color: accent, fontSize: 12),
                ),
                avatar: Icon(Icons.list_alt_rounded, size: 16, color: accent),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: accent,
              onRefresh: () =>
                  ref.read(registroConferenciaProvider.notifier).refresh(),
              child: Builder(
                builder: (ctx) {
                  if (!evento.tieneEvento) return const _NoEventState();
                  if (prov.isLoading && prov.items.isEmpty)
                    return _Loader(accent: accent);
                  if (prov.errorMessage != null && prov.items.isEmpty)
                    return _ErrorState(
                      message: prov.errorMessage!,
                      accent: accent,
                      onRetry: () => ref
                          .read(registroConferenciaProvider.notifier)
                          .fetchInitial(),
                    );
                  if (prov.items.isEmpty) return _EmptyState(subColor: subColor);

                  return ListView.separated(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: prov.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = prov.items[i];
                      return _RegistroTile(
                        registro: r,
                        isHalloween: isHalloween,
                        onTap: () => context.push('/show-info/${r.id}'),
                        onDoubleTap: () => _confirmAsistencia(
                          context,
                          r.id,
                          r.nombreCompleto,
                          r.asistioConfirmado,
                          r.acompanantes ?? 0,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: accent,
        onPressed: () => _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
      ),
    );
  }
}

class _RegistroTile extends StatelessWidget {
  final RegistroConferencia registro;
  final bool isHalloween;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  const _RegistroTile({
    required this.registro,
    required this.isHalloween,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = registro.nombreCompleto;
    final tel = (registro.telefono ?? '').trim();
    final prog = (registro.programaInteres ?? '').trim();
    final confirmado = registro.asistioConfirmado;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    final accent =
        isHalloween ? HalloweenColors.secondary : AppColors.primary;
    final cardColor =
        isHalloween ? HalloweenColors.surface : AppColors.card;
    final borderColor = confirmado
        ? AppColors.success.withValues(alpha: 0.5)
        : isHalloween
            ? HalloweenColors.divider
            : AppColors.divider;
    final textColor =
        isHalloween ? HalloweenColors.text : AppColors.text;
    final subColor =
        isHalloween ? HalloweenColors.textSub : AppColors.textSub;
    final chipBg = isHalloween ? HalloweenColors.input : AppColors.surface;

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Card(
        color: cardColor,
        elevation: isHalloween ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: isHalloween && confirmado ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: accent,
            child: Text(
              inicial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            nombre.isNotEmpty ? nombre : 'Sin nombre',
            style:
                TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tel.isNotEmpty)
                Text(tel,
                    style: TextStyle(color: subColor, fontSize: 12)),
              if (prog.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(prog,
                        style:
                            TextStyle(color: accent, fontSize: 11)),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Badge(
                label: confirmado ? 'Asistió' : 'Pendiente',
                color: confirmado ? AppColors.success : AppColors.warning,
                icon: confirmado
                    ? Icons.check_circle_outline
                    : Icons.hourglass_bottom_outlined,
              ),
              if ((registro.acompanantes ?? 0) > 0) ...[
                const SizedBox(height: 4),
                _Badge(
                  label: '+${registro.acompanantes}',
                  color: accent,
                  icon: Icons.group_outlined,
                ),
              ],
            ],
          ),
          onTap: onTap,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  final Color accent;
  const _Loader({required this.accent});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: accent),
          const SizedBox(height: 12),
          const Text('Cargando registros…',
              style: TextStyle(color: AppColors.textSub)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color subColor;
  const _EmptyState({required this.subColor});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: subColor),
          const SizedBox(height: 8),
          const Text('Sin resultados', style: TextStyle(color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Ajusta tu búsqueda',
              style: TextStyle(color: subColor, fontSize: 13)),
        ],
      ),
    );
  }
}

class _NoEventState extends StatelessWidget {
  const _NoEventState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_rounded,
              size: 40, color: AppColors.warning),
          const SizedBox(height: 8),
          const Text('Sin evento activo',
              style: TextStyle(color: AppColors.text, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Configura un evento en Ajustes',
              style: TextStyle(color: AppColors.textSub, fontSize: 13)),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            label: const Text('Ir a Ajustes',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Color accent;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.message, required this.accent, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: accent),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSub)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
