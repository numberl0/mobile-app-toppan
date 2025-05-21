const os = require('os');
const path = require('path');

// Auto-detect local IP
function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return '127.0.0.1'; // fallback
}

const environment = 'test'; // test, production
const localIP = environment === 'test' ? getLocalIP() : '127.0.0.1';

const config = {

    // ------------------------------------------------- Test ---------------------------------------------------------- //
    test: {
        gateWayConfig: {
            port: 5000,
            ip: localIP,
            domain: `http://${localIP}:5000`,
        },
        jwtToken: {
            key: 'Toppan',
            enable: true,
        },
        ldapConfig: {
            port: 3000,
            pipe: 'auth',
            domain: 'dptf.com',
            server: '192.168.200.1',
        },
        visitorDB: {
            host: '192.168.200.170',
            user: 'root',
            password: 'iPwd4MyDb.',
            database: 'TEST_VISITOR_APP',
        },
        visitorConfig: {
            port: 3306,
            pipe: 'visitor',
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', '..', '/docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', '..', 'logError', 'visitorService'),
            notifyTime: "*/30 * * * *", // 30 minute
            clearFCMToken: '0 2 * * *', // 2 A.M.
        },
    },

    // ------------------------------------------------- Production ---------------------------------------------------------- //
    production: {
        gateWayConfig: {
            port: 5000,         // Not use this in production
            ip: '127.0.0.1',    // Not use this in production
            domain: `https://visitor.toppan-edge.co.th`,
        },
        jwtToken: {
            key: 'Toppan',
            enable: true,
        },
        ldapConfig: {
            port: 20505,
            pipe: 'auth',
            domain: 'dptf.com',
            server: '192.168.200.1',
        },
        visitorDB: {
            host: '192.168.200.170',
            user: 'root',
            password: 'iPwd4MyDb.',
            database: 'VISITORAPP',
        },
        visitorConfig: {
            port: 20506,
            pipe: 'visitor',
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', '..', '/docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', '..', 'logError', 'visitorService'),
            notifyTime: "*/30 * * * *", // 30 minute
            clearFCMToken: '0 2 * * *', // 2 A.M.
        },
    },
};

console.log(`Loaded config for: ${environment.toUpperCase()}`);
module.exports = config[environment];