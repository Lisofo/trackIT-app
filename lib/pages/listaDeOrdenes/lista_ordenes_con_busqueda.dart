import 'package:app_tec_sedel/main.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:flutter/cupertino.dart';
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
  int groupValue = 0; // 0=PENDIENTE, 1=RECIBIDO, 2=APROBADO
  List trabajodres = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool datosCargados = false;
  bool isAdmin = false;

  // Variables para los filtros
  bool _isFilterExpanded = false;
  int? _clienteIdFiltro;
  int? _unidadIdFiltro;
  DateTime? _fechaDesdeFiltro;
  DateTime? _fechaHastaFiltro;
  String? _numeroOrdenFiltro;
  
  // Estados disponibles
  List<String> estados = ['PENDIENTE', 'RECIBIDO', 'APROBADO'];

  @override
  void initState() {
    super.initState();
    token = context.read<AuthProvider>().token;
    tecnicoId = context.read<AuthProvider>().tecnicoId;
    // Establecer estado inicial como PENDIENTE (groupValue = 0)
    groupValue = 0;
    
    // Verificar si hay una unidad seleccionada (viene desde MonitorVehiculos)
    final unidadSeleccionada = context.read<OrdenProvider>().unidadSeleccionada;
    // Verificar si hay un cliente seleccionado (viene desde MonitorClientes)
    final clienteSeleccionado = context.read<OrdenProvider>().cliente;
    
    // Cargar datos automáticamente con estado PENDIENTE por defecto
    if (unidadSeleccionada.unidadId > 0 || clienteSeleccionado.clienteId > 0) {
      // Si hay unidad o cliente seleccionado, cargar datos automáticamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cargarDatos();
      });
    }
  }

  // Método para determinar el tipo de dispositivo
  bool _esMovil(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide < 600;
  }

  bool _esTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600 && shortestSide < 1200;
  }

  bool _esEscritorio(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 1200;
  }

  // 2. Método para manejar la actualización de datos
  Future<void> _refreshData() async {
    ordenes = [];
    setState(() {});
    await cargarDatos();
  }

  cargarDatos() async {
    try {
      datosCargados = true;
      
      // Limpiar filtros previos cuando viene desde monitor vehículos o clientes
      final unidadSeleccionada = context.read<OrdenProvider>().unidadSeleccionada;
      final clienteSeleccionado = context.read<OrdenProvider>().cliente;
      
      if (unidadSeleccionada.unidadId > 0 || clienteSeleccionado.clienteId > 0) {
        _clienteIdFiltro = null;
        _fechaDesdeFiltro = null;
        _fechaHastaFiltro = null;
        _numeroOrdenFiltro = null;
      }
      
      // Obtener la unidad y cliente seleccionados del provider
      Map<String, dynamic> queryParams = {};
      queryParams['sort'] = 'fechaDesde DESC';
      
      // AGREGAR FILTRO POR ESTADO (PENDIENTE por defecto)
      queryParams['estado'] = estados[groupValue];

      queryParams['tecnicoId'] = tecnicoId.toString();
      
      // Agregar parámetros de filtro si existen
      if (_clienteIdFiltro != null && _clienteIdFiltro! > 0) {
        queryParams['clienteId'] = _clienteIdFiltro.toString();
      } else if (clienteSeleccionado.clienteId > 0) {
        queryParams['clienteId'] = clienteSeleccionado.clienteId.toString();
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
          token,
          queryParams: queryParams,
        );
      } else {
        ordenes = await ordenServices.getOrden(
          context,
          tecnicoId.toString(),
          token,
        );
      }
      
      Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);
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
    String? numeroOrden,
  ) {
    setState(() {
      _clienteIdFiltro = clienteId;
      _unidadIdFiltro = unidadId;
      _fechaDesdeFiltro = fechaDesde;
      _fechaHastaFiltro = fechaHasta;
      _numeroOrdenFiltro = numeroOrden;
      _isFilterExpanded = false;
    });
    
    _filtrarYRecargarOrdenes();
  }

  void _filtrarYRecargarOrdenes() async {
    try {
      token = context.read<AuthProvider>().token;
      tecnicoId = context.read<AuthProvider>().tecnicoId;
      
      Map<String, dynamic> queryParams = {};
      queryParams['sort'] = 'fechaDesde DESC';
      
      // AGREGAR FILTRO POR ESTADO
      queryParams['estado'] = estados[groupValue];

      queryParams['tecnicoId'] = tecnicoId.toString();
      
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
      _numeroOrdenFiltro = null;
      groupValue = 0; // Resetear a PENDIENTE
      _isFilterExpanded = false;
    });
    cargarDatos();
  }

  void _toggleFiltros(bool isExpanded) {
    setState(() {
      _isFilterExpanded = isExpanded;
    });
  }

  // Widget para construir el encabezado de la orden según el dispositivo
  Widget _buildOrdenHeader(BuildContext context, Orden orden) {
    final esMovil = _esMovil(context);
    final esTablet = _esTablet(context);
    // ignore: unused_local_variable
    final esEscritorio = _esEscritorio(context);
    
    if (esMovil) {
      return _buildMovilHeader(orden, context);
    } else if (esTablet) {
      return _buildTabletHeader(orden, context);
    } else {
      return _buildEscritorioHeader(orden, context);
    }
  }

  Widget _buildMovilHeader(Orden orden, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orden.numeroOrdenTrabajo.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orden.fechaOrdenTrabajo != null
                      ? DateFormat('dd/MM/yyyy HH:mm', 'es').format(orden.fechaOrdenTrabajo!)
                      : 'Fecha no disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (orden.alerta != null && orden.alerta == true)
              const Icon(Icons.flag, color: Colors.red, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        if (orden.descripcion != null && orden.descripcion!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              orden.descripcion.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (orden.matricula != null && orden.matricula!.isNotEmpty)
              Text(
                orden.matricula!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            Text(
              orden.estado ?? "",
              style: TextStyle(
                color: _getEstadoColor(orden.estado),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletHeader(Orden orden, BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orden.numeroOrdenTrabajo.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                orden.fechaOrdenTrabajo != null
                  ? DateFormat('dd/MM/yyyy HH:mm', 'es').format(orden.fechaOrdenTrabajo!)
                  : 'Fecha no disponible',
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              orden.descripcion ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (orden.alerta != null && orden.alerta == true)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.flag, color: Colors.red),
                ),
              if (orden.matricula != null && orden.matricula!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    orden.matricula!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              Text(
                orden.estado ?? "",
                style: TextStyle(
                  color: _getEstadoColor(orden.estado),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEscritorioHeader(Orden orden, BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            orden.numeroOrdenTrabajo.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 180,
          child: Text(
            orden.fechaOrdenTrabajo != null
              ? DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(orden.fechaOrdenTrabajo!)
              : 'Fecha no disponible',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(orden.descripcion ?? ''),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            if (orden.alerta != null && orden.alerta == true)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.flag, color: Colors.red),
              ),
            if (orden.matricula != null && orden.matricula!.isNotEmpty)
              SizedBox(
                width: 100,
                child: Text(
                  orden.matricula!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: Text(
                orden.estado ?? "",
                style: TextStyle(
                  color: _getEstadoColor(orden.estado),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget para construir la información del cliente según el dispositivo
  Widget _buildClienteInfo(BuildContext context, Orden orden) {
    final esMovil = _esMovil(context);
    final esTablet = _esTablet(context);
    // ignore: unused_local_variable
    final esEscritorio = _esEscritorio(context);
    
    if (esMovil || esTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '${orden.cliente?.codCliente} - ${orden.cliente?.nombre}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (orden.comentarioCliente != null && orden.comentarioCliente!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                orden.comentarioCliente!,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (orden.comentarioTrabajo != null && orden.comentarioTrabajo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                orden.comentarioTrabajo!,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${orden.cliente?.codCliente} - ${orden.cliente?.nombre}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  orden.comentarioCliente ?? '',
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                orden.comentarioTrabajo ?? '',
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getEstadoColor(String? estado) {
    if (estado == null) return Colors.black;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'recibido':
      case 'en proceso':
        return Colors.blue;
      case 'aprobado':
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    isAdmin = context.watch<OrdenProvider>().admOrdenes;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(color: colors.onPrimary),
          title: const Text(
            'Órdenes',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            if (isAdmin)
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
              icon: const Icon(Icons.logout)
            )
          ],
        ),
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
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
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: CupertinoSegmentedControl<int>(
                    groupValue: groupValue,
                    borderColor: Colors.black,
                    selectedColor: colors.primary,
                    unselectedColor: Colors.white,
                    children: {
                      0: buildSegment('Pendiente'),
                      1: buildSegment('Recibido'),
                      2: buildSegment('Aprobado'),
                    },
                    onValueChanged: (newValue) {
                      setState(() {
                        groupValue = newValue;
                        // Actualizar datos cuando se cambia el estado
                        _filtrarYRecargarOrdenes();
                      });
                    },
                  ),
                ),
                
                Expanded(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _refreshData,
                    child: ordenes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth < 600 ? 8.0 : 16.0,
                              vertical: 8.0,
                            ),
                            itemCount: ordenes.length,
                            itemBuilder: (context, i) {
                              final orden = ordenes[i];
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: constraints.maxWidth < 600 ? 4.0 : 8.0,
                                  vertical: 6.0,
                                ),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () {
                                    Provider.of<OrdenProvider>(context, listen: false).clearListaPto();
                                    context.read<OrdenProvider>().setOrden(orden);
                                    if (isAdmin) {
                                      router.push('/monitorOrdenes');
                                    } else {
                                      if (flavor == 'parabrisasejido') {
                                        router.push('/ordenInternaVertical');
                                      } else {
                                        router.push('/ordenInternaHorizontalw');
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      constraints.maxWidth < 600 ? 12.0 : 16.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildOrdenHeader(context, orden),
                                        _buildClienteInfo(context, orden),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay órdenes disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Intenta ajustar los filtros o crear una nueva orden',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          text,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro de querer cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('CANCELAR')
            ),
            TextButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).setToken('');
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