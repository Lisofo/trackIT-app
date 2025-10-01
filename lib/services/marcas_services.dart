// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/config/config.dart';
import 'package:app_tec_sedel/models/marcas_sedel.dart';
import 'package:provider/provider.dart';

class MarcasServices {
  String apiUrl = Config.APIURL;
  final _dio = Dio();
  int? statusCode;

  static Future<void> showDialogs(BuildContext context, String errorMessage, bool doblePop, bool triplePop) async {
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

  Future<void> resetStatusCode() async {
    statusCode = null;
  }

  Future<int?> getStatusCode() async {
    return statusCode;
  }

  Future postMarca(BuildContext context, Marca marca, String token) async {
    try {
      String link = '${apiUrl}api/v1/marcas';
      var headers = {'Authorization': token};
      var xx = marca.toMap();
      final resp = await _dio.request(
        link,
        data: xx, 
        options: 
        Options(
          method: 'POST', 
          headers: headers
        )
      );
      
      statusCode = 1;
      marca.marcaId = resp.data['marcaId'];

      if (resp.statusCode == 201) {
        Provider.of<OrdenProvider>(context, listen: false).setMarca(marca.marcaId);
        showDialogs(context, 'Acaba de marcar entrada, que tenga buena jornada', false, false);
      } else {
        showErrorDialog(context, 'Hubo un error al momento de marcar entrada');
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

  Future putMarca(BuildContext context, Marca marca, String token) async {
    try {
      String link = '${apiUrl}api/v1/marcas/${marca.marcaId.toString()}';
      var headers = {'Authorization': token};
      var xx = marca.toMap();
      final resp = await _dio.request(
        link,
        data: xx, 
        options: Options(
          method: 'PUT',
          headers: headers
        )
      );
      statusCode = 1;
      if (resp.statusCode == 200) {
        showDialogs(context, 'Marcó salida correctamente, que tenga un buen dia', false, false);
        print('funciono marcar salida');
      } else {
        showErrorDialog(context, 'Hubo un error al momento de marcar entrada');
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

  Future getUltimaMarca(BuildContext context, int tecnicoId, String token) async {
    String link = '${apiUrl}api/v1/tecnicos/$tecnicoId/ultimaMarca';
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
      late Marca marca;
      if(resp.data == null) {
        marca = Marca.empty();
        marca.tecnicoId = tecnicoId;
      } else {
        marca = Marca.fromJson(resp.data);
        if(marca.hasta != null) {
          marca = Marca.empty();
          marca.tecnicoId = tecnicoId;
        }
      }
      return marca;

    } catch (e) {
      statusCode = 0;
      if (e is DioException) {
        if (e.response != null) {
          final responseData = e.response!.data;
          if (responseData != null) {
            if(e.response!.statusCode == 403){
              showErrorDialog(context, 'Error: ${e.response!.data['message']}');
            }else{
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
          showErrorDialog(context, 'Error: ${e.message}');
        }
      }
    }
  }

}
