class Incidencia {
  late int incidenciaId;
  late String codIncidencia;
  late String descripcion;

  Incidencia({
    required this.incidenciaId,
    required this.codIncidencia,
    required this.descripcion,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) =>
    Incidencia(
      incidenciaId: json["metodoAplicacionId"] as int? ?? 0,
      codIncidencia: json["codIncidencia"] as String? ?? '',
      descripcion: json["descripcion"] as String? ?? '',
    );

  Map<String, dynamic> toMap() => {
    "metodoAplicacionId": incidenciaId,
    "codIncidencia": codIncidencia,
    "descripcion": descripcion,
  };

  Incidencia.empty() {
    incidenciaId = 0;
    codIncidencia = '';
    descripcion = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}