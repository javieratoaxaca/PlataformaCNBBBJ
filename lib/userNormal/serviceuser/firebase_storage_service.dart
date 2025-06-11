// Esta clase administra la carga de archivos PDF a Firebase Storage 
// verificando permisos y existencia previa en Firestore. Además, genera 
//registros de notificaciones sobre la subida de archivos.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:plataformacnbbbjo/components/formPatrts/my_button.dart';
import 'package:plataformacnbbbjo/dataConst/constand.dart';


class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Permite a un usuario subir un archivo PDF a Firebase Storage, generando una notificación en Firestore sobre la subida.
  Future<void> subirArchivo({
    required BuildContext context,
    required String trimester,
    required String dependency,
    required String course,
    required String nomenclatura,
    required String idCurso,
    String? subCourse,
    required Function(double) onProgress,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No se seleccionó archivo'),
          content: Text('Debes seleccionar un archivo para continuar.'),
          actions: [
            MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), buttonColor: greenColorLight, onPressed: () => Navigator.pop(context),),
          ],
        ),
      );
      return;
    }
    // Se consulta Firestore para evitar archivos duplicados.
    String fileName = basename(result.files.single.name);
    String year = DateFormat('yyyy').format(DateTime.now());
    // Se define la estructura de carpetas en Firebase Storage.
    String storagePath = '$year/$trimester/$dependency/$course/';
    if (subCourse != null) storagePath += '$subCourse/';
    storagePath += fileName;
    // Se sube el archivo a Firebase Storage, monitoreando el progreso.
    final storageRef = _storage.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: 'application/pdf');

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");
      
      // Se crea un documento en notifications con la información del archivo subido.
       QuerySnapshot querySnapshot = await _firestore
        .collection('notifications')
        .where('uid', isEqualTo: user.uid)
        .where('IdCurso', isEqualTo: idCurso)
        .where('status', isEqualTo: 'activo') // Solo archivos activos
        .get();

    if (querySnapshot.docs.isNotEmpty) {
       if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Archivo ya existente'),
          content: Text('Ya has subido un archivo para este curso. No puedes subir otro.'),
          actions: [
            MyButton(
              text: "Aceptar",
              icon: Icon(Icons.check_circle_outline),
              buttonColor: greenColorLight,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
      }

      try {
        await storageRef.getDownloadURL();
         if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Archivo existente'),
            content: Text('El archivo ya existe en el almacenamiento.'),
            actions: [MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), buttonColor: greenColorLight, onPressed: () => Navigator.pop(context),)],
          ),
        );
        return;
      } catch (_) {}

      UploadTask uploadTask;
      if (result.files.single.bytes != null) {
        uploadTask = storageRef.putData(result.files.single.bytes!, metadata);
      } else if (result.files.single.path != null) {
        File file = File(result.files.single.path!);
        uploadTask = storageRef.putFile(file, metadata);
      } else {
         if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('No se pudo obtener los datos del archivo.'),
            actions: [MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), buttonColor: greenColorLight, onPressed: () => Navigator.pop(context),)],
          ),
        );
        return;
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred / snapshot.totalBytes);
        onProgress(progress);
      });

      await uploadTask;
      String downloadURL = await storageRef.getDownloadURL();

      await _firestore.collection('notifications').add({
        'estado': 'pendiente',
        'trimester': trimester,
        'dependecy': dependency,
        'course': course,
        'IdCurso': idCurso,
        'uid': user.uid,
        'fileName': fileName,
        'uploader': user.email ?? 'Usuario desconocido',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'pdfUrl': downloadURL,
        'filePaht': storagePath,
        'status': 'activo',
        'statusUser':'activo',
        'mensajeAdmin': '',
      });
       if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Éxito'),
          content: Text('El archivo se subió correctamente.'),
          actions: [
            MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), 
            buttonColor: greenColorLight, 
            onPressed: () {
            Navigator.pop(context); // Cierra el diálogo
            Navigator.pop(context); // Cierra CursosNormal
            },)

          ],
        ),
      );
    } catch (e) {
       if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error al subir'),
          content: Text('Error al subir el archivo: $e'),
          actions: [
            MyButton(text: "Aceptar", icon: Icon(Icons.check_circle_outline), 
            buttonColor: greenColorLight, 
            onPressed: () => Navigator.pop(context),)
            ],
        ),
      );
    }
  }

  //Metodo para verificar si el curso esta en revisión
Future<bool> tieneArchivoPendiente({
  required String idCurso,
  required String uid,
}) async {
  final snapshot = await _firestore
      .collection('notifications')
      .where('uid', isEqualTo: uid)
      .where('IdCurso', isEqualTo: idCurso)
      .where('estado', isEqualTo: 'pendiente')
      .get();

  return snapshot.docs.isNotEmpty;
}

}