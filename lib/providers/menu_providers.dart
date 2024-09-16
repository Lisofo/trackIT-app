import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:flutter/widgets.dart';

class MenuProvider {
  Menu opciones = Menu.empty();
  List<Ruta> rutas = [];
  MenuProvider();

  Future<List<dynamic>> cargarData(BuildContext context, String codTipoOrden, String token) async {
    final Menu? menu = await MenuServices().getMenu(context, token);
    if(menu != null){
      rutas = menu.rutas;
      return rutas.where((Ruta ruta) => ruta.tipoOrden.contains(codTipoOrden)).toList();
    } else{
      return [];
    }
  }
}

final menuProvider = MenuProvider();
