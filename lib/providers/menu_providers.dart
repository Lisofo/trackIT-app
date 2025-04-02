import 'dart:convert';

import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MenuProvider {
  Menu opciones = Menu.empty();
  List<Ruta> rutas = [];
  MenuProvider();
  List<dynamic> opciones2 = [];

  Future<List<dynamic>> cargarData(BuildContext context, String codTipoOrden, String token) async {
    final Menu? menu = await MenuServices().getMenu(context, token);
    if(menu != null){
      rutas = menu.rutas;
      return rutas.where((Ruta ruta) => ruta.tipoOrden.contains(codTipoOrden)).toList();
    } else{
      return [];
    }
  }

  Future<List<dynamic>> cargarDataJson() async {
    final resp = await rootBundle.loadString('data/menu_opts.json');

    Map dataMap = json.decode(resp);
    opciones2 = dataMap['rutas'];
    return opciones2;
  }
}

final menuProvider = MenuProvider();
