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
    final state = ref.watch(registroProvider);

    // 🎃 Paleta temática
    const darkBg = Color(0xFF12101C);
    const purpleDark = Color(0xFF1E1B2D);
    const orange = Color(0xFFFF6B00);
    const neon = Color(0xFFFFAE42);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: purpleDark,
        title: const Text(
          'HalloweenFest 🎃',
          style: TextStyle(
            color: orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 🌌 Fondo decorativo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D0B16), Color(0xFF1A1728)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 👻 Murciélagos flotando
          Positioned(
            top: 40,
            left: 30,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('lib/assets/images/bats_left.png', width: 80),
            ),
          ),
          Positioned(
            top: 60,
            right: 40,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('lib/assets/images/bats_right.png', width: 100),
            ),
          ),

          // 🎃 Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación principal
                  Lottie.asset(
                    'lib/assets/animations/pamkin.json',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.width * 0.6,
                    repeat: true,
                    animate: true,
                  ),

                  const SizedBox(height: 12),

                  // 🕯️ Subtítulo con efecto
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: _mostrarTexto ? 1 : 0,
                    child: Column(
                      children: [
                        const Text(
                          'Registros activos',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: orange,
                              ),
                            ),
                          )
                        else if (state.errorMessage != null)
                          Text(
                            'Error: ${state.errorMessage}',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            '${state.items.length}',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: orange,
                              shadows: [
                                Shadow(
                                  color: neon,
                                  blurRadius: 12,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🧙‍♂️ Botones principales
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.list_alt_rounded,
                        label: 'Ver registros',
                        color: neon,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ListScreen()),
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Nuevo registro',
                        color: orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Escanear QR',
                        color: Colors.deepPurpleAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScannerScreen()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón actualizar con ícono giratorio
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(registroProvider.notifier).fetchInitial(),
                    icon: const Icon(Icons.refresh_rounded, color: neon),
                    label: const Text(
                      'Actualizar',
                      style: TextStyle(color: neon),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 👁‍🗨 Footer decorativo
                  const Text(
                    'Halloween Edition v1.0',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
