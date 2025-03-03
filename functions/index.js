const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {Storage} = require("@google-cloud/storage");
const archiver = require("archiver");
const fs = require("fs");

admin.initializeApp();
const storage = new Storage();
const bucket = storage.bucket("expedientesems.firebasestorage.app");

exports.generarZipDocumentos = functions.https.onRequest(async (req, res) => {
  try {
    const [files]= await bucket.getFiles();
    const zipFileName = `documentos-${Date.now()}.zip`;
    const tempFilePath = `/tmp/${zipFileName}`;

    const archive = archiver("zip", {zlib: {level: 9}});
    const output = fs.createWriteStream(tempFilePath);
    archive.pipe(output);

    // Agregar cada archivo al ZIP manteniendo su estructura de carpetas
    for (const file of files) {
      const filePath = file.name; // Mantiene la ruta dentro del bucket
      const fileStream = file.createReadStream();
      archive.append(fileStream, {name: filePath});
    }

    await archive.finalize();

    // Subir el archivo ZIP a Firebase Storage en una carpeta específica
    await bucket.upload(tempFilePath, {
      destination: `zips/${zipFileName}`,
      metadata: {contentType: "application/zip"},
    });

    // 🔹 Generar un enlace temporal para descargar el ZIP
    const [zipFileUrl] = await bucket.file(`zips/${zipFileName}`).getSignedUrl({
      action: "read",
      expires: Date.now() + 60 * 60 * 1000, // Expira en 1 hora
    });
    res.set("Access-Control-Allow-Origin", "*");
    res.status(200).json({url: zipFileUrl});
  } catch (error) {
    console.error("Error al generar ZIP:", error);
    res.status(500).json({error: "Error al generar el archivo ZIP"});
  }
});
