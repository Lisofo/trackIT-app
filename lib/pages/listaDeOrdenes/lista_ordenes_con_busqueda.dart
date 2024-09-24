// ignore_for_file: use_build_context_synchronously

import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';

class ListaOrdenesConBusqueda extends StatefulWidget {
  const ListaOrdenesConBusqueda({super.key});

  @override
  State<ListaOrdenesConBusqueda> createState() => _ListaOrdenesConBusquedaState();
}

class _ListaOrdenesConBusquedaState extends State<ListaOrdenesConBusqueda> {
  final ordenServices = OrdenServices();
  String token = '';
  List<Orden> ordenes = [];
  List<Orden> ordenesFiltradas = [];
  late int tecnicoId = 0;
  int groupValue = 0;
  List trabajodres = [];
  final TextEditingController buscador = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // 2. Método para manejar la actualización de datos
  Future<void> _refreshData() async {
    ordenes = [];
    setState(() {});
    await cargarDatos();
  }

  cargarDatos() async {
    try {
      token = context.read<OrdenProvider>().token;
      tecnicoId = context.read<OrdenProvider>().tecnicoId;
      ordenes = await ordenServices.getOrden(context, tecnicoId.toString(), "Anteriores", "Anteriores", token);
      ordenesFiltradas = ordenes; // Inicializa la lista de filtradas con todas las órdenes
      Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);
      setState(() {});
    } catch (e) {
      ordenes = [];
    }
  }

  void filtrarOrdenes(String query) {
    setState(() {
      if (query.isEmpty) {
        ordenesFiltradas = ordenes; // Muestra todas las órdenes si el filtro está vacío
      } else {
        // Filtrar las órdenes que coinciden con el criterio de búsqueda
        ordenesFiltradas = ordenes.where((orden) {
          final idMatch = orden.numeroOrdenTrabajo.toString().contains(query);
          final codClienteMatch = orden.cliente.codCliente.contains(query);
          final nombreClienteMatch = orden.cliente.nombre.toLowerCase().contains(query.toLowerCase());
          final notasMatch = orden.cliente.notas.toLowerCase().contains(query.toLowerCase());
          final matricula = orden.matricula!.toLowerCase().contains(query.toLowerCase());
          return idMatch || codClienteMatch || nombreClienteMatch || notasMatch || matricula;
        }).toList();
      }
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(
            color: colors.onPrimary
          ),
          title: const Text(
            'Lista de Ordenes',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: SearchBar(
                  controller: buscador,
                  hintText: 'Filtrar ordenes',
                  hintStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  leading: const Icon(Icons.search, color: Colors.black,),
                  onChanged: (value) {
                    filtrarOrdenes(value); // Llama al método de filtrado
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () async {
                logout();
              }, 
              icon: const Icon(
                Icons.logout,
                size: 34,
              )
            )
          ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: ordenes.length,
                  itemBuilder: (context, i) {
                    final orden = ordenes[i];
                    return Visibility(
                      visible: ordenesFiltradas.contains(ordenes[i]),
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            Provider.of<OrdenProvider>(context, listen: false).clearListaPto();
                            context.read<OrdenProvider>().setOrden(orden);
                            router.push('/ordenInterna');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      orden.numeroOrdenTrabajo.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(orden.fechaOrdenTrabajo),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    const Spacer(),
                                    Text(
                                      orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('${orden.cliente.codCliente} - ${orden.cliente.nombre}',),
                                    const VerticalDivider(),
                                    Text(orden.comentarioCliente),
                                    const VerticalDivider(),
                                    Text(orden.comentarioTrabajo),
                                    const Spacer(),
                                    Text(orden.estado)
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSegment(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesion'),
          content: const Text('Esta seguro de querer cerrar sesion?'),
          actions: [
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('Cancelar')
            ),
            TextButton(
              onPressed: () {
                Provider.of<OrdenProvider>(context, listen: false).setToken('');
                router.pushReplacement('/');
              },
              child: const Text(
                'Cerrar Sesion',
                style: TextStyle(color: Colors.red),
              )
            ),
          ],
        );
      },
    );
  }
}
