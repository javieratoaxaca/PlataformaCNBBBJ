import 'dart:io' show Directory, File, Platform; // Solo para detectar si es móvil
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Para descargas en web
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:plataformacnbbbjo/components/formPatrts/custom_snackbar.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> downloadApkFile(BuildContext context) async {
  try {
    // Ruta del archivo en Firebase Storage
    String filePath = "app-cnbbbjo.apk"; // Ajusta la ruta según tu Storage
    Reference ref = FirebaseStorage.instance.ref().child(filePath);

    if (kIsWeb) {
      // 🔹 Opción para Flutter Web
      String downloadUrl = await ref.getDownloadURL();
      html.AnchorElement(href: downloadUrl)
        ..setAttribute("download", "mi_aplicacion.apk")
        ..click();
        if(context.mounted) {
        showCustomSnackBar(context, 'Descarga iniciada en Web: $downloadUrl', greenColorLight);
        }
    } else {
      // 🔹 Opción para Android/iOS
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
            if(context.mounted) {
              showCustomSnackBar(context, 'Permiso denegado', Colors.red);
            }
          return;
        }

        Directory tempDir = await getTemporaryDirectory();
        String filePathLocal = "${tempDir.path}/mi_aplicacion.apk";
        File file = File(filePathLocal);

        await ref.writeToFile(file);

        // Abre el archivo APK en Android
        OpenFile.open(filePathLocal);
      }
    }
  } catch (e, stackTrace) {
        await Sentry.captureException(
      e,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('operation', 'service_apk');
      },
    );
  }
}
