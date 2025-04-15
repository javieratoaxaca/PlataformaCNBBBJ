import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/pages/documents/firebaseservice.dart';

/// Página que muestra la lista de archivos subidos por los usuarios
/// para un curso específico.
/// Esta clase permite al administrador visualizar los archivos
/// asociados a un curso, dependencia y trimestre, y también descargar cada archivo.
class FilesListPage extends StatefulWidget {
  /// Nombre del curso del cual se desean visualizar los archivos.
  final String courseName;
  /// Nombre de la dependencia a la que pertenece el curso. 
  final String dependency;
  /// Trimestre al que corresponde el curso.
  final String trimester;

  /// Constructor para inicializar la vista con los datos requeridos.
  const FilesListPage({
    super.key,
    required this.courseName,
    required this.dependency,
    required this.trimester,
  });

  @override
  State<FilesListPage> createState() => _FilesListPageState();
}
class _FilesListPageState extends State<FilesListPage> {
  /// Servicio para interactuar con Firebase (obtener y descargar archivos).
  final FirebaseService _firebaseService = FirebaseService();
  /// Mapa que almacena el nombre del archivo como clave y la URL como valor.
  Map<String, String> files = {};
  /// Indica si se están cargando los archivos.
  bool isLoading = true;

  /// Inicializa el estado y comienza la carga de archivos del curso.
  @override
  void initState() {
    super.initState();
    _loadFiles();
    
  }

  /// Carga los archivos del curso desde Firebase y actualiza el estado de la vista.
  Future<void> _loadFiles() async {
    files = await _firebaseService.getCourseFiles(
        widget.trimester, widget.dependency, widget.courseName);
    setState(() => isLoading = false);
  }
  
  /// Descarga un archivo desde su URL.
  /// Se utiliza cuando el usuario presiona el botón de descarga.
  Future<void> _downloadFile(String fileUrl) async {
    await _firebaseService.downloadFile(fileUrl);
  }

  /// Construye la interfaz de usuario que muestra la lista de archivos.
  /// Muestra un indicador de carga mientras se obtienen los archivos,
  /// un mensaje si no hay archivos disponibles,
  /// o una lista de archivos con opción para descargarlos.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archivos de ${widget.courseName}'),
        //backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : files.isEmpty
              ? const Center(
                  child: Text('No hay archivos disponibles.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    String fileName = files.keys.elementAt(index);
                    String fileUrl = files[fileName]!;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        title: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          tooltip: 'Descargar',
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadFile(fileUrl),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
