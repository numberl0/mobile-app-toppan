const path = require('node:path');

const environment = 'test'; // test, production
const config = {

    // ------------------------------------------------- Test ---------------------------------------------------------- //
    test: {
        domain: `http://192.168.31.193:20509`,
        jwtToken: {
            key: 'KYg3KIuDxLkrCXqiUeSjE+kvr90wzspS8v5MKgq87as=',
            enable: true,
        },
        ldapConfig: {
            domain: 'dptf.com',
            server: '192.168.200.1',
        },
        hrisDB: {
            server: '192.168.200.10',
            user: 'view_user1',
            password: 'er*W!y2eHp9$',
            database: 'dptf_prd_0705',
            options: {
                encrypt: false,
                trustServerCertificate: true
            },
        },
        visitorDB: {
            host: '192.168.200.170',
            user: 'root',
            password: 'iPwd4MyDb.',
            database: 'TEST_VISITOR_APP',
            waitForConnections: true,
            connectionLimit: 50,
            queueLimit: 0,
            namedPlaceholders: true,
        },
        visitorConfig: {
            port: 20509,
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', 'docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', 'logError'),
            manualFilename: 'visitor_mobile_manual_'
        },
    },

    // ------------------------------------------------- Production ---------------------------------------------------------- //
    production: {
        domain: `https://visitor.toppan-edge.co.th`,
        jwtToken: {
            key: 'Toppan',
            enable: true,
        },
        ldapConfig: {
            domain: 'dptf.com',
            server: '192.168.200.1',
        },
        hrisDB: {
            server: '192.168.200.10',
            user: 'view_user1',
            password: 'er*W!y2eHp9$',
            database: 'dptf_prd_0705',
            options: {
                encrypt: false,
                trustServerCertificate: true
            },
        },
        visitorDB: {
            host: '192.168.200.170',
            user: 'root',
            password: 'iPwd4MyDb.',
            database: 'VISITORAPP',
        },
        visitorConfig: {
            port: 20509,
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', 'docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', 'logError'),
            manualFilename: 'visitor_mobile_manual_'
        },
    },
};

console.log(`Loaded config for: ${environment.toUpperCase()}`);
console.log('Using Domain:', config[environment].domain)
console.log('Using pathImageDocuments in Visitor:', config[environment].visitorConfig.pathImageDocuments);
module.exports = config[environment];