const path = require('path');

const environment = 'test'; // test, production

const config = {

    // ------------------------------------------------- Test ---------------------------------------------------------- //
    test: {
        gateWayConfig: {
            port: 5000,
            ip: '127.0.0.1',
            // http_ip: `http://127.0.0.1:5000`,
            // http_ip: `http://10.0.2.2:5000`,
            // http_ip: `http://192.168.31.193:5000`,
            http_ip: `http://192.168.31.228:5000`,
        },
        jwtToken: {
            key: 'Toppan',
            enable: true,
        },
        ldapConfig: {
            port: 3000,
            pipe: '',
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
            pipe: '',
            harderIp: 'visitor',
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', '..', '/uploadImageForm'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', '..', 'logError', 'visitorService'),
            notifyTime: "*/30 * * * *",
        },
    },

    // ------------------------------------------------- Production ---------------------------------------------------------- //
    production: {
        gateWayConfig: {
            port: 5000,
            ip: '127.0.0.1',
            http_ip: `http://127.0.0.1:5000`,
        },
        jwtToken: {
            key: 'Toppan',
            enable: true,
        },
        ldapConfig: {
            port: 3000,
            pipe: '',
            domain: 'dptf.com',
            server: '192.168.200.1',
        },
        VisitorDB: {
            host: '192.168.200.170',
            user: 'root',
            password: 'iPwd4MyDb.',
            database: 'TEST_VISITOR_APP',
        },
        visitorConfig: {
            port: 3306,
            pipe: '',
            harderIp: 'visitor',
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', '..', '/uploadImageForm'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', '..', 'logError', 'visitorService'),
            notifyTime: "*/30 * * * *",
        },
    },
};

console.log(`Loaded config for: ${environment.toUpperCase()}`);
module.exports = config[environment];