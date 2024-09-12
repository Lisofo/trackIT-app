// ignore_for_file: use_build_context_synchronously

import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';

class ListaOrdenes extends StatefulWidget {
  const ListaOrdenes({super.key});

  @override
  State<ListaOrdenes> createState() => _ListaOrdenesState();
}

DateTime fecha = DateTime.now();
DateTime fecha2 = DateTime(fecha.year, fecha.month, fecha.day + 1);


String fechaHoy = DateFormat('yyyy-MM-dd', 'es').format(fecha);
String fechaManana = DateFormat('yyyy-MM-dd', 'es').format(fecha2);
List<String> fechas = [fechaHoy, fechaManana, 'Anteriores'];

class _ListaOrdenesState extends State<ListaOrdenes> {
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
      ordenes = await ordenServices.getOrden(context, tecnicoId.toString(), opcionActual, opcionActual, token);
      Provider.of<OrdenProvider>(context, listen: false).setOrdenes(ordenes);
      setState(() {});
    } catch (e) {
      ordenes = [];
    }
  }

  String opcionActual = fechas[0];
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
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          surfaceTintColor: Colors.white,
                          title: const Text('Cambiar de fechas'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile(
                                title: Text(fechas[0]),
                                value: fechas[0],
                                groupValue: opcionActual,
                                onChanged: (value) {
                                  setState(() {
                                    opcionActual = value.toString();
                                  });
                                },
                              ),
                              RadioListTile(
                                title: Text(fechas[1]),
                                value: fechas[1],
                                groupValue: opcionActual,
                                onChanged: (value) {
                                  setState(() {
                                    opcionActual = value.toString();
                                  });
                                },
                              ),
                              RadioListTile(
                                title: Text(fechas[2]),
                                value: fechas[2],
                                groupValue: opcionActual,
                                onChanged: (value) {
                                  setState(() {
                                    opcionActual = value.toString();
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Confirmar'),
                              onPressed: () {
                                cargarDatos();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.date_range_rounded,
                color: Colors.white,
              ),
            )
          ],
        ),
        backgroundColor: Colors.grey.shade200,
        body: Column(
          children: [
            CupertinoSegmentedControl<int>(
              padding: const EdgeInsets.all(10),
              groupValue: groupValue,
              borderColor: Colors.black,
              selectedColor: colors.primary,
              unselectedColor: Colors.white,
              children: {
                0: buildSegment('Pendiente'),
                1: buildSegment('En Proceso'),
                2: buildSegment('Finalizado'),
              },
              onValueChanged: (newValue) {
                setState(() {
                  groupValue = newValue;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: ordenesFiltradas.length,
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
                          final orden = ordenesFiltradas[i];
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
                                    ordenesFiltradas[i].ordenTrabajoId.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    DateFormat('EEEE d, MMMM yyyy', 'es').format(ordenesFiltradas[i].fechaOrdenTrabajo),
                                  ),
                                  const Expanded(child: Text('')),
                                  Text(ordenesFiltradas[i].tipoOrden.descripcion),
                                ],
                              ),
                              Text('${ordenesFiltradas[i].cliente.codCliente} - ${ordenesFiltradas[i].cliente.nombre}',),
                              Text(ordenesFiltradas[i].cliente.direccion),
                              Text(ordenesFiltradas[i].cliente.telefono1),
                              Text(ordenesFiltradas[i].cliente.notas),
                              Text(ordenesFiltradas[i].instrucciones),
                              for (var j = 0; j < ordenesFiltradas[i].servicio.length; j++) ...[
                                Text(ordenesFiltradas[i].servicio[j].descripcion,)
                              ],
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
