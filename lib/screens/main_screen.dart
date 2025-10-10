import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/evento_provider.dart';
import '../screens/home_screen.dart';

const String BASE_URL = 'https://tu-api-aqui.com';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  DateTime _fecha = DateTime.now();
  String _mes = DateFormat('yyyy-MM').format(DateTime.now());
  bool _loading = true;

  List<String> _eventos = [];
  String? _eventoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('$BASE_URL/registros/eventos/por-mes?mes=$_mes');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          _eventos = data.map<String>((e) => e['Conferencista'].toString()).toList();
          _eventoSeleccionado = _eventos.first;
        } else {
          _eventos = [];
          _eventoSeleccionado = null;
        }

        final box = await Hive.openBox('settings');
        await box.put('mesSeleccionado', _mes);
      } else {
        _eventos = [];
        _eventoSeleccionado = null;
      }
    } catch (e) {
      _eventos = [];
      _eventoSeleccionado = null;
      debugPrint('Error cargando eventos: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _seleccionarFecha(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _fecha = selected;
        _mes = DateFormat('yyyy-MM').format(selected);
      });
      _cargarEventos();
    }
  }

  void _continuar() async {
    if (_eventoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un evento')),
      );
      return;
    }

    // Guardar evento en Hive y en provider
    ref.read(eventoProvider.notifier).setEvento(_eventoSeleccionado!);

    // Navegar a HomeScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Evento')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Selecciona el evento activo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _seleccionarFecha(context),
                    child: Text('Mes actual: $_mes'),
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
                    onPressed: _continuar,
                    child: const Text('Continuar'),
                  ),
                ],
              ),
      ),
    );
  }
}
