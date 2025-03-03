import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:plataformacnbbbjo/components/formPatrts/my_button.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtener trimestres únicos
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


  // Obtener dependencias únicas por trimestre
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

  // Obtener cursos por trimestre y dependencia
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

  // Obtener archivos de un curso en Firebase Storage
  Future<Map<String, String>> getCourseFiles(
      String trimester, String dependency, String courseName) async {
    try {
      ListResult coursesList = await _storage
          .ref(
              '$trimester/$dependency/$courseName')
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

  // Descargar archivo
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
 

  /*
  Future<void> descargarZIP() async {
  final uri = Uri.parse("https://us-central1-expedientesems.cloudfunctions.net/generarZipDocumentos");

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final downloadUrl = data["url"];

      if (downloadUrl != null) {
        

        //brir el enlace en el navegador
        if (await canLaunchUrl(Uri.parse(downloadUrl))) {
          await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
        } else {
          throw Exception("No se puede abrir el enlace de descarga.");
        }
      } else {
        throw Exception("No se recibió una URL de descarga válida.");
      }
    } else {
      throw Exception("Error en la descarga: Código ${response.statusCode}");
    }
  } catch (exception, stackTrace) {
    

    //Capturar el error en Sentry
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag("firebase_function", "generarZipDocumentos");
        scope.setContexts("uri", uri.toString());
      },
    );
  }
}*/
Future<void> descargarZIP(BuildContext context, String trimestre) async {
    final uri = Uri.parse("https://us-central1-expedientesems.cloudfunctions.net/generarZipPorTrimestre?trimestre=$trimestre");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final downloadUrl = data["url"];
        if (downloadUrl != null) {
          if (await canLaunchUrl(Uri.parse(downloadUrl))) {
            await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
          } else {
            throw Exception("No se puede abrir el enlace de descarga.");
          }
        } else {
           if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('No se pudo obtener los datos del archivo.'),
            actions: [MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), buttonColor: greenColorLight, onPressed: () => Navigator.pop(context),)],
          ),
        );
        return;
        }
      } else {
        throw Exception("Error en la descarga: Código ${response.statusCode}");
      }
    } catch (exception, stackTrace) {
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
}
