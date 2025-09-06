class Marca {
  final int id;
  final String nombre;
  final List<String> modelos;

  Marca({required this.id, required this.nombre, required this.modelos});
}

class Modelo {
  final int id;
  final String nombre;
  final int marcaId;

  Modelo({required this.id, required this.nombre, required this.marcaId});
}

class ClienteCP {
  final int id;
  final String nombre;
  final String apellido;
  final String direccion;
  final String telefono;
  final String documento;
  final String tipoDocumento; // 'CI' o 'RUT'
  final String correo;

  ClienteCP({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.direccion,
    required this.telefono,
    required this.documento,
    required this.tipoDocumento,
    required this.correo,
  });

  String get nombreCompleto => '$nombre $apellido';

  factory ClienteCP.empty() {
    return ClienteCP(
      id: 0,
      nombre: '',
      apellido: '',
      direccion: '',
      telefono: '',
      documento: '',
      tipoDocumento: 'CI',
      correo: '',
    );
  }
}

class Vehiculo {
  final int id;
  final int clienteId; // Este campo es necesario para las órdenes
  final String matricula;
  final String marca;
  final String modelo;
  final int ano;
  final String nroMotor;
  final String nroChasis;

  Vehiculo({
    required this.id,
    required this.clienteId, // Agregar este campo requerido
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.nroMotor,
    required this.nroChasis,
  });

  String get displayInfo => '$marca/$modelo/$matricula';

  factory Vehiculo.empty() {
    return Vehiculo(
      id: 0,
      clienteId: 0, // Agregar aquí también
      matricula: '',
      marca: '',
      modelo: '',
      ano: 0,
      nroMotor: '',
      nroChasis: '',
    );
  }
}

class SharedData {
  static List<Marca> marcas = [
    Marca(
      id: 1,
      nombre: 'Toyota',
      modelos: ['Corolla', 'Hilux', 'RAV4', 'Yaris', 'Camry'],
    ),
    Marca(
      id: 2,
      nombre: 'Ford',
      modelos: ['Ranger', 'Fiesta', 'Focus', 'EcoSport', 'Kuga'],
    ),
    Marca(
      id: 3,
      nombre: 'Volkswagen',
      modelos: ['Golf', 'Polo', 'T-Cross', 'Virtus', 'Amarok'],
    ),
    Marca(
      id: 4,
      nombre: 'Chevrolet',
      modelos: ['Cruze', 'Onix', 'Tracker', 'S10', 'Spin'],
    ),
    Marca(
      id: 5,
      nombre: 'Fiat',
      modelos: ['Cronos', 'Argo', 'Mobi', 'Pulse', 'Strada'],
    ),
  ];
    static List<ClienteCP> clientes = [
      ClienteCP(
        id: 1,
        nombre: 'GOMEZ',
        apellido: 'HECTOR',
        direccion: 'SOLFERINO 3900',
        telefono: '5069884',
        documento: '12345678',
        correo: 'gomez.hector@email.com', // Nuevo campo agregado
        tipoDocumento: "CI"
      ),
      ClienteCP(
        id: 2,
        nombre: 'PEREZ',
        apellido: 'JUAN',
        direccion: 'AV. LIBERTADOR 123',
        telefono: '1234567',
        documento: '87654321',
        correo: 'perez.juan@email.com', // Nuevo campo agregado
        tipoDocumento: "CI"
      ),
      ClienteCP(
        id: 3,
        nombre: 'LOPEZ',
        apellido: 'MARIA',
        direccion: 'CALLE 45 #67-89',
        telefono: '7654321',
        documento: '45678912',
        correo: 'lopez.maria@email.com', // Nuevo campo agregado
        tipoDocumento: "CI"
      ),
      ClienteCP(
        id: 4,
        nombre: 'RODRIGUEZ',
        apellido: 'CARLOS',
        direccion: 'AV. SIEMPRE VIVA 742',
        telefono: '5551234',
        documento: '98765432',
        correo: 'rodriguez.carlos@email.com', // Nuevo campo agregado
        tipoDocumento: "CI"
      ),
      ClienteCP(
        id: 5,
        nombre: 'GONZALEZ',
        apellido: 'ANA',
        direccion: 'CALLE FALSA 123',
        telefono: '5555678',
        documento: '34567890',
        correo: 'gonzalez.ana@email.com', // Nuevo campo agregado
        tipoDocumento: "CI"
      ),
    ];

    static List<Vehiculo> vehiculos = [
      Vehiculo(
        id: 1,
        clienteId: 1, // Agregar clienteId correspondiente
        marca: 'Toyota',
        matricula: 'ABC123',
        modelo: 'Corolla',
        ano: 2020,
        nroMotor: 'M123456789',
        nroChasis: 'CH123456789',
      ),
      Vehiculo(
        id: 2,
        clienteId: 1, // Mismo cliente (GOMEZ HECTOR)
        marca: 'Ford',
        matricula: 'XYZ789',
        modelo: 'Fiesta',
        ano: 2018,
        nroMotor: 'M987654321',
        nroChasis: 'CH987654321',
      ),
      Vehiculo(
        id: 3,
        clienteId: 2, // Cliente PEREZ JUAN
        marca: 'Honda',
        matricula: 'DEF456',
        modelo: 'Civic',
        ano: 2019,
        nroMotor: 'M456789123',
        nroChasis: 'CH456789123',
      ),
      Vehiculo(
        id: 4,
        clienteId: 3, // Cliente LOPEZ MARIA
        marca: 'Chevrolet',
        matricula: 'GHI789',
        modelo: 'Cruze',
        ano: 2021,
        nroMotor: 'M789123456',
        nroChasis: 'CH789123456',
      ),
      Vehiculo(
        id: 5,
        clienteId: 4, // Cliente RODRIGUEZ CARLOS
        marca: 'Volkswagen',
        matricula: 'JKL012',
        modelo: 'Golf',
        ano: 2017,
        nroMotor: 'M012345678',
        nroChasis: 'CH012345678',
      ),
      Vehiculo(
        id: 6,
        clienteId: 5, // Cliente GONZALEZ ANA
        marca: 'Renault',
        matricula: 'MNO345',
        modelo: 'Clio',
        ano: 2020,
        nroMotor: 'M345678901',
        nroChasis: 'CH345678901',
      ),
    ];
  }