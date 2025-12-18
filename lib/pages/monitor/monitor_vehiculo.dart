// monitor_vehiculo.dart
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/marca.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/codigueras_services.dart';
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:app_tec_sedel/widgets/dialogo_unidad.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorVehiculos extends StatefulWidget {
  const MonitorVehiculos({super.key});

  @override
  MonitorVehiculosState createState() => MonitorVehiculosState();
}

class MonitorVehiculosState extends State<MonitorVehiculos> {
  
  List<Unidad> unidadesFiltradas = [];
  TextEditingController searchController = TextEditingController();
  final UnidadesServices _unidadesServices = UnidadesServices();
  final CodiguerasServices _codiguerasServices = CodiguerasServices();
  late String token = '';
  bool _isLoading = false;
  bool _hasSearched = false;

  // Variables para marcas y modelos (se cargan al iniciar)
  List<Marca> _marcas = [];

  @override
  void initState() {
    super.initState();
    token = context.read<AuthProvider>().token;
    _cargarMarcas(); // Cargar marcas al iniciar la pantalla
    // Removemos la carga automática de unidades
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _buscarUnidades() async {
    final query = searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        unidadesFiltradas = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final listaUnidades = await _unidadesServices.getUnidades(
        context, 
        token, 
        matricula: query // Solo buscar por matrícula
      );
      
      setState(() {
        unidadesFiltradas = listaUnidades;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
      // El error ya fue manejado por Carteles().errorManagment en el servicio
    }
  }

  Future<void> _cargarMarcas() async {
    if (_marcas.isNotEmpty) return; // Ya están cargadas
    
    try {
      final listaMarcas = await _codiguerasServices.getMarcas(context, token);
      setState(() {
        _marcas = listaMarcas;
      });
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  String _getDisplayInfo(Unidad unidad) {
    return '${unidad.marca} ${unidad.modelo} - ${unidad.matricula}';
  }

  // Método reutilizable para crear/editar unidad
  void _mostrarDialogoUnidad(BuildContext context, {Unidad? unidadExistente}) async {
    final Unidad? unidadGuardada = await showDialog<Unidad>(
      context: context,
      builder: (BuildContext context) {
        return DialogoUnidad(
          unidadExistente: unidadExistente,
          token: token,
          unidadesServices: _unidadesServices,
          codiguerasServices: _codiguerasServices,
          permitirBusquedaMatricula: false, // Deshabilitar búsqueda en monitor vehículos
        );
      },
    );

    if (unidadGuardada != null) {
      // Si se creó/editó una unidad, puedes realizar una nueva búsqueda si hay texto en el buscador
      if (searchController.text.isNotEmpty) {
        _buscarUnidades();
      }
    }
  }

  void _mostrarDialogoNuevaUnidad(BuildContext context) {
    _mostrarDialogoUnidad(context);
  }

  void _editarUnidad(Unidad unidad) {
    _mostrarDialogoUnidad(context, unidadExistente: unidad);
  }

  void _verHistorial(Unidad unidad) {
    // Settear la unidad en el provider
    Provider.of<OrdenProvider>(context, listen: false).setUnidadSeleccionada(unidad);
    
    // Navegar a la lista de órdenes
    router.push('/listaOrdenes');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Lista de Vehículos', style: TextStyle(color: colors.onPrimary)),
        iconTheme: IconThemeData(color: colors.onPrimary),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por matrícula',
                      prefixIcon: Icon(Icons.search, color: colors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    onSubmitted: (value) => _buscarUnidades(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _buscarUnidades,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: _isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : Icon(Icons.search, color: colors.onPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : unidadesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 64, color: colors.onSurface.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _hasSearched 
                                  ? 'No se encontraron vehículos con esa matrícula'
                                  : 'Ingrese una matrícula para buscar',
                              style: TextStyle(
                                fontSize: 18,
                                color: colors.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: unidadesFiltradas.length,
                        itemBuilder: (context, index) {
                          final unidad = unidadesFiltradas[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                _getDisplayInfo(unidad),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Año: ${unidad.anio}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Motor: ${unidad.motor}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Chasis: ${unidad.chasis}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  if (unidad.color.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Color: ${unidad.color}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                  if (unidad.descripcion.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Descripción: ${unidad.descripcion}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                  if (unidad.codItem.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Código: ${unidad.codItem}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                  if (unidad.consignado) ...[
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Consignado: Sí',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  if (unidad.averias) ...[
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Averías: Sí',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: colors.primary.withOpacity(0.2),
                                child: Text(
                                  unidad.marca.isNotEmpty ? unidad.marca[0] : 'V',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _editarUnidad(unidad);
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.blue,)
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _verHistorial(unidad);
                                    },
                                    icon: const Icon(Icons.history, color: Colors.green,) // Nuevo botón
                                  ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogoNuevaUnidad(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }
}