const os = require('os');
const path = require('path');
const { execSync } = require('child_process');

// Auto-detect host IP depending on platform (Linux or Windows/Mac Docker)
function getHostIP() {
  if (process.platform === 'darwin' || process.platform === 'win32') {
    // Docker Desktop on Mac/Windows provides this special DNS name
    return 'host.docker.internal';
  } else {
    // On Linux, get default gateway IP inside container (usually host IP)
    try {
      const route = execSync('ip route').toString();
      const match = route.match(/default via ([0-9.]+)/);
      if (match && match[1]) return match[1];
    } catch (e) {
      // Ignore errors and fallback
    }
    return '127.0.0.1';
  }
}

// // Auto-detect Host IP For Use PM2
// function getHostIP() {
//     const interfaces = os.networkInterfaces();
//     for (const name of Object.keys(interfaces)) {
//         for (const iface of interfaces[name]) {
//             if (iface.family === 'IPv4' && !iface.internal) {
//                 return iface.address;
//             }
//         }
//     }
//     return '127.0.0.1'; // fallback
// }

const environment = 'test'; // test, production
const localIP = getHostIP();
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
console.log('Using pathImageDocuments:', config[environment].visitorConfig.pathImageDocuments);
console.log('Using localIP:', localIP);
module.exports = config[environment];