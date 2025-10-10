import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

final eventoProvider = StateNotifierProvider<EventoNotifier, String>((ref) {
  return EventoNotifier(ref);
});

class EventoNotifier extends StateNotifier<String> {
  final Ref ref;
  static const String _boxName = 'settings';
  static const String _key = 'eventoSeleccionado';

  EventoNotifier(this.ref) : super('') {
    _loadEvento();
  }

  // Cargar evento desde Hive al iniciar
  Future<void> _loadEvento() async {
    final box = await Hive.openBox(_boxName);
    state = box.get(_key, defaultValue: '');
  }

  // Actualizar evento en Hive y en el estado
  Future<void> setEvento(String evento) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, evento);
    state = evento;
  }
}
