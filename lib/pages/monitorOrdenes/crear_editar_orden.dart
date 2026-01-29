import 'package:app_tec_sedel/config/router/router.dart';
import 'package:app_tec_sedel/models/tecnico.dart';
import 'package:app_tec_sedel/models/tipo_ot.dart';
import 'package:app_tec_sedel/models/condicion_ot.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/client_services.dart';
import 'package:app_tec_sedel/services/codigueras_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/tecnico_services.dart';
import 'package:app_tec_sedel/widgets/carteles.dart';
import 'package:app_tec_sedel/widgets/custom_button.dart';
import 'package:app_tec_sedel/widgets/dialogo_cliente.dart';
import 'package:app_tec_sedel/widgets/dialogo_unidad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/delegates/cliente_search_delegate.dart';
import 'package:provider/provider.dart';
import 'detlla_piezas_screen.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_tec_sedel/models/reporte.dart';
import 'package:app_tec_sedel/models/moneda.dart';

class MonitorOrdenes extends StatefulWidget {
  const MonitorOrdenes({super.key});

  @override
  State<MonitorOrdenes> createState() => _MonitorOrdenesState();
}

class _MonitorOrdenesState extends State<MonitorOrdenes> {
  String token = '';
  final ClientServices clientServices = ClientServices();
  final UnidadesServices unidadesServices = UnidadesServices();
  final CodiguerasServices codiguerasServices = CodiguerasServices();
  final OrdenServices ordenServices = OrdenServices();
  final TecnicoServices tecnicoServices = TecnicoServices();
  
  List<Cliente> clientesLocales = [];
  List<Unidad> unidades = [];
  List<Tecnico> tecnicos = [];
  List<TipoOt> tiposOT = [];
  List<CondicionOt> condicionesOT = [];
  List<Moneda> monedas = [];
  DateTime fecha = DateTime.now();
  bool condIva = true;
  Cliente? clienteSeleccionado;
  Unidad? unidadSeleccionada;
  Tecnico? tecnicoSeleccionado;
  TipoOt? tipoOTSeleccionado;
  CondicionOt? condicionOTSeleccionado;
  Moneda? monedaSeleccionada;
  final TextEditingController _numOrdenController = TextEditingController();
  final TextEditingController _comentClienteController = TextEditingController();
  final TextEditingController _comentTrabajoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  late Orden ordenExistente = Orden.empty();
  bool _isEditMode = false;
  bool _isReadOnly = false;
  Orden? _ordenExistente;
  bool esCredito = false;
  final TextEditingController _ordenCompraController = TextEditingController();
  final TextEditingController _siniestroController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();

  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _productoController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _pedidoController = TextEditingController();
  final TextEditingController _envaseController = TextEditingController();
  final TextEditingController _totTambController = TextEditingController();
  final TextEditingController _batchesController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  
  final TextEditingController _numBatchesController = TextEditingController();
  final TextEditingController _iniciadaEnController = TextEditingController();
  final TextEditingController _produccionController = TextEditingController();
  final TextEditingController _bolsasController = TextEditingController();
  final TextEditingController _nvporcController = TextEditingController();
  final TextEditingController _viscController = TextEditingController();
  
  late String flavor = "";
  late String siguienteEstado = '';
  bool ejecutando = false;
  int? statusCode;

  late bool generandoInforme = false;
  late bool informeGeneradoEsS = false;
  late Reporte reporte = Reporte.empty();
  late int rptGenId = 0;
  Map<String, bool> _opcionesImpresion = {
    'DC': false,
    'DP': false,
    'DM': false,
    'DR': false,
    'II': false,
    'IO': false,
  };
  Map<String, Color> colores = {
    'PENDIENTE': Colors.yellow.shade800,
    'EN PROCESO': Colors.green,
    'REVISADA': Colors.blue.shade400,
    'FINALIZADO': Colors.red.shade200
  };

  void _calcularTotalTambores() {
    double pedido = double.tryParse(_pedidoController.text.replaceAll(',', '.')) ?? 0.0;
    double envase = double.tryParse(_envaseController.text.replaceAll(',', '.')) ?? 0.0;

    if (envase > 0) {
      double total = pedido / envase;
      String formattedTotal = total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(2);
      
      if (_totTambController.text != formattedTotal) {
        setState(() {
          _totTambController.text = formattedTotal;
        });
      }
    } else {
      if (_totTambController.text != '0') {
        setState(() {
          _totTambController.text = '0';
        });
      }
    }
  }

  Future<void> _cargarTecnicos() async {
    try {
      final listaTecnicos = await tecnicoServices.getAllTecnicos(context, token);
      if (listaTecnicos != null && listaTecnicos is List<Tecnico>) {
        final Map<int, Tecnico> tecnicoMap = {};
        for (var tecnico in listaTecnicos) {
          tecnicoMap[tecnico.tecnicoId] = tecnico;
        }
        
        setState(() {
          tecnicos = tecnicoMap.values.toList();
        });
      }
    } catch (e) {
      print('Error cargando técnicos: $e');
    }
  }

  Future<void> _cargarTiposOT() async {
    try {
      final listaTiposOT = await ordenServices.getTiposOT(context, token);
      setState(() {
        tiposOT = listaTiposOT;
      });
        } catch (e) {
      print('Error cargando tipos OT: $e');
    }
  }

  Future<void> _cargarCondicionesOT() async {
    try {
      final listaCondicionesOT = await ordenServices.getCondiciones(context, token);
      setState(() {
        condicionesOT = listaCondicionesOT;
      });
        } catch (e) {
      print('Error cargando condiciones OT: $e');
    }
  }

  Future<void> _cargarMonedas() async {
    try {
      final listaMonedas = await ordenServices.getMonedas(context, token);
      setState(() {
        monedas = listaMonedas;
      });
    } catch (e) {
      print('Error cargando monedas: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    token = context.read<AuthProvider>().token;
    flavor = context.read<AuthProvider>().flavor;
    
    if (flavor == 'resysol') {
      _fechaEmisionController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _pedidoController.addListener(_calcularTotalTambores);
      _envaseController.addListener(_calcularTotalTambores);
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarOrdenExistente();
      _cargarTecnicos();
      if (flavor == 'parabrisasejido') {
        _cargarTiposOT();
        _cargarCondicionesOT();
        _cargarMonedas();
      }
    });
  }

  Future<void> _cargarOrdenExistente() async {
    final ordenProvider = context.read<OrdenProvider>();
    ordenExistente = ordenProvider.orden;

    if (ordenExistente.ordenTrabajoId != null && ordenExistente.ordenTrabajoId != 0) {
      setState(() {
        _isEditMode = true;
        _ordenExistente = ordenExistente;
        _isReadOnly = ordenExistente.estado == 'EN PROCESO' || ordenExistente.estado == 'FINALIZADO' || ordenExistente.estado == 'DESCARTADO';
      });

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await _cargarTecnicos();
        
        if (flavor == 'parabrisasejido') {
          await _cargarTiposOT();
          await _cargarCondicionesOT();
          await _cargarMonedas();
          
          if (ordenExistente.tipoOTId != null) {
            final tipoOTEncontrado = tiposOT.firstWhere(
              (t) => t.tipoOtId == ordenExistente.tipoOTId,
              orElse: () => TipoOt.empty(),
            );
            if (tipoOTEncontrado.tipoOtId != null) {
              setState(() {
                tipoOTSeleccionado = tipoOTEncontrado;
              });
            }
          }
          
          if (ordenExistente.condOTId != null) {
            final condOTEncontrada = condicionesOT.firstWhere(
              (c) => c.condOtId == ordenExistente.condOTId,
              orElse: () => CondicionOt.empty(),
            );
            if (condOTEncontrada.condOtId != null) {
              setState(() {
                condicionOTSeleccionado = condOTEncontrada;
              });
            }
          }

          if (ordenExistente.monedaId != null) {
            final monedaEncontrada = monedas.firstWhere(
              (m) => m.monedaId == ordenExistente.monedaId,
              orElse: () => Moneda.empty(),
            );
            if (monedaEncontrada.monedaId != null) {
              setState(() {
                monedaSeleccionada = monedaEncontrada;
              });
            }
          }

          setState(() {
            esCredito = ordenExistente.credito ?? false;
            _ordenCompraController.text = ordenExistente.ordenCompra ?? '';
            _siniestroController.text = ordenExistente.siniestro ?? '';
            _kmController.text = ordenExistente.km?.toString() ?? '';
          });
        }
        
        if (ordenExistente.tecnico != null && ordenExistente.tecnico!.tecnicoId > 0) {
          final tecnicoEncontrado = tecnicos.firstWhere(
            (t) => t.tecnicoId == ordenExistente.tecnico!.tecnicoId,
            orElse: () => Tecnico.empty(),
          );
          
          if (tecnicoEncontrado.tecnicoId > 0) {
            setState(() {
              tecnicoSeleccionado = tecnicoEncontrado;
            });
          }
        }
        
        if (ordenExistente.cliente?.clienteId != null) {
          await _cargarClienteDesdeAPI(ordenExistente.cliente!.clienteId);
          
          if ((flavor == 'automotoraargentina' || flavor == 'parabrisasejido') && ordenExistente.unidad?.unidadId != null) {
            await _cargarUnidadesYSeleccionar(ordenExistente.cliente!.clienteId, ordenExistente.unidad!.unidadId);
          }
        }
        
        _cargarDatosComunesDesdeOrden();
        
        if (flavor == 'resysol') {
          _cargarDatosResysolDesdeOrden();
        }

        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar la orden existente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cargarClienteDesdeAPI(int clienteId) async {
    try {
      final clientes = await clientServices.getClientes(
        context, 
        ordenExistente.cliente?.nombre ?? '',
        '',
        '',
        '',
        token
      );

      if (clientes != null && clientes is List<Cliente>) {
        final clienteEncontrado = clientes.firstWhere(
          (cliente) => cliente.clienteId == clienteId,
          orElse: () => Cliente.empty(),
        );

        if (clienteEncontrado.clienteId != 0) {
          setState(() {
            clienteSeleccionado = clienteEncontrado;
          });
        }
      }
    } catch (e) {
      print('Error cargando cliente desde API: $e');
    }
  }

  Future<void> _cargarUnidadesYSeleccionar(int clienteId, int unidadId) async {
    try {
      List<Unidad> unidadesDelCliente = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteId, 
        token
      );

      Unidad? unidadDeOrden;
      try {
        unidadDeOrden = unidadesDelCliente.firstWhere(
          (unidad) => unidad.unidadId == unidadId
        );
      } catch (e) {
        if (ordenExistente.matricula != null) {
          try {
            unidadDeOrden = unidadesDelCliente.firstWhere(
              (unidad) => unidad.matricula == ordenExistente.matricula
            );
          } catch (e) {
            print('No se encontró la unidad por matrícula: ${ordenExistente.matricula}');
          }
        }
      }

      setState(() {
        unidades = unidadesDelCliente;
        unidadSeleccionada = unidadDeOrden;
      });
    } catch (e) {
      print('Error cargando unidades: $e');
    }
  }

  void _cargarDatosComunesDesdeOrden() {
    if (_ordenExistente == null) return;

    setState(() {
      _numOrdenController.text = _ordenExistente!.numeroOrdenTrabajo ?? '';
      _comentClienteController.text = _ordenExistente!.comentarioCliente ?? '';
      _comentTrabajoController.text = _ordenExistente!.comentarioTrabajo ?? '';
      _descripcionController.text = _ordenExistente!.descripcion ?? '';
      
      if (_ordenExistente!.fechaOrdenTrabajo != null) {
        fecha = _ordenExistente!.fechaOrdenTrabajo!;
      }

      if (flavor == 'parabrisasejido') {
        _ordenCompraController.text = _ordenExistente!.ordenCompra ?? '';
        _siniestroController.text = _ordenExistente!.siniestro ?? '';
        _kmController.text = _ordenExistente!.km?.toString() ?? '';
        esCredito = _ordenExistente!.credito ?? false;
      }
    });
  }

  void _cargarDatosResysolDesdeOrden() {
    if (_ordenExistente == null) return;

    setState(() {
      _numeroController.text = _ordenExistente!.numeroOrdenTrabajo ?? '';
      _productoController.text = _ordenExistente!.producto ?? _ordenExistente!.descripcion ?? '';
      _pedidoController.text = _ordenExistente!.pedido.toString();
      _envaseController.text = _ordenExistente!.envase.toString();
      _batchesController.text = _ordenExistente!.batches?.toString() ?? '';
      _observacionesController.text = _ordenExistente!.comentarioTrabajo ?? _ordenExistente!.comentarioCliente ?? '';
      
      _numBatchesController.text = _ordenExistente!.numBatches?.toString() ?? '';
      if (_ordenExistente!.iniciadaEn != null) {
        _iniciadaEnController.text = DateFormat('dd/MM/yyyy').format(_ordenExistente!.iniciadaEn!);
      }
      _produccionController.text = _ordenExistente!.produccion?.toString() ?? '';
      _bolsasController.text = _ordenExistente!.bolsas ?? '';
      _nvporcController.text = _ordenExistente!.nvporc ?? '';
      _viscController.text = _ordenExistente!.visc ?? '';
      
      if (_ordenExistente!.fechaOrdenTrabajo != null) {
        _fechaEmisionController.text = DateFormat('dd/MM/yyyy').format(_ordenExistente!.fechaOrdenTrabajo!);
      }
    });
    
    _calcularTotalTambores();
  }

  void _mostrarDialogoConfirmacion(String accion) async {
    late int accionId = accion == "descartar" ? 4 : 0;
    siguienteEstado = await ordenServices.siguienteEstadoOrden(context, ordenExistente, accionId, token);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateBd) {
            return AlertDialog(
              surfaceTintColor: Colors.white,
              title: const Text('Confirmación'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('¿Estás seguro que deseas pasar la OT al estado $siguienteEstado?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    router.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      cambiarEstado(accionId);
                    });
                    router.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  cambiarEstado(int accionId) async {
    if (!ejecutando) {
      ejecutando = true;
      String token = context.read<AuthProvider>().token;
      ordenExistente.otRevisionId = await ordenServices.patchOrdenCambioEstado(context, ordenExistente, accionId, 0, token);
      statusCode = await ordenServices.getStatusCode();
      await ordenServices.resetStatusCode();
      if (statusCode == 1) {
        if (accionId == 4) {          
          ordenExistente.estado == siguienteEstado;
          await Carteles.showDialogs(context, 'Estado cambiado correctamente', false, false, false);
        }
        
      }
      ejecutando = false;
      statusCode = null;
      setState(() {});
    }
  }

  void _abrirBusquedaCliente(BuildContext context) async {
    if (_isReadOnly) return;
    
    final Cliente? resultado = await showSearch<Cliente>(
      context: context,
      delegate: ClienteSearchDelegate(
        token: token,
        clientService: clientServices,
      ),
    );

    if (resultado != null && resultado.clienteId != 0) {
      if (flavor == 'automotoraargentina' || flavor == 'parabrisasejido') {
        List<Unidad> unidadesDelCliente = await unidadesServices.getUnidadesDeCliente(
          context, 
          resultado.clienteId, 
          token
        );
        setState(() {
          clienteSeleccionado = resultado;
          unidades = unidadesDelCliente;
          unidadSeleccionada = null;
        });
      } else {
        setState(() {
          clienteSeleccionado = resultado;
        });
      }
    }
  }

  int getTipoOrden() {
    switch (flavor.toLowerCase()) {
      case 'automotoraargentina':
        return 5;
      case 'parabrisasejido':
        return 6;
      case 'resysol':
        return 7;
      default:
      return 7;
    }
  }

  Orden _crearOrdenEnMemoria() {
    final authProvider = context.read<AuthProvider>();
    Unidad unidadResysol;
    
    if (flavor == 'parabrisasejido' && tipoOTSeleccionado?.reqUnidad == "N") {
      unidadResysol = Unidad.empty();
    } else {
      unidadResysol = unidadSeleccionada ?? Unidad.empty();
    }
    
    int? totalTamboresInt;
    
    double? calculatedTotal = double.tryParse(_totTambController.text.replaceAll(',', '.'));
    if (calculatedTotal != null) {
      if (calculatedTotal == calculatedTotal.toInt()) {
        totalTamboresInt = calculatedTotal.toInt();
      } else {
        totalTamboresInt = 0;
      }
    }

    return Orden(
      ordenTrabajoId: _isEditMode ? _ordenExistente!.ordenTrabajoId : 0,
      numeroOrdenTrabajo: flavor == 'resysol' ? _numeroController.text : _numOrdenController.text,
      descripcion: flavor == 'resysol' ? _productoController.text : _descripcionController.text,
      fechaOrdenTrabajo: fecha,
      fechaVencimiento: _isEditMode ? _ordenExistente!.fechaVencimiento : null,
      fechaEntrega: _isEditMode ? _ordenExistente!.fechaEntrega : null,
      fechaDesde: _isEditMode ? _ordenExistente!.fechaDesde : fecha,
      fechaHasta: _isEditMode ? _ordenExistente!.fechaHasta : fecha,
      ruc: clienteSeleccionado?.ruc ?? '',
      monedaId: flavor == 'parabrisasejido' ? monedaSeleccionada?.monedaId : 1,
      codMoneda: flavor == 'parabrisasejido' ? monedaSeleccionada?.codMoneda : 'UYU',
      descMoneda: flavor == 'parabrisasejido' ? monedaSeleccionada?.descripcion : 'Peso Uruguayo',
      signo: flavor == 'parabrisasejido' ? monedaSeleccionada?.signo : '\$',
      totalOrdenTrabajo: _isEditMode ? _ordenExistente!.totalOrdenTrabajo : 0.0,
      comentarioCliente: flavor == 'resysol' ? _observacionesController.text : _comentClienteController.text,
      comentarios: _isEditMode ? _ordenExistente!.comentarios : '',
      comentarioTrabajo: flavor == 'resysol' ? _observacionesController.text : _comentTrabajoController.text,
      estado: _isEditMode ? _ordenExistente!.estado : 'PENDIENTE',
      presupuestoIdPlantilla: _isEditMode ? _ordenExistente!.presupuestoIdPlantilla : null,
      numeroPresupuesto: _isEditMode ? _ordenExistente!.numeroPresupuesto : null,
      descripcionPresupuesto: _isEditMode ? _ordenExistente!.descripcionPresupuesto : null,
      totalPresupuesto: _isEditMode ? _ordenExistente!.totalPresupuesto : null,
      plantilla: _isEditMode ? _ordenExistente!.plantilla : false,
      unidadId: unidadResysol.unidadId,
      matricula: unidadResysol.matricula,
      km: flavor == 'parabrisasejido' ? int.tryParse(_kmController.text) : 
          (_isEditMode ? _ordenExistente!.km ?? unidadSeleccionada?.km : 0),
      regHs: _isEditMode ? _ordenExistente!.regHs ?? false : false,
      instrucciones: _isEditMode ? _ordenExistente!.instrucciones : '',
      tipoOrden: _isEditMode ? _ordenExistente!.tipoOrden : TipoOrden.empty(),
      cliente: clienteSeleccionado ?? Cliente.empty(),
      tecnico: tecnicoSeleccionado ?? Tecnico.empty(),
      unidad: unidadResysol,
      servicio: _isEditMode ? _ordenExistente!.servicio : [],
      otRevisionId: _isEditMode ? _ordenExistente!.otRevisionId : 0,
      planoId: _isEditMode ? _ordenExistente!.planoId : 0,
      alerta: _isEditMode ? _ordenExistente!.alerta : false,
      tecnicoId: flavor == 'parabrisasejido' ? tecnicoSeleccionado?.tecnicoId : 
          (tecnicoSeleccionado?.tecnicoId ?? authProvider.tecnicoId),
      clienteId: clienteSeleccionado?.clienteId ?? 0,
      tipoOrdenId: getTipoOrden(),
      producto: _productoController.text,
      pedido: int.tryParse(_pedidoController.text),
      envase: int.tryParse(_envaseController.text),
      totalTambores: totalTamboresInt,
      batches: int.tryParse(_batchesController.text),
      totalkgs: 0.0,
      mermaKgs: 0.0,
      mermaPorcentual: 0.0,
      tipoOTId: tipoOTSeleccionado?.tipoOtId,
      condOTId: condicionOTSeleccionado?.condOtId,
      credito: flavor == 'parabrisasejido' ? esCredito : null,
      ordenCompra: flavor == 'parabrisasejido' ? _ordenCompraController.text : null,
      siniestro: flavor == 'parabrisasejido' ? _siniestroController.text : null,
      numBatches: int.tryParse(_numBatchesController.text),
      iniciadaEn: _iniciadaEnController.text.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').parse(_iniciadaEnController.text) 
          : null,
      produccion: int.tryParse(_produccionController.text),
      bolsas: _bolsasController.text,
      nvporc: _nvporcController.text,
      visc: _viscController.text,
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    if (_isReadOnly) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Map<String, dynamic> _crearDatosProduccion() {
    return {
      'fechaEmision': _fechaEmisionController.text,
      'numero': _numeroController.text,
      'producto': _productoController.text,
      'referencia': _refController.text,
      'pedido': _pedidoController.text,
      'envase': _envaseController.text,
      'totalTambores': _totTambController.text,
      'batches': _batchesController.text,
      'observaciones': _observacionesController.text,
      'fecha': DateTime.now(),
      'cliente': clienteSeleccionado?.toMap(),
      'numBatches': _numBatchesController.text,
      'iniciadaEn': _iniciadaEnController.text,
      'produccion': _produccionController.text,
      'bolsas': _bolsasController.text,
      'nvporc': _nvporcController.text,
      'visc': _viscController.text,
    };
  }

  void _mostrarDialogoOpcionesImpresion() {
    Map<String, bool> opcionesTemp = {
      'DC': false,
      'DP': false,
      'DM': false,
      'DR': false,
      'II': false,
      'IO': false,
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Opciones de Impresión', textAlign: TextAlign.center),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Detallar ítems de Chapa'),
                      value: opcionesTemp['DC'] ?? false,
                      onChanged: opcionesTemp['IO'] == false ? (bool? value) {
                        setStateDialog(() {
                          opcionesTemp['DC'] = value ?? false;
                        });
                      } : null,
                    ),
                    CheckboxListTile(
                      title: const Text('Detallar ítems de Pintura'),
                      value: opcionesTemp['DP'] ?? false,
                      onChanged: opcionesTemp['IO'] == false ? (bool? value) {
                        setStateDialog(() {
                          opcionesTemp['DP'] = value ?? false;
                        });
                      } : null,
                    ),
                    CheckboxListTile(
                      title: const Text('Detallar ítems de Mecánica'),
                      value: opcionesTemp['DM'] ?? false,
                      onChanged: opcionesTemp['IO'] == false ? (bool? value) {
                        setStateDialog(() {
                          opcionesTemp['DM'] = value ?? false;
                        });
                      } : null,
                    ),
                    CheckboxListTile(
                      title: const Text('Detallar ítems de Repuestos'),
                      value: opcionesTemp['DR'] ?? false,
                      onChanged: opcionesTemp['IO'] == false ? (bool? value) {
                        setStateDialog(() {
                          opcionesTemp['DR'] = value ?? false;
                        });
                      } : null,
                    ),
                    CheckboxListTile(
                      title: const Text('Imprimir la observación'),
                      value: opcionesTemp['II'] ?? false,
                      onChanged: opcionesTemp['IO'] == false ? (bool? value) {
                        setStateDialog(() {
                          opcionesTemp['II'] = value ?? false;
                        });
                      } : null,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Impresión para USO INTERNO'),
                      value: opcionesTemp['IO'] ?? false,                                                                                        
                      onChanged: (opcionesTemp["DC"] == true || opcionesTemp["DP"] == true || opcionesTemp["DM"] == true || opcionesTemp["DR"] == true || opcionesTemp["II"] == true) ? null : (bool? value) {
                        setStateDialog(() {
                          opcionesTemp['IO'] = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cerrar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _opcionesImpresion = opcionesTemp;
                    });
                    Navigator.of(context).pop();
                    await _imprimirConOpciones();
                    await generarInformeCompleto();
                  },
                  child: const Text('Imprimir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _imprimirConOpciones() async {
    if (_ordenExistente == null || _ordenExistente!.ordenTrabajoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una orden válida para imprimir')),
      );
      return;
    }

    List<String> opcionesSeleccionadas = [];
    
    _opcionesImpresion.forEach((key, value) {
      if (value) {
        opcionesSeleccionadas.add(key);
      }
    });
    
    String opcionesString = opcionesSeleccionadas.join(', ');
    
    try {
      await ordenServices.postimprimirOTAdm(
        context, 
        _ordenExistente!, 
        opcionesString,
        token
      );
      rptGenId = context.read<OrdenProvider>().rptGenId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> generarInformeCompleto() async {
    if (_ordenExistente == null) return;

    int contador = 0;
    generandoInforme = true;
    informeGeneradoEsS = false;
    
    setState(() {});
    while (contador < 15 && informeGeneradoEsS == false && generandoInforme){
      if (rptGenId == 0) {
        informeGeneradoEsS = false;
        generandoInforme = false;
        break;
      } 
      reporte = await ordenServices.getReporte(context, rptGenId, token);

      if(reporte.generado == 'S'){
        await Future.delayed(const Duration(seconds: 1));
        informeGeneradoEsS = true;
        if(kIsWeb){
          abrirUrlWeb(reporte.archivoUrl);
        } else{
          await abrirUrl(reporte.archivoUrl, token);
        }
        generandoInforme = false;
        informeGeneradoEsS = false;
        context.read<OrdenProvider>().setRptId(0);
        setState(() {});
      }else{
        await Future.delayed(const Duration(seconds: 1));
      }
      contador++;
    }
    if(informeGeneradoEsS != true && generandoInforme){
      await popUpInformeDemoro();
    }
  }

  Future<void> popUpInformeDemoro() async{
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Su PDF esta tardando demasiado en generarse, quiere seguir esperando?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                generandoInforme = false;
                await ordenServices.patchInforme(context, reporte, 'D', token);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('No'),
            ),
            TextButton(
              child: const Text('Si'),
              onPressed: () async {
                Navigator.of(context).pop();
                await generarInformeInfinite();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> generarInformeInfinite() async {
    generandoInforme = true;
    while (informeGeneradoEsS == false && generandoInforme){
      reporte = await ordenServices.getReporte(context, rptGenId, token);
      if(reporte.generado == 'S'){
        informeGeneradoEsS = true;
        if(kIsWeb) {
          abrirUrlWeb(reporte.archivoUrl);
        } else {
          await abrirUrl(reporte.archivoUrl, token);
        }
        generandoInforme = false;
        setState(() {});
      }else{
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    setState(() {});
  }

  Future<void> abrirUrl(String url, String token) async {
    Dio dio = Dio();
    String link = "$url?authorization=$token";
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
        Uri uri = Uri.parse(link);
        await launchUrl(uri);
      } else {
        print('Error al cargar la URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud: $e');
    }
  }

  Future<void> abrirUrlWeb(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('No se puede abrir la URL: $url');
    }
  }

  Future<void> _actualizarListaOrdenes(BuildContext context) async {
    try {
      final ordenProvider = Provider.of<OrdenProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      Map<String, dynamic> queryParams = {};
      queryParams['sort'] = 'fechaDesde DESC';
      
      final ordenesActualizadas = await ordenServices.getOrden(
        context,
        authProvider.tecnicoId.toString(),
        token,
        queryParams: queryParams,
      );
      
      ordenProvider.setOrdenes(ordenesActualizadas);
    } catch (e) {
      print('Error actualizando lista de órdenes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final flavor = context.read<AuthProvider>().flavor;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text(
          flavor == 'resysol' 
            ? 'Planilla de Producción Química'
            : (_isEditMode ? 'Editar Orden ${ordenExistente.numeroOrdenTrabajo}' : 'Registro de Orden'),
          style: TextStyle(color: colors.onPrimary),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
        actions: [
          if (flavor == 'resysol' && _ordenExistente?.ordenTrabajoId != null && _ordenExistente!.ordenTrabajoId! > 0)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _mostrarDialogoOpcionesImpresion,
            ),
        ],
      ),
      body: flavor == 'resysol' 
          ? _buildResysolUI(context)
          : _buildAutomotoraUI(context),
    );
  }

  Widget _buildResysolUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClienteCardResysol(),
          const SizedBox(height: 20),
          _buildChemicalHeaderCard(), 
          const SizedBox(height: 20),
          _buildChemicalProductionCard(), 
          const SizedBox(height: 24),
          _buildChemicalActionButtons(),
        ],
      ),
    );
  }

  Widget _buildClienteCardResysol() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onDoubleTap: _isReadOnly ? null : (clienteSeleccionado != null ? _editarClienteSeleccionado : null),
              child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Buscar cliente...',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.search),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
                controller: TextEditingController(
                  text: clienteSeleccionado != null ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' : '',
                ),
                onTap: _isReadOnly ? null : () {
                  _abrirBusquedaCliente(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomotoraUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colores[ordenExistente.estado],
              borderRadius: BorderRadius.circular(5)
            ),
            height: 30,
            child: const Center(
              child: Text(
                'Detalles',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(fecha),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    border: const OutlineInputBorder(),
                    filled: _isReadOnly,
                    fillColor: _isReadOnly ? Colors.grey[200] : null,
                  ),
                  onTap: _isReadOnly ? null : () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: fecha,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != fecha) {
                      setState(() {
                        fecha = picked;
                      });
                    }
                  },
                ),
              ),
              if (ordenExistente.numeroOrdenTrabajo != null && ordenExistente.numeroOrdenTrabajo!.isNotEmpty && ordenExistente.numeroOrdenTrabajo != '') ... [
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _numOrdenController,
                    decoration: InputDecoration(
                      labelText: 'N° Orden',
                      border: const OutlineInputBorder(),
                      filled: _isReadOnly,
                      fillColor: _isReadOnly ? Colors.grey[200] : null,
                    ),
                    readOnly: true,
                  )
                ),
              ]
            ],
          ),
          
          const SizedBox(height: 16),
          if (tecnicos.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: tecnicoSeleccionado?.tecnicoId,
              decoration: InputDecoration(
                labelText: 'Técnico asignado',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Sin técnico asignado'),
                ),
                ...tecnicos.map((Tecnico tecnico) {
                  return DropdownMenuItem<int>(
                    value: tecnico.tecnicoId,
                    child: Text(tecnico.nombre.trim()),
                  );
                }).toList(),
              ],
              onChanged: _isReadOnly ? null : (int? nuevoTecnicoId) {
                if (nuevoTecnicoId != null) {
                  Tecnico? nuevoTecnico = tecnicos.firstWhere(
                    (t) => t.tecnicoId == nuevoTecnicoId,
                    orElse: () => Tecnico.empty(),
                  );
                  setState(() {
                    tecnicoSeleccionado = nuevoTecnico.tecnicoId != 0 ? nuevoTecnico : null;
                  });
                } else {
                  setState(() {
                    tecnicoSeleccionado = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          
          if (flavor == 'parabrisasejido') ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TipoOt>(
                    value: tipoOTSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Tipo OT',
                      border: const OutlineInputBorder(),
                      filled: _isReadOnly,
                      fillColor: _isReadOnly ? Colors.grey[200] : null,
                    ),
                    items: tiposOT.map((TipoOt tipoOT) {
                      return DropdownMenuItem<TipoOt>(
                        value: tipoOT,
                        child: Text(tipoOT.descripcion ?? ''),
                      );
                    }).toList(),
                    onChanged: _isReadOnly ? null : (TipoOt? nuevoTipoOT) {
                      setState(() {
                        tipoOTSeleccionado = nuevoTipoOT;
                        if (nuevoTipoOT?.reqUnidad == "N") {
                          unidadSeleccionada = null;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<CondicionOt>(
                    value: condicionOTSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Condición OT',
                      border: const OutlineInputBorder(),
                      filled: _isReadOnly,
                      fillColor: _isReadOnly ? Colors.grey[200] : null,
                    ),
                    items: condicionesOT.map((CondicionOt condicionOT) {
                      return DropdownMenuItem<CondicionOt>(
                        value: condicionOT,
                        child: Text(condicionOT.descripcion ?? ''),
                      );
                    }).toList(),
                    onChanged: _isReadOnly ? null : (CondicionOt? nuevaCondicionOT) {
                      setState(() {
                        condicionOTSeleccionado = nuevaCondicionOT;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          if (flavor == 'parabrisasejido') ...[
            if (monedas.isNotEmpty) ...[
              DropdownButtonFormField<Moneda>(
                value: monedaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Moneda',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
                items: monedas.map((Moneda moneda) {
                  return DropdownMenuItem<Moneda>(
                    value: moneda,
                    child: Text('${moneda.descripcion} (${moneda.signo})'),
                  );
                }).toList(),
                onChanged: _isReadOnly ? null : (Moneda? nuevaMoneda) {
                  setState(() {
                    monedaSeleccionada = nuevaMoneda;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            
            CheckboxListTile(
              title: const Text('¿Es Crédito?'),
              value: esCredito,
              onChanged: _isReadOnly ? null : (bool? value) {
                setState(() {
                  esCredito = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _ordenCompraController,
              decoration: InputDecoration(
                labelText: 'Número de Orden de Compra',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
              readOnly: _isReadOnly,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _siniestroController,
              decoration: InputDecoration(
                labelText: 'Número de Siniestro',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
              readOnly: _isReadOnly,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _kmController,
              decoration: InputDecoration(
                labelText: 'Kilometraje (KM)',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
              keyboardType: TextInputType.number,
              readOnly: _isReadOnly,
            ),
            const SizedBox(height: 16),
          ],
          
          TextFormField(
            controller: _descripcionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              border: const OutlineInputBorder(),
              filled: _isReadOnly,
              fillColor: _isReadOnly ? Colors.grey[200] : null,
            ),
            readOnly: _isReadOnly,
          ),
          const SizedBox(height: 16),
          if (_isEditMode)
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: _ordenExistente!.estado ?? ''),
              decoration: InputDecoration(
                labelText: 'Estado',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
            ),
          if (ordenExistente.estado == 'EN PROCESO' || ordenExistente.estado == 'FINALIZADO') ... [
            const SizedBox(height: 16,),
            CustomButton(
              text: 'Ver revisión', onPressed: () {
                router.push('/revisionOrden');
              }
            ),
          ],
          const SizedBox(height: 24),
          
          const Text(
            'Datos del Cliente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          GestureDetector(
            onDoubleTap: _isReadOnly ? null : (clienteSeleccionado != null ? _editarClienteSeleccionado : null),
            child: TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Buscar cliente...',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.search),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
              controller: TextEditingController(
                text: clienteSeleccionado != null ? '${clienteSeleccionado!.nombre} ${clienteSeleccionado!.nombreFantasia}' : '',
              ),
              onTap: _isReadOnly ? null : () {
                _abrirBusquedaCliente(context);
              },
            ),
          ),
          
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isReadOnly ? null : () {
                _mostrarDialogoNuevoCliente(context);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Agregar Nuevo Cliente'),
            ),
          ),
          
          if (clienteSeleccionado != null) ...[
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: clienteSeleccionado!.direccion),
              decoration: InputDecoration(
                labelText: 'Dirección',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: clienteSeleccionado!.telefono1),
              decoration: InputDecoration(
                labelText: 'Teléfono',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: clienteSeleccionado!.email),
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: 'RUC: ${clienteSeleccionado!.ruc}'),
              decoration: InputDecoration(
                labelText: 'Documento',
                border: const OutlineInputBorder(),
                filled: _isReadOnly,
                fillColor: _isReadOnly ? Colors.grey[200] : null,
              ),
            ),
          ],
          
          if (flavor != 'parabrisasejido' || (tipoOTSeleccionado?.reqUnidad != "N")) ...[
            const SizedBox(height: 24),
            const Text(
              'Datos del Vehículo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: _isReadOnly ? null : (unidadSeleccionada != null ? _editarUnidadSeleccionada : null),
                    child: DropdownButtonFormField<Unidad>(
                      value: unidadSeleccionada,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Seleccione un vehículo',
                        filled: _isReadOnly,
                        fillColor: _isReadOnly ? Colors.grey[200] : null,
                      ),
                      items: unidades.map((Unidad unidad) {
                        return DropdownMenuItem<Unidad>(
                          value: unidad,
                          child: Text(unidad.displayInfo),
                        );
                      }).toList(),
                      onChanged: _isReadOnly ? null : (Unidad? nuevaUnidad) {
                        setState(() {
                          unidadSeleccionada = nuevaUnidad;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _isReadOnly ? null : () {
                    _mostrarDialogoNuevaUnidad(context);
                  },
                ),
              ],
            ),
            
            if (unidadSeleccionada != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: unidadSeleccionada!.marca),
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        border: const OutlineInputBorder(),
                        filled: _isReadOnly,
                        fillColor: _isReadOnly ? Colors.grey[200] : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(text: unidadSeleccionada!.modelo),
                      decoration: InputDecoration(
                        labelText: 'Modelo',
                        border: const OutlineInputBorder(),
                        filled: _isReadOnly,
                        fillColor: _isReadOnly ? Colors.grey[200] : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: unidadSeleccionada!.matricula),
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: unidadSeleccionada!.motor),
                decoration: InputDecoration(
                  labelText: 'Número de Motor',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: unidadSeleccionada!.chasis),
                decoration: InputDecoration(
                  labelText: 'Número de Chasis',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: unidadSeleccionada!.anio.toString()),
                decoration: InputDecoration(
                  labelText: 'Año',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _comentClienteController,
                decoration: InputDecoration(
                  labelText: 'Comentario Cliente',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
                minLines: 1,
                maxLines: 5,
                readOnly: _isReadOnly,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _comentTrabajoController,
                decoration: InputDecoration(
                  labelText: 'Comentario Trabajo',
                  border: const OutlineInputBorder(),
                  filled: _isReadOnly,
                  fillColor: _isReadOnly ? Colors.grey[200] : null,
                ),
                minLines: 1,
                maxLines: 5,
                readOnly: _isReadOnly,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isEditMode) ... [
                  ElevatedButton(
                    onPressed: _isReadOnly ? null : () async {
                      _mostrarDialogoConfirmacion('descartar');
                    },
                    child: const Text('Descartar orden'),
                  ),
                  const SizedBox(width: 16),
                ],
                // CAMBIO IMPORTANTE AQUÍ: Botón de crear/actualizar orden
                ElevatedButton(
                  onPressed: _isReadOnly ? null : () async {
                    if (flavor == 'parabrisasejido') {
                      if (tipoOTSeleccionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debe seleccionar un Tipo OT')),
                        );
                        return;
                      }
                      if (condicionOTSeleccionado == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debe seleccionar una Condición OT')),
                        );
                        return;
                      }
                      if (tipoOTSeleccionado!.reqUnidad != "N" && (clienteSeleccionado == null || unidadSeleccionada == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                        );
                        return;
                      }
                      if (clienteSeleccionado == null || unidadSeleccionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                        );
                        return;
                      }
                    } else {
                      if (clienteSeleccionado == null || unidadSeleccionada == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debe seleccionar un cliente y un vehículo')),
                        );
                        return;
                      }
                    }
                    
                    final ordenCreada = _crearOrdenEnMemoria();
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      final ordenServices = OrdenServices();
                      // CAMBIO AQUÍ: Usamos la tupla (ordenGuardada, success)
                      final (ordenGuardada, success) = _isEditMode 
                          ? await ordenServices.actualizarOrden(context, token, ordenCreada)
                          : await ordenServices.postOrden(context, token, ordenCreada);
                      
                      // SIEMPRE cerrar el diálogo primero
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      
                      // Verificar si fue exitoso
                      if (success && ordenGuardada != null) {
                        setState(() {
                          _isEditMode = true;
                          ordenExistente = ordenGuardada;
                          _ordenExistente = ordenGuardada;
                        });

                        context.read<OrdenProvider>().setOrden(ordenGuardada);
                        
                        await _actualizarListaOrdenes(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isEditMode ? 'Orden actualizada correctamente' : 'Orden creada correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        // Si success es false, mostrar mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al guardar la orden'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Este catch solo se ejecutará si hay una excepción no manejada en el bloque try
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error inesperado: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(_isEditMode ? 'Actualizar Orden' : 'Crear orden'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'DATOS DE PRODUCCIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 8,),
                TextButton(
                  onPressed: _isReadOnly ? null : () async {
                    await _mostrarDialogoCopiarOrden();
                  },
                  child: const Text('Generar copia')
                ),
              ],
            ),
            
            if (tecnicos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLabeledDropdownTecnico(
                label: 'Técnico responsable',
                tecnicos: tecnicos,
                tecnicoSeleccionado: tecnicoSeleccionado,
                onChanged: (Tecnico? nuevoTecnico) {
                  setState(() {
                    tecnicoSeleccionado = nuevoTecnico;
                  });
                },
                width: 300,
                isReadOnly: _isReadOnly,
              ),
              const SizedBox(height: 20),
            ],
            
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Fecha Emisión',
                  controller: _fechaEmisionController,
                  width: 200,
                  readOnly: _isReadOnly,
                  onTap: _isReadOnly ? null : () => _selectDate(context, _fechaEmisionController),
                  icon: Icons.calendar_today,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Número',
                  controller: _numeroController,
                  width: 150,
                  isReadOnly: _isReadOnly,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Producto',
                  controller: _productoController,
                  width: 280,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Referencia',
                  controller: _refController,
                  width: 120,
                  isReadOnly: _isReadOnly,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Pedido (kg)',
                  controller: _pedidoController,
                  width: 180,
                  keyboardType: TextInputType.number,
                  suffixText: 'kg',
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Envase (kg)',
                  controller: _envaseController,
                  width: 180,
                  keyboardType: TextInputType.number,
                  suffixText: 'kg',
                  isReadOnly: _isReadOnly,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(), 
            const SizedBox(height: 10),
            const Text(
              'Detalle de Producción',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'Fecha Producción',
                  controller: _iniciadaEnController,
                  width: 200,
                  readOnly: _isReadOnly,
                  onTap: _isReadOnly ? null : () => _selectDate(context, _iniciadaEnController),
                  icon: Icons.calendar_today,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Producción (Kg)',
                  controller: _produccionController,
                  width: 150,
                  keyboardType: TextInputType.number,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Bolsas',
                  controller: _bolsasController,
                  width: 150,
                  keyboardType: TextInputType.number,
                  isReadOnly: _isReadOnly,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'N.V %',
                  controller: _nvporcController,
                  width: 120,
                  keyboardType: TextInputType.number,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Visc. (cps) 25°',
                  controller: _viscController,
                  width: 120,
                  keyboardType: TextInputType.number,
                  isReadOnly: _isReadOnly,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledDropdownTecnico({
    required String label,
    required List<Tecnico> tecnicos,
    required Tecnico? tecnicoSeleccionado,
    required ValueChanged<Tecnico?> onChanged,
    required double width,
    required bool isReadOnly,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: isReadOnly ? Colors.grey[200] : Colors.white,
            ),
            child: DropdownButton<int>(
              value: tecnicoSeleccionado?.tecnicoId,
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text(
                    'Sin técnico asignado',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...tecnicos.map((Tecnico tecnico) {
                  return DropdownMenuItem<int>(
                    value: tecnico.tecnicoId,
                    child: Text(
                      tecnico.nombre.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isReadOnly ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ],
              onChanged: isReadOnly ? null : (int? nuevoTecnicoId) {
                if (nuevoTecnicoId != null) {
                  final nuevoTecnico = tecnicos.firstWhere(
                    (t) => t.tecnicoId == nuevoTecnicoId,
                    orElse: () => Tecnico.empty(),
                  );
                  onChanged(nuevoTecnico.tecnicoId != 0 ? nuevoTecnico : null);
                } else {
                  onChanged(null);
                }
              },
              hint: Text(
                'Seleccione un técnico',
                style: TextStyle(
                  color: isReadOnly ? Colors.grey[600] : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoCopiarOrden() async {
    if (_isReadOnly) return;
    
    if (_ordenExistente == null || _ordenExistente!.ordenTrabajoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una orden válida para copiar')),
      );
      return;
    }

    DateTime fechaSeleccionada = DateTime.now();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Generar Copia de Orden', textAlign: TextAlign.center),
              content: SizedBox(
                height: 150,
                child: Column(
                  children: [
                    Text(
                      'Se va a generar una copia de la orden ${_ordenExistente!.numeroOrdenTrabajo}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Seleccione la fecha para la nueva orden:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          setStateDialog(() {
                            fechaSeleccionada = fecha;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(fechaSeleccionada),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _procesarCopiaOrden(fechaSeleccionada);
                  },
                  child: const Text('Generar Copia'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _procesarCopiaOrden(DateTime fecha) async {
    if (_ordenExistente == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    bool errorOcurrido = false;
    
    try {
      String fechaFormateada = DateFormat('yyyy-MM-dd').format(fecha);
      int nuevaOrdenId = await ordenServices.copiarOrden(
        context, 
        _ordenExistente!.ordenTrabajoId!, 
        fechaFormateada, 
        token
      );

      if (nuevaOrdenId > 0 && mounted) {
        final Orden nuevaOrden = await ordenServices.getOrdenPorId(context, nuevaOrdenId, token);
        
        setState(() {
          _ordenExistente = nuevaOrden;
          ordenExistente = nuevaOrden;
          _isEditMode = true;
          _isReadOnly = false;
        });

        if (nuevaOrden.cliente?.clienteId != null) {
          await _cargarClienteDesdeAPI(nuevaOrden.cliente!.clienteId);
          
          if (flavor == 'automotoraargentina' && nuevaOrden.unidad?.unidadId != null) {
            await _cargarUnidadesYSeleccionar(nuevaOrden.cliente!.clienteId, nuevaOrden.unidad!.unidadId);
          }
        }
        
        _cargarDatosComunesDesdeOrden();
        
        if (flavor == 'resysol') {
          _cargarDatosResysolDesdeOrden();
        }

        await _actualizarListaOrdenes(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copia generada exitosamente. Nueva orden: ${nuevaOrden.numeroOrdenTrabajo}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        errorOcurrido = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar la copia de la orden'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      errorOcurrido = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (errorOcurrido && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo completar la copia de la orden'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildChemicalProductionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  'PRODUCCIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildLabeledTextField(
                  label: 'N° Batches',
                  controller: _numBatchesController,
                  width: 150,
                  keyboardType: TextInputType.number,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Batches',
                  controller: _batchesController,
                  width: 150,
                  keyboardType: TextInputType.number,
                  isReadOnly: _isReadOnly,
                ),
                _buildLabeledTextField(
                  label: 'Total Tambores',
                  controller: _totTambController,
                  width: 180,
                  keyboardType: TextInputType.number,
                  readOnly: _isReadOnly,
                  isReadOnly: _isReadOnly,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observaciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isReadOnly ? Colors.grey[200] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _observacionesController,
                    maxLines: 3,
                    readOnly: _isReadOnly,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'Ingrese observaciones de producción...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalActionButtons() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // CAMBIO IMPORTANTE AQUÍ: Botón de crear/actualizar orden para Resysol
            ElevatedButton(
              onPressed: _isReadOnly ? null : () async {
                if (_isReadOnly) return;
                
                if (clienteSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debe seleccionar un cliente')),
                  );
                  return;
                }

                final ordenCreada = _crearOrdenEnMemoria();
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  final ordenServices = OrdenServices();
                  // CAMBIO AQUÍ: Usamos la tupla (ordenGuardada, success)
                  final (ordenGuardada, success) = _isEditMode 
                      ? await ordenServices.actualizarOrden(context, token, ordenCreada)
                      : await ordenServices.postOrden(context, token, ordenCreada);
                  
                  // SIEMPRE cerrar el diálogo primero
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  
                  // Verificar si fue exitoso
                  if (success && ordenGuardada != null) {
                    setState(() {
                      _isEditMode = true;
                      ordenExistente = ordenGuardada;
                      _ordenExistente = ordenGuardada;
                      _isReadOnly = ordenGuardada.estado == 'EN PROCESO' || 
                                   ordenGuardada.estado == 'FINALIZADO';
                    });

                    context.read<OrdenProvider>().setOrden(ordenGuardada);

                    await _actualizarListaOrdenes(context);

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetallePiezasScreen(
                          datosProduccion: _crearDatosProduccion(),
                          ordenPrevia: ordenGuardada,
                        ),
                      ),
                    );
                  } else {
                    // Si success es false, mostrar mensaje de error
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al guardar la orden'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  // Este catch solo se ejecutará si hay una excepción no manejada en el bloque try
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error inesperado: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isReadOnly ? Colors.grey : Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isEditMode ? 'CONTINUAR A DETALLE' : 'CREAR ORDEN Y CONTINUAR A DETALLE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
            if (_isEditMode && _ordenExistente?.ordenTrabajoId != null && _ordenExistente!.ordenTrabajoId! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _mostrarDialogoOpcionesImpresion,
                  icon: const Icon(Icons.print),
                  label: const Text('IMPRIMIR ORDEN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledTextField({
    required String label,
    required TextEditingController controller,
    required double width,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    required bool isReadOnly,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly || isReadOnly,
            onTap: (readOnly || isReadOnly) ? null : onTap,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
              filled: true,
              fillColor: (readOnly || isReadOnly) ? Colors.grey[200] : Colors.white,
              suffixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
              suffixText: suffixText,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) async {
    if (_isReadOnly) return;
    
    final clienteGuardado = await showDialog<Cliente>(
      context: context,
      builder: (BuildContext context) {
        return DialogoCliente(
          clientServices: clientServices,
          token: token,
        );
      },
    );

    if (clienteGuardado != null && mounted) {
      setState(() {
        clienteSeleccionado = clienteGuardado;
        clientesLocales.add(clienteGuardado);
        unidades = [];
        unidadSeleccionada = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${clienteGuardado.nombre} creado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarDialogoNuevaUnidad(BuildContext context) async {
    if (_isReadOnly) return;
    
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe seleccionar un cliente')),
      );
      return;
    }

    final Unidad? unidadGuardada = await showDialog<Unidad>(
      context: context,
      builder: (BuildContext context) {
        return DialogoUnidad(
          token: token,
          clienteId: clienteSeleccionado!.clienteId,
          unidadesServices: unidadesServices,
          codiguerasServices: codiguerasServices,
          permitirBusquedaMatricula: true,
        );
      },
    );

    if (unidadGuardada != null) {
      List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteSeleccionado!.clienteId, 
        token
      );

      setState(() {
        unidades = unidadesActualizadas;
        try {
          unidadSeleccionada = unidades.firstWhere(
            (u) => u.matricula == unidadGuardada.matricula
          );
        } catch (e) {
          unidadSeleccionada = unidades.isNotEmpty ? unidades.first : null;
        }
      });
    }
  }

  void _editarClienteSeleccionado() async {
    if (_isReadOnly) return;
    
    if (clienteSeleccionado == null) return;

    final clienteEditado = await showDialog<Cliente>(
      context: context,
      builder: (BuildContext context) {
        return DialogoCliente(
          clientServices: clientServices,
          token: token,
          esEdicion: true,
          clienteEditar: clienteSeleccionado,
        );
      },
    );

    if (clienteEditado != null && mounted) {
      setState(() {
        clienteSeleccionado = clienteEditado;
      });

      await _cargarUnidadesYSeleccionar(clienteEditado.clienteId, unidadSeleccionada?.unidadId ?? 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${clienteEditado.nombre} actualizado exitosamente'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _editarUnidadSeleccionada() async {
    if (_isReadOnly) return;
    
    if (unidadSeleccionada == null || clienteSeleccionado == null) return;

    final Unidad? unidadEditada = await showDialog<Unidad>(
      context: context,
      builder: (BuildContext context) {
        return DialogoUnidad(
          token: token,
          clienteId: clienteSeleccionado!.clienteId,
          unidadesServices: unidadesServices,
          codiguerasServices: codiguerasServices,
          permitirBusquedaMatricula: false,
          unidadExistente: unidadSeleccionada,
        );
      },
    );

    if (unidadEditada != null && mounted) {
      List<Unidad> unidadesActualizadas = await unidadesServices.getUnidadesDeCliente(
        context, 
        clienteSeleccionado!.clienteId, 
        token
      );

      setState(() {
        unidades = unidadesActualizadas;
        try {
          unidadSeleccionada = unidades.firstWhere(
            (u) => u.unidadId == unidadEditada.unidadId
          );
        } catch (e) {
          unidadSeleccionada = unidades.isNotEmpty ? unidades.first : null;
        }
      });
    }
  }

  @override
  void dispose() {
    _ordenCompraController.dispose();
    _siniestroController.dispose();
    _kmController.dispose();
    _pedidoController.removeListener(_calcularTotalTambores);
    _envaseController.removeListener(_calcularTotalTambores);
    _numBatchesController.dispose();
    _iniciadaEnController.dispose();
    _produccionController.dispose();
    _bolsasController.dispose();
    _nvporcController.dispose();
    _viscController.dispose();
    _totTambController.dispose(); 
    _fechaEmisionController.dispose(); 
    _numeroController.dispose(); 
    _productoController.dispose(); 
    _refController.dispose(); 
    _pedidoController.dispose(); 
    _envaseController.dispose(); 
    _batchesController.dispose(); 
    _observacionesController.dispose(); 
    _numOrdenController.dispose();
    _comentClienteController.dispose();
    _comentTrabajoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}