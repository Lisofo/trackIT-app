class ServicioOrdenes {
  late int servicioId;
  late String codServicio;
  late String descripcion;

  ServicioOrdenes({
    required this.servicioId,
    required this.codServicio,
    required this.descripcion,
  });

  factory ServicioOrdenes.fromJson(Map<String, dynamic> json) =>
      ServicioOrdenes(
        servicioId: json["servicioId"],
        codServicio: json["codServicio"],
        descripcion: json["descripcion"],
      );

  Map<String, dynamic> toMap() => {
        "servicioId": servicioId,
        "codServicio": codServicio,
        "descripcion": descripcion,
      };

  ServicioOrdenes.empty() {
    servicioId = 0;
    codServicio = '';
    descripcion = '';
  }
}
