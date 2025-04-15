import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:plataformacnbbbjo/userNormal/serviceuser/firebase_storage_service.dart';

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

  /// Constructor del widget `CursosNormal`.
  const CursosNormal({
    required this.course,
    this.subCourse,
    required this.trimester,
    required this.dependecy,
    required this.idCurso,
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

  /// Inicializa el estado obteniendo el usuario actual.
  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
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
            Text(
              widget.subCourse != null
                  ? 'Sube la evidencia del curso en formato PDF para ${widget.trimester}, Dependencia: ${widget.dependecy}.'
                  : 'Sube un documento PDF para el curso seleccionado (${widget.course}). \n El nombre del archivo debe ser: Constancia_NombreCurso_ApellidoPaterno_ApellidoMaterno_Nombres_Adscripcion',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
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
             
              onPressed: isUploading ? null : _uploadPDF, // Deshabilita si está subiendo
              icon: const Icon(Icons.upload_file, color: greenColorLight,),     
              label: const Text('Seleccionar y Subir PDF',
              style: TextStyle(
              color: greenColorLight, ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
