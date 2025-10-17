import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../models/registro.dart';
import '../providers/registro_provider.dart';

final qrBoxProvider = Provider<Box<Event>>((ref) {
  return Hive.box<Event>('events');
});

/// Lista de eventos locales escaneados desde QR.
final qrListProvider = StateNotifierProvider<QrListNotifier, List<Event>>((ref) {
  final box = ref.watch(qrBoxProvider);
  return QrListNotifier(box, ref);
});

class QrListNotifier extends StateNotifier<List<Event>> {
  final Box<Event> _box;
  final Ref ref;
  StreamSubscription? _sub;

  QrListNotifier(this._box, this.ref) : super([]) {
    load();
    _sub = _box.watch().listen((_) => load());
  }

  void load() {
    state = _box.values.toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
  }

  Future<void> addFromQr(String qrValue, {String? name}) async {
    try {
      final id = int.tryParse(qrValue);
      if (id == null) {
        throw Exception('QR inválido: no es un ID numérico');
      }

      // ⚠️ Ahora accedemos al registroProvider solo cuando se necesita
      final registroNotifier = ref.read(registroProvider.notifier);
      final registro = await registroNotifier.getById(id);

      if (registro.asistio == true || registro.asistio == 1) {
        throw Exception('Asistencia ya confirmada');
      }

      await registroNotifier.update(id, {'asistio': 1});

      final localEvent = Event(
        id: const Uuid().v4(),
        qrValue: qrValue,
        name: registro.nombre ?? 'Confirmado',
        createdAt: DateTime.now(),
      );

      await _box.put(localEvent.id, localEvent);
      load();
    } catch (e) {
      print('Error al procesar QR: $e');
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    load();
  }

  Future<void> clearAll() async {
    await _box.clear();
    load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
