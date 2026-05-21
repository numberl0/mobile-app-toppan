// routes/upload-image.routes.js
const express = require('express');
const authenticateToken = require('../middlewares/authenticateToken');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { cleanUpFolder } = require('../utils/fileUntils');
const { visitorConfig } = require('../config/config');


const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const { tno, date, typeForm} = req.body;
    const basePath = visitorConfig.pathImageDocuments;

    // Extract year and month from date
    const parsedDate = new Date(date);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const tnoFolder = path.join(basePath, typeForm, `${year}`, `${month}`, tno);

    // Map fieldname to folder
    const folderMap = {
      'people[]': 'people',
      'item_in[]': 'item_in',
      'item_out[]': 'item_out',
      'sign[]': 'signatures'
    };

    const fieldFolder = folderMap[file.fieldname];
    if (!fieldFolder) return cb(new Error('Unknown fieldname'), null);

    const finalPath = path.join(tnoFolder, fieldFolder);

    // สร้างเฉพาะ folder ของฟิลด์นี้
    if (!fs.existsSync(finalPath)) {
      fs.mkdirSync(finalPath, { recursive: true });
    }

    cb(null, finalPath);
  },
  filename: (req, file, cb) => {
  const fileName = file.originalname;
    cb(null, fileName);
  }
});

// Initialize multer with storage settings
const upload = multer({ 
  storage: storage,  limits: {
  fileSize: 1 * 1024 * 1024 // 10 MB per file
  } 
});


// ========================
// ROUTE
// ========================
router.post(`/image-files`, authenticateToken, upload.fields([
  { name: 'people[]'},
  { name: 'item_in[]'},
  { name: 'item_out[]'},
  { name: 'sign[]'}
]), (req, res, next) => {
  if (!req.files || Object.keys(req.files).length === 0) {
    return res.status(400).send('No files uploaded.');
  }

  try {
    const { mode = 'append', tno, date, typeForm } = req.body;

    if (!tno || !date || !typeForm) {
      return res.status(400).send('Missing required fields (tno, date, typeForm)');
    }

    const parsedDate = new Date(date);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const basePath = visitorConfig.pathImageDocuments;
    const tnoFolder = path.join(basePath, typeForm, `${year}`, `${month}`, tno);

    const uploadedFiles = req.files || {};

    const folderMap = {
      'people[]': 'people',
      'item_in[]': 'item_in',
      'item_out[]': 'item_out',
      'sign[]': 'signatures'
    };

    // ========================
    // REPLACE MODE
    // ========================
    if (mode === 'replace') {
      for (const [key, folderName] of Object.entries(folderMap)) {
          const folderPath = path.join(tnoFolder, folderName);
          const uploadedFileNames = (uploadedFiles[key] || []).map(file => file.filename);
          cleanUpFolder(folderPath, uploadedFileNames);
      }
    }

    // =========================
    // MODE: APPEND (default)
    // =========================
    return res.status(200).json({
        message:
          mode === 'replace'
            ? 'Replace upload success'
            : 'Append upload success',
        mode: mode,
        files: req.files || {}
      });
  } catch (err) {
    next(err);
  }

});

// load image directory
router.use(`/loadImages`, express.static(visitorConfig.pathImageDocuments));

module.exports = router;