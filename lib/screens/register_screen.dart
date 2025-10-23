import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../providers/registro_provider.dart';
import '../constants/opciones_invito.dart';
import '../constants/opciones_artistas.dart';
import '../constants/opciones_como_entero_evento.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _escProcController = TextEditingController();

  String _artista = '';
  String _disfraz = '';
  String _nombreInvito = '';
  String _comoEnteroEvento = '';
  String _programa = ''; // 👈 nuevo campo

  bool _loading = false;

  String limpiarTexto(String texto) =>
      texto.toUpperCase().replaceAll(RegExp(r'[^\w\s]'), '');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final payload = {
        'nombre': limpiarTexto(_nombreController.text.trim()),
        'edad': _edadController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'correo': _correoController.text.trim().toLowerCase(),
        'escuelaProcedencia': limpiarTexto(_escProcController.text.trim()),
        'artista': limpiarTexto(_artista),
        'disfraz': _disfraz,
        'fechaRegistro': DateTime.now().toIso8601String(),
        'invito': _nombreInvito,
        'programa': _programa, // 👈 agregado
        'comoEnteroEvento': _comoEnteroEvento,
        'asistio': 1,
      };

      await ref.read(registroProvider.notifier).create(payload);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _SuccessPumpkinDialog(),
      );

      if (mounted) {
        _limpiarCampos();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
      }
    } catch (e) {
      _mostrarError('Algo salió mal 😓');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _limpiarCampos() {
    _nombreController.clear();
    _edadController.clear();
    _correoController.clear();
    _telefonoController.clear();
    _escProcController.clear();
    setState(() {
      _artista = '';
      _disfraz = '';
      _nombreInvito = '';
      _comoEnteroEvento = '';
      _programa = '';
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const halloweenOrange = Color(0xFFFF6B00);
    const darkBg = Color(0xFF12101C);
    const purpleCard = Color(0xFF1E1B2D);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Registro HalloweenFest 🎃'),
        centerTitle: true,
        backgroundColor: purpleCard,
        foregroundColor: halloweenOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 22),

              _buildInput(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person_outline,
                validator: (v) =>
                    v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
                color: halloweenOrange,
              ),
              _buildInput(
                controller: _edadController,
                label: 'Edad',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                color: halloweenOrange,
              ),
              _buildInput(
                controller: _correoController,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                color: halloweenOrange,
              ),
              _buildInput(
                controller: _telefonoController,
                label: 'Teléfono (10 dígitos)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'El teléfono es obligatorio';
                  if (t.length != 10 || int.tryParse(t) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
                color: halloweenOrange,
              ),
              _buildInput(
                controller: _escProcController,
                label: 'Escuela de procedencia',
                icon: Icons.school_outlined,
                color: halloweenOrange,
              ),

              // 👇 Nuevo dropdown para programa / grado actual
              _buildDropdown(
                label: 'Grado actual / Programa',
                value: _programa.isEmpty ? null : _programa,
                items: const [
                  'Secundaria',
                  'Bachillerato',
                  'Licenciatura / Ingeniería',
                  'Maestría',
                  'Doctorado',
                ],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Selecciona una opción' : null,
                onChanged: (v) => setState(() => _programa = v ?? ''),
                color: halloweenOrange,
              ),

              _buildDropdown(
                label: 'Artista',
                value: _artista.isEmpty ? null : _artista,
                items: opcionesArtistas,
                onChanged: (v) => setState(() => _artista = v ?? ''),
                color: halloweenOrange,
              ),
              _buildDropdown(
                label: '¿Disfraz?',
                value: _disfraz.isEmpty ? null : _disfraz,
                items: const ['SI', 'NO'],
                onChanged: (v) => setState(() => _disfraz = v ?? ''),
                color: halloweenOrange,
              ),
              _buildDropdown(
                label: '¿Quién te invitó?',
                value: _nombreInvito.isEmpty ? null : _nombreInvito,
                items: opcionesInvito.map((e) => e['label'] ?? '').toList(),
                onChanged: (v) => setState(() => _nombreInvito = v ?? ''),
                color: halloweenOrange,
              ),
              _buildDropdown(
                label: '¿Cómo te enteraste del evento?',
                value: _comoEnteroEvento.isEmpty ? null : _comoEnteroEvento,
                items: opcionesComoEnteroEvento,
                onChanged: (v) => setState(() => _comoEnteroEvento = v ?? ''),
                color: halloweenOrange,
              ),
              const SizedBox(height: 28),

              _buildSubmitButton(halloweenOrange),
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        _limpiarCampos();
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.orangeAccent, size: 18),
                label: const Text(
                  'Cancelar y volver',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const purpleCard = Color(0xFF1E1B2D);
    const darkBg = Color(0xFF12101C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [purpleCard, darkBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Color(0xFFFF6B00),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formulario de Registro',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Completa los siguientes campos para registrar tu participación.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(Color halloweenOrange) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.rocket_launch_outlined),
        label: Text(
          _loading ? 'Registrando...' : 'Registrar asistencia',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: halloweenOrange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _loading ? null : _submit,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Color color = Colors.orange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: color) : null,
          labelText: label,
          labelStyle: TextStyle(color: color),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color.withOpacity(0.5)),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1B2D),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    String? value,
    String? Function(String?)? validator,
    required void Function(String?) onChanged,
    Color color = Colors.orange,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        dropdownColor: const Color(0xFF1E1B2D),
        value: value,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: color.withOpacity(0.5)),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1B2D),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// 🎃 Modal de éxito animado
class _SuccessPumpkinDialog extends StatelessWidget {
  const _SuccessPumpkinDialog();

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF0F0D1B);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'lib/assets/animations/success_pumpkin.json',
              height: 150,
              repeat: false,
            ),
            const SizedBox(height: 10),
            const Text(
              '¡Registro exitoso!',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                shadows: [
                  Shadow(color: Colors.orange, blurRadius: 10),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }
}
