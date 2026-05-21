const jwt = require('jsonwebtoken');
const { db } = require("../config/db");

const { jwtToken } = require('../config/config');
const jwtSecret = jwtToken.key;
const JwtEnable = jwtToken.enable;

// ================================
// Authentication Middleware
// ================================
const authenticateToken = async (req, res, next) => {
    try {
    // ถ้า disable JWT (เช่น dev mode)
    if (JwtEnable === false) {
        return next();
    }
    const authHeader = req.headers['authorization'];
    if (!authHeader) {
        return res.status(401).json({
            message: 'Access denied. No token provided.'
        });
    }
    const token = authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({
            message: 'Invalid authorization format.'
        });
    }

    const decoded = jwt.verify(token, jwtSecret);

    const [rows] = await db.query(
            `SELECT device_id FROM DEVICE_TOKEN WHERE device_id = ?`,
            [decoded.deviceId]
        );

    if (!rows.length) {
        return res.status(401).json({
            message: 'Session revoked'
        });
    }

    req.user = decoded;
    return next();

    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ message: 'Token expired' });
        }

        return res.status(401).json({ message: 'Invalid token' });
    }
};
module.exports = authenticateToken;
