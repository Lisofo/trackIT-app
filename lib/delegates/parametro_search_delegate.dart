// ignore_for_file: overridden_fields

import 'package:app_tec_sedel/models/informes_values.dart';
import 'package:app_tec_sedel/models/parametro.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/services/informes_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ParametroSearchDelegate extends SearchDelegate {
  @override
  final String searchFieldLabel;
  final List<ParametrosValues> historial;
  final int informeId;
  final int parametroId;
  final String? dependeDe;
  List<Parametro> parametros;
  ParametroSearchDelegate(this.searchFieldLabel, this.historial, this.informeId, this.parametroId, this.dependeDe, this.parametros);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
      IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.more_horiz)
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_ios_new),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Text('No hay criterios de búsqueda');
    }

    final clientServices = InformesServices();
    final token = context.watch<AuthProvider>().token;

    // final List<String> searchParams = query.split(" ");

    String id = '';
    String descripcion = '';
    
    descripcion = query;
    // if (searchParams.length >= 2) {
    //   id = searchParams[0];
    //   descripcion = searchParams.sublist(1).join(' ');
    // } else {
    //   if (int.tryParse(searchParams[0]) != null) {
    //     id = searchParams[0];
    //     descripcion = '';
    //   } else {
    //     id = '';
    //     descripcion = searchParams[0];
    //   }
    // }

    return FutureBuilder(
      future: clientServices.getParametrosValues(context, token, informeId, parametroId, id, descripcion, dependeDe.toString(), parametros),
      builder: (_, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const ListTile(
            title: Text('No se encontró en la busqueda'),
          );
        }

        if (snapshot.hasData) {
          return _showClient(snapshot.data!);
        } else {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 4),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _showClient(historial);
  }

  Widget _showClient(List<ParametrosValues> clients) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, i) {
        final cliente = clients[i];
        return ListTile(
          title: Text(cliente.descripcion.toString()),
          onTap: () {
            close(context, cliente);
          },
        );
      }
    );
  }
}
