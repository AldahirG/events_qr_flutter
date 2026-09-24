// lib/models/registro_conferencia.dart
class RegistroConferencia {
  final int id;
  final String? nombre;
  final String? correo;
  final String? telefono;
  final String? nivelEstudios;
  final String? conferencista;
  final int? idConferencista;
  final String? nombreInvito;
  final String? facebook;
  final DateTime? fechaRegistro;
  final String? horarioHouse;
  final String? hobbies;
  final String? alumno;
  final String? promocion;
  final String? tipo;
  final String? escProc;
  final String? nivelUninter;
  final String? reglamento;
  final String? programaInteres;
  final String? asistio; // "SI" | "NO"
  final int? acompanantes;
  final String? curp;
  final String? comoEnteroEvento;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? matricula;

  const RegistroConferencia({
    required this.id,
    this.nombre,
    this.correo,
    this.telefono,
    this.nivelEstudios,
    this.conferencista,
    this.idConferencista,
    this.nombreInvito,
    this.facebook,
    this.fechaRegistro,
    this.horarioHouse,
    this.hobbies,
    this.alumno,
    this.promocion,
    this.tipo,
    this.escProc,
    this.nivelUninter,
    this.reglamento,
    this.programaInteres,
    this.asistio,
    this.acompanantes,
    this.curp,
    this.comoEnteroEvento,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.matricula,
  });

  bool get asistioConfirmado {
    final v = asistio?.toUpperCase().trim() ?? '';
    return v == 'SI' || v == '1' || v == 'TRUE';
  }

  String get nombreCompleto {
    // API returns full name in `nombre`; apellidos are extra if present
    final parts = [apellidoPaterno, apellidoMaterno, nombre]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .toList();
    return parts.isEmpty ? '' : parts.join(' ');
  }

  factory RegistroConferencia.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    // Helper: try multiple key variants (API uses mixed case)
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k] as T?;
      }
      return null;
    }

    return RegistroConferencia(
      id: (j['idhalloweenfest_registro'] ?? j['idregistro_conferencias'] ?? j['id'] ?? 0) as int,
      // API model uses lowercase for core personal fields
      nombre: pick(['nombre', 'Nombre']),
      correo: pick(['correo', 'Correo']),
      telefono: pick(['telefono', 'Telefono']),
      nivelEstudios: pick(['Nivel_Estudios', 'nivel_estudios', 'nivelEstudios']),
      conferencista: pick(['Conferencista', 'conferencista']),
      idConferencista: pick(['idConferencista']),
      nombreInvito: pick(['Nombre_invito', 'NombreInvito', 'nombreInvito', 'invito']),
      facebook: pick(['Facebook', 'facebook']),
      fechaRegistro: parseDate(pick(['fecha_registro', 'fechaRegistro'])),
      horarioHouse: pick(['horario_house', 'horarioHouse']),
      hobbies: pick(['hobbies']),
      alumno: pick(['alumno']),
      promocion: pick(['promocion']),
      tipo: pick(['tipo']),
      escProc: pick(['escProc', 'escuelaProcedencia']),
      nivelUninter: pick(['NivelUninter', 'nivelUninter']),
      reglamento: pick(['Reglamento', 'reglamento']),
      programaInteres: pick(['programaInteres', 'programa']),
      asistio: j['asistio']?.toString(),
      acompanantes: (j['acompanantes'] as num?)?.toInt(),
      curp: pick(['curp']),
      comoEnteroEvento: pick(['comoEnteroEvento']),
      apellidoPaterno: pick(['ApellidoPaterno', 'apellidoPaterno']),
      apellidoMaterno: pick(['ApellidoMaterno', 'apellidoMaterno']),
      matricula: pick(['Matricula', 'matricula']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'correo': correo,
        'telefono': telefono,
        'Nivel_Estudios': nivelEstudios,
        'Nombre_invito': nombreInvito,
        'escProc': escProc,
        'programaInteres': programaInteres,
        'alumno': alumno,
        'asistio': asistio,
        'curp': curp,
      };
}
