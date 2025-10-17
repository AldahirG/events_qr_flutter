// lib/models/registro.dart

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
  final DateTime fechaRegistro; // no-null en el modelo
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

  /// ✅ Getter para usar en list_screen o UI sin errores
  String get nombreCompleto => nombre?.trim().isNotEmpty == true
      ? nombre!.trim()
      : '(Sin nombre)';

  String get folio => id.toString().padLeft(3, '0');


  // ---------------------- UTILIDADES INTERNAS ----------------------

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (['1', 'true', 'sí', 'si', 'yes'].contains(s)) return true;
    if (['0', 'false', 'no'].contains(s)) return false;
    return null;
  }

  static DateTime _resolveFecha(Map<String, dynamic> j) {
    final candidates = [
      j['fechaRegistro'],
      j['fecha_registro'],
      j['createdAt'],
      j['created_at'],
      j['fecha'], // compatibilidad con versiones anteriores
      j['timestamp'],
    ];

    for (final v in candidates) {
      if (v == null) continue;
      if (v is DateTime) return v;
      if (v is int) {
        // soporta timestamps en segundos o milisegundos
        final ms = v > 2000000000 ? v : v * 1000;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      if (v is String && v.trim().isNotEmpty) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
    }
    // fallback seguro
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ---------------------- CONSTRUCTOR FROM JSON ----------------------

  factory Registro.fromJson(Map<String, dynamic> json) {
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
      escuelaProcedencia: (json['escuelaProcedencia'] ??
              json['escuela_procedencia'] ??
              json['escProc']) as String?,
      artista: json['artista'] as String?,
      disfraz: json['disfraz'] as String?,
      varFB: (json['varFB'] ?? json['var_fb']) as String?,
      fechaRegistro: _resolveFecha(json),
      promotor: json['promotor'] as String?,
      invito: json['invito'] as String?,
      asistio: _toBool(json['asistio']),
      programa: json['programa'] as String?,
      comoEnteroEvento: (json['comoEnteroEvento'] ??
              json['como_entero_evento'] ??
              json['Nombre_invito']) as String?,
    );
  }

  // ---------------------- MÉTODOS AUXILIARES ----------------------

  Map<String, dynamic> toJson() {
    return {
      'idhalloweenfest_registro': id,
      'nombre': nombre,
      'edad': edad,
      'telefono': telefono,
      'correo': correo,
      'escuelaProcedencia': escuelaProcedencia,
      'artista': artista,
      'disfraz': disfraz,
      'varFB': varFB,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'promotor': promotor,
      'invito': invito,
      'asistio': asistio == true ? 1 : 0,
      'programa': programa,
      'comoEnteroEvento': comoEnteroEvento,
    };
  }
}
