class Unidad {
  late int unidadId;
  late int? itemId;
  late String codItem;
  late String descripcion;
  late int modeloId;
  late String codModelo;
  late String modelo;
  late int marcaId;
  late String codMarca;
  late String marca;
  late String chasis;
  late String motor;
  late int anio;
  late int colorId;
  late String color;
  late bool consignado;
  late bool averias;
  late String matricula;
  late int km;
  late String comentario;
  late int recibidoPorId;
  late String recibidoPor;
  late String transportadoPor;
  late int? clienteId;
  late String? padron;

  Unidad({
    required this.unidadId,
    required this.itemId,
    required this.codItem,
    required this.descripcion,
    required this.modeloId,
    required this.codModelo,
    required this.modelo,
    required this.marcaId,
    required this.codMarca,
    required this.marca,
    required this.chasis,
    required this.motor,
    required this.anio,
    required this.colorId,
    required this.color,
    required this.consignado,
    required this.averias,
    required this.matricula,
    required this.km,
    required this.comentario,
    required this.recibidoPorId,
    required this.recibidoPor,
    required this.transportadoPor,
    this.clienteId,
    this.padron,
  });

  Unidad copyWith({
    int? unidadId,
    int? itemId,
    String? codItem,
    String? descripcion,
    int? modeloId,
    String? codModelo,
    String? modelo,
    int? marcaId,
    String? codMarca,
    String? marca,
    String? chasis,
    String? motor,
    int? anio,
    int? colorId,
    String? color,
    bool? consignado,
    bool? averias,
    String? matricula,
    int? km,
    String? comentario,
    int? recibidoPorId,
    String? recibidoPor,
    String? transportadoPor,
    int? clienteId,
    String? padron,
  }) => 
      Unidad(
        unidadId: unidadId ?? this.unidadId,
        itemId: itemId ?? this.itemId,
        codItem: codItem ?? this.codItem,
        descripcion: descripcion ?? this.descripcion,
        modeloId: modeloId ?? this.modeloId,
        codModelo: codModelo ?? this.codModelo,
        modelo: modelo ?? this.modelo,
        marcaId: marcaId ?? this.marcaId,
        codMarca: codMarca ?? this.codMarca,
        marca: marca ?? this.marca,
        chasis: chasis ?? this.chasis,
        motor: motor ?? this.motor,
        anio: anio ?? this.anio,
        colorId: colorId ?? this.colorId,
        color: color ?? this.color,
        consignado: consignado ?? this.consignado,
        averias: averias ?? this.averias,
        matricula: matricula ?? this.matricula,
        km: km ?? this.km,
        comentario: comentario ?? this.comentario,
        recibidoPorId: recibidoPorId ?? this.recibidoPorId,
        recibidoPor: recibidoPor ?? this.recibidoPor,
        transportadoPor: transportadoPor ?? this.transportadoPor,
        clienteId: clienteId ?? this.clienteId,
        padron: padron ?? this.padron,
      );

  factory Unidad.fromJson(Map<String, dynamic> json) => Unidad(
    unidadId: json["unidadId"] as int? ?? 0,
    itemId: json["itemId"] as int? ?? 0,
    codItem: json["codItem"] as String? ?? '',
    descripcion: json["descripcion"] as String? ?? '',
    modeloId: json["modeloId"] as int? ?? 0,
    codModelo: json["codModelo"] as String? ?? '',
    modelo: json["modelo"] as String? ?? '',
    marcaId: json["marcaId"] as int? ?? 0,
    codMarca: json["codMarca"] as String? ?? '',
    marca: json["marca"] as String? ?? '',
    chasis: json["chasis"] as String? ?? '',
    motor: json["motor"] as String? ?? '',
    anio: json["anio"] as int? ?? 0,
    colorId: json["colorId"] as int? ?? 0,
    color: json["color"] as String? ?? '',
    consignado: json["consignado"] as bool? ?? false,
    averias: json["averias"] as bool? ?? false,
    matricula: json["matricula"] as String? ?? '',
    km: json["km"] is double ? (json["km"] as double).toInt() : json["km"] as int? ?? 0,
    comentario: json["comentario"] as String? ?? '',
    recibidoPorId: json["recibidoPorId"] as int? ?? 0,
    recibidoPor: json["recibidoPor"] as String? ?? '',
    transportadoPor: json["transportadoPor"] as String? ?? '',
    clienteId: json["clienteId"] as int?,
    padron: json["padron"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "unidadId": unidadId,
    "itemId": null,
    "modeloId": modeloId,
    "chasis": chasis,
    "motor": motor,
    "anio": anio,
    "colorId": 1,
    "consignado": consignado,
    "averias": averias,
    "matricula": matricula,
    "km": km,
    "comentario": comentario,
    "recibidoPorId": recibidoPorId,
    "transportadoPor": transportadoPor,
    "clienteId": clienteId,
    "padron": padron,
  };

  Unidad.empty() {
    unidadId = 0;
    itemId = 0;
    codItem = '';
    descripcion = '';
    modeloId = 0;
    codModelo = '';
    modelo = '';
    marcaId = 0;
    codMarca = '';
    marca = '';
    chasis = '';
    motor = '';
    anio = 0;
    colorId = 0;
    color = '';
    consignado = false;
    averias = false;
    matricula = '';
    km = 0;
    comentario = '';
    recibidoPorId = 0;
    recibidoPor = '';
    transportadoPor = '';
    clienteId = null;
    padron = null;
  }

  // Método auxiliar para mostrar información en la lista
  String get displayInfo {
    return '$marca $modelo - $matricula';
  }
}