const jwt = require('jsonwebtoken');

const { jwtToken } = require('../config');
const jwtSecret = jwtToken.key;
const JwtEnable = jwtToken.enable;

// Authentication Middleware
const authenticateToken = (req, res, next) => {
    if (JwtEnable === false) {
        return next();
    }
    const token = req.header('Authorization')?.split(' ')[1];
    if (!token) {
        return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    jwt.verify(token, jwtSecret, (err, decoded) => {
        if (err) {
            return res.status(403).json({ message: 'Invalid or expired token.' });
        }
        req.user = decoded;
        next();
    });
};
module.exports = authenticateToken;
