import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/userNormal/componentsNormal/card_welcome.dart';
import 'package:plataformacnbbbjo/userNormal/componentsNormal/view_data_user_normal.dart';

 ///Widget con un mensaje para el usuario
class ScreenHome extends StatelessWidget {
  const ScreenHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CardWelcome(),
        Expanded(child: SizedBox(
          height: 300,
        child: ViewDataUserNormal(),
        ))
      ],
    );
  }
}
