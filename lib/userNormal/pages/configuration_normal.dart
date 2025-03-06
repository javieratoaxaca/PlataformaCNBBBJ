import 'package:flutter/cupertino.dart';
import 'package:plataformacnbbbjo/components/configuration/card_colors.dart';
import 'package:plataformacnbbbjo/components/configuration/theme_color.dart';
import 'package:plataformacnbbbjo/userNormal/pages/get_apk.dart';

/// `ConfigurationNormal` es un widget que agrupa configuraciones visuales.
///
/// Contiene los widgets `ThemeColor`, `CardColors`, que gestionan la apariencia.
/// y `GetApk` que permite la descarga del archivo para movil.
class ConfigurationNormal extends StatelessWidget {
  const ConfigurationNormal({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(10.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ThemeColor(), // Widget que maneja la configuración del tema de la app.
        CardColors(), // Widget que gestiona los colores de la UI.
        GetApk() // Widget para la descarga del APK.
      ],
    ),
    );
  }
}
