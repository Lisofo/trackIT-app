import 'dart:io';
import 'dart:typed_data';
import 'package:app_tec_sedel/models/incidencia.dart';
import 'package:app_tec_sedel/models/orden.dart';
import 'package:app_tec_sedel/models/revision_incidencia.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/providers/orden_provider.dart';
import 'package:app_tec_sedel/services/incidencia_services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';

class CameraGalleryScreen extends StatefulWidget {
  final bool fromRevisionMenu;
  final bool isReadOnly;
  
  const CameraGalleryScreen({
    super.key, 
    this.fromRevisionMenu = false,
    this.isReadOnly = false,
  });

  @override
  CameraGalleryScreenState createState() => CameraGalleryScreenState();
}

class CameraGalleryScreenState extends State<CameraGalleryScreen> {
  List<Uint8List> nuevasImagenes = [];
  List<IncidenciaAdjunto> adjuntosExistentes = [];
  
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isLoading = true;
  bool _isTakingPicture = false;
  String? _errorMessage;
  
  List<Incidencia> selectedObservations = [];
  List<Incidencia> observations = [];
  bool _isLoadingObservations = false;
  final TextEditingController commentController = TextEditingController();
  final IncidenciaServices _incidenciaServices = IncidenciaServices();
  
  late Orden orden;
  late String token;
  RevisionIncidencia? revisionIncidenciaExistente;
  bool _cargandoDatos = true;
  bool _enviandoDatos = false;
  
  bool isDropdownSearchOpen = false;

  // =========================
  // VALIDACIÓN DE ESTADO
  // =========================
  bool get _ordenPermiteEdicion {
    if (widget.fromRevisionMenu || widget.isReadOnly) {
      return false;
    }
    return orden.estado != 'PENDIENTE' && orden.estado != 'FINALIZADO';
  }

  void _mostrarErrorNoEdicion(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pueden modificar datos en modo de revisión.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarOrdenYToken();
  }

  void _cargarOrdenYToken() {
    final authProvider = context.read<AuthProvider>();
    final ordenProvider = context.read<OrdenProvider>();
    
    setState(() {
      orden = ordenProvider.orden;
      token = authProvider.token;
    });
    
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _cargandoDatos = true;
    });

    try {
      await _loadIncidencias();
      await _cargarRevisionIncidenciaExistente();
      
      if (revisionIncidenciaExistente != null) {
        await _cargarAdjuntosExistentes();
      }
      
      setState(() {
        _cargandoDatos = false;
      });
    } catch (e) {
      setState(() {
        _cargandoDatos = false;
        _errorMessage = "Error al cargar datos: $e";
      });
    }
  }

  Future<void> _cargarRevisionIncidenciaExistente() async {
    try {
      final revisiones = await _incidenciaServices.getRevisionIncidencia(context, orden, token);
      
      if (_incidenciaServices.statusCode == 1 && revisiones != null && revisiones.isNotEmpty) {
        RevisionIncidencia? revisionEncontrada;
        
        for (var revision in revisiones) {
          if (revision.ordenTrabajoId == orden.ordenTrabajoId && 
              revision.otRevisionId == orden.otRevisionId) {
            revisionEncontrada = revision;
            break;
          }
        }
        
        if (revisionEncontrada != null) {
          setState(() {
            revisionIncidenciaExistente = revisionEncontrada;
          });
          
          _cargarDatosDeRevision();
          await _cargarAdjuntosExistentes();
        }
      }
    } catch (e) {
      print("Error al cargar revisión de incidencia: $e");
    }
  }

  Future<void> _cargarAdjuntosExistentes() async {
    if (revisionIncidenciaExistente == null) return;
    
    try {
      final adjuntos = await _incidenciaServices.getAdjuntosPorRevisionIncidencia(
        context,
        revisionIncidenciaExistente!,
        token
      );
      
      if (adjuntos != null) {
        setState(() {
          adjuntosExistentes = adjuntos;
        });
      }
    } catch (e) {
      print("Error al cargar adjuntos: $e");
    }
  }

  void _cargarDatosDeRevision() {
    if (revisionIncidenciaExistente == null) return;
    
    commentController.text = revisionIncidenciaExistente!.observacion;
    
    if (revisionIncidenciaExistente!.incidenciaIds.isNotEmpty && observations.isNotEmpty) {
      final incidenciasSeleccionadas = observations.where(
        (incidencia) => revisionIncidenciaExistente!.incidenciaIds.contains(incidencia.incidenciaId)
      ).toList();
      
      setState(() {
        selectedObservations = incidenciasSeleccionadas;
      });
    }
  }

  Future<void> _loadIncidencias() async {
    setState(() {
      _isLoadingObservations = true;
    });

    try {
      final incidenciasList = await _incidenciaServices.getIncidencias(context, token);
      
      if (_incidenciaServices.statusCode == 1) {
        setState(() {
          observations = (incidenciasList as List).cast<Incidencia>();
          _isLoadingObservations = false;
        });
      } else {
        setState(() {
          _isLoadingObservations = false;
          _errorMessage = "Error al cargar las incidencias";
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingObservations = false;
        _errorMessage = "Error al cargar las incidencias: $e";
      });
    }
  }

  String _calcularMD5(Uint8List bytes) {
    return md5.convert(bytes).toString();
  }

  Future<File> _guardarImagenTemporal(Uint8List bytes, String extension) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}$extension');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<void> _uploadAllImages() async {
    // Validar estado de la orden
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    if (nuevasImagenes.isEmpty && selectedObservations.isEmpty && commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para enviar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _enviandoDatos = true;
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  if (nuevasImagenes.isNotEmpty)
                    Text("Enviando ${nuevasImagenes.length} imágenes..."),
                  if (selectedObservations.isNotEmpty)
                    Text("Con ${selectedObservations.length} incidencias"),
                  if (commentController.text.isNotEmpty)
                    const Text("Con comentario"),
                ],
              ),
            ),
          );
        },
      );

      RevisionIncidencia revisionIncidencia;
      
      if (revisionIncidenciaExistente == null) {
        revisionIncidencia = RevisionIncidencia(
          otIncidenciaId: 0,
          ordenTrabajoId: orden.ordenTrabajoId ?? 0,
          otRevisionId: orden.otRevisionId ?? 0,
          observacion: commentController.text,
          incidenciaIds: selectedObservations.map((inc) => inc.incidenciaId).toList(),
        );
        
        RevisionIncidencia? nuevaRevision = await _incidenciaServices.postRevisionIncidencia(
          context, orden, revisionIncidencia, token
        );
        
        if (_incidenciaServices.statusCode == 1 && nuevaRevision != null) {
          setState(() {
            revisionIncidenciaExistente = nuevaRevision;
          });
          revisionIncidencia = nuevaRevision;
        } else {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al crear la incidencia'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() { _enviandoDatos = false; });
          return;
        }
      } else {
        revisionIncidenciaExistente!.observacion = commentController.text;
        revisionIncidenciaExistente!.incidenciaIds = selectedObservations.map((inc) => inc.incidenciaId).toList();
        
        RevisionIncidencia? revisionActualizada = await _incidenciaServices.putRevisionIncidencia(
          context, orden, revisionIncidenciaExistente!, token
        );
        
        if (_incidenciaServices.statusCode == 1 && revisionActualizada != null) {
          setState(() {
            revisionIncidenciaExistente = revisionActualizada;
          });
          revisionIncidencia = revisionActualizada;
        } else {
          revisionIncidencia = revisionIncidenciaExistente!;
        }
      }

      if (_incidenciaServices.statusCode == 1 && revisionIncidencia.otIncidenciaId > 0 && nuevasImagenes.isNotEmpty) {
        List<String> erroresAdjuntos = [];
        
        for (int i = 0; i < nuevasImagenes.length; i++) {
          final imagen = nuevasImagenes[i];
          
          try {
            final tempFile = await _guardarImagenTemporal(imagen, '.jpg');
            final md5Hash = _calcularMD5(imagen);
            
            final adjunto = await _incidenciaServices.postAdjuntoIncidencia(
              context,
              orden,
              revisionIncidencia.otIncidenciaId,
              tempFile.path,
              md5Hash,
              token
            );
            
            if (adjunto != null) {
              setState(() {
                adjuntosExistentes.add(adjunto);
              });
            } else {
              erroresAdjuntos.add("Imagen ${i+1}");
            }
            
            await tempFile.delete();
          } catch (e) {
            erroresAdjuntos.add("Imagen ${i+1}: $e");
          }
        }
        
        setState(() {
          nuevasImagenes.clear();
        });
        
        if (erroresAdjuntos.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Algunas imágenes no se pudieron subir: ${erroresAdjuntos.join(", ")}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      Navigator.of(context).pop();

      if (_incidenciaServices.statusCode == 1) {
        String mensaje = "";
        if (nuevasImagenes.isNotEmpty) mensaje += "${nuevasImagenes.length} imágenes subidas exitosamente\n";
        if (selectedObservations.isNotEmpty) mensaje += "${selectedObservations.length} incidencias guardadas\n";
        if (commentController.text.isNotEmpty) mensaje += "Comentario guardado\n";
        mensaje += revisionIncidenciaExistente == null ? "Nueva incidencia creada" : "Incidencia actualizada";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar los datos'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _enviandoDatos = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _cameras = await availableCameras();
      _controller = CameraController(_cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al inicializar la cámara: $e";
      });
    }
  }

  Future<void> _openCamera() async {
    // Validar estado de la orden
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    await _initializeCamera();
    
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: _buildCameraScreen(),
        ),
      );
    });
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámara'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _safeDisposeCamera();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildCameraPreview(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "camera_btn_modal",
            onPressed: _ordenPermiteEdicion ? _takePicture : null,
            tooltip: 'Tomar foto',
            child: _isTakingPicture
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : const Icon(Icons.camera),
          ),
        ],
      ),
    );
  }

  void _safeDisposeCamera() {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  Future<void> _takePicture() async {
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;

    try {
      setState(() {
        _isTakingPicture = true;
        _errorMessage = null;
      });

      final XFile picture = await _controller!.takePicture();
      final Uint8List imageBytes = await File(picture.path).readAsBytes();

      await File(picture.path).delete();

      setState(() {
        nuevasImagenes.add(imageBytes);
        _isTakingPicture = false;
      });

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        _safeDisposeCamera();
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto tomada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
        _errorMessage = "Error al tomar la foto: $e";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al tomar la foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    // Validar estado de la orden
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await File(image.path).readAsBytes();
        setState(() {
          nuevasImagenes.add(imageBytes);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen agregada desde galería'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error al seleccionar imagen: $e";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al seleccionar imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(int index) {
    // Validar estado de la orden
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar imagen'),
          content: const Text('¿Estás seguro de que quieres eliminar esta imagen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteImage(index);
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Imagen eliminada'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteImage(int index) {
    // Validar estado de la orden
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    setState(() {
      nuevasImagenes.removeAt(index);
    });
  }

  void _deleteAdjunto(int index) async {
    // Validar estado de la orden
    if (!_ordenPermiteEdicion) {
      _mostrarErrorNoEdicion(context);
      return;
    }

    final adjunto = adjuntosExistentes[index];
    final incidenciaId = revisionIncidenciaExistente?.otIncidenciaId;
    
    if (incidenciaId == null || incidenciaId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar del servidor: incidencia no encontrada.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Capturamos el contexto de la pantalla
    final screenContext = context;

    showDialog(
      context: screenContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar adjunto'),
          content: const Text('¿Estás seguro de que quieres eliminar este adjunto del servidor?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Cerramos el diálogo de confirmación
                Navigator.of(dialogContext).pop();
                
                // Mostramos progreso usando el contexto de pantalla
                showDialog(
                  context: screenContext,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
                
                final success = await _incidenciaServices.deleteAdjuntoIncidencia(
                  screenContext,
                  orden,
                  incidenciaId,
                  adjunto.filename,
                  token,
                );
                
                if (!mounted) return;
                
                // Cerramos progreso usando rootNavigator sobre el contexto de pantalla
                Navigator.of(screenContext, rootNavigator: true).pop();
                  
                if (success && _incidenciaServices.statusCode == 1) {
                  setState(() {
                    adjuntosExistentes.removeAt(index);
                  });
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(
                      content: Text('Adjunto eliminado exitosamente.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(
                      content: Text('Error al eliminar el adjunto del servidor.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _openImageCarousel() {
    final totalImagenes = nuevasImagenes.length + adjuntosExistentes.length;
    
    if (totalImagenes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imágenes para mostrar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<CarouselImageItem> items = [];
    
    for (var imagen in nuevasImagenes) {
      items.add(CarouselImageItem(imagenBytes: imagen, isLocal: true));
    }
    
    for (var adjunto in adjuntosExistentes) {
      items.add(CarouselImageItem(
        imageUrl: adjunto.filepath, 
        isLocal: false,
        adjunto: adjunto,
      ));
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageCarouselScreen(
          items: items,
          allowDelete: _ordenPermiteEdicion,
          onDeleteLocalImage: (index) {
            if (index < nuevasImagenes.length) {
              setState(() {
                nuevasImagenes.removeAt(index);
              });
            }
          },
          onDeleteRemoteImage: (adjunto) async {
            final incidenciaId = revisionIncidenciaExistente?.otIncidenciaId;
            if (incidenciaId == null || incidenciaId == 0) {
              return false;
            }
            
            final success = await _incidenciaServices.deleteAdjuntoIncidencia(
              context,
              orden,
              incidenciaId,
              adjunto.filename,
              token,
            );
            
            if (success && _incidenciaServices.statusCode == 1) {
              setState(() {
                adjuntosExistentes.removeWhere((a) => a.filename == adjunto.filename);
              });
              return true;
            }
            return false;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _safeDisposeCamera();
    commentController.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Inicializando cámara...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Error con la cámara',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Cámara no disponible'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        CameraPreview(_controller!),
        if (_isTakingPicture)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  SizedBox(height: 16),
                  Text(
                    'Procesando imagen...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildObservationsDropdown() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incidencias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_isLoadingObservations)
              const Center(child: CircularProgressIndicator())
            else if (observations.isEmpty)
              const Text(
                'No hay incidencias disponibles',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              DropdownSearch<Incidencia>.multiSelection(
                enabled: _ordenPermiteEdicion, // Habilitar/deshabilitar según estado
                dropdownBuilder: (context, selectedItems) {
                  return Text(
                    selectedItems.isEmpty
                        ? 'Selecciona incidencias'
                        : '${selectedItems.length} incidencia(s) seleccionada(s)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  );
                },
                popupProps: PopupPropsMultiSelection.menu(
                  isFilterOnline: true,
                  showSelectedItems: true,
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Buscar incidencias...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  menuProps: const MenuProps(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  itemBuilder: (context, item, isSelected) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.descripcion,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected 
                                      ? Theme.of(context).primaryColor 
                                      : Colors.black,
                                    fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                  ),
                                ),
                                if (item.codIncidencia.isNotEmpty)
                                  Text(
                                    'Código: ${item.codIncidencia}',                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: 'Selecciona incidencias',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  baseStyle: const TextStyle(fontSize: 14),
                ),
                items: observations,
                selectedItems: selectedObservations,
                onChanged: (List<Incidencia>? newValues) {
                  if (!_ordenPermiteEdicion) {
                    _mostrarErrorNoEdicion(context);
                    return;
                  }
                  
                  if (newValues != null) {
                    setState(() {
                      selectedObservations = newValues;
                    });
                  }
                },
                clearButtonProps: const ClearButtonProps(
                  isVisible: true,
                  icon: Icon(Icons.clear, size: 20),
                  tooltip: 'Borrar seleccion'
                ),
                compareFn: (item1, item2) => item1.incidenciaId == item2.incidenciaId,
              ),
            
            if (selectedObservations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: selectedObservations.map((incidencia) {
                  return Chip(
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incidencia.descripcion,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
              ),
            ],
            
            if (!_isLoadingObservations && observations.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${selectedObservations.length}/${observations.length} seleccionadas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            
            if (_errorMessage != null)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _loadIncidencias,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentField() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comentario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              maxLines: 3,
              enabled: _ordenPermiteEdicion, // Habilitar/deshabilitar según estado
              decoration: const InputDecoration(
                hintText: 'Escribe tu comentario aquí...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjuntoExistente(int index) {
    final adjunto = adjuntosExistentes[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          adjunto.filepath,
          headers: {'Authorization': token},
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    adjunto.filename.length > 15 
                      ? '${adjunto.filename.substring(0, 12)}...' 
                      : adjunto.filename,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        if (_ordenPermiteEdicion) // Solo mostrar botón de eliminar si se permite edición
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () => _deleteAdjunto(index),
              ),
            ),
          ),
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_done, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    adjunto.filename.length > 15 
                      ? '${adjunto.filename.substring(0, 12)}...' 
                      : adjunto.filename,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNuevaImagen(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          nuevasImagenes[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey,
            child: const Icon(Icons.error),
          ),
        ),
        if (_ordenPermiteEdicion) // Solo mostrar botón de eliminar si se permite edición
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () => _showDeleteConfirmation(index),
              ),
            ),
          ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload, size: 12, color: Colors.white),
                SizedBox(width: 2),
                Text('Nueva', style: TextStyle(fontSize: 10, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    final totalImagenes = nuevasImagenes.length + adjuntosExistentes.length;
    
    if (totalImagenes == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay imágenes',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Toma algunas fotos para verlas aquí',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalImagenes,
      itemBuilder: (context, index) {
        if (index < nuevasImagenes.length) {
          return _buildNuevaImagen(index);
        } else {
          final adjuntoIndex = index - nuevasImagenes.length;
          return _buildAdjuntoExistente(adjuntoIndex);
        }
      },
    );
  }

  Widget _buildCarouselButton() {
    final totalImagenes = nuevasImagenes.length + adjuntosExistentes.length;
    
    if (totalImagenes == 0) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _openImageCarousel,
        icon: const Icon(Icons.slideshow),
        label: Text('Ver Carrusel ($totalImagenes imágenes)'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    if (_cargandoDatos) {
      Widget contenido = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando datos...'),
          ],
        ),
      );

      // Si viene del menú de revisión, NO mostrar Scaffold con AppBar
      if (widget.fromRevisionMenu) {
        return contenido;
      }

      return Scaffold(
        appBar: AppBar(
          foregroundColor: colors.onPrimary,
          title: const Text('Cámara e Incidencias'),
        ),
        body: contenido,
      );
    }

    // Construir el contenido principal
    Widget contenido = SingleChildScrollView(
      child: Column(
        children: [
          _buildObservationsDropdown(),
          _buildCommentField(),
          _buildCarouselButton(),
          
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Galería de Imágenes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text('${nuevasImagenes.length}', style: const TextStyle(fontSize: 12)),
                  ),
                  label: const Text('Nuevas'),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text('${adjuntosExistentes.length}', style: const TextStyle(fontSize: 12)),
                  ),
                  label: const Text('Subidas'),
                ),
                Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text('${selectedObservations.length}', style: const TextStyle(fontSize: 12)),
                  ),
                  label: const Text('Incidencias'),
                ),
              ],
            ),
          ),
          
          _buildImageGrid(),
          const SizedBox(height: 100),
        ],
      ),
    );

    // Si viene del menú de revisión, NO mostrar Scaffold con AppBar
    if (widget.fromRevisionMenu) {
      return SafeArea(
        child: contenido,
      );
    }

    // Si es acceso directo, mostrar el Scaffold completo
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: colors.onPrimary,
          title: const Text('Cámara e Incidencias'),
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: (_enviandoDatos || !_ordenPermiteEdicion) ? null : _uploadAllImages,
              tooltip: 'Enviar datos',
            ),
          ],
        ),
        body: contenido,
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "gallery_btn",
              onPressed: _ordenPermiteEdicion ? _pickImageFromGallery : null,
              mini: true,
              tooltip: 'Abrir galería',
              child: const Icon(Icons.photo_library),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: "camera_btn",
              onPressed: _ordenPermiteEdicion ? _openCamera : null,
              tooltip: 'Abrir cámara',
              child: const Icon(Icons.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class CarouselImageItem {
  final Uint8List? imagenBytes;
  final String? imageUrl;
  final bool isLocal;
  final IncidenciaAdjunto? adjunto;
  
  CarouselImageItem({
    this.imagenBytes,
    this.imageUrl,
    required this.isLocal,
    this.adjunto,
  });
}

class ImageCarouselScreen extends StatefulWidget {
  final List<CarouselImageItem> items;
  final bool allowDelete;
  final Function(int)? onDeleteLocalImage;
  final Future<bool> Function(IncidenciaAdjunto adjunto)? onDeleteRemoteImage;

  const ImageCarouselScreen({
    super.key,
    required this.items,
    required this.allowDelete,
    this.onDeleteLocalImage,
    this.onDeleteRemoteImage,
  });

  @override
  State<ImageCarouselScreen> createState() => _ImageCarouselScreenState();
}

class _ImageCarouselScreenState extends State<ImageCarouselScreen> {
  late int currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    // Validar si se permite eliminar
    if (!widget.allowDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden modificar datos en modo de revisión.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Usamos el contexto pasado por parámetro que es el del builder del FloatingActionButton
    final screenContext = context;
    final item = widget.items[index];
    
    showDialog(
      context: screenContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar imagen'),
          content: Text(
            item.isLocal 
              ? '¿Estás seguro de que quieres eliminar esta imagen?'
              : '¿Estás seguro de que quieres eliminar este adjunto del servidor?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteImage(index);
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteImage(int index) {
    // Validar si se permite eliminar
    if (!widget.allowDelete) {
      return;
    }

    final item = widget.items[index];
    final screenContext = context; // Contexto de ImageCarouselScreen
    
    if (!item.isLocal && item.adjunto != null && widget.onDeleteRemoteImage != null) {
      showDialog(
        context: screenContext,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Eliminar adjunto'),
            content: const Text('¿Estás seguro de que quieres eliminar este adjunto del servidor?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  // Cerramos el diálogo de confirmación
                  Navigator.of(dialogContext).pop();
                  
                  // Mostrar indicador de progreso
                  showDialog(
                    context: screenContext,
                    barrierDismissible: false,
                    builder: (BuildContext loadingContext) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );
                  
                  final success = await widget.onDeleteRemoteImage!(item.adjunto!);
                  
                  if (!mounted) return;
                  
                  // Cerrar indicador usando rootNavigator sobre el contexto de pantalla
                  Navigator.of(screenContext, rootNavigator: true).pop();
                    
                  if (success) {
                    if (widget.onDeleteLocalImage != null) {
                      widget.onDeleteLocalImage!(index);
                    }
                    
                    setState(() {
                      widget.items.removeAt(index);
                    });

                    if (widget.items.isEmpty) {
                      Navigator.of(screenContext).pop();
                      return;
                    }

                    if (index >= widget.items.length) {
                      currentIndex = widget.items.length - 1;
                    }

                    if (widget.items.isNotEmpty) {
                      _pageController.jumpToPage(currentIndex);
                    }

                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(
                        content: Text('Adjunto eliminado exitosamente.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(
                        content: Text('Error al eliminar el adjunto del servidor.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } else {
      // Borrado local simple
      if (widget.onDeleteLocalImage != null && item.isLocal) {
        widget.onDeleteLocalImage!(index);
      }
      
      setState(() {
        widget.items.removeAt(index);
      });

      if (widget.items.isEmpty) {
        Navigator.of(screenContext).pop();
        return;
      }

      if (index >= widget.items.length) {
        currentIndex = widget.items.length - 1;
      }

      if (widget.items.isNotEmpty) {
        _pageController.jumpToPage(currentIndex);
      }

      ScaffoldMessenger.of(screenContext).showSnackBar(
        SnackBar(
          content: Text(item.isLocal 
            ? 'Imagen eliminada' 
            : 'Adjunto removido localmente'),
          backgroundColor: item.isLocal ? Colors.orange : Colors.blue,
        ),
      );
    }
  }

  ImageProvider _buildImageProvider(CarouselImageItem item) {
    if (item.isLocal && item.imagenBytes != null) {
      return MemoryImage(item.imagenBytes!);
    } else if (!item.isLocal && item.imageUrl != null) {
      return NetworkImage(item.imageUrl!);
    }
    return const AssetImage('assets/placeholder.png');
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Imagen ${currentIndex + 1} de ${widget.items.length}',
          style: TextStyle(
            color: colores.onPrimary,
          ),
        ),
        backgroundColor: colores.primary,
        iconTheme: IconThemeData(
          color: colores.onPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.items.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.98,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PhotoViewGallery.builder(
                    itemCount: widget.items.length,
                    builder: (context, index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: _buildImageProvider(widget.items[index]),
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 3.0,
                        heroAttributes: PhotoViewHeroAttributes(tag: index),
                      );
                    },
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    pageController: _pageController,
                    scrollPhysics: const BouncingScrollPhysics(),
                    backgroundDecoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.items.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      _scrollToIndex(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Container(
                        width: 16.0,
                        height: 16.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == index 
                            ? (widget.items[index].isLocal ? Colors.orange : Colors.green)
                            : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.items[currentIndex].isLocal 
                    ? Colors.orange.withOpacity(0.1) 
                    : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.items[currentIndex].isLocal 
                        ? Icons.cloud_upload 
                        : Icons.cloud_done,
                      color: widget.items[currentIndex].isLocal ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.items[currentIndex].isLocal 
                        ? 'Imagen nueva (no subida)' 
                        : 'Adjunto en servidor',
                      style: TextStyle(
                        color: widget.items[currentIndex].isLocal ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),
                    Icon(Icons.photo_library, size: 64, color: Colors.grey),
                    SizedBox(height: 20),
                    Text('No hay imágenes para mostrar'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: widget.items.isNotEmpty && widget.allowDelete
          ? Builder(
              builder: (buttonContext) => FloatingActionButton(
                onPressed: () {
                  _showDeleteConfirmation(buttonContext, currentIndex);
                },
                backgroundColor: widget.items[currentIndex].isLocal ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                child: const Icon(Icons.delete),
              ),
            )
          : null,
    );
  }
}