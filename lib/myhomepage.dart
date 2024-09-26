

import 'package:flutter/material.dart';
  class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<bool> _onWillPop() async {
    // Aquí puedes mostrar un diálogo de confirmación si lo deseas
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('¿Estás seguro?'),
            content: Text('¿Quieres salir de la aplicación?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // No salir
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Salir
                child: Text('Sí'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ejemplo de WillPopScope'),
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: Center(
          child: Text('Presiona el botón de retroceso.'),
        ),
      ),
    );
  }
}