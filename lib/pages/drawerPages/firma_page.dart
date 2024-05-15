// ignore_for_file: use_build_context_synchronously, avoid_print, void_checks

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:crypto/crypto.dart';

import '../../models/clientes_firmas.dart';
import '../../models/orden.dart';
import '../../providers/orden_provider.dart';
import '../../services/revision_services.dart';
import '../../widgets/custom_button.dart';

class Firma extends StatefulWidget {
  const Firma({super.key});

  @override
  State<Firma> createState() => _FirmaState();
}

class _FirmaState extends State<Firma> {
  final _formKey1 = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  List<ClienteFirma> client = [];
  late int marcaId = 0;
  late Orden orden = Orden.empty();
  late String token = '';
  Uint8List? exportedImage;
  late String md5Hash = '';
  late List<int> firmaBytes = [];

  SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  void _agregarCliente() {
    if (_formKey1.currentState!.validate()) {
      setState(() {
        client.add(ClienteFirma(
          nombre: nameController.text,
          area: areaController.text,
          firma: exportedImage,
          otFirmaId: 0,
          firmaPath: '',
          ordenTrabajoId: 0,
          otRevisionId: 0,
          firmaMd5: '',
          comentario: '',
        ));

        nameController.clear();
        areaController.clear();
        controller.clear();
        exportedImage = null;
      });
    }
  }

  Future<void> _borrarCliente(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text("Confirmar"),
          content: const Text("¿Estas seguro de querer borrar la firma?"),
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
                Navigator.of(context).pop();
                await RevisionServices().deleteRevisionFirma(context, orden, client[index], token);
                setState(() {
                  client.removeAt(index);
                });
              },
              child: const Text("BORRAR")
            ),
          ],
        );
      }
    );
  }

  Future<void> _editarCliente(ClienteFirma firma) async {
    String nuevoNombre = firma.nombre;
    String nuevoArea = firma.area;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Editar Cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: nuevoNombre),
                onChanged: (value) {
                  nuevoNombre = value;
                },
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: TextEditingController(text: nuevoArea),
                onChanged: (value) {
                  nuevoArea = value;
                },
                decoration: const InputDecoration(labelText: 'Área'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                firma.area = nuevoArea;
                firma.nombre = nuevoNombre;

                await RevisionServices().putRevisionFirma(context, orden, firma, token);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null &&
          result['nombre'] != null &&
          result['area'] != null) {
        setState(() {
          firma.nombre = result['nombre'];
          firma.area = result['area'];
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<OrdenProvider>().token;
    orden = context.read<OrdenProvider>().orden;
    marcaId = context.read<OrdenProvider>().marcaId;
    client = await RevisionServices().getRevisionFirmas(orden, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: colors.primary,
          title: Text(
            '${orden.ordenTrabajoId} - Firma',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Form(
                    key: _formKey1,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.primary,
                                  width: 2),
                              borderRadius: BorderRadius.circular(5)),
                          child: TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(5)),
                                fillColor: Colors.white,
                                filled: true,
                                hintText: 'Nombre'),
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.primary,
                                  width: 2),
                              borderRadius: BorderRadius.circular(5)),
                          child: TextFormField(
                            controller: areaController,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(5)),
                                fillColor: Colors.white,
                                filled: true,
                                hintText: 'Area'),
                          ),
                        )
                      ],
                    )),
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: colors.primary,
                          width: 2),
                      borderRadius: BorderRadius.circular(5)),
                  child: Signature(
                      controller: controller,
                      width: 350,
                      height: 200,
                      backgroundColor: Colors.white),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: CustomButton(
                      onPressed: () async {
                        if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('No puede de ingresar o editar datos.'),
                          ));
                          return Future.value(false);
                        }
                        if (nameController.text.isNotEmpty && areaController.text.isNotEmpty) {
                          await guardarFirma(context, null);
                        } else {
                          completeDatosPopUp(context);
                        }
                      },
                      text: 'Guardar',
                      tamano: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                        onPressed: () {
                          controller.clear();
                        },
                        style: const ButtonStyle(
                            backgroundColor:
                                MaterialStatePropertyAll(Colors.white),
                            elevation: MaterialStatePropertyAll(10),
                            shape: MaterialStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.horizontal(
                                        left: Radius.circular(50),
                                        right: Radius.circular(50))))),
                        child: Icon(
                          Icons.delete,
                          color: colors.primary,
                        )),
                  )
                ],
              ),
              // if (exportedImage != null) Image.memory(exportedImage!),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: client.length,
                  itemBuilder: (context, index) {
                    final item = client[index];
                    return Dismissible(
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
                            return borrarDesdeDismiss(context, index);
                          }
                        );
                      },
                      onDismissed: (direction) async {
                        setState(() {
                          client.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('La firma de $item ha sido borrada'),
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
                          tileColor: Colors.white,
                          title: Text(client[index].nombre),
                          subtitle: Text(client[index].area),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                splashColor: Colors.transparent,
                                splashRadius: 25,
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('No puede de ingresar o editar datos.'),
                                    ));
                                    return Future.value(false);
                                  }
                                  await _editarCliente(client[index]);
                                },
                              ),
                              IconButton(
                                splashColor: Colors.transparent,
                                splashRadius: 25,
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  if(marcaId == 0 || (orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('No puede de ingresar o editar datos.'),
                                    ));
                                    return Future.value(false);
                                  }
                                  await _borrarCliente(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  AlertDialog borrarDesdeDismiss(BuildContext context, int index) {
    return AlertDialog(
      surfaceTintColor: Colors.white,
      title: const Text("Confirmar"),
      content: const Text("¿Estas seguro de querer borrar la firma?"),
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
            await RevisionServices().deleteRevisionFirma(context, orden, client[index], token);
          },
          child: const Text("BORRAR")
          ),
      ],
    );
  }

  Future<void> guardarFirma(BuildContext context, Uint8List? firma) async {
    exportedImage = firma ?? await controller.toPngBytes();
    firmaBytes = exportedImage as List<int>;
    md5Hash = calculateMD5(firmaBytes);
    int? statusCode;

    final ClienteFirma nuevaFirma = ClienteFirma(
      otFirmaId: 0,
      ordenTrabajoId: orden.ordenTrabajoId,
      otRevisionId: orden.otRevisionId,
      nombre: nameController.text,
      area: areaController.text,
      firmaPath: '',
      firmaMd5: md5Hash,
      comentario: '',
      firma: exportedImage
    );

    RevisionServices revisionServices = RevisionServices();

    await revisionServices.postRevisonFirma(context, orden, nuevaFirma, token);
    statusCode = await revisionServices.getStatusCode();

    if(statusCode == 201){
      _agregarCliente();
    }else{
      print('error');
    }
  }

  void completeDatosPopUp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: const Text('Campos vacíos'),
          content: const Text(
            'Por favor, completa todos los campos antes de guardar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String calculateMD5(List<int> bytes) {
    var md5c = md5.convert(bytes);
    return md5c.toString();
  }
}
