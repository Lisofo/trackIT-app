// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/models/material_consumo.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/services/linea_services.dart';
import 'package:app_tec_sedel/services/excel_consumo_service.dart';
import 'package:provider/provider.dart';
import 'package:app_tec_sedel/models/lote.dart';
import 'package:app_tec_sedel/services/lote_services.dart';

// Enumeración para modos de guardado
enum GuardadoModo {
  MANUAL,
  AUTOMATICO,
  DEBOUNCE,
}

// ignore: must_be_immutable
class ConsumosScreen extends StatefulWidget {
  late Lote? loteSeleccionado; // Cambiar de final a mutable
  
  ConsumosScreen({super.key, this.loteSeleccionado});

  @override
  ConsumosScreenState createState() => ConsumosScreenState();
}

class ConsumosScreenState extends State<ConsumosScreen> {
  final OrdenServices _ordenServices = OrdenServices();
  final LineasServices _lineasServices = LineasServices();
  final LoteServices _loteServices = LoteServices();
  final ExcelConsumoService _excelService = ExcelConsumoService();
  
  // Variables principales
  List<Orden> _ordenes = [];
  List<Orden> _ordenesSeleccionadas = [];
  TablaConsumoExcel _tablaConsumo = TablaConsumoExcel();
  bool _cargando = false;
  bool _cargandoMateriales = false;
  
  // Controladores para campos editables
  Map<String, Map<String, TextEditingController>> controllers = {};
  
  // Controladores para agrupador
  Map<String, TextEditingController> agrupadorControllers = {};
  
  // Variables para almacenar líneas
  Map<String, Linea> lineasOriginalesMap = {};
  List<Linea> lineasActuales = [];
  
  // Variables para líneas de lote
  List<LineaLote> _lineasLote = [];
  Map<String, LineaLote> lineasLoteMap = {};
  bool _cargandoLineasLote = false;
  
  // ============================================
  // NUEVO: SISTEMA DE MULTIPLICACIÓN PARA FILAS 25 Y 26
  // ============================================
  
  // NUEVAS VARIABLES PARA FILAS 25 Y 26
  double _multiplicadorFila25 = 0.0;
  double _multiplicadorFila26 = 0.0;
  Map<String, bool> materialesSeleccionados = {}; // Para checkboxes (compatibilidad)
  Map<String, bool> agrupadoresSeleccionados = {}; // Para checkboxes por agrupador
  
  // Controladores para los campos de multiplicación
  late TextEditingController _controllerMulti25;
  late TextEditingController _controllerMulti26;
  
  // ============================================
  // NUEVO: SISTEMA DE GUARDADO MEJORADO
  // ============================================
  bool _hayCambiosSinGuardar = false;
  bool _guardandoAuto = false;
  GuardadoModo _modoGuardado = GuardadoModo.MANUAL;
  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(seconds: 3);
  
  // Almacenar cambios pendientes
  Map<String, Map<String, double>> cambiosPendientesLote = {};
  Map<String, Map<String, double>> cambiosPendientesOrden = {};
  
  // ============================================
  // NUEVO: CONTROLADORES PARA ENVASADO PRODUCCIÓN
  // ============================================
  late TextEditingController _cantTamboresController;
  late TextEditingController _kgTamborController;
  late TextEditingController _picoProduccionController;
  late TextEditingController _cantPalletsController;
  late TextEditingController _totalEmbarcarController;
  
  // Controladores para picos de producción
  late TextEditingController _picoCantidad1Controller;
  late TextEditingController _picoTotal1Controller;
  late TextEditingController _picoCantidad2Controller;
  late TextEditingController _picoKg2Controller;
  late TextEditingController _picoTotal2Controller;
  
  // NUEVO: Variable para carga de lote
  bool _cargandoLote = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores de multiplicación
    _controllerMulti25 = TextEditingController(text: '0');
    _controllerMulti26 = TextEditingController(text: '0');
    
    // Inicializar controladores de envasado producción con valores por defecto
    _cantTamboresController = TextEditingController(text: '0');
    _kgTamborController = TextEditingController(text: '0');
    _picoProduccionController = TextEditingController(text: '0');
    _cantPalletsController = TextEditingController(text: '0');
    _totalEmbarcarController = TextEditingController(text: '0');
    
    // Controladores para picos de producción
    _picoCantidad1Controller = TextEditingController(text: '0');
    _picoTotal1Controller = TextEditingController(text: '0');
    _picoCantidad2Controller = TextEditingController(text: '0');
    _picoKg2Controller = TextEditingController(text: '0');
    _picoTotal2Controller = TextEditingController(text: '0');
    
    // Agregar listeners después de inicializar
    _agregarListeners();
    
    if (widget.loteSeleccionado != null) {
      // CARGAR EL LOTE COMPLETO CON TODOS SUS ATRIBUTOS
      _cargarLoteCompleto().then((_) async {
        // Convertir órdenes de trabajo a órdenes completas
        _ordenesSeleccionadas = await _convertirOrdenesTrabajoAOrden(widget.loteSeleccionado!.ordenes ?? []);
        await _cargarLineasLote(); // Asegurar que se complete
        _cargarMateriales();
      });
    } else {
      _cargarOrdenes();
    }
  }

  // NUEVO MÉTODO: Cargar el lote completo con todos sus atributos
  Future<void> _cargarLoteCompleto() async {
    if (widget.loteSeleccionado == null || widget.loteSeleccionado!.loteId == null) return;
    
    setState(() => _cargandoLote = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      
      // Obtener el lote completo desde la API
      final loteCompleto = await _loteServices.getLotePorId(
        context, 
        widget.loteSeleccionado!.loteId!, 
        token
      );
      
      // Actualizar el widget con el lote completo
      widget.loteSeleccionado = loteCompleto;
      
      // Actualizar los controladores con los valores del lote
      _actualizarControladoresDesdeLote(loteCompleto);
      
    } catch (e) {
      print('Error cargando lote completo: $e');
      // Si falla la carga completa, usar los valores que ya tenemos
      _actualizarControladoresDesdeLote(widget.loteSeleccionado!);
    } finally {
      setState(() => _cargandoLote = false);
    }
  }

  // NUEVO MÉTODO: Actualizar controladores desde los valores del lote
  void _actualizarControladoresDesdeLote(Lote lote) {
    // Primero remover listeners temporales para evitar múltiples llamadas
    _removerListenersTemporales();
    
    // Actualizar valores de envasado producción
    _cantTamboresController.text = (lote.cantTambores ?? 0).toString();
    _kgTamborController.text = (lote.kgTambor ?? 0).toString();
    _picoProduccionController.text = (lote.picoProduccion ?? 0).toString();
    _cantPalletsController.text = (lote.cantPallets ?? 0).toString();
    _totalEmbarcarController.text = (lote.totalEmbarcar ?? 0).toString();
    
    // Para los picos de producción
    _picoCantidad1Controller.text = '0';
    _picoTotal1Controller.text = '0';
    _picoCantidad2Controller.text = '0';
    _picoKg2Controller.text = (lote.kgTambor ?? 0).toString();
    _picoTotal2Controller.text = '0';
    
    // Volver a agregar listeners
    _agregarListeners();
  }

  // Métodos auxiliares para manejar listeners
  void _removerListenersTemporales() {
    _cantTamboresController.removeListener(_marcarCambiosLote);
    _kgTamborController.removeListener(_marcarCambiosLote);
    _picoProduccionController.removeListener(_marcarCambiosLote);
    _cantPalletsController.removeListener(_marcarCambiosLote);
    _totalEmbarcarController.removeListener(_marcarCambiosLote);
    _picoCantidad1Controller.removeListener(_marcarCambiosLote);
    _picoTotal1Controller.removeListener(_marcarCambiosLote);
    _picoCantidad2Controller.removeListener(_marcarCambiosLote);
    _picoKg2Controller.removeListener(_marcarCambiosLote);
    _picoTotal2Controller.removeListener(_marcarCambiosLote);
  }

  void _agregarListeners() {
    _cantTamboresController.addListener(_marcarCambiosLote);
    _kgTamborController.addListener(_marcarCambiosLote);
    _picoProduccionController.addListener(_marcarCambiosLote);
    _cantPalletsController.addListener(_marcarCambiosLote);
    _totalEmbarcarController.addListener(_marcarCambiosLote);
    _picoCantidad1Controller.addListener(_marcarCambiosLote);
    _picoTotal1Controller.addListener(_marcarCambiosLote);
    _picoCantidad2Controller.addListener(_marcarCambiosLote);
    _picoKg2Controller.addListener(_marcarCambiosLote);
    _picoTotal2Controller.addListener(_marcarCambiosLote);
  }

  Future<List<Orden>> _convertirOrdenesTrabajoAOrden(List<OrdenTrabajo> ordenesTrabajo) async {
    if (ordenesTrabajo.isEmpty) return [];
    
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      String tecnicoId = authProvider.tecnicoId.toString();
      
      // Obtener todas las órdenes disponibles
      List<Orden> todasLasOrdenes = await _ordenServices.getOrden(context, tecnicoId, token);
      
      // Filtrar las órdenes que coinciden por numeroOrdenTrabajo
      List<Orden> ordenesFiltradas = [];
      
      for (var ordenTrabajo in ordenesTrabajo) {
        // Buscar la orden completa que coincide
        Orden? ordenCompleta = todasLasOrdenes.firstWhere(
          (orden) => orden.numeroOrdenTrabajo == ordenTrabajo.numeroOrdenTrabajo,
          orElse: () => Orden(), // Retorna una orden vacía si no encuentra
        );
        
        // Si se encontró una orden completa, agregarla
        if (ordenCompleta.ordenTrabajoId != null) {
          ordenesFiltradas.add(ordenCompleta);
        } else {
          // Si no se encontró, crear una orden básica con los datos disponibles
          ordenesFiltradas.add(Orden(
            ordenTrabajoId: ordenTrabajo.ordenTrabajoId,
            numeroOrdenTrabajo: ordenTrabajo.numeroOrdenTrabajo,
            descripcion: ordenTrabajo.descripcion,
            fechaOrdenTrabajo: DateTime.now(),
          ));
        }
      }
      
      return ordenesFiltradas;
    } catch (e) {
      print('Error convirtiendo órdenes de trabajo: $e');
      // En caso de error, retornar órdenes básicas
      return ordenesTrabajo.map((ot) {
        return Orden(
          ordenTrabajoId: ot.ordenTrabajoId,
          numeroOrdenTrabajo: ot.numeroOrdenTrabajo,
          descripcion: ot.descripcion,
          fechaOrdenTrabajo: DateTime.now(),
        );
      }).toList();
    }
  }

  Future<void> _cargarLineasLote() async {
    if (widget.loteSeleccionado == null || widget.loteSeleccionado!.loteId == null) return;
    
    setState(() => _cargandoLineasLote = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      
      _lineasLote = await _loteServices.getLineasLote(
        context, 
        widget.loteSeleccionado!.loteId!, 
        token
      );
      
      print('Líneas de lote cargadas: ${_lineasLote.length}');
      
      lineasLoteMap.clear();
      for (var linea in _lineasLote) {
        if (linea.itemId != null && linea.referencia != null) {
          final key = "${linea.itemId}_${linea.referencia}";
          lineasLoteMap[key] = linea;
          print('  Línea lote: itemId=${linea.itemId}, referencia=${linea.referencia}, agrupador=${linea.agrupador}');
        }
      }
      
    } catch (e) {
      print('Error cargando líneas de lote: $e');
    } finally {
      setState(() => _cargandoLineasLote = false);
    }
  }

  @override
  void dispose() {
    // Cancelar timer de debounce
    _debounceTimer?.cancel();
    
    // Remover listeners de controladores de lote
    _cantTamboresController.removeListener(_marcarCambiosLote);
    _kgTamborController.removeListener(_marcarCambiosLote);
    _picoProduccionController.removeListener(_marcarCambiosLote);
    _cantPalletsController.removeListener(_marcarCambiosLote);
    _totalEmbarcarController.removeListener(_marcarCambiosLote);
    _picoCantidad1Controller.removeListener(_marcarCambiosLote);
    _picoTotal1Controller.removeListener(_marcarCambiosLote);
    _picoCantidad2Controller.removeListener(_marcarCambiosLote);
    _picoKg2Controller.removeListener(_marcarCambiosLote);
    _picoTotal2Controller.removeListener(_marcarCambiosLote);
    
    // Limpiar controladores
    controllers.forEach((codigo, map) {
      map.forEach((key, controller) {
        controller.dispose();
      });
    });
    
    // Limpiar controladores de agrupador
    agrupadorControllers.forEach((key, controller) {
      controller.dispose();
    });
    
    // Limpiar controladores de multiplicación
    _controllerMulti25.dispose();
    _controllerMulti26.dispose();
    
    // Limpiar controladores de envasado producción
    _cantTamboresController.dispose();
    _kgTamborController.dispose();
    _picoProduccionController.dispose();
    _cantPalletsController.dispose();
    _totalEmbarcarController.dispose();
    _picoCantidad1Controller.dispose();
    _picoTotal1Controller.dispose();
    _picoCantidad2Controller.dispose();
    _picoKg2Controller.dispose();
    _picoTotal2Controller.dispose();
    
    super.dispose();
  }

  Future<void> _cargarOrdenes() async {
    setState(() => _cargando = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      String tecnicoId = authProvider.tecnicoId.toString();
      
      _ordenes = await _ordenServices.getOrden(context, tecnicoId, token);
      print('Órdenes cargadas: ${_ordenes.length}');
    } catch (e) {
      print('Error cargando órdenes: $e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarMateriales() async {
    if (_ordenesSeleccionadas.isEmpty) {
      setState(() {
        _tablaConsumo = TablaConsumoExcel();
        _cargandoMateriales = false;
        lineasOriginalesMap.clear();
        lineasActuales.clear();
        agrupadorControllers.clear();
        _hayCambiosSinGuardar = false;
        cambiosPendientesLote.clear();
        cambiosPendientesOrden.clear();
        materialesSeleccionados.clear(); // Limpiar selección
        agrupadoresSeleccionados.clear(); // Limpiar selección de agrupadores
      });
      return;
    }
    
    setState(() => _cargandoMateriales = true);

    try {
      final authProvider = context.read<AuthProvider>();
      String token = authProvider.token;
      List<Linea> todasLineas = [];

      // Limpiar datos anteriores
      lineasOriginalesMap.clear();
      lineasActuales.clear();
      agrupadorControllers.clear();
      _hayCambiosSinGuardar = false;
      cambiosPendientesLote.clear();
      cambiosPendientesOrden.clear();
      materialesSeleccionados.clear();
      agrupadoresSeleccionados.clear();

      for (var orden in _ordenesSeleccionadas) {
        final lineas = await _lineasServices.getLineasDeOrden(
          context, 
          orden.ordenTrabajoId!, 
          token
        );
        todasLineas.addAll(lineas);
        
        // DEPURACIÓN: Mostrar líneas cargadas con sus agrupadores
        for (var linea in lineas) {
          final key = "${linea.ordenTrabajoId}_${linea.codItem}";
          lineasOriginalesMap[key] = linea.copyWith();
          lineasActuales.add(linea.copyWith());
          print('Línea cargada: ${linea.codItem} (itemId: ${linea.itemId}) - Agrupador: "${linea.agrupador}"');
        }
      }

      _tablaConsumo = _excelService.procesarDatosReales(
        todasLineas, 
        _ordenesSeleccionadas,
        _lineasLote,
      );
      
      _inicializarControllers();
      _inicializarSeleccionMateriales();
      
    } catch (e) {
      print('Error cargando materiales: $e');
    } finally {
      setState(() => _cargandoMateriales = false);
    }
  }

  void _inicializarControllers() {
    controllers.clear();
    agrupadorControllers.clear();
    
    print('=== INICIALIZANDO CONTROLADORES ===');
    print('Total filas en tabla: ${_tablaConsumo.filas.length}');
    print('Líneas actuales cargadas: ${lineasActuales.length}');
    print('Líneas lote cargadas: ${lineasLoteMap.length}');
    
    // DEPURACIÓN: Mostrar todas las líneas disponibles
    print('\n--- Líneas de Orden disponibles ---');
    for (var linea in lineasActuales) {
      print('  ${linea.codItem} (itemId: ${linea.itemId}) -> Agrupador: "${linea.agrupador}"');
    }
    
    print('\n--- Líneas de Lote disponibles ---');
    for (var entry in lineasLoteMap.entries) {
      final linea = entry.value;
      print('  itemId: ${linea.itemId}, referencia: ${linea.referencia} -> Agrupador: "${linea.agrupador}"');
    }
    
    for (var fila in _tablaConsumo.filas) {
      controllers[fila.codigo] = {};
      
      // Inicializar controlador para el agrupador
      String agrupadorInicial = '';
      bool encontrado = false;
      
      print('\nBuscando agrupador para: ${fila.codigo} (itemId: ${fila.itemId})');
      
      // 1. BUSCAR EN LÍNEAS DE ORDEN (lineasActuales)
      for (var linea in lineasActuales) {
        // Comparar por código de item o por itemId
        if ((linea.codItem == fila.codigo || linea.itemId == fila.itemId) && 
            linea.agrupador != null && 
            linea.agrupador!.isNotEmpty) {
          agrupadorInicial = linea.agrupador!;
          encontrado = true;
          print('  ✓ ENCONTRADO en línea orden: "$agrupadorInicial"');
          break;
        }
      }
      
      // 2. SI NO SE ENCONTRÓ, BUSCAR EN LÍNEAS DE LOTE
      if (!encontrado) {
        for (var entry in lineasLoteMap.entries) {
          final linea = entry.value;
          if (linea.itemId == fila.itemId && 
              linea.agrupador != null && 
              linea.agrupador!.isNotEmpty) {
            agrupadorInicial = linea.agrupador!;
            encontrado = true;
            print('  ✓ ENCONTRADO en línea lote: "$agrupadorInicial"');
            break;
          }
        }
      }
      
      // 3. SI NO SE ENCONTRÓ EN NINGUNO
      if (!encontrado) {
        print('  ⚠ NO ENCONTRADO agrupador para ${fila.codigo}');
        // Buscar en líneas actuales para debug
        print('    Buscando coincidencias en líneas orden:');
        for (var linea in lineasActuales) {
          if (linea.codItem == fila.codigo || linea.itemId == fila.itemId) {
            print('      Coincidencia: ${linea.codItem} (itemId: ${linea.itemId}) -> Agrupador: "${linea.agrupador}"');
          }
        }
        // Buscar en líneas lote para debug
        print('    Buscando coincidencias en líneas lote:');
        for (var entry in lineasLoteMap.entries) {
          final linea = entry.value;
          if (linea.itemId == fila.itemId) {
            print('      Coincidencia: itemId: ${linea.itemId} -> Agrupador: "${linea.agrupador}"');
          }
        }
      }
      
      agrupadorControllers[fila.codigo] = TextEditingController(
        text: agrupadorInicial
      );
      
      // Inicializar controladores para ANT1-4
      for (var i = 1; i <= 4; i++) {
        final key = 'ant_$i';
        controllers[fila.codigo]![key] = TextEditingController(
          text: fila.consumosAnteriores[key]?.toStringAsFixed(0) ?? '0'
        );
      }
      
      // Inicializar controladores para cada orden
      for (var orden in _ordenesSeleccionadas) {
        final ordenId = orden.ordenTrabajoId.toString();
        controllers[fila.codigo]![ordenId] = TextEditingController(
          text: fila.consumosPorOrden[ordenId]?.toStringAsFixed(0) ?? '0'
        );
      }
    }
    
    print('=== FIN INICIALIZACIÓN CONTROLADORES ===');
    print('Total controladores agrupador creados: ${agrupadorControllers.length}');
  }
  
  // MODIFICADO MÉTODO: Inicializar selección de materiales por AGRUPADOR
  void _inicializarSeleccionMateriales() {
    materialesSeleccionados.clear();
    agrupadoresSeleccionados.clear();
    
    // Agrupar materiales por agrupador
    Map<String, List<String>> materialesPorAgrupador = {};
    
    for (var fila in _tablaConsumo.filas) {
      final agrupador = agrupadorControllers[fila.codigo]?.text.trim() ?? 'Sin agrupar';
      
      if (!materialesPorAgrupador.containsKey(agrupador)) {
        materialesPorAgrupador[agrupador] = [];
      }
      materialesPorAgrupador[agrupador]!.add(fila.codigo);
      
      // Inicializar selección individual (para compatibilidad)
      materialesSeleccionados[fila.codigo] = true;
    }
    
    // Inicializar todos los agrupadores como seleccionados
    for (var agrupador in materialesPorAgrupador.keys) {
      agrupadoresSeleccionados[agrupador] = true;
    }
  }

  // ============================================
  // NUEVO: SISTEMA DE GUARDADO UNIFICADO
  // ============================================
  
  void _actualizarValorDesdeController(String codigoMaterial, String columna) {
    final controller = controllers[codigoMaterial]?[columna];
    if (controller != null) {
      final nuevoValor = double.tryParse(controller.text) ?? 0.0;
      final valorAnterior = _tablaConsumo.obtenerValor(codigoMaterial, columna) ?? 0.0;
      
      // Solo procesar si hay cambio real
      if (nuevoValor != valorAnterior) {
        // Actualizar tabla localmente
        _tablaConsumo.actualizarValor(codigoMaterial, columna, nuevoValor);
        
        // Manejar según tipo de columna y modo de guardado
        if (columna.startsWith('ant_')) {
          _manejarCambioLote(codigoMaterial, columna, nuevoValor, valorAnterior);
        } else {
          _manejarCambioOrden(codigoMaterial, int.parse(columna), nuevoValor);
        }
        
        // Actualizar estado
        setState(() {
          _hayCambiosSinGuardar = true;
        });
        
        // Ejecutar según modo de guardado
        _ejecutarSegunModoGuardado();
      }
    }
  }
  
  void _manejarCambioLote(
    String codigoMaterial, 
    String columna,
    double nuevoValor,
    double valorAnterior
  ) {
    // Guardar en cambios pendientes
    if (!cambiosPendientesLote.containsKey(codigoMaterial)) {
      cambiosPendientesLote[codigoMaterial] = {};
    }
    cambiosPendientesLote[codigoMaterial]![columna] = nuevoValor;
  }
  
  void _manejarCambioOrden(
    String codigoMaterial, 
    int ordenTrabajoId,
    double nuevoValor
  ) {
    final columna = ordenTrabajoId.toString();
    
    // Guardar en cambios pendientes
    if (!cambiosPendientesOrden.containsKey(codigoMaterial)) {
      cambiosPendientesOrden[codigoMaterial] = {};
    }
    cambiosPendientesOrden[codigoMaterial]![columna] = nuevoValor;
    
    // Actualizar línea localmente también
    _actualizarLineaControlLocal(codigoMaterial, ordenTrabajoId, nuevoValor);
  }
  
  void _actualizarLineaControlLocal(String codigoMaterial, int ordenTrabajoId, double nuevoControl) {
    for (int i = 0; i < lineasActuales.length; i++) {
      final linea = lineasActuales[i];
      if (linea.codItem == codigoMaterial && linea.ordenTrabajoId == ordenTrabajoId) {
        lineasActuales[i] = linea.copyWith(control: nuevoControl);
        break;
      }
    }
  }
  
  void _ejecutarSegunModoGuardado() {
    switch (_modoGuardado) {
      case GuardadoModo.MANUAL:
        // Solo marcar cambios pendientes, no hacer nada automático
        break;
        
      case GuardadoModo.DEBOUNCE:
        // Programar guardado automático con debounce
        _programarGuardadoDebounce();
        break;
        
      case GuardadoModo.AUTOMATICO:
        // Guardar inmediatamente
        _guardarCambiosAutomaticamente();
        break;
    }
  }
  
  void _programarGuardadoDebounce() {
    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();
    
    // Crear nuevo timer
    _debounceTimer = Timer(_debounceDuration, () {
      _guardarCambiosAutomaticamente();
    });
  }
  
  Future<void> _guardarCambiosAutomaticamente() async {
    if (!_hayCambiosSinGuardar || _guardandoAuto) return;
    
    setState(() => _guardandoAuto = true);
    
    try {
      await _procesarCambiosPendientes();
      
      setState(() {
        _hayCambiosSinGuardar = false;
        _guardandoAuto = false;
      });
      
      // Mostrar confirmación breve
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados automáticamente'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      setState(() => _guardandoAuto = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar automáticamente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _procesarCambiosPendientes() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    
    // 0. Primero procesar cambios de agrupador
    await _procesarCambiosAgrupador();
    
    // 1. Siempre guardar agrupadores en órdenes (incluso si no hay LineaLote)
    await _guardarAgrupadoresEnOrdenes(token);
    
    // 2. Procesar cambios de lote (líneas de consumo)
    if (widget.loteSeleccionado != null && cambiosPendientesLote.isNotEmpty) {
      await _procesarCambiosLote(token);
    }
    
    // 3. Procesar cambios de órdenes
    if (cambiosPendientesOrden.isNotEmpty) {
      await _procesarCambiosOrdenes(token);
    }
    
    // 4. Guardar datos de envasado producción del lote
    if (widget.loteSeleccionado != null) {
      await _guardarDatosLote();
    }
  }
  
  // NUEVO MÉTODO: Procesar cambios de agrupador
  Future<void> _procesarCambiosAgrupador() async {
    print('=== PROCESANDO CAMBIOS DE AGRUPADOR ===');
    for (var entry in agrupadorControllers.entries) {
      final codigoMaterial = entry.key;
      final controller = entry.value;
      final nuevoAgrupador = controller.text.trim();
      
      print('Material: $codigoMaterial -> Agrupador: "$nuevoAgrupador"');
      
      // Actualizar en líneas de orden (lineasActuales)
      for (int i = 0; i < lineasActuales.length; i++) {
        if (lineasActuales[i].codItem == codigoMaterial) {
          lineasActuales[i] = lineasActuales[i].copyWith(agrupador: nuevoAgrupador);
          print('  Actualizado en línea orden: ${lineasActuales[i].codItem}');
        }
      }
      
      // Actualizar en líneas originales
      for (var key in lineasOriginalesMap.keys) {
        if (key.contains(codigoMaterial)) {
          final linea = lineasOriginalesMap[key];
          if (linea != null) {
            lineasOriginalesMap[key] = linea.copyWith(agrupador: nuevoAgrupador);
          }
        }
      }
      
      // Actualizar en líneas de lote
      for (var entryLote in lineasLoteMap.entries) {
        final fila = _tablaConsumo.obtenerFila(codigoMaterial);
        if (fila != null && entryLote.value.itemId == fila.itemId) {
          final key = entryLote.key;
          final lineaActualizada = entryLote.value.copyWith(agrupador: nuevoAgrupador);
          lineasLoteMap[key] = lineaActualizada;
          print('  Actualizado en línea lote: itemId ${fila.itemId}');
        }
      }
    }
    print('=== FIN PROCESAMIENTO AGRUPADOR ===');
  }
  
  Future<void> _procesarCambiosLote(String token) async {
    final loteId = widget.loteSeleccionado!.loteId!;
    
    for (var entryMaterial in cambiosPendientesLote.entries) {
      final codigoMaterial = entryMaterial.key;
      final cambiosPorReferencia = entryMaterial.value;
      
      final fila = _tablaConsumo.obtenerFila(codigoMaterial);
      if (fila == null) continue;
      
      for (var entryReferencia in cambiosPorReferencia.entries) {
        final referencia = entryReferencia.key;
        final nuevoValor = entryReferencia.value;
        
        await _procesarUnCambioLote(
          fila.itemId, referencia, nuevoValor, token, loteId, codigoMaterial
        );
      }
    }
    
    // Limpiar cambios procesados
    cambiosPendientesLote.clear();
  }
  
  Future<void> _procesarUnCambioLote(
    int itemId,
    String referencia,
    double nuevoValor,
    String token,
    int loteId,
    String codigoMaterial
  ) async {
    try {
      final key = "${itemId}_$referencia";
      final lineaExistente = lineasLoteMap[key];
      final ordinal = _obtenerOrdinalDesdeReferencia(referencia);
      
      // Obtener el agrupador actual del controlador
      String agrupador = '';
      if (agrupadorControllers.containsKey(codigoMaterial)) {
        agrupador = agrupadorControllers[codigoMaterial]!.text.trim();
      } else {
        // Si no hay controlador, buscar en líneas actuales
        for (var linea in lineasActuales) {
          if (linea.codItem == codigoMaterial) {
            agrupador = linea.agrupador ?? '';
            break;
          }
        }
      }
      
      print('Procesando cambio lote: itemId=$itemId, referencia=$referencia, agrupador="$agrupador"');
      
      if (nuevoValor == 0 && lineaExistente != null) {
        // Eliminar - pero primero guardar el agrupador en la línea de orden si existe
        await _loteServices.deleteLineaLote(
          context, token, loteId, lineaExistente.lineaId!
        );
        lineasLoteMap.remove(key);
        
      } else if (nuevoValor > 0 && lineaExistente != null) {
        // Actualizar - siempre incluir el agrupador
        final lineaActualizada = lineaExistente.copyWith(
          cantidad: nuevoValor.toInt(),
          control: nuevoValor.toInt(),
          referencia: referencia,
          ordinal: ordinal,
          agrupador: agrupador, // Incluir agrupador siempre
        );
        
        await _loteServices.updateLineaLote(
          context, token, loteId, lineaActualizada
        );
        lineasLoteMap[key] = lineaActualizada;
        
      } else if (nuevoValor > 0 && lineaExistente == null) {
        // Crear nueva línea con agrupador
        final nuevaLinea = LineaLote(
          loteId: loteId,
          itemId: itemId,
          ordinal: ordinal,
          cantidad: nuevoValor.toInt(),
          control: nuevoValor.toInt(),
          comentario: 'Consumo anterior $referencia',
          referencia: referencia,
          piezaId: itemId,
          agrupador: agrupador, // Incluir agrupador siempre
        );
        
        final lineaCreada = await _loteServices.createLineaLote(
          context, token, loteId, nuevaLinea
        );
        lineasLoteMap[key] = lineaCreada;
      }
      
    } catch (e) {
      print('Error procesando cambio de lote: $e');
      rethrow;
    }
  }
  
  Future<void> _procesarCambiosOrdenes(String token) async {
    int actualizacionesExitosas = 0;
    int errores = 0;
    
    print('=== PROCESANDO CAMBIOS DE ÓRDENES ===');
    
    for (var entryMaterial in cambiosPendientesOrden.entries) {
      final codigoMaterial = entryMaterial.key;
      final cambiosPorOrden = entryMaterial.value;
      final agrupador = agrupadorControllers[codigoMaterial]?.text.trim() ?? '';
      
      print('Material: $codigoMaterial -> Agrupador: "$agrupador"');
      
      for (var entryOrden in cambiosPorOrden.entries) {
        final ordenIdStr = entryOrden.key;
        final nuevoValor = entryOrden.value;
        final ordenId = int.parse(ordenIdStr);
        
        try {
          // Buscar la línea correspondiente
          final lineaKey = "${ordenId}_$codigoMaterial";
          final lineaOriginal = lineasOriginalesMap[lineaKey];
          
          if (lineaOriginal != null) {
            // Incluir el agrupador en la línea actualizada
            final lineaActualizada = lineaOriginal.copyWith(
              control: nuevoValor,
              agrupador: agrupador, // Agregar agrupador aquí
            );
            
            print('  Actualizando línea orden: $lineaKey, control: $nuevoValor, agrupador: "$agrupador"');
            
            final resultado = await _lineasServices.actualizarLinea(
              context, ordenId, lineaActualizada, token
            );
            
            if (_lineasServices.statusCode == 1) {
              actualizacionesExitosas++;
              // Actualizar también en línea original con el agrupador
              lineasOriginalesMap[lineaKey] = resultado.copyWith();
              print('  ✓ Línea actualizada exitosamente');
            } else {
              errores++;
              print('  ✗ Error actualizando línea');
            }
          } else {
            print('  ⚠ Línea no encontrada: $lineaKey');
          }
        } catch (e) {
          print('Error actualizando línea de orden: $e');
          errores++;
        }
      }
    }
    
    print('Resultado: $actualizacionesExitosas éxitos, $errores errores');
    print('=== FIN PROCESAMIENTO ÓRDENES ===');
    
    // Limpiar cambios procesados
    cambiosPendientesOrden.clear();
  }

  Future<void> _guardarAgrupadoresEnOrdenes(String token) async {
    print('=== GUARDANDO AGRUPADORES EN ÓRDENES ===');
    
    for (var entry in agrupadorControllers.entries) {
      final codigoMaterial = entry.key;
      final controller = entry.value;
      final nuevoAgrupador = controller.text.trim();
      
      if (nuevoAgrupador.isEmpty) continue;
      
      print('Material: $codigoMaterial -> Agrupador: "$nuevoAgrupador"');
      
      // Para cada orden, actualizar el agrupador en la línea correspondiente
      for (var orden in _ordenesSeleccionadas) {
        final ordenId = orden.ordenTrabajoId!;
        final lineaKey = "${ordenId}_$codigoMaterial";
        final lineaOriginal = lineasOriginalesMap[lineaKey];
        
        if (lineaOriginal != null) {
          try {
            // Crear copia con el nuevo agrupador
            final lineaActualizada = lineaOriginal.copyWith(
              agrupador: nuevoAgrupador,
            );
            
            print('  Actualizando agrupador en orden $ordenId');
            
            final resultado = await _lineasServices.actualizarLinea(
              context, ordenId, lineaActualizada, token
            );
            
            if (_lineasServices.statusCode == 1) {
              // Actualizar en el mapa original
              lineasOriginalesMap[lineaKey] = resultado.copyWith();
              print('  ✓ Agrupador guardado exitosamente en orden');
            }
          } catch (e) {
            print('  ✗ Error guardando agrupador en orden: $e');
          }
        }
      }
    }
    
    print('=== FIN GUARDADO AGRUPADORES ===');
  }
  
  // NUEVO MÉTODO: Guardar datos de envasado producción en el lote
  Future<void> _guardarDatosLote() async {
    if (widget.loteSeleccionado == null) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      // Obtener valores actuales de los controladores
      int cantidadTambores = int.tryParse(_cantTamboresController.text) ?? 0;
      int kgPorTambor = int.tryParse(_kgTamborController.text) ?? 0;
      int picoProduccion = int.tryParse(_picoProduccionController.text) ?? 0;
      int cantPallets = int.tryParse(_cantPalletsController.text) ?? 0;
      int totalEmbarcar = int.tryParse(_totalEmbarcarController.text) ?? 0;
      
      // Calcular merma y porcentaje de merma
      int picoCantidad1 = int.tryParse(_picoCantidad1Controller.text) ?? 0;
      int picoTotal1 = int.tryParse(_picoTotal1Controller.text) ?? 0;
      int picoCantidad2 = int.tryParse(_picoCantidad2Controller.text) ?? 0;
      int picoKg2 = int.tryParse(_picoKg2Controller.text) ?? kgPorTambor;
      int picoTotal2 = int.tryParse(_picoTotal2Controller.text) ?? 0;
      
      int totalExportacion = cantidadTambores * kgPorTambor;
      int totalEnvasadoCalculado = totalExportacion + picoTotal1 + picoProduccion;
      int mermaProceso = totalEmbarcar - totalEnvasadoCalculado;
      double porcentajeMerma = totalEnvasadoCalculado > 0 
          ? (mermaProceso / totalEnvasadoCalculado) * 100 
          : 0.0;

      // Crear lote actualizado con TODOS los valores, incluyendo los que ya tenía
      final loteActualizado = widget.loteSeleccionado!.copyWith(
        totalEmbarcar: totalEmbarcar,
        picoProduccion: picoProduccion,
        cantTambores: cantidadTambores,
        kgTambor: kgPorTambor,
        mermaProceso: mermaProceso,
        porcentajeMerma: porcentajeMerma,
        cantPallets: cantPallets,
        // Mantener los valores existentes que no se modifican en esta pantalla
        lote: widget.loteSeleccionado!.lote,
        nvporc: widget.loteSeleccionado!.nvporc,
        visc: widget.loteSeleccionado!.visc,
        fechaLote: widget.loteSeleccionado!.fechaLote,
        estado: widget.loteSeleccionado!.estado,
        observaciones: widget.loteSeleccionado!.observaciones,
        pedidoId: widget.loteSeleccionado!.pedidoId,
      );

      // Obtener IDs de las órdenes actuales
      final ordenesIds = _ordenesSeleccionadas
          .where((orden) => orden.ordenTrabajoId != null)
          .map((orden) => orden.ordenTrabajoId!)
          .toList();

      // Llamar al servicio para actualizar el lote
      final loteActualizadoRespuesta = await _loteServices.updateLote(
        context,
        token,
        loteActualizado,
        ordenesIds,
      );

      if (_loteServices.statusCode == 1) {
        // Actualizar el lote local con la respuesta del servidor
        widget.loteSeleccionado = loteActualizadoRespuesta;
        print('Datos del lote guardados exitosamente');
      } else {
        throw Exception('Error al guardar datos del lote');
      }
    } catch (e) {
      print('Error guardando datos del lote: $e');
      rethrow;
    }
  }
  
  int _obtenerOrdinalDesdeReferencia(String referencia) {
    final partes = referencia.split('_');
    if (partes.length >= 2) {
      return int.tryParse(partes[1]) ?? 1;
    }
    return 1;
  }
  
  // ============================================
  // GUARDADO MANUAL (método original modificado)
  // ============================================
  
  Future<void> _guardarCambios() async {
    if (!_hayCambiosSinGuardar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
      return;
    }

    setState(() => _cargando = true);
    
    try {
      await _procesarCambiosPendientes();
      
      setState(() {
        _hayCambiosSinGuardar = false;
        _cargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // ============================================
  // MODIFICADO: MÉTODOS PARA FILAS 25 Y 26 POR AGRUPADOR
  // ============================================
  
  // MODIFICADO: Calcular valores de las filas 25 y 26 POR AGRUPADOR
  Map<String, Map<String, double>> _calcularFilasMultiplicacion() {
    final resultados = <String, Map<String, double>>{
      'fila_25': {},
      'fila_26': {}
    };
    
    // 1. Agrupar porcentajes por agrupador
    final Map<String, Map<String, double>> porcentajesPorAgrupador = {};
    final porcentajesIndividuales = _tablaConsumo.calcularPorcentajes();
    
    // Agrupar porcentajes por agrupador
    for (var fila in _tablaConsumo.filas) {
      final codigo = fila.codigo;
      final agrupador = agrupadorControllers[codigo]?.text.trim() ?? 'Sin agrupar';
      final porcentajesFila = porcentajesIndividuales[codigo] ?? {};
      
      if (!porcentajesPorAgrupador.containsKey(agrupador)) {
        porcentajesPorAgrupador[agrupador] = {};
      }
      
      // Sumar porcentajes de este material al agrupador
      for (var entry in porcentajesFila.entries) {
        final columna = entry.key;
        final valor = entry.value;
        
        porcentajesPorAgrupador[agrupador]![columna] = 
            (porcentajesPorAgrupador[agrupador]![columna] ?? 0.0) + valor;
      }
    }
    
    // 2. Para cada columna (ANT1-4 y órdenes)
    // Determinar todas las columnas posibles
    final todasColumnas = <String>{};
    for (var agrupador in porcentajesPorAgrupador.keys) {
      todasColumnas.addAll(porcentajesPorAgrupador[agrupador]!.keys);
    }
    
    for (var columna in todasColumnas) {
      double sumaPorcentajesSeleccionados = 0.0;
      
      // Sumar porcentajes de agrupadores seleccionados
      for (var entry in porcentajesPorAgrupador.entries) {
        final agrupador = entry.key;
        final porcentajesAgrupador = entry.value;
        
        if (agrupadoresSeleccionados[agrupador] == true) {
          sumaPorcentajesSeleccionados += porcentajesAgrupador[columna] ?? 0.0;
        }
      }
      
      // Aplicar multiplicadores (divididos entre 100)
      resultados['fila_25']![columna] = sumaPorcentajesSeleccionados * (_multiplicadorFila25 / 100);
      resultados['fila_26']![columna] = sumaPorcentajesSeleccionados * (_multiplicadorFila26 / 100);
    }
    
    return resultados;
  }
  
  // MODIFICADO: Seleccionar/deseleccionar todos los AGRUPADORES
  void _toggleTodosMateriales(bool seleccionar) {
    setState(() {
      for (var key in agrupadoresSeleccionados.keys) {
        agrupadoresSeleccionados[key] = seleccionar;
      }
    });
  }
  
  // NUEVO: Actualizar selección de agrupador
  void _actualizarSeleccionAgrupador(String agrupador, bool seleccionado) {
    setState(() {
      agrupadoresSeleccionados[agrupador] = seleccionado;
    });
  }
  
  // MODIFICADO: Actualizar multiplicadores
  void _actualizarMultiplicadorFila25(String valor) {
    final nuevoValor = double.tryParse(valor) ?? 0.0;
    if (_multiplicadorFila25 != nuevoValor) {
      setState(() {
        _multiplicadorFila25 = nuevoValor;
      });
    }
  }
  
  void _actualizarMultiplicadorFila26(String valor) {
    final nuevoValor = double.tryParse(valor) ?? 0.0;
    if (_multiplicadorFila26 != nuevoValor) {
      setState(() {
        _multiplicadorFila26 = nuevoValor;
      });
    }
  }
  
  // ============================================
  // NUEVO: MÉTODO PARA MARCAR CAMBIOS EN LOTE
  // ============================================
  
  void _marcarCambiosLote() {
    if (!_hayCambiosSinGuardar) {
      setState(() {
        _hayCambiosSinGuardar = true;
      });
    }
  }

  // ============================================
  // NUEVO: MÉTODO PARA MARCAR CAMBIOS EN AGRUPADOR
  // ============================================
  
  void _marcarCambiosAgrupador(String codigoMaterial, String nuevoAgrupador) {
    if (!_hayCambiosSinGuardar) {
      setState(() {
        _hayCambiosSinGuardar = true;
      });
    }
    
    // Ejecutar según modo de guardado
    _ejecutarSegunModoGuardado();
  }
  
  // ============================================
  // MODIFICADO: WIDGET PARA CONTROLES DE MULTIPLICACIÓN POR AGRUPADOR
  // ============================================
  
  Widget _buildControlesMultiplicacion() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MULTIPLICACIÓN DE PORCENTAJES POR AGRUPADOR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seleccione los AGRUPADORES y defina los valores para las filas de cálculo:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                // Checkbox para seleccionar todos los AGRUPADORES
                Row(
                  children: [
                    Checkbox(
                      value: agrupadoresSeleccionados.isNotEmpty && 
                             agrupadoresSeleccionados.values.every((value) => value),
                      onChanged: (value) => _toggleTodosMateriales(value ?? false),
                      tristate: true,
                    ),
                    const Text('Seleccionar todos los agrupadores'),
                  ],
                ),
                const SizedBox(width: 32),
                
                // Campo para Fila 25
                SizedBox(
                  width: 120,
                  child: Expanded(
                    child: TextField(
                      controller: _controllerMulti25,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor Fila 25',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onChanged: _actualizarMultiplicadorFila25,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Campo para Fila 26
                SizedBox(
                  width: 120,
                  child: Expanded(
                    child: TextField(
                      controller: _controllerMulti26,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor Fila 26',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onChanged: _actualizarMultiplicadorFila26,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text(
              'Nota: Los valores se dividirán entre 100 antes de multiplicar. Ejemplo: 69 se convertirá en 0.69',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
  
  // ============================================
  // MODIFICADO: TABLA DE PORCENTAJES POR AGRUPADOR CON CHECKBOXES Y FILAS 25, 26
  // ============================================
  
  Widget _buildTablaPorcentajes() {
    if (_cargandoMateriales) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_tablaConsumo.filas.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar'));
    }

    // 1. Agrupar materiales por agrupador y calcular sumas
    final Map<String, Map<String, double>> porcentajesPorAgrupador = {};
    final Map<String, double> totalesPorAgrupador = {};
    
    // Obtener porcentajes individuales primero
    final porcentajesIndividuales = _tablaConsumo.calcularPorcentajes();
    
    // Agrupar por agrupador
    for (var fila in _tablaConsumo.filas) {
      final codigo = fila.codigo;
      final agrupador = agrupadorControllers[codigo]?.text.trim() ?? 'Sin agrupar';
      
      // Inicializar mapa para este agrupador si no existe
      if (!porcentajesPorAgrupador.containsKey(agrupador)) {
        porcentajesPorAgrupador[agrupador] = {};
        totalesPorAgrupador[agrupador] = 0.0;
      }
      
      // Sumar porcentajes de cada columna
      final porcentajesFila = porcentajesIndividuales[codigo] ?? {};
      
      for (var entry in porcentajesFila.entries) {
        final columna = entry.key;
        final valor = entry.value;
        
        porcentajesPorAgrupador[agrupador]![columna] = 
            (porcentajesPorAgrupador[agrupador]![columna] ?? 0.0) + valor;
        
        // Sumar al total del agrupador
        totalesPorAgrupador[agrupador] = totalesPorAgrupador[agrupador]! + valor;
      }
    }
    
    final ordenesParaMostrar = _ordenesSeleccionadas;
    final filasMultiplicacion = _calcularFilasMultiplicacion();

    return Column(
      children: [        
        // Tabla de porcentajes por agrupador
        Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PORCENTAJES DE DISTRIBUCIÓN POR AGRUPADOR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Porcentaje que representa cada agrupador en el total de cada columna',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final int numOrdenes = ordenesParaMostrar.length;
                    final double anchoMinimoRequerido = 60 + 100 + (4 * 70) + (numOrdenes * 100) + 20;
                    
                    // Calcular total de filas: agrupadores + filas 25/26 + filas control calidad
                    int totalFilas = porcentajesPorAgrupador.length;
                    if (_multiplicadorFila25 > 0) totalFilas += 1;
                    if (_multiplicadorFila26 > 0) totalFilas += 1;
                    totalFilas += 2; // ccVisc y ccNvporc
                    
                    final double alturaTotal = totalFilas * 50 + 60;
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                          minHeight: alturaTotal,
                        ),
                        child: SizedBox(
                          width: anchoMinimoRequerido > constraints.maxWidth 
                              ? anchoMinimoRequerido 
                              : constraints.maxWidth,
                          child: DataTable(
                            columnSpacing: 8,
                            horizontalMargin: 8,
                            dataRowHeight: 50,
                            headingRowHeight: 60,
                            columns: _buildColumnasPorcentajesPorAgrupador(),
                            rows: _buildFilasPorcentajesPorAgrupador(
                              porcentajesPorAgrupador,
                              filasMultiplicacion,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Controles de multiplicación
        _buildControlesMultiplicacion(),
      ],
    );
  }

  List<DataColumn> _buildColumnasPorcentajesPorAgrupador() {
    const double widthCheckbox = 60;
    const double widthAgrupador = 100;
    const double widthAnt = 70;
    const double widthOrden = 100;

    return [
      const DataColumn(
        label: SizedBox(
          width: widthCheckbox,
          child: Center(
            child: Text(
              'Seleccionar', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      const DataColumn(
        label: SizedBox( 
          width: widthAgrupador,
          child: Center(
            child: Text(
              'Agrupador', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
      for (int i = 1; i <= 4; i++)
        DataColumn(
          label: SizedBox( 
            width: widthAnt,
            child: Center(
              child: Text(
                'ANT$i %', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      for (var orden in _ordenesSeleccionadas)
        DataColumn(
          label: SizedBox( 
            width: widthOrden,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    orden.numeroOrdenTrabajo ?? 'OT${orden.ordenTrabajoId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    '%',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<DataRow> _buildFilasPorcentajesPorAgrupador(
    Map<String, Map<String, double>> porcentajesPorAgrupador,
    Map<String, Map<String, double>> filasMultiplicacion
  ) {
    final List<DataRow> filas = [];
    
    // Ordenar agrupadores alfabéticamente
    final agrupadoresOrdenados = porcentajesPorAgrupador.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    // Filas de agrupadores
    for (var agrupador in agrupadoresOrdenados) {
      final porcentajesAgrupador = porcentajesPorAgrupador[agrupador] ?? {};
      
      final celdas = <DataCell>[
        // Checkbox para seleccionar AGRUPADOR
        DataCell(
          Center(
            child: Checkbox(
              value: agrupadoresSeleccionados[agrupador] ?? false,
              onChanged: (value) {
                _actualizarSeleccionAgrupador(agrupador, value ?? false);
              },
            ),
          ),
        ),
        
        // Celda de Agrupador
        DataCell(
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                agrupador,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        
        // Porcentajes ANT1-4
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 70,
              child: Center(
                child: _buildCeldaPorcentajeAgrupador(
                  porcentajesAgrupador['ant_$i'] ?? 0.0,
                ),
              ),
            ),
          ),

        // Porcentajes por orden
        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 100,
              child: Center(
                child: _buildCeldaPorcentajeAgrupador(
                  porcentajesAgrupador[orden.ordenTrabajoId.toString()] ?? 0.0,
                ),
              ),
            ),
          ),
      ];

      filas.add(DataRow(cells: celdas));
    }
    
    // Fila 25 (calculada)
    if (_multiplicadorFila25 > 0) {
      final celdasFila25 = <DataCell>[
        const DataCell(SizedBox.shrink()), // Sin checkbox
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Multiplicado por ${_multiplicadorFila25.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue),
            ),
          ),
        ),
        
        // Valores calculados para ANT1-4
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 70,
              child: Center(
                child: _buildCeldaPorcentajeCalculado(
                  filasMultiplicacion['fila_25']?['ant_$i'] ?? 0.0,
                  _multiplicadorFila25
                ),
              ),
            ),
          ),

        // Valores calculados para órdenes
        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 100,
              child: Center(
                child: _buildCeldaPorcentajeCalculado(
                  filasMultiplicacion['fila_25']?[orden.ordenTrabajoId.toString()] ?? 0.0,
                  _multiplicadorFila25
                ),
              ),
            ),
          ),
      ];

      filas.add(DataRow(
        cells: celdasFila25,
        color: MaterialStateProperty.resolveWith<Color?>(
          (states) => Colors.blue[50]
        ),
      ));
    }
    
    // Fila 26 (calculada)
    if (_multiplicadorFila26 > 0) {
      final celdasFila26 = <DataCell>[
        const DataCell(SizedBox.shrink()), // Sin checkbox
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Multiplicado por ${_multiplicadorFila26.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green),
            ),
          ),
        ),
        
        // Valores calculados para ANT1-4
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 70,
              child: Center(
                child: _buildCeldaPorcentajeCalculado(
                  filasMultiplicacion['fila_26']?['ant_$i'] ?? 0.0,
                  _multiplicadorFila26
                ),
              ),
            ),
          ),

        // Valores calculados para órdenes
        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 100,
              child: Center(
                child: _buildCeldaPorcentajeCalculado(
                  filasMultiplicacion['fila_26']?[orden.ordenTrabajoId.toString()] ?? 0.0,
                  _multiplicadorFila26
                ),
              ),
            ),
          ),
      ];

      filas.add(DataRow(
        cells: celdasFila26,
        color: MaterialStateProperty.resolveWith<Color?>(
          (states) => Colors.green[50]
        ),
      ));
    }
    
    // ============================================
    // FILAS DE CONTROL CALIDAD (se mantienen)
    // ============================================
    
    // Fila para ccVisc
    final celdasCcVisc = <DataCell>[
      const DataCell(SizedBox.shrink()), // Sin checkbox
      const DataCell(
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Viscosidad Control Calidad',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.purple),
          ),
        ),
      ),
      
      // Para ANT1-4 (no aplica)
      for (int i = 1; i <= 4; i++)
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ),

      // Para cada orden - mostrar el valor de ccVisc
      for (var orden in _ordenesSeleccionadas)
        DataCell(
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                orden.ccVisc ?? '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
          ),
        ),
    ];

    filas.add(DataRow(
      cells: celdasCcVisc,
      color: MaterialStateProperty.resolveWith<Color?>(
        (states) => Colors.purple[50]
      ),
    ));
    
    // Fila para ccNvporc
    final celdasCcNvporc = <DataCell>[
      const DataCell(SizedBox.shrink()), // Sin checkbox
      const DataCell(
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'NV% Control Calidad',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange),
          ),
        ),
      ),
      
      // Para ANT1-4 (no aplica)
      for (int i = 1; i <= 4; i++)
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ),

      // Para cada orden - mostrar el valor de ccNvporc
      for (var orden in _ordenesSeleccionadas)
        DataCell(
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                orden.ccNvporc ?? '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ),
    ];

    filas.add(DataRow(
      cells: celdasCcNvporc,
      color: MaterialStateProperty.resolveWith<Color?>(
        (states) => Colors.orange[50]
      ),
    ));
    
    return filas;
  }

  Widget _buildCeldaPorcentajeAgrupador(double porcentaje) {
    // Determinar color según el porcentaje
    Color color;
    if (porcentaje == 0) {
      color = Colors.grey;
    } else if (porcentaje < 10) {
      color = Colors.blueGrey;
    } else if (porcentaje < 30) {
      color = Colors.blue;
    } else if (porcentaje < 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Tooltip(
      message: '${porcentaje.toStringAsFixed(1)}% del total de la columna',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${porcentaje.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // ============================================
  // MÉTODO _buildCeldaPorcentajeCalculado
  // ============================================
  
  Widget _buildCeldaPorcentajeCalculado(double valor, double multiplicador) {
    final valorReal = valor; // Ya viene multiplicado por (multiplicador/100)
    
    return Tooltip(
      message: '${valorReal.toStringAsFixed(1)}%\n'
              '(Multiplicador: ${multiplicador.toStringAsFixed(0)}%)',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${valorReal.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple, // Color distintivo para filas calculadas
            ),
          ),
          Text(
            '(${multiplicador.toStringAsFixed(0)}%)',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================
  
  // ignore: unused_element
  void _seleccionarTodasOrdenes() {
    setState(() {
      _ordenesSeleccionadas = List.from(_ordenes);
    });
    _cargarMateriales();
  }

  // ignore: unused_element
  void _deseleccionarTodasOrdenes() {
    setState(() {
      _ordenesSeleccionadas.clear();
      _tablaConsumo = TablaConsumoExcel();
      controllers.clear();
      agrupadorControllers.clear();
      lineasOriginalesMap.clear();
      lineasActuales.clear();
      _lineasLote.clear();
      lineasLoteMap.clear();
      _hayCambiosSinGuardar = false;
      cambiosPendientesLote.clear();
      cambiosPendientesOrden.clear();
      materialesSeleccionados.clear(); // Limpiar selección
      agrupadoresSeleccionados.clear(); // Limpiar selección de agrupadores
      _controllerMulti25.text = '0';
      _controllerMulti26.text = '0';
      _multiplicadorFila25 = 0.0;
      _multiplicadorFila26 = 0.0;
    });
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    
    final meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    
    return '${fecha.day}-${meses[fecha.month - 1]}-${fecha.year.toString().substring(2)}';
  }
  
  void _onReorderOrdenes(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Orden item = _ordenesSeleccionadas.removeAt(oldIndex);
      _ordenesSeleccionadas.insert(newIndex, item);
    });
    _cargarMateriales();
  }
  
  void _cambiarModoGuardado(GuardadoModo nuevoModo) {
    setState(() {
      _modoGuardado = nuevoModo;
    });
    
    // Si se cambia a automático y hay cambios pendientes, guardar inmediatamente
    if (nuevoModo == GuardadoModo.AUTOMATICO && _hayCambiosSinGuardar) {
      _guardarCambiosAutomaticamente();
    }
    
    // Mostrar mensaje informativo
    final mensajes = {
      GuardadoModo.MANUAL: 'Modo Manual: Debes hacer clic en Guardar para persistir cambios',
      GuardadoModo.DEBOUNCE: 'Modo Auto-guardado (3s): Los cambios se guardarán automáticamente',
      GuardadoModo.AUTOMATICO: 'Modo Automático: Los cambios se guardan inmediatamente',
    };
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensajes[nuevoModo]!),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('CONSUMOS - Lote ${widget.loteSeleccionado?.lote ?? "Sin lote"}'),
            if (_hayCambiosSinGuardar)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Cambios sin guardar',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            if (_cargandoLote)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_cargandoLineasLote)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_guardandoAuto)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ),
          ]
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Selector de modo de guardado
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<GuardadoModo>(
                value: _modoGuardado,
                dropdownColor: Colors.blue[800],
                icon: const Icon(Icons.settings, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (modo) => _cambiarModoGuardado(modo!),
                items: [
                  DropdownMenuItem(
                    value: GuardadoModo.MANUAL,
                    child: Row(
                      children: [
                        const Icon(Icons.save, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text('Manual'),
                        if (_modoGuardado == GuardadoModo.MANUAL)
                          const Icon(Icons.check, size: 12, color: Colors.green),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: GuardadoModo.DEBOUNCE,
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text('Auto (3s)'),
                        if (_modoGuardado == GuardadoModo.DEBOUNCE)
                          const Icon(Icons.check, size: 12, color: Colors.green),
                      ],
                    ),
                  ),
                  // DropdownMenuItem(
                  //   value: GuardadoModo.AUTOMATICO,
                  //   child: Row(
                  //     children: [
                  //       const Icon(Icons.autorenew, size: 16, color: Colors.white),
                  //       const SizedBox(width: 4),
                  //       const Text('Automático'),
                  //       if (_modoGuardado == GuardadoModo.AUTOMATICO)
                  //         const Icon(Icons.check, size: 12, color: Colors.green),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          
          // Botón de guardado manual
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.save),
                if (_hayCambiosSinGuardar)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _cargando ? null : _guardarCambios,
            tooltip: 'Guardar cambios manualmente',
          ),
          
          // // Botones de selección
          // IconButton(
          //   icon: const Icon(Icons.select_all),
          //   onPressed: _seleccionarTodasOrdenes,
          //   tooltip: 'Seleccionar todas',
          // ),
          // IconButton(
          //   icon: const Icon(Icons.deselect),
          //   onPressed: _deseleccionarTodasOrdenes,
          //   tooltip: 'Deseleccionar todas',
          // ),
        ]
      ),
      // Reemplaza el widget Stack actual en el build() con esta versión:
body: Stack(
  children: [
    Column(
      children: [
        // Widget de información del lote fijo
        if (widget.loteSeleccionado != null) 
          _buildInfoLote(),
        
        // Contenido desplazable
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Indicador de modo de guardado
                if (_hayCambiosSinGuardar) _buildIndicadorModoGuardado(),
                
                // Ordenes del lote (reordenables)
                if (widget.loteSeleccionado != null) _buildOrdenesLoteReorderable(),
                
                // Selector de órdenes (solo si no hay lote)
                if (widget.loteSeleccionado == null) _buildSelectorOrdenes(),
                
                // Tabla de consumos
                _buildTablaExcelDinamicaExpandida(),
                
                // Tabla de porcentajes con checkboxes y filas 25, 26
                _buildTablaPorcentajes(),
                
                _envasadoProduccion(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    ),
    
    // Overlay de carga
    if (_cargando)
      Container(
        color: Colors.black54,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
  ],
),
    );
  }

  Widget _buildIndicadorModoGuardado() {
    Color color;
    String texto;
    IconData icono;
    
    switch (_modoGuardado) {
      case GuardadoModo.MANUAL:
        color = Colors.orange;
        texto = 'Cambios pendientes - Guardado Manual';
        icono = Icons.save;
        break;
      case GuardadoModo.DEBOUNCE:
        color = Colors.blue;
        texto = 'Auto-guardando en ${_debounceDuration.inSeconds}s...';
        icono = Icons.timer;
        break;
      case GuardadoModo.AUTOMATICO:
        color = Colors.green;
        texto = 'Guardando automáticamente...';
        icono = Icons.autorenew;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenesLoteReorderable() {
    if (_ordenesSeleccionadas.isEmpty) {
      return Container();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reordenar Órdenes del Lote (Arrastra para cambiar orden de columnas):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 70,
              alignment: Alignment.centerLeft,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _ordenesSeleccionadas.length,
                onReorder: _onReorderOrdenes,
                itemBuilder: (context, index) {
                  final orden = _ordenesSeleccionadas[index];
                  return Tooltip(
                    key: ValueKey(orden.ordenTrabajoId),
                    message: 'Arrastra para reordenar columna: ${orden.numeroOrdenTrabajo}',
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'OT: ${orden.numeroOrdenTrabajo}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: Al reordenar las órdenes, se cambiará el orden de las columnas en la tabla de consumos.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLote() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INFORMACIÓN DEL LOTE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.tag, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Lote: ${widget.loteSeleccionado!.lote}'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.loteSeleccionado!.estaAbierto ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.loteSeleccionado!.estado ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Fecha: ${widget.loteSeleccionado!.fechaLoteFormatted ?? "N/A"}'),
                const Spacer(),
                const Icon(Icons.inventory, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Embarcar: ${widget.loteSeleccionado!.totalEmbarcar ?? 0} kg'),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.loteSeleccionado!.observaciones?.isNotEmpty ?? false)
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Obs: ${widget.loteSeleccionado!.observaciones}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.list_alt, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Órdenes asociadas: ${_ordenesSeleccionadas.length}'),
              ],
            ),
            const SizedBox(height: 4,),
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.percent, size: 16, color: Colors.black,),
                      const SizedBox(width: 8),
                      Text('Nv ${widget.loteSeleccionado?.nvporc}',style: const TextStyle(fontWeight: FontWeight.bold),)
                    ]
                  ),
                  const SizedBox(height: 4,),
                  Text('Viscosidad: ${widget.loteSeleccionado?.visc ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold),)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorOrdenes() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Órdenes (Arrastra para reordenar columnas):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : DropdownSearch<Orden>.multiSelection(
                    items: _ordenes,
                    compareFn: (item1, item2) => item1.ordenTrabajoId == item2.ordenTrabajoId,
                    selectedItems: _ordenesSeleccionadas, 
                    onChanged: (List<Orden> nuevasSeleccionadas) {
                      setState(() {
                        final Map<int?, Orden> nuevaMap = {for (var o in nuevasSeleccionadas) o.ordenTrabajoId: o};
                        final List<Orden> mantenidas = _ordenesSeleccionadas.where((o) => nuevaMap.containsKey(o.ordenTrabajoId)).toList();
                        final Set<int?> mantenidasIds = mantenidas.map((o) => o.ordenTrabajoId).toSet();
                        final List<Orden> nuevasAniadidas = nuevasSeleccionadas.where((o) => !mantenidasIds.contains(o.ordenTrabajoId)).toList();
                        _ordenesSeleccionadas = [...mantenidas, ...nuevasAniadidas];
                      });
                      _cargarMateriales();
                    },
                    dropdownBuilder: (context, selectedItems) {
                      if (_ordenesSeleccionadas.isEmpty) {
                        return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '0 órdenes seleccionadas',
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                      }
                      
                      return Container(
                          height: 60,
                          alignment: Alignment.centerLeft,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _ordenesSeleccionadas.length, 
                            onReorder: _onReorderOrdenes,
                            itemBuilder: (context, index) {
                              final orden = _ordenesSeleccionadas[index];
                              return Tooltip(
                                key: ValueKey(orden.ordenTrabajoId), 
                                message: 'Arrastra para reordenar columna: ${orden.numeroOrdenTrabajo}',
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  color: Colors.blue[50],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Center(
                                      child: Text(
                                        'OT: ${orden.numeroOrdenTrabajo}',
                                        style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                    },
                    popupProps: PopupPropsMultiSelection.menu(
                      showSearchBox: true,
                      showSelectedItems: true,
                      searchFieldProps: const TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Buscar órdenes...",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      itemBuilder: (context, item, isSelected) {
                        return ListTile(
                          title: Text('${item.numeroOrdenTrabajo}'),
                          subtitle: Text(
                            'Fecha: ${_formatearFecha(item.fechaOrdenTrabajo)}',
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.radio_button_unchecked),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaExcelDinamicaExpandida() {
    if (_cargandoMateriales) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_tablaConsumo.filas.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar'));
    }

    final ordenesParaMostrar = widget.loteSeleccionado != null 
      ? _ordenesSeleccionadas 
      : _ordenesSeleccionadas;

    return Card(
      margin: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int numOrdenes = ordenesParaMostrar.length;
          final double anchoMinimoRequerido = 100 + 80 + 150 + (4 * 60) + (numOrdenes * 90) + 70 + 70 + 150 + 20; 
          
          final int totalFilas = _tablaConsumo.filas.length + 1;
          final double alturaTotal = totalFilas * 50 + 60;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: alturaTotal,
              ),
              child: SizedBox(
                width: anchoMinimoRequerido > constraints.maxWidth 
                    ? anchoMinimoRequerido 
                    : constraints.maxWidth,
                child: DataTable(
                  columnSpacing: 8,
                  horizontalMargin: 8,
                  dataRowHeight: 50,
                  headingRowHeight: 60,
                  columns: _buildColumnasDinamicas(),
                  rows: _buildFilasDinamicas(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<DataColumn> _buildColumnasDinamicas() {
    const double widthAgrupador = 100;
    const double widthAnt = 60;
    const double widthOrden = 90; 
    const double widthTotal = 70;
    const double widthConsumo = 70;

    return [
      // NUEVA COLUMNA: Agrupador
      const DataColumn(
        label: SizedBox( 
          width: widthAgrupador,
          child: Center(
            child: Text(
              'AGRUPADOR', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ),
      const DataColumn(
        label: Center(
          child: Text(
            'Código', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      const DataColumn(
        label: Center(
          child: Text(
            'Artículo', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      for (int i = 1; i <= 4; i++)
        DataColumn(
          label: SizedBox( 
            width: widthAnt,
            child: Center(
              child: Text(
                'ANT$i', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      for (var orden in _ordenesSeleccionadas)
        DataColumn(
          label: SizedBox( 
            width: widthOrden,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    orden.numeroOrdenTrabajo ?? 'OT${orden.ordenTrabajoId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatearFecha(orden.fechaOrdenTrabajo),
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      const DataColumn(
        label: SizedBox( 
          width: widthTotal,
          child: Center(
            child: Text(
              'TOTAL', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      const DataColumn(
        label: SizedBox( 
          width: widthConsumo,
          child: Center(
            child: Text(
              'CONSUMO', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
      const DataColumn(
        label: Center(
          child: Text(
            'DESCRIPCIÓN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildFilasDinamicas() {
    final List<DataRow> filas = [];

    for (var fila in _tablaConsumo.filas) {
      final celdas = <DataCell>[
        // NUEVA CELDA: Agrupador (editable)
        DataCell(
          SizedBox(
            width: 100, // Ancho igual al definido en la columna
            child: Center(
              child: TextField(
                controller: agrupadorControllers[fila.codigo],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  hintText: '',
                ),
                onChanged: (value) {
                  // Marcar que hay cambios en el agrupador
                  _marcarCambiosAgrupador(fila.codigo, value);
                },
              ),
            ),
          ),
        ),
        DataCell(Align(alignment: Alignment.centerLeft, child: Text(fila.codigo, style: const TextStyle(fontSize: 16)))),
        DataCell(Align(alignment: Alignment.centerLeft, child: Tooltip(message: fila.articulo, child: SizedBox(width: 150, child: Text(fila.articulo, style: const TextStyle(fontSize: 16), overflow: TextOverflow.visible))))),
        
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 60,
              child: Center(
                child: TextField(
                  controller: controllers[fila.codigo]?['ant_$i'],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onChanged: (value) {
                    _actualizarValorDesdeController(fila.codigo, 'ant_$i');
                  },
                ),
              ),
            ),
          ),

        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 90,
              child: Center(
                child: TextField(
                  controller: controllers[fila.codigo]?[orden.ordenTrabajoId.toString()],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onChanged: (value) {
                    _actualizarValorDesdeController(fila.codigo, orden.ordenTrabajoId.toString());
                  },
                ),
              ),
            ),
          ),

        DataCell(
          SizedBox(
            width: 70, 
            child: Center(
              child: Text(fila.totalFila.toStringAsFixed(0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                fila.consumoCalculado.toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
        ),

        DataCell(Align(alignment: Alignment.centerLeft, child: Tooltip(message: fila.descripcionS, child: SizedBox(width: 150, child: Text(fila.descripcionS, style: const TextStyle(fontSize: 16), overflow: TextOverflow.visible))))),
      ];

      filas.add(DataRow(cells: celdas));
    }
    
    if (_tablaConsumo.filas.isNotEmpty) {
        double totalAntGeneral = 0.0;
      for (int i = 1; i <= 4; i++) {
        totalAntGeneral += (_tablaConsumo.totalesColumnas['ant_$i'] ?? 0.0);
      }
      
      final celdasTotales = <DataCell>[
        const DataCell(SizedBox.shrink()), // Sin agrupador
        const DataCell(Align(alignment: Alignment.centerLeft, child: Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        const DataCell(SizedBox.shrink()),
        
        for (int i = 1; i <= 4; i++)
          DataCell(
            SizedBox(
              width: 60,
              child: Center(
                child: Text(
                  (_tablaConsumo.totalesColumnas['ant_$i'] ?? 0.0).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        for (var orden in _ordenesSeleccionadas)
          DataCell(
            SizedBox(
              width: 90,
              child: Center(
                child: Text(
                  (_tablaConsumo.totalesColumnas[orden.ordenTrabajoId.toString()] ?? 0.0).toStringAsFixed(0),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                (_tablaConsumo.totalesColumnas['total'] ?? 0.0).toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                _tablaConsumo.totalConsumoGeneral.toStringAsFixed(0),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          ),
        ),

        const DataCell(SizedBox.shrink()),
      ];

      filas.add(DataRow(cells: celdasTotales, color: MaterialStateProperty.resolveWith<Color?>((states) => Colors.grey[200])));
    }
    
    return filas;
  }

  Widget _envasadoProduccion() {
    // Calcular valores en función de los controladores
    int cantidadTambores = int.tryParse(_cantTamboresController.text) ?? 0;
    int kgPorTambor = int.tryParse(_kgTamborController.text) ?? 0;
    int picoProduccion = int.tryParse(_picoProduccionController.text) ?? 0;
    int cantPallets = int.tryParse(_cantPalletsController.text) ?? 0;
    int totalEmbarcar = int.tryParse(_totalEmbarcarController.text) ?? 0;
    
    // Obtener valores de picos
    int picoCantidad1 = int.tryParse(_picoCantidad1Controller.text) ?? 0;
    int picoTotal1 = int.tryParse(_picoTotal1Controller.text) ?? 0;
    int picoCantidad2 = int.tryParse(_picoCantidad2Controller.text) ?? 0;
    int picoKg2 = int.tryParse(_picoKg2Controller.text) ?? kgPorTambor;
    
    // Calcular valores
    int totalExportacion = cantidadTambores * kgPorTambor;
    int totalEnvasadoCalculado = totalExportacion + picoTotal1 + picoProduccion;
    int mermaProceso = totalEmbarcar - totalEnvasadoCalculado;
    double porcentajeMerma = totalEnvasadoCalculado > 0 
        ? (mermaProceso / totalEnvasadoCalculado) * 100 
        : 0.0;
    
    // Calcular suma total de materiales (totalFila de cada material)
    double sumaTotalMateriales = _tablaConsumo.filas.fold(
      0.0, 
      (sum, fila) => sum + fila.totalFila
    );
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENVASADO PRODUCCIÓN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const SizedBox(height: 16),
            
            // Tabla de envasado producción
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FixedColumnWidth(200),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(60),
                3: FixedColumnWidth(100),
              },
              children: [
                // Encabezados - NO EDITABLES (son texto)
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'cantidad',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Kg',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'TOTAL (Kg)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Fila EXPORTACION
                TableRow(
                  children: [
                    // Celda de texto - NO EDITABLE
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'EXPORTACION',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Celda cantidad - EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _cantTamboresController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            // Recalcular cuando cambia
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    // Celda kg - EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _kgTamborController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            // Recalcular cuando cambia
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    // Celda total - NO EDITABLE (calculada)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: TextEditingController(text: totalExportacion.toString()),
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Primera fila Pico de producción
                TableRow(
                  children: [
                    // Celda de texto - NO EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Pico de producción',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    // Celda cantidad - EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _picoCantidad1Controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            hintText: '0',
                          ),
                          onChanged: (value) {
                            // Recalcular total
                            int cant = int.tryParse(value) ?? 0;
                            int kg = int.tryParse(_kgTamborController.text) ?? 0;
                            _picoTotal1Controller.text = (cant * kg).toString();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    // Celda kg - EDITABLE (mismo que exportación)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: TextEditingController(text: kgPorTambor.toString()),
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                    ),
                    // Celda total - EDITABLE (calculada)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _picoTotal1Controller,
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Segunda fila Pico de producción
                TableRow(
                  children: [
                    // Celda de texto - NO EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Pico de producción',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    // Celda cantidad - EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _picoCantidad2Controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            hintText: '0',
                          ),
                          onChanged: (value) {
                            // Recalcular total
                            int cant = int.tryParse(value) ?? 0;
                            int kg = int.tryParse(_picoKg2Controller.text) ?? kgPorTambor;
                            _picoTotal2Controller.text = (cant * kg).toString();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    // Celda kg - EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _picoKg2Controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            // Recalcular total
                            int cant = int.tryParse(_picoCantidad2Controller.text) ?? 0;
                            int kg = int.tryParse(value) ?? 0;
                            _picoTotal2Controller.text = (cant * kg).toString();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    // Celda total - EDITABLE (calculada)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: _picoTotal2Controller,
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Fila TOTAL ENVASADO
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[50]),
                  children: [
                    // Celda de texto - NO EDITABLE
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'TOTAL ENVASADO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Celda total - NO EDITABLE (calculada automáticamente)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: TextEditingController(text: totalEnvasadoCalculado.toString()),
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Fila MERMA de PROCESO
                TableRow(
                  children: [
                    // Celda de texto - NO EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'MERMA de PROCESO',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Celda merma - NO EDITABLE (calculada automáticamente)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: TextEditingController(text: mermaProceso.abs().toString()),
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: mermaProceso > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Fila % MERMA
                TableRow(
                  children: [
                    // Celda de texto - NO EDITABLE
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '% MERMA',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Celda porcentaje - NO EDITABLE (calculada automáticamente)
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: TextEditingController(
                            text: porcentajeMerma.toStringAsFixed(2).replaceAll('.', ',')
                          ),
                          enabled: false,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: porcentajeMerma > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Sección de MATERIAL DE ENVASE Exportación
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título - NO EDITABLE
                  Text(
                    'MATERIAL DE ENVASE Exportación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  //TAMBOR TAPA Y ZUNCHO
                  Row(
                    children: [
                      // Etiqueta - NO EDITABLE
                      const SizedBox(
                        width: 200,
                        child: Text(
                          'TAMBOR TAPA Y ZUNCHO',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      // Valor - EDITABLE
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _cantTamboresController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Pallets
                  Row(
                    children: [
                      // Etiqueta - NO EDITABLE
                      const SizedBox(
                        width: 200,
                        child: Text(
                          'Pallets',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      // Valor - EDITABLE
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _cantPalletsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Línea vacía
                  const Row(
                    children: [
                      SizedBox(width: 200),
                      Spacer(),
                      SizedBox(width: 40),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // TOTAL
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        // Etiqueta - NO EDITABLE
                        SizedBox(
                          width: 200,
                          child: Text(
                            'TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Valor - EDITABLE
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _totalEmbarcarController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ============================================
            // NUEVA TABLA: DISTRIBUCIÓN POR MATERIAL
            // ============================================
            const SizedBox(height: 20),
            _buildTablaDistribucionMateriales(
              sumaTotalMateriales: sumaTotalMateriales,
              totalEnvasadoCalculado: totalEnvasadoCalculado.toDouble(),
            ),
          ],
        ),
      ),
    );
  }

  // NUEVO MÉTODO: Tabla de distribución por material
  Widget _buildTablaDistribucionMateriales({
    required double sumaTotalMateriales,
    required double totalEnvasadoCalculado,
  }) {
    // Calcular datos para la tabla
    final datosMateriales = <Map<String, dynamic>>[];
    double sumaPorcentajeConMerma = 0.0;
    double sumaPorcentajeSinMerma = 0.0;

    for (var fila in _tablaConsumo.filas) {
      final totalMaterial = fila.totalFila;
      
      // Porcentaje con merma: totalMaterial / totalEnvasadoCalculado
      final porcentajeConMerma = totalEnvasadoCalculado > 0 
          ? (totalMaterial / totalEnvasadoCalculado) 
          : 0.0;
      
      // Porcentaje sin merma: totalMaterial / sumaTotalMateriales
      final porcentajeSinMerma = sumaTotalMateriales > 0 
          ? (totalMaterial / sumaTotalMateriales) 
          : 0.0;

      sumaPorcentajeConMerma += porcentajeConMerma;
      sumaPorcentajeSinMerma += porcentajeSinMerma;

      datosMateriales.add({
        'codigo': fila.codigo,
        'articulo': fila.articulo,
        'total': totalMaterial,
        'porcentajeConMerma': porcentajeConMerma,
        'porcentajeSinMerma': porcentajeSinMerma,
      });
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DISTRIBUCIÓN POR MATERIAL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Envasado: ${totalEnvasadoCalculado.toStringAsFixed(0)} kg | '              'Total Materiales: ${sumaTotalMateriales.toStringAsFixed(0)} kg',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey[300]!),
                columnWidths: const {
                  0: FixedColumnWidth(200),  // Material
                  1: FixedColumnWidth(80),   // Total
                  2: FixedColumnWidth(100),  // % con merma
                  3: FixedColumnWidth(100),  // % sin merma
                },
                children: [
                  // Encabezados
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Material',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '% con merma',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '% sin merma',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Filas de datos
                  for (var dato in datosMateriales)
                    TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dato['codigo'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  dato['articulo'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              (dato['total'] as double).toStringAsFixed(0),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              (dato['porcentajeConMerma'] as double)
                                  .toStringAsFixed(4)
                                  .replaceAll('.', ','),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              (dato['porcentajeSinMerma'] as double)
                                  .toStringAsFixed(4)
                                  .replaceAll('.', ','),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Fila de totales
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[50]),
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            sumaTotalMateriales.toStringAsFixed(0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            sumaPorcentajeConMerma.toStringAsFixed(4).replaceAll('.', ','),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            sumaPorcentajeSinMerma.toStringAsFixed(4).replaceAll('.', ','),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '% con merma = Total Material / Total Envasado (${totalEnvasadoCalculado.toStringAsFixed(0)}) | '
                    '% sin merma = Total Material / Suma Total Materiales (${sumaTotalMateriales.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}