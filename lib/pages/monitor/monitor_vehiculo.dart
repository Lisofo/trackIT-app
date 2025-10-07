// monitor_vehiculo.dart
import 'package:app_tec_sedel/models/marca.dart';
import 'package:app_tec_sedel/models/unidad.dart';
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
  
  List<Unidad> unidades = [];
  List<Unidad> unidadesFiltradas = [];
  TextEditingController searchController = TextEditingController();
  final UnidadesServices _unidadesServices = UnidadesServices();
  final CodiguerasServices _codiguerasServices = CodiguerasServices();
  late String token = '';
  bool _isLoading = true;

  // Variables para marcas y modelos (se cargan al iniciar)
  List<Marca> _marcas = [];

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
    _cargarMarcas(); // Cargar marcas al iniciar la pantalla
    searchController.addListener(_filtrarUnidades);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarUnidades() async {
    token = context.read<OrdenProvider>().token;
    try {
      final listaUnidades = await _unidadesServices.getUnidades(context, token);
      
      setState(() {
        unidades = listaUnidades;
        unidadesFiltradas = unidades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // El error ya fue manejado por Carteles().errorManagment en el servicio
    }
  }

  Future<void> _cargarMarcas() async {
    if (_marcas.isNotEmpty) return; // Ya están cargadas
    
    setState(() {
    });

    try {
      final listaMarcas = await _codiguerasServices.getMarcas(context, token);
      setState(() {
        _marcas = listaMarcas;
      });
    } catch (e) {
      setState(() {
      });
    }
  }

  void _filtrarUnidades() {
    final query = searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        unidadesFiltradas = unidades;
      });
      return;
    }

    setState(() {
      unidadesFiltradas = unidades.where((unidad) {
        return unidad.marca.toLowerCase().contains(query) ||
            (unidad.matricula.toLowerCase().contains(query)) ||
            unidad.modelo.toLowerCase().contains(query) ||
            unidad.anio.toString().contains(query) ||
            unidad.motor.toLowerCase().contains(query) ||
            unidad.chasis.toLowerCase().contains(query) ||
            unidad.descripcion.toLowerCase().contains(query) ||
            unidad.codItem.toLowerCase().contains(query) ||
            _getDisplayInfo(unidad).toLowerCase().contains(query);
      }).toList();
    });
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
      await _cargarUnidades();
    }
  }

  void _mostrarDialogoNuevaUnidad(BuildContext context) {
    _mostrarDialogoUnidad(context);
  }

  void _editarUnidad(Unidad unidad) {
    _mostrarDialogoUnidad(context, unidadExistente: unidad);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar vehículo',
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
                  ),
                ),
                Expanded(
                  child: unidadesFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_outlined, size: 64, color: colors.onSurface.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                unidades.isEmpty ? 'No hay vehículos registrados' : 'No se encontraron resultados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: colors.onSurface.withOpacity(0.7),
                                ),
                              ),
                              if (unidades.isEmpty) 
                                TextButton(
                                  onPressed: _cargarUnidades,
                                  child: Text('Reintentar', style: TextStyle(color: colors.primary)),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: unidadesFiltradas.length,
                          // separatorBuilder: (context, index) => Divider(height: 1, color: colors.outline.withOpacity(0.3)),
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
                                      onPressed: () {},
                                      icon: const Icon(Icons.delete, color: Colors.red,)
                                    )
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