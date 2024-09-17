// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/models/revision_tarea.dart';
import 'package:app_tec_sedel/models/ubicacion.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/services/ubicacion_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:flutter/cupertino.dart';
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

class OrdenInternaHorizontal extends StatefulWidget {
  const OrdenInternaHorizontal({super.key});

  @override
  State<OrdenInternaHorizontal> createState() => _OrdenInternaHorizontalState();
}

class _OrdenInternaHorizontalState extends State<OrdenInternaHorizontal> {
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
  late List<RevisionTarea> tareas = [];
  late List<RevisionMaterial> materiales = [];
  bool cambiarLista = true;
  int groupValue = 0;

  @override
  void initState() {
    super.initState();
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    token = context.read<OrdenProvider>().token;
    cargarDatos();
  }
  
  cargarDatos() async {
    if(orden.otRevisionId != 0) {
      tareas = await RevisionServices().getRevisionTareas(context, orden, token);
      materiales = await MaterialesServices().getRevisionMateriales(context, orden, token);
    }
    setState(() {
      
    });
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
            'Orden ${orden.ordenTrabajoId}: Servicio y distribucion 90.000KM',
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
              Container(
                color: colors.primary,
                child: Image.asset('images/banner.jpg')
              ),
              const SizedBox(
                height: 25,
              ),
              Expanded(child: _listaItems())
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cliente: ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${orden.cliente.codCliente} - ${orden.cliente.nombre} Telefono: ${orden.cliente.telefono1}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Fecha de la orden: ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaOrdenTrabajo),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text(
                                'Estado: ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                context.watch<OrdenProvider>().orden.estado,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const Text(
                            'Notas del cliente: ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.primary, width: 2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextFormField(
                              enabled: false,
                              minLines: 1,
                              maxLines: 10,
                              initialValue: 'Cheaquear luz de chequeo y luces',
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                          ),
                          const Text(
                            'Instrucciones: ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.primary, width: 2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextFormField(
                              enabled: false,
                              minLines: 1,
                              maxLines: 5,
                              initialValue: 'En el servicio anterior le hicieron distribucion, no fue en el taller.. se controlo con scaner por luz de fallo , ',
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20), 
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoSegmentedControl<int>(
                            padding: const EdgeInsets.all(10),
                            groupValue: groupValue,
                            borderColor: Colors.black,
                            selectedColor: colors.primary,
                            unselectedColor: Colors.white,
                            children: {
                              0: buildSegment('Tareas'),
                              1: buildSegment('Materiales'),
                            },
                            onValueChanged: (newValue) {
                              groupValue = newValue;
                              cambiarLista = groupValue == 0 ? true : false;
                              setState(() {});
                            },
                          ),
                          if(cambiarLista)...[
                            Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.5,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: colors.onPrimary,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(right: 8),
                                                child: Text('Codigo'),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.only(right: 8),
                                                child: Text('Descripcion',),
                                              ),
                                              Text(''),
                                            ],
                                          ),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Table(
                                              columnWidths: const <int, TableColumnWidth> {
                                                0: IntrinsicColumnWidth(flex: 1),
                                                1: IntrinsicColumnWidth(flex: 4),
                                                2: IntrinsicColumnWidth(flex: 2),
                                                3: IntrinsicColumnWidth(flex: 1),
                                              },
                                              children: [
                                                for(var tarea in tareas)...[
                                                  TableRow(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Text(tarea.codTarea, textAlign: TextAlign.center,),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Text(tarea.descripcion),
                                                      ),
                                                      const Text('Comentario'),
                                                      const Text('Avance'),
                                                    ]
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Material(
                                        elevation: 0,
                                        child: Container(
                                          color: colors.onPrimary,
                                          child: Table(
                                            columnWidths: const <int, TableColumnWidth>{
                                              0: IntrinsicColumnWidth(flex: 1),
                                              1: IntrinsicColumnWidth(flex: 4),
                                              2: IntrinsicColumnWidth(flex: 2),
                                              3: FlexColumnWidth(1),
                                            },
                                            children: const [
                                              TableRow(
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(right: 8),
                                                    child: Text('Codigo', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(right: 8),
                                                    child: Text('Descripcion', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(right: 8),
                                                    child: Text('Comentario', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.only(right: 8),
                                                    child: Text('Avance', style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            )
                          ] else...[
                            Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.height * 0.5,
                              decoration: BoxDecoration(
                                color: colors.onPrimary,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(5)
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  child: Table(
                                    columnWidths: const <int, TableColumnWidth> {
                                      0 : FlexColumnWidth(),
                                      1 : FlexColumnWidth(11)
                                    },
                                    children: [
                                      for(var material in materiales)...[
                                        TableRow(
                                          children: [
                                            Text(material.material.codMaterial, textAlign: TextAlign.center,),
                                            Text(material.material.descripcion),
                                          ]
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                              )
                              
                            )
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20,),
                 
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
    final String tipoOrden = orden.tipoOrden.codTipoOrden;
    return FutureBuilder(
      future: menuProvider.cargarData(context, tipoOrden, token),
      initialData: const [],
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        } else if(snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        } else {
          final List<Ruta> rutas = snapshot.data as List<Ruta>;

          return ListView.separated(
            itemCount: rutas.length,
            itemBuilder: (context, i) {
              final Ruta ruta = rutas[i];
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
        int uId = context.read<OrdenProvider>().uId;
        String token = context.read<OrdenProvider>().token;
        await _ordenServices.patchOrden(context, orden, estado, ubicacionId, token);
        statusCode = await _ordenServices.getStatusCode();
        await _ordenServices.resetStatusCode();
        if (statusCode == 1) {
          if (estado == 'EN PROCESO') {
            await _revisionServices.postRevision(context, uId, orden, token);
            statusCode = await _revisionServices.getStatusCode();
            await _revisionServices.resetStatusCode();
            if (statusCode == 1) {
              await OrdenServices.showDialogs(context, 'Estado cambiado correctamente', false, false);
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
    int uId = context.read<OrdenProvider>().uId;
    ubicacion.fecha = DateTime.now();
    ubicacion.usuarioId = uId;
    ubicacion.ubicacion = _currentPosition;
    String token = context.read<OrdenProvider>().token;
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
                      await OrdenServices.showDialogs(context, 'Estado cambiado a Pendiente', true, true);
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

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

}
