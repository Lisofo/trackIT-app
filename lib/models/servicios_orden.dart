class ServiciosOrden {
  late String codServicio;
  late String descripcion;

  ServiciosOrden({
    required this.codServicio,
    required this.descripcion,
  });

  ServiciosOrden.empty() {
    codServicio = '';
    descripcion = '';
  }
}
