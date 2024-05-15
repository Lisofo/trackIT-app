// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:app_track_it/config/config.dart';
import 'package:app_track_it/models/orden.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OrdenServices {
  final _dio = Dio();
  String apiLink = Config.APIURL;

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
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarError(BuildContext context, String mensaje) async {
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
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future getOrden(
      String tecnicoId, String desde, String hasta, String token) async {
    String link = apiLink;
    String linkFiltrado = link += desde == 'Anteriores'
        ? 'api/v1/ordenes/?sort=fechaDesde&tecnicoId=$tecnicoId&estado=EN PROCESO'
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

      final List<dynamic> ordenList = resp.data;
      var retorno = ordenList.map((obj) => Orden.fromJson(obj)).toList();
      print(retorno.length);
      return retorno;
    } on DioException catch (e) {
      print(e.error);
      print(e.response);
    }
  }

  Future patchOrden(BuildContext context, Orden orden, String estado,
      int ubicacionId, String token) async {
    String link = apiLink;
    link += 'api/v1/ordenes/${orden.ordenTrabajoId}';

    try {
      var headers = {'Authorization': token};
      var data = ({"estado": estado, "ubicacionId": ubicacionId});
      var resp = await _dio.request(link,
          options: Options(
            method: 'PATCH',
            headers: headers,
          ),
          data: data);

      if (resp.statusCode == 200) {
        orden.estado = estado;
        await showDialogs(
            context, 'Estado cambiado correctamente', false, false);
      } else {
        _mostrarError(
            context, 'Hubo un error al momento de cambiar el servicio');
      }

      return;
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            final errors = responseData['errors'] as List<dynamic>;
            final errorMessages = errors.map((error) {
              return "Error: ${error['message']}";
            }).toList();
            await _mostrarError(context, errorMessages.join('\n'));
          } else {
            await _mostrarError(context, 'Error: ${e.response!.data}');
          }
        } else {
          await _mostrarError(context, 'Error: ${e.message}');
        }
      }
    }
  }
}
