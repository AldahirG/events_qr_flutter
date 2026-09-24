// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../core/app_animations.dart';
import '../core/app_theme.dart';
import '../providers/app_event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/evento_activo_provider.dart';
import '../providers/registro_conferencia_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final evento = ref.watch(eventoActivoProvider);
    final registros = ref.watch(registroConferenciaProvider);
    final appEvent = ref.watch(appEventProvider);
    final isHalloween = appEvent == AppEvent.halloween;

    final total = registros.all.length;
    final confirmados = registros.all.where((r) => r.asistioConfirmado).length;

    if (isHalloween) {
      return _HalloweenHome(
        total: total,
        confirmados: confirmados,
        isLoading: registros.isLoading,
        error: registros.errorMessage,
        onRefresh: () =>
            ref.read(registroConferenciaProvider.notifier).refresh(),
      );
    }

    // ── Conferencias layout ───────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Eventos UNINTER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!evento.tieneEvento)
              _NoEventBanner(onGoToSettings: () => context.go('/settings'))
            else
              _EventoBanner(
                conferencista: evento.eventoSeleccionado,
                mes: evento.mes,
              ),

            const SizedBox(height: 20),

            Center(
              child: Lottie.asset(
                AppAnimations.header(AppEvent.conferencias),
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.width * 0.5,
                repeat: true,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (evento.tieneEvento) ...[
              _StatsRow(
                total: total,
                confirmados: confirmados,
                isLoading: registros.isLoading,
              ),
              const SizedBox(height: 24),
            ],

            const Text(
              'ACCIONES RÁPIDAS',
              style: TextStyle(
                color: AppColors.textSub,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _QuickAction(
                  icon: Icons.list_alt_rounded,
                  label: 'Registros',
                  color: AppColors.primaryLight,
                  onTap: () => context.go('/list'),
                ),
                _QuickAction(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Registrar',
                  color: AppColors.primary,
                  onTap: () => context.go('/register'),
                ),
                _QuickAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Escanear QR',
                  color: AppColors.primaryDark,
                  onTap: () => context.go('/scanner'),
                ),
                _QuickAction(
                  icon: Icons.tune_rounded,
                  label: 'Configurar',
                  color: AppColors.textSub,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (evento.tieneEvento)
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(registroConferenciaProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  label: const Text('Actualizar datos',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                'Eventos UNINTER v2.0\nDesarrollado por Ecommerce UNINTER',
                style: TextStyle(
                  color: AppColors.textSub.withValues(alpha: 0.6),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Halloween home ───────────────────────────────────────────────────────────

class _HalloweenHome extends ConsumerWidget {
  final int total;
  final int confirmados;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const _HalloweenHome({
    required this.total,
    required this.confirmados,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const orange = HalloweenColors.secondary;
    const purple = HalloweenColors.primary;
    const bg = HalloweenColors.bg;
    const surface = HalloweenColors.surface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'HalloweenFest 🎃',
          style: TextStyle(
            color: orange,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: orange),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ── Pumpkin header ────────────────────────────────────────────
            SizedBox(
              height: 180,
              child: Lottie.asset(
                AppAnimations.header(AppEvent.halloween),
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.whatshot_rounded,
                  size: 100,
                  color: orange,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Stats card ────────────────────────────────────────────────
            _HwStatsCard(
              total: total,
              confirmados: confirmados,
              isLoading: isLoading,
              error: error,
              onRefresh: onRefresh,
            ),

            const SizedBox(height: 24),

            // ── Action buttons ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _HwActionCard(
                    icon: Icons.list_alt_rounded,
                    label: 'Ver registros',
                    color: orange,
                    onTap: () => context.go('/list'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HwActionCard(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Nuevo registro',
                    color: orange,
                    onTap: () => context.go('/register'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _HwActionCard(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Escanear QR',
              color: purple,
              onTap: () => context.go('/scanner'),
              fullWidth: true,
            ),

            const SizedBox(height: 24),

            Text(
              'Halloween Fest 2026\nDesarrollado por Ecommerce UNINTER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HalloweenColors.textSub.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HwStatsCard extends StatelessWidget {
  final int total;
  final int confirmados;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const _HwStatsCard({
    required this.total,
    required this.confirmados,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    const orange = HalloweenColors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HalloweenColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: orange.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: orange.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registros activos',
            style: TextStyle(
              color: HalloweenColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: orange),
            )
          else if (error != null)
            Column(
              children: [
                Text(
                  'Error: $error',
                  style: const TextStyle(
                      color: HalloweenColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, color: orange),
                  label: const Text('Reintentar',
                      style: TextStyle(color: orange)),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _HwStat(
                    value: '$total',
                    label: 'Total',
                    color: orange,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: HalloweenColors.divider,
                ),
                Expanded(
                  child: _HwStat(
                    value: '$confirmados',
                    label: 'Confirmados',
                    color: HalloweenColors.success,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HwStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _HwStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              color: HalloweenColors.textSub, fontSize: 12),
        ),
      ],
    );
  }
}

class _HwActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  const _HwActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          vertical: fullWidth ? 20 : 22,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: HalloweenColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conferencias sub-widgets ─────────────────────────────────────────────────

class _EventoBanner extends StatelessWidget {
  final String conferencista;
  final String mes;
  const _EventoBanner({required this.conferencista, required this.mes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EVENTO ACTIVO',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  conferencista,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (mes.isNotEmpty)
                  Text(mes,
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEventBanner extends StatelessWidget {
  final VoidCallback onGoToSettings;
  const _NoEventBanner({required this.onGoToSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded,
              color: AppColors.warning, size: 36),
          const SizedBox(height: 8),
          const Text(
            'Sin evento activo',
            style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configura un conferencista en Ajustes\npara comenzar a registrar asistencias.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onGoToSettings,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int total;
  final int confirmados;
  final bool isLoading;
  const _StatsRow(
      {required this.total,
      required this.confirmados,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
          label: 'Registros',
          value: isLoading ? '…' : '$total',
          color: AppColors.primary,
          icon: Icons.people_alt_rounded,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
          label: 'Asistencias',
          value: isLoading ? '…' : '$confirmados',
          color: AppColors.success,
          icon: Icons.how_to_reg_rounded,
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Text(label,
              style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
