  // ignore_for_file: file_names, avoid_print, use_build_context_synchronously, non_constant_identifier_names

import 'package:app_tec_sedel/models/materialesTPI.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/plagaXTPI.dart';
import 'package:app_tec_sedel/models/revision_materiales.dart';
import 'package:app_tec_sedel/models/revision_pto_inspeccion.dart';
import 'package:app_tec_sedel/models/tareaXtpi.dart';
import 'package:app_tec_sedel/models/tipos_ptos_inspeccion.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/plagas_services.dart';
import 'package:app_tec_sedel/services/ptos_services.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';

class PtosInspeccionActividad extends StatefulWidget {
  const PtosInspeccionActividad({super.key});

  @override
  State<PtosInspeccionActividad> createState() => _PtosInspeccionActividadState();
}

class _PtosInspeccionActividadState extends State<PtosInspeccionActividad> {
  late String token = '';
  late Orden orden = Orden.empty();
  late int marcaId = 0;
  bool isReadOnly = true;
  late TipoPtosInspeccion tPISeleccionado = TipoPtosInspeccion.empty();
  late List<RevisionPtoInspeccion> ptoInspeccionSeleccionados = [];
  List<TareaXtpi> tareas = [];
  List<PlagaXtpi> plagas = [];
  List<PtoPlaga> plagasSeleccionadas = [];
  late PlagaXtpi plagaSeleccionada = PlagaXtpi.empty();
  List<Lote> lotesVencimientos = [];
  TextEditingController cantidadController = TextEditingController();
  TextEditingController cantidadControllerMateriales = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  MaterialXtpi? materialSeleccionado;
  Lote? loteSeleccionado;
  late String menu = context.read<OrdenProvider>().menu;
  List<MaterialXtpi> materiales = [];
  List<PtoMaterial> materialesSeleccionados = [];
  bool subiendoAcciones = false;
  late RevisionPtoInspeccion nuevaRevisionPtoInspeccion = RevisionPtoInspeccion.empty();
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  final _ptosInspeccionServices = PtosInspeccionServices();
  final _tareasServices = TareasServices();
  final _materialesServices = MaterialesServices();
  int? statusCodeRevision;
  int? statusCodeTareas;
  int? statusCodeMateriales;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    try {
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      final String modo = context.read<OrdenProvider>().modo;
      tPISeleccionado = context.read<OrdenProvider>().tipoPtosInspeccion;
      ptoInspeccionSeleccionados = context.read<OrdenProvider>().puntosSeleccionados;
      tareas = await _tareasServices.getTareasXTPI(context, tPISeleccionado, modo, token);
      statusCodeTareas = await _tareasServices.getStatusCode();
      await _tareasServices.resetStatusCode();
      materiales = await _materialesServices.getMaterialesXTPI(context, tPISeleccionado, token);
      statusCodeMateriales = await _materialesServices.getStatusCode();
      await _materialesServices.resetStatusCode();

      if (orden.estado == "EN PROCESO" && marcaId != 0) {
        isReadOnly = false;
      }
      int accion = menu == "Actividad" ? 2 : 3;
      bool modificando = ptoInspeccionSeleccionados.length == 1 && ptoInspeccionSeleccionados[0].piAccionId == accion;
      if (modificando) {
        for (var tarea in tareas) {
          tarea.selected = ptoInspeccionSeleccionados[0].tareas.any((asignada) => asignada.tareaId == tarea.tareaId);
        }
        materialesSeleccionados = ptoInspeccionSeleccionados[0].materiales;
        plagasSeleccionadas = ptoInspeccionSeleccionados[0].plagas;
      }
      if (statusCodeMateriales == 1 && statusCodeTareas == 1){
        cargoDatosCorrectamente = true;
        statusCodeMateriales = null;
        statusCodeTareas = null;
      }
      cargando = false;
    }catch (e) {
      cargando = false;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${orden.ordenTrabajoId} - $menu',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: colors.primary,
        ),
        backgroundColor: Colors.grey.shade200,
        body: cargando ? const Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text('Cargando, por favor espere...')
          ],
        ),
      ) : !cargoDatosCorrectamente ? 
      Center(
        child: TextButton.icon(
          onPressed: () async {
            await cargarDatos();
          }, 
          icon: const Icon(Icons.replay_outlined),
          label: const Text('Recargar'),
        ),
      ) : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(5)),
                  height: 30,
                  child: const Center(
                    child: Text(
                      'Tareas',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: tareas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas[index];
                      return CheckboxListTile(
                        activeColor: colors.primary,
                        title: Text(tarea.descripcion),
                        value: tarea.selected,
                        onChanged: (newValue) {
                          setState(() {
                            tarea.selected = newValue ?? false;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                if (menu == 'Actividad') ...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Flexible(
                          flex: 10,
                          child: Container(
                            decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(5)),
                            height: 30,
                            child: const Center(
                              child: Text(
                                'Plagas',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          flex: 1,
                          child: PopUpPlagas(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 230,
                    ),
                    child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: plagasSeleccionadas.length,
                        itemBuilder: (context, i) {
                          final plaga = plagasSeleccionadas[i];
                          return Dismissible(
                            key: Key(plaga.toString()),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (DismissDirection direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    surfaceTintColor: Colors.white,
                                    title: const Text("Confirmar"),
                                    content: const Text(
                                        "¿Estas seguro de querer borrar el item?"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("CANCELAR"),
                                      ),
                                      TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text("BORRAR")),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              setState(() {
                                plagasSeleccionadas.removeAt(i);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('$plaga borrado'),
                              ));
                            },
                            background: Container(
                              color: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              alignment: AlignmentDirectional.centerEnd,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: ListTile(
                              title: Text(plaga.descPlaga),
                              trailing: Text(plaga.cantidad == null ? '' : plaga.cantidad.toString()),
                            ),
                          );
                        }),
                  ),
                ],
                const SizedBox(
                  height: 20,
                ),
                Container(
                  decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(5)),
                  height: 30,
                  child: const Center(
                    child: Text(
                      'Materiales',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          width: 2,
                          color: colors.primary),
                      borderRadius: BorderRadius.circular(5)),
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(border: InputBorder.none),
                    items: materiales.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            e.descripcion,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                    isDense: true,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        materialSeleccionado = value;
                      });
                      mostrarPopupCantidadMateriales(materialSeleccionado!);
                    },
                    value: materialSeleccionado,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      controller: _scrollController,
                      itemCount: materialesSeleccionados.length,
                      itemBuilder: (context, i) {
                        final material = materialesSeleccionados[i];
                        return Dismissible(
                          key: Key(material.toString()),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (DismissDirection direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  surfaceTintColor: Colors.white,
                                  title: const Text("Confirmar"),
                                  content: const Text(
                                      "¿Estas seguro de querer borrar el item?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("CANCELAR"),
                                    ),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("BORRAR")),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            setState(() {
                              materialesSeleccionados.removeAt(i);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('$material borrado'),
                            ));
                          },
                          background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: AlignmentDirectional.centerEnd,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: ListTile(
                            title: Text(material.descripcion),
                            subtitle: Text(material.lote == '' ? "No hay lote disponible" : material.lote.toString()),
                            trailing: Text(material.cantidad.toString()),
                          ),
                        );
                      }),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 10,
          elevation: 0,
          shape: const CircularNotchedRectangle(),
          color: Colors.grey.shade200,
          child: ElevatedButton(
              clipBehavior: Clip.antiAlias,
              style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  elevation: WidgetStatePropertyAll(10),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(50),
                          right: Radius.circular(50))))),
              onPressed: () async {
                if(!subiendoAcciones){
                  subiendoAcciones = true;
                  if (menu == 'Mantenimiento') {
                    await marcarPIActividad(3, '');
                  } else {
                    await marcarPIActividad(2, '');
                  }
                }
              },
              child: Text(
                'Guardar',
                style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              )),
        ),
      ),
    );
  }

  Future marcarPIActividad(int idPIAccion, String comentario) async {
    List<PtoTarea> agregarTareas = [];
    agregarTareas = agregarTareasSeleccionadas(agregarTareas, tareas);

    for (var i = 0; i < ptoInspeccionSeleccionados.length; i++) {
      ptoInspeccionSeleccionados[i].codAccion = idPIAccion == 2 ? 'ACTIVIDAD' : 'MANTENIMIENTO';
      ptoInspeccionSeleccionados[i].idPIAccion = idPIAccion;
      ptoInspeccionSeleccionados[i].piAccionId = idPIAccion;
      ptoInspeccionSeleccionados[i].comentario = comentario;
      ptoInspeccionSeleccionados[i].plagas = List<PtoPlaga>.from(plagasSeleccionadas);
      ptoInspeccionSeleccionados[i].materiales = List<PtoMaterial>.from(materialesSeleccionados);
      ptoInspeccionSeleccionados[i].tareas = List<PtoTarea>.from(agregarTareas);
      ptoInspeccionSeleccionados[i].trasladoNuevo = [];
      Provider.of<OrdenProvider>(context, listen: false).actualizarPunto(i, ptoInspeccionSeleccionados[i]);
    }
    await postAcciones(ptoInspeccionSeleccionados);
    statusCodeRevision = null;
    subiendoAcciones = false;
  }

  Future postAcciones(List<RevisionPtoInspeccion> acciones) async {
    await _ptosInspeccionServices.postAcciones(context, orden, acciones, token);
    statusCodeRevision = await _ptosInspeccionServices.getStatusCode();
    await _ptosInspeccionServices.resetStatusCode();
    if(statusCodeRevision == 1) {
      await PtosInspeccionServices.showDialogs(context, acciones.length == 1 ? 'Accion creada' : 'Acciones creadas', true, true);
    }
  }

  Widget PopUpPlagas(BuildContext context) {
    return InkWell(
      onTap: () async {
        plagas = await PlagaServices().getPlagasXTPI(context, tPISeleccionado, token);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            PlagaXtpi? nuevaPlagaSeleccionada;
            String nuevaCantidad = '';
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateBd) {
                return AlertDialog(
                  surfaceTintColor: Colors.white,
                  title: const Text('Agregar Plaga'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: DropdownButtonFormField(
                          isExpanded: true,
                          items: plagas.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text(e.descripcion),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              nuevaPlagaSeleccionada = value;
                            });
                          },
                          value: nuevaPlagaSeleccionada,
                        ),
                      ),
                      TextField(
                        onChanged: (value) {
                          nuevaCantidad = value;
                        },
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Cantidad'),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        late PtoPlaga nuevaPlaga = PtoPlaga(
                          otPiPlagaId: 0,
                          otPuntoInspeccionId: 0,
                          plagaId: nuevaPlagaSeleccionada!.plagaId,
                          codPlaga: nuevaPlagaSeleccionada!.codPlaga,
                          descPlaga: nuevaPlagaSeleccionada!.descripcion,
                          cantidad: nuevaCantidad == '' ? null : int.parse(nuevaCantidad)
                        );

                        if (nuevaPlagaSeleccionada != null) {
                          plagasSeleccionadas.add(nuevaPlaga);
                          Navigator.of(context).pop();
                          setState(() {
                            plagaSeleccionada = nuevaPlagaSeleccionada!;
                          });
                        }
                      },
                      child: const Text('Agregar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: const Icon(Icons.add),
    );
  }

  mostrarPopupCantidadMateriales(MaterialXtpi material) async {
    await cargarLotes();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Cantidad de materiales'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unidad: ${material.unidad}'),
              TextField(
                controller: cantidadControllerMateriales,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              DropdownButtonFormField(
                hint: const Text("Lotes/Vencimientos"),
                items: lotesVencimientos.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.lote),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    loteSeleccionado = value;
                  });
                },
                value: loteSeleccionado,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                cantidadControllerMateriales.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Agregar'),
              onPressed: () {
                final cantidad = cantidadControllerMateriales.text;
                late PtoMaterial nuevoMaterial = PtoMaterial(
                    otPiMaterialId: 0,
                    otPuntoInspeccionId: 0,
                    materialId: materialSeleccionado!.materialId,
                    codMaterial: materialSeleccionado!.codMaterial,
                    descripcion: materialSeleccionado!.descripcion,
                    dosis: materialSeleccionado!.dosis,
                    unidad: materialSeleccionado!.unidad,
                    cantidad: int.parse(cantidad),
                    materialLoteId: loteSeleccionado?.materialLoteId == null
                        ? null
                        : loteSeleccionado!.materialLoteId,
                    lote: loteSeleccionado?.lote == null
                        ? ''
                        : loteSeleccionado!.lote);
                if (cantidad.isNotEmpty && materialSeleccionado != null) {
                  materialesSeleccionados.add(nuevoMaterial);
                  cantidadControllerMateriales.clear();
                  setState(() {
                    materialSeleccionado = null;
                    loteSeleccionado = null;
                  });
                }
                Navigator.of(context).pop();
                setState(() {
                  // _scrollController.animateTo(
                  //   _scrollController.position.maxScrollExtent + 200,
                  //   duration: Duration(milliseconds: 500),
                  //   curve: Curves.easeInOut,
                  // );
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> cargarLotes() async {
    lotesVencimientos = await MaterialesServices().getLotes(context, materialSeleccionado!.materialId, token);
    setState(() {});
  }

  List<PtoTarea> agregarTareasSeleccionadas(List<PtoTarea> listaPtoTarea, List<TareaXtpi> listaTareaXtpi) {
    // Filtrar los elementos seleccionados de TareaXtpi
    List<TareaXtpi> tareasSeleccionadas = listaTareaXtpi.where((tarea) => tarea.selected).toList();

    // Convertir los elementos seleccionados a PtoTarea y agregarlos a la listaPtoTarea
    listaPtoTarea.addAll(tareasSeleccionadas.map((tareaXtpi) => 
      PtoTarea(
        otPiTareaId: tareaXtpi.configTpiTareaId, // Usar el campo adecuado según tus necesidades
        otPuntoInspeccionId: tareaXtpi.tipoPuntoInspeccionId, // Usar el campo adecuado según tus necesidades
        tareaId: tareaXtpi.tareaId,
        codTarea: tareaXtpi.codTarea,
        descTarea: tareaXtpi.descripcion,
      ))
    );
    return listaPtoTarea;
  }
}
