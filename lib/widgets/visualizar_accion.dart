import 'package:flutter/material.dart';

import '../models/revision_pto_inspeccion.dart';

// ignore: must_be_immutable
class VisualizarAccion extends StatelessWidget {
  late RevisionPtoInspeccion? revision;

  VisualizarAccion({super.key, this.revision});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (revision!.codPuntoInspeccion == '') ...{
                  const Text(
                    'Falta dato obligatorio',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  )
                } else ...{
                  Text(
                    'Punto ${revision?.codPuntoInspeccion}',
                    style: const TextStyle(fontSize: 22),
                  ),
                },
                const Spacer(),
                Text(
                  revision!.codAccion.toString(),
                  style: TextStyle(fontSize: 22, color: colors.primary),
                )
              ],
            ),
            const SizedBox(height: 10,),
            if (revision!.piAccionId == 2 || revision!.piAccionId == 3) ...[
              const ContainerTituloPIRevision(
                titulo: 'Tareas',
              ),
              if (revision!.tareas.isEmpty) ...{
                const Text(
                  'Faltan datos obligatorios',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                )
              } else ...{
                for (var i = 0; i < revision!.tareas.length; i++) ...[
                  Text(
                    revision!.tareas[i].descTarea,
                    style: const TextStyle(fontSize: 16),
                  )
                ]
              }
            ],
            const SizedBox(height: 10,),
            if (revision!.piAccionId == 2) ...[
              const ContainerTituloPIRevision(titulo: 'Plagas'),
              if (revision!.plagas.isEmpty) ...{
                const Text(
                  'Faltan datos obligatorios',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                )
              } else ...{
                for (var i = 0; i < revision!.plagas.length; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 15,
                        child: Text(
                          revision!.plagas[i].descPlaga,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 1),
                      Flexible(
                        flex: 1,
                        child: TextFormField(
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: revision!.plagas[i].cantidad == null ? '' : revision!.plagas[i].cantidad.toString(),
                            enabled: false,
                            border: InputBorder.none
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              }
            ],
            const SizedBox(height: 10,),
            if (revision!.piAccionId == 2 || revision!.piAccionId == 3) ...[
              const ContainerTituloPIRevision(titulo: 'Materiales'),
              for (var i = 0; i < revision!.materiales.length; i++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 15,
                      child: Text(
                        revision!.materiales[i].descripcion,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Flexible(
                      flex: 1,
                      child: TextFormField(
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: revision!.materiales[i].cantidad.toString(),
                          enabled: false,
                          border: InputBorder.none
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            if (revision!.piAccionId == 5 || revision!.piAccionId == 6) ...[
              const ContainerTituloPIRevision(titulo: 'Zona'),
              if (revision!.trasladoNuevo[0].zona == '') ...{
                const Text(
                  'Faltan datos obligatorios',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                )
              } else ...{
                Text(
                  revision!.trasladoNuevo[0].zona == 'E' ? 'Exterior' : 'Interior',
                  style: const TextStyle(fontSize: 16),
                ),
              },
              const ContainerTituloPIRevision(titulo: 'Sector'),
              if (revision!.trasladoNuevo[0].sector == '') ...{
                const Text(
                  'Faltan datos obligatorios',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                )
              } else ...{
                Text(
                  revision!.trasladoNuevo[0].sector,
                  style: const TextStyle(fontSize: 16),
                ),
              }
            ],
            if (revision!.piAccionId == 5) ...[
              const ContainerTituloPIRevision(titulo: 'Plaga objetivo'),
              if (revision!.trasladoNuevo[0].plagaObjetivoId == 0) ...{
                const Text(
                  'Faltan datos obligatorios',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                )
              } else ...{
                Text(revision!.trasladoNuevo[0].plagaObjetivo),
              },
              const ContainerTituloPIRevision(titulo: 'Codigo de barras'),
              Text(revision!.codigoBarra),
            ],
            if (revision!.piAccionId == 1 ||
                revision!.piAccionId == 4 ||
                revision!.piAccionId == 5 ||
                revision!.piAccionId == 6 ||
                revision!.piAccionId == 7) ...[
              const ContainerTituloPIRevision(titulo: 'Comentario'),
              Text(
                revision!.comentario,
                style: const TextStyle(fontSize: 16),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class ContainerTituloPIRevision extends StatelessWidget {
  final String titulo;

  const ContainerTituloPIRevision({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 90, 163, 101),
        borderRadius: BorderRadius.circular(5)
      ),
      height: 30,
      child: Center(
        child: Text(
          titulo,
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 18
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
