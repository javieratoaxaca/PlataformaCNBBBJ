


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/auth/login_or_register.dart';
import 'package:plataformacnbbbjo/pages/main_pages/home_page.dart';
import 'package:plataformacnbbbjo/service/role_select.dart';
import 'package:plataformacnbbbjo/userNormal/pages/home_normal.dart';

class AuthGate extends StatelessWidget {

  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(child: CircularProgressIndicator(),);
            }

            //user is logged in
            if (snapshot.hasData) {
            return FutureBuilder<bool>(
                future: RoleService.isAdmin(),
                builder: (context, admisSnapshot) {
                  if(admisSnapshot.connectionState == ConnectionState.waiting){
                    return const Center(child: CircularProgressIndicator(),);
                  }
                  if(admisSnapshot.hasData && admisSnapshot.data == true) {
                    return const HomePage();
                  } else {
                    return const HomeNormal();
                  }

                });


            } else {
              return const LoginOrRegister();
            }
          }),
    );
  }
}
