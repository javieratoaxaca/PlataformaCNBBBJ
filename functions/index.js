/* eslint-disable prefer-const */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {Storage} = require("@google-cloud/storage");
const archiver = require("archiver");
const fs = require("fs");
const os = require("os");
const path = require("path");
admin.initializeApp();
const storage = new Storage();
const bucket = storage.bucket("expedientesems.firebasestorage.app");
const ExcelJS = require("exceljs");

exports.generarZipPorTrimestre = functions.https.onRequest(async (req, res) => {
  try {
    const {trimestre}=req.query;
    if (!trimestre) {
      return res.status(400).json({
        error: "Se requiere el parámetro 'trimestre'."});
    }

    // Filtrar archivos por el trimestre dentro del Storage
    const year = new Date().getFullYear();
    const [files] = await bucket.getFiles({
      prefix: `${year}/${
        trimestre}/`});
    if (files.length === 0) {
      return res.status(404).json({error: "No se encontraron archivos"});
    }

    const zipFileName = `constancias_${trimestre}_${Date.now()}.zip`;
    const tempFilePath = `/tmp/${zipFileName}`;

    const archive = archiver("zip", {zlib: {level: 9}});
    const output = fs.createWriteStream(tempFilePath);
    archive.pipe(output);

    for (const file of files) {
      const filePath = file.name;
      const fileStream = file.createReadStream();
      archive.append(fileStream, {name: filePath});
    }

    await archive.finalize();

    await bucket.upload(tempFilePath, {
      destination: `zips/${zipFileName}`,
      metadata: {contentType: "application/zip"},
    });

    const [zipFileUrl] = await bucket.file(`zips/${zipFileName}`).getSignedUrl({
      action: "read",
      expires: Date.now() + 60 * 60 * 1000, // 1 hora de validez
    });
    res.set("Access-Control-Allow-Origin", "*");
    res.status(200).json({url: zipFileUrl});
  } catch (error) {
    console.error("Error al generar ZIP:", error);
    res.status(500).json({error: "Error al generar el archivo ZIP"});
  }
});

exports.eliminarArchivosPorTrimestre=
functions.https.onRequest(async (req, res)=>{
  res.set("Access-Control-Allow-Origin", "*");
  try {
    const {trimestre} = req.query;
    if (!trimestre) {
      return res.status(400).json({
        error: "Debe proporcionar un trimestre."});
    }

    // Ruta base en Storage donde se guardan los archivos del trimestre
    const year = new Date().getFullYear();
    const folderPath = `${year}/${trimestre}/`;

    // Obtener todos los archivos dentro de la carpeta del trimestre
    const [files] = await bucket.getFiles({prefix: folderPath});

    if (files.length === 0) {
      return res.status(404).json({
        message: `No hay archivos para el trimestre ${trimestre}.`});
    }

    // Filtrar solo archivos y no carpetas vacías
    const archivosAEliminar= files.filter((file) => file.name.endsWith(".pdf"));

    if (archivosAEliminar.length === 0) {
      return res.status(404).json({
        message: `No hay archivos PDF en el trimestre ${trimestre}.`});
    }

    // Eliminar todos los archivos encontrados
    await Promise.all(archivosAEliminar.map((file) => file.delete()));

    return res.status(200).json({
      message: `Todos los archivos del trimestre${
        trimestre} han sido eliminados.`});
  } catch (error) {
    console.error("Error al eliminar archivos:", error);
    return res.status(500).json({
      error: "Error al eliminar archivos del trimestre."});
  }
});


exports.generarExcelCursos = functions.https.onRequest(async (req, res) => {
  try {
    console.log("🚀 Iniciando generación del Excel...");

    // 1️⃣ Obtener SOLO los empleados que han completado cursos
    const cursosCompletadosSnapshot = await
    admin.firestore().collection("CursosCompletados").get();
    const empleadosCursos = cursosCompletadosSnapshot.docs.map((doc) => ({
      uid: doc.data().uid,
      cursos: doc.data().IdCursosCompletados || [],
      fechas: doc.data().FechaCursoCompletado || [],
    }));

    console.log(`📌 Empleados con cursos completados: ${
      empleadosCursos.length}`);

    // 2️⃣ Obtener los datos de los cursos completados
    let cursosUnicos = new Set(); // Para evitar duplicados
    empleadosCursos.forEach((empleado) => {
      empleado.cursos.forEach((cursoId) => cursosUnicos.add(cursoId));
    });

    // Consultamos solo los cursos que fueron completados
    const cursosSnapshot = await admin.firestore()
        .collection("Cursos")
        .where(admin.firestore.FieldPath.documentId(),
            "in", Array.from(cursosUnicos))
        .get();

    const cursos = cursosSnapshot.docs.map((doc) => ({
      id: doc.id,
      nombre: doc.data().NombreCurso || `CURSO_${doc.id}`,
      dependencia: doc.data().Dependencia || "SIN DEPENDENCIA",
      trimestre: doc.data().Trimestre || "SIN TRIMESTRE",
    }));

    // Agrupar los cursos por Dependencia y Trimestre
    const dependencias = {};
    cursos.forEach((curso) => {
      if (!dependencias[curso.dependencia]) {
        dependencias[curso.dependencia] =
        {"1": [], "2": [], "3": [], "4": []};
      }
      dependencias[curso.dependencia][curso.trimestre].push(curso);
    });

    console.log(`📌 Cursos organizados por Dependencia y Trimestre.`);

    // 3️⃣ Crear el archivo Excel
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Reporte General");

    // 4️⃣ Definir encabezados fijos
    let columnas = [
      {header: "NOMBRE", key: "nombre", width: 25},
      {header: "CUPO", key: "cupo", width: 15},
    ];
    let encabezadosDependencias = ["NOMBRE", "CUPO"];
    let encabezadosTrimestres = ["", ""];
    let encabezadosCursos = ["", ""];

    let ultimaColumna = 2;

    // 5️⃣ Agregar columnas
    // dinámicas solo con los cursos que han sido completados
    Object.keys(dependencias).forEach((dependencia) => {
      let primeraColumna = ultimaColumna + 1;
      let trimestres = Object.keys(dependencias[dependencia]);

      encabezadosDependencias.push(dependencia);
      if (trimestres.length > 0) {
        encabezadosDependencias = encabezadosDependencias.concat(
            Array(Math.max(trimestres.length * 2 - 1, 0)).fill(""));
      }


      trimestres.forEach((trimestre) => {
        encabezadosTrimestres.push(`Trimestre ${trimestre}`);
        let cursosEnTrimestre = dependencias[
            dependencia][trimestre].length || 0;
        if (cursosEnTrimestre > 0) {
          encabezadosTrimestres = encabezadosTrimestres.concat(
              Array(Math.max(cursosEnTrimestre * 2 - 1, 0)).fill(""),
          );
        }

        dependencias[dependencia][trimestre].forEach((curso) => {
          columnas.push({
            header: curso.nombre, key: `curso_${curso.id}`, width: 20});
          columnas.push({header: "Fecha", key: `fecha_${curso.id}`, width: 15});
          encabezadosCursos.push(curso.nombre, "Fecha");
        });
      });

      let ultimaColumnaDependencia = primeraColumna + trimestres.length * 2 - 1;
      worksheet.mergeCells(1, primeraColumna, 1, ultimaColumnaDependencia);
      ultimaColumna = ultimaColumnaDependencia;
    });

    worksheet.columns = columnas;

    // 6️⃣ Agregar encabezados
    worksheet.addRow(encabezadosDependencias);
    worksheet.addRow(encabezadosTrimestres);
    worksheet.addRow(encabezadosCursos);

    worksheet.mergeCells(1, 1, 3, 1);
    worksheet.mergeCells(1, 2, 3, 2);

    // 7️⃣ Procesar cada empleado y verificar cursos completados
    for (const empleado of empleadosCursos) {
      console.log(`👤 Procesando empleado UID: ${empleado.uid}`);

      let cupo = "NO ASIGNADO";
      let nombreEmpleado = "No encontrado";

      // Obtener el cupo del usuario desde Firestore
      const userDoc = await
      admin.firestore().collection("User").doc(empleado.uid).get();
      if (userDoc.exists) {
        cupo = userDoc.data().CUPO;
      }

      // Obtener el nombre del empleado desde Firestore - Empleados
      if (cupo) {
        const empleadosSnapshot = await
        admin.firestore().collection("Empleados")
            .where("CUPO", "==", cupo)
            .limit(1)
            .get();
        if (!empleadosSnapshot.empty) {
          nombreEmpleado = empleadosSnapshot.docs[0].data().Nombre;
        }
      }

      const fila = {nombre: nombreEmpleado, cupo};

      Object.keys(dependencias).forEach((dependencia) => {
        Object.keys(dependencias[dependencia]).forEach((trimestre) => {
          dependencias[dependencia][trimestre].forEach((curso) => {
            const index = empleado.cursos.indexOf(curso.id);
            let fechaFormateada = "NO COMPLETADO";

            if (index !== -1 && empleado.fechas[
                index] && empleado.fechas[index].toDate) {
              fechaFormateada = empleado.fechas[
                  index].toDate().toLocaleDateString();
            }

            fila[`curso_${curso.id}`] = "✅";
            fila[`fecha_${curso.id}`] = fechaFormateada;
          });
        });
      });

      worksheet.addRow(fila);
    }

    // Guardar y subir a Firebase Storage
    const tmpFilePath = path.join(os.tmpdir(),
        `ReporteGeneral_${Date.now()}.xlsx`);
    await workbook.xlsx.writeFile(tmpFilePath);
    const destination = `excels/ReporteGeneral.xlsx`;
    await bucket.upload(tmpFilePath, {destination});

    res.status(200).json({url: await
    bucket.file(destination).getSignedUrl({action:
            "read", expires: Date.now() + 60 * 60 * 1000})});
  } catch (error) {
    console.error("❌ Error generando el Excel:", error);
    res.status(500).json({error: error.message});
  }
});
