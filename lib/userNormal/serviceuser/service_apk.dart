import 'dart:io' show Directory, File, Platform; // Solo para detectar si es móvil
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Para descargas en web
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

Future<void> downloadApkFile() async {
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
      print("Descarga iniciada en Web: $downloadUrl");
    } else {
      // 🔹 Opción para Android/iOS
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          print("Permiso denegado");
          return;
        }

        Directory tempDir = await getTemporaryDirectory();
        String filePathLocal = "${tempDir.path}/mi_aplicacion.apk";
        File file = File(filePathLocal);

        await ref.writeToFile(file);
        print("Descarga completa: $filePathLocal");

        // Abre el archivo APK en Android
        OpenFile.open(filePathLocal);
      }
    }
  } catch (e) {
    print("Error al descargar el archivo: $e");
  }
}
