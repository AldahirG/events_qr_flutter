import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/qr_provider.dart';
import '../providers/registro_provider.dart';
import '../models/registro.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final code = barcode?.rawValue;
    if (code == null || code.isEmpty) return;

    final id = int.tryParse(code);
    if (id == null) return;

    setState(() => _scanned = true);

    try {
      final registro = await ref.read(registroProvider.notifier).getById(id);

      // ⚠️ Si ya está confirmada la asistencia, mostrar aviso y salir
      if (registro.asistio == true || registro.asistio == 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Asistencia ya confirmada ⚠️',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }
        return; // 🚫 No preguntar de nuevo si ya estaba confirmada
      }

      // Si no estaba confirmada, pedir confirmación
      final confirm = await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (ctx) {
          const orange = Color(0xFFFF6B00);
          const purpleDark = Color(0xFF1E1B2D);

          return AlertDialog(
            backgroundColor: purpleDark,
            title: const Text(
              'Confirmar asistencia',
              style: TextStyle(
                color: orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '¿Confirmar asistencia para "${registro.nombre}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, confirmar'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        final result =
            await ref.read(registroProvider.notifier).confirmarAsistencia(id);

        if (result == 'ok') {
          // ✅ Asistencia confirmada con éxito
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF1E1B2D),
                content: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Color(0xFF64FF6A), size: 20),
                    SizedBox(width: 8),
                    Text('Asistencia confirmada ✅',
                        style: TextStyle(color: Color(0xFF64FF6A))),
                  ],
                ),
              ),
            );
          }
        } else if (result == 'ya_confirmada') {
          // ⚠️ Ya estaba confirmada (por si backend lo detecta)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.orangeAccent,
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text('Asistencia ya confirmada ⚠️',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }
        }

        await ref
            .read(qrListProvider.notifier)
            .addFromQr(code, name: registro.nombre ?? 'QR escaneado');
      }
    } catch (e) {
      // ⚠️ Error general (sin conexión, servidor, etc.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Algo salió mal 😓',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      }
    }
  }

  void _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF12101C);
    const orange = Color(0xFFFF6B00);
    const neon = Color(0xFFFFAE42);
    const green = Color(0xFF64FF6A);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2D),
        title: const Text(
          'Escanear código QR 🎃',
          style: TextStyle(color: orange, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? neon : Colors.white70,
            ),
            tooltip: 'Linterna',
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 🎃 Marco de escaneo
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _scanned ? green : orange,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _scanned
                        ? green.withOpacity(0.4)
                        : orange.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // 🕸 Texto superior
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 32),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: orange.withOpacity(0.7)),
              ),
              child: const Text(
                'Apunta la cámara al código QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 🟠 Botón de "Escanear otro"
          if (_scanned)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text(
                    'Escanear otro',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => setState(() => _scanned = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
