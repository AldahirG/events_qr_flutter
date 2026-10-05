// lib/screens/show_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_theme.dart';
import '../models/registro_conferencia.dart';
import '../providers/app_event_provider.dart';
import '../providers/registro_conferencia_provider.dart';

// ── Uppercase formatter (same as register_screen) ────────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
      );
}

// ── Catalogs (mirrors register_screen) ───────────────────────────────────────
const _nivelesEstudios = [
  'SECUNDARIA', 'BACHILLERATO', 'UNIVERSIDAD', 'POSGRADO', 'EJECUTIVA',
];

const _invitadores = [
  'ADRIAN MOLINA', 'ALDAHIR GOMEZ', 'ALEJANDRA RIVAS', 'ANALIT ROMÁN ARCE',
  'ANGÉLICA NIETO', 'ANETT VERA', 'ASLHEY GONZÁLEZ', 'CÉSAR SANTA OLALLA',
  'GEORGINA NERI', 'ILEANA REYES', 'ISIS CORTES', 'ISRAEL OSORIO',
  'JAVER ESPINOSA', 'JESÚS GUZMÁN', 'JESUS TRILLO', 'JULIAN RODRIGUEZ',
  'MARCO SALGADO', 'MELYSSA MONROY', 'RAUL CASTILLEJA',
  'REDES SOCIALES / CORREO', 'SARA DURÁN', 'XIMENA MARTÍNEZ',
  'YANIN VAZQUEZ', 'ALUMNO', 'NINGUNO DE LOS ANTERIORES',
];

const _programasPorNivel = <String, List<String>>{
  'SECUNDARIA': ['SIU MULTICULTURAL', 'SIU BILINGÜE', 'TOV', 'OTRA'],
  'BACHILLERATO': ['BIU MULTICULTURAL', 'BIU BILINGÜE', 'PREPA-A', 'TOV', 'OTRA'],
  'UNIVERSIDAD': [
    'Administración de Empresas (LAE)',
    'Administración de Empresas Turísticas (LAET)',
    'Administración de Negocios Internacionales (LANI)',
    'Administración y Mercadotecnia (LAM)',
    'Administración de Negocios Internacionales en línea (LEANI)',
    'Ambiental (IAM)', 'Animación y Diseño Digital (LADD)',
    'Arquitectura (ARQ)', 'Ciencias Políticas y Gestión Pública (LCP)',
    'Civil (ICI)', 'Comercio Exterior (LCE)', 'Comercio Exterior en línea (LECE)',
    'Comunicación (LCO)', 'Comunicación y Relaciones Públicas (CORP)',
    'Derecho (LED)', 'Derecho en línea (LEDE)',
    'Diseño de Modas y Tendencias Internacionales (LDM)',
    'Diseño Gráfico (LDG)', 'Diseño Industrial (LDI)',
    'Economía y Finanzas (LEF)', 'Gestión Empresarial en línea (LEGE)',
    'Idiomas (LID)', 'Industrial y de Sistemas de Calidad (IISCA)',
    'Mecánica Industrial (IMI)', 'Mecatrónica (IME)', 'Mercadotecnia (LEM)',
    'Mercadotecnia en línea (LEMK)', 'Mercadotecnia y Publicidad (LEMP)',
    'Mercadotecnia y Publicidad en línea (LEMKP)', 'Pedagogía (LPE)',
    'Psicología (LPS)', 'Relaciones Internacionales (LRI)',
    'Relaciones Internacionales y Ciencias Políticas (RICP)',
    'Relaciones Internacionales y Economía (RIEC)',
    'Sistemas Computacionales (ISC)',
    'OTRA',
  ],
  'POSGRADO': [
    'Doctorado en Administración', 'Doctorado en Humanidades',
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
    'OTRA',
  ],
  'EJECUTIVA': [
    'Administración de Negocios Internacionales (LEANI)',
    'Administración y Mercadotecnia (LEAM)', 'Comercio Exterior (LECE)',
    'Derecho (LEDE)', 'Gestión Empresarial (LEGE)',
    'Mercadotecnia (LEMK)', 'Mercadotecnia y Publicidad (LEMKP)',
    'OTRA',
  ],
};

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class ShowInfoScreen extends ConsumerStatefulWidget {
  final int id;
  const ShowInfoScreen({super.key, required this.id});

  @override
  ConsumerState<ShowInfoScreen> createState() => _ShowInfoScreenState();
}

class _ShowInfoScreenState extends ConsumerState<ShowInfoScreen> {
  bool _loading = true;
  bool _saving  = false;
  RegistroConferencia? _registro;

  // Controllers
  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl   = TextEditingController();
  final _escProcCtrl  = TextEditingController();
  final _programaLibreCtrl = TextEditingController();

  // Dropdown / state
  String _nivelEstudios = '';
  String _programaInteres = '';
  String _alumno = 'NO';
  String _nombreInvito = '';
  String _asistio = 'NO';
  int    _acompanantes = 0;
  int    _acompanantesOriginal = 0;

  // Theme — updated each build
  Color _bg      = AppColors.bg;
  Color _surface = AppColors.card;
  Color _accent  = AppColors.primary;
  Color _textCol = AppColors.text;
  Color _subCol  = AppColors.textSub;
  Color _divCol  = AppColors.divider;

  List<String> get _programas => _programasPorNivel[_nivelEstudios] ?? [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _escProcCtrl.dispose();
    _programaLibreCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await ref
          .read(registroConferenciaProvider.notifier)
          .getById(widget.id);
      setState(() {
        _registro = r;
        _nombreCtrl.text   = r.nombre ?? '';
        _correoCtrl.text   = r.correo ?? '';
        _telefonoCtrl.text = r.telefono ?? '';
        _escProcCtrl.text  = r.escProc ?? '';
        _nivelEstudios     = r.nivelEstudios ?? '';
        _programaInteres   = r.programaInteres ?? '';
        _alumno            = r.alumno ?? 'NO';
        _nombreInvito      = r.nombreInvito ?? '';
        _asistio           = r.asistioConfirmado ? 'SI' : 'NO';
        _acompanantes         = r.acompanantes ?? 0;
        _acompanantesOriginal = r.acompanantes ?? 0;
      });
    } catch (e) {
      _snack('No se pudo obtener el registro', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    final nombre   = _nombreCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();
    final correo   = _correoCtrl.text.trim();

    if (nombre.isEmpty) { _snack('El nombre es requerido', error: true); return; }
    if (telefono.isEmpty) { _snack('El teléfono es requerido', error: true); return; }
    if (correo.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      _snack('Correo inválido', error: true);
      return;
    }

    final programa = _programas.isEmpty
        ? _programaLibreCtrl.text.trim()
        : _programaInteres;

    setState(() => _saving = true);
    try {
      final notifier = ref.read(registroConferenciaProvider.notifier);

      await notifier.update(widget.id, {
        'nombre':          nombre,
        'correo':          correo.toLowerCase(),
        'telefono':        telefono,
        'Nivel_Estudios':  _nivelEstudios,
        // Conferencias key
        'Nombre_invito':   _nombreInvito,
        // Halloween key (backend ignores unknown fields)
        'promotor':        _nombreInvito,
        'escProc':         _escProcCtrl.text.trim(),
        'escuelaProcedencia': _escProcCtrl.text.trim(),
        'programaInteres': programa,
        'programa':        programa,
        'alumno':          _alumno,
        'asistio':         _asistio,
      });

      // Acompañantes use separate PATCH endpoint
      if (_acompanantes != _acompanantesOriginal) {
        await notifier.actualizarAcompanantes(widget.id, _acompanantes);
        setState(() => _acompanantesOriginal = _acompanantes);
      }

      _snack('Registro actualizado');
      if (mounted) context.pop();
    } catch (_) {
      _snack('Error al actualizar', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ));

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isHalloween = ref.watch(appEventProvider) == AppEvent.halloween;

    _bg      = isHalloween ? HalloweenColors.bg       : AppColors.bg;
    _surface = isHalloween ? HalloweenColors.surface  : AppColors.card;
    _accent  = isHalloween ? HalloweenColors.secondary: AppColors.primary;
    _textCol = isHalloween ? HalloweenColors.text     : AppColors.text;
    _subCol  = isHalloween ? HalloweenColors.textSub  : AppColors.textSub;
    _divCol  = isHalloween ? HalloweenColors.divider  : AppColors.divider;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: isHalloween ? HalloweenColors.surface : null,
        elevation: isHalloween ? 0 : null,
        centerTitle: isHalloween,
        title: isHalloween
            ? const Text('Editar registro 🎃',
                style: TextStyle(
                    color: HalloweenColors.secondary, fontWeight: FontWeight.bold))
            : const Text('Editar registro'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isHalloween ? HalloweenColors.secondary : null),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _accent))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Read-only info card ───────────────────────────────
                    _InfoCard(
                      registro: _registro,
                      isHalloween: isHalloween,
                      surface: _surface,
                      accent: _accent,
                      textCol: _textCol,
                      subCol: _subCol,
                      divCol: _divCol,
                    ),
                    const SizedBox(height: 24),

                    // ════════════════════════════════════════════════════
                    // DATOS PERSONALES
                    // ════════════════════════════════════════════════════
                    _sectionLabel('DATOS PERSONALES'),
                    const SizedBox(height: 12),

                    _upperField(
                      controller: _nombreCtrl,
                      label: 'Nombre completo *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: _required,
                    ),
                    const SizedBox(height: 14),

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
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: _textCol),
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════
                    // INTERÉS ACADÉMICO
                    // ════════════════════════════════════════════════════
                    _sectionLabel('INTERÉS ACADÉMICO'),
                    const SizedBox(height: 12),

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
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _nivelEstudios = v ?? '';
                        _programaInteres = '';
                        _programaLibreCtrl.clear();
                      }),
                    ),

                    if (_nivelEstudios.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildProgramaField(),
                    ],
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════
                    // PROCEDENCIA
                    // ════════════════════════════════════════════════════
                    _sectionLabel('PROCEDENCIA'),
                    const SizedBox(height: 12),

                    _upperField(
                      controller: _escProcCtrl,
                      label: 'Escuela de procedencia',
                      prefixIcon: Icons.business_outlined,
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _alumno.isEmpty ? 'NO' : _alumno,
                      dropdownColor: _surface,
                      style: TextStyle(color: _textCol),
                      decoration: const InputDecoration(
                        labelText: '¿Eres alumno UNINTER?',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const ['SI', 'NO']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _alumno = v ?? 'NO'),
                    ),
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════
                    // PROMOTOR
                    // ════════════════════════════════════════════════════
                    _sectionLabel('PROMOTOR'),
                    const SizedBox(height: 12),

                    _searchableField(
                      key: const ValueKey('invitador_edit'),
                      options: _invitadores,
                      label: '¿Quién te invitó?',
                      prefixIcon: Icons.group_add_outlined,
                      initialValue: _nombreInvito,
                      onSelected: (v) => setState(() => _nombreInvito = v),
                    ),
                    const SizedBox(height: 14),

                    _AcompanantesStepper(
                      value: _acompanantes,
                      onChanged: (v) => setState(() => _acompanantes = v),
                      accent: _accent,
                      surface: _surface,
                      textCol: _textCol,
                      subCol: _subCol,
                      divCol: _divCol,
                    ),
                    const SizedBox(height: 28),

                    // ════════════════════════════════════════════════════
                    // ASISTENCIA
                    // ════════════════════════════════════════════════════
                    _sectionLabel('ASISTENCIA'),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _asistio,
                      dropdownColor: _surface,
                      style: TextStyle(color: _textCol),
                      decoration: const InputDecoration(
                        labelText: '¿Asistió?',
                        prefixIcon: Icon(Icons.how_to_reg_outlined),
                      ),
                      items: const ['SI', 'NO']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) => setState(() => _asistio = v ?? 'NO'),
                    ),
                    const SizedBox(height: 32),

                    // ── Buttons ──────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: isHalloween ? 0 : 2,
                        ),
                        onPressed: _saving ? null : _guardar,
                        icon: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_alt_rounded),
                        label: Text(
                          _saving ? 'Guardando…' : 'Guardar cambios',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _subCol,
                          side: BorderSide(color: _divCol),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Cascading programa field ──────────────────────────────────────────────
  Widget _buildProgramaField() {
    final programs = _programas;

    if (programs.isEmpty) {
      return _upperField(
        controller: _programaLibreCtrl,
        label: 'Programa de interés',
        prefixIcon: Icons.book_outlined,
      );
    }

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
        hint: Text('Selecciona programa', style: TextStyle(color: _subCol)),
        items: programs
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) => setState(() => _programaInteres = v ?? ''),
      );
    }

    return _searchableField(
      key: ValueKey('prog_$_nivelEstudios'),
      options: programs,
      label: 'Programa de interés',
      prefixIcon: Icons.book_outlined,
      initialValue: _programaInteres,
      onSelected: (v) => setState(() => _programaInteres = v),
    );
  }

  // ── Field helpers ─────────────────────────────────────────────────────────
  Widget _upperField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
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

  Widget _searchableField({
    Key? key,
    required List<String> options,
    required String label,
    required ValueChanged<String> onSelected,
    String initialValue = '',
    IconData? prefixIcon,
  }) =>
      Autocomplete<String>(
        key: key,
        initialValue: TextEditingValue(text: initialValue),
        optionsBuilder: (v) {
          final q = v.text.toUpperCase().trim();
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
                separatorBuilder: (_, __) => Divider(height: 1, color: _divCol),
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
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: Icon(Icons.search_rounded, color: _subCol, size: 18),
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        ),
      );

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

// ═════════════════════════════════════════════════════════════════════════════
// Acompañantes stepper (mirrors register_screen)
// ═════════════════════════════════════════════════════════════════════════════
class _AcompanantesStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final Color accent, surface, textCol, subCol, divCol;

  const _AcompanantesStepper({
    required this.value, required this.onChanged,
    required this.accent, required this.surface,
    required this.textCol, required this.subCol, required this.divCol,
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
                        color: textCol, fontWeight: FontWeight.w600, fontSize: 14)),
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
            child: Text('$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: accent, fontSize: 20, fontWeight: FontWeight.bold)),
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
  const _StepBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 22),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Info card (read-only header)
// ═════════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final RegistroConferencia? registro;
  final bool isHalloween;
  final Color surface, accent, textCol, subCol, divCol;

  const _InfoCard({
    required this.registro, required this.isHalloween,
    required this.surface, required this.accent,
    required this.textCol, required this.subCol, required this.divCol,
  });

  @override
  Widget build(BuildContext context) {
    final r = registro;
    if (r == null) return const SizedBox.shrink();
    final confirmado = r.asistioConfirmado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: confirmado
              ? AppColors.success.withValues(alpha: 0.5)
              : isHalloween
                  ? accent.withValues(alpha: 0.3)
                  : divCol,
          width: isHalloween ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent,
                radius: 22,
                child: Text(
                  r.nombreCompleto.isNotEmpty
                      ? r.nombreCompleto[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.nombreCompleto.isNotEmpty
                          ? r.nombreCompleto
                          : 'Sin nombre',
                      style: TextStyle(
                          color: textCol,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusBadge(
                          label: confirmado ? 'Asistió' : 'Pendiente',
                          color: confirmado ? AppColors.success : AppColors.warning,
                          icon: confirmado
                              ? Icons.check_circle_outline
                              : Icons.hourglass_bottom_outlined,
                        ),
                        if ((r.acompanantes ?? 0) > 0) ...[
                          const SizedBox(width: 6),
                          _StatusBadge(
                            label: '+${r.acompanantes} acomp.',
                            color: accent,
                            icon: Icons.group_outlined,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 20, color: divCol),
          _InfoRow('ID', '${r.id}', subCol, textCol),
          if ((r.tipo ?? '').isNotEmpty)
            _InfoRow('Tipo', r.tipo!, subCol, textCol),
          if ((r.conferencista ?? '').isNotEmpty)
            _InfoRow(
                isHalloween ? 'Artista' : 'Conferencista',
                r.conferencista!,
                subCol,
                textCol),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color labelColor, valueColor;
  const _InfoRow(this.label, this.value, this.labelColor, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: TextStyle(
                      color: labelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(color: valueColor, fontSize: 13)),
            ),
          ],
        ),
      );
}
