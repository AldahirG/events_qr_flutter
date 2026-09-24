// lib/models/reporte_resumen.dart

class DatosGenerales {
  final String evento;
  final String fecha;
  final String ubicacion;
  final String responsable;

  const DatosGenerales({
    required this.evento,
    required this.fecha,
    required this.ubicacion,
    required this.responsable,
  });

  factory DatosGenerales.fromJson(Map<String, dynamic> j) => DatosGenerales(
        evento: j['evento']?.toString() ?? '',
        fecha: j['fecha']?.toString() ?? '',
        ubicacion: j['ubicacion']?.toString() ?? '',
        responsable: j['responsable']?.toString() ?? '',
      );
}

class Duplicado {
  final String nombre;
  final String promotor;
  final String motivo;

  const Duplicado({
    required this.nombre,
    required this.promotor,
    required this.motivo,
  });

  factory Duplicado.fromJson(Map<String, dynamic> j) => Duplicado(
        nombre: j['nombre']?.toString() ?? '',
        promotor: j['promotor']?.toString() ?? '',
        motivo: j['motivo']?.toString() ?? '',
      );
}

class DesempenoPromotor {
  final String promotor;
  final int invitados;
  final int asistentes;
  final int acompanantes;
  final int conversion; // 0–100, integer per backend spec
  final int pi;         // cuántos dieron programa de interés

  const DesempenoPromotor({
    required this.promotor,
    required this.invitados,
    required this.asistentes,
    required this.acompanantes,
    required this.conversion,
    required this.pi,
  });

  factory DesempenoPromotor.fromJson(Map<String, dynamic> j) =>
      DesempenoPromotor(
        promotor: j['promotor']?.toString() ?? '',
        invitados: (j['invitados'] as num?)?.toInt() ?? 0,
        asistentes: (j['asistentes'] as num?)?.toInt() ?? 0,
        acompanantes: (j['acompanantes'] as num?)?.toInt() ?? 0,
        conversion: (j['conversion'] as num?)?.toInt() ?? 0,
        pi: (j['pi'] as num?)?.toInt() ?? 0,
      );
}

/// Minimal promotor record used inside Insights (conversion only).
class PromoSimple {
  final String promotor;
  final int conversion;

  const PromoSimple({required this.promotor, required this.conversion});

  factory PromoSimple.fromJson(Map<String, dynamic> j) => PromoSimple(
        promotor: j['promotor']?.toString() ?? '',
        conversion: (j['conversion'] as num?)?.toInt() ?? 0,
      );
}

/// Minimal record used for masInvitados / menosInvitados.
class InvitadoSimple {
  final String promotor;
  final int invitados;

  const InvitadoSimple({required this.promotor, required this.invitados});

  factory InvitadoSimple.fromJson(Map<String, dynamic> j) => InvitadoSimple(
        promotor: j['promotor']?.toString() ?? '',
        invitados: (j['invitados'] as num?)?.toInt() ?? 0,
      );
}

class Insights {
  /// Promotores con conversión ≥70% Y ≥2 invitados.
  final List<PromoSimple> altoDesempeno;

  /// Promotores con conversión = 0%.
  final List<PromoSimple> peorPromotor;

  /// Promotor con más invitados.
  final InvitadoSimple? masInvitados;

  /// Promotor con menos invitados.
  final InvitadoSimple? menosInvitados;

  final bool altaPerdidaFunnel;

  const Insights({
    required this.altoDesempeno,
    required this.peorPromotor,
    this.masInvitados,
    this.menosInvitados,
    required this.altaPerdidaFunnel,
  });

  factory Insights.fromJson(Map<String, dynamic> j) => Insights(
        altoDesempeno: (j['altoDesempeno'] as List<dynamic>? ?? [])
            .map((e) => PromoSimple.fromJson(e as Map<String, dynamic>))
            .toList(),
        peorPromotor: (j['peorPromotor'] as List<dynamic>? ?? [])
            .map((e) => PromoSimple.fromJson(e as Map<String, dynamic>))
            .toList(),
        masInvitados: j['masInvitados'] != null
            ? InvitadoSimple.fromJson(
                j['masInvitados'] as Map<String, dynamic>)
            : null,
        menosInvitados: j['menosInvitados'] != null
            ? InvitadoSimple.fromJson(
                j['menosInvitados'] as Map<String, dynamic>)
            : null,
        altaPerdidaFunnel: j['altaPerdidaFunnel'] as bool? ?? false,
      );
}

class ReporteResumen {
  final DatosGenerales datosGenerales;
  final int totalRegistros;
  final int totalDuplicados;
  final int registrosUnicos;
  final List<Duplicado> duplicados;
  final int asistentesRegistrados;
  final int asistentesSinRegistro;
  final int totalAcompanantes;
  final int totalAsistentes;
  final String pctRegistroAsistencia;
  final String pctAsistenciaTotal;
  final List<DesempenoPromotor> desempenoPorPromotor;
  final String pctDirectos;
  final String pctWalkins;
  final Insights insights;

  const ReporteResumen({
    required this.datosGenerales,
    required this.totalRegistros,
    required this.totalDuplicados,
    required this.registrosUnicos,
    required this.duplicados,
    required this.asistentesRegistrados,
    required this.asistentesSinRegistro,
    required this.totalAcompanantes,
    required this.totalAsistentes,
    required this.pctRegistroAsistencia,
    required this.pctAsistenciaTotal,
    required this.desempenoPorPromotor,
    required this.pctDirectos,
    required this.pctWalkins,
    required this.insights,
  });

  factory ReporteResumen.fromJson(Map<String, dynamic> j) => ReporteResumen(
        datosGenerales: DatosGenerales.fromJson(
            j['datosGenerales'] as Map<String, dynamic>),
        totalRegistros: (j['totalRegistros'] as num?)?.toInt() ?? 0,
        totalDuplicados: (j['totalDuplicados'] as num?)?.toInt() ?? 0,
        registrosUnicos: (j['registrosUnicos'] as num?)?.toInt() ?? 0,
        duplicados: (j['duplicados'] as List<dynamic>? ?? [])
            .map((e) => Duplicado.fromJson(e as Map<String, dynamic>))
            .toList(),
        asistentesRegistrados:
            (j['asistentesRegistrados'] as num?)?.toInt() ?? 0,
        asistentesSinRegistro:
            (j['asistentesSinRegistro'] as num?)?.toInt() ?? 0,
        totalAcompanantes: (j['totalAcompanantes'] as num?)?.toInt() ?? 0,
        totalAsistentes: (j['totalAsistentes'] as num?)?.toInt() ?? 0,
        pctRegistroAsistencia:
            j['pctRegistroAsistencia']?.toString() ?? '0%',
        pctAsistenciaTotal: j['pctAsistenciaTotal']?.toString() ?? '0%',
        desempenoPorPromotor:
            (j['desempenoPorPromotor'] as List<dynamic>? ?? [])
                .map((e) =>
                    DesempenoPromotor.fromJson(e as Map<String, dynamic>))
                .toList(),
        pctDirectos: j['pctDirectos']?.toString() ?? '0%',
        pctWalkins: j['pctWalkins']?.toString() ?? '0%',
        insights: Insights.fromJson(
            j['insights'] as Map<String, dynamic>? ?? {}),
      );
}
