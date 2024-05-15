// To parse this JSON data, do
//
//     final materialesXtpi = materialesXtpiFromMap(jsonString);

// ignore_for_file: file_names

import 'dart:convert';

List<MaterialXtpi> materialesXtpiFromMap(String str) => List<MaterialXtpi>.from(
    json.decode(str).map((x) => MaterialXtpi.fromJson(x)));

String materialesXtpiToMap(List<MaterialXtpi> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class MaterialXtpi {
  late int configTpiMaterialId;
  late int tipoPuntoInspeccionId;
  late int materialId;
  late String codMaterial;
  late String descripcion;
  late String unidad;
  late String dosis;

  MaterialXtpi({
    required this.configTpiMaterialId,
    required this.tipoPuntoInspeccionId,
    required this.materialId,
    required this.codMaterial,
    required this.descripcion,
    required this.unidad,
    required this.dosis,
  });

  factory MaterialXtpi.fromJson(Map<String, dynamic> json) => MaterialXtpi(
        configTpiMaterialId: json["configTPIMaterialId"] as int? ?? 0,
        tipoPuntoInspeccionId: json["tipoPuntoInspeccionId"] as int? ?? 0,
        materialId: json["materialId"] as int? ?? 0,
        codMaterial: json["codMaterial"] as String? ?? '',
        descripcion: json["descripcion"] as String? ?? '',
        unidad: json["unidad"] as String? ?? '',
        dosis: json["dosis"] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        "configTPIMaterialId": configTpiMaterialId,
        "tipoPuntoInspeccionId": tipoPuntoInspeccionId,
        "materialId": materialId,
        "codMaterial": codMaterial,
        "descripcion": descripcion,
        "unidad": unidad,
        "dosis": dosis,
      };

  MaterialXtpi.empty() {
    configTpiMaterialId = 0;
    tipoPuntoInspeccionId = 0;
    materialId = 0;
    codMaterial = '';
    descripcion = '';
    unidad = '';
    dosis = '';
  }
}
