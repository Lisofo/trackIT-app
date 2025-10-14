// unidad_search_delegate.dart
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/unidad.dart';

class UnidadSearchDelegate extends SearchDelegate<Unidad> {
  final String token;
  final UnidadesServices unidadService;
  
  bool _shouldSearch = false;

  UnidadSearchDelegate({
    required this.token,
    required this.unidadService,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          _shouldSearch = false;
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Unidad.empty());
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (_shouldSearch) {
      return _buildSearchResults(context);
    } else {
      return _buildInitialState();
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (_shouldSearch) {
      return _buildSearchResults(context);
    } else {
      return _buildInitialState();
    }
  }

  @override
  void showResults(BuildContext context) {
    _shouldSearch = true;
    super.showResults(context);
  }

  Widget _buildInitialState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Escriba la matricula de la unidad y presione Enter',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<Unidad>>(
      future: _searchUnidades(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final unidades = snapshot.data ?? [];

        if (unidades.isEmpty) {
          return const Center(
            child: Text('No se encontraron unidades'),
          );
        }

        return ListView.builder(
          itemCount: unidades.length,
          itemBuilder: (context, index) {
            final unidad = unidades[index];
            
            return ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text(unidad.matricula),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unidad.marca.isNotEmpty && unidad.modelo.isNotEmpty)
                    Text('${unidad.marca} - ${unidad.modelo}'),
                  Text('Kilometraje: ${unidad.km} km'),
                  if (unidad.descripcion.isNotEmpty)
                    Text('Descripción: ${unidad.descripcion}'),
                ],
              ),
              onTap: () {
                close(context, unidad);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Unidad>> _searchUnidades(BuildContext context) async {
    try {
      // Asumiendo que tienes un servicio para unidades
      final resultados = await unidadService.getUnidades(
        context,
        token,
        matricula: query
      );
      return resultados;
    } catch (e) {
      throw Exception('Error al buscar unidades: $e');
    }
  }

  @override
  String get searchFieldLabel => 'Buscar por matricula de la unidad...';
}