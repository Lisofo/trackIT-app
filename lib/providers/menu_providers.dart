import 'dart:convert';

import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MenuProvider {
   List<dynamic> opciones = [];
  List<Ruta> rutas = []; // CAMBIÉ: List<Opcion> por List<Ruta>
  MenuProvider();
  List<dynamic> opciones2 = [];

  Future<List<dynamic>> cargarData(BuildContext context, String codTipoOrden, String token) async {
    final Menu? menu = await MenuServices().getMenu(context, token);
    if(menu != null){
      rutas = menu.rutas;
      // CORRECCIÓN: Buscar en las opciones de cada ruta
      List<Opcion> opcionesFiltradas = [];
      
      for (var ruta in rutas) {
        for (var opcion in ruta.opciones) {
          if (opcion.tipoOrden != null && opcion.tipoOrden!.contains(codTipoOrden)) {
            opcionesFiltradas.add(opcion);
          }
        }
      }
      
      return opcionesFiltradas;
    } else{
      return [];
    }
  }

  Future<List<dynamic>> cargarDataAdm(BuildContext context, String token) async {
    final menu = await MenuServices().getMenu(context, token);
    if(menu != null){
      opciones = menu.rutas;
      return opciones;
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
