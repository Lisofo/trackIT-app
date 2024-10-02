// ignore_for_file: use_build_context_synchronously, avoid_print, unused_element
import 'package:app_tec_sedel/models/control.dart';
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/models/ubicacion.dart';
import 'package:app_tec_sedel/providers/menu_services.dart';
import 'package:app_tec_sedel/services/control_services.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
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
  final TextEditingController notasController = TextEditingController();
  final TextEditingController instruccionesController = TextEditingController();
  final TextEditingController comentarioController = TextEditingController();
  final TextEditingController kmController = TextEditingController();
  late List<Control> controles = [];
  List<String> grupos = [];
  List<String> models = [];
  late List<Control> controlesConformidad = [];
  late List<Control> controlesDeNivel = [];
  late List<Control> controlesSeguridad = [];
  late List<Control> controlesSeVi = [];
  Map<String, String?> valores = {};
  Map<String, Color> colores = {};
  bool isMobile = false;
  double heightMultiplierCliente = 0.13;
  late String siguienteEstado = '';
  // Función para manejar el cambio de valor y color
  void actualizarValor(String concepto, Control control, String valor, Color color) {
    setState(() {
      control.respuesta = valor;
      colores[concepto] = color;
    });
  }
  bool cargando = false;

  Map<String, List<Control>> controlesPorGrupo = {};
  late TabController tabBarController;
  late TabController tabBarController2 = TabController(length: 0, vsync: this);
  late int cantidadDeGruposControles = 0;

  @override
  void initState() {
    super.initState();
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    token = context.read<OrdenProvider>().token;
    tabBarController = TabController(length: 4, vsync: this);
    tabBarController.addListener(handleTabSelection);
    tabBarController2.addListener(handleTabSelection2);
    cargarDatos();
    
  }

  void handleTabSelection() {
    if (tabBarController.indexIsChanging) {
      FocusScope.of(context).unfocus();
      print('Tab ${tabBarController.index} is being selected');
    }
  }
  void handleTabSelection2() {
    if (tabBarController2.indexIsChanging) {
      FocusScope.of(context).unfocus();
      print('Tab ${tabBarController2.index} is being selected');
    }
  }

  @override
  void dispose() {
    tabBarController.removeListener(handleTabSelection);
    tabBarController2.removeListener(handleTabSelection2);
    tabBarController.dispose();
    tabBarController2.dispose();
    notasController.dispose();
    instruccionesController.dispose();
    kmController.dispose();
    super.dispose();
  }

  // Función para limpiar el valor y el color
  void limpiarValor(String concepto) {
    setState(() {
      valores[concepto] = null;
      colores[concepto] = Colors.white; // Restablece el color por defecto
    });
  }
  
  cargarDatos() async {
    cargando = true;
    setState(() {});
    tareas = await TareasServices().getMO(context, orden, token);
    materiales = await MaterialesServices().getRepuestos(context, orden, token);
    notasController.text = orden.comentarioCliente;
    instruccionesController.text = orden.comentarioTrabajo;
    kmController.text = orden.km.toString();
    controles = await OrdenServices().getControles2(context, orden.ordenTrabajoId, token);
    controles.sort((a, b) => a.pregunta.compareTo(b.pregunta));
    for(var i = 0; i < controles.length; i++){
      models.add(controles[i].grupo);
    }
    Set<String> conjunto = Set.from(models);
    grupos = conjunto.toList();
    grupos.sort((a, b) => a.compareTo(b));
    cantidadDeGruposControles = grupos.length;
    cargarListas();
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    isMobile = shortestSide < 600;
    if (isMobile) {
      heightMultiplierCliente = 0.18;
    }
    tabBarController2 = TabController(length: cantidadDeGruposControles + 1, vsync: this);
    cargando = false;
    setState(() {});
  }

  void cargarListas() {
  controlesPorGrupo.clear();
  for (var control in controles) {
    String grupoLower = control.grupo.toLowerCase();
    if (!controlesPorGrupo.containsKey(grupoLower)) {
      controlesPorGrupo[grupoLower] = [];
    }
    controlesPorGrupo[grupoLower]?.add(control);
  }
}

  void _mostrarDialogoConfirmacion(String accion) async {
    pinController.text = '';
    late int accionId = accion == "recibir" ? 21 : 18;
    siguienteEstado = await ordenServices.siguienteEstadoOrden(context, orden, accionId, token);
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) {
            return AlertDialog(
              surfaceTintColor: Colors.white,
              title: const Text('Confirmación'),
              content: Text('¿Estás seguro que deseas pasar la OT al estado $siguienteEstado?'),
              actions: [
                TextButton(
                  onPressed: () {
                    router.pop(context);
                  },
                  child: const Text('CANCELAR'),
                ),
                TextButton(
                  onPressed: () async {
                    cambiarEstado(accionId);
                    setState(() {});
                    router.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onError,
                  ),
                  child: const Text('CONFIRMAR'),
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: colors.primary,
            iconTheme: IconThemeData(
              color: colors.onPrimary
            ),
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
            title: Text(
              'Orden ${orden.numeroOrdenTrabajo} ${orden.descripcion} ',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  logout();
                }, 
                icon: const Icon(
                  Icons.logout,
                  size: 34,
                )
              ),
            ],
          ),
          body: cargando ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10,),
                Text('Cargando...'),
              ],
            ),
          ) : Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [  
                SizedBox(
                  width: screenWidth,
                  child: TabBar(
                    labelColor: Colors.white,
                    indicator: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                      color: colors.primary,
                    ),
                    dividerColor: colors.secondary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    controller: tabBarController,
                    onTap: (value) {
                      setState(() {});
                    },
                    tabs: [
                      if (isMobile) ... [
                        const Icon(Icons.description, size: 40,),
                        const Icon(Icons.article_outlined, size: 40,),
                        const Icon(Icons.format_list_bulleted_outlined, size: 40,),
                        const Icon(Icons.grading, size: 40,),
                      ] else ... [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description),
                            SizedBox(width: 10,),
                            Tab(child: Text('Datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                          ],
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined),
                            SizedBox(width: 10,),
                            Tab(child: Text('Tareas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                          ],
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.format_list_bulleted_outlined),
                            SizedBox(width: 10,),
                            Tab(child: Text('Materiales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                          ],
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grading),
                            SizedBox(width: 10,),
                            Tab(child: Text('Control', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),),),
                          ],
                        ),
                      ],
                      
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth,
                  height: screenWidth > screenHeight ? screenHeight * 0.76 : screenHeight * 0.85,
                  child: TabBarView(
                    controller: tabBarController,
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: screenWidth,
                                  height: (screenWidth > screenHeight) ? screenHeight * heightMultiplierCliente : screenHeight * 0.092,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Cliente:',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 5,),
                                        Text(
                                          '${orden.cliente.codCliente} - ${orden.cliente.nombre} Telefono: ${orden.cliente.telefono1}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(), 
                            Padding(
                              padding: (MediaQuery.of(context).orientation == Orientation.landscape) ? const EdgeInsets.fromLTRB(0,20,0,0) : const EdgeInsets.fromLTRB(0,5,0,0),
                              child: (MediaQuery.of(context).orientation == Orientation.landscape) ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isMobile) ... [
                                    ChildrenColumn1(screenWidth: screenWidth * 0.4, screenHeight: screenHeight * 0.15, colors: colors, orden: orden),
                                    const SizedBox(height: 10,),
                                    ChildrenColumn2(screenWidth: screenWidth * 0.4, screenHeight: screenHeight * 0.15, colors: colors, notas: notasController, instrucciones: instruccionesController, km: kmController,)
                                  ]else ... [
                                    ChildrenColumn1(screenWidth: screenWidth * 0.4, screenHeight: screenHeight * 0.11, colors: colors, orden: orden),
                                    const SizedBox(height: 10,),
                                    ChildrenColumn2(screenWidth: screenWidth * 0.4, screenHeight: screenHeight * 0.15, colors: colors, notas: notasController, instrucciones: instruccionesController, km: kmController,)
                                  ],
                                ],
                              ):Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ChildrenColumn1(screenWidth: screenWidth * 0.7, screenHeight: screenHeight * 0.07, colors: colors, orden: orden),
                                    const SizedBox(height: 10,),
                                    ChildrenColumn2(screenWidth: screenWidth, screenHeight: screenHeight * 0.15, colors: colors, notas: notasController, instrucciones: instruccionesController, km: kmController,)
                                  ],
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
                          borderRadius: BorderRadius.circular(8),
                          color: colors.onPrimary,
                        ),
                        child: Column(
                          children: [
                            // Fixed header
                            const SizedBox(height: 5,),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: const Border(bottom: BorderSide(color: Colors.grey)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  //! ACAAAAAAAAAAAAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
                                  _buildHeaderCell('Código', flex: 2),
                                  if (isMobile) ... [
                                    screenWidth > screenHeight ? _buildHeaderCell('Descripción', flex: 3) : _buildHeaderCell('Descripción', flex: 3),
                                  ] else ... [
                                    screenWidth > screenHeight ? _buildHeaderCell('Descripción', flex: 3) : _buildHeaderCell('Descripción', flex: 2),
                                  ],
                                  if(!isMobile)
                                  _buildHeaderCell('Comentario', flex: 1),
                                  _buildHeaderCell('Avance', flex: 1),
                                  if(!isMobile)
                                  IconButton(onPressed: null, icon: Icon(Icons.play_arrow,color: Colors.grey[200],)),
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
                          borderRadius: BorderRadius.circular(8),
                          color: colors.onPrimary,
                        ),
                        child: Column(
                          children: [
                            // Fixed header
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: const Border(bottom: BorderSide(color: Colors.grey)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  //! ACAAAAAAAAAAAAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
                                  if (isMobile) ... [
                                    _buildHeaderCell('Código', flex: 2),
                                    screenWidth > screenHeight ? _buildHeaderCell('Descripción', flex: 4) : _buildHeaderCell('Descripción', flex: 3),
                                  ] else ...[
                                    _buildHeaderCell('Código', flex: 2),
                                    screenWidth > screenHeight ? _buildHeaderCell('Descripción', flex: 3) : _buildHeaderCell('Descripción', flex: 4),
                                  ],
                                  if(!isMobile)
                                  _buildHeaderCell('Comentario', flex: 1),
                                  _buildHeaderCell('Cant', flex: 1),
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
                      Column(
                        children: [
                          SizedBox(
                            width: screenWidth,
                            child: TabBar(
                              labelColor: Colors.white,
                              indicator: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(3)),
                                color: colors.secondary,
                              ),
                              dividerColor: colors.secondary,
                              indicatorSize: TabBarIndicatorSize.tab,
                              controller: tabBarController2,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              tabs: [
                                const Tab(child: Text('Todos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),),
                                for(var grupo in grupos)...[
                                  Tab(child: Text(grupo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),),
                                ]
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: tabBarController2,
                              children: [
                                listaControles(controles),
                                for (var grupo in grupos) 
                                listaControles(controlesPorGrupo[grupo.toLowerCase()] ?? []),
                              ]
                            ),
                          ),
                        ],
                      ),
                    ]
                  ),
                ),
              ],
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
              onTap: (index) async {
                  buttonIndex = index;
                  switch (buttonIndex){
                    case 0: 
                      if (!ejecutando){
                        _mostrarDialogoConfirmacion('recibir');
                      } else {
                        null;
                      }
                    break;
                    case 1:
                      if (!ejecutando){
                        
                        _mostrarDialogoConfirmacion('aprobar');
                      } else {
                        null;
                      }
                    break;  
                    case 2:
                      await botonGuardar(context);
                    break;
                    case 3:
                      print(tabBarController.index);
                      await botonImprimir(context, tabBarController.index);
                    break;
                  }
                setState(() {});
              },
              showUnselectedLabels: true,
              selectedItemColor: colors.primary,
              unselectedItemColor: colors.primary,  
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.read_more),
                  label: 'Recibir',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.done_all),
                  label: 'Aprobar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.save),
                  label: 'Guardar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.print,),
                  label: 'Imprimir',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> botonImprimir(BuildContext context, int index) {
    final colors = Theme.of(context).colorScheme;
    return showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: Text(index == 0 ? 'Imprimir OT' : 'Imprimir controles'),
          content: Text(
            index == 0 ? 'Esta por imprimir la OT ${orden.numeroOrdenTrabajo}, esta seguro de querer imprimirla?' : 'Esta por imprimir los controles de la OT ${orden.numeroOrdenTrabajo}, esta seguro de querer imprimirlos?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('CANCELAR')
            ),
            TextButton(
              onPressed: () async {
                if(index == 0){
                  await ordenServices.imprimirOT(context, orden, token);
                } else if(index == 3){
                  await ordenServices.imprimirControles(context, orden, token);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: colors.onError,
              ),
              child: const Text(
                'IMPRIMIR',
              )
            ),
          ],
        );
      }
    );
  }

  Future<void> botonGuardar(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    if(buttonIndex == 2) {
      orden.comentarioCliente = notasController.text ;
      orden.comentarioTrabajo = instruccionesController.text;
      orden.km = int.tryParse(kmController.text);
      await showDialog(
        context: context, 
        builder: (context) {
          return AlertDialog(
            title: const Text('Quiere marcar la OT en ALERTA?'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: const Text(
                '(Responda SI si los comentarios en la OT son relevantes al momento de la facturación  del servicio.)', 
                style: TextStyle(fontSize: 18),
              )
            ),
            actions: [
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      router.pop();
                    },
                    child: const Text('CANCELAR')
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      orden.alerta = true;
                      await ordenServices.datosAdicionales(context, orden, token);
                      router.pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onError,
                    ),
                    child: const Text('SI')
                  ),
                  TextButton(
                    onPressed: () async {
                      orden.alerta = false;
                      await ordenServices.datosAdicionales(context, orden, token);
                      router.pop();
                    },
                    child: const Text(
                      'NO',
                    ),
                  ),
                ],
              ), 
            ],
          );
        }
      );
    }
  }

  ListView listaControles(List<Control> controles) {
    return isMobile ? ListView.builder(
      itemCount: controles.length,
      itemBuilder: (context, index) {
        final control = controles[index];
        return GestureDetector(
          onDoubleTap: () async {
            if(control.controlRegId != 0){
              await comentarioControl(context, control);
            }
          },
          child: Card(
            color: control.respuesta == 'Largo Plazo' ? Colors.green[100] : control.respuesta == 'Corto Plazo' ? Colors.yellow[100] : control.respuesta == 'Inmediato' ? Colors.red[100] : Colors.white, // Default color
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8,8,0,0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        control.pregunta,
                      ),
                      Text(
                        control.respuesta != '' ? control.respuesta : 'Sin selección',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      control.comentario ?? '',
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Verde
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () async {
                          actualizarValor(control.pregunta, control, 'Largo Plazo', Colors.green[100]!);
                          control.claveRespuesta = 0;
                          if(control.controlRegId == 0) {
                            await ControlServices().postControl2(context, control, token);
                          } else{
                            await ControlServices().putControl2(context, control, token);
                          }
                        },
                      ),
                      // Botón Amarillo
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.yellow),
                        onPressed: () async {
                          actualizarValor(control.pregunta, control, 'Corto Plazo', Colors.yellow[100]!);
                          control.claveRespuesta = 1;
                          if(control.controlRegId == 0) {
                            await ControlServices().postControl2(context, control, token);
                          } else{
                            await ControlServices().putControl2(context, control, token);
                          }
                        },
                      ),
                      // Botón Rojo
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.red),
                        onPressed: () async {
                          actualizarValor(control.pregunta, control, 'Inmediato', Colors.red[100]!);
                          control.claveRespuesta = 2;
                          if(control.controlRegId == 0) {
                            await ControlServices().postControl2(context, control, token);
                          } else{
                            await ControlServices().putControl2(context, control, token);
                          }
                        },
                      ),
                      // Botón Limpiar
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: ()  async {
                          await ControlServices().deleteControl2(context, control, token);
                          control.comentario = '';
                          control.controlRegId = 0;
                          actualizarValor(control.pregunta, control, 'Sin selección', Colors.white);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ) : ListView.builder(
      itemCount: controles.length,
      itemBuilder: (context, index) {
        final control = controles[index];
        return GestureDetector(
          onDoubleTap: () async {
            if(control.controlRegId != 0){
              await comentarioControl(context, control);
            }
          },
          child: Card(
            color: control.respuesta == 'Largo Plazo' ? Colors.green[100] : control.respuesta == 'Corto Plazo' ? Colors.yellow[100] : control.respuesta == 'Inmediato' ? Colors.red[100] : Colors.white, // Default color
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8,0,0,8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Text(
                          control.pregunta,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Botón Verde
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () async {
                              actualizarValor(control.pregunta, control, 'Largo Plazo', Colors.green[100]!);
                              control.claveRespuesta = 0;
                              if(control.controlRegId == 0) {
                                await ControlServices().postControl2(context, control, token);
                              } else{
                                await ControlServices().putControl2(context, control, token);
                              }
                            },
                          ),
                          // Botón Amarillo
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.yellow),
                            onPressed: () async {
                              actualizarValor(control.pregunta, control, 'Corto Plazo', Colors.yellow[100]!);
                              control.claveRespuesta = 1;
                              if(control.controlRegId == 0) {
                                await ControlServices().postControl2(context, control, token);
                              } else{
                                await ControlServices().putControl2(context, control, token);
                              }
                            },
                          ),
                          // Botón Rojo
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.red),
                            onPressed: () async {
                              actualizarValor(control.pregunta, control, 'Inmediato', Colors.red[100]!);
                              control.claveRespuesta = 2;
                              if(control.controlRegId == 0) {
                                await ControlServices().postControl2(context, control, token);
                              } else{
                                await ControlServices().putControl2(context, control, token);
                              }
                            },
                          ),
                          // Botón Limpiar
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: ()  async {
                              await ControlServices().deleteControl2(context, control, token);
                              control.comentario = '';
                              control.controlRegId = 0;
                              actualizarValor(control.pregunta, control, 'Sin selección', Colors.white);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Column(
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Text(
                  //       control.respuesta != '' ? control.respuesta : 'Sin selección',
                  //       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  //     ),
                  //   ],
                  // ),
                  if (control.comentario != '')
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      control.comentario ?? '',
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> comentarioControl(BuildContext context, Control control) {
    final colors = Theme.of(context).colorScheme;
    if(control.comentario != null){
      comentarioController.text = control.comentario!;
    } else {
      comentarioController.text = '';
    }
    return showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('Comentario'),
          content: CustomTextFormField(
            controller: comentarioController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('CANCELAR')
            ),
            TextButton(
              onPressed: () async {
                control.comentario = comentarioController.text;
                await ControlServices().putControl2(context, control, token);
                setState(() {});
                router.pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: colors.onError,
              ),
              child: const Text(
                'GUARDAR',  
              )
            ),
          ],
        );
      },
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

  cambiarEstado(int accionId) async {
    if (!ejecutando) {
      ejecutando = true;
      String token = context.read<OrdenProvider>().token;
      await _ordenServices.patchOrdenCambioEstado(context, orden, accionId, token);
      statusCode = await _ordenServices.getStatusCode();
      await _ordenServices.resetStatusCode();
      if(statusCode == 1){
        orden.estado = siguienteEstado;
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

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: (text == 'Código' || text == 'Avance' || text == 'Cant') ? Alignment.center : Alignment.centerLeft,
        child: Text(
          text,
          style: isMobile ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 15) : const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataRow(dynamic objeto, BuildContext context, int index) {
    final isSelected = index == selectedTaskIndex;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTaskIndex = isSelected ? null : index; 
        });
      },
      onLongPress: () async {
        await showDialog(
          context: context, 
          builder: (context) {
            return AlertDialog(
              title: const Text('Comentario'),
              content: Text(objeto.comentario ?? ''),
              actions: [
                TextButton(
                  onPressed: () {
                    router.pop();
                  },
                  child: const Text('CERRAR')
                )
              ],
            );
          }
        );
      },
      onDoubleTap: () {
        if(orden.estado != 'PENDIENTE'){
          if(objeto is Linea) {
            if (objeto.mo == 'MO'){
              setState(() {
                selectedTaskIndex = isSelected ? null : index; 
              });
              comenzarTarea(context, index);
            }
          }
        }
      },
      child: Card(
        shadowColor: Colors.blue.withOpacity(0.3),
        //color: (objeto is Linea && objeto.comentario != '') ? colors.primary.withOpacity(0.3) : null,
        child: Column(
          children: [
            (objeto is Linea && objeto.comentario != '') ?
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.comment_outlined, color: colors.secondary, size: 20,),
                const SizedBox(width: 20,),
              ],
            ) : const SizedBox(),
            Row(
              children: [
                if(objeto is Linea)...[
                  //! ACAAAAAAAAAAAAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
                  _buildDataCell(objeto.codItem, flex: 2, alignment: Alignment.center),
                  if (isMobile) ... [
                    _buildDataCell(objeto.descripcion, flex: 3, alignment: Alignment.centerLeft),
                  ]else ... [
                    _buildDataCell(objeto.descripcion, flex: 3, alignment: Alignment.centerLeft),
                  ],
                  if(!isMobile)
                  _buildDataCell(objeto.comentario, flex: 1, alignment: Alignment.centerLeft),
                  _buildDataCell(objeto.mo == 'MO' ? objeto.getAvanceEnHorasMinutos() : objeto.cantidad.toString() , flex: 1, alignment: Alignment.center),
                  if(!isMobile)
                  if(objeto.mo == 'MO')...[
                    IconButton(
                      onPressed: (){
                        // if(orden.estado != 'PENDIENTE'){
                          if (objeto.mo == 'MO'){
                            setState(() {
                              selectedTaskIndex = isSelected ? null : index; 
                            });
                            comenzarTarea(context, index);
                          }
                        // }
                      }, icon: const Icon(Icons.play_arrow)
                    ),
                  ]
                ] 
              ],
            ),
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
          style: TextStyle(fontSize: isMobile ? 15 : 18),
          text,
          textAlign: alignment == Alignment.center ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }

  void comenzarTarea(BuildContext context, int i) {
    final colors = Theme.of(context).colorScheme;
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
                Text("¿Comienza a trabajar en la OT: ${orden.numeroOrdenTrabajo} ${orden.descripcion} en la tarea ${tareas[i].descripcion}?"),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCELAR"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colors.onError,
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

  void logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('Esta seguro de querer cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('CANCELAR')
            ),
            TextButton(
              onPressed: () {
                Provider.of<OrdenProvider>(context, listen: false).setToken('');
                router.go('/');
              },
              child: const Text(
                'CERRAR SESIÓN',
                style: TextStyle(color: Colors.red),
              )
            ),
          ],
        );
      },
    );
  }
  
}

class ChildrenColumn1 extends StatelessWidget {
  const ChildrenColumn1({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.colors,
    required this.orden,
  });

  final double screenWidth;
  final double screenHeight;
  final ColorScheme colors;
  final Orden orden;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Estado: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              context.watch<OrdenProvider>().orden.estado,
              style: const TextStyle(fontSize: 14,),
            ),
          ],
        ), 
        const SizedBox(height: 10,),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fecha: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaOrdenTrabajo),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),     
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Vencimiento: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaVencimiento),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (orden.fechaEntrega != null) ... [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Entrega: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                DateFormat('EEEE d, MMMM yyyy HH:ss', 'es').format(orden.fechaEntrega!),
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ],      
      ],
    );
  }
}

class ChildrenColumn2 extends StatelessWidget {
  const ChildrenColumn2({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.colors,
    required this.notas,
    required this.instrucciones,
    required this.km,
  });

  final double screenWidth;
  final double screenHeight;
  final ColorScheme colors;
  final TextEditingController notas;
  final TextEditingController instrucciones;
  final TextEditingController km;
  
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: screenWidth,
              child: TextFormField(
                minLines: 2,
                maxLines: 20,
                controller: notas,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Comentario del cliente',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: screenWidth,
              child: TextFormField(
                minLines: 2,
                maxLines: 20,
                style: const TextStyle(color: Colors.black),
                controller: instrucciones,
                decoration: const InputDecoration(
                  hintText: 'Comentarios del trabajo',
                  border: OutlineInputBorder(),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            SizedBox(
              width: screenWidth * 0.3,
              child: TextFormField(
                maxLines: 1,
                style: const TextStyle(color: Colors.black),
                controller: km,
                textAlign: TextAlign.end,
                onTap: () {
                  km.selection = TextSelection(baseOffset: 0, extentOffset: km.text.length);
                },
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('KM'),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
          ],
        );
      },
      
    );
  }
}


