// incidencia_screen.dart
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/incidencia.dart';
import 'package:app_tec_sedel/services/incidencia_services.dart';
import 'package:provider/provider.dart';

class IncidenciaScreen extends StatefulWidget {

  const IncidenciaScreen({super.key});
  
  @override
  IncidenciaScreenState createState() => IncidenciaScreenState();
}

class IncidenciaScreenState extends State<IncidenciaScreen> {
  final IncidenciaServices _services = IncidenciaServices();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  
  List<Incidencia> _incidencias = [];
  List<Incidencia> _filteredIncidencias = [];
  bool _isLoading = true;
  bool _isSearching = false;
  late String token = context.read<AuthProvider>().token;
  
  // Variable para el switch de "Sin Garantía"
  bool _sinGarantiaValue = false;
  
  @override
  void initState() {
    super.initState();
    _loadIncidencias();
    
    // Configurar búsqueda en tiempo real
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadIncidencias() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _services.getIncidencias(context, token);
      
      if (result != null && result is List<Incidencia>) {
        setState(() {
          _incidencias = result;
          _filteredIncidencias = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar incidencias: $e')),
      );
    }
  }
  
  void _onSearchChanged() {
    final searchText = _searchController.text.toLowerCase();
    
    if (searchText.isEmpty) {
      setState(() {
        _filteredIncidencias = _incidencias;
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredIncidencias = _incidencias
            .where((incidencia) =>
                incidencia.descripcion.toLowerCase().contains(searchText) ||
                incidencia.codIncidencia.toLowerCase().contains(searchText))
            .toList();
      });
    }
  }
  
  Future<void> _createIncidencia() async {
    _descripcionController.clear();
    _sinGarantiaValue = false; // Resetear valor por defecto
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nueva Incidencia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ingrese la descripción de la incidencia',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Sin Garantía'),
                  value: _sinGarantiaValue,
                  onChanged: (value) {
                    setState(() {
                      _sinGarantiaValue = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_descripcionController.text.trim().isNotEmpty) {
                    final nuevaIncidencia = Incidencia(
                      incidenciaId: 0,
                      codIncidencia: '', // Se generará automáticamente
                      descripcion: _descripcionController.text.trim(),
                      sinGarantia: _sinGarantiaValue ? 'S' : 'N', // Convertir boolean a S/N
                    );
                    
                    final creada = await _services.createIncidencia(
                      context,
                      token,
                      nuevaIncidencia,
                    );
                    
                    if (creada != null) {
                      await _loadIncidencias();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incidencia creada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _editIncidencia(Incidencia incidencia) async {
    _descripcionController.text = incidencia.descripcion;
    // Convertir 'S'/'N' a boolean para el Switch
    _sinGarantiaValue = incidencia.sinGarantia == 'S';
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Incidencia'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código: ${incidencia.codIncidencia}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Sin Garantía'),
                  value: _sinGarantiaValue,
                  onChanged: (value) {
                    setState(() {
                      _sinGarantiaValue = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_descripcionController.text.trim().isNotEmpty) {
                    final incidenciaEditada = Incidencia(
                      incidenciaId: incidencia.incidenciaId,
                      codIncidencia: incidencia.codIncidencia,
                      descripcion: _descripcionController.text.trim(),
                      sinGarantia: _sinGarantiaValue ? 'S' : 'N', // Convertir boolean a S/N
                    );
                    
                    final actualizada = await _services.updateIncidencia(
                      context,
                      token,
                      incidencia.incidenciaId,
                      incidenciaEditada,
                    );
                    
                    if (actualizada != null) {
                      await _loadIncidencias();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incidencia actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _deleteIncidencia(Incidencia incidencia) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Está seguro de eliminar la incidencia "${incidencia.descripcion}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final eliminado = await _services.deleteIncidencia(
                context,
                token,
                incidencia.incidenciaId,
              );
              
              if (eliminado) {
                await _loadIncidencias();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incidencia eliminada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showIncidenciaMenu(BuildContext context, Incidencia incidencia) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              _editIncidencia(incidencia);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteIncidencia(incidencia);
            },
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: colors.onPrimary,
        title: const Text('Gestión de Incidencias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidencias,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar incidencias',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                hintText: 'Buscar por descripción o código...',
              ),
            ),
          ),
          
          // Indicador de búsqueda
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${_filteredIncidencias.length} resultados encontrados',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de incidencias
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIncidencias.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.list,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No se encontraron incidencias\npara "${_searchController.text}"'
                                  : 'No hay incidencias registradas',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadIncidencias,
                        child: ListView.builder(
                          itemCount: _filteredIncidencias.length,
                          itemBuilder: (context, index) {
                            final incidencia = _filteredIncidencias[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    incidencia.codIncidencia.isNotEmpty
                                        ? incidencia.codIncidencia[0]
                                        : 'I',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(incidencia.descripcion),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Código: ${incidencia.codIncidencia}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sin Garantía: ${incidencia.sinGarantia}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _showIncidenciaMenu(context, incidencia),
                                ),
                                onTap: () => _editIncidencia(incidencia),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createIncidencia,
        child: const Icon(Icons.add),
      ),
    );
  }
}