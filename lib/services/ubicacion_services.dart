// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:app_track_it/config/config.dart';
import 'package:flutter/material.dart';
import 'package:app_track_it/models/ubicacion.dart';

class UbicacionServices {
  String apiUrl = Config.APIURL;
  final _dio = Dio();

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

  Future postUbicacion(
      BuildContext context, Ubicacion ubicacion, String token) async {
    try {
      String link = '${apiUrl}api/v1/ubicaciones';
      var headers = {'Authorization': token};
      var xx = ubicacion.toMap();
      final resp = await _dio.request(link,
          data: xx, options: Options(method: 'POST', headers: headers));

      ubicacion.ubicacionId = resp.data['ubicacionId'];

      if (resp.statusCode == 201) {
      } else {
        _mostrarError(context, 'Hubo un error al momento de marcar entrada');
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
