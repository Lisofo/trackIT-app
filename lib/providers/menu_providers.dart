import 'dart:convert';

import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class MenuProvider {
  List<dynamic> opciones = [];
  List<Ruta> rutas = [];
  MenuProvider();
  List<dynamic> opciones2 = [];
  List<DrawerOpcion> drawerOpciones = []; // NUEVO: Para drawer

  // Método para cargar datos del drawer (usado en orden_interna_vertical)
  Future<List<DrawerOpcion>> cargarDataDrawer(BuildContext context, String codTipoOrden, String token) async {
    final DrawerMenu? drawerMenu = await MenuServices().getDrawer(context, token);
    if(drawerMenu != null){
      // Filtrar opciones por tipoOrden si se especifica
      return drawerMenu.opciones;
    } else {
      return [];
    }
  }

  // Método original para cargar datos administrativos (mantener para compatibilidad)
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