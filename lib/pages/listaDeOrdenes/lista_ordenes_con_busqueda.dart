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
  bool isMobile = false;
  bool isAdmin = false;

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
      var shortestSide = MediaQuery.of(context).size.shortestSide;
      isMobile = shortestSide < 600;
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
    isAdmin = context.watch<OrdenProvider>().admOrdenes;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          iconTheme: IconThemeData(
            color: colors.onPrimary
          ),
          title: const Text(
            'Ordenes',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: SearchBar(
                  controller: buscador,
                  hintText: 'Filtrar',
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
              onPressed: () {
                Provider.of<OrdenProvider>(context, listen: false).setOrden(Orden.empty());
                router.push('/monitorOrdenes');
              },
              icon: const Icon(Icons.add),
              tooltip: "Nueva orden",
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
                            if (isAdmin) {
                              router.push('/monitorOrdenes');
                            } else {
                              router.push('/ordenInterna');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(isMobile)...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            orden.numeroOrdenTrabajo.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            orden.fechaOrdenTrabajo != null
                                              ? DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(orden.fechaOrdenTrabajo!)
                                              : 'Fecha no disponible',
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.7,
                                            child: Text(orden.descripcion)
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Column(
                                        children: [
                                          if (MediaQuery.of(context).size.width < 1000)... [
                                            if(orden.alerta)
                                            const Icon(
                                              Icons.flag,
                                              color:Colors.red
                                            ),
                                            Text(
                                              orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(orden.estado)
                                          ]
                                          else ... [
                                            if(orden.alerta)
                                            const Icon(
                                              Icons.flag,
                                              color:Colors.red
                                            ),
                                            Text(
                                              orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ],
                                  ),
                                ]else...[
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            orden.numeroOrdenTrabajo.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        orden.fechaOrdenTrabajo != null
                                          ? DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(orden.fechaOrdenTrabajo!)
                                          : 'Fecha no disponible',
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(orden.descripcion),
                                      const Spacer(),
                                      Column(
                                        children: [
                                          if (MediaQuery.of(context).size.width < 1000)... [
                                            if(orden.alerta)
                                            const Icon(
                                              Icons.flag,
                                              color:Colors.red
                                            ),
                                            Text(
                                              orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(orden.estado)
                                          ]
                                          else ... [
                                            if(orden.alerta)
                                            const Icon(
                                              Icons.flag,
                                              color:Colors.red
                                            ),
                                            Text(
                                              orden.matricula.toString(), style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],

                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                                if (MediaQuery.of(context).size.width < 1000)... [
                                  Text('${orden.cliente.codCliente} - ${orden.cliente.nombre}',),
                                  Text(orden.comentarioCliente),
                                  Text(orden.comentarioTrabajo),
                                ]else ... [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width *0.2,
                                        child: Text('${orden.cliente.codCliente} - ${orden.cliente.nombre}',)
                                        ),
                                      const VerticalDivider(),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width *0.3,
                                        child: Text(orden.comentarioCliente)
                                      ),
                                      const VerticalDivider(),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width *0.3,
                                        child: Text(orden.comentarioTrabajo)
                                      ),
                                      const Spacer(),
                                      Text(orden.estado)
                                    ],
                                  ),
                                ],
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
          title: const Text('Cerrar sesión'),
          content: const Text('Esta seguro de querer cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('CANCELAR')
            ),
            TextButton(
              onPressed: () {
                Provider.of<OrdenProvider>(context, listen: false).setToken('');
                router.go('/');
              },
              child: const Text(
                'CERRAR SESIÓN',
                style: TextStyle(color: Colors.red),
              )
            ),
          ],
        );
      },
    );
  }
}
