import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> generarExcelCursosCompletados() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Obtener documentos de CursosCompletados
  QuerySnapshot cursosCompletadosSnapshot =
      await firestore.collection('CursosCompletados').get();

  // Crear una instancia de Excel
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Cursos Completados'];

  // Mapeo de dependencias únicas
  Set<String> dependenciasSet = {};

  // Obtener todas las dependencias disponibles en los cursos
  for (var doc in cursosCompletadosSnapshot.docs) {
    List<String> idCursos = List<String>.from(doc['IdCursosCompletados']);

    for (String cursoId in idCursos) {
      DocumentSnapshot cursoSnapshot =
          await firestore.collection('Cursos').doc(cursoId).get();

      if (cursoSnapshot.exists) {
        String dependencia = cursoSnapshot['Dependencia'] ?? 'S/D';
        dependenciasSet.add(dependencia);
      }
    }
  }

  // Convertimos el Set en una lista y la ordenamos alfabéticamente
  List<String> dependenciasOrdenadas = dependenciasSet.toList()..sort();

  // Crear encabezados principales (CUPO, Nombre del Empleado y Dependencias)
  List<CellValue?> encabezadoDependencias = [
    TextCellValue('CUPO'),
    TextCellValue('Nombre del Empleado')
  ];
  for (String dependencia in dependenciasOrdenadas) {
    encabezadoDependencias.add(TextCellValue(dependencia));
    encabezadoDependencias.add(TextCellValue(''));
    encabezadoDependencias.add(TextCellValue(''));
  }

  sheetObject.appendRow(encabezadoDependencias);

  // Crear subencabezados (Curso, Trimestre, Fecha Completado)
  List<CellValue?> subEncabezados = [TextCellValue(''), TextCellValue('')]; // Primeras dos columnas vacías
  for (String dependencia in dependenciasOrdenadas) {
    subEncabezados.add(TextCellValue('Curso'));
    subEncabezados.add(TextCellValue('Trimestre'));
    subEncabezados.add(TextCellValue('Fecha Completado'));
  }

  sheetObject.appendRow(subEncabezados);

  // Recorrer los documentos de CursosCompletados
  for (var doc in cursosCompletadosSnapshot.docs) {
    String uid = doc['uid'];
    List<String> idCursos = List<String>.from(doc['IdCursosCompletados']);
    List<String> fechasCursos = (doc['FechaCursoCompletado'] as List)
        .map((fecha) => (fecha as Timestamp).toDate().toIso8601String())
        .toList();

    // Obtener datos del usuario (User) relacionado con el uid
    DocumentSnapshot userSnapshot =
        await firestore.collection('User').doc(uid).get();
    String cupon = userSnapshot['CUPO'] ?? 'S/D';

    // Obtener el nombre del empleado usando el CUPO de la colección 'User'
    String empleadoNombre = 'Desconocido';
    if (cupon.isNotEmpty) {
      QuerySnapshot empleadosSnapshot = await firestore
          .collection('Empleados')
          .where('CUPO', isEqualTo: cupon)
          .get();

      if (empleadosSnapshot.docs.isNotEmpty) {
        empleadoNombre = empleadosSnapshot.docs.first['Nombre'] ?? 'Desconocido';
      }
    }

    // Inicializamos la fila con el CUPO y el nombre del empleado
    List<CellValue?> fila = [TextCellValue(cupon), TextCellValue(empleadoNombre)];

    // Mapeamos las dependencias a listas vacías para cursos, trimestres y fechas
    Map<String, List<String>> cursosPorDependencia = {};
    Map<String, List<String>> trimestresPorDependencia = {};
    Map<String, List<String>> fechasPorDependencia = {};

    for (String dependencia in dependenciasOrdenadas) {
      cursosPorDependencia[dependencia] = [];
      trimestresPorDependencia[dependencia] = [];
      fechasPorDependencia[dependencia] = [];
    }

    // Recorrer los cursos completados por el usuario
    for (int i = 0; i < idCursos.length; i++) {
      String cursoId = idCursos[i];
      String fechaCurso = fechasCursos[i];

      DocumentSnapshot cursoSnapshot =
          await firestore.collection('Cursos').doc(cursoId).get();

      if (cursoSnapshot.exists) {
        String nombreCurso = cursoSnapshot['NombreCurso'] ?? 'Desconocido';
        String trimestre = cursoSnapshot['Trimestre'] ?? '0';
        String dependencia = cursoSnapshot['Dependencia'] ?? 'S/D';

        // Agregar los datos en la dependencia correspondiente
        if (cursosPorDependencia.containsKey(dependencia)) {
          cursosPorDependencia[dependencia]!.add(nombreCurso);
          trimestresPorDependencia[dependencia]!.add(trimestre);
          fechasPorDependencia[dependencia]!.add(fechaCurso);
        }
      }
    }

    // Llenamos la fila con los datos organizados por dependencia
    for (String dependencia in dependenciasOrdenadas) {
      fila.add(TextCellValue(cursosPorDependencia[dependencia]!.isNotEmpty ? cursosPorDependencia[dependencia]![0] : ''));
      fila.add(TextCellValue(trimestresPorDependencia[dependencia]!.isNotEmpty ? trimestresPorDependencia[dependencia]![0] : ''));
      fila.add(TextCellValue(fechasPorDependencia[dependencia]!.isNotEmpty ? fechasPorDependencia[dependencia]![0] : ''));
    }

    // Agregar la fila al Excel
    sheetObject.appendRow(fila);
  }

  // Guardar y abrir el archivo
  await guardarYAbrirExcel(excel);
}

Future<void> guardarYAbrirExcel(Excel excel) async {
  var bytes = excel.encode();
  if (bytes == null) return;

  Uint8List uint8List = Uint8List.fromList(bytes);
  final blob = html.Blob([uint8List]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "CursosCompletados.xlsx")
    ..click();

  html.Url.revokeObjectUrl(url);
  print('📂 Archivo descargado exitosamente.');
}
