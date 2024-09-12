// ignore_for_file: file_names

import 'package:app_tec_sedel/models/revision_pto_inspeccion.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/widgets/visualizar_accion.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PtosInspeccionRevisionPage extends StatefulWidget {
  const PtosInspeccionRevisionPage({super.key});

  @override
  State<PtosInspeccionRevisionPage> createState() => _PtosInspeccionRevisionPageState();
}

class _PtosInspeccionRevisionPageState extends State<PtosInspeccionRevisionPage> {
  late RevisionPtoInspeccion puntoSeleccionado = RevisionPtoInspeccion.empty();
  late List<RevisionPtoInspeccion> puntosSeleccionados = [];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() {
    puntoSeleccionado = context.read<OrdenProvider>().revisionPtoInspeccion;
    puntosSeleccionados = context.read<OrdenProvider>().puntosSeleccionados;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: const Text(
            'Revisión',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
            if (puntosSeleccionados.isNotEmpty) ...[
              for (var i = 0; i < puntosSeleccionados.length; i++) ...[
                VisualizarAccion(
                  revision: puntosSeleccionados[i],
                )
              ]
            ] else ...[
              VisualizarAccion(revision: puntoSeleccionado)
            ],
          ]),
        ),
      ),
    );
  }
}
