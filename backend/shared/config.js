const path = require('path');

const environment = 'test'; // test, production
const localIP = '192.168.31.193';
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
            pathImageDocuments: path.join(__dirname, '..', 'service', 'visitor', 'docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', 'service', 'visitor', 'logError'),
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
            pathImageDocuments: path.join(__dirname, '..', 'service', 'visitor', 'docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', 'service', 'visitor', 'logError'),
            notifyTime: "*/30 * * * *", // 30 minute
            clearFCMToken: '0 2 * * *', // 2 A.M.
        },
    },
};

console.log(`Loaded config for: ${environment.toUpperCase()}`);
console.log('Using localIP:', localIP);
console.log('Using pathImageDocuments Visitor:', config[environment].visitorConfig.pathImageDocuments);
module.exports = config[environment];