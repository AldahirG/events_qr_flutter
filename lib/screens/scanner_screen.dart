// lib/screens/scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_theme.dart';
import '../providers/evento_activo_provider.dart';
import '../providers/qr_provider.dart';
import '../providers/registro_conferencia_provider.dart';

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

  // Combined confirm + acompañantes dialog
  // Returns: null = cancelled | int = confirmed (0 = no companions, N = N companions)
  Future<int?> _showScanDialog(dynamic registro, int id) async {
    int acomp = (registro.acompanantes as int?) ?? 0;

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Confirmar asistencia',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Person info
              Text(
                registro.nombreCompleto?.isNotEmpty == true
                    ? registro.nombreCompleto
                    : 'ID: $id',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              if ((registro.programaInteres as String? ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    registro.programaInteres as String,
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 13),
                  ),
                ),
              if ((registro.nombreInvito as String? ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: AppColors.textSub),
                      const SizedBox(width: 4),
                      Text(
                        'Invitado por ${registro.nombreInvito}',
                        style: const TextStyle(
                            color: AppColors.textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 14),

              // Acompañantes stepper
              Row(
                children: [
                  const Icon(Icons.group_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Acompañantes',
                      style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                  // minus button
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: acomp > 0
                        ? () => setLocal(() => acomp--)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.remove_circle_outline,
                        color: acomp > 0
                            ? AppColors.error
                            : AppColors.divider,
                        size: 28,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$acomp',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  // plus button
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setLocal(() => acomp++),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSub)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, acomp),
              child: Text(
                acomp > 0
                    ? 'Confirmar (+$acomp)'
                    : 'Confirmar',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (code == null) return;

    final id = int.tryParse(code);
    if (id == null) {
      _snack('QR inválido: no contiene un ID numérico', error: true);
      return;
    }

    final evento = ref.read(eventoActivoProvider);
    if (!evento.tieneEvento) {
      _snack('Sin evento activo. Ve a Configuración.', error: true);
      return;
    }

    setState(() => _scanned = true);

    try {
      final registro = await ref
          .read(registroConferenciaProvider.notifier)
          .getById(id);

      if (!mounted) return;

      if (registro.asistioConfirmado) {
        _snack('Asistencia ya confirmada para ${registro.nombreCompleto}',
            isWarning: true);
        return;
      }

      // Single dialog: confirm + acompañantes in one step
      final acompResult = await _showScanDialog(registro, id);
      if (acompResult == null || !mounted) return; // cancelled

      final result = await ref
          .read(registroConferenciaProvider.notifier)
          .confirmarAsistencia(id);

      if (!mounted) return;

      if (result == 'ok') {
        // Save acompañantes if user changed the value
        final initialAcomp = registro.acompanantes ?? 0;
        if (acompResult != initialAcomp) {
          await ref
              .read(registroConferenciaProvider.notifier)
              .actualizarAcompanantes(id, acompResult);
        }

        _snack(acompResult > 0
            ? 'Confirmado: ${registro.nombreCompleto} +$acompResult acomp.'
            : 'Asistencia confirmada: ${registro.nombreCompleto}');
        await ref
            .read(qrListProvider.notifier)
            .addFromQr(code, name: registro.nombreCompleto);
      } else if (result == 'ya_confirmada') {
        _snack('Ya estaba confirmada', isWarning: true);
      }
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}', error: true);
    }
  }

  void _snack(String msg, {bool error = false, bool isWarning = false}) {
    final color = error
        ? AppColors.error
        : isWarning
            ? AppColors.warning
            : AppColors.success;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      content: Text(msg,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final evento = ref.watch(eventoActivoProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Escanear QR'),
            if (evento.tieneEvento)
              Text(
                evento.eventoSeleccionado,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? Colors.yellow : Colors.white70,
            ),
            tooltip: 'Linterna',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // No event overlay
          if (!evento.tieneEvento)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_rounded,
                          color: AppColors.warning, size: 40),
                      SizedBox(height: 12),
                      Text(
                        'Sin evento activo',
                        style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configura un evento en Ajustes\npara escanear asistencias.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.textSub, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Scan frame
          if (evento.tieneEvento)
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _scanned
                        ? AppColors.success
                        : AppColors.primaryLight,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _scanned
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

          // Hint
          if (evento.tieneEvento)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 28),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'Apunta la cámara al código QR',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // "Scan another" button
          if (_scanned)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Escanear otro',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _scanned = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
