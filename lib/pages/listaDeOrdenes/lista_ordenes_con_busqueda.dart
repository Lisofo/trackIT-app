// ignore_for_file: use_build_context_synchronously

import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/widgets/filtros_ordenes.dart';

class ListaOrdenesConBusqueda extends StatefulWidget {
  const ListaOrdenesConBusqueda({super.key});

  @override
  State<ListaOrdenesConBusqueda> createState() => _ListaOrdenesConBusquedaState();
}

class _ListaOrdenesConBusquedaState extends State<ListaOrdenesConBusqueda> {
  final ordenServices = OrdenServices();
  String token = '';
  List<Orden> ordenes = [];
  late int tecnicoId = 0;
  int groupValue = 0;
  List trabajodres = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool isMobile = false;
  bool isAdmin = false;

  // Variables para los filtros
  bool _isFilterExpanded = false;
  int? _clienteIdFiltro;
  int? _unidadIdFiltro;
  DateTime? _fechaDesdeFiltro;
  DateTime? _fechaHastaFiltro;
  String? _numeroOrdenFiltro; // Nueva variable

  @override
  void initState() {
    super.initState();
    // cargarDatos();
    token = context.read<OrdenProvider>().token;
    tecnicoId = context.read<OrdenProvider>().tecnicoId;
  }

  // 2. Método para manejar la actualización de datos
  Future<void> _refreshData() async {
    ordenes = [];
    setState(() {});
    await cargarDatos();
  }

  cargarDatos() async {
    try {
      
      // Obtener la unidad seleccionada del provider
      final unidadSeleccionada = context.read<OrdenProvider>().unidadSeleccionada;
      
      Map<String, dynamic> queryParams = {};
      queryParams['sort'] = 'fechaDesde DESC'; // Ordenar por fechaDesde descendente
      
      // Agregar parámetros de filtro si existen
      if (_clienteIdFiltro != null && _clienteIdFiltro! > 0) {
        queryParams['clienteId'] = _clienteIdFiltro.toString();
      }
      
      if (_unidadIdFiltro != null && _unidadIdFiltro! > 0) {
        queryParams['unidadId'] = _unidadIdFiltro.toString();
      } else if (unidadSeleccionada.unidadId > 0) {
        queryParams['unidadId'] = unidadSeleccionada.unidadId.toString();
      }
      
      if (_fechaDesdeFiltro != null) {
        queryParams['fechaDesde'] = DateFormat('yyyy-MM-dd').format(_fechaDesdeFiltro!);
      }
      
      if (_fechaHastaFiltro != null) {
        queryParams['fechaHasta'] = DateFormat('yyyy-MM-dd').format(_fechaHastaFiltro!);
      }

      if (queryParams.isNotEmpty) {
        ordenes = await ordenServices.getOrden(
          context, 
          tecnicoId.toString(), 
          // "Anteriores", 
          // "Anteriores", 
          token,
          queryParams: queryParams,
        );
      } else {
        ordenes = await ordenServices.getOrden(
          context,
          tecnicoId.toString(),
          // "Anteriores",
          // "Anteriores",
          token,
        );
      }
      
      Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);
      var shortestSide = MediaQuery.of(context).size.shortestSide;
      isMobile = shortestSide < 600;
      setState(() {});
    } catch (e) {
      ordenes = [];
      setState(() {});
    }
  }

  void _aplicarFiltros(
    int? clienteId,
    int? unidadId, 
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? numeroOrden, // Nuevo parámetro
  ) {
    setState(() {
      _clienteIdFiltro = clienteId;
      _unidadIdFiltro = unidadId;
      _fechaDesdeFiltro = fechaDesde;
      _fechaHastaFiltro = fechaHasta;
      _numeroOrdenFiltro = numeroOrden; // Asignar el nuevo filtro
      _isFilterExpanded = false;
    });
    
    _filtrarYRecargarOrdenes();
  }

  void _filtrarYRecargarOrdenes() async {
    try {
      token = context.read<OrdenProvider>().token;
      tecnicoId = context.read<OrdenProvider>().tecnicoId;
      
      Map<String, dynamic> queryParams = {};
      queryParams['sort'] = 'fechaDesde DESC';
      
      // Agregar parámetros de filtro
      if (_clienteIdFiltro != null && _clienteIdFiltro! > 0) {
        queryParams['clienteId'] = _clienteIdFiltro.toString();
      }
      
      if (_unidadIdFiltro != null && _unidadIdFiltro! > 0) {
        queryParams['unidadId'] = _unidadIdFiltro.toString();
      }
      
      if (_fechaDesdeFiltro != null) {
        queryParams['fechaDesde'] = DateFormat('yyyy-MM-dd').format(_fechaDesdeFiltro!);
      }
      
      if (_fechaHastaFiltro != null) {
        queryParams['fechaHasta'] = DateFormat('yyyy-MM-dd').format(_fechaHastaFiltro!);
      }

      // AGREGAR FILTRO POR NÚMERO DE ORDEN
      if (_numeroOrdenFiltro != null && _numeroOrdenFiltro! != '') {
        queryParams['numeroOrdenTrabajo'] = _numeroOrdenFiltro.toString();
      }

      // Obtener la unidad seleccionada del provider (si existe)
      final unidadSeleccionada = context.read<OrdenProvider>().unidadSeleccionada;
      if (unidadSeleccionada.unidadId > 0 && _unidadIdFiltro == null) {
        queryParams['unidadId'] = unidadSeleccionada.unidadId.toString();
      }

      ordenes = await ordenServices.getOrden(
        context, 
        tecnicoId.toString(), 
        token,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      
      Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);
      setState(() {});
    } catch (e) {
      ordenes = [];
      setState(() {});
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _clienteIdFiltro = null;
      _unidadIdFiltro = null;
      _fechaDesdeFiltro = null;
      _fechaHastaFiltro = null;
      _numeroOrdenFiltro = null; // Resetear el nuevo filtro
      _isFilterExpanded = false;
    });
    cargarDatos();
  }

  void _toggleFiltros(bool isExpanded) {
    setState(() {
      _isFilterExpanded = isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    isAdmin = context.watch<OrdenProvider>().admOrdenes;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(
            color: colors.onPrimary
          ),
          title: const Text(
            'Ordenes',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Provider.of<OrdenProvider>(context, listen: false).setOrden(Orden.empty());
                router.push('/monitorOrdenes');
              },
              icon: const Icon(Icons.add),
              tooltip: "Nueva orden",
            ),
            IconButton(
              onPressed: () async {
                logout();
              }, 
              icon: const Icon(
                Icons.logout,
                size: 34,
              )
            )
          ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Widget de Filtros
            FiltrosOrdenes(
              onSearch: _aplicarFiltros,
              onReset: _limpiarFiltros,
              isFilterExpanded: _isFilterExpanded,
              onToggleFilter: _toggleFiltros,
              cantidadDeOrdenes: ordenes.length,
              token: token,
            ),
            
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: ordenes.length,
                  itemBuilder: (context, i) {
                    final orden = ordenes[i];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          Provider.of<OrdenProvider>(context, listen: false).clearListaPto();
                          context.read<OrdenProvider>().setOrden(orden);
                          if (isAdmin) {
                            router.push('/monitorOrdenes');
                          } else {
                            router.push('/ordenInterna');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(isMobile)...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          orden.numeroOrdenTrabajo.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          orden.fechaOrdenTrabajo != null
                                            ? DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(orden.fechaOrdenTrabajo!)
                                            : 'Fecha no disponible',
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.7,
                                          child: Text(orden.descripcion)
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Column(
                                      children: [
                                        if (MediaQuery.of(context).size.width < 1000)... [
                                          if(orden.alerta)
                                          const Icon(
                                            Icons.flag,
                                            color:Colors.red
                                          ),
                                          Text(
                                            orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(orden.estado)
                                        ]
                                        else ... [
                                          if(orden.alerta)
                                          const Icon(
                                            Icons.flag,
                                            color:Colors.red
                                          ),
                                          Text(
                                            orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              ]else...[
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          orden.numeroOrdenTrabajo.toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      orden.fechaOrdenTrabajo != null
                                        ? DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(orden.fechaOrdenTrabajo!)
                                        : 'Fecha no disponible',
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(orden.descripcion),
                                    const Spacer(),
                                    Column(
                                      children: [
                                        if (MediaQuery.of(context).size.width < 1000)... [
                                          if(orden.alerta)
                                          const Icon(
                                            Icons.flag,
                                            color:Colors.red
                                          ),
                                          Text(
                                            orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(orden.estado)
                                        ]
                                        else ... [
                                          if(orden.alerta)
                                          const Icon(
                                            Icons.flag,
                                            color:Colors.red
                                          ),
                                          Text(
                                            orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],

                                      ],
                                    ),
                                  ],
                                ),
                              ],
                              if (MediaQuery.of(context).size.width < 1000)... [
                                Text('${orden.cliente.codCliente} - ${orden.cliente.nombre}',),
                                Text(orden.comentarioCliente),
                                Text(orden.comentarioTrabajo),
                              ]else ... [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *0.2,
                                      child: Text('${orden.cliente.codCliente} - ${orden.cliente.nombre}',)
                                      ),
                                    const VerticalDivider(),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *0.3,
                                      child: Text(orden.comentarioCliente)
                                    ),
                                    const VerticalDivider(),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *0.3,
                                      child: Text(orden.comentarioTrabajo)
                                    ),
                                    const Spacer(),
                                    Text(orden.estado)
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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