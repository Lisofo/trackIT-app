// ignore_for_file: use_build_context_synchronously, void_checks

import 'package:app_track_it/models/gradoInfestacion.dart';
import 'package:app_track_it/models/orden.dart';
import 'package:app_track_it/models/plaga.dart';
import 'package:app_track_it/models/revision_plaga.dart';
import 'package:app_track_it/providers/orden_provider.dart';
import 'package:app_track_it/services/plagas_services.dart';
import 'package:app_track_it/services/revision_services.dart';
import 'package:app_track_it/widgets/custom_button.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlagasPage extends StatefulWidget {
  const PlagasPage({super.key});

  @override
  State<PlagasPage> createState() => _PlagasPageState();
}

class _PlagasPageState extends State<PlagasPage> {
  List<Plaga> plagas = [];

  List<GradoInfestacion> gradoInfeccion = [
    GradoInfestacion(
        gradoInfestacionId: 1,
        codGradoInfestacion: '1',
        descripcion: 'Sin Avistamiento'),
    GradoInfestacion(
        gradoInfestacionId: 2,
        codGradoInfestacion: '2',
        descripcion: 'Población Controlada - Aceptable'),
    GradoInfestacion(
        gradoInfestacionId: 3,
        codGradoInfestacion: '3',
        descripcion: 'Población Media - Requiere Atención'),
    GradoInfestacion(
        gradoInfestacionId: 4,
        codGradoInfestacion: '4',
        descripcion: 'Población Alta - Grave'),
  ];
  List<Plaga> plagasSeleccionadas = [];
  late Plaga selectedPlaga = Plaga.empty();
  List<GradoInfestacion> gradosSeleccionados = [];
  GradoInfestacion selectedGrado = GradoInfestacion.empty();
  final ScrollController _scrollController = ScrollController();
  late String token = '';
  late Orden orden = Orden.empty();
  late List<RevisionPlaga> revisionPlagasList = [];
  bool isReadOnly = true;
  late int marcaId = 0;

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
    plagas = await PlagaServices().getPlagas(token);
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    revisionPlagasList = await RevisionServices().getRevisionPlagas(orden, token);
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
          '${orden.ordenTrabajoId} - Plagas',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 2,
                        color: colors.primary),
                    borderRadius: BorderRadius.circular(5)),
                child: DropdownSearch(
                  items: plagas,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true, searchDelay: Duration.zero
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedPlaga = value;
                    });
                  },
                )),
            const SizedBox(height: 30,),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: colors.primary),
                  borderRadius: BorderRadius.circular(5)),
              child: DropdownSearch(
                items: gradoInfeccion,
                popupProps: const PopupProps.menu(
                    showSearchBox: true, searchDelay: Duration.zero),
                onChanged: (value) {
                  setState(() {
                    selectedGrado = value;
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
                    bool agregarPlaga = true;
                    if (revisionPlagasList.isNotEmpty) {
                      agregarPlaga = !revisionPlagasList.any((plaga) => plaga.plagaId == selectedPlaga.plagaId);
                    }
                    if (agregarPlaga) {
                      await posteoRevisionPlaga(context);
                      setState(() {});
                    }
                  },
                  text: 'Agregar +',
                  tamano: 20,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: revisionPlagasList.length,
                  itemBuilder: (context, index) {
                    final item = revisionPlagasList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: Key(item.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (DismissDirection direction) async {
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
                                  "¿Estas seguro de querer borrar la plaga?"),
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
                                      Navigator.of(context).pop(true);
                                      await RevisionServices().deleteRevisionPlaga(context,orden,revisionPlagasList[index],token);
                                    },
                                    child: const Text("BORRAR")
                                  ),
                                ],
                              );
                            }
                          );
                        },
                        onDismissed: (direction) async {
                          setState(() {
                            revisionPlagasList.removeAt(index);
                          });
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text('La plaga $item ha sido borrada'),
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
                        child: Container(
                          decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide())),
                          child: ListTile(
                            title: Text(revisionPlagasList[index].plaga),
                            subtitle: Text(revisionPlagasList[index].gradoInfestacion),
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
                                              "¿Estas seguro de querer borrar la plaga?"),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text("CANCELAR"),
                                            ),
                                            TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.red,
                                                ),
                                                onPressed: () async {
                                                  await borrarPlaga(context, index);
                                                },
                                                child:
                                                    const Text("BORRAR")),
                                          ],
                                        );
                                      });
                                },
                                icon: const Icon(Icons.delete)),
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

  Future<void> borrarPlaga(BuildContext context, int index) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('La plaga ${revisionPlagasList[index].plaga} ha sido borrada'),
    ));
    await RevisionServices().deleteRevisionPlaga(context, orden, revisionPlagasList[index], token);

    setState(() {
      revisionPlagasList.removeAt(index);
    });
    
  }

  Future<void> posteoRevisionPlaga(BuildContext context) async {
    var nuevaPlaga = RevisionPlaga(
        otPlagaId: 0,
        ordenTrabajoId: orden.ordenTrabajoId,
        otRevisionId: orden.otRevisionId,
        comentario: '',
        plagaId: selectedPlaga.plagaId,
        codPlaga: selectedPlaga.codPlaga,
        plaga: selectedPlaga.descripcion,
        gradoInfestacionId: selectedGrado.gradoInfestacionId,
        codGradoInfestacion: selectedGrado.codGradoInfestacion,
        gradoInfestacion: selectedGrado.descripcion);
    await RevisionServices().postRevisionPlaga(
        context,
        orden,
        selectedPlaga.plagaId,
        selectedGrado.gradoInfestacionId,
        nuevaPlaga,
        token);
    revisionPlagasList.add(nuevaPlaga);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
