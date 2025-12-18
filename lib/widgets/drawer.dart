import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/menu.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
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
    final authProvider = context.read<AuthProvider>();
    return FutureBuilder(
      future: menuProvider.cargarDataAdm(context, authProvider.token),
      initialData: const [],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(),);
        } else if (snapshot.hasError) {
          return Center(child: Text('Error ${snapshot.error}'),);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        } else {
          final List<Ruta> rutas = snapshot.data as List<Ruta>;

          return ListView.builder(
            controller: ScrollController(),
            itemCount: rutas.length,
            itemBuilder: (context, index) {
              final Ruta ruta = rutas[index];
              return ExpansionTile(
                title: Text(
                  ruta.camino,
                  style: const TextStyle(color: Colors.black),
                ),
                collapsedIconColor: colors.secondary,
                iconColor: colors.secondary,
                initiallyExpanded: true,
                children: _filaBotones2(ruta.opciones, context),
              );
            },
          );
        }
      }
    );
  }
}

List<Widget> _filaBotones2(List<Opcion> opciones, BuildContext context) {
  final List<Widget> opcionesRet = [];
  final ordenProvider = Provider.of<OrdenProvider>(context, listen: false);
  for (var opt in opciones) {
    final widgetTemp = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          getIcon(opt.icon, context),
          TextButton(
            onPressed: () {
              if (opt.ruta == '/monitorOrdenes') {
                ordenProvider.setOrden(Orden.empty());
              }
              if (opt.ruta == '/listaOrdenes') {
                ordenProvider.setUnidadSeleccionada(Unidad.empty());
                ordenProvider.setCliente(Cliente.empty());
              }
              ordenProvider.setAdmOrdenes(true);
              router.push(opt.ruta);
            },
            child: Text(opt.texto)
          )
        ],
      ),
    );
    opcionesRet.add(widgetTemp);
  }
  return opcionesRet;
}
