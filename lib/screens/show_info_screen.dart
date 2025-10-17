import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/evento_provider.dart';
import '../providers/registro_provider.dart';
import '../constants/opciones_invito.dart'; // usa tu archivo real

class ShowInfoScreen extends ConsumerStatefulWidget {
  final int id;
  const ShowInfoScreen({super.key, required this.id});

  @override
  ConsumerState<ShowInfoScreen> createState() => _ShowInfoScreenState();
}

class _ShowInfoScreenState extends ConsumerState<ShowInfoScreen> {
  bool _loading = true;
  bool _saving = false;

  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _escProcCtrl = TextEditingController();
  final _programaInteresCtrl = TextEditingController();

  String _nombre = '';
  String _nivelEstudios = '';
  String _nombreInvito = '';
  String _asistio = 'NO';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _escProcCtrl.dispose();
    _programaInteresCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final evento = ref.read(eventoProvider);
    if (evento.isEmpty) {
      _snack('No hay evento seleccionado', error: true);
      setState(() => _loading = false);
      return;
    }

    try {
      final registro = await ref.read(registroProvider.notifier).getById(widget.id);

      _nombre = registro.nombre ?? '';
      _correoCtrl.text = registro.correo ?? '';
      _telefonoCtrl.text = registro.telefono ?? '';
      _escProcCtrl.text = registro.escuelaProcedencia ?? '';
      _programaInteresCtrl.text = registro.programa ?? '';
      _nivelEstudios = registro.edad ?? ''; // o mapea si tienes nivelEstudios
      _nombreInvito = registro.comoEnteroEvento ?? '';
      _asistio = (registro.asistio == true) ? 'SI' : 'NO';
    } catch (e) {
      _snack('No se pudo obtener el registro', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombre.trim();
    final telefono = _telefonoCtrl.text.trim();
    final correo = _correoCtrl.text.trim();

    if (nombre.isEmpty || telefono.isEmpty) {
      _snack('Nombre y teléfono son requeridos', error: true);
      return;
    }
    if (correo.isNotEmpty) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+\$');
      if (!emailRegex.hasMatch(correo)) {
        _snack('Correo inválido', error: true);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'correo': correo,
        'telefono': telefono,
        'escuela_procedencia': _escProcCtrl.text.trim().toUpperCase(),
        'programa': _programaInteresCtrl.text.trim(),
        'como_entero_evento': _nombreInvito,
        'asistio': _asistio.toUpperCase() == 'SI',
      };

      await ref.read(registroProvider.notifier).update(widget.id, payload);

      _snack('Registro actualizado');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _snack('Error al actualizar', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.redAccent : null),
    );
  }

  Widget _label(BuildContext context, String text) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: c.onSurface)),
    );
  }

  Widget _readonlyBox(BuildContext context, String value) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.onSurface.withOpacity(0.1)),
      ),
      child: Text(value.isEmpty ? '-' : value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

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
                    _label(context, 'Nombre'),
                    _readonlyBox(context, _nombre),
                    const SizedBox(height: 12),

                    _label(context, 'Correo'),
                    TextField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    _label(context, 'Teléfono'),
                    TextField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    _label(context, 'Nivel de Estudios'),
                    _readonlyBox(context, _nivelEstudios),
                    const SizedBox(height: 12),

                    _label(context, 'Escuela de Procedencia'),
                    TextField(
                      controller: _escProcCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    _label(context, 'Programa de Interés'),
                    TextField(
                      controller: _programaInteresCtrl,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    _label(context, '¿Quién te invitó?'),
                    DropdownButtonFormField<String>(
                      value: _nombreInvito.isEmpty ? null : _nombreInvito,
                      items: opcionesInvito
                          .map((e) => DropdownMenuItem(
                                value: e['value'] ?? '',
                                child: Text(e['label'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _nombreInvito = v ?? ''),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    _label(context, '¿Asistió?'),
                    DropdownButtonFormField<String>(
                      value: _asistio,
                      items: const ['SI', 'NO']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _asistio = v ?? 'NO'),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saving ? null : _guardar,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmar asistencia'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  ],
                ),
              ),
            ),
    );
  }
}
