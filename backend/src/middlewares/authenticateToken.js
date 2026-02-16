const jwt = require('jsonwebtoken');

const { jwtToken } = require('../config/config');
const jwtSecret = jwtToken.key;
const JwtEnable = jwtToken.enable;

// ================================
// Authentication Middleware
// ================================
const authenticateToken = (req, res, next) => {
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

    jwt.verify(token, jwtSecret, (err, decoded) => {

        if (err) {

            // 🔥 token หมดอายุ
            if (err.name === 'TokenExpiredError') {
                return res.status(401).json({
                    message: 'Token expired'
                });
            }

            // 🔥 token ไม่ถูกต้อง
            return res.status(401).json({
                message: 'Invalid token'
            });
        }

        // แนบข้อมูล user ไปกับ request
        req.user = decoded;

        next();
    });
};
module.exports = authenticateToken;
