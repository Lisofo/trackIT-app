// filtros_ordenes.dart
import 'package:app_tec_sedel/delegates/cliente_search_delegate.dart';
import 'package:app_tec_sedel/delegates/unidad_search_delegate.dart';
import 'package:app_tec_sedel/services/unidades_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_tec_sedel/models/cliente.dart';
import 'package:app_tec_sedel/models/unidad.dart';
import 'package:app_tec_sedel/services/client_services.dart';

class FiltrosOrdenes extends StatefulWidget {
  final Function(
    int? clienteId,
    int? unidadId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? numeroOrden, // Agregar este parámetro
  ) onSearch;
  final Function onReset;
  final bool isFilterExpanded;
  final Function(bool) onToggleFilter;
  final int cantidadDeOrdenes;
  final String token;

  const FiltrosOrdenes({
    super.key,
    required this.onSearch,
    required this.onReset,
    required this.isFilterExpanded,
    required this.onToggleFilter,
    required this.cantidadDeOrdenes,
    required this.token,
  });

  @override
  State<FiltrosOrdenes> createState() => _FiltrosOrdenesState();
}

class _FiltrosOrdenesState extends State<FiltrosOrdenes> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  Cliente? _selectedCliente;
  Unidad? _selectedUnidad;
  final TextEditingController _numeroOrdenController = TextEditingController();
  final ClientServices _clientService = ClientServices();
  final UnidadesServices _unidadService = UnidadesServices();

  @override
  void dispose() {
    _numeroOrdenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              widget.onToggleFilter(!widget.isFilterExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_hasActiveFilters())
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.cantidadDeOrdenes == 0 ? '' : widget.cantidadDeOrdenes.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.isFilterExpanded 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: widget.isFilterExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.isFilterExpanded ? 1.0 : 0.0,
              child: widget.isFilterExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        const Divider(),
                        TextFormField(
                          controller: _numeroOrdenController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Orden',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.search),
                            hintText: 'Ingrese número de orden...',
                          ),
                          keyboardType: TextInputType.number,
                          onFieldSubmitted: (value) {
                            // Buscar automáticamente al escribir (opcional)
                            print(value);
                            _handleSearch();
                          },
                        ),
                        const SizedBox(height: 15),
                        // Selector de Cliente
                        InkWell(
                          onTap: _mostrarBusquedaCliente,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.search),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCliente != null 
                                      ? '${_selectedCliente!.nombre} ${_selectedCliente!.nombreFantasia}'
                                      : 'Buscar cliente...',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _selectedCliente != null ? Colors.blue : null,
                                      fontWeight: _selectedCliente != null ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                                if (_selectedCliente != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() => _selectedCliente = null);
                                      _handleSearch();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Selector de Unidad
                        InkWell(
                          onTap: _mostrarBusquedaUnidad,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.search),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedUnidad != null 
                                      ? _selectedUnidad!.matricula
                                      : 'Buscar unidad...',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: _selectedUnidad != null ? Colors.blue : null,
                                      fontWeight: _selectedUnidad != null ? FontWeight.bold : null,
                                    ),
                                  ),
                                ),
                                if (_selectedUnidad != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() => _selectedUnidad = null);
                                      _handleSearch();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Selectores de Fecha
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fecha Desde',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _fechaDesde != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _fechaDesde = null;
                                            });
                                          },
                                        )
                                      : const Icon(Icons.calendar_today, size: 18),
                                  ),
                                  child: Text(
                                    _fechaDesde != null 
                                      ? DateFormat('dd/MM/yyyy').format(_fechaDesde!)
                                      : 'Seleccionar fecha',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectDate(context, false),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Fecha Hasta',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: _fechaHasta != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _fechaHasta = null;
                                            });
                                          },
                                        )
                                      : const Icon(Icons.calendar_today, size: 18),
                                  ),
                                  child: Text(
                                    _fechaHasta != null 
                                      ? DateFormat('dd/MM/yyyy').format(_fechaHasta!)
                                      : 'Seleccionar fecha',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Botones
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetFilters,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('LIMPIAR'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleSearch,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: colors.primary,
                                ),
                                child: const Text(
                                  'BUSCAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _fechaDesde != null ||
          _fechaHasta != null ||
          _selectedCliente != null ||
          _selectedUnidad != null ||
          _numeroOrdenController.text.isNotEmpty; // Agregar esta condición
  }

  Future<void> _selectDate(BuildContext context, bool isDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
    }
  }

  void _mostrarBusquedaCliente() async {
    final Cliente? resultado = await showSearch<Cliente>(
      context: context,
      delegate: ClienteSearchDelegate(
        token: widget.token,
        clientService: _clientService,
      ),
    );

    if (resultado != null && resultado.clienteId > 0) {
      setState(() {
        _selectedCliente = resultado;
      });
      _handleSearch();
    }
  }

  void _mostrarBusquedaUnidad() async {
    final Unidad? resultado = await showSearch<Unidad>(
      context: context,
      delegate: UnidadSearchDelegate(
        token: widget.token,
        unidadService: _unidadService,
      ),
    );

    if (resultado != null && resultado.unidadId > 0) {
      setState(() {
        _selectedUnidad = resultado;
      });
      _handleSearch();
    }
  }

   void _handleSearch() {
    String? numeroOrden;
    if (_numeroOrdenController.text.isNotEmpty) {
      numeroOrden = _numeroOrdenController.text;
    }

    widget.onSearch(
      _selectedCliente?.clienteId,
      _selectedUnidad?.unidadId,
      _fechaDesde,
      _fechaHasta,
      numeroOrden, // Agregar este parámetro
    );
  }

  void _resetFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _selectedCliente = null;
      _selectedUnidad = null;
      _numeroOrdenController.clear(); // Limpiar el campo
    });
    widget.onReset();
  }
}