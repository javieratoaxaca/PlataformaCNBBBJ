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
  res.set("Access-Control-Allow-Origin", "*");
  try {
    console.log("Iniciando generación del Excel...");

    // 1. Obtener SOLO los empleados que están en "CursosCompletados"
    const cursosCompletadosSnapshot = await
    admin.firestore().collection("CursosCompletados").get();
    const empleadosCursos = cursosCompletadosSnapshot.docs.map((doc) => ({
      uid: doc.data().uid, // Identificador del usuario
      cursos: doc.data().IdCursosCompletados || [],
      fechas: doc.data().FechaCursoCompletado || [],
    }));

    console.log(`Se encontraron ${
      empleadosCursos.length} empleados con cursos completados.`);

    // 2. Obtener los nombres de los cursos desde la colección "Cursos"
    const cursosSnapshot = await admin.firestore().collection("Cursos").get();
    const cursos = cursosSnapshot.docs.map((doc) => ({
      id: doc.id,
      nombre: doc.data().NombreCurso || `CURSO_${doc.id}`,
    }));

    // 3. Crear el workbook y la hoja de Excel
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet("Reporte de Cursos");

    // 4. Definir columnas fijas:
    // CUPO y NOMBRE + columnas dinámicas para cada curso
    const columnas = [
      {header: "CUPO", key: "cupo", width: 12},
      {header: "NOMBRE", key: "nombre", width: 25},
    ];

    // Agregar una columna por cada curso (nombre como encabezado)
    cursos.forEach((curso) => {
      columnas.push({
        header: curso.nombre, // Nombre del curso como encabezado
        key: `curso_${curso.id}`, // Identificador para el mapeo de datos
        width: 20,
      });
    });
    worksheet.columns = columnas;

    // 5. Procesar cada empleado que completó cursos
    for (const empleado of empleadosCursos) {
      console.log(`Procesando empleado con UID: ${empleado.uid}`);

      // Buscar el CUPO y NOMBRE del empleado en la colección "User"
      let cupo = null;
      let nombreEmpleado = "No encontrado";

      const userDoc = await
      admin.firestore().collection("User").doc(empleado.uid).get();
      if (userDoc.exists) {
        cupo = userDoc.data().CUPO;
      }

      // Si encontramos el CUP0, buscamos el NOMBRE en "Empleados"
      if (cupo) {
        const empleadosSnapshot = await admin.firestore()
            .collection("Empleados")
            .where("CUPO", "==", cupo)
            .limit(1)
            .get();

        if (!empleadosSnapshot.empty) {
          nombreEmpleado = empleadosSnapshot.docs[0].data().Nombre;
        }
      }

      console.log(`Empleado: ${nombreEmpleado} - CUPO: ${cupo}`);

      // 6. Construir la fila del empleado
      const fila = {
        cupo: cupo || "NO ASIGNADO",
        nombre: nombreEmpleado,
      };

      // Verificamos los cursos completados y asignamos las fechas
      for (const curso of cursos) {
        const index = empleado.cursos.indexOf(curso.id);
        if (index !== -1) {
          const fechaTimestamp = empleado.fechas[index];
          let fechaFormateada = "NO COMPLETADO";
          if (fechaTimestamp && fechaTimestamp.toDate) {
            fechaFormateada = fechaTimestamp.toDate().toLocaleDateString();
          }
          fila[`curso_${curso.id}`] = fechaFormateada;
        } else {
          fila[`curso_${curso.id}`] = "NO COMPLETADO";
        }
      }

      // Agregar la fila al worksheet
      worksheet.addRow(fila);
    }

    // 7. Guardar el workbook en un archivo temporal
    const tmpFilePath = path.join(os.tmpdir(),
        `ReporteCursos_${Date.now()}.xlsx`);
    await workbook.xlsx.writeFile(tmpFilePath);

    // 8. Subir el archivo a Cloud Storage
    const bucket = admin.storage().bucket();
    const destination = `excels/${path.basename(tmpFilePath)}`;
    await bucket.upload(tmpFilePath, {destination});

    // 9. Generar URL firmada para descargar el archivo (válida por 1 hora)
    const file = bucket.file(destination);
    const expires = Date.now() + 60 * 60 * 1000;
    const [url] = await file.getSignedUrl({action: "read", expires});

    // 10. Eliminar el archivo temporal
    fs.unlinkSync(tmpFilePath);

    res.status(200).json({url});
  } catch (error) {
    console.error("Error generando el Excel:", error);
    res.status(500).json({error: error.message});
  }
});
