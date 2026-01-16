// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/delegates/cliente_search_delegate.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/tecnico_services.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Monitoreo extends StatefulWidget {
  const Monitoreo({super.key});

  @override
  State<Monitoreo> createState() => _MonitoreoState();
}

class _MonitoreoState extends State<Monitoreo> {
  List<Tecnico> tecnicos = [];
  List<Orden> ordenes = [];
  List<String> estados = [
    'Pendiente',
    'Recibido',
    'Aprobado',
  ];
  late String token = '';
  Tecnico? selectedTecnico;
  final _ordenServices = OrdenServices();
  DateTime selectedDate = DateTime.now();
  int tecnicoFiltro = 0;
  int clienteFiltro = 0;
  List<Orden> ordenesPendientes = [];
  List<Orden> ordenesEnProceso = [];
  List<Orden> ordenesFinalizadas = [];
  List<Orden> ordenesRevisadas = [];
  Map<String, Color> colores = {
    'Pendiente': Colors.yellow.shade200,
    'Recibido': Colors.greenAccent.shade400,
    // 'Revisada': Colors.blue.shade400,
    'Aprobado': Colors.red.shade200
  };
  Map<String, Color> coloresCampanita = {
    'PENDIENTE': Colors.yellow.shade200,
    'RECIBIDO': Colors.greenAccent.shade400,
    // 'REVISADA': Colors.blue.shade400,
    'APROBADO': Colors.red.shade200
  };
  late Cliente clienteSeleccionado;
  List<Orden> ordenesCampanita = [];
  late DateTime hoy = DateTime.now();
  late DateTime mesesAtras = DateTime(hoy.year, hoy.month - 3, hoy.day);
  late DateTime ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
  late String desde = DateFormat('yyyy-MM-dd', 'es').format(mesesAtras);
  late String hasta = DateFormat('yyyy-MM-dd', 'es').format(ayer);
  
  // Variables específicas para móvil
  late final PageController _pageController = PageController(initialPage: 0);
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    clienteSeleccionado = Cliente.empty();
    hoy = DateTime.now();
    ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
    mesesAtras = DateTime(hoy.year, hoy.month - 3, hoy.day);
    desde = DateFormat('yyyy-MM-dd', 'es').format(mesesAtras);
    hasta = DateFormat('yyyy-MM-dd', 'es').format(ayer);
    cargarListas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (tecnicos.isEmpty) {
      loadTecnicos();
    }
    cargarDatos();
  }

  cargarDatos() async {
    token = context.watch<AuthProvider>().token;
    ordenesCampanita = await OrdenServices().getOrdenCampanita(context, desde, hasta, 'PENDIENTE, RECIBIDO, APROBADO', 1, token);
    setState(() {});
  }

  Future<void> loadTecnicos() async {
    final token = context.watch<AuthProvider>().token;
    final loadedTecnicos = await TecnicoServices().getAllTecnicos(context, token);

    setState(() {
      tecnicos = loadedTecnicos;
      tecnicos.insert(
          0,
          Tecnico(
          cargoId: 0,
          tecnicoId: 0,
          codTecnico: '0',
          nombre: 'Todos',
          fechaNacimiento: null,
          documento: '',
          fechaIngreso: null,
          fechaVtoCarneSalud: null,
          deshabilitado: false,
          firmaPath: '' ,
          firmaMd5: '' ,
          avatarPath: '' ,
          avatarMd5: '' ,
          cargo: null,
          verDiaSiguiente: null,
        ));
    });
  }

  void _mostrarBusquedaCliente() async {
    final Cliente? resultado = await showSearch<Cliente>(
      context: context,
      delegate: ClienteSearchDelegate(
        token: token,
        clientService: ClientServices(),
      ),
    );

    if (resultado != null && resultado.clienteId > 0) {
      setState(() {
        clienteSeleccionado = resultado;
        clienteFiltro = resultado.clienteId;
      });
      // Buscar automáticamente después de seleccionar cliente
      if (token.isNotEmpty) {
        buscar(token);
      }
    }
  }

  Future<void> buscar(String token) async {
  if (token.isEmpty) return;
  
  // Si no hay cliente seleccionado, no buscar
  if (clienteSeleccionado.clienteId == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor seleccione un cliente'))
    );
    return;
  }

  String tecnicoId = selectedTecnico != null && selectedTecnico!.tecnicoId > 0 
    ? selectedTecnico!.tecnicoId.toString() 
    : '';
  
  String fechaDesde = DateFormat('yyyy-MM-dd', 'es').format(selectedDate);
  
  // Preparar los parámetros de consulta
  Map<String, dynamic> queryParams = {};
  
  // Agregar filtros
  queryParams['clienteId'] = clienteSeleccionado.clienteId.toString();
  
  if (tecnicoId.isNotEmpty) {
    queryParams['tecnicoId'] = tecnicoId;
  }
  
  
  try {
    List<Orden> results = await _ordenServices.getOrden(
      context, 
      tecnicoId,
      token,
      queryParams: queryParams,
      desde: fechaDesde,
      hasta: fechaDesde,
    );
    
    setState(() {
      ordenes = results;
    });
    cargarListas();
  } catch (e) {
    print('Error al buscar órdenes: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al buscar órdenes: ${e.toString()}'))
    );
  }
}

  void cargarListas() {
    List<Orden> ordenesFiltradas = [];
    ordenesFiltradas = ordenes
        .where((e) =>
            (clienteFiltro > 0 ? e.cliente?.clienteId == clienteFiltro : true) &&
            (tecnicoFiltro > 0 ? e.tecnico?.tecnicoId == tecnicoFiltro : true))
        .toList();
    
    ordenesPendientes.clear();
    ordenesEnProceso.clear();
    ordenesFinalizadas.clear();
    ordenesRevisadas.clear();
    
    for (var orden in ordenesFiltradas) {
      switch (orden.estado?.toUpperCase()) {
        case 'PENDIENTE':
          ordenesPendientes.add(orden);
          break;
        case 'RECIBIDO':
          ordenesEnProceso.add(orden);
          break;
        case 'APROBADO':
          ordenesFinalizadas.add(orden);
          break;
        case 'REVISADA':
          ordenesRevisadas.add(orden);
          break;
        default:
          break;
      }
    }
    setState(() {});
  }

  String _formatDateAndTime(DateTime? date) {
    return '${date?.day.toString().padLeft(2, '0')}/${date?.month.toString().padLeft(2, '0')}/${date?.year.toString().padLeft(4, '0')} ${date?.hour.toString().padLeft(2, '0')}:${date?.minute.toString().padLeft(2, '0')}';
  }

  Future<void> ordenesARevisar(BuildContext context) async {
    ordenesCampanita = await OrdenServices().getOrdenCampanita(context, desde, hasta, 'PENDIENTE, APROBADO, RECIBIDO', 1000, token);
    
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Ordenes a revisar"),
          content: Column(
            children: [
              SizedBox(
                height: isMobile 
                  ? MediaQuery.of(context).size.height * 0.75
                  : MediaQuery.of(context).size.height * 0.68,
                width: isMobile 
                  ? MediaQuery.of(context).size.width * 0.8
                  : MediaQuery.of(context).size.width * 0.3,
                child: isMobile 
                  ? ListView.separated(
                      itemCount: ordenesCampanita.length,
                      itemBuilder: (context, i) {
                        var orden = ordenesCampanita[i];
                        return InkWell(
                          onTap: () {
                            Provider.of<OrdenProvider>(context, listen: false).setOrden(orden);
                            Navigator.of(context).pop();
                            router.push('/editOrden');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: coloresCampanita[orden.estado],),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${orden.ordenTrabajoId}', style: const TextStyle(color: Colors.white),),
                                )
                              ),
                              Text(orden.cliente!.nombre, style: const TextStyle(fontWeight: FontWeight.w600),),
                              Text('${orden.tecnico!.nombre} \nEstado: ${orden.estado}'),
                              Text(orden.fechaDesde != null ? DateFormat("E d, MMM HH:mm", 'es').format(orden.fechaDesde!) : ''),
                              Text(orden.fechaHasta != null ? DateFormat("E d, MMM HH:mm", 'es').format(orden.fechaHasta!) : ''),
                            ],
                          ),
                        );
                      }, 
                      separatorBuilder: (BuildContext context, int index) { 
                        return const Divider(); 
                      },
                    )
                  : ListView.builder(
                      itemCount: ordenesCampanita.length,
                      itemBuilder: (context, i) {
                        var orden = ordenesCampanita[i];
                        return ListTile(
                          isThreeLine: true,
                          leading: Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: coloresCampanita[orden.estado],),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${orden.ordenTrabajoId}', style: const TextStyle(color: Colors.white),),
                            )
                          ),
                          title: Text(orden.cliente!.nombre, style: const TextStyle(fontWeight: FontWeight.w600),),
                          subtitle: Text('${orden.tecnico!.nombre} \nEstado: ${orden.estado}'),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(orden.fechaDesde != null ? DateFormat("E d, MMM HH:mm", 'es').format(orden.fechaDesde!) : ''),
                              Text(orden.fechaHasta != null ? DateFormat("E d, MMM HH:mm", 'es').format(orden.fechaHasta!) : ''),
                            ],
                          ),
                          onTap: () {
                            Provider.of<OrdenProvider>(context, listen: false).setOrden(orden);
                            Navigator.of(context).pop();
                            router.push('/editOrden');
                          },
                        );
                      },
                    ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: (){router.pop();}, 
              child: const Text('Cerrar')
            )
          ],
        );
      },
    );
  }

  Widget cardsDeLaLista(List<Orden> orden, int index, String color) {
    return InkWell(
      onTap: () {
        Provider.of<OrdenProvider>(context, listen: false).setOrden(orden[index]);
        router.push('/editOrden');
      },
      child: Card(
        color: colores[color],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Orden  ${orden[index].ordenTrabajoId}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                )
              ),
              // Text('Tecnico: ${orden[index].tecnico!.nombre}''\n${orden[index].cliente!.codCliente} Cliente: ${orden[index].cliente!.nombre}'),
              Text('Fecha Desde: ${orden[index].fechaDesde != null ? DateFormat("E d, MMM, HH:mm", 'es').format(orden[index].fechaDesde!) : ''}'),
              Text('Fecha Hasta: ${orden[index].fechaHasta != null ? DateFormat("E d, MMM, HH:mm", 'es').format(orden[index].fechaHasta!) : ''}'),
              if(orden[index].estado != 'PENDIENTE')...[
                Text(orden[index].iniciadaEn == null ? '' : 'Iniciada: ${_formatDateAndTime(orden[index].iniciadaEn)}'),
                if(orden[index].estado != 'EN PROCESO')
                Text(orden[index].finalizadaEn == null ? '' : 'Finalizada: ${_formatDateAndTime(orden[index].finalizadaEn)}')
              ],
              Text(orden[index].tipoOrden!.descripcion.toString()),
              Text(orden[index].estado.toString()),
              // for (var i = 0; i < orden[index].servicios.length; i++) ...[
              //   Text(orden[index].servicios[i].descripcion)
              // ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoContainer(String estado, List<Orden> ordenesEstado) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color: colores[estado],
                borderRadius: BorderRadius.circular(5)),
              height: 30,
              child: Center(
                child: Text(
                  '$estado (${ordenes.where((orden) => orden.estado!.toLowerCase() == estado.toLowerCase()).length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: ordenesEstado.length,
              itemBuilder: (context, index) {
                return cardsDeLaLista(ordenesEstado, index, estado);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    if (isMobile) {
      return _buildMobileView(colors);
    } else {
      return _buildDesktopView(colors);
    }
  }

  Widget _buildMobileView(ColorScheme colors) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitor de ordenes'),
          foregroundColor: colors.onPrimary,
          actions: [
            IconButton(
              onPressed: () {router.pop();},
              icon: const Icon(Icons.arrow_back)
            )
          ],
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: colors.primary, width: 15)),  
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Column(
                    children: [
                      const Text(
                        'Tecnico: ',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10,),
                      SizedBox(
                        width: 220,
                        child: DropdownSearch(
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                  hintText: 'Seleccione un tecnico')),
                          items: tecnicos,
                          popupProps: const PopupProps.menu(
                              showSearchBox: true, searchDelay: Duration.zero),
                          onChanged: (value) {
                            setState(() {
                              selectedTecnico = value;
                              tecnicoFiltro = value!.tecnicoId;
                            });
                          },
                        ),
                      ),
                      const Divider(height: 50,),
                      const Text(
                        'Cliente: ',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _mostrarBusquedaCliente,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.search),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  clienteSeleccionado.clienteId > 0 
                                    ? '${clienteSeleccionado.nombre} ${clienteSeleccionado.nombreFantasia}'
                                    : 'Buscar cliente...',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: clienteSeleccionado.clienteId > 0 ? Colors.blue : null,
                                    fontWeight: clienteSeleccionado.clienteId > 0 ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                              if (clienteSeleccionado.clienteId > 0)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      clienteSeleccionado = Cliente.empty();
                                      clienteFiltro = 0;
                                    });
                                    if (token.isNotEmpty) {
                                      buscar(token);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),              
                  const Divider(height: 50,),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: const Text('Seleccione fecha'),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        initialDate: selectedDate,
                        firstDate: DateTime(2022),
                        lastDate: DateTime(2099),
                        context: context,
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                          print(selectedDate);
                        });
                      }
                    },
                  ),
                  Text(
                    DateFormat('d/MM/yyyy').format(selectedDate), style: const TextStyle(fontSize: 20),
                  ),
                  const Divider(height: 50,),
                  CustomButton(
                    text: 'Buscar',
                    onPressed: () async {
                      await buscar(token);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _pageIndex = index;
            });
          },
          scrollDirection: Axis.horizontal,
          children: [
            _buildEstadoContainer('Pendiente', ordenesPendientes),
            _buildEstadoContainer('Recibido', ordenesEnProceso),
            _buildEstadoContainer('', ordenesFinalizadas),
            // _buildEstadoContainer('Revisada', ordenesRevisadas),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            ordenesARevisar(context);
          },
          child: ordenesCampanita.isEmpty ? Icon(Icons.notifications, color: colors.onPrimary,) : Icon(Icons.notifications_active, color: colors.onPrimary,),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _pageIndex,
          onTap: (index) {
            setState(() {
              _pageIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
          showUnselectedLabels: true,
          selectedItemColor: Colors.black,
          unselectedItemColor: colors.primary,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions),
              label: 'Pendiente',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_arrow),
              label: 'Recibido',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.done),
              label: 'Aprobado',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.check),
            //   label: 'Revisada',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopView(ColorScheme colors) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitoreo de ordenes'),
          foregroundColor: colors.onPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      const Text(
                        'Tecnico: ',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownSearch(
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                  hintText: 'Seleccione un tecnico')),
                          items: tecnicos,
                          popupProps: const PopupProps.menu(
                              showSearchBox: true, searchDelay: Duration.zero),
                          onChanged: (value) {
                            setState(() {
                              selectedTecnico = value;
                              tecnicoFiltro = value!.tecnicoId;
                            });
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const Text(
                        'Cliente: ',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: _mostrarBusquedaCliente,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.primary),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                color: clienteSeleccionado.clienteId > 0 ? colors.primary : colors.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                clienteSeleccionado.clienteId > 0 
                                  ? clienteSeleccionado.nombre.length > 15 
                                    ? '${clienteSeleccionado.nombre.substring(0, 15)}...'
                                    : clienteSeleccionado.nombre
                                  : 'Seleccionar cliente',
                                style: TextStyle(
                                  color: clienteSeleccionado.clienteId > 0 ? colors.primary : null,
                                  fontWeight: clienteSeleccionado.clienteId > 0 ? FontWeight.bold : null,
                                ),
                              ),
                              if (clienteSeleccionado.clienteId > 0)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      clienteSeleccionado = Cliente.empty();
                                      clienteFiltro = 0;
                                    });
                                    if (token.isNotEmpty) {
                                      buscar(token);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await buscar(token);
                        },
                        icon: const Icon(Icons.search_outlined),
                        tooltip: 'Buscar',
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          await ordenesARevisar(context);
                        },
                        tooltip: 'Ordenes a revisar',  
                        icon: ordenesCampanita.isEmpty ? Icon(Icons.notifications, color: colors.primary,) : Icon(Icons.notifications_active, color: colors.primary,)
                      ),
                      IconButton(
                        tooltip: 'Seleccione fecha',
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2099),
                            context: context,
                          );
                          if (pickedDate != null &&
                              pickedDate != selectedDate) {
                            setState(() {
                              selectedDate = pickedDate;
                              print(selectedDate);
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month)
                      ),
                      const Text('Fecha: ',
                        style: TextStyle(fontSize: 24),
                      ),
                      Text(DateFormat("E d, MMM", 'es').format(selectedDate),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(5)),
                  height: 30,
                  child: const Center(
                    child: Text(
                      'Ordenes de trabajo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: estados.map((estado) {
                    final color = colores[estado];
                    return Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        height: 60,
                        width: 170,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              '$estado (${ordenes.where((orden) => orden.estado!.toLowerCase() == estado.toLowerCase()).length})',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        width: 450,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: ordenesPendientes.length,
                              itemBuilder: (context, index) {
                                return cardsDeLaLista(ordenesPendientes, index, 'Pendiente');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: SizedBox(
                        width: 450,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: ordenesEnProceso.length,
                              itemBuilder: (context, index) {
                                return cardsDeLaLista(ordenesEnProceso, index, 'Recibido');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      child: SizedBox(
                        width: 450,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              itemCount: ordenesFinalizadas.length,
                              itemBuilder: (context, index) {
                                return cardsDeLaLista(ordenesFinalizadas, index, 'Aprobado');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Flexible(
                    //   flex: 1,
                    //   child: SizedBox(
                    //     width: 450,
                    //     child: Column(
                    //       mainAxisAlignment: MainAxisAlignment.start,
                    //       children: [
                    //         ListView.builder(
                    //           shrinkWrap: true,
                    //           scrollDirection: Axis.vertical,
                    //           itemCount: ordenesRevisadas.length,
                    //           itemBuilder: (context, index) {
                    //             return cardsDeLaLista(ordenesRevisadas, index, 'Revisada');
                    //           },
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}