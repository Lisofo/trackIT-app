class Lote {
  int? loteId;
  int? pedidoId;
  String? lote;
  int? totalEmbarcar;
  String? nvporc;
  String? visc;
  DateTime? fechaLote;
  String? estado;
  String? observaciones;
  DateTime? fechaCierre;
  List<OrdenTrabajo>? ordenes;
  
  // Nuevos atributos
  int? picoProduccion;
  int? cantTambores;
  int? kgTambor;
  int? mermaProceso;
  double? porcentajeMerma;
  int? cantPallets;

  Lote({
    this.loteId,
    this.pedidoId,
    this.lote,
    this.totalEmbarcar,
    this.nvporc,
    this.visc,
    this.fechaLote,
    this.estado,
    this.observaciones,
    this.fechaCierre,
    this.ordenes,
    // Nuevos parámetros en el constructor
    this.picoProduccion,
    this.cantTambores,
    this.kgTambor,
    this.mermaProceso,
    this.porcentajeMerma,
    this.cantPallets,
  });

  // Constructor empty actualizado
  factory Lote.empty() {
    return Lote(
      loteId: 0,
      pedidoId: 0,
      lote: '',
      totalEmbarcar: 0,
      nvporc: '',
      visc: '',
      fechaLote: null,
      estado: '',
      observaciones: '',
      fechaCierre: null,
      ordenes: [],
      // Valores por defecto para nuevos atributos
      picoProduccion: 0,
      cantTambores: 0,
      kgTambor: 0,
      mermaProceso: 0,
      porcentajeMerma: 0.0,
      cantPallets: 0,
    );
  }

  // Método fromJson actualizado
  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      loteId: json['loteId'],
      pedidoId: json['pedidoId'],
      lote: json['lote'],
      totalEmbarcar: json['totalEmbarcar'],
      nvporc: json['nvporc'],
      visc: json['visc'],
      fechaLote: json['fechaLote'] != null ? DateTime.parse(json['fechaLote']) : null,
      estado: json['estado'],
      observaciones: json['observaciones'],
      fechaCierre: json['fechaCierre'] != null ? DateTime.parse(json['fechaCierre']) : null,
      ordenes: json['ordenes'] != null
          ? List<OrdenTrabajo>.from(
              json['ordenes'].map((x) => OrdenTrabajo.fromJson(x)))
          : null,
      // Nuevos campos desde JSON
      picoProduccion: json['picoProduccion'] ?? json['picoProduccion'],
      cantTambores: json['cantTambores'] ?? json['cantTambores'],
      kgTambor: json['kgTambor'] ?? json['kgTambor'],
      mermaProceso: json['mermaProceso'] ?? json['mermaProceso'],
      porcentajeMerma: (json['porcentajeMerma'] ?? json['%Merma'] ?? 0.0).toDouble(),
      cantPallets: json['cantPallets'] ?? json['cantPallets'],
    );
  }

  // Método toJson actualizado
  Map<String, dynamic> toJson() {
    return {
      'loteId': loteId,
      'pedidoId': pedidoId,
      'lote': lote,
      'totalEmbarcar': totalEmbarcar,
      'nvporc': nvporc,
      'visc': visc,
      'fechaLote': fechaLote?.toIso8601String(),
      'estado': estado,
      'observaciones': observaciones,
      'fechaCierre': fechaCierre?.toIso8601String(),
      'ordenes': ordenes != null
          ? List<dynamic>.from(ordenes!.map((x) => x.toJson()))
          : null,
      // Nuevos campos en JSON
      'picoProduccion': picoProduccion,
      'cantTambores': cantTambores,
      'kgTambor': kgTambor,
      'mermaProceso': mermaProceso,
      'porcentajeMerma': porcentajeMerma,
      'cantPallets': cantPallets,
    };
  }

  // Método estático para parsear una lista de lotes (sin cambios)
  static List<Lote> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Lote.fromJson(json)).toList();
  }

  // Método estático para convertir lista a JSON (sin cambios)
  static List<Map<String, dynamic>> toJsonList(List<Lote> lotes) {
    return lotes.map((lote) => lote.toJson()).toList();
  }

  // Método copyWith actualizado
  Lote copyWith({
    int? loteId,
    int? pedidoId,
    String? lote,
    int? totalEmbarcar,
    String? nvporc,
    String? visc,
    DateTime? fechaLote,
    String? estado,
    String? observaciones,
    DateTime? fechaCierre,
    List<OrdenTrabajo>? ordenes,
    // Nuevos parámetros en copyWith
    int? picoProduccion,
    int? cantTambores,
    int? kgTambor,
    int? mermaProceso,
    double? porcentajeMerma,
    int? cantPallets,
  }) {
    return Lote(
      loteId: loteId ?? this.loteId,
      pedidoId: pedidoId ?? this.pedidoId,
      lote: lote ?? this.lote,
      totalEmbarcar: totalEmbarcar ?? this.totalEmbarcar,
      nvporc: nvporc ?? this.nvporc,
      visc: visc ?? this.visc,
      fechaLote: fechaLote ?? this.fechaLote,
      estado: estado ?? this.estado,
      observaciones: observaciones ?? this.observaciones,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      ordenes: ordenes ?? this.ordenes,
      // Nuevos campos
      picoProduccion: picoProduccion ?? this.picoProduccion,
      cantTambores: cantTambores ?? this.cantTambores,
      kgTambor: kgTambor ?? this.kgTambor,
      mermaProceso: mermaProceso ?? this.mermaProceso,
      porcentajeMerma: porcentajeMerma ?? this.porcentajeMerma,
      cantPallets: cantPallets ?? this.cantPallets,
    );
  }

  @override
  String toString() {
    return 'Lote(loteId: $loteId, lote: $lote, estado: $estado, totalEmbarcar: $totalEmbarcar, picoProduccion: $picoProduccion, cantTambores: $cantTambores)';
  }

  // Métodos auxiliares (sin cambios)
  bool get estaAbierto => estado == 'ABIERTO';
  bool get estaCerrado => estado == 'CERRADO';
  
  String? get fechaLoteFormatted => fechaLote != null 
      ? '${fechaLote!.day}/${fechaLote!.month}/${fechaLote!.year}' 
      : null;
      
  String? get fechaCierreFormatted => fechaCierre != null 
      ? '${fechaCierre!.day}/${fechaCierre!.month}/${fechaCierre!.year}' 
      : null;
}

class OrdenTrabajo {
  int? ordenTrabajoId;
  String? numeroOrdenTrabajo;
  String? descripcion;

  OrdenTrabajo({
    this.ordenTrabajoId,
    this.numeroOrdenTrabajo,
    this.descripcion,
  });

  // Constructor empty
  factory OrdenTrabajo.empty() {
    return OrdenTrabajo(
      ordenTrabajoId: 0,
      numeroOrdenTrabajo: '',
      descripcion: '',
    );
  }

  factory OrdenTrabajo.fromJson(Map<String, dynamic> json) {
    return OrdenTrabajo(
      ordenTrabajoId: json['ordenTrabajoId'],
      numeroOrdenTrabajo: json['numeroOrdenTrabajo'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordenTrabajoId': ordenTrabajoId,
      'numeroOrdenTrabajo': numeroOrdenTrabajo,
      'descripcion': descripcion,
    };
  }

  @override
  String toString() {
    return 'OrdenTrabajo(numeroOrdenTrabajo: $numeroOrdenTrabajo, descripcion: $descripcion)';
  }
}

class LineaLote {
  int? lineaId;
  int? loteId;
  int? itemId;
  int? ordinal;
  int? cantidad;
  double? costoUnitario;
  String? comentario;
  int? accionId;
  int? piezaId;
  int? control;
  String? lote;
  String? referencia;

  LineaLote({
    this.lineaId,
    this.loteId,
    this.itemId,
    this.ordinal,
    this.cantidad,
    this.costoUnitario,
    this.comentario,
    this.accionId,
    this.piezaId,
    this.control,
    this.lote,
    this.referencia
  });

  factory LineaLote.empty() {
    return LineaLote(
      lineaId: 0,
      loteId: 0,
      itemId: 0,
      ordinal: 0,
      cantidad: 0,
      costoUnitario: 0.0,
      comentario: '',
      accionId: 0,
      piezaId: 0,
      control: null,
      lote: null,
      referencia: null,
    );
  }

  factory LineaLote.fromJson(Map<String, dynamic> json) {
    return LineaLote(
      lineaId: json['lineaId'],
      loteId: json['loteId'],
      itemId: json['itemId'],
      ordinal: json['ordinal'],
      cantidad: json['cantidad'],
      costoUnitario: json['costoUnitario']?.toDouble(),
      comentario: json['comentario'],
      accionId: json['accionId'],
      piezaId: json['piezaId'],
      control: json['control'],
      lote: json['lote'],
      referencia: json['referencia']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lineaId': lineaId,
      'loteId': loteId,
      'itemId': itemId,
      'ordinal': ordinal,
      'cantidad': cantidad,
      'costoUnitario': costoUnitario,
      'comentario': comentario,
      'accionId': accionId,
      'piezaId': piezaId,
      'control': control,
      'lote': lote,
      'referencia': referencia,
    };
  }

  LineaLote copyWith({
    int? lineaId,
    int? loteId,
    int? itemId,
    int? ordinal,
    int? cantidad,
    double? costoUnitario,
    String? comentario,
    int? accionId,
    int? piezaId,
    int? control,
    String? lote,
    String? referencia
  }) {
    return LineaLote(
      lineaId: lineaId ?? this.lineaId,
      loteId: loteId ?? this.loteId,
      itemId: itemId ?? this.itemId,
      ordinal: ordinal ?? this.ordinal,
      cantidad: cantidad ?? this.cantidad,
      costoUnitario: costoUnitario ?? costoUnitario,
      comentario: comentario ?? this.comentario,
      accionId: accionId ?? this.accionId,
      piezaId: piezaId ?? this.piezaId,
      control: control ?? this.control,
      lote: lote ?? this.lote,
      referencia: referencia ?? this.referencia,
    );
  }

  @override
  String toString() {
    return 'LineaLote(lineaId: $lineaId, loteId: $loteId, itemId: $itemId, cantidad: $cantidad)';
  }
}