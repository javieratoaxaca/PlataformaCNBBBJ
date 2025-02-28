import 'package:firebase_auth/firebase_auth.dart';

class RoleService {

static Future<bool> isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final idTokenResult = await user.getIdTokenResult();
    print("Claims del usuario: ${idTokenResult.claims}");
    return idTokenResult.claims?['admin'] == true;
  }
  return false;
}
}