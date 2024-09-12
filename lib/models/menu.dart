// To parse this JSON data, do
//
//     final menu = menuFromMap(jsonString);

import 'dart:convert';

Menu menuFromMap(String str) => Menu.fromJson(json.decode(str));

String menuToMap(Menu data) => json.encode(data.toMap());

class Menu {
  late String nombreApp;
  late List<Ruta> rutas;

  Menu({
    required this.nombreApp,
    required this.rutas,
  });

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
    nombreApp: json["nombreApp"],
    rutas: List<Ruta>.from(json["rutas"].map((x) => Ruta.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "nombreApp": nombreApp,
    "rutas": List<dynamic>.from(rutas.map((x) => x.toMap())),
  };

  Menu.empty(){
    nombreApp = '';
    rutas = [];
  }
}

class Ruta {
  late String ruta;
  late String icon;
  late String texto;
  late String tipoOrden;

  Ruta({
    required this.ruta,
    required this.icon,
    required this.texto,
    required this.tipoOrden,
  });

  factory Ruta.fromMap(Map<String, dynamic> json) => Ruta(
    ruta: json["ruta"],
    icon: json["icon"],
    texto: json["texto"],
    tipoOrden: json["tipoOrden"],
  );

  Map<String, dynamic> toMap() => {
    "ruta": ruta,
    "icon": icon,
    "texto": texto,
    "tipoOrden": tipoOrden,
  };

  Ruta.empty(){
    ruta = '';
    icon = '';
    texto = '';
    tipoOrden = '';
  }
}
