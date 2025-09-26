import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
class Carteles {
  
  static showDialogs(BuildContext context, String errorMessage, bool doblePop, bool triplePop, bool cuadruplePop) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
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
                if(cuadruplePop) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
    return true;
  }

  static void showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mensaje'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void errorManagment(Object e, BuildContext context) {
    if (e is DioException) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData != null) {
          if (e.response!.statusCode == 403) {
            Carteles.showErrorDialog(context, 'Error: ${e.response!.data['message']}');
          }else if (e.response!.statusCode! >= 500) {
            Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
          } else {
            final errors = responseData['errors'] as List<dynamic>;
            final errorMessages = errors.map((error) {
              return "Error: ${error['message']}";
            }).toList();
            Carteles.showErrorDialog(context, errorMessages.join('\n'));
          }
        } else {
          Carteles.showErrorDialog(context, 'Error: ${e.response!.data}');
        }
      } else {
        Carteles.showErrorDialog(context, 'Error: No se pudo completar la solicitud');
      }
    }
  }
  
}