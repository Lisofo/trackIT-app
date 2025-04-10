import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/providers/menu_providers.dart';
import 'package:app_tec_sedel/widgets/icons.dart';
import 'package:flutter/material.dart';

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
  opciones.forEach((opt) {
    final widgetTemp = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          getIcon(opt['icon'], context),
          TextButton(
            onPressed: () {
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
