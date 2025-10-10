// lib/screens/show_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/evento_provider.dart';

// Ajusta tu BASE_URL real aquí
const String BASE_URL = 'https://tu-api-aqui.com';

// Importa tus opciones reales en lugar de este fallback si tienes el archivo:
// import '../constants/opciones_invito.dart';
const List<Map<String, String>> opcionesInvitoFallback = [
  {'label': 'Amigo', 'value': 'Amigo'},
  {'label': 'Familiar', 'value': 'Familiar'},
  {'label': 'Otro', 'value': 'Otro'},
];

class ShowInfoScreen extends ConsumerStatefulWidget {
  final String id; // mantendremos string (viene del router)
  const ShowInfoScreen({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<ShowInfoScreen> createState() => _ShowInfoScreenState();
}

class _ShowInfoScreenState extends ConsumerState<ShowInfoScreen> {
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic> _registro = {};

  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _escProcController = TextEditingController();
  final TextEditingController _programaInteresController = TextEditingController();

  String _nombreInvito = '';
  String _asistio = 'NO';

  @override
  void initState() {
    super.initState();
    _fetchRegistro();
  }

  @override
  void dispose() {
    _correoController.dispose();
    _telefonoController.dispose();
    _escProcController.dispose();
    _programaInteresController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegistro() async {
    setState(() => _loading = true);

    final evento = ref.read(eventoProvider);
    if (evento.isEmpty) {
      _showSnack('No hay evento seleccionado', isError: true);
      setState(() => _loading = false);
      return;
    }

    try {
      final url = Uri.parse(
        '$BASE_URL/registros/${widget.id}?conferencista=${Uri.encodeComponent(evento)}',
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          _registro = data;
        } else {
          _registro = Map<String, dynamic>.from(data as Map);
        }

        _correoController.text = (_registro['correo'] ?? '').toString();
        _telefonoController.text = (_registro['telefono'] ?? '').toString();
        _escProcController.text = (_registro['escProc'] ?? '').toString();
        _programaInteresController.text = (_registro['programaInteres'] ?? '').toString();
        _nombreInvito = (_registro['Nombre_invito'] ?? '').toString();
        _asistio = (_registro['asistio'] ?? 'NO').toString();
      } else {
        _showSnack('No se pudo obtener el registro', isError: true);
      }
    } catch (e) {
      debugPrint('Error fetching registro: $e');
      _showSnack('Error al obtener datos', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmAttendance() async {
    final evento = ref.read(eventoProvider);
    if (evento.isEmpty) {
      _showSnack('No hay evento seleccionado', isError: true);
      return;
    }

    final nombre = (_registro['nombre'] ?? '').toString();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim();

    if (nombre.trim().isEmpty || telefono.trim().isEmpty) {
      _showSnack('Nombre y teléfono son requeridos', isError: true);
      return;
    }

    if (correo.isNotEmpty) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(correo)) {
        _showSnack('Correo inválido', isError: true);
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final url = Uri.parse(
        '$BASE_URL/registros/${widget.id}?conferencista=${Uri.encodeComponent(evento)}',
      );

      final body = {
        'nombre': nombre,
        'correo': correo,
        'telefono': telefono,
        'Nivel_Estudios': _registro['Nivel_Estudios'] ?? '',
        'Nombre_invito': _nombreInvito,
        'escProc': _escProcController.text.toUpperCase(),
        'programaInteres': _programaInteresController.text,
        'asistio': _asistio,
      };

      final res = await http.put(url,
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));

      if (res.statusCode == 200 || res.statusCode == 204) {
        _showSnack('Registro actualizado correctamente');
        Future.delayed(const Duration(milliseconds: 800),
            () => Navigator.of(context).pop());
      } else {
        debugPrint('Update failed: ${res.statusCode} ${res.body}');
        _showSnack('Error al actualizar registro', isError: true);
      }
    } catch (e) {
      debugPrint('Error updating registro: $e');
      _showSnack('Error al actualizar registro', isError: true);
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final snack = SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : null);
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  Widget _buildLabel(String text) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
    );
  }

  Widget _buildField(String labelText, TextEditingController controller,
      {bool editable = true, TextInputType? keyboardType}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(labelText),
          TextField(
            controller: controller,
            enabled: editable,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: editable ? colors.surface : colors.surface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Información de Registro')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nombre'),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.onSurface.withOpacity(0.1)),
                      ),
                      child: Text(_registro['nombre']?.toString() ?? 'Sin nombre'),
                    ),
                    const SizedBox(height: 12),
                    _buildField('Correo', _correoController, keyboardType: TextInputType.emailAddress),
                    _buildField('Teléfono', _telefonoController, keyboardType: TextInputType.phone),
                    _buildLabel('Nivel de Estudios'),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.onSurface.withOpacity(0.1)),
                      ),
                      child: Text(_registro['Nivel_Estudios']?.toString() ?? ''),
                    ),
                    const SizedBox(height: 12),
                    _buildField('Escuela de Procedencia', _escProcController),
                    _buildField('Programa de Interés', _programaInteresController),
                    const SizedBox(height: 8),
                    _buildLabel('¿Quién te invitó?'),
                    DropdownButtonFormField<String>(
                      value: _nombreInvito.isEmpty ? null : _nombreInvito,
                      items: opcionesInvitoFallback
                          .map((e) => DropdownMenuItem(value: e['value'] ?? e['label'], child: Text(e['label']!)))
                          .toList(),
                      onChanged: (v) => setState(() => _nombreInvito = v ?? ''),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    _buildLabel('¿Asistió?'),
                    DropdownButtonFormField<String>(
                      value: _asistio,
                      items: ['SI', 'NO'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _asistio = v ?? 'NO'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitting ? null : _confirmAttendance,
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmar asistencia'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  ],
                ),
              ),
            ),
    );
  }
}
