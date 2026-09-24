// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../providers/app_event_provider.dart';
import '../providers/evento_activo_provider.dart';
import '../providers/registro_conferencia_provider.dart';

// ── Formatter: forces every character to uppercase in real-time ───────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl    = TextEditingController();
  final _telefonoCtrl  = TextEditingController();
  final _correoCtrl    = TextEditingController();
  final _escProcCtrl   = TextEditingController();
  // Free-text program ctrl used only for EJECUTIVA
  final _programaLibreCtrl = TextEditingController();

  String _nivelEstudios = '';
  String _programaInteres = '';
  String _alumno = 'NO';
  String _nombreInvito = '';
  int    _acompanantes = 0;
  bool   _loading = false;

  // Theme colors — set at top of build() so helper methods can use them
  bool   _hw        = false;
  Color  _bg        = AppColors.bg;
  Color  _surface   = AppColors.card;
  Color  _accent    = AppColors.primary;
  Color  _textCol   = AppColors.text;
  Color  _subCol    = AppColors.textSub;
  Color  _divCol    = AppColors.divider;
  Color  _inputFill = AppColors.card;

  // ── Catalogs ────────────────────────────────────────────────────────────────

  static const _nivelesEstudios = [
    'SECUNDARIA',
    'BACHILLERATO',
    'UNIVERSIDAD',
    'POSGRADO',
    'EJECUTIVA',
  ];

  static const _invitadores = [
    'ADRIAN MOLINA',
    'ALDAHIR GOMEZ',
    'ALEJANDRA RIVAS',
    'ANALIT ROMÁN ARCE',
    'ANGÉLICA NIETO',
    'ANETT VERA',
    'ASLHEY GONZÁLEZ',
    'CÉSAR SANTA OLALLA',
    'GEORGINA NERI',
    'ILEANA REYES',
    'ISIS CORTES',
    'ISRAEL OSORIO',
    'JAVER ESPINOSA',
    'JESÚS GUZMÁN',
    'JESUS TRILLO',
    'JULIAN RODRIGUEZ',
    'MARCO SALGADO',
    'MELYSSA MONROY',
    'RAUL CASTILLEJA',
    'REDES SOCIALES / CORREO',
    'SARA DURÁN',
    'XIMENA MARTÍNEZ',
    'YANIN VAZQUEZ',
    'ALUMNO',
    'NINGUNO DE LOS ANTERIORES',
  ];

  static const _programasPorNivel = <String, List<String>>{
    'SECUNDARIA': ['SIU MULTICULTURAL', 'SIU BILINGÜE'],
    'BACHILLERATO': ['BIU MULTICULTURAL', 'BIU BILINGÜE', 'PREPA-A'],
    'UNIVERSIDAD': [
      'Administración de Empresas (LAE)',
      'Administración de Empresas Turísticas (LAET)',
      'Administración de Negocios Internacionales (LANI)',
      'Administración y Mercadotecnia (LAM)',
      'Administración de Negocios Internacionales en línea (LEANI)',
      'Ambiental (IAM)',
      'Animación y Diseño Digital (LADD)',
      'Arquitectura (ARQ)',
      'Ciencias Políticas y Gestión Pública (LCP)',
      'Civil (ICI)',
      'Comercio Exterior (LCE)',
      'Comercio Exterior en línea (LECE)',
      'Comunicación (LCO)',
      'Comunicación y Relaciones Públicas (CORP)',
      'Derecho (LED)',
      'Derecho en línea (LEDE)',
      'Diseño de Modas y Tendencias Internacionales (LDM)',
      'Diseño Gráfico (LDG)',
      'Diseño Industrial (LDI)',
      'Economía y Finanzas (LEF)',
      'Gestión Empresarial en línea (LEGE)',
      'Idiomas (LID)',
      'Industrial y de Sistemas de Calidad (IISCA)',
      'Mecánica Industrial (IMI)',
      'Mecatrónica (IME)',
      'Mercadotecnia (LEM)',
      'Mercadotecnia en línea (LEMK)',
      'Mercadotecnia y Publicidad (LEMP)',
      'Mercadotecnia y Publicidad en línea (LEMKP)',
      'Pedagogía (LPE)',
      'Psicología (LPS)',
      'Relaciones Internacionales (LRI)',
      'Relaciones Internacionales y Ciencias Políticas (RICP)',
      'Relaciones Internacionales y Economía (RIEC)',
      'Sistemas Computacionales (ISC)',
    ],
    'POSGRADO': [
      'Doctorado en Administración',
      'Doctorado en Humanidades',
      'Especialidad en Administración de la Tecnología en Línea (EATL)',
      'Especialidad en Administración de Obra (EAO)',
      'Especialidad en Animación y Post-Producción Digital (EAPD)',
      'Especialidad en Criminalística (EC)',
      'Especialidad en Marketing Digital (EMD)',
      'Especialidad en Promoción Turística (EPT)',
      'Especialidad en Publicidad (EPU)',
      'Especialidad en Relaciones Mercantiles Internacionales (ERMI)',
      'Maestría en Administración con Especialidad en Negocios Internacionales (MAD)',
      'Maestría en Administración y Dirección de Empresas (MADE)',
      'Maestría en Alta Dirección (MADIR)',
      'Maestría en Educación en Formación Docente (MEFD)',
      'Maestría en Enseñanza de Lenguas Extranjeras (MEL)',
      'Maestría en Finanzas Corporativas (MFC)',
      'Maestría en Gestión de la Calidad (MGC)',
      'Maestría en Gestión del Factor y Capital Humano (MGFH)',
      'Maestría en Impuestos (MI)',
      'Maestría en Línea de Administración y Dirección de Empresas (MADEL)',
      'Maestría en Mercadotecnia Global (MMG)',
      'Maestría en Redes de Computadoras y Tecnologías WEB (MARET)',
    ],
    'EJECUTIVA': [
      'Administración de Negocios Internacionales (LEANI)',
      'Administración y Mercadotecnia (LEAM)',
      'Comercio Exterior (LECE)',
      'Derecho (LEDE)',
      'Gestión Empresarial (LEGE)',
      'Mercadotecnia (LEMK)',
      'Mercadotecnia y Publicidad (LEMKP)',
    ],
  };

  List<String> get _programas => _programasPorNivel[_nivelEstudios] ?? [];

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _escProcCtrl.dispose();
    _programaLibreCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final evento = ref.read(eventoActivoProvider);
    if (!evento.tieneEvento) {
      _snack('Selecciona un evento antes de registrar', error: true);
      return;
    }

    // programa comes from dropdown/Autocomplete (_programaInteres)
    // or free-text ctrl only when programs list is empty (fallback)
    final programa = _programas.isEmpty
        ? _programaLibreCtrl.text.trim()
        : _programaInteres;

    setState(() => _loading = true);
    try {
      await ref.read(registroConferenciaProvider.notifier).create({
        'nombre':         _nombreCtrl.text.trim(),
        'telefono':       _telefonoCtrl.text.trim(),
        'correo':         _correoCtrl.text.trim().toLowerCase(),
        'Nivel_Estudios': _nivelEstudios,
        'escProc':        _escProcCtrl.text.trim(),
        'programaInteres': programa,
        'alumno':         _alumno,
        'Nombre_invito':  _nombreInvito,
        'acompanantes':   _acompanantes,
        'asistio':        'SI',
        'tipo':           'walkin',
        'fecha_registro': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Registro creado', style: TextStyle(color: Colors.white)),
          ],
        ),
      ));
      context.go('/list');
    } catch (e) {
      _snack('Error al crear el registro: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : _accent,
      ));

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final evento = ref.watch(eventoActivoProvider);
    final isHalloween = ref.watch(appEventProvider) == AppEvent.halloween;

    _hw        = isHalloween;
    _bg        = isHalloween ? HalloweenColors.bg       : AppColors.bg;
    _surface   = isHalloween ? HalloweenColors.surface  : AppColors.card;
    _accent    = isHalloween ? HalloweenColors.secondary: AppColors.primary;
    _textCol   = isHalloween ? HalloweenColors.text     : AppColors.text;
    _subCol    = isHalloween ? HalloweenColors.textSub  : AppColors.textSub;
    _divCol    = isHalloween ? HalloweenColors.divider  : AppColors.divider;
    _inputFill = isHalloween ? HalloweenColors.input    : AppColors.card;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: isHalloween ? HalloweenColors.surface : null,
        elevation: isHalloween ? 0 : null,
        centerTitle: isHalloween,
        title: isHalloween
            ? const Text('Nuevo registro 🎃',
                style: TextStyle(
                    color: HalloweenColors.secondary,
                    fontWeight: FontWeight.bold))
            : const Text('Nuevo registro'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Evento activo ────────────────────────────────────────
                if (!evento.tieneEvento)
                  _WarningBanner(onTap: () => context.go('/settings'))
                else
                  _EventChip(
                    conferencista: evento.eventoSeleccionado,
                    isHalloween: _hw,
                    accent: _accent,
                  ),

                const SizedBox(height: 24),

                // ════════════════════════════════════════════════════════
                // DATOS PERSONALES
                // ════════════════════════════════════════════════════════
                _sectionLabel('DATOS PERSONALES'),
                const SizedBox(height: 12),

                // Nombre — uppercase real-time
                _upperField(
                  controller: _nombreCtrl,
                  label: 'Nombre completo *',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: _required,
                ),
                const SizedBox(height: 14),

                // Teléfono — digits only, max 10
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: _textCol),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    if (v.trim().length < 10) return 'Debe tener 10 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Correo — lowercase, optional
                TextFormField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _textCol),
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v.trim())
                        ? null
                        : 'Correo inválido';
                  },
                ),

                const SizedBox(height: 28),

                // ════════════════════════════════════════════════════════
                // INTERÉS ACADÉMICO
                // ════════════════════════════════════════════════════════
                _sectionLabel('INTERÉS ACADÉMICO'),
                const SizedBox(height: 12),

                // Nivel de estudios — 5 fixed options
                DropdownButtonFormField<String>(
                  value: _nivelEstudios.isEmpty ? null : _nivelEstudios,
                  dropdownColor: _surface,
                  style: TextStyle(color: _textCol),
                  decoration: const InputDecoration(
                    labelText: 'Nivel de estudios',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  hint: Text('Selecciona nivel',
                      style: TextStyle(color: _subCol)),
                  items: _nivelesEstudios
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _nivelEstudios = v ?? '';
                    _programaInteres = '';
                    _programaLibreCtrl.clear();
                  }),
                ),

                // Programa de interés — cascades from nivel
                if (_nivelEstudios.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildProgramaField(),
                ],

                const SizedBox(height: 28),

                // ════════════════════════════════════════════════════════
                // PROCEDENCIA
                // ════════════════════════════════════════════════════════
                _sectionLabel('PROCEDENCIA'),
                const SizedBox(height: 12),

                // Escuela — uppercase
                _upperField(
                  controller: _escProcCtrl,
                  label: 'Escuela de procedencia',
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 14),

                // ¿Alumno UNINTER?
                DropdownButtonFormField<String>(
                  value: _alumno,
                  dropdownColor: _surface,
                  style: TextStyle(color: _textCol),
                  decoration: const InputDecoration(
                    labelText: '¿Eres alumno UNINTER?',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const ['SI', 'NO']
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _alumno = v ?? 'NO'),
                ),

                const SizedBox(height: 28),

                // ════════════════════════════════════════════════════════
                // PROMOTOR
                // ════════════════════════════════════════════════════════
                _sectionLabel('PROMOTOR'),
                const SizedBox(height: 12),

                // Quién invitó — searchable
                _searchableField(
                  key: const ValueKey('invitador'),
                  options: _invitadores,
                  label: '¿Quién te invitó?',
                  prefixIcon: Icons.group_add_outlined,
                  initialValue: _nombreInvito,
                  onSelected: (v) => setState(() => _nombreInvito = v),
                ),
                const SizedBox(height: 14),

                // Acompañantes stepper
                _AcompanantesStepper(
                  value: _acompanantes,
                  onChanged: (v) => setState(() => _acompanantes = v),
                  accent: _accent,
                  surface: _surface,
                  textCol: _textCol,
                  subCol: _subCol,
                  divCol: _divCol,
                ),

                const SizedBox(height: 32),

                // ── Submit ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: _hw ? 0 : 2,
                    ),
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(
                      _loading ? 'Registrando…' : 'Crear registro',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Cascading programa field ───────────────────────────────────────────────

  Widget _buildProgramaField() {
    final programs = _programas;

    // EJECUTIVA or unknown — free-text uppercase
    if (programs.isEmpty) {
      return _upperField(
        controller: _programaLibreCtrl,
        label: 'Programa de interés',
        prefixIcon: Icons.book_outlined,
      );
    }

    // SECUNDARIA / BACHILLERATO — 2 options → plain dropdown
    if (programs.length <= 3) {
      return DropdownButtonFormField<String>(
        key: ValueKey(_nivelEstudios),
        value: _programaInteres.isEmpty ? null : _programaInteres,
        dropdownColor: _surface,
        style: TextStyle(color: _textCol),
        decoration: const InputDecoration(
          labelText: 'Programa de interés',
          prefixIcon: Icon(Icons.book_outlined),
        ),
        hint: Text('Selecciona programa',
            style: TextStyle(color: _subCol)),
        items: programs
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => setState(() => _programaInteres = v ?? ''),
      );
    }

    // UNIVERSIDAD / POSGRADO — long list → searchable autocomplete
    return _searchableField(
      key: ValueKey('prog_$_nivelEstudios'),
      options: programs,
      label: 'Programa de interés',
      prefixIcon: Icons.book_outlined,
      initialValue: _programaInteres,
      onSelected: (v) => setState(() => _programaInteres = v),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────

  Widget _upperField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: _textCol),
      inputFormatters: [_UpperCaseFormatter()],
      textCapitalization: TextCapitalization.characters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }

  Widget _searchableField({
    Key? key,
    required List<String> options,
    required String label,
    required ValueChanged<String> onSelected,
    String initialValue = '',
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      key: key,
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.toUpperCase().trim();
        if (q.isEmpty) return options;
        return options.where((o) => o.toUpperCase().contains(q));
      },
      displayStringForOption: (o) => o,
      onSelected: (v) {
        onSelected(v);
        FocusScope.of(context).unfocus();
      },
      optionsViewBuilder: (ctx, onAutoSelect, opts) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          color: _surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: opts.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _divCol),
              itemBuilder: (_, i) {
                final opt = opts.elementAt(i);
                return InkWell(
                  onTap: () => onAutoSelect(opt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Text(opt,
                        style: TextStyle(color: _textCol, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) =>
          TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        style: TextStyle(color: _textCol),
        inputFormatters: [_UpperCaseFormatter()],
        textCapitalization: TextCapitalization.characters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          suffixIcon: Icon(Icons.search_rounded, color: _subCol, size: 18),
        ),
        onFieldSubmitted: (_) => onFieldSubmitted(),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: _subCol,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;
}

// ══════════════════════════════════════════════════════════════════════════════
// Acompañantes stepper
// ══════════════════════════════════════════════════════════════════════════════

class _AcompanantesStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final Color accent;
  final Color surface;
  final Color textCol;
  final Color subCol;
  final Color divCol;

  const _AcompanantesStepper({
    required this.value,
    required this.onChanged,
    required this.accent,
    required this.surface,
    required this.textCol,
    required this.subCol,
    required this.divCol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divCol),
      ),
      child: Row(
        children: [
          Icon(Icons.group_outlined, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acompañantes',
                    style: TextStyle(
                        color: textCol,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('Personas sin registro previo',
                    style: TextStyle(color: subCol, fontSize: 11)),
              ],
            ),
          ),
          _StepBtn(
            icon: Icons.remove_rounded,
            color: value > 0 ? AppColors.error : divCol,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: accent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            color: accent,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _StepBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Small sub-widgets
// ══════════════════════════════════════════════════════════════════════════════

class _EventChip extends StatelessWidget {
  final String conferencista;
  final bool isHalloween;
  final Color accent;
  const _EventChip({
    required this.conferencista,
    required this.isHalloween,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isHalloween ? Icons.whatshot_rounded : Icons.event_rounded,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              conferencista,
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _WarningBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin evento activo — toca para configurar',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}
