const path = require('path');
const os = require('os');

// use for test only
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

const environment = 'production'; // test, production
const localIP = getLocalIP();
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
            port: 20505,
            pipe: 'auth',
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
            manualFilename: 'visitor_mobile_manual_'
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
            port: 20506,
            pipe: 'visitor',
            pathImageSignatureUser: 'http://192.168.200.170:81/static/uploads',
            pathImageDocuments: path.join(__dirname, '..', 'service', 'visitor', 'docImage'),
            max_logError: 10,
            path_logError: path.join(__dirname, '..', 'service', 'visitor', 'logError'),
            notifyTime: "0 * * * *", // 1 hour
            clearFCMToken: '0 2 * * *', // 2 A.M.
            manualFilename: 'visitor_mobile_manual_'
        },
    },
};

console.log(`Loaded config for: ${environment.toUpperCase()}`);
console.log('Using Domain:', config[environment].gateWayConfig.domain)
console.log('Using pathImageDocuments in Visitor:', config[environment].visitorConfig.pathImageDocuments);
module.exports = config[environment];