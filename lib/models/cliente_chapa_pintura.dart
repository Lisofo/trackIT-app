class ClienteCP {
  final int id;
  final String nombre;
  final String apellido;
  final String direccion;
  final String telefono;

  ClienteCP({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.direccion,
    required this.telefono,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory ClienteCP.empty() {
    return ClienteCP(
      id: 0,
      nombre: '',
      apellido: '',
      direccion: '',
      telefono: '',
    );
  }
}

class Vehiculo {
  final int id;
  final int clienteId;
  final String marca;
  final String matricula;
  final String modelo;
  final int ano;

  Vehiculo({
    required this.id,
    required this.clienteId,
    required this.marca,
    required this.matricula,
    required this.modelo,
    required this.ano,
  });

  String get displayInfo => '$marca/$modelo/$matricula';

  factory Vehiculo.empty() {
    return Vehiculo(
      id: 0,
      clienteId: 0,
      marca: '',
      matricula: '',
      modelo: '',
      ano: 0,
    );
  }
}