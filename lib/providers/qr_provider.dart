import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';

final qrBoxProvider = Provider<Box<Event>>((ref) {
  return Hive.box<Event>('events'); // asegura que esté abierto en main()
});

final qrListProvider = StateNotifierProvider<QrListNotifier, List<Event>>((ref) {
  final box = ref.watch(qrBoxProvider);
  return QrListNotifier(box);
});

class QrListNotifier extends StateNotifier<List<Event>> {
  final Box<Event> _box;

  QrListNotifier(this._box) : super([]) {
    load();
  }

  void load() {
    state = _box.values.toList();
  }

  Future<void> addFromQr(String qrValue, {String? name}) async {
    final id = const Uuid().v4();
    final event = Event(id: id, qrValue: qrValue, name: name);
    await _box.put(id, event);
    load();
  }

  Future<void> addEvent(Event event) async {
    await _box.put(event.id, event);
    load();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    load();
  }

  Future<void> clearAll() async {
    await _box.clear();
    load();
  }
}
