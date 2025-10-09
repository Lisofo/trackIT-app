// monitor_tecnicos.dart
import 'dart:async';
import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/tecnicos_services.dart';
import 'package:app_tec_sedel/widgets/dialogo_tecnico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MonitorTecnicos extends StatefulWidget {
  const MonitorTecnicos({super.key});

  @override
  MonitorTecnicosState createState() => MonitorTecnicosState();
}

class MonitorTecnicosState extends State<MonitorTecnicos> {
  List<Tecnico> tecnicos = [];
  List<Tecnico> tecnicosFiltrados = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  // Variables para paginación
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  final TecnicosServices tecnicosServices = TecnicosServices();
  final TextEditingController searchController = TextEditingController();
  String token = '';

  @override
  void initState() {
    super.initState();
    token = context.read<OrdenProvider>().token;
    searchController.addListener(_filtrarTecnicosEnTiempoReal);
    _scrollController.addListener(_scrollListener);
    _cargarTecnicosIniciales();
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
      
      final nuevosTecnicos = await tecnicosServices.getTecnicos(
        context,
        '',
        '',
        searchController.text,
        token,
      );
      
      if (nuevosTecnicos != null && nuevosTecnicos.isNotEmpty) {
        setState(() {
          tecnicosFiltrados.addAll(nuevosTecnicos);
          _offset = nuevoOffset;
          _hasMore = nuevosTecnicos.length == _limit;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      print('Error al cargar más técnicos: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _cargarTecnicosIniciales() async {
    try {
      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      
      final tecnicosIniciales = await tecnicosServices.getTecnicos(
        context,
        '',
        '',
        searchController.text,
        token,
      );

      if (tecnicosIniciales != null) {
        setState(() {
          tecnicos = tecnicosIniciales;
          tecnicosFiltrados = tecnicosIniciales;
          _isLoading = false;
          _hasMore = tecnicosIniciales.length == _limit;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando técnicos iniciales: $e');
    }
  }

  void _filtrarTecnicosEnTiempoReal() {
    final query = searchController.text;
    
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        tecnicosFiltrados = tecnicos;
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
        final resultados = await tecnicosServices.getTecnicos(
          context,
          '',
          '',
          searchController.text,
          token,
        );
        
        if (mounted) {
          setState(() {
            tecnicosFiltrados = resultados ?? [];
            _isSearching = false;
            _hasMore = (resultados?.length ?? 0) == _limit;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            tecnicosFiltrados = [];
            _isSearching = false;
          });
        }
        print('Error buscando técnicos: $e');
      }
    });
  }

  Future<void> _recargarDatos() async {
    if (searchController.text.isEmpty) {
      await _cargarTecnicosIniciales();
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _offset = 0;
      });
      
      final resultados = await tecnicosServices.getTecnicos(
        context,
        '',
        '',
        searchController.text,
        token,
      );
      
      setState(() {
        tecnicosFiltrados = resultados ?? [];
        _isLoading = false;
        _hasMore = (resultados?.length ?? 0) == _limit;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al recargar técnicos: $e');
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
        title: Text('Lista de Técnicos', style: TextStyle(color: colors.onPrimary)),
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
                labelText: 'Buscar técnico...',
                hintText: 'Buscar por nombre, código, documento...',
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
                    : tecnicosFiltrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.engineering, size: 64, color: colors.onSurface.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'No hay técnicos registrados'
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
                            itemCount: tecnicosFiltrados.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == tecnicosFiltrados.length) {
                                return _buildLoadingMoreIndicator();
                              }
                              
                              final tecnico = tecnicosFiltrados[index];
                              
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
                                    tecnico.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (tecnico.codTecnico.isNotEmpty)
                                        Text(
                                          'Código: ${tecnico.codTecnico}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      if (tecnico.codTecnico.isNotEmpty) const SizedBox(height: 2),
                                      if (tecnico.documento.isNotEmpty)
                                        Text(
                                          'Documento: ${tecnico.documento}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      if (tecnico.documento.isNotEmpty) const SizedBox(height: 2),
                                      if (tecnico.cargo?.descripcion.isNotEmpty ?? false)
                                        Text(
                                          'Cargo: ${tecnico.cargo!.descripcion}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: colors.primary.withOpacity(0.2),
                                    child: Text(
                                      tecnico.nombre.isNotEmpty ? tecnico.nombre[0] : 'T',
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
                                          _mostrarDialogoEditarTecnico(context, tecnico);
                                        },
                                        icon: Icon(Icons.edit, color: colors.primary),
                                        tooltip: 'Editar Técnico',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _mostrarDialogoEliminarTecnico(context, tecnico);
                                        },
                                        icon: Icon(Icons.delete, color: colors.error),
                                        tooltip: 'Eliminar Técnico',
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
          _mostrarDialogoNuevoTecnico(context);
        },
        backgroundColor: colors.primary,
        elevation: 4,
        child: Icon(Icons.add, color: colors.onPrimary),
      ),
    );
  }

  void _mostrarDialogoEliminarTecnico(BuildContext context, Tecnico tecnico) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Técnico'),
          content: Text('¿Estás seguro de que quieres eliminar a ${tecnico.nombre}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await tecnicosServices.deleteTecnico(context, tecnico, token);
                  await _recargarDatos();
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error eliminando técnico: $e');
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoNuevoTecnico(BuildContext context) async {
    final tecnicoGuardado = await showDialog<Tecnico>(
      context: context,
      builder: (BuildContext context) {
        return DialogoTecnico(
          tecnicosServices: tecnicosServices,
          token: token,
        );
      },
    );

    if (tecnicoGuardado != null && mounted) {
      await _recargarDatos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Técnico ${tecnicoGuardado.nombre} creado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarDialogoEditarTecnico(BuildContext context, Tecnico tecnico) async {
    final tecnicoEditado = await showDialog<Tecnico>(
      context: context,
      builder: (BuildContext context) {
        return DialogoTecnico(
          tecnicosServices: tecnicosServices,
          token: token,
          esEdicion: true,
          tecnicoEditar: tecnico,
        );
      },
    );

    if (tecnicoEditado != null && mounted) {
      await _recargarDatos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Técnico ${tecnicoEditado.nombre} actualizado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}