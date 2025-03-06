import 'package:flutter/cupertino.dart';
import 'package:plataformacnbbbjo/userNormal/pages/screen_home.dart';

/// `DashboardNormal` es un widget que representa el panel principal para los usuarios normales.
///
/// Actualmente, solo devuelve el widget `ScreenHome`, que contiene la estructura
/// y contenido principal del dashboard.
class DashboardNormal extends StatelessWidget {
  const DashboardNormal({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenHome();
  }
}
