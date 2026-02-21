// untils/fileUntils.js
const path = require('path');
const fs = require('fs');
const Jimp = require('jimp');
const http = require("http");
const { visitorConfig, domain } = require('../config/config');

function cleanUpFolder(folderPath, uploadedFilenames) {
  if (!fs.existsSync(folderPath)) return;
  if (!uploadedFilenames || uploadedFilenames.length <= 1) return; // ไม่มีไฟล์ใหม่ -> ไม่ลบ
  const filesInFolder = fs.readdirSync(folderPath);
  filesInFolder.forEach(file => {
    if (!uploadedFilenames.includes(file)) {
      fs.unlinkSync(path.join(folderPath, file));
    }
  });
}

function convertFilenameToUrl(filename, folder) {
  if (!filename) return null;
  return `${domain}/upload/loadImages/${folder}/${filename}`;
}


const transformFilenameToUrlDoc = (data) =>
  data.map(record => {
    let dateFolder;
    let pk;

    const fieldByType = {
      VISITOR: ["appr_sign", "media_sign", "guard_sign", "prod_sign"],
      EMPLOYEE: ["emp_sign", "appr_sign", "media_sign", "guard_sign"],
      PERMISSION: ["sign_emp", "sign_respon", "sign_guardI", "sign_guardO"],
      TEMPORARY: ["brw_sign_brw", "brw_sign_guard", "ret_sign_brw", "ret_sign_guard"]
    };

    switch (record.request_type) {
      case 'VISITOR':
        dateFolder = record.date_in;
        pk = record.tno_pass;
        break;
      case 'EMPLOYEE':
        dateFolder = record.date_out;
        pk = record.tno_pass;
        break;
      case 'PERMISSION':
        dateFolder = record.doc_date;
        pk = record.tno_pass;
        break;
      case 'TEMPORARY':
        dateFolder = record.brw_at;
        pk = record.id;
        break;
    }

    const parsedDate = new Date(dateFolder);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const ymFolder = `${year}/${month}`;

    const fields = fieldByType[record.request_type] || [];

    fields.forEach(field => {
      if (record[field]) {
        record[field] = convertFilenameToUrl(record[field], `${record.request_type}/${ymFolder}/${pk}/signatures`);
      }
    });

    if (record.people?.length) {
      record.people = record.people.map(person => ({
        ...person,
        Signature: person.Signature ? convertFilenameToUrl(person.Signature, `${record.request_type}/${ymFolder}/${pk}/people`) : null,
      }));
    }

    ["item_in", "item_out"].forEach(type => {
      if (record[type]?.images?.length > 0) {
        record[type].images = record[type].images.map(filename =>
          convertFilenameToUrl(filename, `${record.request_type}/${ymFolder}/${pk}/${type}`)
        );
      }
    });

    return record;
  });


async function copyApprovedFile(pathOut, filenameOld) {
  try {
    if (!filenameOld) {
      console.error("Filename is missing.");
      return null;
    }

    const sourceUrl = `${visitorConfig.pathImageSignatureUser}/${filenameOld}`;
    const targetFolder = path.join(visitorConfig.pathImageDocuments, pathOut, "signatures");

    if (!fs.existsSync(targetFolder)) fs.mkdirSync(targetFolder, { recursive: true });

    const targetPath = path.join(targetFolder, 'approved.png');

    return new Promise((resolve, reject) => {
      const file = fs.createWriteStream(targetPath);

      http.get(sourceUrl, response => {
        if (response.statusCode !== 200) {
          reject(new Error(`Failed to download file: HTTP ${response.statusCode}`));
          return;
        }

        const chunks = [];
        response.on('data', chunk => chunks.push(chunk));
        response.on('end', async () => {
          const buffer = Buffer.concat(chunks);

          if (buffer.length === 0) return reject(new Error('Downloaded file is empty'));

          try {
            const image = await Jimp.read(buffer);

            image.scan(0, 0, image.bitmap.width, image.bitmap.height, function (x, y, idx) {
              const r = this.bitmap.data[idx + 0];
              const g = this.bitmap.data[idx + 1];
              const b = this.bitmap.data[idx + 2];

              // ถ้าเป็นสีขาวเกือบทั้งหมด → ทำให้โปร่งใส
              if (r > 240 && g > 240 && b > 240) {
                this.bitmap.data[idx + 3] = 0; // alpha = 0
              }
            });

            await image.writeAsync(targetPath); // แปลงเป็น PNG โดยอัตโนมัติ
            resolve('approved.png');
          } catch (err) {
             reject(new Error(`Jimp failed: ${err.message}`));
          }
        });
      }).on('error', err => reject(err));

    });
  } catch (err) {
    console.error("Error copying file:", err);
    return null;
  }
}

const transformFilenameToPath = (data) =>
  data.map(record => {
    let dateFolder;
    let pk;

    const fieldByType = {
      VISITOR: ["appr_sign", "media_sign", "guard_sign", "prod_sign"],
      EMPLOYEE: ["emp_sign", "appr_sign", "media_sign", "guard_sign"],
      PERMISSION: ["sign_emp", "sign_respon", "sign_guardI", "sign_guardO"],
      TEMPORARY: ["brw_sign_brw", "brw_sign_guard", "ret_sign_brw", "ret_sign_guard"]
    };

    switch (record.request_type) {
      case 'VISITOR':
        dateFolder = record.date_in;
        pk = record.tno_pass;
        break;
      case 'EMPLOYEE':
        dateFolder = record.date_out;
        pk = record.tno_pass;
        break;
      case 'PERMISSION':
        dateFolder = record.doc_date;
        pk = record.tno_pass;
        break;
      case 'TEMPORARY':
        dateFolder = record.brw_at;
        pk = record.id;
        break;
    }

    const parsedDate = new Date(dateFolder);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const ymFolder = `${year}/${month}`;

    const fields = fieldByType[record.request_type] || [];

    fields.forEach(field => {
      if (record[field]) {
        record[field] = `${record.request_type}/${ymFolder}/${pk}/signatures/${record[field]}`;
      }
    });

    if (record.people?.length) {
      record.people = record.people.map(person => ({
        ...person,
        Signature: person.Signature ? `${record.request_type}/${ymFolder}/${pk}/people/${person.Signature}` : null,
      }));
    }

    ["item_in", "item_out"].forEach(type => {
      if (record[type]?.images?.length > 0) {
        record[type].images = record[type].images.map(filename =>
          `${record.request_type}/${ymFolder}/${pk}/${type}/${filename}`
        );
      }
    });

    return record;
  });

// ------------------------- Export ------------------------- //
module.exports = {
  cleanUpFolder,
  convertFilenameToUrl,
  transformFilenameToUrlDoc,
  copyApprovedFile,
  transformFilenameToPath
};