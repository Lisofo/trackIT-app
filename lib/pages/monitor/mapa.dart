// ignore_for_file: avoid_print

import 'package:app_tec_sedel/delegates/cliente_search_delegate.dart';
import 'package:app_tec_sedel/models/ubicacion_mapa.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:app_tec_sedel/services/tecnico_services.dart';
import 'package:app_tec_sedel/services/ubicacion_mapa_services.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:app_tec_sedel/widgets/drawer.dart';
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
  DateTime selectedDate = DateTime.now();
  late String token = '';

  List<Tecnico> tecnicos = [];
  int tecnicoFiltro = 0;
  int clienteFiltro = 0;
  List<UbicacionMapa> ubicaciones = [];

  // Eliminado: Key apiKeyMap = const Key('AIzaSyDXT7F5CCCKNAok1xCYtxDX0sztOnQellM');
  final String googleMapsApiKey = 'AIzaSyDXT7F5CCCKNAok1xCYtxDX0sztOnQellM';

  List<UbicacionMapa> ubicacionesFiltradas = [];
  final LatLng currentLocation = const LatLng(-34.8927715, -56.1233649);
  late GoogleMapController mapController;
  final Map<String, Marker> _markers = {};
  List<LatLng> polylineCoordinates = [];

  TextEditingController filtroController = TextEditingController();
  late AnimationController _animationController;
  bool selectAll = true;
  int buttonIndex = 0;
  Cliente? clienteSeleccionado;

  @override
  void initState() {
    super.initState();
    selectedCliente = Cliente.empty();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 500)
    );
    cargarDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (tecnicos.isEmpty) {
      loadTecnicos();
    }
  }

  cargarDatos() async {
    token = context.read<OrdenProvider>().token;
    print(_animationController.value);
  }

  Future<void> loadTecnicos() async {
    final token = context.watch<OrdenProvider>().token;
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
  void _abrirBusquedaCliente(BuildContext context) async {
    final Cliente? resultado = await showSearch<Cliente>(
      context: context,
      delegate: ClienteSearchDelegate(
        token: token,
        clientService: ClientServices(),
      ),
    );

    if (resultado != null && resultado.clienteId != 0) {
      // Obtener las unidades del cliente desde la API
      setState(() {
        clienteSeleccionado = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Ubicaciones'),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
        drawer: isMobile ? _buildMobileDrawer(colors) : null,
        body: isMobile ? _buildMobileBody() : _buildDesktopBody(colors),
      ),
    );
  }

  // Widgets para la versión móvil
  Widget _buildMobileDrawer(ColorScheme colors) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.9,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
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
                label: 'Filtrar por número de orden',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Tecnico: ', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: DropdownSearch(
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(hintText: 'Seleccione un tecnico')
              ),
              items: tecnicos,
              popupProps: const PopupProps.menu(
                showSearchBox: true, searchDelay: Duration.zero
              ),
              onChanged: (value) {
                setState(() {
                  selectedTecnico = value;
                  tecnicoFiltro = value!.tecnicoId;
                });
              },
            ),
          ),      
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text('Cliente: ', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  child: TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Buscar cliente...',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    controller: TextEditingController(
                      text: clienteSeleccionado != null ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' : '',
                    ),
                    onTap: () {
                      _abrirBusquedaCliente(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),    
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2099),
                    context: context,
                  );
                            
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                icon: Container(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(3)
                  ),
                  child: const Icon(Icons.calendar_month),
                )
              ),
              const Text('Fecha: ', style: TextStyle(fontSize: 18)),
              Text(DateFormat("E d, MMM", 'es').format(selectedDate),
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const Divider(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.45,
            child: ListView.builder(
              itemCount: ubicacionesFiltradas.length,
              itemBuilder: (context, i) {
                var ubicacion = ubicacionesFiltradas[i];
                return CheckboxListTile(
                  title: Text(
                    ubicacion.cliente.nombre,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text('${ubicacion.ordenTrabajoId} - ${DateFormat('HH:mm', 'es').format(ubicacion.fechaDate)}'),
                  value: ubicacion.seleccionado,
                  onChanged: (value) async {
                    ubicacion.seleccionado = value!;
                    await cargarMarkers();
                    setState(() {});
                  },
                );
              }
            )
          ),
          const Spacer(),
          BottomNavigationBar(
            currentIndex: buttonIndex,
            onTap: (index) async {
              buttonIndex = index;
              switch (buttonIndex){
                case 0:
                  if (selectedTecnico != null) {
                    String fechaDesde = DateFormat('yyyy-MM-dd', 'es').format(selectedDate);
                    DateTime manana = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1);
                    String fechaHasta = DateFormat('yyyy-MM-dd', 'es').format(manana);
                    ubicaciones = await UbicacionesMapaServices().getUbicaciones(
                      context, selectedTecnico!.tecnicoId, fechaDesde, fechaHasta, token);
                    await cargarUbicacion();
                    await cargarMarkers();
                    setState(() {});
                  }
                break;
                case 1:
                  selectAll = !selectAll;
                  for (var ubicacion in ubicacionesFiltradas) {
                    ubicacion.seleccionado = selectAll;
                  }
                  await cargarMarkers();
                  setState(() {});
                break;
              }
            },
            showUnselectedLabels: true,
            selectedItemColor: colors.primary,
            unselectedItemColor: colors.primary,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Buscar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_box_outlined),
                label: 'Marcar Todos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          GoogleMap(
            key: const Key('google_map_mobile'),
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
                color: Colors.blue,
                width: 3,
                points: polylineCoordinates,
              ),
            },
          ),
        ],
      )
    );
  }

  // Widgets para la versión desktop
  Widget _buildDesktopBody(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Fila de filtros con scroll horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Tecnico: ', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 220,
                  child: DropdownSearch(
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        hintText: 'Seleccione un tecnico'
                      )
                    ),
                    items: tecnicos,
                    popupProps: const PopupProps.menu(showSearchBox: true, searchDelay: Duration.zero),
                    onChanged: (value) {
                      setState(() {
                        selectedTecnico = value;
                        tecnicoFiltro = value!.tecnicoId;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 30),
                const Text('Cliente: ', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                // Campo de búsqueda de cliente - SOLUCIÓN APLICADA
                SizedBox(
                  width: 300,
                  child: GestureDetector(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Buscar cliente...',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.search),
                      ),
                      controller: TextEditingController(
                        text: clienteSeleccionado != null ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' : '',
                      ),
                      onTap: () {
                        _abrirBusquedaCliente(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () async {
                    if (selectedTecnico != null) {
                      String fechaDesde = DateFormat('yyyy-MM-dd', 'es').format(selectedDate);
                      DateTime manana = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1);
                      String fechaHasta = DateFormat('yyyy-MM-dd', 'es').format(manana);
                      ubicaciones = await UbicacionesMapaServices().getUbicaciones(
                        context, selectedTecnico!.tecnicoId, fechaDesde, fechaHasta, token);
                      await cargarUbicacion();
                      await cargarMarkers();
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.search),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2099),
                      context: context,
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month)
                ),
                const Text('Fecha: ', style: TextStyle(fontSize: 24)),
                Text(
                  DateFormat("E d, MMM", 'es').format(selectedDate),
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 20), // Espacio adicional al final
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final targetWidth = MediaQuery.of(context).size.width / 1.35;
                    final initialWidth = MediaQuery.of(context).size.width - 26;
                    final currentWidth = initialWidth + (_animationController.value * (targetWidth - initialWidth));
                    final targetHeight = MediaQuery.of(context).size.height / 1.45;
                    final initialHeight = MediaQuery.of(context).size.height - 141;
                    final currentHeight = initialHeight + (_animationController.value * (targetHeight - initialHeight));
                    return SizedBox(
                      width: currentWidth,
                      height: currentHeight,
                      child: Stack(
                        children: <Widget>[
                          GoogleMap(
                            key: const Key('google_map_desktop'),
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
                                color: Colors.blue,
                                width: 3,
                                points: polylineCoordinates,
                              ),
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Column(
                                children: <Widget>[
                                  FloatingActionButton(
                                    onPressed: () async {
                                      toggleMapWidth();
                                      print(_animationController.value);
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.padded,
                                    backgroundColor: Colors.green,
                                    child: const Icon(
                                      Icons.format_list_bulleted_rounded,
                                      size: 36.0
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    );
                  }
                ),
                if (_animationController.value == 1.0)
                const SizedBox(width: 10.0),
                if (_animationController.value == 1.0)
                Card(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 300,
                        child: Row(
                          children: [
                            Expanded(
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
                            Checkbox(
                              value: selectAll,
                              onChanged: (value) {
                                setState(() {
                                  selectAll = value!;
                                  for (var ubicacion in ubicacionesFiltradas) {
                                    ubicacion.seleccionado = selectAll;
                                  }
                                  cargarMarkers();
                                });
                              },
                            ),
                            const Text('Marcar todos'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        height: MediaQuery.of(context).size.height / 1.45,
                        child: ListView.builder(
                          itemCount: ubicacionesFiltradas.length,
                          itemBuilder: (context, i) {
                            var ubicacion = ubicacionesFiltradas[i];
                            return CheckboxListTile(
                              title: Text(
                                ubicacion.cliente.nombre,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text('${ubicacion.ordenTrabajoId} - ${DateFormat('HH:mm', 'es').format(ubicacion.fechaDate)} ${ubicacion.estado}'),
                              value: ubicacion.seleccionado,
                              onChanged: (value) {
                                ubicacion.seleccionado = value!;
                                setState(() {
                                  cargarMarkers();
                                });
                              },
                            );
                          }
                        )
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos comunes
  addMarker(String id, LatLng location, String title, String snippet) {
    var marker = Marker(
      markerId: MarkerId(id),
      position: location,
      infoWindow: InfoWindow(title: title, snippet: snippet),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan)
    );
    _markers[id] = marker;
    polylineCoordinates.add(location);
  }

  cargarMarkers() {
    _markers.clear();
    polylineCoordinates.clear();
    for (var ubicacion in ubicacionesFiltradas) {
      if (ubicacion.seleccionado && ubicacion.ubicacion != null && ubicacion.ubicacion!.isNotEmpty) {
        var coord = ubicacion.ubicacion!.split(',');

        if (coord.length >= 2) {
          try {
            final lat = double.parse(coord[0]);
            final lng = double.parse(coord[1]);
            addMarker(
              ubicacion.logId.toString(),
              LatLng(lat, lng),
              ubicacion.cliente.nombre,
              'Orden: ${ubicacion.ordenTrabajoId} - ${DateFormat('HH:mm', 'es').format(ubicacion.fechaDate)} ${ubicacion.estado}'
            );
          } catch (e) {
            print('Error parsing coordinates: $e');
          }
        } else {
          print('Error: Coordinates not properly formatted');
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
}