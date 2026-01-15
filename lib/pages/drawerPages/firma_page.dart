// ignore_for_file: use_build_context_synchronously, avoid_print, void_checks

import 'dart:typed_data';

import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
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
  final _revisionServices = RevisionServices();
  TextEditingController nameController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  List<ClienteFirma> client = [];
  late int marcaId = 0;
  late Orden orden = Orden.empty();
  late String token = '';
  Uint8List? exportedImage;
  late String md5Hash = '';
  late List<int> firmaBytes = [];
  bool clienteNoDisponible = false;
  bool filtro = false;
  late String? firmaDisponible = '';
  bool cargoDatosCorrectamente = false;
  bool cargando = true;
  int contadorDeVeces = 0;
  bool guardandoFirma = false;
  int? statusCode;
  bool estoyEditando = false;
  bool estoyBorrando = false;


  SignatureController controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    try {
      orden = context.read<OrdenProvider>().orden;
      marcaId = context.read<OrdenProvider>().marcaId;
      if(orden.otRevisionId != 0){
        client = await RevisionServices().getRevisionFirmas(context, orden, token);
        firmaDisponible = await RevisionServices().getRevision(context, orden, token);
        contadorDeVeces++;
      }
      print(firmaDisponible);
      if(firmaDisponible == 'N'){
        clienteNoDisponible = true;
        filtro = true;
        controller.disabled = !controller.disabled;
      }
      if (contadorDeVeces > 1 && client.isNotEmpty){ //toDo && firmaDisponible != ''
        cargoDatosCorrectamente = true;
      }
      else if (contadorDeVeces == 1){
        cargoDatosCorrectamente = true;
      }
      cargando = false;
    } catch (e) {
      cargando = false;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: colors.primary,
          title: Text(
            '${orden.ordenTrabajoId} - Firma',
            style: const TextStyle(color: Colors.white),
          ),
        ),
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
          child: Column(
            children: [
              const SizedBox(height: 20,),
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
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(5)
                            ),
                            fillColor: !clienteNoDisponible ? Colors.white : Colors.grey,
                            filled: true,
                            hintText: 'Nombre'
                          ),
                          enabled: !clienteNoDisponible,
                        ),
                      ),
                      const SizedBox(height: 8,),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.primary,
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: TextFormField(
                          controller: areaController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(5)
                            ),
                            fillColor: !clienteNoDisponible ? Colors.white : Colors.grey,
                            filled: true,
                            hintText: 'Area'
                          ),
                          enabled: !clienteNoDisponible,
                        ),
                      )
                    ],
                  )
                ),
              ),
              const SizedBox(height: 8,),
              Padding(
                padding: const EdgeInsets.only(left: 5, right: 5),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colors.primary,
                      width: 2
                    ),
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: Signature(
                    controller: controller,
                    width: MediaQuery.of(context).size.width,
                    height: 200,
                    backgroundColor: !clienteNoDisponible ? Colors.white : Colors.grey,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(!clienteNoDisponible)...[
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomButton(
                        onPressed: !guardandoFirma ? () async {
                          guardandoFirma = true;
                          if(((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')) || clienteNoDisponible){
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(clienteNoDisponible ? 'Cliente no disponible' : 'No puede de ingresar o editar datos.'),
                            ));
                            guardandoFirma = false;
                            return Future.value(false);
                          }
                          if (nameController.text.isNotEmpty && areaController.text.isNotEmpty) {
                            await guardarFirma(context, null);
                            guardandoFirma = false;
                          } else {
                            completeDatosPopUp(context);
                            guardandoFirma = false;
                          }
                          guardandoFirma = false;
                          setState(() {});
                        } : null,
                        text: 'Guardar',
                        tamano: 20,
                        disabled: guardandoFirma,
                      ),
                      
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        onPressed: () {
                          controller.clear();
                        },
                        style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                          elevation: WidgetStatePropertyAll(10),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(50),
                                right: Radius.circular(50)
                              )
                            )
                          )
                        ),
                        child: Icon(
                          Icons.delete,
                          color: colors.primary,
                        )
                      ),
                    ),
                  ],
                  if(client.isEmpty)...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          activeColor: colors.primary,
                          value: filtro,
                          onChanged: (value) async {
                            if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('No puede de ingresar o editar datos.'),
                              ));
                              return Future.value(false);
                            }
                            if(value){
                              await _revisionServices.patchFirma(context, orden, 'N', token);
                            } else{
                              await _revisionServices.patchFirma(context, orden, null, token);
                            }
                            statusCode = await _revisionServices.getStatusCode();
                            await _revisionServices.resetStatusCode(); 

                            if(statusCode == 1){
                              setState(() {
                                filtro = value;
                                clienteNoDisponible = filtro;
                                controller.disabled = !controller.disabled;
                                controller.clear();
                                nameController.clear();
                                areaController.clear();
                              });
                            }
                            statusCode = null;

                            
                          }
                        ),
                        const Text('Cliente no disponible')
                      ],
                    ),
                  ]
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
                        if(((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')) || clienteNoDisponible){
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
                        if(statusCode == 1){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('La firma de $item ha sido borrada'),
                          ));
                          setState(() {
                            client.removeAt(index);
                          });
                        }
                        statusCode = null;
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
                          border: Border(
                            bottom: BorderSide()
                          )
                        ),
                        child: ListTile(
                          tileColor: Colors.white,
                          title: Text(client[index].nombre),
                          subtitle: Text(client[index].area),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                              onPressed: () async {
                                await showDialog(
                                  context: context, 
                                  builder: (context) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          item.firmaPath != '' ? Image.network('${item.firmaPath}?authorization=$token', width: 600, height: 450) : item.firma != null ? Image.memory(item.firma!, width: 600, height: 450) :const Center(child: Text('No hay firma registrada'),),
                                        ],
                                      ) 
                                    );
                                  },
                                );
                              }, 
                              child: const Text('Ver firma')
                            ),
                              IconButton(
                                splashColor: Colors.transparent,
                                splashRadius: 25,
                                icon: const Icon(Icons.edit),
                                onPressed: !estoyEditando ? () async {
                                  estoyEditando = true;
                                  if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('No puede de ingresar o editar datos.'),
                                    ));
                                    estoyEditando = false;
                                    return Future.value(false);
                                  }
                                  await _editarCliente(client[index]);
                                  estoyEditando = false;
                                  setState(() {});
                                } : null,
                              ),
                              IconButton(
                                splashColor: Colors.transparent,
                                splashRadius: 25,
                                icon: const Icon(Icons.delete),
                                onPressed: !estoyBorrando ? () async {
                                  estoyBorrando = true;
                                  if((orden.estado == 'PENDIENTE' || orden.estado == 'FINALIZADA')){
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('No puede de ingresar o editar datos.'),
                                    ));
                                    estoyBorrando = false;
                                    return Future.value(false);
                                  }
                                  await _borrarCliente(client[index], index);
                                  estoyBorrando = false;
                                } : null,
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
            await _revisionServices.deleteRevisionFirma(context, orden, client[index], token);
            statusCode = await _revisionServices.getStatusCode();
            await _revisionServices.resetStatusCode();
            if(statusCode == 1){
              Navigator.of(context).pop(true);
            }
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
    

    final ClienteFirma nuevaFirma = ClienteFirma(
      otFirmaId: 0,
      ordenTrabajoId: orden.ordenTrabajoId!,
      otRevisionId: orden.otRevisionId!,
      nombre: nameController.text,
      area: areaController.text,
      firmaPath: '',
      firmaMd5: md5Hash,
      comentario: '',
      firma: exportedImage
    );

    await _revisionServices.postRevisonFirma(context, orden, nuevaFirma, token);
    statusCode = await _revisionServices.getStatusCode();
    await _revisionServices.resetStatusCode();

    if(statusCode == 1){
      _agregarCliente(nuevaFirma);
    }else{
      print('error');
    }
    statusCode = null;
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

  void _agregarCliente(ClienteFirma cliente) {
    if (_formKey1.currentState!.validate()) {
      setState(() {
        client.add(cliente);

        nameController.clear();
        areaController.clear();
        controller.clear();
        exportedImage = null;
      });
    }
  }

  Future<void> _borrarCliente(ClienteFirma cliente, int index) async {
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
                await _revisionServices.deleteRevisionFirma(context, orden, cliente, token);
                statusCode = await _revisionServices.getStatusCode();
                await _revisionServices.resetStatusCode();

                if (statusCode == 1){
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('La firma de ${cliente.nombre} ha sido borrada'),
                  ));

                  setState(() {
                    client.removeAt(index);
                  });
                  router.pop();
                }
                statusCode = null;
                
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
                await _revisionServices.putRevisionFirma(context, orden, firma, nuevoNombre, nuevoArea, token);
                statusCode = await _revisionServices.getStatusCode();
                await _revisionServices.resetStatusCode();
                if(statusCode == 1){
                  firma.nombre = nuevoNombre;
                  firma.area = nuevoArea;
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ).then((result) {
      if(statusCode == 1){
        if (result != null && result['nombre'] != null && result['area'] != null) {
          setState(() {
            firma.nombre = result['nombre'];
            firma.area = result['area'];
          });
        }
      }     
    });
  }
}
