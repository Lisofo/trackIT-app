// ignore_for_file: avoid_print, void_checks

import 'package:app_tec_sedel/models/observacion.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
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
  final _revisionServices = RevisionServices();
  bool _isButtonEnabledObs = false;
  bool _isButtonEnabledCom = false;
  String _initialObs = '';
  String _initialCom = '';
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  int? statusCodeRevision;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  void _obsChanged() {
    setState(() {
      _isButtonEnabledObs = observacionController.text != _initialObs;
    });
  }

  void _comChanged() {
    setState(() {
      _isButtonEnabledCom = comentarioInternoController.text != _initialCom;
    });
  }



  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    try {
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      if(orden.otRevisionId != 0){
        observaciones = await _revisionServices.getObservacion(context, orden, token);
      }
      if (observaciones.isNotEmpty) {
        observacion = observaciones[0];
        cargoDatosCorrectamente = true;
      } else {
        observacion = Observacion.empty();
        cargoDatosCorrectamente = true;
      }
      cargando = false;
    } catch (e) {
      observacion = Observacion.empty();
      cargando = false;
    }
    
    print(observacion.otObservacionId);
    setState(() {
      observacionController.text = observacion.observacion;
      comentarioInternoController.text = observacion.comentarioInterno;
      _initialObs = observacion.observacion;
      _initialCom = observacion.comentarioInterno;
    });

    observacionController.addListener(_obsChanged);
    comentarioInternoController.addListener(_comChanged);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(
          '${orden.ordenTrabajoId} - Observaciones',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: colors.primary,
      ),
      body: cargando ? const Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text('Cargando, por favor espere...')
          ],
        ),
        ) : !cargoDatosCorrectamente ? 
        Center(
          child: TextButton.icon(
            onPressed: () async {
              await cargarDatos();
            }, 
            icon: const Icon(Icons.replay_outlined),
            label: const Text('Recargar'),
          ),
        ) : Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para el cliente:',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.primary, width: 2),
                      borderRadius: BorderRadius.circular(5),
                      // color: Colors.white
                    ),
                    child: TextFormField(
                      controller: observacionController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  const Text(
                    'Comentario interno:',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.primary, width: 2),
                      borderRadius: BorderRadius.circular(5),
                      // color: Colors.white
                    ),
                    child: TextFormField(                      
                      controller: comentarioInternoController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true
                      ),
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Align(
                    alignment: Alignment.center,
                    child: CustomButton(
                      onPressed: () async {
                        if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede de ingresar o editar datos.'),
                        ));
                        return Future.value(false);
                        }
                        if(_isButtonEnabledCom || _isButtonEnabledObs){
                          guardarObservaciones();
                        } else {
                          null;
                        }
                      },
                      text: 'Guardar',
                      tamano: 20,
                      disabled: !_isButtonEnabledCom && !_isButtonEnabledObs,
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
      await _revisionServices.postObservacion(context, orden, observacion, token);
      statusCodeRevision = await _revisionServices.getStatusCode();
      await _revisionServices.resetStatusCode();
    } else {
      await _revisionServices.putObservacion(context, orden, observacion, token);
      statusCodeRevision = await _revisionServices.getStatusCode();
      await _revisionServices.resetStatusCode();
    }
    if(statusCodeRevision == 1){
      setState(() {
        _initialObs = observacionController.text;
        _initialCom = comentarioInternoController.text;
        _isButtonEnabledCom = false;
        _isButtonEnabledObs = false;
      });  
    }
    statusCodeRevision = null;  
  }
}
