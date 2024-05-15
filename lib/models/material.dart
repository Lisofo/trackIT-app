import 'dart:convert';

List<Materiales> materialFromMap(String str) =>
    List<Materiales>.from(json.decode(str).map((x) => Materiales.fromJson(x)));

String materialToMap(List<Materiales> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class Materiales {
  late int materialId;
  late String codMaterial;
  late String descripcion;
  late String dosis;
  late String unidad;
  late String fabProv;
  late String enAppTecnico;
  late String enUso;

  Materiales({
    required this.materialId,
    required this.codMaterial,
    required this.descripcion,
    required this.dosis,
    required this.unidad,
    required this.fabProv,
    required this.enAppTecnico,
    required this.enUso,
  });

  factory Materiales.fromJson(Map<String, dynamic> json) => Materiales(
        materialId: json["materialId"] as int? ?? 0,
        codMaterial: json["codMaterial"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
        dosis: json["dosis"] as String? ?? '',
        unidad: json["unidad"] as String? ?? '',
        fabProv: json["fabProv"] as String? ?? '',
        enAppTecnico: json["enAppTecnico"] as String? ?? '',
        enUso: json["enUso"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "materialId": materialId,
        "codMaterial": codMaterial,
        "descripcion": descripcion,
        "dosis": dosis,
        "unidad": unidad,
        "fabProv": fabProv,
        "enAppTecnico": enAppTecnico,
        "enUso": enUso,
      };

  Materiales.empty() {
    materialId = 0;
    codMaterial = '';
    descripcion = '';
    dosis = '';
    unidad = '';
    fabProv = '';
    enAppTecnico = '';
    enUso = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
