import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/delegates/parametro_search_delegate.dart';
import 'package:app_tec_sedel/models/informes.dart';
import 'package:app_tec_sedel/models/informes_values.dart';
import 'package:app_tec_sedel/models/parametro.dart';
import 'package:app_tec_sedel/models/reporte.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/informes_services.dart';
import 'package:app_tec_sedel/widgets/custom_form_dropdown.dart';
import 'package:app_tec_sedel/widgets/custom_form_field.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:url_launcher/url_launcher.dart';

class InformesPage extends StatefulWidget {
  const InformesPage({super.key});

  @override
  State<InformesPage> createState() => _InformesPageState();
}

class _InformesPageState extends State<InformesPage> {
  bool showSnackBar = false;
  bool expandChildrenOnReady = true;
  // ignore: unused_field
  TreeViewController? _controller;
  late String token = '';
  late List<Informe> informes = [];
  TreeNode sampleTree = TreeNode.root();
  dynamic selectedNodeData;
  late List<Parametro> parametros = [];
  late ParametrosValues campoCliente = ParametrosValues.empty();
  late ParametrosValues campoPlagaObjetivo = ParametrosValues.empty();
  late String campoFecha = '';
  late String campoFechaDesde = '';
  late String campoFechaHasta = '';
  late String campoOrdenTrabajo = '';
  late String campoIdRevision = '';
  List<ParametrosValues> historial = [];
  List<ParametrosValues> parametrosValues = [];
  final Map<String, TextEditingController> _controllers = {};
  late String nombreInforme = '';
  late MaskTextInputFormatter maskFormatter;
  late dynamic selectedInforme = InformeHijo.empty();
  int buttonIndex = 0;
  late String tipo = '';
  List<TiposImpresion> tipos = [];
  late int rptGenId = 0;
  late Reporte reporte = Reporte.empty();
  late bool generandoInforme = false;
  late bool informeGeneradoEsS = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  cargarDatos() async {
    token = context.read<AuthProvider>().token;
    try {
      informes = await InformesServices().getInformes(context, token);
    } catch (e) {
      informes = [];
    }
    setState(() {
      sampleTree = convertInformesToTreeNode(informes);
    });
  }

  String _sanitizeKey(String key) {
    // if (key.contains('.')) {
    //   print('La Key: $key tiene un punto');
    // }
    return key.replaceAll('.', '_');
  }

  abrirUrl(String url, String token) async {
    Dio dio = Dio();
    String link = url += '?authorization=$token';
    print(link);
    try {
      Response response = await dio.get(
        link,
        options: Options(
          headers: {
            'Authorization': 'headers $token',
          },
        ),
      );
      if (response.statusCode == 200) {
        Uri uri = Uri.parse(url);
        await launchUrl(uri);
      } else {
        print('Error al cargar la URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
    }
  }

  // MÉTODOS DE UI RESPONSIVA
  Widget _buildMobileLayout() {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      onDrawerChanged: (isOpened) async {
        await cargarDatos();
      },
      appBar: AppBar(
        title: const Text('Informes'),
        foregroundColor: colors.onPrimary,
        actions: [
          IconButton(
            onPressed: () {router.pop();},
            icon: const Icon(Icons.arrow_back)
          )
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.9,
        child: _buildTreeView(colors, expandOnReady: false),
      ),
      body: _buildMainContent(colors, isMobile: true),
    );
  }

  Widget _buildDesktopLayout() {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Informes'), foregroundColor: colors.onPrimary,),
      body: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: _buildTreeView(colors, expandOnReady: true),
          ),
          VerticalDivider(
            color: colors.secondary,
            width: 1,
          ),
          Expanded(child: _buildMainContent(colors, isMobile: false)),
        ],
      ),
    );
  }

  Widget _buildTreeView(ColorScheme colors, {bool expandOnReady = true}) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 0.8,
      child: TreeView.simple(
        tree: sampleTree,
        showRootNode: false,
        expansionIndicatorBuilder: (context, node) => ChevronIndicator.rightDown(
          tree: node,
          color: Colors.black,
          padding: const EdgeInsets.all(8),
        ),
        indentation: const Indentation(style: IndentStyle.squareJoint),
        onItemTap: (item) async {
          await _handleTreeItemTap(item);
        },
        onTreeReady: (controller) {
          _controller = controller;
          if (expandOnReady) controller.expandAllChildren(sampleTree);
        },
        builder: (context, node) => Card(
          color: colors.tertiary,
          child: node.data.objetoArbol == 'informe'
              ? ListTile(
                  title: Text(node.key),
                  leading: Icon(Icons.file_copy_outlined, color: colors.primary),
                )
              : ListTile(title: Text(node.key)),
        ),
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colors, {bool isMobile = true}) {
    if (generandoInforme) {
      return _buildLoadingState(colors);
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Text('Parametros del informe: $nombreInforme'),
        Divider(
          color: colors.primary,
          endIndent: 20,
          indent: 20,
        ),
        if (selectedNodeData != null) ...[
          if (parametros.isNotEmpty) ...[
            SizedBox(
              height: isMobile
                  ? MediaQuery.of(context).size.height * 0.6
                  : MediaQuery.of(context).size.height * 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  itemCount: parametros.length,
                  itemBuilder: (context, i) {
                    var parametro = parametros[i];
                    return isMobile
                        ? _buildMobileParametroRow(parametro, colors)
                        : _buildDesktopParametroRow(parametro, colors);
                  },
                ),
              ),
            ),
            if (selectedNodeData.objetoArbol == 'informe') ...[
              const Spacer(),
              const Center(child: Text('Seleccione formato de generacion del Informe')),
              const SizedBox(height: 5),
              Center(
                child: SizedBox(
                  width: isMobile
                      ? MediaQuery.of(context).size.width * 0.8
                      : 370,
                  child: CustomDropdownFormMenu(
                    value: tipos.isEmpty ? null : tipos[0],
                    isDense: true,
                    items: tipos.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.descripcion),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        tipo = (value as TiposImpresion).tipo;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildGenerateButton(colors),
            ]
          ]
        ],
      ],
    );
  }

  Widget _buildMobileParametroRow(Parametro parametro, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () async {
            await _handleParametroTap(parametro);
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: Text(
              parametro.obligatorio == 'S' ? '* ${parametro.parametro}' : parametro.parametro,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Text(parametro.comparador),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Text(
            parametro.valorAMostrar.toString(),
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }

  Widget _buildDesktopParametroRow(Parametro parametro, ColorScheme colors) {
    return Row(
      children: [
        TextButton(
          onPressed: () async {
            await _handleParametroTap(parametro);
          },
          child: Text(
            parametro.obligatorio == 'S' ? '* ${parametro.parametro}' : parametro.parametro,
          ),
        ),
        const SizedBox(width: 30),
        Text(parametro.comparador),
        const SizedBox(width: 30),
        Text(parametro.valorAMostrar.toString())
      ],
    );
  }

  Widget _buildGenerateButton(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: colors.primary)),
      height: MediaQuery.of(context).size.height * 0.1,
      child: InkWell(
        onTap: () async {
          if (await _validateRequiredFields()) {
            await postInforme(selectedInforme);
            await generarInformeCompleto(context);
            informeGeneradoEsS = false;
            setState(() {});
            tipo = tipos.isNotEmpty ? tipos[0].tipo : '';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hay campos obligatorios sin completar'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: colors.primary),
            Text('Generar Informe', style: TextStyle(color: colors.primary))
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: CircularProgressIndicator(
            color: colors.primary,
            strokeWidth: 5,
          ),
        ),
        const Text('Generando Informe, espere por favor.'),
        TextButton(
          onPressed: () async {
            await InformesServices().patchInforme(context, reporte, 'D', token);
            generandoInforme = false;
            setState(() {});
          },
          child: const Text('Cancelar'),
        )
      ],
    );
  }

  // MÉTODOS DE LÓGICA COMPARTIDA
  Future<void> _handleTreeItemTap(TreeNode item) async {
    if (item.data.objetoArbol == 'informe') {
      parametros = await InformesServices().getParametros(context, token, item.data.informeId);
      nombreInforme = item.key;
      selectedInforme = item.data;
      tipos = selectedInforme.tiposImpresion;
      tipo = tipos.isNotEmpty ? tipos[0].tipo : '';
    }
    for (var param in parametros) {
      if (param.control == 'T') {
        _controllers[param.parametro] = TextEditingController();
      }
    }
    setState(() {
      selectedNodeData = item.data;
    });

    // Cerrar drawer en móvil si es un informe sin hijos
    if (item.data.objetoArbol == 'informe' &&
        item.children.isEmpty &&
        MediaQuery.of(context).size.width < 800) {
      router.pop();
    }
  }

  Future<void> _handleParametroTap(Parametro parametro) async {
    if (parametro.control == 'D') {
      await _selectDate(context, parametro.parametro, parametro.tipo, parametro);
    } else if (parametro.control == 'L') {
      final valorSeleccionado = await showSearch(
        context: context,
        delegate: ParametroSearchDelegate(
          'Buscar ${parametro.parametro}',
          historial,
          parametro.informeId,
          parametro.parametroId,
          parametro.dependeDe,
          parametros,
        ),
      );
      if (valorSeleccionado != null) {
        parametro.valor = valorSeleccionado.id.toString();
        parametro.valorAMostrar = valorSeleccionado.descripcion;
        setState(() {});
      } else {
        parametro.valor = '';
        parametro.valorAMostrar = '';
      }
    } else {
      await _showPopup(context, parametro);
    }
  }

  Future<bool> _validateRequiredFields() async {
    for (var parametro in parametros) {
      if (parametro.obligatorio == 'S' && parametro.valor == '') {
        return false;
      }
    }
    return true;
  }

  // MÉTODOS DE GENERACIÓN DE INFORMES (compartidos)
  Future<void> generarInformeCompleto(BuildContext context) async {
    int contador = 0;
    generandoInforme = true;
    setState(() {});

    while (contador < 15 && !informeGeneradoEsS && generandoInforme) {
      reporte = await InformesServices().getReporte(context, rptGenId, token);
      if (reporte.generado == 'S') {
        informeGeneradoEsS = true;
        await abrirUrl(reporte.archivoUrl, token);
        generandoInforme = false;
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
      contador++;
    }

    if (!informeGeneradoEsS && generandoInforme) {
      await _showTimeoutDialog(context);
    }
    setState(() {});
  }

  Future<void> _showTimeoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Su informe esta tardando demasiado en generarse, quiere seguir esperando?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                generandoInforme = false;
                await InformesServices().patchInforme(context, reporte, 'D', token);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('No'),
            ),
            TextButton(
              child: const Text('Si'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _generateInfinite();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateInfinite() async {
    generandoInforme = true;
    while (!informeGeneradoEsS) {
      reporte = await InformesServices().getReporte(context, rptGenId, token);
      if (reporte.generado == 'S') {
        informeGeneradoEsS = true;
        await abrirUrl(reporte.archivoUrl, token);
        generandoInforme = false;
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    setState(() {});
  }

  // MÉTODOS DE UI PARA PARÁMETROS (compartidos)
  Future<void> _showPopup(BuildContext context, Parametro parametro) async {
    if (parametro.control == 'T') {
      _controllers[parametro.parametro] = TextEditingController();
    }
    if (parametro.sql != '') {
      parametrosValues = await InformesServices().getParametrosValues(
        context,
        token,
        parametro.informeId,
        parametro.parametroId,
        '',
        '',
        parametro.dependeDe.toString(),
        parametros,
      );
    }
    if (parametro.control == 'T' && parametro.tipo == 'N') {
      maskFormatter = MaskTextInputFormatter(
        mask: '###############',
        filter: {"#": RegExp(r'[0-9]')},
      );
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(parametro.parametro),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parametro.control == 'C') ...[
                SizedBox(
                  width: 300,
                  child: DropdownSearch(
                    items: parametrosValues,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchDelay: Duration.zero,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        parametro.valor = (value as ParametrosValues).id.toString();
                        parametro.valorAMostrar = (value).descripcion;
                      }
                    },
                  ),
                ),
              ] else if (parametro.control == 'T') ...[
                SizedBox(
                  width: 370,
                  child: CustomTextFormField(
                    controller: _controllers[parametro.parametro],
                    hint: parametro.parametro,
                    mascara: parametro.tipo == 'N' ? [maskFormatter] : [],
                    maxLines: 1,
                    onFieldSubmitted: (value) async {
                      await _validateAndSetParametroValue(parametro);
                    },
                  ),
                )
              ]
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                router.pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                await _validateAndSetParametroValue(parametro);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _validateAndSetParametroValue(Parametro parametro) async {
    bool existe = false;
    if (_controllers[parametro.parametro]?.text != '' && parametro.control == 'T') {
      if (parametro.control == 'T' && parametro.tieneLista == 'S') {
        existe = await InformesServices().getExisteParametro(
          context,
          token,
          parametro.informeId,
          parametro,
          _controllers[parametro.parametro]?.text,
        );
        if (existe) {
          parametro.valor = _controllers[parametro.parametro]?.text ?? '';
          parametro.valorAMostrar = _controllers[parametro.parametro]?.text ?? '';
        }
      }
    } else {
      router.pop();
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, String title, String tipo, Parametro parametro) async {
    DateTime selectedDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        if (tipo == 'D' || tipo == 'Dd') {
          parametro.valor = DateFormat('yyyy-MM-dd HH:mm:ss.SSS', 'es').format(DateTime(picked.year, picked.month, picked.day, 0, 0, 0, 0));
          parametro.valorAMostrar = DateFormat('y/M/d', 'es').format(picked);
        } else if (tipo == 'Dh') {
          parametro.valor = DateFormat('yyyy-MM-dd HH:mm:ss.SSS', 'es').format(DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 0));
          parametro.valorAMostrar = DateFormat('y/M/d', 'es').format(picked);
        }
      });
    }
  }

  // MÉTODOS DE CONVERSIÓN DE ÁRBOL (compartidos)
  TreeNode convertInformesToTreeNode(List<Informe> informes) {
    TreeNode root = TreeNode.root();
    for (var informe in informes) {
      TreeNode node = TreeNode(
        key: _sanitizeKey(informe.nombre),
        data: informe,
      );
      node.addAll(_convertInformeHijosToTreeNode(informe.hijos, '${informe.objetoArbol}-${informe.nombre}'));
      root.add(node);
    }
    return root;
  }

  List<TreeNode> _convertInformeHijosToTreeNode(List<InformeHijo> hijos, String parentKey) {
    List<TreeNode> nodes = [];
    for (var hijo in hijos) {
      String key = hijo.objetoArbol == 'informe' 
        ? hijo.informe ?? hijo.nombre ?? ''
        : hijo.nombre ?? '';
      TreeNode node = TreeNode(
        key: _sanitizeKey(key),
        data: hijo,
      );
      node.addAll(_convertHijoHijosToTreeNode(hijo.hijos, '${hijo.objetoArbol}-${hijo.nombre}'));
      nodes.add(node);
    }
    return nodes;
  }

  List<TreeNode> _convertHijoHijosToTreeNode(List<HijoHijo> hijos, String parentKey) {
    List<TreeNode> nodes = [];
    for (var hijo in hijos) {
      TreeNode node = TreeNode(
        key: _sanitizeKey(hijo.informe),
        data: hijo,
      );
      node.addAll(_convertHijoHijosToTreeNode(hijo.hijos, '${hijo.objetoArbol}-${hijo.informe}'));
      nodes.add(node);
    }
    return nodes;
  }

  postInforme(dynamic informe) async {
    await InformesServices().postGenerarInforme(context, informe, parametros, tipo, token);
    rptGenId = context.read<OrdenProvider>().rptGenId;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }
}