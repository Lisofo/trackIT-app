// monitor_materiales.dart
import 'dart:async';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/widgets/dialogo_material.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorMateriales extends StatefulWidget {
  const MonitorMateriales({super.key});

  @override
  MonitorMaterialesState createState() => MonitorMaterialesState();
}

class MonitorMaterialesState extends State<MonitorMateriales> {
  List<Materiales> materiales = [];
  List<Materiales> materialesFiltrados = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  // Variables para paginación
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  final MaterialesServices materialesServices = MaterialesServices();
  final TextEditingController searchController = TextEditingController();
  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<OrdenProvider>().token;
    searchController.addListener(_filtrarMaterialesEnTiempoReal);
    _scrollController.addListener(_scrollListener);
    _cargarMaterialesIniciales();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _cargarMasDatos();
    }
  }

  Future<void> _cargarMasDatos() async {
    if (_isLoadingMore || !_hasMore || searchController.text.isEmpty) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      final nuevoOffset = _offset + _limit;
      
      final nuevosMateriales = await materialesServices.getMateriales(
        context,
        token,
      );
      
      if (nuevosMateriales != null && nuevosMateriales.isNotEmpty) {
        setState(() {
          materialesFiltrados.addAll(nuevosMateriales);
          _offset = nuevoOffset;
          _hasMore = nuevosMateriales.length == _limit;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      print('Error al cargar más materiales: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _cargarMaterialesIniciales() async {
    try {
      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      
      final materialesIniciales = await materialesServices.getMateriales(
        context,
        token,
      );

      if (materialesIniciales != null) {
        setState(() {
          materiales = materialesIniciales;
          materialesFiltrados = materialesIniciales;
          _isLoading = false;
          _hasMore = materialesIniciales.length == _limit;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando materiales iniciales: $e');
    }
  }

  void _filtrarMaterialesEnTiempoReal() {
    final query = searchController.text;
    
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        materialesFiltrados = materiales;
        _isSearching = false;
        _hasMore = true;
        _offset = 0;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
        _hasMore = true;
        _offset = 0;
      });
      
      try {
        final resultados = await materialesServices.getMateriales(
          context,
          token,
        );
        
        if (mounted) {
          setState(() {
            materialesFiltrados = resultados?.where((material) =>
              material.descripcion.toLowerCase().contains(query.toLowerCase()) ||
              material.codMaterial.toLowerCase().contains(query.toLowerCase())
            ).toList() ?? [];
            _isSearching = false;
            _hasMore = (materialesFiltrados.length) == _limit;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            materialesFiltrados = [];
            _isSearching = false;
          });
        }
        print('Error buscando materiales: $e');
      }
    });
  }

  Future<void> _recargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      
      final resultados = await materialesServices.getMateriales(
        context,
        token,
      );
      
      setState(() {
        materiales = resultados ?? [];
        materialesFiltrados = searchController.text.isEmpty 
            ? materiales 
            : materiales.where((material) =>
                material.descripcion.toLowerCase().contains(searchController.text.toLowerCase()) ||
                material.codMaterial.toLowerCase().contains(searchController.text.toLowerCase())
              ).toList();
        _isLoading = false;
        _hasMore = (resultados?.length ?? 0) == _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al recargar materiales: $e');
    }
  }

  void _limpiarBusqueda() {
    searchController.clear();
    FocusScope.of(context).unfocus();
  }

  Widget _buildLoadingMoreIndicator() {
    return _hasMore 
      ? const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        )
      : const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No hay más resultados',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('Lista de Materiales', style: TextStyle(color: colors.onPrimary)),
        iconTheme: IconThemeData(color: colors.onPrimary),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargarDatos,
            tooltip: 'Recargar datos',
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _limpiarBusqueda,
              tooltip: 'Limpiar búsqueda',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar material...',
                hintText: 'Buscar por descripción, código...',
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : materialesFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2, size: 64, color: colors.onSurface.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'No hay materiales registrados'
                                      : 'No se encontraron resultados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colors.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: materialesFiltrados.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == materialesFiltrados.length) {
                                return _buildLoadingMoreIndicator();
                              }
                              
                              final material = materialesFiltrados[index];
                              
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.30),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    material.descripcion,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (material.codMaterial.isNotEmpty)
                                        Text(
                                          'Código: ${material.codMaterial}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: colors.primary.withOpacity(0.2),
                                    child: Icon(Icons.inventory_2, color: colors.primary),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _mostrarDialogoEditarMaterial(context, material);
                                        },
                                        icon: Icon(Icons.edit, color: colors.primary),
                                        tooltip: 'Editar Material',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _mostrarDialogoEliminarMaterial(context, material);
                                        },
                                        icon: Icon(Icons.delete, color: colors.error),
                                        tooltip: 'Eliminar Material',
                                      ),
                                    ],
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogoNuevoMaterial(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }

  void _mostrarDialogoEliminarMaterial(BuildContext context, Materiales material) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Material'),
          content: Text('¿Estás seguro de que quieres eliminar ${material.descripcion}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await materialesServices.deleteMaterial(context, material, token);
                  await _recargarDatos();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Material ${material.descripcion} eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error eliminando material: $e');
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoNuevoMaterial(BuildContext context) async {
    final materialGuardado = await showDialog<Materiales>(
      context: context,
      builder: (BuildContext context) {
        return DialogoMaterial(
          materialesServices: materialesServices,
          token: token,
        );
      },
    );

    if (materialGuardado != null && mounted) {
      await _recargarDatos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material ${materialGuardado.descripcion} creado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarDialogoEditarMaterial(BuildContext context, Materiales material) async {
    final materialEditado = await showDialog<Materiales>(
      context: context,
      builder: (BuildContext context) {
        return DialogoMaterial(
          materialesServices: materialesServices,
          token: token,
          esEdicion: true,
          materialEditar: material,
        );
      },
    );

    if (materialEditado != null && mounted) {
      await _recargarDatos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material ${materialEditado.descripcion} actualizado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}