/* eslint-disable prefer-const */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {Storage} = require("@google-cloud/storage");
const archiver = require("archiver");
const fs = require("fs");
// const os = require("os");
// const path = require("path");
admin.initializeApp();
const storage = new Storage();
const bucket = storage.bucket("expedientesems.firebasestorage.app");
// const ExcelJS = require("exceljs");

exports.generarZip = functions.https.onRequest(async (req, res) => {
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
