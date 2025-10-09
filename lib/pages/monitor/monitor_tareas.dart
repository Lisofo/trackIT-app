// monitor_tareas.dart
import 'dart:async';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:app_tec_sedel/widgets/dialogo_tarea.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorTareas extends StatefulWidget {
  const MonitorTareas({super.key});

  @override
  MonitorTareasState createState() => MonitorTareasState();
}

class MonitorTareasState extends State<MonitorTareas> {
  List<Tarea> tareas = [];
  List<Tarea> tareasFiltradas = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  // Variables para paginación
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  final TareasServices tareasServices = TareasServices();
  final TextEditingController searchController = TextEditingController();
  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<OrdenProvider>().token;
    searchController.addListener(_filtrarTareasEnTiempoReal);
    _scrollController.addListener(_scrollListener);
    _cargarTareasIniciales();
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
      
      final nuevasTareas = await tareasServices.getTareas(
        context,
        token,
      );
      
      if (nuevasTareas != null && nuevasTareas.isNotEmpty) {
        setState(() {
          tareasFiltradas.addAll(nuevasTareas);
          _offset = nuevoOffset;
          _hasMore = nuevasTareas.length == _limit;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      print('Error al cargar más tareas: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _cargarTareasIniciales() async {
    try {
      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      
      final tareasIniciales = await tareasServices.getTareas(
        context,
        token,
      );

      if (tareasIniciales != null) {
        setState(() {
          tareas = tareasIniciales;
          tareasFiltradas = tareasIniciales;
          _isLoading = false;
          _hasMore = tareasIniciales.length == _limit;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando tareas iniciales: $e');
    }
  }

  void _filtrarTareasEnTiempoReal() {
    final query = searchController.text;
    
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        tareasFiltradas = tareas;
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
        final resultados = await tareasServices.getTareas(
          context,
          token,
        );
        
        if (mounted) {
          setState(() {
            tareasFiltradas = resultados?.where((tarea) =>
              tarea.descripcion.toLowerCase().contains(query.toLowerCase()) ||
              tarea.codTarea.toLowerCase().contains(query.toLowerCase())
            ).toList() ?? [];
            _isSearching = false;
            _hasMore = (tareasFiltradas.length) == _limit;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            tareasFiltradas = [];
            _isSearching = false;
          });
        }
        print('Error buscando tareas: $e');
      }
    });
  }

  Future<void> _recargarDatos() async {
    try {
      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      
      final resultados = await tareasServices.getTareas(
        context,
        token,
      );
      
      setState(() {
        tareas = resultados ?? [];
        tareasFiltradas = searchController.text.isEmpty 
            ? tareas 
            : tareas.where((tarea) =>
                tarea.descripcion.toLowerCase().contains(searchController.text.toLowerCase()) ||
                tarea.codTarea.toLowerCase().contains(searchController.text.toLowerCase())
              ).toList();
        _isLoading = false;
        _hasMore = (resultados?.length ?? 0) == _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al recargar tareas: $e');
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
        title: Text('Lista de Tareas', style: TextStyle(color: colors.onPrimary)),
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
                labelText: 'Buscar tarea...',
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
                    : tareasFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task, size: 64, color: colors.onSurface.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'No hay tareas registradas'
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
                            itemCount: tareasFiltradas.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == tareasFiltradas.length) {
                                return _buildLoadingMoreIndicator();
                              }
                              
                              final tarea = tareasFiltradas[index];
                              
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
                                    tarea.descripcion,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (tarea.codTarea.isNotEmpty)
                                        Text(
                                          'Código: ${tarea.codTarea}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: colors.primary.withOpacity(0.2),
                                    child: Icon(Icons.task, color: colors.primary),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          _mostrarDialogoEditarTarea(context, tarea);
                                        },
                                        icon: Icon(Icons.edit, color: colors.primary),
                                        tooltip: 'Editar Tarea',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _mostrarDialogoEliminarTarea(context, tarea);
                                        },
                                        icon: Icon(Icons.delete, color: colors.error),
                                        tooltip: 'Eliminar Tarea',
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
          _mostrarDialogoNuevaTarea(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }

  void _mostrarDialogoEliminarTarea(BuildContext context, Tarea tarea) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Tarea'),
          content: Text('¿Estás seguro de que quieres eliminar ${tarea.descripcion}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // await tareasServices.deleteTarea(context, tarea, token);
                  await _recargarDatos();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tarea ${tarea.descripcion} eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error eliminando tarea: $e');
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoNuevaTarea(BuildContext context) async {
    final tareaGuardada = await showDialog<Tarea>(
      context: context,
      builder: (BuildContext context) {
        return DialogoTarea(
          tareasServices: tareasServices,
          token: token,
        );
      },
    );

    if (tareaGuardada != null && mounted) {
      await _recargarDatos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea ${tareaGuardada.descripcion} creada exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarDialogoEditarTarea(BuildContext context, Tarea tarea) async {
    final tareaEditada = await showDialog<Tarea>(
      context: context,
      builder: (BuildContext context) {
        return DialogoTarea(
          tareasServices: tareasServices,
          token: token,
          esEdicion: true,
          tareaEditar: tarea,
        );
      },
    );

    if (tareaEditada != null && mounted) {
      await _recargarDatos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea ${tareaEditada.descripcion} actualizada exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}