// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/models/ubicacion.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/services/ubicacion_services.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/menu_providers.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/widgets/icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdenInternaVertical extends StatefulWidget {
  const OrdenInternaVertical({super.key});

  @override
  State<OrdenInternaVertical> createState() => _OrdenInternaVerticalState();
}

class _OrdenInternaVerticalState extends State<OrdenInternaVertical> {
  late Orden orden;
  late int marcaId = 0;
  late String _currentPosition = '';
  late Ubicacion ubicacion = Ubicacion.empty();
  bool ejecutando = false;
  String token = '';
  final _ubicacionServices = UbicacionServices();
  final _ordenServices = OrdenServices();
  final _revisionServices = RevisionServices();
  int? statusCode;
  final TextEditingController pinController = TextEditingController();
  bool pedirConfirmacion = true;
  bool isObscured = true;
  

  @override
  void initState() {
    super.initState();
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    token = context.read<AuthProvider>().token;
  }

  void _mostrarDialogoConfirmacion(String accion) {
    pinController.text = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) {
            return AlertDialog(
              surfaceTintColor: Colors.white,
              title: const Text('Confirmación'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¿Estás seguro que deseas $accion la orden?'),
                  if(pedirConfirmacion)...[
                    const SizedBox(height: 5,),
                    CustomTextFormField(
                      preffixIcon: const Icon(Icons.lock),
                      keyboard: const TextInputType.numberWithOptions(),
                      controller: pinController,
                      hint: 'Ingrese PIN',
                      maxLines: 1,
                      obscure: isObscured,
                      suffixIcon: IconButton(
                        icon: isObscured
                            ? const Icon(
                                Icons.visibility_off,
                                color: Colors.black,
                              )
                            : const Icon(
                                Icons.visibility,
                                color: Colors.black,
                              ),
                        onPressed: () {
                          setStateBd(() {
                            isObscured = !isObscured;
                          });
                        },
                      ),
                    )
                  ]
                ],
              ),
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
                        cambiarEstado('EN PROCESO');
                      } else {
                        cambiarEstado('FINALIZADA');
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
      },
    );
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
            'Orden ${orden.ordenTrabajoId}',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new),
              color: Colors.white,
            )
          ],
        ),
        drawer: Drawer(
          surfaceTintColor: Colors.white,
          child: Column(
            children: [
              // Container(
              //   color: colors.primary,
              //   child: Image.asset('images/banner.jpg')
              // ),
              // const SizedBox(
              //   height: 25,
              // ),
              Expanded(child: _listaItems())
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(5)),
                  height: 30,
                  child: const Center(
                    child: Text(
                      'Detalle',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Nombre del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  orden.cliente!.nombre,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Código del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  orden.cliente!.codCliente,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Fecha de la orden: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('EEEE d, MMMM yyyy', 'es').format(orden.fechaOrdenTrabajo ?? DateTime.now()),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    const Text(
                      'Direccion del cliente: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    IconButton(onPressed: (){
                      _launchMaps(orden.cliente?.coordenadas);
                    }, icon: Icon(Icons.person_pin, color: colors.primary))
                  ],
                ),
                Text(
                  orden.cliente!.direccion,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Telefono del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  orden.cliente!.telefono1,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    const Text(
                      'Estado: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      context.watch<OrdenProvider>().orden.estado.toString(),
                      style: const TextStyle(fontSize: 16),
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    const Text(
                      'Tipo de Orden: ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(orden.tipoOrden!.descripcion.toString(),
                        style: const TextStyle(fontSize: 16))
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Servicios: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                for (var i = 0; i < orden.servicio!.length; i++) ...[
                  Text(
                    orden.servicio![i].descripcion,
                    style: const TextStyle(fontSize: 16),
                  )
                ],
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Notas del cliente: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary,
                          width: 2),
                      borderRadius: BorderRadius.circular(5)),
                  child: TextFormField(
                    enabled: false,
                    minLines: 1,
                    maxLines: 100,
                    initialValue: orden.cliente?.notas,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  'Instrucciones: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary,
                          width: 2),
                      borderRadius: BorderRadius.circular(5)),
                  child: TextFormField(
                    enabled: false,
                    minLines: 1,
                    maxLines: 100,
                    initialValue: orden.instrucciones,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                  ),
                ),
                const SizedBox(
                  height: 15,
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
                onPressed: ((marcaId != 0 && orden.estado != 'EN PROCESO') || !ejecutando ) ? () => _mostrarDialogoConfirmacion('iniciar') : null,
                text: 'Iniciar',
                tamano: 18,
                disabled: (!(marcaId != 0 && orden.estado == 'PENDIENTE') || ejecutando),
              ),
              CustomButton(
                clip: Clip.antiAlias,
                onPressed: marcaId != 0 && orden.estado == 'EN PROCESO' ? () => router.push('/resumenOrden') : null, /*_mostrarDialogoConfirmacion('finalizar')*/ 
                text: 'Finalizar',
                tamano: 18,
                disabled: !(marcaId != 0 && orden.estado == 'EN PROCESO'),
              ),
              IconButton(
                onPressed: marcaId != 0 && orden.estado == 'EN PROCESO' ? () => volverAPendiente(orden) : null,
                icon: Icon(Icons.backspace,
                  color: marcaId != 0 && orden.estado == 'EN PROCESO' ? colors.primary : Colors.grey
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaItems() {
    final colors = Theme.of(context).colorScheme;
    final String? tipoOrden = orden.tipoOrden!.codTipoOrden;
    return FutureBuilder(
      future: menuProvider.cargarData(context, tipoOrden!, token),
      initialData: const [],
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        } else if(snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        } else {
          final List<Opcion> rutas = snapshot.data as List<Opcion>;

          return ListView.separated(
            itemCount: rutas.length,
            itemBuilder: (context, i) {
              final Opcion ruta = rutas[i];
              return ListTile(
                title: Text(ruta.texto),
                leading: getIcon(ruta.icon, context),
                trailing: Icon(
                  Icons.keyboard_arrow_right,
                  color: colors.secondary,
                ),
                onTap: () {
                  router.push(ruta.ruta);
                } 
              );
            }, 
            separatorBuilder: (BuildContext context, int index) { return const Divider(); },
          ); 
        }
      },
    );
  }

  cambiarEstado(String estado) async {
    if (!ejecutando) {
      ejecutando = true;
      await obtenerUbicacion();
      if (statusCode == 1){
        int ubicacionId = ubicacion.ubicacionId;
        int uId = context.read<AuthProvider>().uId;
        String token = context.read<AuthProvider>().token;
        await _ordenServices.patchOrden(context, orden, estado, ubicacionId, token);
        statusCode = await _ordenServices.getStatusCode();
        await _ordenServices.resetStatusCode();
        if (statusCode == 1) {
          if (estado == 'EN PROCESO') {
            await _revisionServices.postRevision(context, uId, orden, token);
            statusCode = await _revisionServices.getStatusCode();
            await _revisionServices.resetStatusCode();
            if (statusCode == 1) {
              await Carteles.showDialogs(context, 'Estado cambiado correctamente', false, false, false);
            }
          }
          
        }
      }
      ejecutando = false;
      statusCode = null;
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

  Future<void> volverAPendiente(Orden orden) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('ADVERTENCIA'),
          content: Text(
            'Todos los datos que hubiera cargado para esta Orden se perderan, Desea pasar a PENDIENTE la Orden ${orden.ordenTrabajoId}?',
            style: const TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () => GoRouter.of(context).pop(),
              child: const Text('Cancelar')
            ),
            TextButton(
              onPressed: () async {
                if (!ejecutando) {
                  ejecutando = true;
                  await obtenerUbicacion();
                  if (statusCode == 1){
                    int ubicacionId = ubicacion.ubicacionId;
                    await _ordenServices.patchOrden(context, orden, 'PENDIENTE', ubicacionId, token);
                    statusCode = await _ordenServices.getStatusCode();
                    await _ordenServices.resetStatusCode();
                    if (statusCode == 1){
                      await Carteles.showDialogs(context, 'Estado cambiado a Pendiente', true, true, false);
                    }
                  }
                }
                ejecutando = false;
                statusCode = null;
                setState(() {});
              },
              child: const Text('Confirmar')
            )
          ],
        );
      }
    );
  }

   _launchMaps(String coordenadas) async {
    // Coordenadas a abrir en el mapa
    var coords = coordenadas.split(',');
    String latitude = coords[0]; // Latitud de ejemplo
    String longitude = coords[1]; // Longitud de ejemplo

    // URI con las coordenadas
    final Uri toLaunch = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: 'maps/search/',
        query: 'api=1&query=$latitude,$longitude');

    if (await launchUrl(toLaunch)) {
    } else {
      throw 'No se pudo abrir la url';
    }
  }

}
