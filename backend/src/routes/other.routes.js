// routes/other.routes.js
const express = require('express');
const authenticateToken = require('../middlewares/authenticateToken');
const router = express.Router();
const { db } = require("../config/db");


router.get('/config-value', authenticateToken, async (req, res, next) => {
  try {
    const { key } = req.query;
    if (!key) {
      return next(new ApiError(400, "Missing 'key' query parameter"));
    }

    const [results] = await db.query('SELECT Value FROM Config WHERE KeyValue = ?', [key]);

    if (results.length === 0) {
      return next(new ApiError(404, 'Config Key Not Found'));
    }

    res.status(200).json({ value: results[0].Value });
  } catch (err) {
    next(err);
  }
});

module.exports = router;