// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/models/ubicacion.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/revision_services.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:app_tec_sedel/services/ubicacion_services.dart';
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

class OrdenInternaHorizontal extends StatefulWidget {
  const OrdenInternaHorizontal({super.key});

  @override
  State<OrdenInternaHorizontal> createState() => _OrdenInternaHorizontalState();
}

class _OrdenInternaHorizontalState extends State<OrdenInternaHorizontal> with TickerProviderStateMixin{
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
  late List<Linea> tareas = [];
  late List<Linea> materiales = [];
  bool cambiarLista = true;
  int groupValue = 0;
  int buttonIndex = 0;
  int? selectedTaskIndex;
  final ordenServices = OrdenServices();


  late TabController tabBarController;

  @override
  void initState() {
    super.initState();
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    token = context.read<OrdenProvider>().token;
    tabBarController = TabController(length: 3, vsync: this);
    tabBarController.addListener(handleTabSelection);
    cargarDatos();
  }

  void handleTabSelection() {
    if (tabBarController.indexIsChanging) {
      print('Tab ${tabBarController.index} is being selected');
    }
  }

  @override
  void dispose() {
    tabBarController.removeListener(handleTabSelection);
    tabBarController.dispose();
    super.dispose();
  }

  
  
  cargarDatos() async {
    tareas = await TareasServices().getMO(context, orden, token);
    materiales = await MaterialesServices().getRepuestos(context, orden, token);
    setState(() {});
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



    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text(
            'Orden ${orden.numeroOrdenTrabajo} ${orden.descripcion} ',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: screenWidth,
                  child: TabBar(
                    labelColor: Colors.white,
                    indicator: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                      color: Colors.cyan,
                    ),
                    dividerColor: Colors.cyan,
                    indicatorSize: TabBarIndicatorSize.tab,
                    controller: tabBarController,
                    tabs: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.description),
                          SizedBox(width: 10,),
                          Tab(child: Text('Datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_bulleted_outlined),
                          SizedBox(width: 10,),
                          Tab(child: Text('Tareas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_bulleted_outlined),
                          SizedBox(width: 10,),
                          Tab(child: Text('Materiales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth,
                  height: screenHeight * 0.7,
                  child: TabBarView(
                    controller: tabBarController,
                    children: [
                      Card(
                        elevation: 10,
                        
                        child: Column(
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: screenWidth * 0.4,
                                  height: (screenWidth > screenHeight) ? screenHeight * 0.12 : screenHeight * 0.08,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Cliente: ',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                        Center(
                                          child: Text(
                                            '${orden.cliente.codCliente} - ${orden.cliente.nombre}',
                                            style: const TextStyle(fontSize: 18),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            'Telefono: ${orden.cliente.telefono1}',
                                            style: const TextStyle(fontSize: 18),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Padding(
                              padding: (screenWidth > screenHeight) ? const EdgeInsets.fromLTRB(0,20,0,0) : const EdgeInsets.fromLTRB(0,25,0,0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: screenWidth * 0.4,
                                        height: screenHeight * 0.11,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: colors.primary, width: 2),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          //crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Center(
                                              child: Text(
                                                'Estado: ',
                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Text(
                                                context.watch<OrdenProvider>().orden.estado,
                                                style: const TextStyle(fontSize: 18,),
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ), 
                                      const SizedBox(height: 10,),
                                      Container(
                                        width: screenWidth * 0.4,
                                        height: screenHeight * 0.11,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: colors.primary, width: 2),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Center(
                                              child: Text(
                                                'Fecha de la orden: ',
                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Text(
                                                DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaOrdenTrabajo),
                                                style: const TextStyle(fontSize: 18),
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),     
                                      Container(
                                        width: screenWidth * 0.4,
                                        height: screenHeight * 0.11,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: colors.primary, width: 2),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Center(
                                              child: Text(
                                                'Fecha de Vencimiento: ',
                                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Text(
                                                DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaVencimiento),
                                                style: const TextStyle(fontSize: 18),
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (orden.fechaEntrega != null) ... [
                                        Container(
                                          width: screenWidth * 0.4,
                                          height: screenHeight * 0.11,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: colors.primary, width: 2),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Center(
                                                child: Text(
                                                  'Fecha de Entrega: ',
                                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(6.0),
                                                child: Text(
                                                  DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaEntrega!),
                                                  style: const TextStyle(fontSize: 18),
                                                  textAlign: TextAlign.start,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],      
                                    ],
                                  ),
                                  Column(
                                    //mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      
                                      Container(
                                        width: screenWidth * 0.4,
                                        height: screenHeight * 0.2,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: colors.primary, width: 2),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Notas del cliente: ',
                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                            ),
                                            TextFormField(
                                              enabled: false,
                                              minLines: 3,
                                              maxLines: 20,
                                              initialValue: 'Cheaquear luz de chequeo y luces',
                                              style: const TextStyle(color: Colors.black),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                fillColor: Colors.white,
                                                filled: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10,),
                                      Container(
                                        width: screenWidth * 0.4,
                                        height: screenHeight * 0.2,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: colors.primary, width: 2),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Instrucciones: ',
                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                            ),
                                            TextFormField(
                                              enabled: false,
                                              minLines: 3,
                                              maxLines: 20,
                                              style: const TextStyle(color: Colors.black),
                                              initialValue: 'En el servicio anterior le hicieron distribucion, no fue en el taller.. se controlo con scaner por luz de fallo , ',
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                fillColor: Colors.white,
                                                filled: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.6,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: colors.onPrimary,
                        ),
                        child: Column(
                          children: [
                            // Fixed header
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                border: const Border(bottom: BorderSide(color: Colors.grey)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderCell('Codigo', flex: 1),
                                  _buildHeaderCell('Descripcion', flex: 3),
                                  _buildHeaderCell('Comentario', flex: 1),
                                  _buildHeaderCell('Avance', flex: 1),
                                  IconButton(onPressed: null, icon: Icon(Icons.play_arrow,color: Colors.grey[400],)),
                                  IconButton(onPressed: null, icon: Icon(Icons.play_arrow,color: Colors.grey[400],)),
                                ],
                              ),
                            ),
                            // Scrollable content
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: tareas.asMap().entries.map((entry) => 
                                    _buildDataRow(entry.value, context, entry.key)
                                  ).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.6,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: colors.onPrimary,
                        ),
                        child: Column(
                          children: [
                            // Fixed header
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                border: const Border(bottom: BorderSide(color: Colors.grey)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  _buildHeaderCell('Codigo', flex: 1),
                                  _buildHeaderCell('Descripcion', flex: 3),
                                  _buildHeaderCell('Comentario', flex: 1),
                                  _buildHeaderCell('Cantidad', flex: 1),
                                ],
                              ),
                            ),
                            // Scrollable content
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: materiales.asMap().entries.map((entry) => 
                                    _buildDataRow(entry.value, context, entry.key)
                                  ).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ),
                ),
                
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.primary,
                  width: 1,
                ),
              ),
            ),
          child: BottomNavigationBar(
            currentIndex: buttonIndex,
            onTap: (index) {
              setState(() {
                buttonIndex = index;
                switch (buttonIndex){
                  case 0: 
                    if ((marcaId != 0 && orden.estado != 'EN PROCESO') || !ejecutando){
                      _mostrarDialogoConfirmacion('iniciar');
                    } else {
                      null;
                    }
                  break;
                  case 1:
                    if (marcaId != 0 && orden.estado == 'EN PROCESO'){
                      router.push('/resumenOrden');
                    } else {
                      null;
                    }
                  break;
                  case 2:
                    if (marcaId != 0 && orden.estado == 'EN PROCESO'){
                      volverAPendiente(orden);
                    } else {
                      null;
                    }  
                  break;
                }
              });
            },
            showUnselectedLabels: true,
          
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.primary,  
            items: const [
              BottomNavigationBarItem(
                
                icon: Icon(Icons.play_circle_outline),
                label: 'Iniciar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.stop_circle_outlined),
                label: 'Finalizar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.backspace_outlined),
                label: 'Volver a Pendiente',
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


  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: text != 'Codigo' ? Alignment.centerLeft : Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataRow(dynamic objeto, BuildContext context, int index) {
    final isSelected = index == selectedTaskIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTaskIndex = isSelected ? null : index; 
        });
      },
      onDoubleTap: () {
        if(objeto is Linea) {
          if (objeto.mo == 'MO'){
            setState(() {
              selectedTaskIndex = isSelected ? null : index; 
            });
            comenzarTarea(context, index);
          }
        }
        
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : null,
          border: const Border(bottom: BorderSide(color: Colors.grey)),      
        ),
        child: Row(
          children: [
            if(objeto is Linea)...[
              _buildDataCell(objeto.codItem, flex: 1, alignment: Alignment.center),
              _buildDataCell(objeto.descripcion, flex: 3, alignment: Alignment.centerLeft),
              _buildDataCell(objeto.comentario, flex: 1, alignment: Alignment.centerLeft),
              _buildDataCell(objeto.mo == 'MO' ? objeto.getAvanceEnHorasMinutos() : objeto.cantidad.toString() , flex: 1, alignment: Alignment.centerLeft),
              if(objeto.mo == 'MO')...[
                IconButton(
                  onPressed: (){
                    if (objeto.mo == 'MO'){
                      setState(() {
                        selectedTaskIndex = isSelected ? null : index; 
                      });
                      comenzarTarea(context, index);
                    }
                  }, icon: const Icon(Icons.play_arrow)
                ),
                IconButton(
                  onPressed: (){
                    if (objeto.mo == 'MO'){
                      setState(() {
                        selectedTaskIndex = isSelected ? null : index; 
                      });
                      comenzarTarea(context, index);
                    }
                  }, icon: const Icon(Icons.stop_circle_outlined)
                )
              ]
              
            ] 
            // else if(objeto is RevisionMaterial) ... [
              // _buildDataCell(objeto.material.codMaterial, flex: 1, alignment: Alignment.center),
              // _buildDataCell(objeto.material.descripcion, flex: 3, alignment: Alignment.centerLeft),
              // _buildDataCell('Comentario', flex: 1, alignment: Alignment.centerLeft),
              // _buildDataCell('Avance', flex: 1, alignment: Alignment.centerLeft),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {required int flex, required Alignment alignment}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: alignment,
        child: Text(
          style: const TextStyle(fontSize: 18),
          text,
          textAlign: alignment == Alignment.center ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }

  void comenzarTarea(BuildContext context, int i) {
    late int? statusCode;
    pinController.text = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: const Text("Confirmar"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("¿Comienza a trabajar en la tarea ${tareas[i].descripcion}?"),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCELAR"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () async {
                  await ordenServices.iniciarTrabajo(context, orden, tareas[i].lineaId, token);
                  statusCode = await ordenServices.getStatusCode();
                  await ordenServices.resetStatusCode();
                  if(statusCode == 1){
                    MenuServices.showDialogs2(context, 'Tarea comenzada', true, false, false, false);
                  }
                }, 
                child: const Text("COMENZAR")
              ),
            ],
          ),
        );
      }
    );
  }

}
