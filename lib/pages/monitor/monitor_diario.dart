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
    'En proceso',
    'Finalizado',
  ];
  late String token = '';
  Tecnico? selectedTecnico;
  final _ordenServices = OrdenServices();
  DateTime fechaDesde = DateTime.now();
  DateTime fechaHasta = DateTime.now();
  int tecnicoFiltro = 0;
  int clienteFiltro = 0;
  List<Orden> ordenesPendientes = [];
  List<Orden> ordenesEnProceso = [];
  List<Orden> ordenesFinalizadas = [];
  List<Orden> ordenesRevisadas = [];
  
  // Colores mejorados con paleta profesional
  Map<String, Color> coloresEstado = {
    'Pendiente': const Color(0xFFFFE082), // Amarillo suave
    'En proceso': const Color(0xFF81C784),  // Verde suave
    'Finalizado': const Color(0xFFEF9A9A),  // Rojo suave
  };
  
  Map<String, Color> coloresBorde = {
    'Pendiente': const Color(0xFFFFB74D),
    'En proceso': const Color(0xFF66BB6A),
    'Finalizado': const Color(0xFFEF5350),
  };
  
  Map<String, Color> coloresCampanita = {
    'PENDIENTE': const Color(0xFFFFE082),
    'EN PROCESO': const Color(0xFF81C784),
    'FINALIZADO': const Color(0xFFEF9A9A),
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
    ordenesCampanita = await OrdenServices().getOrdenCampanita(context, desde, hasta, 'PENDIENTE, EN PROCESO, FINALIZADO', 1, token);
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
  

  String tecnicoId = selectedTecnico != null && selectedTecnico!.tecnicoId > 0 
    ? selectedTecnico!.tecnicoId.toString() 
    : '';
  
  // MODIFICADO: Usar fechaDesde y fechaHasta
  String desdeStr = DateFormat('yyyy-MM-dd', 'es').format(fechaDesde);
  String hastaStr = DateFormat('yyyy-MM-dd', 'es').format(fechaHasta);
  
  // Preparar los parámetros de consulta
  Map<String, dynamic> queryParams = {};
  
  // Agregar filtros
  if (clienteSeleccionado.clienteId != 0) {
    queryParams['clienteId'] = clienteSeleccionado.clienteId.toString();
  }

  if (tecnicoId.isNotEmpty) {
    queryParams['tecnicoId'] = tecnicoId;
  }

  queryParams['fechaDesde'] = desdeStr;
  queryParams['fechaHasta'] = hastaStr;
  
  
  try {
    List<Orden> results = await _ordenServices.getOrden(
      context, 
      tecnicoId,
      token,
      queryParams: queryParams,
      desde: desdeStr,
      hasta: hastaStr,
    );
    
    setState(() {
      ordenes = results;
    });
    cargarListas();
  } catch (e) {
    print('Error al buscar órdenes: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al buscar órdenes: ${e.toString()}'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )
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
        case 'EN PROCESO':
          ordenesEnProceso.add(orden);
          break;
        case 'FINALIZADO':
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
    ordenesCampanita = await OrdenServices().getOrdenCampanita(context, desde, hasta, 'PENDIENTE, FINALIZADO, EN PROCESO', 1000, token);
    
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              "Órdenes a Revisar",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          content: Container(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: isMobile 
                    ? MediaQuery.of(context).size.height * 0.75
                    : MediaQuery.of(context).size.height * 0.68,
                  width: isMobile 
                    ? MediaQuery.of(context).size.width * 0.8
                    : MediaQuery.of(context).size.width * 0.4,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (var i = 0; i < ordenesCampanita.length; i++)
                          _buildCampanitaCard(ordenesCampanita[i], isMobile, context),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: (){router.pop();},
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ), 
              child: const Text('Cerrar'),
            )
          ],
        );
      },
    );
  }

  Widget _buildCampanitaCard(Orden orden, bool isMobile, BuildContext context) {
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: coloresCampanita[orden.estado]!,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            Provider.of<OrdenProvider>(context, listen: false).setOrden(orden);
            Navigator.of(context).pop();
            router.push('/editOrden');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: coloresCampanita[orden.estado],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${orden.ordenTrabajoId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _getEstadoIcon(orden.estado),
                      color: coloresCampanita[orden.estado],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  orden.cliente!.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orden.tecnico!.nombre,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        orden.fechaDesde != null 
                          ? DateFormat("dd/MM/yyyy HH:mm", 'es').format(orden.fechaDesde!)
                          : 'Sin fecha',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: coloresCampanita[orden.estado]!,
            width: 2,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: coloresCampanita[orden.estado],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${orden.ordenTrabajoId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          title: Text(
            orden.cliente!.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orden.tecnico!.nombre),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    orden.fechaDesde != null 
                      ? DateFormat("dd/MM/yyyy HH:mm", 'es').format(orden.fechaDesde!)
                      : 'Sin fecha',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            _getEstadoIcon(orden.estado),
            color: coloresCampanita[orden.estado],
          ),
          onTap: () {
            Provider.of<OrdenProvider>(context, listen: false).setOrden(orden);
            Navigator.of(context).pop();
            router.push('/editOrden');
          },
        ),
      );
    }
  }

  IconData _getEstadoIcon(String? estado) {
    switch (estado?.toUpperCase()) {
      case 'PENDIENTE':
        return Icons.pending;
      case 'EN PROCESO':
        return Icons.play_arrow;
      case 'FINALIZADO':
        return Icons.check_circle;
      default:
        return Icons.question_mark;
    }
  }

  Widget cardsDeLaLista(List<Orden> orden, int index, String estado) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: coloresBorde[estado] ?? Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Provider.of<OrdenProvider>(context, listen: false).setOrden(orden[index]);
          router.push('/editOrden');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                coloresEstado[estado]!.withOpacity(0.1),
                coloresEstado[estado]!.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: coloresEstado[estado],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${orden[index].ordenTrabajoId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Icon(
                      _getEstadoIcon(orden[index].estado),
                      color: coloresEstado[estado],
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        orden[index].tecnico?.nombre ?? 'Sin técnico',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${orden[index].cliente?.codCliente} - ${orden[index].cliente?.nombre}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_circle_down,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Inicio:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            orden[index].fechaDesde != null 
                              ? DateFormat("dd/MM/yyyy HH:mm", 'es').format(orden[index].fechaDesde!)
                              : 'No programado',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_circle_up,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Fin:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            orden[index].fechaHasta != null 
                              ? DateFormat("dd/MM/yyyy HH:mm", 'es').format(orden[index].fechaHasta!)
                              : 'No programado',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if(orden[index].estado != 'PENDIENTE') ...[
                  Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 14,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Iniciada: ${_formatDateAndTime(orden[index].iniciadaEn)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  if(orden[index].estado != 'EN PROCESO')
                  Row(
                    children: [
                      Icon(
                        Icons.stop,
                        size: 14,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Finalizada: ${_formatDateAndTime(orden[index].finalizadaEn)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    orden[index].tipoOrden?.descripcion ?? 'Sin tipo',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoContainer(String estado, List<Orden> ordenesEstado) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    coloresEstado[estado]!.withOpacity(0.8),
                    coloresEstado[estado]!,
                  ],
              ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: coloresEstado[estado]!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    estado.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${ordenesEstado.length}',
                      style: TextStyle(
                        color: coloresEstado[estado],
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ordenesEstado.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 60,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay órdenes $estado',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int index = 0; index < ordenesEstado.length; index++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: cardsDeLaLista(ordenesEstado, index, estado),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitor de Órdenes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        foregroundColor: colors.onPrimary,
        backgroundColor: colors.primary,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {router.pop();},
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          )
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(16),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withOpacity(0.05),
                colors.primary.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Filtros de Búsqueda',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFilterCard(
                    title: 'Técnico',
                    child: DropdownSearch<Tecnico>(
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: 'Seleccione un técnico',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.outline),
                          ),
                          filled: true,
                          fillColor: colors.surface,
                          prefixIcon: const Icon(Icons.person_search),
                        ),
                      ),
                      items: tecnicos,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchDelay: Duration.zero,
                        menuProps: MenuProps(
                          borderRadius: BorderRadius.circular(12),
                          elevation: 4,
                        ),
                        containerBuilder: (context, popupWidget) {
                          return Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: popupWidget,
                          );
                        },
                      ),
                      itemAsString: (Tecnico t) => t.nombre,
                      onChanged: (value) {
                        setState(() {
                          selectedTecnico = value;
                          tecnicoFiltro = value?.tecnicoId ?? 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterCard(
                    title: 'Cliente',
                    child: InkWell(
                      onTap: _mostrarBusquedaCliente,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.outline),
                          borderRadius: BorderRadius.circular(12),
                          color: colors.surface,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: clienteSeleccionado.clienteId > 0 
                                ? colors.primary 
                                : colors.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clienteSeleccionado.clienteId > 0 
                                      ? clienteSeleccionado.nombre
                                      : 'Buscar cliente...',
                                    style: TextStyle(
                                      color: clienteSeleccionado.clienteId > 0 
                                        ? colors.primary 
                                        : colors.onSurface.withOpacity(0.7),
                                      fontWeight: clienteSeleccionado.clienteId > 0 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                    ),
                                  ),
                                  if (clienteSeleccionado.clienteId > 0)
                                    Text(
                                      clienteSeleccionado.nombreFantasia,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (clienteSeleccionado.clienteId > 0)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
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
                  ),
                  const SizedBox(height: 16),
                  _buildFilterCard(
                    title: 'Rango de Fechas',
                    child: Column(
                      children: [
                        _buildDatePickerField(
                          context: context,
                          label: 'Desde',
                          date: fechaDesde,
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: fechaDesde,
                              firstDate: DateTime(2022),
                              lastDate: DateTime(2099),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    dialogBackgroundColor: colors.background,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null && pickedDate != fechaDesde) {
                              setState(() {
                                fechaDesde = pickedDate;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildDatePickerField(
                          context: context,
                          label: 'Hasta',
                          date: fechaHasta,
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: fechaHasta,
                              firstDate: DateTime(2022),
                              lastDate: DateTime(2099),
                            );
                            if (pickedDate != null && pickedDate != fechaHasta) {
                              setState(() {
                                fechaHasta = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await buscar(token);
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text(
                        'BUSCAR ÓRDENES',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: colors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
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
          _buildEstadoContainer('En proceso', ordenesEnProceso),
          _buildEstadoContainer('Finalizado', ordenesFinalizadas),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          ordenesARevisar(context);
        },
        icon: ordenesCampanita.isEmpty 
          ? const Icon(Icons.notifications_none)
          : Badge(
              label: Text(
                ordenesCampanita.length > 99 ? '99+' : '${ordenesCampanita.length}',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.notifications_active),
            ),
        label: const Text('Revisar'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _pageIndex,
          onTap: (index) {
            setState(() {
              _pageIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          showUnselectedLabels: true,
          selectedItemColor: colors.primary,
          unselectedItemColor: colors.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.pending_actions),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pending_actions),
              ),
              label: 'Pendiente',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.play_arrow),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow),
              ),
              label: 'En proceso',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.done_all),
              activeIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done_all),
              ),
              label: 'Finalizado',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime date,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopView(ColorScheme colors) {
    return Scaffold(
      body: SingleChildScrollView( // ← AÑADIDO Scroll general
        child: Column(
          children: [
            // Header superior
            Container(
              decoration: BoxDecoration(
                color: colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => router.pop(),
                            tooltip: 'Volver',
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Monitoreo de Órdenes de Trabajo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _buildNotificationButton(colors),
                        ],
                      ),
                      const SizedBox(height: 12), // ← REDUCIDO de 20 a 12
                    ],
                  ),
                ),
              ),
            ),
            // Filtros compactos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ← MENOS espacio vertical
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16), // ← REDUCIDO de 20 a 16
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterFieldCompact( // ← NUEVO método compacto
                              label: 'Técnico',
                              icon: Icons.person_search,
                              child: DropdownSearch<Tecnico>(
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    hintText: 'Seleccione un técnico',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: colors.outline),
                                    ),
                                    filled: true,
                                    fillColor: colors.surface,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ← COMPACTO
                                    isDense: true,
                                  ),
                                ),
                                items: tecnicos,
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchDelay: Duration.zero,
                                  menuProps: MenuProps(
                                    borderRadius: BorderRadius.circular(8),
                                    elevation: 4,
                                  ),
                                  containerBuilder: (context, popupWidget) {
                                    return Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: popupWidget,
                                    );
                                  },
                                ),
                                itemAsString: (Tecnico t) => t.nombre,
                                onChanged: (value) {
                                  setState(() {
                                    selectedTecnico = value;
                                    tecnicoFiltro = value?.tecnicoId ?? 0;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12), // ← REDUCIDO de 20 a 12
                          Expanded(
                            flex: 2,
                            child: _buildFilterFieldCompact(
                              label: 'Cliente',
                              icon: Icons.business,
                              child: InkWell(
                                onTap: _mostrarBusquedaCliente,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ← COMPACTO
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colors.outline),
                                    borderRadius: BorderRadius.circular(8),
                                    color: colors.surface,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.business,
                                        size: 18, // ← REDUCIDO
                                        color: clienteSeleccionado.clienteId > 0 
                                          ? colors.primary 
                                          : colors.onSurface.withOpacity(0.5),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              clienteSeleccionado.clienteId > 0 
                                                ? clienteSeleccionado.nombre
                                                : 'Buscar cliente...',
                                              style: TextStyle(
                                                fontSize: 14, // ← COMPACTO
                                                color: clienteSeleccionado.clienteId > 0 
                                                  ? colors.primary 
                                                  : colors.onSurface.withOpacity(0.7),
                                                fontWeight: clienteSeleccionado.clienteId > 0 
                                                  ? FontWeight.w600 
                                                  : FontWeight.normal,
                                              ),
                                            ),
                                            if (clienteSeleccionado.clienteId > 0)
                                              Text(
                                                clienteSeleccionado.nombreFantasia,
                                                style: TextStyle(
                                                  fontSize: 11, // ← COMPACTO
                                                  color: colors.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (clienteSeleccionado.clienteId > 0)
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 16), // ← REDUCIDO
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
                            ),
                          ),
                          const SizedBox(width: 12), // ← REDUCIDO
                          Expanded(
                            child: _buildDateFieldCompact(
                              context: context,
                              label: 'Desde',
                              date: fechaDesde,
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: fechaDesde,
                                  firstDate: DateTime(2022),
                                  lastDate: DateTime(2099),
                                );
                                if (pickedDate != null && pickedDate != fechaDesde) {
                                  setState(() {
                                    fechaDesde = pickedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12), // ← REDUCIDO
                          Expanded(
                            child: _buildDateFieldCompact(
                              context: context,
                              label: 'Hasta',
                              date: fechaHasta,
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: fechaHasta,
                                  firstDate: DateTime(2022),
                                  lastDate: DateTime(2099),
                                );
                                if (pickedDate != null && pickedDate != fechaHasta) {
                                  setState(() {
                                    fechaHasta = pickedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12), // ← REDUCIDO
                          SizedBox(
                            width: 120, // ← REDUCIDO de 200 a 120
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await buscar(token);
                              },
                              icon: const Icon(Icons.search, size: 18), // ← REDUCIDO
                              label: const Text('BUSCAR', style: TextStyle(fontSize: 12)), // ← COMPACTO
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10), // ← COMPACTO
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                backgroundColor: colors.primary,
                                foregroundColor: colors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado de resumen
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // ← COMPACTO
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Resumen de Órdenes',
                          style: TextStyle(
                            fontSize: 16, // ← REDUCIDO
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            _buildResumenChipCompact( // ← NUEVO método compacto
                              count: ordenesPendientes.length,
                              label: 'PENDIENTES',
                              color: coloresEstado['Pendiente']!,
                            ),
                            const SizedBox(width: 8),
                            _buildResumenChipCompact(
                              count: ordenesEnProceso.length,
                              label: 'RECIBIDAS',
                              color: coloresEstado['En proceso']!,
                            ),
                            const SizedBox(width: 8),
                            _buildResumenChipCompact(
                              count: ordenesFinalizadas.length,
                              label: 'APROBADAS',
                              color: coloresEstado['Finalizado']!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Grid de órdenes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildEstadoColumnCompact(
                          estado: 'Pendiente',
                          ordenes: ordenesPendientes,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEstadoColumnCompact(
                          estado: 'En proceso',
                          ordenes: ordenesEnProceso,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEstadoColumnCompact(
                          estado: 'Finalizado',
                          ordenes: ordenesFinalizadas,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32), // ← Espacio al final para mejor scroll
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterFieldCompact({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary), // ← REDUCIDO
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12, // ← REDUCIDO
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // ← REDUCIDO
        child,
      ],
    );
  }

  Widget _buildDateFieldCompact({
    required BuildContext context,
    required String label,
    required DateTime date,
    required Function() onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF4F46E5)), // ← REDUCIDO
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12, // ← REDUCIDO
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6), // ← REDUCIDO
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ← COMPACTO
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16, // ← REDUCIDO
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13, // ← COMPACTO
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenChipCompact({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // ← COMPACTO
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, // ← REDUCIDO
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14, // ← REDUCIDO
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10, // ← REDUCIDO
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoColumnCompact({
    required String estado,
    required List<Orden> ordenes,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la columna
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // ← COMPACTO
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  coloresEstado[estado]!.withOpacity(0.8),
                  coloresEstado[estado]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getEstadoIcon(estado),
                      color: Colors.white,
                      size: 20, // ← REDUCIDO
                    ),
                    const SizedBox(width: 8),
                    Text(
                      estado.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14, // ← REDUCIDO
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // ← COMPACTO
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${ordenes.length}',
                    style: TextStyle(
                      color: coloresEstado[estado],
                      fontWeight: FontWeight.w800,
                      fontSize: 14, // ← REDUCIDO
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de órdenes
          Container(
            padding: const EdgeInsets.all(12), // ← COMPACTO
            child: ordenes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 40, // ← REDUCIDO
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No hay órdenes $estado',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 14, // ← REDUCIDO
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (int index = 0; index < ordenes.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: cardsDeLaLista(ordenes, index, estado),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(ColorScheme colors) {
    return Stack(
      children: [
        IconButton(
          onPressed: () async {
            await ordenesARevisar(context);
          },
          icon: Container(
            width: 40, // ← REDUCIDO
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: ordenesCampanita.isEmpty
                  ? const Icon(Icons.notifications_none, color: Colors.white, size: 20)
                  : const Icon(Icons.notifications_active, color: Colors.white, size: 20),
            ),
          ),
          tooltip: 'Órdenes a revisar',
        ),
        if (ordenesCampanita.isNotEmpty)
          Positioned(
            right: 6, // ← AJUSTADO
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                ordenesCampanita.length > 99 ? '99+' : ordenesCampanita.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}