import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// `PaginatedTableService` maneja la obtención de datos de cursos completados por un usuario 
/// desde Firebase Firestore.
class PaginatedTableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `fetchCompletedCourses` Obtiene la lista de cursos completados por el usuario autenticado.
  ///
  /// Retorna una lista de mapas con información sobre los cursos:
  /// - `Nombre del curso`: Nombre del curso completado.
  /// - `Trimestre`: Trimestre en el que se cursó.
  /// - `Fecha de envio de Constancia`: Fecha formateada de finalización.
  Future<List<Map<String, dynamic>>> fetchCompletedCourses() async {

    try {

      final auth = FirebaseAuth.instance;

      String uid = auth.currentUser?.uid ?? '';

      // Obtiene los documentos donde el UID coincide con el usuario autenticado.
      QuerySnapshot cursosCompletadosSnapshot =
      await _firestore.collection('CursosCompletados').where('uid', isEqualTo: uid).get();

      Map<dynamic, String> idCursoFechaMap = {}; // Mapeo de IdCurso -> FechaCursoCompletado

      for (var doc in cursosCompletadosSnapshot.docs) {
        List<dynamic> ids = doc['IdCursosCompletados'] ?? [];
        List<dynamic> fechas = doc['FechaCursoCompletado'] ?? [];

        // Asegurar que cada ID tenga una fecha correspondiente
        for (int i = 0; i < ids.length; i++) {
          Timestamp? timestamp = (i < fechas.length) ? fechas[i] as Timestamp? : null;
          String formattedDate = timestamp != null
              ? DateFormat('dd/MM/yyyy/ - HH:mm:ss').format(timestamp.toDate()) // Formato legible
              : "Fecha no disponible";

          idCursoFechaMap[ids[i]] = formattedDate;
        }
      }

      if (idCursoFechaMap.isEmpty) return [];

      List<Map<String, dynamic>> tempRows = [];

      // Dividir en grupos de 10 para whereIn
      List<List<dynamic>> batches = [];
      List<dynamic> idCursosCompletados = idCursoFechaMap.keys.toList();

      for (var i = 0; i < idCursosCompletados.length; i += 10) {
        batches.add(idCursosCompletados.sublist(
            i, i + 10 > idCursosCompletados.length ? idCursosCompletados.length : i + 10));
      }

      // Consultar 'Cursos' en lotes
      for (var batch in batches) {
        QuerySnapshot cursosSnapshot = await _firestore
            .collection('Cursos')
            .where('IdCurso', whereIn: batch)
            .get();

        tempRows.addAll(cursosSnapshot.docs.map((doc) {
          dynamic idCurso = doc["IdCurso"];
          return {
            "Nombre del curso": doc['NombreCurso'] ?? 'N/A',
            "Trimestre": doc['Trimestre'] ?? 'N/A',
            "Fecha de envio de Constancia": idCursoFechaMap[idCurso] ?? "Fecha no disponible",
          };
        }).toList());
      }

      return tempRows;
    } catch (e, stackTrace) {
      // Captura errores en Sentry para su monitoreo
      await Sentry.captureException(e, stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('Table employee', 'No data find');
      } 
      );
      return [];
    }
  }


}
