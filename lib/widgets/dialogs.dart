// lib/widgets/dialogs.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/registro_conferencia_provider.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

/// Shows a stepper (+/–) dialog to adjust companion count.
///
/// [initialCount] — current value already stored for this registro
/// (e.g. set during registration).  The stepper starts at this value so the
/// user sees the current count and only needs to adjust it.
///
/// PATCH is only called when the user confirms AND the new value differs
/// from [initialCount], avoiding a pointless overwrite.
/// "Omitir" always closes without writing.
Future<void> showAcompanantesDialog(
  BuildContext context,
  WidgetRef ref, {
  required int registroId,
  required String nombre,
  int initialCount = 0,
}) async {
  int cantidad = initialCount;

  final result = await showDialog<int?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.group_outlined, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Acompañantes',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Cuántos acompañantes trae\n${nombre.isNotEmpty ? nombre : "el asistente"}?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSub, fontSize: 13),
            ),
            if (initialCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Registrado actualmente: $initialCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: cantidad > 0 ? AppColors.error : AppColors.divider,
                    size: 32,
                  ),
                  onPressed:
                      cantidad > 0 ? () => setLocal(() => cantidad--) : null,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$cantidad',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  onPressed: () => setLocal(() => cantidad++),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Omitir',
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, cantidad),
            child: const Text('Confirmar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );

  // Only PATCH if user confirmed AND value actually changed.
  if (result != null && result != initialCount && context.mounted) {
    await ref
        .read(registroConferenciaProvider.notifier)
        .actualizarAcompanantes(registroId, result);
  }
}
