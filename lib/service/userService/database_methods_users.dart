import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class DatabaseMethodsUsers {

/// Obtiene todos los usuarios de la colección `User` junto con información adicional.
///
/// Este método realiza las siguientes operaciones para cada usuario:
/// 1. Obtiene su documento de la colección `User`, ordenado por el campo `CUPO`.
/// 2. Verifica si el usuario tiene cursos completados, consultando su documento en
///    la colección `CursosCompletados`, usando su `uid`.
/// 3. Verifica si está registrado como empleado en la colección `Empleados`, buscando
///    por el campo `CUPO`.
/// 4. Si está registrado como empleado, se obtiene su nombre.
///
/// Cada usuario retornado incluye los siguientes campos adicionales:
/// - `hasCompletedCourse` (bool): Indica si tiene cursos completados.
/// - `empleadoNombre` (String): Nombre del empleado (o "No registrado").
/// - `estaDadoDeAlta` (bool): `true` si está dado de alta como empleado.
///
/// Retorna:
/// - Una lista de mapas (`List<Map<String, dynamic>>`) con los datos combinados de cada usuario.
///
/// Lanza:
/// - Relanza cualquier excepción (`FirebaseException` o general) después de reportarla a Sentry.
  Future<List<Map<String, dynamic>>> getDataUsers() async {
    final firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot userSnapshot =
          await firestore.collection('User').orderBy('CUPO').get();

      List<Map<String, dynamic>> users = [];

      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['uid'] as String? ?? '';
        final cupon = data['CUPO'] as String? ?? '';

        // Verificar si tiene cursos completados
        final cursoDoc =
            await firestore.collection('CursosCompletados').doc(uid).get();

        // Buscar si está registrado como empleado
        String empleadoNombre = 'No registrado';
        bool estaDadoDeAlta = false;

        if (cupon.isNotEmpty) {
          final empleadosSnapshot = await firestore
              .collection('Empleados')
              .where('CUPO', isEqualTo: cupon)
              .get();

          if (empleadosSnapshot.docs.isNotEmpty) {
            empleadoNombre =
                empleadosSnapshot.docs.first['Nombre'] as String? ??
                    'No registrado';
            estaDadoDeAlta = true;
          }
        }

        users.add({
          ...data,
          'hasCompletedCourse': cursoDoc.exists,
          'empleadoNombre': empleadoNombre,
          'estaDadoDeAlta': estaDadoDeAlta,
        });
      }

      return users;
    } on FirebaseException catch (exception, stackTrace) {
      // Maneja excepciones específicas de Firebase
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('firebase_error_code', exception.code);
        },
      );
      rethrow; // Relanzar la excepción
    } catch (exception, stackTrace) {
      // Maneja otras excepciones
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }


/// Busca y obtiene una lista de usuarios con información adicional sobre cursos y empleados.
///
/// Este método realiza las siguientes operaciones:
/// 1. Consulta todos los documentos de la colección `User`, ordenados por el campo `CUPO`.
/// 2. Para cada usuario:
///    - Verifica si tiene cursos completados en la colección `CursosCompletados`, usando su `uid`.
///    - Verifica si está registrado como empleado en la colección `Empleados`, usando el campo `CUPO`.
///    - Si está registrado, obtiene su nombre.
/// 3. Aplica un filtro opcional por nombre del empleado si se proporciona.
///
/// Cada elemento en la lista resultante incluye:
/// - Todos los datos originales del documento en `User`.
/// - `hasCompletedCourse` (bool): Indica si el usuario tiene cursos completados.
/// - `empleadoNombre` (String): Nombre del empleado registrado (o "No registrado").
/// - `estaDadoDeAlta` (bool): `true` si está registrado como empleado, `false` si no.
///
/// Parámetros:
/// - [nombreEmpleadoBusqueda] (opcional): Nombre parcial del empleado para filtrar los resultados.
///
/// Retorna:
/// - Una lista de mapas (`List<Map<String, dynamic>>`), cada uno representando a un usuario con información combinada.
///
/// Lanza:
/// - Relanza cualquier excepción (`FirebaseException` o general) después de reportarla a Sentry.
  Future<List<Map<String, dynamic>>> searchDataUsers(
      {String? nombreEmpleadoBusqueda}) async {
    final firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot userSnapshot =
          await firestore.collection('User').orderBy('CUPO').get();

      List<Map<String, dynamic>> users = [];

      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['uid'] as String? ?? '';
        final cupon = data['CUPO'] as String? ?? '';

        // Verificar si tiene cursos completados
        final cursoDoc =
            await firestore.collection('CursosCompletados').doc(uid).get();

        // Buscar si está registrado como empleado
        String empleadoNombre = 'No registrado';
        bool estaDadoDeAlta = false;

        if (cupon.isNotEmpty) {
          final empleadosSnapshot = await firestore
              .collection('Empleados')
              .where('CUPO', isEqualTo: cupon)
              .get();

          if (empleadosSnapshot.docs.isNotEmpty) {
            empleadoNombre =
                empleadosSnapshot.docs.first['Nombre'] as String? ??
                    'No registrado';
            estaDadoDeAlta = true;
          }
        }

        final userMap = {
          ...data,
          'hasCompletedCourse': cursoDoc.exists,
          'empleadoNombre': empleadoNombre,
          'estaDadoDeAlta': estaDadoDeAlta,
        };

        // Si hay filtro, aplicarlo
        if (nombreEmpleadoBusqueda == null ||
            empleadoNombre
                .toLowerCase()
                .contains(nombreEmpleadoBusqueda.toLowerCase())) {
          users.add(userMap);
        }
      }

      return users;
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
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

/// Elimina un usuario y sus cursos completados de Firebase Firestore.
///
/// Este método realiza las siguientes operaciones:
/// 1. Intenta obtener y eliminar el documento del usuario en la colección `User`
///    utilizando el `id` proporcionado.
/// 2. Intenta obtener y eliminar el documento relacionado en la colección
///    `CursosCompletados`, también identificado por el mismo `id`.
///
/// Si cualquiera de los documentos (`User` o `CursosCompletados`) no existe,
/// simplemente omite su eliminación.
///
/// Captura y reporta excepciones mediante Sentry en los siguientes casos:
/// - [FirebaseException]: errores específicos de Firebase como permisos, red, etc.
/// - [Exception]: errores generales inesperados.
///
/// Parámetros:
/// - [id]: El ID del documento del usuario que se desea eliminar.
///
/// Lanza:
/// - Relanza cualquier excepción capturada después de reportarla a Sentry.
  Future<void> deleteuser(String id) async {
    try {
      // Se establecen las colecciones que se van a utilizar
      final userRef = FirebaseFirestore.instance.collection('User').doc(id);
      final cursoRef =
          FirebaseFirestore.instance.collection('CursosCompletados').doc(id);


      final userDoc = await userRef.get();
      if (userDoc.exists) await userRef.delete();

      final cursoDoc = await cursoRef.get();
      if (cursoDoc.exists) await cursoRef.delete();
    } on FirebaseException catch (exception, stackTrace) {
      // Maneja excepciones específicas de Firebase
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('operation', 'deleteUser');
          scope.setTag('firebase_error_code', exception.code);
        },
      );
      rethrow; // Relanzar la excepción
    } catch (exception, stackTrace) {
      // Maneja otras excepciones
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }
}
