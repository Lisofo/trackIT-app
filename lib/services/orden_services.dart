// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/control.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/ultima_tarea.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdenServices {
  final _dio = Dio();
  String apiLink = Config.APIURL;
  int? statusCode = 0;

  Future getOrden(BuildContext context, String tecnicoId, String desde, String hasta, String token) async {
    String link = apiLink;
    String linkFiltrado = '${link}api/v1/ordenes/';
    // String linkFiltrado = '${link}api/v1/ordenes/?fechaHasta=2024-09-24 23:59:59';
    
    // += desde == 'Anteriores'
        // ? 'api/v1/ordenes/?sort=fechaDesde&tecnicoId=$tecnicoId&estado=EN PROCESO,PENDIENTE'
        // : 'api/v1/ordenes/?sort=fechaDesde&tecnicoId=$tecnicoId&fechaDesde=$desde&fechaHasta=$hasta';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        linkFiltrado,
        options: Options(
          method: 'GET',
          headers: headers,

        ),
      );
      statusCode = 1;
      final List<dynamic> ordenList = resp.data;
      var retorno = ordenList.map((obj) => Orden.fromJson(obj)).toList();
      print(retorno.length);
      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future postOrden(BuildContext context, String token, Orden orden) async {
    String link = apiLink;
    String linkFiltrado = '${link}api/v1/ordenes/';
    var data = orden.toMapCyP();
    // print(data);

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        linkFiltrado,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      
      // print(resp.data);
      var retorno = Orden.fromJson(resp.data);
      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  // Agregar este método en la clase OrdenServices
  Future actualizarOrden(BuildContext context, String token, Orden orden) async {
    String link = apiLink;
    String linkFiltrado = '${link}api/v1/ordenes/${orden.ordenTrabajoId}'; // Usar PUT para actualizar

    try {
      var headers = {'Authorization': token};
      var data = orden.toMapCyP();
      
      var resp = await _dio.request(
        linkFiltrado,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data
      );
      
      statusCode = 1;
      
      print(resp.data);
      var retorno = Orden.fromJson(resp.data);
      return retorno;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
      rethrow;
    }
  }

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }


  Future patchOrden(BuildContext context, Orden orden, String estado, int ubicacionId, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}';

    try {
      var headers = {'Authorization': token};
      var data = ({"estado": estado, "ubicacionId": ubicacionId});
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        orden.estado = estado;
        Provider.of<OrdenProvider>(context, listen: false).cambiarEstadoOrden(estado);
        
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future iniciarTrabajo(BuildContext context, Orden orden, int lineaId, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/tiempos';

    try {
      var headers = {'Authorization': token};
      var data = ({"lineaId": lineaId});
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        final UltimaTarea ultima = await ultimaTarea(context, token);
        Provider.of<OrdenProvider>(context, listen: false).setUltimaTarea(ultima);
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future cerrarTarea(BuildContext context, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/tiempos';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        final UltimaTarea ultima = await ultimaTarea(context, token);
        Provider.of<OrdenProvider>(context, listen: false).setUltimaTarea(ultima);
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future ultimaTarea(BuildContext context, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/tiempos';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      statusCode = 1;
      late UltimaTarea ultimaTarea;
      if (resp.data == null) {
        ultimaTarea = UltimaTarea.empty();
      } else {
        ultimaTarea = UltimaTarea.fromMap(resp.data);
      }

      return ultimaTarea;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future getControles2(BuildContext context, int ordenId, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/$ordenId/controles';
    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,

        ),
      );
      statusCode = 1;
      final List<dynamic> controlesList = resp.data;

      return controlesList.map((obj) => Control.fromJson(obj)).toList();
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future datosAdicionales(BuildContext context, Orden orden, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/datosAdicionales';

    try {
      var headers = {'Authorization': token};
      var data = ({
        "km": orden.km,
        "comentarioCliente": orden.comentarioCliente, 
        "comentarioTrabajo": orden.comentarioTrabajo,
        "alerta": orden.alerta
      });

      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        // Provider.of<OrdenProvider>(context, listen: false).cambiarEstadoOrden(estado);
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future siguienteEstadoOrden(BuildContext context, Orden orden, int accionId, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/accion/$accionId';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        // Provider.of<OrdenProvider>(context, listen: false).cambiarEstadoOrden(resp.data["estadoSiguiente"]);
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return resp.data["estadoSiguiente"];
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future patchOrdenCambioEstado(BuildContext context, Orden orden, int accionId, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}';

    try {
      var headers = {'Authorization': token};
      var data = ({"accionId": accionId});
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'PATCH',
          headers: headers,
        ),
        data: data
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        Provider.of<OrdenProvider>(context, listen: false).cambiarEstadoOrden(resp.data["estado"]);
        
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future imprimirOT(BuildContext context, Orden orden, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/imprimirOT';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        router.pop();
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }

  Future imprimirControles(BuildContext context, Orden orden, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}/imprimirControlesOT';

    try {
      var headers = {'Authorization': token};
      var resp = await _dio.request(
        link,
        options: Options(
          method: 'POST',
          headers: headers,
        ),
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        router.pop();
      } else {
        Carteles.showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }
      return;
    } catch (e) {
      statusCode = 0;
      Carteles().errorManagment(e, context);
    }
  }
}
