import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/userNormal/serviceuser/firebase_storage_service.dart';
import 'package:plataformacnbbbjo/util/responsive.dart';

/// Pantalla donde el usuario puede subir un documento PDF como evidencia
/// de haber completado un curso o subcurso específico.
/// El archivo se sube a Firebase Storage y se asocia con los datos del curso,
/// trimestre, dependencia, e identificación del curso.
class CursosNormal extends StatefulWidget {
  /// Nombre del curso principal.
  final String course;
  /// Nombre del subcurso (opcional).
  final String? subCourse;
  /// Trimestre al que pertenece el curso.
  final String trimester;
  /// Dependencia relacionada con el curso.
  final String dependecy;
  /// ID único del curso.
  final String idCurso;
  final String nomenclatura;

  /// Constructor del widget `CursosNormal`.
  const CursosNormal({
    required this.course,
    this.subCourse,
    required this.trimester,
    required this.dependecy,
    required this.idCurso,
    required this.nomenclatura,
    super.key, 
  });

  @override
  State<CursosNormal> createState() => _CursosNormalState();
}

/// Estado asociado a la pantalla `CursosNormal`.
/// Controla el proceso de subida del archivo PDF, incluyendo
/// la barra de progreso y el manejo del estado de carga.
class _CursosNormalState extends State<CursosNormal> {
  /// Servicio que maneja la subida de archivos a Firebase Storage.
  final FirebaseStorageService _storageService = FirebaseStorageService();
  /// Usuario actualmente autenticado.
  User? user;
  /// Indica si un archivo se está subiendo actualmente.
  bool isUploading = false;
  /// Progreso de subida del archivo (de 0.0 a 1.0).
  double uploadProgress = 0.0;
  // Valor que indica si el curso esta en revisión
    bool hasPendingFile = false;

  /// Inicializa el estado obteniendo el usuario actual.
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _checkPendingFile(); // Carga la consulta para deshabilitar el curso si esta en revisión.
  }

    // Método que devuelve un true si es que hay un documento pendiente 'en revisión'.
    Future<void> _checkPendingFile() async {
    if (user != null) {
      bool pending = await _storageService.tieneArchivoPendiente(
        idCurso: widget.idCurso,
        uid: user!.uid,
      );
      setState(() {
        hasPendingFile = pending;
      });
    }
  }

  /// Método que inicia el proceso de selección y subida de un archivo PDF.
  /// Actualiza la barra de progreso en tiempo real mediante un callback.
  Future<void> _uploadPDF() async {
    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    await _storageService.subirArchivo(
      context: context,
      trimester: widget.trimester,
      dependency: widget.dependecy,
      course: widget.course,
      idCurso: widget.idCurso,
      nomenclatura: widget.nomenclatura,
      subCourse: widget.subCourse,
      onProgress: (progress) {
        setState(() {
          uploadProgress = progress;
        });
      },
    );

    setState(() {
      isUploading = false;
    });

    // Después de subir un documento, se vuelve a verificar si hay archivos pendientes
    await _checkPendingFile();
  }

  /// Construye la interfaz visual de la pantalla.
  /// Incluye el mensaje descriptivo, la barra de progreso (si aplica)
  /// y un botón para subir el archivo PDF.
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.subCourse != null
          ? 'Subir Documento: ${widget.course} > ${widget.subCourse}'
          : 'Subir Documento: ${widget.course}'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            color: Colors.yellow[100],
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: pantone872c, width: 1.5),
            ),
            child: Padding(
              padding:  EdgeInsets.all(12.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text: widget.subCourse != null
                          ? 'Sube la evidencia del curso en formato PDF para ${widget.trimester}, Dependencia: ${widget.dependecy}.\n\n'
                          : 'Sube un documento PDF para el curso seleccionado (${widget.course}).\n\n',
                    ),
                    const TextSpan(
                      text: '📄 El nombre del archivo debe ser:\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    TextSpan(
                      text: widget.nomenclatura,
                      style: TextStyle(
                        backgroundColor: Color.fromARGB(255, 155, 34, 71),
                        color: light,
                        fontWeight: FontWeight.w500,
                        fontSize: responsiveFontSize(context, 16)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Barra de progreso
          if (isUploading)
            Column(
              children: [
                LinearProgressIndicator(value: uploadProgress),
                const SizedBox(height: 10),
                Text('${(uploadProgress * 100).toStringAsFixed(0)}%'),
              ],
            ),

          const SizedBox(height: 20),

          // Botón de subida
          ElevatedButton.icon(
            onPressed: (isUploading || hasPendingFile) ? null : _uploadPDF, // Deshabilita si está subiendo o el curso esta en estado 'Pendiente'
            icon: const Icon(Icons.upload_file, color: greenColorLight),
            label: Text( hasPendingFile ? 'En revisión' : 'Seleccionar y Subir PDF', style: TextStyle(color: greenColorDark),),
          ),
        ],
      ),
    ),
  );
}
}