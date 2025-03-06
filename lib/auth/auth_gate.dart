import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/auth/login_or_register.dart';
import 'package:plataformacnbbbjo/pages/main_pages/home_page.dart';
import 'package:plataformacnbbbjo/service/role_select.dart';
import 'package:plataformacnbbbjo/userNormal/pages/home_normal.dart';

/// Widget que maneja la autenticación y redirige a la página correspondiente
/// según el estado de autenticación del usuario y su rol.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Mostrar indicador de carga mientras se establece la conexión con Firebase Auth
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Si el usuario está autenticado
            if (snapshot.hasData) {
              return FutureBuilder<bool>(
                  future: RoleService.isAdmin(),
                  builder: (context, adminSnapshot) {
                    // Mostrar indicador de carga mientras se verifica el rol del usuario
                    if (adminSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                     // Si el usuario es administrador, redirigir a HomePage
                    if (adminSnapshot.hasData && adminSnapshot.data == true) {
                      return const HomePage();
                    } else {
                      // Si no es administrador, redirigir a HomeNormal
                      return const HomeNormal();
                    }
                  });
            } else {
              // Si no está autenticado, redirigir a la pantalla de Login o Registro
              return const LoginOrRegister();
            }
          }),
    );
  }
}
