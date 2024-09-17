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
  late int tecnicoId = 0;
  int groupValue = 0;
  List trabajodres = [];
  // 1. Agrega una clave global para el RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<Orden> get ordenesFiltradas {
    if (groupValue == 0) {
      return ordenes.where((orden) => orden.estado == 'PENDIENTE').toList();
    } else if (groupValue == 1) {
      return ordenes.where((orden) => orden.estado == 'EN PROCESO').toList();
    } else if (groupValue == 2) {
      return ordenes.where((orden) => orden.estado == 'FINALIZADA').toList();
    }
    return [];
  }

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
      Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);
      setState(() {});
    } catch (e) {
      ordenes = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: const Text(
            'Lista de Ordenes',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.grey.shade200,
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: ordenes.length,
                  itemBuilder: (context, i) {
                    return Card(
                      surfaceTintColor: Colors.white,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      elevation: 20,
                      child: InkWell(
                        onTap: () {
                          final orden = ordenes[i];
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
                                    ordenes[i].ordenTrabajoId.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm:ss', 'es').format(ordenes[i].fechaOrdenTrabajo),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'SCN 1016', style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('${ordenes[i].cliente.codCliente} - ${ordenes[i].cliente.nombre}',),
                                  const VerticalDivider(),
                                  Text(ordenes[i].cliente.direccion),
                                  const VerticalDivider(),
                                  Text(ordenes[i].cliente.notas),
                                  const Spacer(),
                                  Text(ordenes[i].estado)
                                ],
                              ),
                              
                            ],
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
}
