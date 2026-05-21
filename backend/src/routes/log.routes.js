// routes/log.routes.js
const express = require('express');
const router = express.Router();
const path = require('path');
const { visitorConfig } = require('../config/config');
const fs = require('fs');
const authenticateToken = require('../middlewares/authenticateToken');
const { db } = require("../config/db");

function logError(message, stack, timestamp) {
  const pathLogError = visitorConfig.path_logError;
  if (!fs.existsSync(pathLogError)) fs.mkdirSync(pathLogError, { recursive: true });
  const date = timestamp.split(" ")[0];
  const logFilePath = path.join(pathLogError, `logError_${date}.txt`);
  const logEntry = `\n[${timestamp}] \n[Error] ${message} \n[Stack Trace]\n${stack}\n-------------------`;

  fs.appendFileSync(logFilePath, logEntry);

  const logFiles = fs.readdirSync(pathLogError)
    .filter(file => file.startsWith("logError_") && file.endsWith(".txt"))
    .map(file => ({ name: file, time: fs.statSync(path.join(pathLogError, file)).ctime.getTime() }))
    .sort((a, b) => a.time - b.time);

  while (logFiles.length > visitorConfig.max_logError) {
    fs.unlinkSync(path.join(pathLogError, logFiles.shift().name));
  }
}

// API to handle incoming error logs
router.post(`/log-error`, (req, res) => {
  const { message, stack, timestamp } = req.body;
  logError(message, stack, timestamp);
  res.status(200).send("Write error logged successfully");
});

// Insert Activity Log
router.post(`/activity-log`, authenticateToken, async (req, res, next) => {
  try {
    const data = req.body;

    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return next(new ApiError(400, 'Invalid Data'));
    }

    const query = `INSERT INTO LOG_MOBILE_APP SET ?`;

    const [result] = await db.query(query, [data]);

    if (!result || result.affectedRows === 0) {
      return next(new ApiError(400, 'Insert failed'));
    }

    res.status(200).json({ message: 'Insert activity successful' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;