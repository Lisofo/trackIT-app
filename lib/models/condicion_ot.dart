// To parse this JSON data, do
//
//     final condicionOt = condicionOtFromJson(jsonString);

import 'dart:convert';

List<CondicionOt> condicionOtFromJson(String str) => List<CondicionOt>.from(json.decode(str).map((x) => CondicionOt.fromJson(x)));

String condicionOtToJson(List<CondicionOt> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CondicionOt {
  late int? condOtId;
  late String? descripcion;
  late bool? facturable;

  CondicionOt({
    this.condOtId,
    this.descripcion,
    this.facturable,
  });

  CondicionOt copyWith({
    int? condOtId,
    String? descripcion,
    bool? facturable,
  }) => CondicionOt(
    condOtId: condOtId ?? this.condOtId,
    descripcion: descripcion ?? this.descripcion,
    facturable: facturable ?? this.facturable,
  );

  factory CondicionOt.fromJson(Map<String, dynamic> json) => CondicionOt(
    condOtId: json["CondOTId"] as int?,
    descripcion: json["Descripcion"] as String?,
    facturable: json["Facturable"] as bool?,
  );

  Map<String, dynamic> toJson() => {
    "CondOTId": condOtId,
    "Descripcion": descripcion,
    "Facturable": facturable,
  };

  CondicionOt.empty() {
    condOtId = null;
    descripcion = null;
    facturable = null;
  }
}
