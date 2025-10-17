class Registro {
  final int id;
  final String? nombre;
  final String? edad;
  final String? telefono;
  final String? correo;
  final String? escuelaProcedencia;
  final String? artista;
  final String? disfraz;
  final String? varFB;
  final DateTime fechaRegistro;   // no-null en el modelo
  final String? promotor;
  final String? invito;
  final bool? asistio;
  final String? programa;
  final String? comoEnteroEvento;

  Registro({
    required this.id,
    required this.fechaRegistro,
    this.nombre,
    this.edad,
    this.telefono,
    this.correo,
    this.escuelaProcedencia,
    this.artista,
    this.disfraz,
    this.varFB,
    this.promotor,
    this.invito,
    this.asistio,
    this.programa,
    this.comoEnteroEvento,
  });

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == '1' || s == 'true' || s == 'sí' || s == 'si' || s == 'yes') return true;
    if (s == '0' || s == 'false' || s == 'no') return false;
    return null;
  }

  static DateTime _resolveFecha(Map<String, dynamic> j) {
    final candidates = [
      j['fechaRegistro'],
      j['fecha_registro'],
      j['createdAt'],
      j['created_at'],
      j['fecha'], // por si algún backend viejo usa esta
      j['timestamp'],
    ];

    for (final v in candidates) {
      if (v == null) continue;
      if (v is DateTime) return v;
      if (v is int) {
        // milisegundos o segundos -> intenta ambos
        final ms = v > 2000000000 ? v : v * 1000;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      if (v is String && v.trim().isNotEmpty) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
    }
    // fallback seguro para evitar crasheo: epoch 0
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory Registro.fromJson(Map<String, dynamic> json) {
    // helper para id
    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return Registro(
      id: _toInt(json['idhalloweenfest_registro'] ?? json['id']),
      nombre: json['nombre'] as String?,
      edad: json['edad'] as String?,
      telefono: json['telefono'] as String?,
      correo: json['correo'] as String?,
      escuelaProcedencia:
          (json['escuelaProcedencia'] ?? json['escuela_procedencia'] ?? json['escProc']) as String?,
      artista: json['artista'] as String?,
      disfraz: json['disfraz'] as String?,
      varFB: (json['varFB'] ?? json['var_fb']) as String?,
      fechaRegistro: _resolveFecha(json),
      promotor: json['promotor'] as String?,
      invito: json['invito'] as String?,
      asistio: _toBool(json['asistio']),
      programa: json['programa'] as String?,
      comoEnteroEvento:
          (json['comoEnteroEvento'] ?? json['como_entero_evento'] ?? json['Nombre_invito']) as String?,
    );
  }
}
