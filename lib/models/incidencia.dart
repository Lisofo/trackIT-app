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
      incidenciaId: json["incidenciaId"] as int? ?? 0,
      codIncidencia: json["codIncidencia"] as String? ?? '',
      descripcion: json["descripcion"] as String? ?? '',
    );

  Map<String, dynamic> toMap() => {
    "incidenciaId": incidenciaId,
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
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Incidencia && other.incidenciaId == incidenciaId;
  }

  @override
  int get hashCode => incidenciaId.hashCode;
}