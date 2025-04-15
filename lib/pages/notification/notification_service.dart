import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
/// Servicio encargado de manejar las notificaciones, 
/// interacciones con Firestore y Firebase Storage, así como el registro de errores con Sentry.
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final FirebaseStorage _storage = FirebaseStorage.instance;

  //Obtiene un stream de notificaciones activas en tiempo real desde Firestore.
  //Las notificaciones se ordenan por fecha de creación (timestamp) de forma descendente.
  // Captura errores con Sentry en caso de fallos.
   Stream<QuerySnapshot> getNotifications() {
    try {
      return _firestore
          .collection('notifications')
          .where('status', isEqualTo: 'activo') // Solo traer notificaciones activas
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error, stackTrace) async {
            // Capturar error en Sentry
            await Sentry.captureException(
              error,
              stackTrace: stackTrace,
              withScope: (scope) {
                scope.setTag('error_type', 'stream_notifications');
              },
            );
          });
    } catch (exception, stackTrace) {
      // Capturar excepciones inesperadas
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'unexpected_exception');
        },
      );

      // Relanzar la excepción para que el código que lo llame la maneje
      rethrow;
    }
  }
  // Marca un curso como completado para un usuario, registrando la evidencia en Firestore.
  // [userId] - ID del usuario.
  // [cursoId] - ID del curso completado.
  // [evidenciaUrl] - URL del archivo de evidencia subido a Firebase Storage.
  Future<void> marcarCursoCompletado(String userId, String cursoId, String evidenciaUrl) async {
  try {
    DocumentReference userDocRef = _firestore.collection('CursosCompletados').doc(userId);
    Timestamp timestamp = Timestamp.now();

    await userDocRef.set({
      'uid': userId,
      'IdCursosCompletados': FieldValue.arrayUnion([cursoId]),
      'FechaCursoCompletado': FieldValue.arrayUnion([timestamp]),
      'Evidencias': FieldValue.arrayUnion([evidenciaUrl]),
      'completado': true,
    }, SetOptions(merge: true));

    
  } on FirebaseException catch (exception, stackTrace) {
    // Captura errores específicos de Firebase en Sentry
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_firebase_cursocompletado', exception.code);
      },
    );
    rethrow; // Relanzar la excepción después de capturarla
  } catch (exception, stackTrace) {
    // Captura cualquier otro tipo de error
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', 'errorMarcarCurso');
      },
    );

    rethrow; // Relanzar la excepción después de capturarla
  }
}

  //Rechaza una evidencia de curso, eliminando el archivo del Storage y actualizando la notificación.
  //[userId] - ID del usuario.
  //[filePath] - Ruta del archivo en Firebase Storage.
  //[notificationId] - ID de la notificación relacionada.
  Future<void> rechazarEvidencia(String userId, String filePath, String notificationId) async {
  try {

    await _storage.ref(filePath).delete();

    await _firestore.collection('notifications').doc(notificationId).update({
      'estado': 'Rechazado',
      'mensajeAdmin': 'Tu evidencia ha sido rechazada. Por favor, vuelve a subir un nuevo archivo.',
    }); 
  } on FirebaseException catch (exception, stackTrace) {
    // Manejo de errores específicos de Firebase
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('firebase_error_code', exception.code);
      },
    );
    rethrow; // Relanzar la excepción después de capturarla

  } catch (exception, stackTrace) {
    // Captura de otros errores
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

  // Elimina una notificación específica de Firestore.
  // [notificationId] - ID de la notificación a eliminar.
  Future<void> eliminarNotificacion(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      
    } on FirebaseException catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('firebase_error_code', exception.code);
        },
      );
      
      rethrow;
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('error_type', 'unknown_exception');
        
        },
      );
      
      rethrow;
    }
  }

  // Cambia el estado de una notificación a inactivo en Firestore.
  // [notificationId] - ID de la notificación a actualizar.
Future<void> marcarNotificacionInactiva(String notificationId) async {
  try {
    await _firestore.collection('notifications').doc(notificationId).update({
      'status': 'inactivo'
    });
    
  } on FirebaseException catch (exception, stackTrace) {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('firebase_error_code_notifacion_no_leida', exception.code);
       
      },
    );
    
    rethrow;
  } catch (exception, stackTrace) {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', 'unknown_exception');
        
      },
    );
    
    rethrow;
  }
}

  // Marca una notificación como leída en Firestore.
  // [notificationId] - ID de la notificación.
  Future<void> marcarNotificacionLeida(String notificationId) async {
  try {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true
    });
    
  } on FirebaseException catch (exception, stackTrace) {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('firebase_error_code_notifaction_no_leida', exception.code);
       
      },
    );
    
    rethrow;
  } catch (exception, stackTrace) {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', 'unknown_exception');
        
      },
    );
    
    rethrow;
  }
}

  // Marca una notificación como aprobada en Firestore. 
  // [notificationId] - ID de la notificación.
Future<void> aprobado(String notificationId) async {
  try {
    await _firestore.collection('notifications').doc(notificationId).update({
      'estado': 'Aprobado'
    });
    
  } on FirebaseException catch (exception, stackTrace) {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('firebase_error_code_aprobar_notificacion', exception.code);
       
      },
    );
   
    rethrow;
  } catch (exception, stackTrace) {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('error_type', 'unknown_exception');
        
      },
    );
    
    rethrow;
  }
}
//Se inicia la funcion para verificar en el storage de firebase si existe
Future<bool> verificarArchivo(String storagePath) async {
  try {
    //se obtiene  la URL del archivo en Firebase Storage
    await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
    return true;
  } catch (e) {
    if (e.toString().contains("object-not-found")) {
      // Firebase lanza 'object-not-found' si el archivo no existe
      return false;
    }
    return false; // Otros errores
  }
}
}
