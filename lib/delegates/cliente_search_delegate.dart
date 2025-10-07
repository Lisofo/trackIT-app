import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/services/client_services.dart';

class ClienteSearchDelegate extends SearchDelegate<Cliente> {
  final String token;
  final ClientServices clientService;
  
  // Variable para controlar si se debe realizar la búsqueda
  bool _shouldSearch = false;

  ClienteSearchDelegate({
    required this.token,
    required this.clientService,
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
        close(context, Cliente.empty());
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Solo buscar cuando se presiona Enter
    if (_shouldSearch) {
      return _buildSearchResults(context);
    } else {
      return _buildInitialState();
    }
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Mostrar estado inicial o resultados según corresponda
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
            'Escriba el nombre y presione Enter',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<Cliente>>(
      future: _searchClientes(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final clientes = snapshot.data ?? [];

        if (clientes.isEmpty) {
          return const Center(
            child: Text('No se encontraron clientes'),
          );
        }

        return ListView.builder(
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            final cliente = clientes[index];
            final nombreCompleto = '${cliente.nombre} ${cliente.nombreFantasia}';
            
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(nombreCompleto),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cliente.ruc.isNotEmpty)
                    Text('RUC: ${cliente.ruc}'),
                  if (cliente.telefono1.isNotEmpty)
                    Text('Teléfono: ${cliente.telefono1}'),
                  if (cliente.direccion.isNotEmpty)
                    Text('Dirección: ${cliente.direccion}'),
                ],
              ),
              onTap: () {
                close(context, cliente);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Cliente>> _searchClientes(BuildContext context) async {
    try {
      final resultados = await clientService.getClientes(
        context,
        query, // nombre
        '',    // codCliente
        null,  // estado
        '0',   // tecnicoId (0 para todos)
        token,
      );
      return resultados ?? [];
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  @override
  String get searchFieldLabel => 'Buscar por nombre...';
}