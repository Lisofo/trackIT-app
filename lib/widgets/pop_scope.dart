// ignore_for_file: void_checks

import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          final shouldPop = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                surfaceTintColor: Colors.white,
                title: const Text('¿Deseas volver atrás?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: const Text('Sí'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('No'),
                  ),
                ],
              );
            },
          );
          return shouldPop ?? false;
        }
        return Future.value(
            true); // Permite el retroceso por defecto si no hay acciones personalizadas.
      },
      child: const Text('data'),
    );
  }
}
