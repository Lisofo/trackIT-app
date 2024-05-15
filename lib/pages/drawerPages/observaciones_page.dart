// ignore_for_file: avoid_print, void_checks

import 'package:app_track_it/models/observacion.dart';
import 'package:app_track_it/models/orden.dart';
import 'package:app_track_it/providers/orden_provider.dart';
import 'package:app_track_it/services/revision_services.dart';
import 'package:app_track_it/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ObservacionesPage extends StatefulWidget {
  const ObservacionesPage({super.key});

  @override
  State<ObservacionesPage> createState() => _ObservacionesPageState();
}

class _ObservacionesPageState extends State<ObservacionesPage> {
  final observacionController = TextEditingController();
  final comentarioInternoController = TextEditingController();
  late Observacion observacion = Observacion.empty();
  late Orden orden = Orden.empty();
  late String token = '';
  late List<Observacion> observaciones = [];
  late int marcaId = 0;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    orden = context.read<OrdenProvider>().orden;
    token = context.read<OrdenProvider>().token;
    marcaId = context.read<OrdenProvider>().marcaId;
    observaciones = await RevisionServices().getObservacion(orden, observacion, token);
    if (observaciones.isNotEmpty) {
      observacion = observaciones[0];
    } else {
      observacion = Observacion.empty();
    }
    print(observacion.otObservacionId);
    setState(() {
      observacionController.text = observacion.observacion;
      comentarioInternoController.text = observacion.comentarioInterno;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${orden.ordenTrabajoId} - Observaciones',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: colors.primary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary, width: 2),
                      borderRadius: BorderRadius.circular(5),
                      // color: Colors.white
                    ),
                    child: TextFormField(
                      controller: observacionController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          fillColor: Colors.white,
                          filled: true),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Comentario interno:',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary, width: 2),
                      borderRadius: BorderRadius.circular(5),
                      // color: Colors.white
                    ),
                    child: TextFormField(
                      controller: comentarioInternoController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          fillColor: Colors.white,
                          filled: true),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: CustomButton(
                      onPressed: () async {
                        if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede de ingresar o editar datos.'),
                        ));
                        return Future.value(false);
                      }
                        guardarObservaciones();
                      },
                      text: 'Guardar',
                      tamano: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  guardarObservaciones() async {
    observacion.comentarioInterno = comentarioInternoController.text;
    observacion.observacion = observacionController.text;
    observacion.obsRestringida = observacionController.text;

    if (observacion.otObservacionId == 0) {
      await RevisionServices().postObservacion(context, orden, observacion, token);
    } else {
      await RevisionServices().putObservacion(context, orden, observacion, token);
    }
  }
}
