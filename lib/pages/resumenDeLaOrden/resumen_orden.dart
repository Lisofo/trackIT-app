import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/clientes_firmas.dart';
import 'package:app_tec_sedel/models/observacion.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_incidencia.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/models/revision_plaga.dart';
import 'package:app_tec_sedel/models/revision_pto_inspeccion.dart';
import 'package:app_tec_sedel/models/revision_tarea.dart';
import 'package:app_tec_sedel/models/ubicacion.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/incidencia_services.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/ptos_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/services/ubicacion_services.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/visualizar_accion.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ResumenOrden extends StatefulWidget {
  const ResumenOrden({super.key});

  @override
  State<ResumenOrden> createState() => _ResumenOrdenState();
}

class _ResumenOrdenState extends State<ResumenOrden> {
  late Orden orden;
  late Orden ordenConGarantia = Orden.empty();
  late int marcaId = 0;
  late String _currentPosition = '';
  late Ubicacion ubicacion = Ubicacion.empty();
  bool ejecutando = false;
  String token = '';
  late List<RevisionTarea> tareas = [];
  late List<RevisionMaterial> materiales = [];
  late List<RevisionPlaga> plagas = [];
  late List<Observacion> observaciones = [];
  late List<RevisionIncidencia> incidencias = [];
  late Observacion observacion = Observacion.empty();
  List<ClienteFirma> firmas = [];
  late String? firmaDisponible = ''; 
  List<RevisionPtoInspeccion> ptosInspeccion = [];
  bool faltanCompletarPtos = false;
  bool yaCargo = false;
  final _ordenServices = OrdenServices();
  final _ubicacionServices = UbicacionServices();
  late int? statusCode = 0;
  bool resumenPlagas = false;
  bool resumenPtoInspeccion = false;
  late String siguienteEstado = '';
  final ordenServices = OrdenServices();
  final _revisionServices = RevisionServices();
  bool get puedeFinalizar {
    if (ordenConGarantia.sinGarantia == 'N' || ordenConGarantia.sinGarantia == null) {
      return true;
    } else {
      return false;
    }
  }
  
  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    orden = context.read<OrdenProvider>().orden;
    ordenConGarantia = await OrdenServices().getOrdenPorId(context, orden.ordenTrabajoId, token);
    marcaId = context.read<OrdenProvider>().marcaId;
    if(orden.tipoOrden?.codTipoOrden == 'N'){
      ptosInspeccion = await PtosInspeccionServices().getPtosInspeccion(context, orden, token);
      faltanCompletarPtos = ptosInspeccion.any((pto)=> pto.otPuntoInspeccionId == 0);
      plagas = await RevisionServices().getRevisionPlagas(context, orden, token);
    } else if(orden.tipoOrden?.codTipoOrden == 'N' || orden.tipoOrden?.codTipoOrden == 'D') {
      materiales = await MaterialesServices().getRevisionMateriales(context, orden, token);
      plagas = await RevisionServices().getRevisionPlagas(context, orden, token);
    }
    tareas = await RevisionServices().getRevisionTareas(context, orden, token);
    materiales = await MaterialesServices().getRevisionMateriales(context, orden, token);
    observaciones = await RevisionServices().getObservacion(context, orden, token);
    incidencias = await IncidenciaServices().getRevisionIncidencia(context, orden, token);
    if (observaciones.isNotEmpty) {
      observacion = observaciones[0];
    } else {
      observacion = Observacion.empty();
    } 
    firmas = await RevisionServices().getRevisionFirmas(context, orden, token);
    firmaDisponible = await RevisionServices().getRevision(context, orden, token);
    yaCargo = true;
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text(
            '${orden.ordenTrabajoId} - Resumen',
            style: const TextStyle(color: Colors.white),
          ),
          automaticallyImplyLeading: false,
        ),
        body: 
        !yaCargo ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10,),
              Text('Generando resumen')
            ],
          ),
        ) :
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if(orden.tipoOrden?.codTipoOrden == 'N')...[
                  if(resumenPtoInspeccion)...[
                    const ContainerTituloPIRevision(titulo: 'Puntos de inspección'),
                    const SizedBox(height: 10,),
                    Text(
                      faltanCompletarPtos ? 'Faltan completar Puntos de inspección' : 'Puntos de inspección: OK', 
                      style: const TextStyle(
                        fontSize: 18
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
                if(orden.tipoOrden?.codTipoOrden == 'N' || orden.tipoOrden?.codTipoOrden == 'D')...[
                  if(resumenPlagas)...[
                    const ContainerTituloPIRevision(titulo: 'Plagas'),
                    const SizedBox(height: 10,),
                    Text(
                      plagas.isEmpty ? 'No registró plagas' : 'OK', 
                      style: const TextStyle(
                        fontSize: 18
                      ),
                    ),
                    const SizedBox(height: 10,),
                  ],
                ],
                const ContainerTituloPIRevision(titulo: 'Tareas'),
                const SizedBox(height: 10,),
                Text(
                  tareas.isEmpty ? 'No registró tareas' : 'OK', 
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
                const SizedBox(height: 10,),
                const ContainerTituloPIRevision(titulo: 'Materiales'),
                const SizedBox(height: 10,),
                Text(
                  materiales.isEmpty ? 'No registró materiales' : 'OK', 
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
                const SizedBox(height: 10,),
                const ContainerTituloPIRevision(titulo: 'Observaciones'),
                const SizedBox(height: 10,),
                Text(
                  observaciones.isEmpty ? 'No registró observación' : 'OK', 
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
                const SizedBox(height: 10,),
                const ContainerTituloPIRevision(titulo: 'Firmas'),
                const SizedBox(height: 10,),
                Text(
                  (firmas.isEmpty && firmaDisponible != 'N') ? 'No registró firmas' : firmaDisponible == 'N' ? 'Cliente no disponible' : 'OK', 
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
                const SizedBox(height: 10,),
                const ContainerTituloPIRevision(titulo: 'Incidencias'),
                Text(
                  incidencias.isEmpty ? 'No registró incidencias' : 'OK',
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 10,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          color: Colors.grey.shade200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(
                clip: Clip.antiAlias,
                onPressed: () {router.pop();},
                text: 'Cancelar',
                tamano: 18,
                disabled: !yaCargo,
              ),
              CustomButton(
                clip: Clip.antiAlias,
                onPressed: ((orden.estado == 'EN PROCESO' || orden.estado == 'RECIBIDO') && puedeFinalizar) ? () => _mostrarDialogoConfirmacion('finalizar') : null,
                text: 'Finalizar',
                tamano: 18,
                disabled: !yaCargo && !puedeFinalizar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoConfirmacion(String accion) async {
    late int accionId = accion == "recibir" ? 21 : 18;
    siguienteEstado = await ordenServices.siguienteEstadoOrden(context, orden, accionId, token);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Confirmación'),
          content: Text('¿Estás seguro que deseas $accion la orden?'),
          actions: [
            TextButton(
              onPressed: () {
                router.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (accion == 'iniciar') {
                    cambiarEstado(accionId);
                  } else {
                    cambiarEstado(accionId);
                  }
                });
                router.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  cambiarEstado(int accionId) async {
    if (!ejecutando) {
      ejecutando = true;
      await obtenerUbicacion();
      if(statusCode == 1) {
        int ubicacionId = ubicacion.ubicacionId;
        // ignore: unused_local_variable
        int uId = context.read<AuthProvider>().uId;
        String token = context.read<AuthProvider>().token;
        orden.otRevisionId = await _ordenServices.patchOrdenCambioEstado(context, orden, accionId, ubicacionId, token);
        statusCode = await _ordenServices.getStatusCode();
        await _ordenServices.resetStatusCode();
        if (statusCode == 1) {
          if (accionId == 18) {
            // await _revisionServices.postRevision(context, uId, orden, token);
            statusCode = await _revisionServices.getStatusCode();
            await _revisionServices.resetStatusCode();
            // if (statusCode == 1) {
              orden.estado == siguienteEstado;
              await Carteles.showDialogs(context, 'Estado cambiado correctamente', true, false, false);
            // }
          }
        }
      }
      statusCode = null;
      ejecutando = false;
      setState(() {});
    }
  }

  obtenerUbicacion() async {
    await getLocation();
    int uId = context.read<AuthProvider>().uId;
    ubicacion.fecha = DateTime.now();
    ubicacion.usuarioId = uId;
    ubicacion.ubicacion = _currentPosition;
    String token = context.read<AuthProvider>().token;
    await _ubicacionServices.postUbicacion(context, ubicacion, token);
    statusCode = await _ubicacionServices.getStatusCode();
    await _ubicacionServices.resetStatusCode();
  }

  Future<void> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = '${position.latitude}, ${position.longitude}';
        print('${position.latitude}, ${position.longitude}');
      });
    } catch (e) {
      setState(() {
        _currentPosition = 'Error al obtener la ubicación: $e';
      });
    }
  }

}