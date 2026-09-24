// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../providers/app_event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/evento_activo_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _pickMonth() async {
    final eventoState = ref.read(eventoActivoProvider);
    DateTime initial;
    try {
      final parts = eventoState.mes.split('-');
      initial = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      initial = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Selecciona un mes',
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;
    final mes = DateFormat('yyyy-MM').format(picked);
    await ref.read(eventoActivoProvider.notifier).setMes(mes);
  }

  Future<void> _selectEvento(String conferencista) async {
    await ref.read(eventoActivoProvider.notifier).setEvento(conferencista);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Evento activo: $conferencista',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(eventoActivoProvider);
    final appEvent = ref.watch(appEventProvider);
    final isHalloween = appEvent == AppEvent.halloween;
    final df = DateFormat('MMMM yyyy', 'es_MX');

    DateTime? mesDate;
    try {
      if (s.mes.isNotEmpty) {
        final parts = s.mes.split('-');
        mesDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (_) {}

    final bg      = isHalloween ? HalloweenColors.bg      : AppColors.bg;
    final surface = isHalloween ? HalloweenColors.surface  : AppColors.card;
    final accent  = isHalloween ? HalloweenColors.secondary: AppColors.primary;
    final textCol = isHalloween ? HalloweenColors.text     : AppColors.text;
    final subCol  = isHalloween ? HalloweenColors.textSub  : AppColors.textSub;
    final divCol  = isHalloween ? HalloweenColors.divider  : AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isHalloween ? HalloweenColors.surface : null,
        elevation: isHalloween ? 0 : null,
        centerTitle: isHalloween,
        title: isHalloween
            ? const Text('Ajustes 🎃',
                style: TextStyle(
                    color: HalloweenColors.secondary,
                    fontWeight: FontWeight.bold))
            : const Text('Configuración'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded,
                color: isHalloween ? HalloweenColors.secondary : null),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Active event banner ────────────────────────────────────────
          if (s.tieneEvento)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isHalloween
                    ? HalloweenColors.primary
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isHalloween
                        ? Icons.whatshot_rounded
                        : Icons.event_available_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Evento activo',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text(
                          s.eventoSeleccionado,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Conferencias only: Month + conferencista picker ───────────
          if (!isHalloween) ...[
            _SectionTitle('Mes del evento', subCol),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: divCol),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded,
                        color: accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mesDate != null
                            ? df.format(mesDate).toUpperCase()
                            : 'Toca para seleccionar mes',
                        style: TextStyle(
                          color: mesDate != null ? textCol : subCol,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: subCol),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),
            _SectionTitle('Conferencistas disponibles', subCol),
            const SizedBox(height: 8),

            if (s.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(color: accent),
                ),
              )
            else if (s.error != null)
              _ErrorBanner(message: s.error!)
            else if (s.conferencistasDisponibles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'Sin eventos para este mes.\nSelecciona otro mes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subCol),
                  ),
                ),
              )
            else
              ...s.conferencistasDisponibles.map(
                (c) {
                  final isSelected = c == s.eventoSeleccionado;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _selectEvento(c),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accent.withValues(alpha: 0.08)
                              : surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? accent : divCol,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? accent : subCol,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                c,
                                style: TextStyle(
                                  color: isSelected ? accent : textCol,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: accent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],

          // ── Halloween: info estática ────────────────────────────────────
          if (isHalloween) ...[
            _SectionTitle('Evento', subCol),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.whatshot_rounded, color: accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Halloween Fest 2026 — evento único.\n'
                      'Los registros se cargan directo de la base de datos.',
                      style: TextStyle(color: subCol, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Change event ───────────────────────────────────────────────
          _SectionTitle('Tipo de evento', subCol),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              ref.read(eventConfirmedProvider.notifier).state = false;
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divCol),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cambiar evento',
                            style: TextStyle(
                                color: textCol,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        Text(
                          'Activo: ${ref.watch(appEventProvider).displayName}',
                          style: TextStyle(color: subCol, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: subCol),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              child: Text(message,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}
