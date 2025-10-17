import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/evento_provider.dart';
import '../providers/registro_provider.dart';
import '../utils/programas_por_nivel.dart';
import '../constants/opciones_invito.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _escProcController = TextEditingController();

  String _nivelEstudios = '';
  String _programaInteres = '';
  String _nombreInvito = '';
  String _alumno = '';
  String _nivelUninter = '';

  bool _loading = false;
  bool _showSuccess = false;

  String limpiarTexto(String texto) {
    return texto.toUpperCase().replaceAll(RegExp(r'[^\w\s]'), '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final evento = ref.read(eventoProvider);
      if (evento.isEmpty) {
        throw Exception('No hay evento seleccionado');
      }

      final payload = {
        'nombre': limpiarTexto(_nombreController.text.trim()),
        'correo': _correoController.text.trim().toLowerCase(),
        'telefono': _telefonoController.text.trim(),
        'nivel_estudios': _nivelEstudios,
        'conferencista': evento,
        'nombre_invito': _nombreInvito,
        'fecha_registro': DateTime.now().toIso8601String(),
        'alumno': _alumno,
        'tipo': 'SESIÓN INFORMATIVA',
        'escuela_procedencia': limpiarTexto(_escProcController.text.trim()),
        'nivel_uninter': _nivelUninter,
        'programa': _programaInteres,
        'asistio': true,
      };

      await ref.read(registroProvider.notifier).create(payload);

      setState(() => _showSuccess = true);
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _showSuccess = false);

      _limpiarCampos();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _limpiarCampos() {
    _nombreController.clear();
    _correoController.clear();
    _telefonoController.clear();
    _escProcController.clear();
    setState(() {
      _nivelEstudios = '';
      _programaInteres = '';
      _nombreInvito = '';
      _alumno = '';
      _nivelUninter = '';
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Registro')),
      body: _showSuccess
          ? const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 100))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre obligatorio' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _correoController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.length != 10 || int.tryParse(t) == null) return 'Teléfono inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _nivelEstudios.isEmpty ? null : _nivelEstudios,
                      decoration: const InputDecoration(labelText: 'Nivel de Estudios'),
                      items: const ['SECUNDARIA', 'BACHILLERATO', 'UNIVERSIDAD', 'POSGRADO']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _nivelEstudios = v ?? '';
                        _programaInteres = '';
                      }),
                    ),
                    if (_nivelEstudios.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _programaInteres.isEmpty ? null : _programaInteres,
                        decoration: const InputDecoration(labelText: 'Programa de Interés'),
                        items: getProgramOptions(_nivelEstudios)
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _programaInteres = v ?? ''),
                        validator: (v) => (v == null || v.isEmpty) ? 'Programa obligatorio' : null,
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _escProcController,
                      decoration: const InputDecoration(labelText: 'Escuela de Procedencia'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _alumno.isEmpty ? null : _alumno,
                      decoration: const InputDecoration(labelText: '¿Eres alumno Uninter?'),
                      items: const ['SI', 'NO']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _alumno = v ?? ''),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _nombreInvito.isEmpty ? null : _nombreInvito,
                      decoration: const InputDecoration(labelText: '¿Quién te invitó?'),
                      items: opcionesInvito
                          .map((e) => DropdownMenuItem(value: e['value'] ?? '', child: Text(e['label'] ?? '')))
                          .toList(),
                      onChanged: (v) => setState(() => _nombreInvito = v ?? ''),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Registrando...' : 'Registrar'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              _limpiarCampos();
                              Navigator.of(context).pop();
                            },
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}