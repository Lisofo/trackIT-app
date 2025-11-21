import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/reporte.dart';
import 'package:app_tec_sedel/models/tarifa.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/models/tarea.dart';
import 'package:app_tec_sedel/models/material.dart';
import 'package:app_tec_sedel/models/linea.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/linea_services.dart';
import 'package:app_tec_sedel/services/tareas_services.dart';
import 'package:app_tec_sedel/services/materiales_services.dart';
import 'package:app_tec_sedel/services/orden_services.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';

class DetallePiezasScreen extends StatefulWidget {
  // Parámetros para automotora
  final Cliente? cliente;
  final Unidad? vehiculo;
  final DateTime? fecha;
  final bool? condIva;
  final Orden? ordenPrevia;
  
  // Parámetros para resysol (producción química)
  final Map<String, dynamic>? datosProduccion;

  const DetallePiezasScreen({
    super.key,
    // Parámetros automotora
    this.cliente,
    this.vehiculo,
    this.fecha,
    this.condIva,
    this.ordenPrevia,
    // Parámetros resysol
    this.datosProduccion,
  });

  @override
  State<DetallePiezasScreen> createState() => _DetallePiezasScreenState();
}

class _DetallePiezasScreenState extends State<DetallePiezasScreen> {
  // Variables para automotora
  List<Linea> lineas = [];
  List<Tarea> tareas = [];
  List<Tarifa> tarifas = [];
  List<Materiales> materiales = [];
  bool isLoadingTareas = false;
  bool isLoadingMateriales = false;
  int ordinalCounter = 1;
  final LineasServices _lineasServices = LineasServices();
  final ordenServices = OrdenServices();
  late int rptGenId = 0;
  late bool generandoInforme = false;
  late bool informeGeneradoEsS = false;
  late Reporte reporte = Reporte.empty();
  Map<String, bool> _opcionesImpresion = {
    'DC': false,
    'DP': false,
    'DM': false,
    'DR': false,
    'II': false,
    'IO': false,
  };

  // Variables para resysol (producción química)
  List<Linea> productionLines = [];
  List<Materiales> materialesList = [];
  bool isLoadingProductionLines = false;
  bool isLoadingMaterialesResysol = false;

  // Controladores para resysol
  final List<TextEditingController> _cantidadControllers = [];
  final List<TextEditingController> _loteControllers = [];
  final List<TextEditingController> _afControllers = [];
  final List<TextEditingController> _controlControllers = [];
  final List<TextEditingController> _instruccionController = [];

  // Campos de envasado para resysol
  final TextEditingController _tamborCompletoController = TextEditingController();
  final TextEditingController _picoController = TextEditingController();
  final TextEditingController _totalKgController = TextEditingController();
  final TextEditingController _mermaKgController = TextEditingController();
  final TextEditingController _mermaPorcentajeController = TextEditingController();
  final TextEditingController _observacionesEnvasadoController = TextEditingController();

  // Métodos para automotora
  double get _totalChapa {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.chapaMonto ?? 0).toDouble();
    }
    return total;
  }

  double get _totalPintura {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.pinturaMonto ?? 0).toDouble();
    }
    return total;
  }

  double get _totalMecanica {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.mecanicaMonto ?? 0).toDouble();
    }
    return total;
  }

  double get _totalRepuestos {
    double total = 0;
    for (var linea in lineas) {
      total += (linea.repSinIva ?? 0).toDouble();
    } 
    return total;
  }

  double get _totalGeneral {
    return _totalChapa + _totalPintura + _totalMecanica + _totalRepuestos;
  }

  double get _costoRealChapa {
    return _totalChapa * 1.0;
  }

  double get _costoRealPintura {
    return _totalPintura * 1.0;
  }

  double get _costoRealMecanica {
    return _totalMecanica * 1.0;
  }

  @override
  void initState() {
    super.initState();
    final flavor = context.read<AuthProvider>().flavor;
    
    if (flavor == 'automotoraargentina') {
      _cargarTareasYMateriales();
      _cargarLineasExistentes();
      _cargarTarifas();
    } else if (flavor == 'resysol') {
      _cargarMaterialesResysol();
      _cargarProductionLinesExistentes();
    }
  }

  // Métodos para resysol
  void _calculateMermaPercentage() {
    final totalKg = double.tryParse(_totalKgController.text.replaceAll(',', '.')) ?? 0;
    final mermaKg = double.tryParse(_mermaKgController.text.replaceAll(',', '.')) ?? 0;
    
    if (totalKg > 0) {
      final percentage = (mermaKg / totalKg) * 100;
      _mermaPorcentajeController.text = '${percentage.toStringAsFixed(2)}%';
    }
  }

  double get _ingredientsTotal {
    double total = 0;
    for (var controller in _cantidadControllers) {
      final value = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
      total += value;
    }
    return total;
  }

  Future<void> _cargarMaterialesResysol() async {
    setState(() {
      isLoadingMaterialesResysol = true;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final materialesService = MaterialesServices();
      final materialesCargados = await materialesService.getMateriales(context, token);
      setState(() {
        materialesList = materialesCargados;
        isLoadingMaterialesResysol = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMaterialesResysol = false;
      });
      print('Error cargando materiales: $e');
    }
  }

  Future<void> _cargarProductionLinesExistentes() async {
    if (widget.ordenPrevia?.ordenTrabajoId == null || widget.ordenPrevia!.ordenTrabajoId == 0) {
      return;
    }
    
    setState(() {
      isLoadingProductionLines = true;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final lineasExistentes = await _lineasServices.getLineasDeOrden(
        context,
        widget.ordenPrevia!.ordenTrabajoId!,
        token,
      );
      setState(() {
        productionLines = lineasExistentes;
        isLoadingProductionLines = false;
      });
      _initializeProductionControllers();
    } catch (e) {
      setState(() {
        isLoadingProductionLines = false;
      });
      print('Error cargando líneas de producción: $e');
    }
  }

  void _initializeProductionControllers() {
    // Limpiar controladores existentes
    for (var controller in _cantidadControllers) {
      controller.dispose();
    }
    for (var controller in _loteControllers) {
      controller.dispose();
    }
    for (var controller in _afControllers) {
      controller.dispose();
    }
    for (var controller in _controlControllers) {
      controller.dispose();
    }

    _cantidadControllers.clear();
    _loteControllers.clear();
    _afControllers.clear();
    _controlControllers.clear();

    // Inicializar controladores con los datos de las líneas
    for (var linea in productionLines) {
      _cantidadControllers.add(TextEditingController(text: linea.cantidad > 0 ? linea.cantidad.toString() : ''));
      _loteControllers.add(TextEditingController(text: linea.lote));
      _afControllers.add(TextEditingController(text: linea.af! > 0.0 ? linea.af.toString() : ''));
      _controlControllers.add(TextEditingController(text: linea.control));
      _instruccionController.add(TextEditingController(text: linea.comentario));
    }
  }

  void _onMaterialSelected(Materiales? selected, int rowIndex) {
    if (selected == null) {
      // Si se selecciona "Seleccione material", limpiar los datos
      setState(() {
        productionLines[rowIndex].itemId = 0;
        productionLines[rowIndex].codItem = '';
        productionLines[rowIndex].descripcion = '';
        productionLines[rowIndex].mo = '';
      });
      return;
    }

    setState(() {
      productionLines[rowIndex].itemId = selected.materialId; // Asignar materialId
      productionLines[rowIndex].codItem = selected.codMaterial;
      productionLines[rowIndex].descripcion = selected.descripcion;
      productionLines[rowIndex].mo = '';
      productionLines[rowIndex].piezaId = selected.materialId;
      
    });
    // No llamar a _actualizarLineaProduccion aquí - se hará al guardar
  }

  void _addNewIngredient() {
    final nuevaLinea = Linea(
      lineaId: 0, // Indicar que es nueva
      ordenTrabajoId: widget.ordenPrevia?.ordenTrabajoId ?? 0,
      itemId: 0, // Se asignará cuando se seleccione el material
      codItem: '',
      descripcion: '',
      macroFamilia: '',
      familia: '',
      grupoInventario: '',
      ordinal: productionLines.length + 1,
      cantidad: 0.0,
      costoUnitario: 0.0,
      descuento1: 0,
      descuento2: 0,
      descuento3: 0,
      precioVenta: 0.0,
      comentario: '',
      ivaId: 0,
      iva: '',
      valor: 0,
      codGruInv: '',
      gruInvId: 0,
      avance: 0,
      mo: 'MA', // Material
      chapaHs: 0.0,
      chapaMonto: 0.0,
      pinturaMonto: 0.0,
      mecanicaHs: 0.0,
      mecanicaMonto: 0.0,
      repSinIva: 0.0,
      accionId: 0,
      accion: '',
      piezaId: 1,
      pieza: '',
      af: 0.0,
      control: '',
      lote: '',
    );

    setState(() {
      productionLines.add(nuevaLinea);
      _cantidadControllers.add(TextEditingController());
      _loteControllers.add(TextEditingController());
      _afControllers.add(TextEditingController());
      _controlControllers.add(TextEditingController());
      _instruccionController.add(TextEditingController());
    });
  }

  void _addInstructionRow() {
    final nuevaLinea = Linea(
      lineaId: 0, // Indicar que es nueva
      ordenTrabajoId: widget.ordenPrevia?.ordenTrabajoId ?? 0,
      itemId: 1, // Siempre 1 para instrucciones
      codItem: '',
      descripcion: '',
      macroFamilia: '',
      familia: '',
      grupoInventario: '',
      ordinal: productionLines.length + 1,
      cantidad: 0.0,
      costoUnitario: 0.0,
      descuento1: 0,
      descuento2: 0,
      descuento3: 0,
      precioVenta: 0.0,
      comentario: '',
      ivaId: 0,
      iva: '',
      valor: 0,
      codGruInv: '',
      gruInvId: 0,
      avance: 0,
      mo: 'IN', // Instrucción
      chapaHs: 0.0,
      chapaMonto: 0.0,
      pinturaMonto: 0.0,
      mecanicaHs: 0.0,
      mecanicaMonto: 0.0,
      repSinIva: 0.0,
      accionId: 0,
      accion: '',
      piezaId: 0,
      pieza: '',
      af: 0.0,
      lote: '',
      control: '',
    );

    setState(() {
      productionLines.add(nuevaLinea);
      _cantidadControllers.add(TextEditingController());
      _loteControllers.add(TextEditingController());
      _afControllers.add(TextEditingController());
      _controlControllers.add(TextEditingController());
      _instruccionController.add(TextEditingController());
    });
  }

  void _eliminarLineaResysol(int index) async {
    if (productionLines.isEmpty || index < 0 || index >= productionLines.length) return;

    final linea = productionLines[index];
    final bool esLineaExistente = linea.lineaId != 0;

    // Mostrar diálogo de confirmación
    bool? confirmado = await _mostrarDialogoConfirmacionEliminacion(context);
    if (confirmado != true) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token;
      
      // Si es una línea existente, eliminarla del servidor
      if (esLineaExistente) {
        await _lineasServices.eliminarLinea(
          context,
          widget.ordenPrevia!.ordenTrabajoId!,
          linea.lineaId,
          token,
        );
      }

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Remover localmente
      setState(() {
        productionLines.removeAt(index);
        _cantidadControllers.removeAt(index).dispose();
        _loteControllers.removeAt(index).dispose();
        _afControllers.removeAt(index).dispose();
        _controlControllers.removeAt(index).dispose();
        _instruccionController.removeAt(index).dispose();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Línea eliminada correctamente')),
      );

    } catch (e) {
      // Cerrar el diálogo de carga en caso de error
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la línea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _mostrarDialogoConfirmacionEliminacion(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Está seguro de que desea eliminar esta línea?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Métodos para automotora
  Future<void> _cargarTarifas() async {
    try {
      final token = context.read<AuthProvider>().token;
      final tarifasCargadas = await ordenServices.getTarifas(context, token);
      setState(() {
        tarifas = tarifasCargadas;
      });
    } catch (e) {
      print('Error cargando tarifas: $e');
    }
  }

  Future<void> _cargarTareasYMateriales() async {
    final token = context.read<AuthProvider>().token;
    
    setState(() {
      isLoadingTareas = true;
      isLoadingMateriales = true;
    });

    try {
      final tareasService = TareasServices();
      final materialesService = MaterialesServices();
      
      final tareasList = await tareasService.getTareas(context, token);
      final materialesList = await materialesService.getMateriales(context, token);
      
      setState(() {
        tareas = tareasList;
        materiales = materialesList;
        isLoadingTareas = false;
        isLoadingMateriales = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTareas = false;
        isLoadingMateriales = false;
      });
    }
  }

  Future<void> _cargarLineasExistentes() async {
    if (widget.ordenPrevia?.ordenTrabajoId == 0) return;
    
    try {
      final token = context.read<AuthProvider>().token;
      final lineasExistentes = await _lineasServices.getLineasDeOrden(
        context,
        widget.ordenPrevia!.ordenTrabajoId!,
        token,
      );
      
      setState(() {
        lineas = lineasExistentes;
        ordinalCounter = lineas.length + 1;
      });
    } catch (e) {
      print('Error cargando líneas existentes: $e');
    }
  }

  void _actualizarOrdenConLineas() {    
    widget.ordenPrevia!.totalOrdenTrabajo = _totalGeneral;
  }

  Future<void> _editarOrden() async {
    try {
      final token = context.read<AuthProvider>().token;
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      _actualizarOrdenConLineas();
      
      final ordenActualizada = await ordenServices.actualizarOrden(
        context, 
        token, 
        widget.ordenPrevia!
      );
            
      Navigator.of(context).pop();
      
      if (ordenActualizada != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Orden #${ordenActualizada.numeroOrdenTrabajo} actualizada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al completar la orden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _agregarLinea(
    int? accionIdSeleccionado,
    int? piezaIdSeleccionado,
    String? accionDescripcionSeleccionada,
    String? piezaDescripcionSeleccionada,
    TextEditingController chapaHorasController,
    TextEditingController chapaMontoController,
    TextEditingController pinturaController,
    TextEditingController mechHorasController,
    TextEditingController mechMontoController,
    TextEditingController reptoController,
  ) async {
    if (accionIdSeleccionado == null || piezaIdSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una acción y una pieza')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token;
      
      final nuevaLinea = Linea(
        lineaId: 0,
        ordenTrabajoId: widget.ordenPrevia!.ordenTrabajoId!,
        itemId: 3098,
        codItem: '',
        descripcion: '',
        macroFamilia: '',
        familia: '',
        grupoInventario: '',
        ordinal: ordinalCounter++,
        cantidad: 1.0,
        costoUnitario: 0.0,
        descuento1: 0,
        descuento2: 0,
        descuento3: 0,
        precioVenta: 0.0,
        comentario: '',
        ivaId: 0,
        iva: '',
        valor: 0,
        codGruInv: '',
        gruInvId: 0,
        avance: 0,
        mo: '',
        chapaHs: double.tryParse(chapaHorasController.text) ?? 0.0,
        chapaMonto: double.tryParse(chapaMontoController.text) ?? 0.0,
        pinturaMonto: double.tryParse(pinturaController.text) ?? 0.0,
        mecanicaHs: double.tryParse(mechHorasController.text) ?? 0.0,
        mecanicaMonto: double.tryParse(mechMontoController.text) ?? 0.0,
        repSinIva: double.tryParse(reptoController.text) ?? 0.0,
        accionId: accionIdSeleccionado,
        accion: accionDescripcionSeleccionada ?? '',
        piezaId: piezaIdSeleccionado,
        pieza: piezaDescripcionSeleccionada ?? '', 
        af: null,
        control: '',
        lote: ''
      );

      nuevaLinea.accionId = accionIdSeleccionado;
      nuevaLinea.piezaId = piezaIdSeleccionado;

      final lineaCreada = await _lineasServices.crearLinea(
        context,
        widget.ordenPrevia!.ordenTrabajoId!,
        nuevaLinea,
        token,
      );

      Navigator.of(context).pop();

      setState(() {
        lineas.add(lineaCreada);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Línea agregada correctamente')),
      );

    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear la línea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _eliminarLinea(int index) async {
    final lineaAEliminar = lineas[index];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token;
      
      if (lineaAEliminar.lineaId != 0) {
        await _lineasServices.eliminarLinea(
          context,
          widget.ordenPrevia!.ordenTrabajoId!,
          lineaAEliminar.lineaId,
          token,
        );
      }

      Navigator.of(context).pop();

      setState(() {
        lineas.removeAt(index);
        for (int i = 0; i < lineas.length; i++) {
          lineas[i].ordinal = i + 1;
        }
        ordinalCounter = lineas.length + 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Línea eliminada correctamente')),
      );

    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la línea: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            ? 'Detalle de Producción'
            : 'Detalle de Piezas ${widget.ordenPrevia?.numeroOrdenTrabajo}',
          style: TextStyle(color: colors.onPrimary),
        ),
        iconTheme: IconThemeData(color: colors.onPrimary),
        leading: flavor == 'automotoraargentina' ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(widget.ordenPrevia);
          },
        ) : null,
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
          // Header con datos de producción
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'DATOS DE PRODUCCIÓN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.datosProduccion != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildDataChip(Icons.shopping_bag, 'Producto', widget.datosProduccion!['producto'] ?? ''),
                        _buildDataChip(Icons.numbers, 'Número', widget.datosProduccion!['numero'] ?? ''),
                        _buildDataChip(Icons.scale, 'Pedido', '${widget.datosProduccion!['pedido'] ?? ''} kg'),
                        _buildDataChip(Icons.batch_prediction, 'Batches', widget.datosProduccion!['batches'] ?? ''),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Mezcla de componentes
          _buildChemicalProductionCard(),

          const SizedBox(height: 20),

          // Envasado y control final
          _buildChemicalPackagingCard(),

          const SizedBox(height: 24),

          // Botón de guardar
          _buildChemicalActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDataChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChemicalProductionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MEZCLA DE COMPONENTES',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
            ),
            const Divider(color: Colors.orange),
            const SizedBox(height: 10),
            const Text(
              'Agregar bajo agitación mínima',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            
            if (isLoadingProductionLines || isLoadingMaterialesResysol)
              const Center(child: CircularProgressIndicator())
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) => Colors.blue.shade50,
                    ),
                    columns: const [
                      DataColumn(label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Cantidad (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Lote', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Af', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Control', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: productionLines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final linea = entry.value;
                      final isInstruction = linea.piezaId == 0;
                      
                      // Encontrar el material correspondiente en la lista
                      Materiales? materialSeleccionado;
                      if (!isInstruction && linea.itemId != 0) {
                        try {
                          materialSeleccionado = materialesList.firstWhere(
                            (m) => m.materialId == linea.itemId,
                          );
                        } catch (e) {
                          materialSeleccionado = null;
                        }
                      }
                      
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) => 
                            index % 2 == 0 ? Colors.grey.shade50 : null,
                        ),
                        cells: [
                          DataCell(
                            Center(child: Text((index + 1).toString())),
                          ),
                          DataCell(
                            isInstruction 
                              ? const SizedBox.shrink()
                              : Text(linea.codItem),
                          ),
                          DataCell(
                            isInstruction
                              ? TextField(
                                  controller: _instruccionController[index],
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                )
                              : DropdownButton<Materiales>(
                                  value: materialSeleccionado,
                                  hint: const Text('Seleccione material'),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: [
                                    const DropdownMenuItem<Materiales>(
                                      value: null,
                                      child: Text('Seleccione material'),
                                    ),
                                    ...materialesList.map((Materiales material) {
                                      return DropdownMenuItem<Materiales>(
                                        value: material,
                                        child: Text(material.descripcion),
                                      );
                                    }),
                                  ],
                                  onChanged: (Materiales? selected) {
                                    _onMaterialSelected(selected, index);
                                  },
                                ),
                          ),
                          DataCell(
                            TextField(
                              controller: _cantidadControllers[index],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          DataCell(
                            TextField(
                              controller: _loteControllers[index],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: TextField(
                                controller: _afControllers[index],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            TextField(
                              controller: _controlControllers[index],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarLineaResysol(index),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Total kg', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Text(_ingredientsTotal.toStringAsFixed(1), 
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Ingrediente'),
                  onPressed: _addNewIngredient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.notes, size: 18),
                  label: const Text('Agregar Instrucción'),
                  onPressed: _addInstructionRow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalPackagingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ENVASADO Y CONTROL FINAL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
            ),
            const Divider(color: Colors.green),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'FILTRAR - Sacar muestra - MEDIR Y ENVASAR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Tabla de exportación anterior
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(150),
                1: FixedColumnWidth(150),
                2: FixedColumnWidth(150),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('EXPORTACIÓN ANTERIOR')),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('TAMBOR COMPLETO')),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('LOTE')),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Container(),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('kg')),
                    ),
                    Container(),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Campos de tambores
            Table(
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(120),
                2: FixedColumnWidth(120),
              },
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Tamb.#'),
                    ),
                    TextField(
                      decoration: _inputDecoration(hint: 'Ingrese número'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Tamb.#'),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Tambor completo
            Table(
              columnWidths: const {
                0: FixedColumnWidth(150),
                1: FixedColumnWidth(150),
                2: FixedColumnWidth(150),
              },
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Tamb completo'),
                    ),
                    TextField(
                      controller: _tamborCompletoController,
                      decoration: _inputDecoration(hint: 'Ingrese cantidad'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      decoration: _inputDecoration(hint: 'Ingrese lotes'),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Totales y merma
            Table(
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(120),
              },
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Total: kg'),
                    ),
                    TextField(
                      controller: _totalKgController,
                      decoration: _inputDecoration(hint: 'Ingrese total'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateMermaPercentage(),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Merma (kg)'),
                    ),
                    TextField(
                      controller: _mermaKgController,
                      decoration: _inputDecoration(hint: 'Ingrese merma'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateMermaPercentage(),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Merma (%)'),
                    ),
                    TextField(
                      controller: _mermaPorcentajeController,
                      decoration: _inputDecoration(),
                      readOnly: true,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text('Observaciones'),
            TextField(
              controller: _observacionesEnvasadoController,
              maxLines: 2,
              decoration: _inputDecoration(hint: 'Ingrese observaciones aquí...'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChemicalActionButtons() {
    return Center(
      child: ElevatedButton(
        onPressed: _guardarProduccion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('GUARDAR PRODUCCIÓN', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _guardarProduccion() async {
    if (widget.ordenPrevia?.ordenTrabajoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay una orden válida para guardar')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token;
      
      // 1. Primero actualizar la orden con los datos de envasado
      final ordenActualizada = await _actualizarOrdenProduccion();
      
      if (ordenActualizada == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la orden')),
        );
        return;
      }

      // 2. Actualizar cada línea con los valores de los controladores
      for (int i = 0; i < productionLines.length; i++) {
        productionLines[i].cantidad = double.tryParse(_cantidadControllers[i].text.replaceAll(',', '.')) ?? 0.0;
        productionLines[i].lote = _loteControllers[i].text;
        productionLines[i].af = double.tryParse(_afControllers[i].text.replaceAll(',', '.')) ?? 0.0;
        productionLines[i].control = _controlControllers[i].text;
        productionLines[i].comentario = _instruccionController[i].text;
      }

      // 3. Procesar cada línea (POST para nuevas, PUT para existentes)
      for (int i = 0; i < productionLines.length; i++) {
        final linea = productionLines[i];
        
        if (linea.lineaId == 0) {
          // Línea nueva - hacer POST
          final lineaCreada = await _lineasServices.crearLinea(
            context,
            widget.ordenPrevia!.ordenTrabajoId!,
            linea,
            token,
          );
          // Actualizar con el ID generado por el servidor
          productionLines[i] = lineaCreada;
        } else {
          // Línea existente - hacer PUT
          final lineaActualizada = await _lineasServices.actualizarLinea(
            context,
            widget.ordenPrevia!.ordenTrabajoId!,
            linea,
            token,
          );
          productionLines[i] = lineaActualizada;
        }
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producción guardada correctamente'),
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la producción: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Orden?> _actualizarOrdenProduccion() async {
    try {
      final token = context.read<AuthProvider>().token;
      final ordenServices = OrdenServices();

      // Actualizar los campos de producción en la orden
      widget.ordenPrevia!.totalkgs = double.tryParse(_totalKgController.text.replaceAll(',', '.'));
      widget.ordenPrevia!.mermaKgs = double.tryParse(_mermaKgController.text.replaceAll(',', '.'));
      
      // Calcular merma porcentual si hay datos
      final totalKg = widget.ordenPrevia!.totalkgs ?? 0;
      final mermaKg = widget.ordenPrevia!.mermaKgs ?? 0;
      if (totalKg > 0) {
        widget.ordenPrevia!.mermaPorcentual = (mermaKg / totalKg) * 100;
      }
      
      widget.ordenPrevia!.comentarioTrabajo = _observacionesEnvasadoController.text;

      return await ordenServices.actualizarOrden(
        context, 
        token, 
        widget.ordenPrevia!
      );
    } catch (e) {
      print('Error actualizando orden: $e');
      return null;
    }
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: const OutlineInputBorder(),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
    );
  }

  // Resto del código para automotora (sin cambios)
  Widget _buildAutomotoraUI(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!generandoInforme) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente: ${widget.cliente!.nombre}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(height: 8),
                      Text('Vehículo: ${widget.vehiculo!.displayInfo}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Fecha: ${DateFormat('dd/MM/yyyy').format(widget.fecha!)}'),
                          const SizedBox(width: 16),
                          Text('Cond. IVA: ${widget.condIva! ? 'Sí' : 'No'}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Detalle de Piezas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Card(
                elevation: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DataTable(
                      dividerThickness: 1.0,
                      horizontalMargin: 12,
                      columnSpacing: 16,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 60,
                      headingRowHeight: 50,
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                      columns: const [
                        DataColumn(label: Text('Acción', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Pieza', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Chapa (H)', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Chapa (M)', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Pintura', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Mec. (H)', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Mec. (M)', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Repto. s/iva', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Editar', textAlign: TextAlign.center)),
                        DataColumn(label: Text('Eliminar', textAlign: TextAlign.center)),
                      ],
                      rows: lineas.isEmpty
                        ? [
                            const DataRow(cells: [
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                              DataCell(Center(child: Text('-'))),
                            ])
                          ]
                        : lineas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final linea = entry.value;
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  return index.isEven ? Colors.grey.shade50 : null;
                                },
                              ),
                              cells: [
                                DataCell(Center(child: Text(linea.accion))),
                                DataCell(Text(linea.pieza)),
                                DataCell(Center(child: Text(linea.chapaHs?.toStringAsFixed(1) ?? '0.0'))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.chapaMonto ?? 0)))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.pinturaMonto ?? 0)))),
                                DataCell(Center(child: Text(linea.mecanicaHs?.toStringAsFixed(1) ?? '0.0'))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.mecanicaMonto ?? 0)))),
                                DataCell(Center(child: Text(formatCurrency.format(linea.repSinIva ?? 0)))),
                                DataCell(
                                  Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _editarLinea(index, linea);
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Center(
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _eliminarLinea(index);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mostrarDialogoNuevaLinea(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Pieza'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Totales presupuestados',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTotalItem('Chapa:', formatCurrency.format(_totalChapa)),
                          _buildTotalItem('Pintura:', formatCurrency.format(_totalPintura)),
                          _buildTotalItem('Mecánica:', formatCurrency.format(_totalMecanica)),
                          _buildTotalItem('Repuestos:', formatCurrency.format(_totalRepuestos)),
                        ],
                      ),
                      const SizedBox(height: 12), 
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildTotalItem('TOTAL:', formatCurrency.format(_totalGeneral), isTotal: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Costos reales',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTotalItem('Chapa:', formatCurrency.format(_costoRealChapa)),
                          _buildTotalItem('Pintura:', formatCurrency.format(_costoRealPintura)),
                          _buildTotalItem('Mecánica:', formatCurrency.format(_costoRealMecanica)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _editarOrden,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirmar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _mostrarDialogoOpcionesImpresion,
                          icon: const Icon(Icons.print),
                          label: const Text('Imprimir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      color: colors.primary,
                      strokeWidth: 5,
                    ),
                  ),
                  const Text('Generando PDF, espere por favor.'),
                  TextButton(
                    onPressed: () async {
                      await ordenServices.patchInforme(context, reporte, 'D', context.read<AuthProvider>().token);
                      generandoInforme = false;
                      setState(() {});
                    }, 
                    child: const Text('Cancelar'))
                ],
              )
            ]
          ],
        ),
      ),
    );
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
    List<String> opcionesSeleccionadas = [];
    
    _opcionesImpresion.forEach((key, value) {
      if (value) {
        opcionesSeleccionadas.add(key);
      }
    });
    
    String opcionesString = opcionesSeleccionadas.join(', ');
    
    print('Opciones seleccionadas: $opcionesString');
    
    try {
      await ordenServices.postimprimirOTAdm(
        context, 
        widget.ordenPrevia!, 
        opcionesString,
        context.read<AuthProvider>().token
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
    int contador = 0;
    generandoInforme = true;
    informeGeneradoEsS = false;
    
    setState(() {});
    while (contador < 15 && informeGeneradoEsS == false && generandoInforme){
      print(contador);
      if (rptGenId == 0) {
        informeGeneradoEsS = false;
        generandoInforme = false;
        print('rptGenId es 0, saliendo del bucle');
        break;
      } 
      reporte = await ordenServices.getReporte(context, rptGenId, context.read<AuthProvider>().token);

      if(reporte.generado == 'S'){
        await Future.delayed(const Duration(seconds: 1));
        informeGeneradoEsS = true;
        if(kIsWeb){
          abrirUrlWeb(reporte.archivoUrl);
        } else{
          await abrirUrl(reporte.archivoUrl, context.read<AuthProvider>().token);
        }
        generandoInforme = false;
        informeGeneradoEsS = false;
        Provider.of<OrdenProvider>(context, listen: false).setRptId(0);
        setState(() {});
      }else{
        await Future.delayed(const Duration(seconds: 1));
      }
      contador++;
    }
    if(informeGeneradoEsS != true && generandoInforme){
      await popUpInformeDemoro();
      
      print('informe demoro en generarse');
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
                await ordenServices.patchInforme(context, reporte, 'D', context.read<AuthProvider>().token);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: const Text('No'),
            ),
            TextButton(
              child: const Text('Si'),
              onPressed: () async {
                Navigator.of(context).pop();
                print('dije SI');
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
      reporte = await ordenServices.getReporte(context, rptGenId, context.read<AuthProvider>().token);
      if(reporte.generado == 'S'){
        informeGeneradoEsS = true;
        if(kIsWeb) {
          abrirUrlWeb(reporte.archivoUrl);
        } else {
          await abrirUrl(reporte.archivoUrl, context.read<AuthProvider>().token);
        }
        generandoInforme = false;
        setState(() {});
      }else{
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    setState(() {});

  }

  abrirUrl(String url, String token) async {
    Dio dio = Dio();
    String link = "$url?authorization=$token";
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

  void _editarLinea(int index, Linea linea) async {
    int? accionIdSeleccionado = linea.accionId;
    int? piezaIdSeleccionado = linea.piezaId;
    String? accionDescripcionSeleccionada = linea.accion;
    String? piezaDescripcionSeleccionada = linea.pieza;
    
    final chapaHorasController = TextEditingController(text: linea.chapaHs?.toString() ?? '');
    final chapaMontoController = TextEditingController(text: linea.chapaMonto?.toString() ?? '');
    final pinturaController = TextEditingController(text: linea.pinturaMonto?.toString() ?? '');
    final mechHorasController = TextEditingController(text: linea.mecanicaHs?.toString() ?? '');
    final mechMontoController = TextEditingController(text: linea.mecanicaMonto?.toString() ?? '');
    final reptoController = TextEditingController(text: linea.repSinIva?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Pieza', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingTareas)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: accionDescripcionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Acción',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: tareas.map((Tarea tarea) {
                      return DropdownMenuItem<String>(
                        value: tarea.descripcion,
                        child: Text(tarea.descripcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevaAccion) {
                      final tareaSeleccionada = tareas.firstWhere(
                        (t) => t.descripcion == nuevaAccion,
                        orElse: () => Tarea.empty()
                      );
                      if (tareaSeleccionada.tareaId != 0) {
                        accionIdSeleccionado = tareaSeleccionada.tareaId;
                        accionDescripcionSeleccionada = tareaSeleccionada.descripcion;
                      }
                    },
                  ),
                const SizedBox(height: 12),
                
                if (isLoadingMateriales)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: piezaDescripcionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Pieza',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: materiales.map((Materiales material) {
                      return DropdownMenuItem<String>(
                        value: material.descripcion,
                        child: Text(material.descripcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevaPieza) {
                      final materialSeleccionado = materiales.firstWhere(
                        (m) => m.descripcion == nuevaPieza,
                        orElse: () => Materiales.empty()
                      );
                      if (materialSeleccionado.materialId != 0) {
                        piezaIdSeleccionado = materialSeleccionado.materialId;
                        piezaDescripcionSeleccionada = materialSeleccionado.descripcion;
                      }
                    },
                  ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: chapaHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Chapa (H)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: chapaMontoController,
                        decoration: const InputDecoration(
                          labelText: 'Chapa (M)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: pinturaController,
                  decoration: const InputDecoration(
                    labelText: 'Pintura',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: mechHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Mec. (H)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: mechMontoController,
                        decoration: const InputDecoration(
                          labelText: 'Mec. (M)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: reptoController,
                  decoration: const InputDecoration(
                    labelText: 'Rep. s/iva',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              onPressed: () {
                _actualizarLinea(
                  index,
                  linea,
                  accionIdSeleccionado,
                  piezaIdSeleccionado,
                  accionDescripcionSeleccionada,
                  piezaDescripcionSeleccionada,
                  chapaHorasController,
                  chapaMontoController,
                  pinturaController,
                  mechHorasController,
                  mechMontoController,
                  reptoController,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  void _actualizarLinea(
    int index,
    Linea lineaOriginal,
    int? accionIdSeleccionado,
    int? piezaIdSeleccionado,
    String? accionDescripcionSeleccionada,
    String? piezaDescripcionSeleccionada,
    TextEditingController chapaHorasController,
    TextEditingController chapaMontoController,
    TextEditingController pinturaController,
    TextEditingController mechHorasController,
    TextEditingController mechMontoController,
    TextEditingController reptoController,
  ) async {
    if (accionIdSeleccionado == null || piezaIdSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una acción y una pieza')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token;
      
      final lineaActualizada = Linea(
        lineaId: lineaOriginal.lineaId,
        ordenTrabajoId: lineaOriginal.ordenTrabajoId,
        itemId: lineaOriginal.itemId,
        codItem: lineaOriginal.codItem,
        descripcion: lineaOriginal.descripcion,
        macroFamilia: lineaOriginal.macroFamilia,
        familia: lineaOriginal.familia,
        grupoInventario: lineaOriginal.grupoInventario,
        ordinal: lineaOriginal.ordinal,
        cantidad: lineaOriginal.cantidad,
        costoUnitario: lineaOriginal.costoUnitario,
        descuento1: lineaOriginal.descuento1,
        descuento2: lineaOriginal.descuento2,
        descuento3: lineaOriginal.descuento3,
        precioVenta: lineaOriginal.precioVenta,
        comentario: lineaOriginal.comentario,
        ivaId: lineaOriginal.ivaId,
        iva: lineaOriginal.iva,
        valor: lineaOriginal.valor,
        codGruInv: lineaOriginal.codGruInv,
        gruInvId: lineaOriginal.gruInvId,
        avance: lineaOriginal.avance,
        mo: lineaOriginal.mo,
        chapaHs: double.tryParse(chapaHorasController.text) ?? 0.0,
        chapaMonto: double.tryParse(chapaMontoController.text) ?? 0.0,
        pinturaMonto: double.tryParse(pinturaController.text) ?? 0.0,
        mecanicaHs: double.tryParse(mechHorasController.text) ?? 0.0,
        mecanicaMonto: double.tryParse(mechMontoController.text) ?? 0.0,
        repSinIva: double.tryParse(reptoController.text) ?? 0.0,
        accionId: accionIdSeleccionado,
        accion: accionDescripcionSeleccionada ?? '',
        piezaId: piezaIdSeleccionado,
        pieza: piezaDescripcionSeleccionada ?? '',
        af: null,
        lote: '',
        control: ''
      );

      final lineaRespuesta = await _lineasServices.actualizarLinea(
        context,
        widget.ordenPrevia!.ordenTrabajoId!,
        lineaActualizada,
        token,
      );

      Navigator.of(context).pop();

      setState(() {
        lineas[index] = lineaRespuesta;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Línea actualizada correctamente')),
      );

    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la línea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTotalItem(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
        )),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          color: isTotal ? Colors.green : Colors.black,
        )),
      ],
    );
  }

  void _mostrarDialogoNuevaLinea(BuildContext context) {
    int? accionIdSeleccionado;
    int? piezaIdSeleccionado;
    String? accionDescripcionSeleccionada;
    String? piezaDescripcionSeleccionada;
    int tarifaChapa = tarifas.firstWhere((t) => t.codTarifa == 'CH', orElse: () => Tarifa.empty()).valor ?? 0;
    int tarifaMecanica = tarifas.firstWhere((t) => t.codTarifa == 'ME', orElse: () => Tarifa.empty()).valor ?? 0;
    
    final chapaHorasController = TextEditingController();
    final chapaMontoController = TextEditingController();
    final pinturaController = TextEditingController();
    final mechHorasController = TextEditingController();
    final mechMontoController = TextEditingController();
    final reptoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Pieza', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingTareas)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: accionDescripcionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Acción',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: tareas.map((Tarea tarea) {
                      return DropdownMenuItem<String>(
                        value: tarea.descripcion,
                        child: Text(tarea.descripcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevaAccion) {
                      final tareaSeleccionada = tareas.firstWhere(
                        (t) => t.descripcion == nuevaAccion,
                        orElse: () => Tarea.empty()
                      );
                      if (tareaSeleccionada.tareaId != 0) {
                        accionIdSeleccionado = tareaSeleccionada.tareaId;
                        accionDescripcionSeleccionada = tareaSeleccionada.descripcion;
                      }
                    },
                  ),
                const SizedBox(height: 12),
                
                if (isLoadingMateriales)
                  const CircularProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: piezaDescripcionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Pieza',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: materiales.map((Materiales material) {
                      return DropdownMenuItem<String>(
                        value: material.descripcion,
                        child: Text(material.descripcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevaPieza) {
                      final materialSeleccionado = materiales.firstWhere(
                        (m) => m.descripcion == nuevaPieza,
                        orElse: () => Materiales.empty()
                      );
                      if (materialSeleccionado.materialId != 0) {
                        piezaIdSeleccionado = materialSeleccionado.materialId;
                        piezaDescripcionSeleccionada = materialSeleccionado.descripcion;
                      }
                    },
                  ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: chapaHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Chapa (H)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          double horas = double.tryParse(value) ?? 0.0;
                          double monto = horas * tarifaChapa;
                          chapaMontoController.text = monto.toStringAsFixed(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: chapaMontoController,
                        decoration: const InputDecoration(
                          labelText: 'Chapa (M)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: pinturaController,
                  decoration: const InputDecoration(
                    labelText: 'Pintura',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: mechHorasController,
                        decoration: const InputDecoration(
                          labelText: 'Mec. (H)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          double horas = double.tryParse(value) ?? 0.0;
                          double monto = horas * tarifaMecanica;
                          mechMontoController.text = monto.toStringAsFixed(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: mechMontoController,
                        decoration: const InputDecoration(
                          labelText: 'Mec. (M)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: reptoController,
                  decoration: const InputDecoration(
                    labelText: 'Rep. s/iva',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              onPressed: () {
                _agregarLinea(
                  accionIdSeleccionado,
                  piezaIdSeleccionado,
                  accionDescripcionSeleccionada,
                  piezaDescripcionSeleccionada,
                  chapaHorasController,
                  chapaMontoController,
                  pinturaController,
                  mechHorasController,
                  mechMontoController,
                  reptoController,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose de todos los controladores de resysol
    for (var controller in _cantidadControllers) {
      controller.dispose();
    }
    for (var controller in _loteControllers) {
      controller.dispose();
    }
    for (var controller in _afControllers) {
      controller.dispose();
    }
    for (var controller in _controlControllers) {
      controller.dispose();
    }
    
    _tamborCompletoController.dispose();
    _picoController.dispose();
    _totalKgController.dispose();
    _mermaKgController.dispose();
    _mermaPorcentajeController.dispose();
    _observacionesEnvasadoController.dispose();
    
    super.dispose();
  }
}