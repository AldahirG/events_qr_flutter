import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../providers/evento_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  String _mesSeleccionado = DateFormat('yyyy-MM').format(DateTime.now());
  List<String> _eventos = [];
  String? _eventoSeleccionado;
  bool _loading = false;
  bool _animacionVisible = false;
  bool _mostrarDatePicker = false;

  @override
  void initState() {
    super.initState();
    _cargarEstadoInicial();
  }

  Future<void> _cargarEstadoInicial() async {
    final box = await Hive.openBox('settings');
    final evento = box.get('eventoSeleccionado', defaultValue: '');
    final mes = box.get('mesSeleccionado', defaultValue: _mesSeleccionado);

    setState(() {
      _eventoSeleccionado = evento.isNotEmpty ? evento : null;
      _mesSeleccionado = mes;
      _fechaSeleccionada = DateFormat('yyyy-MM').parse(mes);
    });

    _cargarTodosLosEventos(mes);
  }

  Future<void> _cargarTodosLosEventos(String mes) async {
    // Por ahora simulamos la lista de eventos; luego se reemplaza con API
    setState(() {
      _eventos = ['Conferencista A', 'Conferencista B', 'Conferencista C'];
      _eventoSeleccionado ??= _eventos.first;
    });

    final box = await Hive.openBox('settings');
    await box.put('mesSeleccionado', mes);
  }

  void _seleccionarFecha(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _fechaSeleccionada = selected;
        _mesSeleccionado = DateFormat('yyyy-MM').format(selected);
      });
      _cargarTodosLosEventos(_mesSeleccionado);
    }
  }

  Future<void> _actualizarEvento() async {
    if (_eventoSeleccionado == null) return;

    setState(() {
      _loading = true;
      _animacionVisible = true;
    });

    final box = await Hive.openBox('settings');
    await box.put('eventoSeleccionado', _eventoSeleccionado!);
    await ref.read(eventoProvider.notifier).setEvento(_eventoSeleccionado!);

    Future.delayed(const Duration(milliseconds: 2200), () {
      setState(() {
        _loading = false;
        _animacionVisible = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evento actualizado: $_eventoSeleccionado')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Selecciona el mes y evento activo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _seleccionarFecha(context),
                  child: Text('Mes actual: $_mesSeleccionado'),
                ),
                const SizedBox(height: 20),
                if (_eventos.isEmpty)
                  const Text('No hay eventos disponibles para este mes.')
                else
                  DropdownButton<String>(
                    value: _eventoSeleccionado,
                    items: _eventos
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _eventoSeleccionado = value),
                    isExpanded: true,
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _loading ? null : _actualizarEvento,
                  child: Text(_loading ? 'Actualizando...' : 'Actualizar Evento'),
                ),
              ],
            ),
          ),
          if (_animacionVisible)
            Center(
              child: Lottie.asset(
                'assets/animations/done.json',
                width: width * 0.5,
                height: width * 0.5,
                repeat: false,
              ),
            ),
        ],
      ),
    );
  }
}
