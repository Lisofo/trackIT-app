import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MenuProvider {
  List<dynamic> opciones = [];

  MenuProvider();

  Future<List<dynamic>> cargarData(String codTipoOrden) async {
    final resp = await rootBundle.loadString('data/menu_opts.json');

    Map dataMap = json.decode(resp);
    opciones = dataMap['rutas'];
    return opciones
        .where((menu) => menu['tipoOrden'].toString().contains(codTipoOrden))
        .toList();
  }
}

final menuProvider = MenuProvider();
