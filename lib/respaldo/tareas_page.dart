import 'package:flutter/material.dart';

class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  List<String> tareas = [
    'Aplicación de Fosfuro de Aluminio con cobertor.',
    'Aplicación de Fosfuro de Aluminio en contenedores.',
    'Aplicación de gel para control de cucarachas.',
    'Aplicación de gel para control de hormigas.',
    'Aplicación de hormiguicida en polvo',
    'Aplicación de hormiguicida granulado',
    'Aplicación de insecticida - Atomización (M.M.).',
    'Aplicación de insecticida - Nebulización',
    'Aplicación de insecticida - Pulverización (M5).',
    'Aplicación de insecticida - Termonebulización.',
    'Aplicación de insecticida en polvo.',
    'Aplicación de insecticida en tarrinas para el control de mosca doméstica',
    'Aplicación de insecticida granulado.',
    'Cambio de arrancadores de trampas de luz UV.',
    'Cambio de aspersores (punteros).',
    'Cambio de placa adhesiva de trampa de luz UV.',
    'Cambio de sensor.',
    'Cambio de tubos de trampas de luz UV.',
    'Capacitación a cliente',
    'Cobranza',
    'Control de calidad - Supervisión.',
    'Desinfección',
    'Desinfección por Covid 19',
    'Diagnóstico',
    'Evaluación de Gestión Integrada de plagas',
    'Evaluación de Gestión Integrada de plagas basada en AIB',
    'Evaluación de Gestión Integrada de plagas basada en BRC'
        'Inspección',
    'Inspección sin particularidades',
    'Instalación de aerosoles de descarga completa',
    'Instalación de Coopermatic / Fly Killer',
    'Instalación de dispositivos de monitoreo y control de plagas',
    'Instalación de estaciones para el control de roedores',
    'Instalación de plan de contingencia',
    'Instalación de servicio',
    'Instalación de tarrinas para el control de moscas',
    'Instalación de trampa para el control de comadrejas / gatos',
    'Instalación de trampa para el control de palomas.',
    'Instalación de trampas atrapavivos para el control de roedores',
    'Instalación de trampas de luz UV para el monitoreo de insectos voladores',
    'Instalación de trampas mecánicas para el control de roedores',
    'Limpieza de trampas de luz UV para el monitoreo de insectos voladores',
    'Medición de tubos de luz UV',
    'Monitoreo de plan de contingencia',
    'Monitoreo y control de aves',
    'Monitoreo y control de cucarachas',
    'Monitoreo y control de hormigas',
    'Monitoreo y control de madrigueras y lugares de tránsito de roedores',
    'Monitoreo y control de moscas',
    'Monitoreo y control de palomas',
    'Monitoreo y control de picudo rojo (Rynchophorus ferrugineus)',
    'Monitoreo y control de roedores',
    'Monitoreo y mantenimiento de estaciones para el control de roedores',
    'Monitoreo y mantenimiento de sistema de control de mosca de los cuernos',
    'Monitoreo y mantenimiento de sistema de desinfección automática de vehículos',
    'Monitoreo y mantenimiento de tarrinas para control de picudo rojo',
    'Monitoreo y mantenimiento de trampa para comadrejas / gatos',
    'Monitoreo y mantenimiento de trampa para el control de palomas',
    'Monitoreo y mantenimiento de trampas de luz UV para insectos voladores',
    'No aplica - Acceso bloqueado por clima.',
    'No aplica - Cliente se encontró cerrado',
    'No aplica - No se pudo ingresar al cliente.',
    'Reposición de cebo atrayente no tóxico',
    'Reposición de Fly Killer',
    'Reposición de producto',
    'Reposición de producto en sistema de control de moscas de los cuernos',
    'Reposición de producto en sistema de desinfección automática de vehículos',
    'Reposición de producto en sistema de desinfección por Covid',
    'Retiro de dispositivos de monitoreo y control de plagas',
    'Retiro de Fosfuro de Aluminio de contenedores',
    'Retiro de Fosfuro de Aluminio en cobertor',
    'Retiro de nidos',
    'Retiro de plan de contingencia',
    'Retiro de servicio',
    'Reunión con cliente',
    'Visita a cliente'
  ];

  final ScrollController _scrollController = ScrollController();
  List<String> tareasSeleccionadas = [];
  String selectedTarea = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: const Text('Tareas'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(5)),
                child: DropdownButtonFormField(
                  padding: const EdgeInsets.only(left: 10),
                  hint: const Text('TAREAS'),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (value) {
                    setState(() {
                      selectedTarea = value!;
                    });
                  },
                  items: tareas.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          e,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  isDense: true,
                  isExpanded: true,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.white),
                          elevation: WidgetStatePropertyAll(10),
                          shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(50),
                                      right: Radius.circular(50))))),
                      onPressed: () {
                        if (selectedTarea.isNotEmpty) {
                          setState(() {
                            tareasSeleccionadas.add(selectedTarea);
                            selectedTarea = '';
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          });
                        }
                      },
                      child: Text(
                        'Agregar +',
                        style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      )),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: tareasSeleccionadas.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(tareasSeleccionadas[index]),
                      trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              tareasSeleccionadas.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.delete)),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider(
                      thickness: 3.0,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
