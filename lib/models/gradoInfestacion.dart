// ignore_for_file: file_names

class GradoInfestacion {
  late int gradoInfestacionId;
  late String codGradoInfestacion;
  late String descripcion;

  GradoInfestacion({
    required this.gradoInfestacionId,
    required this.codGradoInfestacion,
    required this.descripcion,
  });

  GradoInfestacion.empty() {
    gradoInfestacionId = 0;
    codGradoInfestacion = '';
    descripcion = '';
  }

  @override
  String toString() {
    return descripcion;
  }
}
