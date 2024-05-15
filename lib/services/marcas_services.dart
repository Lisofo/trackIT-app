// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:app_track_it/providers/orden_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:app_track_it/config/config.dart';
import 'package:app_track_it/models/marcas.dart';
import 'package:provider/provider.dart';

class MarcasServices {
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

  Future postMarca(BuildContext context, Marca marca, String token) async {
    try {
      String link = '${apiUrl}api/v1/marcas';
      var headers = {'Authorization': token};
      var xx = marca.toMap();
      final resp = await _dio.request(link,
          data: xx, options: Options(method: 'POST', headers: headers));

      marca.marcaId = resp.data['marcaId'];

      if (resp.statusCode == 201) {
        Provider.of<OrdenProvider>(context, listen: false)
            .setMarca(marca.marcaId);
        showDialogs(context, 'Acaba de marcar entrada, que tenga buena jornada',
            false, false);
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

  Future putMarca(BuildContext context, Marca marca, String token) async {
    try {
      String link = '${apiUrl}api/v1/marcas/${marca.marcaId.toString()}';
      var headers = {'Authorization': token};
      var xx = marca.toMap();
      final resp = await _dio.request(link,
          data: xx, options: Options(method: 'PUT', headers: headers));

      if (resp.statusCode == 200) {
        showDialogs(context,
            'Marcó salida correctamente, que tenga un buen dia', false, false);
        print('funciono marcar salida');
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
