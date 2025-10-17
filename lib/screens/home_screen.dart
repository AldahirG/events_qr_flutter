import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../providers/registro_provider.dart';
import 'list_screen.dart';
import 'register_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _mostrarTexto = false;

  @override
  void initState() {
    super.initState();
    // refresca lista al entrar
        Future.microtask(() async {
      try {
        await ref.read(registroProvider.notifier).fetchInitial();
      } catch (e) {
        debugPrint('Error al cargar registros: $e');
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mostrarTexto = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(registroProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('HalloweenFest')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'lib/assets/animations/pamkin.json',
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.width * 0.6,
                repeat: false,
                animate: true,
              ),
              const SizedBox(height: 24),

              if (_mostrarTexto)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: 1,
                  child: Column(
                    children: [
                      Text(
                        'Registros activos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Error: ${state.errorMessage}',
                            style: TextStyle(color: colors.error),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Text(
                          '${state.items.length}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Acciones principales
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.list_alt_rounded,
                    label: 'Ver registros',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ListScreen()),
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Nuevo registro',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Escanear QR',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScannerScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => ref.read(registroProvider.notifier).fetchInitial(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: c.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: c.onSurface)),
          ],
        ),
      ),
    );
  }
}