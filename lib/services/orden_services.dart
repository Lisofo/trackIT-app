// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdenServices {
  final _dio = Dio();
  String apiLink = Config.APIURL;
  int? statusCode = 0;

  static Future<void> showDialogs(BuildContext context, String errorMessage,
      bool doblePop, bool triplePop) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Mensaje'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (doblePop) {
                  Navigator.of(context).pop();
                }
                if (triplePop) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showErrorDialog(BuildContext context, String mensaje) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        surfaceTintColor: Colors.white,
        title: const Text('Error'),
        content: Text(mensaje),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future getOrden(BuildContext context, String tecnicoId, String desde, String hasta, String token) async {
    String link = apiLink;
    String linkFiltrado = link += desde == 'Anteriores'
        ? 'api/v1/ordenes/?sort=fechaDesde&tecnicoId=$tecnicoId&estado=EN PROCESO,PENDIENTE'
        : 'api/v1/ordenes/?sort=fechaDesde&tecnicoId=$tecnicoId&fechaDesde=$desde&fechaHasta=$hasta';

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
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500){
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        }
      } 
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
        showErrorDialog(context, 'Hubo un error al momento de cambiar el estado');
      }

      return;
    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else if(e.response!.statusCode! >= 500) {
              showErrorDialog(context, 'Error: No se pudo completar la solicitud');
            } else{
              final errors = responseData['errors'] as List<dynamic>;
              final errorMessages = errors.map((error) {
                return "Error: ${error['message']}";
              }).toList();
              showErrorDialog(context, errorMessages.join('\n'));
            }
          } else {
            showErrorDialog(context, 'Error: ${e.response!.data}');
          }
        } else {
          showErrorDialog(context, 'Error: No se pudo completar la solicitud');
        } 
      } 
    }
  }
}
