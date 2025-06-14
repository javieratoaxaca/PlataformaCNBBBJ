import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:plataformacnbbbjo/components/formPatrts/my_button.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtiene una lista de trimestres únicos desde la colección 'Cursos' en Firestore.
  // Retorna una lista de cadenas con los nombres de los trimestres ordenados alfabéticamente.
  // Captura y reporta errores con Sentry.
  Future<List<String>> getTrimesters() async {
  try {
    QuerySnapshot snapshot = await _firestore.collection('Cursos').get();

    Set<String> uniqueTrimesters = {};
    for (var doc in snapshot.docs) {
      String? trimester = doc['Trimestre'];
      if (trimester != null) {
        uniqueTrimesters.add(trimester);
      }
    }

    return uniqueTrimesters.toList()..sort();

  } on FirebaseException catch (exception, stackTrace) {
    // Maneja excepciones específicas de Firebase
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('firebase_error_code', exception.code);
      },
    );
    rethrow; // Relanzar la excepción después de capturarla

  } catch (exception, stackTrace) {
    // Captura cualquier otra excepción
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', 'unknown_exception');
      },
    );
    rethrow; // Relanzar la excepción después de capturarla
  }
}


  // Obtiene una lista de dependencias únicas asociadas a un trimestre específico.
  // [trimester] Trimestre seleccionado.
  // Retorna una lista de mapas que contienen `IdDependencia` y `NombreDependencia`.
  // Captura y reporta errores con Sentry.
 Future<List<Map<String, dynamic>>> getDependencies(String trimester) async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('Cursos')
        .where('Trimestre', isEqualTo: trimester)
        .get();

    Set<String> uniqueDependencies = {};
    List<Map<String, dynamic>> dependencies = [];

    for (var doc in snapshot.docs) {
      String idDependencia = doc['IdDependencia'];

      if (!uniqueDependencies.contains(idDependencia)) {
        uniqueDependencies.add(idDependencia);

        DocumentSnapshot dependenciaDoc =
            await _firestore.collection('Dependencia').doc(idDependencia).get();

        if (dependenciaDoc.exists) {
          dependencies.add({
            'IdDependencia': idDependencia,
            'NombreDependencia': dependenciaDoc['NombreDependencia'],
          });
        }
      }
    }

    return dependencies;
  } on FirebaseException catch (exception, stackTrace) {
    // Captura errores específicos de Firebase y los envía a Sentry
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('firebase_error_code', exception.code);
        scope.setContexts('function', {
          'name': 'getDependencies',
          'trimester': trimester,
        });
      },
    );
    rethrow; // Relanza la excepción después de capturarla
  } catch (exception, stackTrace) {
    // Captura cualquier otro error inesperado y lo envía a Sentry
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', 'unknown_exception');
        scope.setContexts('function', {
          'name': 'getDependencies',
          'trimester': trimester,
        });
      },
    );
    rethrow; // Relanza la excepción después de capturarla
  }
}

  // Retorna un stream en tiempo real de los cursos que pertenecen a un trimestre y dependencia específicos.
  // [trimester] Trimestre seleccionado.
  // [dependecyId] ID de la dependencia.
  // Captura y reporta errores con Sentry.
  Stream<QuerySnapshot> getCourses(String trimester, String dependecyId) {
    try {
      return _firestore
          .collection('Cursos')
          .where('Trimestre', isEqualTo: trimester)
          .where('IdDependencia', isEqualTo: dependecyId)
          .snapshots();
    } on FirebaseException catch (exception, stackTrace) {
      // Captura errores de Firebase y los envía a Sentry
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('firebase_error_code', exception.code);
          scope.setContexts('function', {
            'name': 'getCourses',
            'trimester': trimester,
            'dependencyId': dependecyId,
          });
        },
      );
      rethrow;
    } catch (exception, stackTrace) {
      // Captura otros errores inesperados
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'unknown_exception');
          scope.setContexts('function', {
            'name': 'getCourses',
            'trimester': trimester,
            'dependencyId': dependecyId,
          });
        },
      );
      rethrow;
    }
  }

  // Obtiene los archivos almacenados en Firebase Storage para un curso específico.
  // [trimester] Trimestre del curso.
  // [dependency] ID de la dependencia del curso.
  // [courseName] Nombre del curso.
  // Retorna un mapa con nombre de archivo como clave y su URL de descarga como valor.
  // Captura y reporta errores con Sentry.
  Future<Map<String, String>> getCourseFiles(
      String trimester, String dependency, String courseName) async {
    try {
       String year = DateFormat('yyyy').format(DateTime.now());
      ListResult coursesList = await _storage
      
          .ref(
              '$year/$trimester/$dependency/$courseName')
          .listAll();

      Map<String, String> files = {};
      for (Reference fileRef in coursesList.items) {
        String url = await fileRef.getDownloadURL();
        files[fileRef.name] = url;
      }

      return files;
    } on FirebaseException catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('firebase_error_code', exception.code);
          scope.setContexts('function', {
            'name': 'getCourseFiles',
            'trimester': trimester,
            'dependency': dependency,
            'courseName': courseName,
          });
        },
      );
      return {};
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'unknown_exception');
          scope.setContexts('function', {
            'name': 'getCourseFiles',
            'trimester': trimester,
            'dependency': dependency,
            'courseName': courseName,
          });
        },
      );
      return {};
    }
  }

  // Abre una URL de archivo para descarga en el navegador externo del dispositivo.
  // [fileUrl] URL del archivo a descargar.
  // Captura y reporta errores con Sentry si la apertura falla.
  Future<void> downloadFile(String fileUrl) async {
    try {
      final Uri uri = Uri.parse(fileUrl);

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se puede abrir el archivo');
      }
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'download_file_exception');
          scope.setContexts('function', {
            'name': 'downloadFile',
            'fileUrl': fileUrl,
          });
        },
      );
      rethrow;
    }
  }

// Descarga un archivo ZIP con todos los archivos de un trimestre desde una función de Firebase.
// [context] Contexto de la interfaz para mostrar diálogos.
// [trimestre] Trimestre seleccionado.
// Muestra diálogos en caso de errores o si no hay archivos disponibles.
// Captura errores y los reporta con Sentry.
 Future<void> descargarZIP(BuildContext context, String trimestre) async {
  final uri = Uri.parse(
      "https://us-central1-expedientesems.cloudfunctions.net/generarZip?trimestre=$trimestre");

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final downloadUrl = data["url"];

      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        
        if (await canLaunchUrl(Uri.parse(downloadUrl))) {
          await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
        } else {
          
        }
      } else {
        if (!context.mounted) return;
        mostrarDialogo(context, "Sin archivos", "No hay archivos disponibles para el trimestre $trimestre.");
      }
    } else if (response.statusCode == 404) {
      if (!context.mounted) return;
      mostrarDialogo(context, "Sin archivos", "No hay archivos disponibles para el trimestre $trimestre.");
    } else {
      if (!context.mounted) return;
      mostrarDialogo(context, "Error en la descarga", "Error: ${response.statusCode}");
    }
   
  } catch (exception, stackTrace) {
     if (!context.mounted) return;
    mostrarDialogo(context, "Sin archivos", "No hay archivos disponibles para el trimestre $trimestre.");
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag("firebase_function", "generarZipDocumentos");
        scope.setContexts("uri", uri.toString());
      },
    );
  }
}


// Elimina todos los archivos almacenados en Firebase Storage de un trimestre mediante una función en la nube.
// [context] Contexto de la interfaz para mostrar diálogos.
// [trimestre] Trimestre seleccionado.
// Muestra mensajes de éxito o error según el estado de la operación.
// Captura errores y los reporta con Sentry.
Future<void> eliminarArchivosTrimestre(BuildContext context, String trimestre) async {
  final uri = Uri.parse(
      "https://us-central1-expedientesems.cloudfunctions.net/eliminarArchivosPorTrimestre?trimestre=$trimestre");

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      if (!context.mounted) return;
      mostrarDialogo(context, "Eliminación completa", "Se han eliminado los archivos del trimestre $trimestre.");
    } else if (response.statusCode == 404) {
      if (!context.mounted) return;
      mostrarDialogo(context, "Sin archivos", "No hay archivos en el trimestre $trimestre para eliminar.");
    } else {
      if (!context.mounted) return;
      mostrarDialogo(context, "Error en eliminación", "Código de error: ${response.statusCode}");
    }
  } catch (exception, stackTrace) {
    if (!context.mounted) return;
    mostrarDialogo(context, "Error inesperado", "No se pudieron eliminar los archivos.");
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag("firebase_function", "generarZipDocumentos");
        scope.setContexts("uri", uri.toString());
      },
    );
  }
}

// Muestra un cuadro de diálogo personalizado con título y mensaje en la interfaz.
// [context] Contexto donde se mostrará el diálogo.
// [titulo] Título del cuadro de diálogo.
// [mensaje] Contenido del mensaje mostrado.
void mostrarDialogo(BuildContext context, String titulo, String mensaje) {
  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
           MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), buttonColor: greenColorLight, onPressed: () => Navigator.pop(context),),
        ],
      );
    },
  );
}

// Verifica si existen archivos almacenados en Firebase Storage para un trimestre.
// [trimestre] Trimestre a consultar.
// Retorna `true` si existen archivos, `false` en caso contrario.
Future<bool> verificarArchivosTrimestre(String trimestre) async {
  final uri = Uri.parse(
      "https://us-central1-expedientesems.cloudfunctions.net/eliminarArchivosPorTrimestre?trimestre=$trimestre");

  try {
    final response = await http.get(uri);
    if (response.statusCode == 404) {
      return false; // No hay archivos
    }
    return true; // Sí hay archivos
  } catch (e) {
    return false; // Error en la solicitud, asumimos que no hay archivos
  }
}

// Descarga un archivo Excel con información de los cursos desde una función en la nube.
// [context] Contexto para mostrar diálogos informativos.
// Muestra mensajes en caso de éxito, error o si no hay archivos disponibles.
// Captura errores y los reporta con Sentry.
Future<void> descargarExcel(BuildContext context) async {
  final uri = Uri.parse(
      "https://us-central1-expedientesems.cloudfunctions.net/generarExcelCursos");
   // Log de inicio

  try {
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final downloadUrl = data["url"];
      
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        if (await canLaunchUrl(Uri.parse(downloadUrl))) {
          
          await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
        } else {
          if (!context.mounted) return;
          mostrarDialogo(context, "Error", "Problemas al generar la descarga.");
        }
      } else {
        if (!context.mounted) return;
        mostrarDialogo(context, "Sin archivos", "No hay archivos disponibles para descargar.");
      }
    } else if (response.statusCode == 404) {
      if (!context.mounted) return;
      mostrarDialogo(context, "Sin archivos", "No hay archivos disponibles para descargar.");
    } else {
      if (!context.mounted) return;
      mostrarDialogo(context, "Error en la descarga", "Error: ${response.statusCode}");
    }
  } catch (exception, stackTrace) {
    
    if (!context.mounted) return;
    mostrarDialogo(context, "Error", "Ocurrió un error al descargar el archivo Excel.");
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag("firebase_function", "generarExcelCursos");
        scope.setContexts("uri", uri.toString());
      },
    );
  }
}



}
