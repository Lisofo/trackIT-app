class RevisionIncidencia {
  late int otIncidenciaId;
  late int ordenTrabajoId;
  late int otRevisionId;
  late String observacion;
  late List<int> incidenciaIds;
  List<IncidenciaAdjunto>? adjuntos;

  RevisionIncidencia({
    required this.otIncidenciaId,
    required this.ordenTrabajoId,
    required this.otRevisionId,
    required this.observacion,
    required this.incidenciaIds,
    this.adjuntos,
  });

  factory RevisionIncidencia.fromJson(Map<String, dynamic> json) {
    return RevisionIncidencia(
      otIncidenciaId: json['otIncidenciaId'] as int? ?? 0,
      ordenTrabajoId: json['ordenTrabajoId'] as int? ?? 0,
      otRevisionId: json['otRevisionId'] as int? ?? json['revisionId'] as int? ?? 0,
      observacion: json['observacion'] as String? ?? '',
      incidenciaIds: (json['incidenciaIds'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'otIncidenciaId': otIncidenciaId,
      'ordenTrabajoId': ordenTrabajoId,
      'otRevisionId': otRevisionId,
      'observacion': observacion,
      'incidenciaIds': incidenciaIds,
    };
  }

  RevisionIncidencia.empty() {
    otIncidenciaId = 0;
    ordenTrabajoId = 0;
    otRevisionId = 0;
    observacion = '';
    incidenciaIds = [];
    adjuntos = [];
  }

  @override
  String toString() {
    return 'RevisionIncidencia(otIncidenciaId: $otIncidenciaId, observacion: $observacion, incidencias: ${incidenciaIds.length})';
  }
}

class IncidenciaAdjunto {
  late String filename;
  late String filepath;

  IncidenciaAdjunto({
    required this.filename,
    required this.filepath,
  });

  factory IncidenciaAdjunto.fromJson(Map<String, dynamic> json) {
    return IncidenciaAdjunto(
      filename: json['filename'] as String? ?? '',
      filepath: json['filepath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'filename': filename,
      'filepath': filepath,
    };
  }
}