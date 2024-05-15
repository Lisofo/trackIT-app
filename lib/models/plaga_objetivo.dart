import 'dart:convert';

List<PlagaObjetivo> plagaObjetivoFromMap(String str) =>
    List<PlagaObjetivo>.from(
        json.decode(str).map((x) => PlagaObjetivo.fromJson(x)));

String plagaObjetivoToMap(List<PlagaObjetivo> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class PlagaObjetivo {
  late int plagaObjetivoId;
  late String codPlagaObjetivo;
  late String descripcion;
  late dynamic fechaBaja;

  PlagaObjetivo({
    required this.plagaObjetivoId,
    required this.codPlagaObjetivo,
    required this.descripcion,
    required this.fechaBaja,
  });

  factory PlagaObjetivo.fromJson(Map<String, dynamic> json) => PlagaObjetivo(
        plagaObjetivoId: json["plagaObjetivoId"] as int? ?? 0,
        codPlagaObjetivo: json["codPlagaObjetivo"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
        fechaBaja: json["fechaBaja"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "plagaObjetivoId": plagaObjetivoId,
        "codPlagaObjetivo": codPlagaObjetivo,
        "descripcion": descripcion,
        "fechaBaja": fechaBaja,
      };

  PlagaObjetivo.empty() {
    plagaObjetivoId = 0;
    codPlagaObjetivo = '';
    descripcion = '';
    fechaBaja = '';
  }
}
