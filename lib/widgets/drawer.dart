import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/providers/menu_providers.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/widgets/icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BotonesDrawer extends StatefulWidget {
  const BotonesDrawer({super.key});

  @override
  State<BotonesDrawer> createState() => _BotonesDrawerState();
}

class _BotonesDrawerState extends State<BotonesDrawer> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder(
      future: menuProvider.cargarDataJson(),
      initialData: const [],
      builder: (context, snapshot) {
        return ListView.builder(
          itemCount: menuProvider.opciones2.length,
          itemBuilder: (context, index) {
            return ExpansionTile(
              title: Text(
                menuProvider.opciones2[index]['camino'],
                style: const TextStyle(color: Colors.black),
              ),
              collapsedIconColor: colors.secondary,
              iconColor: colors.secondary,
              initiallyExpanded: true,
              children: _filaBotones2(snapshot.data, context, menuProvider.opciones2[index]['opciones']),
            );
          },
        );
      }
    );
  }
}

List<Widget> _filaBotones2(data, context, opciones) {
  final List<Widget> opcionesRet = [];
  final ordenProvider = Provider.of<OrdenProvider>(context, listen: false);
  opciones.forEach((opt) {
    final widgetTemp = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          getIcon(opt['icon'], context),
          TextButton(
            onPressed: () {
              if (opt['ruta'] == '/monitorOrdenes') {
                ordenProvider.setOrden(Orden.empty());
              }
              if (opt['ruta'] == '/listaOrdenes') {
                ordenProvider.setUnidadSeleccionada(Unidad.empty());
              }
              ordenProvider.setAdmOrdenes(true);
              router.push(opt['ruta']);
            },
            child: Text(opt['texto'])
          )
        ],
      ),
    );
    opcionesRet.add(widgetTemp);
  });
  return opcionesRet;
}
