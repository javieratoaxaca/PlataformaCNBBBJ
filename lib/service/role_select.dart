import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para manejar la lógica de roles de usuario en Firebase Authentication.
class RoleService {
  /// Verifica si el usuario autenticado tiene el rol de administrador.
  /// 
  /// Retorna `true` si el usuario tiene el rol de admin, de lo contrario `false`.
static Future<bool> isAdmin() async {

  // Obtiene el usuario actualmente autenticado en Firebase
  final user = FirebaseAuth.instance.currentUser;

  // Si no hay usuario autenticado, retorna false
  if (user != null) {
    // Obtiene los claims del token de autenticación del usuario
    final idTokenResult = await user.getIdTokenResult();
     // Retorna true si el claim 'admin' está presente y es verdadero
    return idTokenResult.claims?['admin'] == true;
  }
  return false;
}
}