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

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final code = barcode?.rawValue;
    if (code == null || code.isEmpty) return;

    final id = int.tryParse(code);
    if (id == null) return;

    setState(() => _scanned = true);

    try {
      final registro = await ref.read(registroProvider.notifier).getById(id);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar asistencia'),
          content: Text('¿Confirmar asistencia para "${registro.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, confirmar'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await ref.read(registroProvider.notifier).update(id, {'asistio': 1});

        // Guardar localmente el QR leído
        await ref.read(qrListProvider.notifier).addFromQr(code, name: registro.nombre ?? 'QR escaneado');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Asistencia confirmada para ${registro.nombre}')),
          );
        }
      } else {
        setState(() => _scanned = false); // permitir otro escaneo
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código QR'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
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
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: c.primary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Apunta la cámara al código QR',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          if (_scanned)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Escanear otro'),
                  onPressed: () => setState(() => _scanned = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
