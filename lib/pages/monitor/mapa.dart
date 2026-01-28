// ignore_for_file: avoid_print, prefer_final_fields, unused_field

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/delegates/cliente_search_delegate.dart';
import 'package:app_tec_sedel/models/ubicacion_mapa.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:app_tec_sedel/services/tecnico_services.dart';
import 'package:app_tec_sedel/services/ubicacion_mapa_services.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../models/cliente.dart';
import '../../../models/tecnico.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> with SingleTickerProviderStateMixin {
  Tecnico? selectedTecnico;
  Cliente? selectedCliente;
  DateTime fechaDesde = DateTime.now();
  DateTime fechaHasta = DateTime.now();
  late String token = '';

  List<Tecnico> tecnicos = [];
  int tecnicoFiltro = 0;
  int clienteFiltro = 0;
  List<UbicacionMapa> ubicaciones = [];
  Cliente? clienteSeleccionado;
  final ClientServices clientServices = ClientServices();
  Key apiKeyMap = const Key('AIzaSyDXT7F5CCCKNAok1xCYtxDX0sztOnQellM');

  List<UbicacionMapa> ubicacionesFiltradas = [];
  final LatLng currentLocation = const LatLng(-34.8927715, -56.1233649);
  late GoogleMapController mapController;
  final Map<String, Marker> _markers = {};
  List<LatLng> polylineCoordinates = [];

  TextEditingController filtroController = TextEditingController();
  late AnimationController _animationController;
  bool selectAll = true;
  int buttonIndex = 0;

  // Variables para el diseño mejorado
  bool _isExpanded = false;
  double _sidebarWidth = 500;
  final double _minSidebarWidth = 350;
  final double _maxSidebarWidth = 500;

  @override
  void initState() {
    super.initState();
    selectedCliente = Cliente.empty();
    cargarDatos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (tecnicos.isEmpty) {
      loadTecnicos();
    }
  }

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500)
    );
    print(_animationController.value);
  }

  Future<void> loadTecnicos() async {
    final token = context.watch<AuthProvider>().token;
    final loadedTecnicos = await TecnicoServices().getAllTecnicos(context, token);
    setState(() {
      tecnicos = loadedTecnicos;
    });
  }

  void toggleMapWidth() {
    if (_animationController.isDismissed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
  }

  bool get isMobile => MediaQuery.of(context).size.width < 800;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: isMobile ? _buildMobileView(colors) : _buildDesktopView(colors),
    );
  }

  // Widgets para la versión móvil
  Widget _buildMobileView(ColorScheme colors) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Ubicaciones'),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          elevation: 4,
          actions: [
            IconButton(
              onPressed: () {router.pop();},
              icon: const Icon(Icons.arrow_back)
            )
          ],
        ),
        drawer: _buildMobileDrawer(colors),
        body: _buildMobileBody(),
      ),
    );
  }

  Widget _buildMobileDrawer(ColorScheme colors) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.9,
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
                    'Filtros del Mapa',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildMobileFilterCard(
                  title: 'Filtrar por Orden',
                  child: CustomTextFormField(
                    controller: filtroController,
                    onChanged: (value) async {
                      await cargarUbicacion();
                      await cargarMarkers();
                    },
                    onFieldSubmitted: (value) async {
                      await cargarUbicacion();
                      await cargarMarkers();
                      setState(() {});
                    },
                    maxLines: 1,
                    label: 'Número de orden',
                    
                  ),
                ),
                const SizedBox(height: 16),
                _buildMobileFilterCard(
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      )
                    ),
                    items: tecnicos,
                    popupProps: PopupProps.menu(
                      showSearchBox: true, 
                      searchDelay: Duration.zero,
                      menuProps: MenuProps(
                        borderRadius: BorderRadius.circular(12),
                        elevation: 4,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedTecnico = value;
                        tecnicoFiltro = value?.tecnicoId ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildMobileFilterCard(
                  title: 'Cliente',
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Buscar cliente...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      filled: true,
                      fillColor: colors.surface,
                      suffixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    controller: TextEditingController(
                      text: clienteSeleccionado != null 
                        ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' 
                        : '',
                    ),
                    onTap: () {
                      _abrirBusquedaCliente(context);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildMobileFilterCard(
                  title: 'Rango de Fechas',
                  child: Column(
                    children: [
                      _buildMobileDateField(
                        label: 'Fecha Desde',
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
                      _buildMobileDateField(
                        label: 'Fecha Hasta',
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
                const SizedBox(height: 16),
                _buildMobileFilterCard(
                  title: 'Ubicaciones',
                  child: SizedBox(
                    height: 200,
                    child: ubicacionesFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 48,
                                  color: colors.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay ubicaciones',
                                  style: TextStyle(
                                    color: colors.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: ubicacionesFiltradas.length,
                            itemBuilder: (context, i) {
                              var ubicacion = ubicacionesFiltradas[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: ubicacion.seleccionado 
                                      ? colors.primary 
                                      : colors.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  title: Text(
                                    ubicacion.cliente.nombre,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${ubicacion.ordenTrabajoId} • ${DateFormat('HH:mm', 'es').format(ubicacion.fechaDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  secondary: Icon(
                                    Icons.location_on,
                                    color: ubicacion.seleccionado 
                                      ? colors.primary 
                                      : colors.onSurface.withOpacity(0.4),
                                  ),
                                  value: ubicacion.seleccionado,
                                  onChanged: (value) async {
                                    ubicacion.seleccionado = value!;
                                    await cargarMarkers();
                                    setState(() {});
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          String fechaDesdeStr = "${DateFormat('yyyy-MM-dd', 'es').format(fechaDesde)} 00:00:00";
                          String fechaHastaStr = "${DateFormat('yyyy-MM-dd', 'es').format(fechaHasta)} 23:59:59";
                          Map<String, dynamic> queryParams = {};
                          if (selectedTecnico != null) {
                            queryParams['tecnicoId'] = selectedTecnico?.tecnicoId;
                          }
                          queryParams['fechaDesde'] = fechaDesdeStr;
                          queryParams['fechaHasta'] = fechaHastaStr;
                          ubicaciones = await UbicacionesMapaServices().getUbicaciones(context, token, queryParams: queryParams);
                          await cargarUbicacion();
                          await cargarMarkers();
                          setState(() {});
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          selectAll = !selectAll;
                          for (var ubicacion in ubicacionesFiltradas) {
                            ubicacion.seleccionado = selectAll;
                          }
                          cargarMarkers();
                          setState(() {});
                        },
                        icon: Icon(
                          selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                        ),
                        label: Text(selectAll ? 'Desmarcar Todos' : 'Marcar Todos'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFilterCard({required String title, required Widget child}) {
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

  Widget _buildMobileDateField({
    required String label,
    required DateTime date,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  void _abrirBusquedaCliente(BuildContext context) async {
    final Cliente? resultado = await showSearch<Cliente>(
      context: context,
      delegate: ClienteSearchDelegate(
        token: token,
        clientService: clientServices,
      ),
    );

    if (resultado != null && resultado.clienteId != 0) {
      setState(() {
        clienteSeleccionado = resultado;
        clienteFiltro = resultado.clienteId;
      });
    }
  }

  Widget _buildMobileBody() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          GoogleMap(
            key: apiKeyMap,
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            markers: _markers.values.toSet(),
            polylines: {
              Polyline(
                polylineId: const PolylineId('polyline'),
                color: Theme.of(context).colorScheme.primary,
                width: 3,
                points: polylineCoordinates,
              ),
            },
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
        ],
      )
    );
  }

  // Widgets para la versión desktop
  Widget _buildDesktopView(ColorScheme colors) {
    return SafeArea(
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar con filtros
            _buildDesktopSidebar(colors),
            // Mapa principal
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    key: apiKeyMap,
                    initialCameraPosition: CameraPosition(
                      target: currentLocation,
                      zoom: 14.0,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    markers: _markers.values.toSet(),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('polyline'),
                        color: colors.primary,
                        width: 3,
                        points: polylineCoordinates,
                      ),
                    },
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                  // Controles superiores
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.map,
                              color: colors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Mapa de Ubicaciones en Tiempo Real',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => router.pop(),
                              icon: const Icon(Icons.arrow_back),
                              tooltip: 'Volver',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Información de ubicaciones
                  if (ubicacionesFiltradas.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${ubicacionesFiltradas.where((u) => u.seleccionado).length} ubicaciones seleccionadas',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildDesktopSidebar(ColorScheme colors) {
    return Container(
      width: _sidebarWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(
            color: colors.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del sidebar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: colors.onPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Filtros del Mapa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // IconButton(
                //   icon: Icon(
                //     _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                //     color: colors.onPrimary,
                //   ),
                //   onPressed: () {
                //     setState(() {
                //       _isExpanded = !_isExpanded;
                //       _sidebarWidth = _isExpanded ? _maxSidebarWidth : _minSidebarWidth;
                //     });
                //   },
                //   tooltip: _isExpanded ? 'Contraer' : 'Expandir',
                // ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro por número de orden
                  _buildDesktopFilterSection(
                    title: 'Búsqueda Rápida',
                    icon: Icons.search,
                    child: CustomTextFormField(
                      controller: filtroController,
                      onChanged: (value) {
                        cargarUbicacion();
                        cargarMarkers();
                      },
                      onFieldSubmitted: (value) {
                        cargarUbicacion();
                        cargarMarkers();
                        setState(() {});
                      },
                      maxLines: 1,
                      label: 'Filtrar por número de orden',
                      
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filtro por técnico
                  _buildDesktopFilterSection(
                    title: 'Técnico Asignado',
                    icon: Icons.person_search,
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
                          prefixIcon: const Icon(Icons.person),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        )
                      ),
                      items: tecnicos,
                      popupProps: PopupProps.menu(
                        showSearchBox: true, 
                        searchDelay: Duration.zero,
                        menuProps: MenuProps(
                          borderRadius: BorderRadius.circular(12),
                          elevation: 4,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedTecnico = value;
                          tecnicoFiltro = value?.tecnicoId ?? 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filtro por cliente
                  _buildDesktopFilterSection(
                    title: 'Cliente',
                    icon: Icons.business,
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Buscar cliente...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.outline),
                        ),
                        filled: true,
                        fillColor: colors.surface,
                        suffixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      controller: TextEditingController(
                        text: clienteSeleccionado != null 
                          ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' 
                          : '',
                      ),
                      onTap: () {
                        _abrirBusquedaCliente(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Filtro por fechas
                  _buildDesktopFilterSection(
                    title: 'Rango de Fechas',
                    icon: Icons.calendar_month,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDesktopDateField(
                            label: 'Desde',
                            date: fechaDesde,
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: fechaDesde,
                                firstDate: DateTime(2022),
                                lastDate: DateTime(2099),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  fechaDesde = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDesktopDateField(
                            label: 'Hasta',
                            date: fechaHasta,
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: fechaHasta,
                                firstDate: DateTime(2022),
                                lastDate: DateTime(2099),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  fechaHasta = pickedDate;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            String fechaDesdeStr = "${DateFormat('yyyy-MM-dd', 'es').format(fechaDesde)} 00:00:00";
                            String fechaHastaStr = "${DateFormat('yyyy-MM-dd', 'es').format(fechaHasta)} 23:59:59";
                            Map<String, dynamic> queryParams = {};
                            if (selectedTecnico != null) {
                              queryParams['tecnicoId'] = selectedTecnico?.tecnicoId;
                            }
                            queryParams['fechaDesde'] = fechaDesdeStr;
                            queryParams['fechaHasta'] = fechaHastaStr;
                            ubicaciones = await UbicacionesMapaServices().getUbicaciones(context, token, queryParams: queryParams);
                            await cargarUbicacion();
                            await cargarMarkers();
                            setState(() {});
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar Ubicaciones'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            selectAll = !selectAll;
                            for (var ubicacion in ubicacionesFiltradas) {
                              ubicacion.seleccionado = selectAll;
                            }
                            cargarMarkers();
                            setState(() {});
                          },
                          icon: Icon(
                            selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                          ),
                          label: Text(selectAll ? 'Desmarcar Todos' : 'Marcar Todos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Lista de ubicaciones
                  _buildDesktopFilterSection(
                    title: 'Ubicaciones Encontradas',
                    icon: Icons.location_on,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${ubicacionesFiltradas.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 400,
                          child: ubicacionesFiltradas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        size: 60,
                                        color: colors.onSurface.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay ubicaciones',
                                        style: TextStyle(
                                          color: colors.onSurface.withOpacity(0.5),
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Aplica filtros y haz clic en "Buscar Ubicaciones"',
                                        style: TextStyle(
                                          color: colors.onSurface.withOpacity(0.4),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: ubicacionesFiltradas.length,
                                  itemBuilder: (context, i) {
                                    var ubicacion = ubicacionesFiltradas[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: ubicacion.seleccionado 
                                            ? colors.primary 
                                            : colors.outline.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: ubicacion.seleccionado 
                                              ? colors.primary.withOpacity(0.1)
                                              : colors.surface,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: ubicacion.seleccionado 
                                                ? colors.primary 
                                                : colors.outline.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${ubicacion.ordenTrabajoId}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: ubicacion.seleccionado 
                                                  ? colors.primary 
                                                  : colors.onSurface,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          ubicacion.cliente.nombre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: colors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${DateFormat('HH:mm', 'es').format(ubicacion.fechaDate)} • ${ubicacion.estado}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.onSurface.withOpacity(0.6),
                                              ),
                                            ),
                                            if (_isExpanded && ubicacion.tecnico.nombre.isNotEmpty)
                                              Text(
                                                'Téc: ${ubicacion.tecnico.nombre}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.onSurface.withOpacity(0.5),
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Checkbox(
                                          value: ubicacion.seleccionado,
                                          onChanged: (value) {
                                            ubicacion.seleccionado = value!;
                                            setState(() {
                                              cargarMarkers();
                                            });
                                          },
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        onTap: () {
                                          ubicacion.seleccionado = !ubicacion.seleccionado;
                                          setState(() {
                                            cargarMarkers();
                                          });
                                        },
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    );
                                  }
                                ),
                        ),
                      ],
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

  Widget _buildDesktopFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDesktopDateField({
    required String label,
    required DateTime date,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métodos comunes
  addMarker(String id, LatLng location, String title, String snippet) {
    var marker = Marker(
      markerId: MarkerId(id),
      position: location,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
    );
    _markers[id] = marker;
    polylineCoordinates.add(location);
  }

  cargarMarkers() {
    _markers.clear();
    polylineCoordinates.clear();
    for (var ubicacion in ubicacionesFiltradas) {
      var coord = ubicacion.ubicacion?.split(',');

      if (ubicacion.seleccionado) {
        if (coord != null && coord.length >= 2) {
          addMarker(
            ubicacion.logId.toString(),
            LatLng(double.parse(coord[0]), double.parse(coord[1])),
            ubicacion.cliente.nombre,
            'Orden: ${ubicacion.ordenTrabajoId} • ${DateFormat('HH:mm', 'es').format(ubicacion.fechaDate)} • ${ubicacion.estado}'
          );
        } else {
          print('Error: Coordenadas no formateadas correctamente');
        }
      }
    }
  }

  cargarUbicacion() {
    ubicacionesFiltradas = ubicaciones.where((e) =>
      (clienteFiltro > 0 ? e.cliente.clienteId == clienteFiltro : true) &&
      (tecnicoFiltro > 0 ? e.tecnico.tecnicoId == tecnicoFiltro : true) &&
      e.ubicacion != '' &&
      (filtroController.text.isEmpty || e.ordenTrabajoId.toString().contains(filtroController.text)))
    .toList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    filtroController.dispose();
    super.dispose();
  }
}