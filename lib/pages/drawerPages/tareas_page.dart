// ignore_for_file: use_build_context_synchronously, void_checks

import 'package:app_track_it/models/orden.dart';
import 'package:app_track_it/models/revision_tarea.dart';
import 'package:app_track_it/models/tarea.dart';
import 'package:app_track_it/providers/orden_provider.dart';
import 'package:app_track_it/services/revision_services.dart';
import 'package:app_track_it/services/tareas_services.dart';
import 'package:app_track_it/widgets/custom_button.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  List<Tarea> tareas = [];
  late String token = '';
  final ScrollController _scrollController = ScrollController();
  List<Tarea> tareasSeleccionadas = [];
  Tarea selectedTarea = Tarea.empty();
  late Orden orden = Orden.empty();
  late List<RevisionTarea> revisionTareasList = [];
  late int marcaId = 0;
  bool isReadOnly = true;

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
    token = context.read<OrdenProvider>().token;
    tareas = await TareasServices().getTareas(token);
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    revisionTareasList = await RevisionServices().getRevisionTareas(orden, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: colors.primary,
        title: Text(
          '${orden.ordenTrabajoId} - Tareas Realizadas',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 1, color: colors.primary),
                    borderRadius: BorderRadius.circular(5)),
                child: DropdownSearch(
                  items: tareas,
                  popupProps: const PopupProps.menu(
                      showSearchBox: true, searchDelay: Duration.zero),
                  onChanged: (value) {
                    setState(() {
                      selectedTarea = value;
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    onPressed: () async {
                      if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede de ingresar o editar datos.'),
                        ));
                        return Future.value(false);
                      }
                      bool agregarTarea = true;
                      if (revisionTareasList.isNotEmpty) {
                        agregarTarea = !revisionTareasList.any((tarea) => tarea.tareaId == selectedTarea.tareaId);
                      }
                      if (agregarTarea) {
                        await posteoRevisionTarea(context);
                        setState(() {});
                      }
                    },
                    text: 'Agregar +',
                    tamano: 20,
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: revisionTareasList.length,
                  itemBuilder: (context, i) {
                    final item = revisionTareasList[i];
                    return Dismissible(
                      key: Key(item.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (DismissDirection direction) {
                        if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('No puede de ingresar o editar datos.'),
                          ));
                          return Future.value(false);
                        }
                        return showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                surfaceTintColor: Colors.white,
                                title: const Text("Confirmar"),
                                content: const Text(
                                    "¿Estas seguro de querer borrar la tarea?"),
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
                                      onPressed: () async {
                                        Navigator.of(context).pop(true);
                                        await RevisionServices().deleteRevisionTarea(context, orden, revisionTareasList[i], token);
                                      },
                                      child: const Text("BORRAR")),
                                ],
                              );
                            });
                      },
                      onDismissed: (direction) async {
                        setState(() {
                          revisionTareasList.removeAt(i);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('La tarea $item ha sido borrada'),
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
                      child: Container(
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide())),
                        child: ListTile(
                          title: Text(revisionTareasList[i].descripcion),
                          trailing: IconButton(
                              onPressed: () async {
                                if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('No puede de ingresar o editar datos.'),
                                  ));
                                  return Future.value(false);
                                }
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        surfaceTintColor: Colors.white,
                                        title: const Text("Confirmar"),
                                        content: const Text(
                                            "¿Estas seguro de querer borrar la tarea?"),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text("CANCELAR"),
                                          ),
                                          TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              onPressed: () async {
                                                await borrarTarea(context, i);
                                              },
                                              child: const Text("BORRAR")),
                                        ],
                                      );
                                    });
                              },
                              icon: const Icon(Icons.delete)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> borrarTarea(BuildContext context, int i) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('La tarea ${revisionTareasList[i].descripcion} ha sido borrada'),
    ));
    await RevisionServices().deleteRevisionTarea(context, orden, revisionTareasList[i], token);
    setState(() {
      revisionTareasList.removeAt(i);
    });
  }

  Future<void> posteoRevisionTarea(BuildContext context) async {
    var nuevaTarea = RevisionTarea(
        otTareaId: 0,
        ordenTrabajoId: orden.ordenTrabajoId,
        otRevisionId: orden.otRevisionId,
        tareaId: selectedTarea.tareaId,
        codTarea: selectedTarea.codTarea,
        descripcion: selectedTarea.descripcion,
        comentario: '');
    await RevisionServices().postRevisionTarea(
        context, orden, selectedTarea.tareaId, nuevaTarea, token);
    revisionTareasList.add(nuevaTarea);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
