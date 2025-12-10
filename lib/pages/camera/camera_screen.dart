import 'dart:io';
import 'dart:typed_data';
import 'package:app_tec_sedel/models/incidencia.dart';
import 'package:app_tec_sedel/providers/auth_provider.dart';
import 'package:app_tec_sedel/services/incidencia_services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:provider/provider.dart';

class CameraGalleryScreen extends StatefulWidget {
  const CameraGalleryScreen({super.key});

  @override
  CameraGalleryScreenState createState() => CameraGalleryScreenState();
}

class CameraGalleryScreenState extends State<CameraGalleryScreen> {
  List<Uint8List> images = [];
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isLoading = true;
  bool _isTakingPicture = false;
  String? _errorMessage;
  
  // Variables para incidencias
  List<Incidencia> selectedObservations = [];
  List<Incidencia> observations = [];
  bool _isLoadingObservations = false;
  final TextEditingController commentController = TextEditingController();
  final IncidenciaServices _incidenciaServices = IncidenciaServices();
  
  // Nueva variable para dropdown_search
  bool isDropdownSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    // Cargar las incidencias al inicializar
    _loadIncidencias();
  }

  // Método para cargar incidencias desde el servicio
  Future<void> _loadIncidencias() async {
    setState(() {
      _isLoadingObservations = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      
      final incidenciasList = await _incidenciaServices.getIncidencias(context, token);
      
      if (_incidenciaServices.statusCode == 1) {
        setState(() {
          observations = incidenciasList ?? [];
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
    await _initializeCamera();
    
    if (!mounted) return;
    
    // Esperar un frame para asegurar que la cámara esté inicializada
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
            onPressed: _takePicture,
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
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;

    try {
      setState(() {
        _isTakingPicture = true;
        _errorMessage = null;
      });

      final XFile picture = await _controller!.takePicture();
      final Uint8List imageBytes = await File(picture.path).readAsBytes();

      // Eliminar el archivo temporal de la cámara
      await File(picture.path).delete();

      setState(() {
        images.add(imageBytes);
        _isTakingPicture = false;
      });

      // Esperar a que se complete la actualización del estado antes de cerrar
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
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final Uint8List imageBytes = await File(image.path).readAsBytes();
        setState(() {
          images.add(imageBytes);
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
    setState(() {
      images.removeAt(index);
    });
  }

  Future<void> _uploadAllImages() async {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imágenes para enviar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Preparar datos de incidencias
    selectedObservations
        .map((incidencia) => incidencia.toMap())
        .toList();
    
    final String comentario = commentController.text;

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
                  Text("Enviando ${images.length} imágenes..."),
                  if (selectedObservations.isNotEmpty)
                    Text("Con ${selectedObservations.length} incidencias"),
                  if (comentario.isNotEmpty)
                    Text("Con comentario: ${comentario.length > 30 ? '${comentario.substring(0, 30)}...' : comentario}"),
                ],
              ),
            ),
          );
        },
      );

      // Simular envío a API (reemplaza con tu lógica real)
      // Aquí puedes enviar: images, incidenciasData, y comentario
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${images.length} imágenes enviadas exitosamente'),
              if (selectedObservations.isNotEmpty)
                Text('${selectedObservations.length} incidencias asociadas'),
              if (comentario.isNotEmpty)
                const Text('Comentario incluido'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para abrir el carrusel de imágenes
  void _openImageCarousel() {
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imágenes para mostrar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageCarouselScreen(
          images: images,
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
              // DropdownSearch con selección múltiple usando Incidencia
              DropdownSearch<Incidencia>.multiSelection(
                dropdownBuilder: (context, selectedItems) {
                  return Text(
                    'Selecciona incidencias',
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
                  // Personalizar el ítem con checkbox
                  itemBuilder: (context, item, isSelected) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) {},
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                    'Código: ${item.codIncidencia}',
                                    style: TextStyle(
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
                  // Animación al abrir/cerrar
                  containerBuilder: (context, popupWidget) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: isDropdownSearchOpen 
                        ? MediaQuery.of(context).size.height * 0.5 
                        : null,
                      child: popupWidget,
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
                  if (newValues != null) {
                    setState(() {
                      selectedObservations = newValues;
                    });
                  }
                },
                validator: (List<Incidencia>? value) {
                  if (selectedObservations.isEmpty) {
                    return 'Por favor selecciona al menos una incidencia';
                  }
                  return null;
                },
                clearButtonProps: const ClearButtonProps(
                  isVisible: true,
                  icon: Icon(Icons.clear, size: 20),
                  tooltip: 'Borrar seleccion'
                ),
                compareFn: (item1, item2) => item1.incidenciaId == item2.incidenciaId,
              ),
            
            // Mostrar chips con las incidencias seleccionadas
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
            
            // Contador de selecciones
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
            
            // Botón para recargar incidencias
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

  Widget _buildImageGrid() {
    if (images.isEmpty) {
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
      itemCount: images.length,
      itemBuilder: (context, index) => Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey,
              child: const Icon(Icons.error),
            ),
          ),
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
        ],
      ),
    );
  }

  // NUEVO MÉTODO PARA CONSTRUIR EL BOTÓN DEL CARRUSEL
  Widget _buildCarouselButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _openImageCarousel,
        icon: const Icon(Icons.slideshow),
        label: const Text('Ver Carrusel de Imágenes'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: colors.onPrimary,
          title: const Text('Cámara y Galería'),
          actions: [
            if (images.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.cloud_upload),
                onPressed: _uploadAllImages,
                tooltip: 'Enviar todas las imágenes',
              ),
          ],
        ),
        body: SingleChildScrollView(
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
              _buildImageGrid(),
              const SizedBox(height: 100), // Espacio extra para el FAB
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "gallery_btn",
              onPressed: _pickImageFromGallery,
              mini: true,
              tooltip: 'Abrir galería',
              child: const Icon(Icons.photo_library),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: "camera_btn",
              onPressed: _openCamera,
              tooltip: 'Abrir cámara',
              child: const Icon(Icons.camera),
            ),
          ],
        ),
      ),
    );
  }
}

// NUEVA PANTALLA PARA EL CARRUSEL DE IMÁGENES BASADA EN TU CÓDIGO
class ImageCarouselScreen extends StatefulWidget {
  final List<Uint8List> images;

  const ImageCarouselScreen({
    super.key,
    required this.images,
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
                Navigator.of(context).pop();
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
    // Actualizar el estado local
    setState(() {
      widget.images.removeAt(index);
    });

    // Si era la última imagen, regresar a la pantalla anterior
    if (widget.images.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    // Ajustar el índice actual si es necesario
    if (index >= widget.images.length) {
      currentIndex = widget.images.length - 1;
    }

    // Notificar al PageController
    if (widget.images.isNotEmpty) {
      _pageController.jumpToPage(currentIndex);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen eliminada'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Imagen ${currentIndex + 1} de ${widget.images.length}',
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
            if (widget.images.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.98,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PhotoViewGallery.builder(
                    itemCount: widget.images.length,
                    builder: (context, index) {
                      return PhotoViewGalleryPageOptions(
                        imageProvider: MemoryImage(widget.images[index]),
                        minScale: PhotoViewComputedScale.contained * 0.8,
                        maxScale: PhotoViewComputedScale.covered * 3.0,
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
                children: List.generate(widget.images.length, (index) {
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
                          color: currentIndex == index ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
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
      floatingActionButton: widget.images.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _showDeleteConfirmation(context, currentIndex);
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(Icons.delete),
            )
          : null,
    );
  }
}