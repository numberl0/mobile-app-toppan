const admin = require("firebase-admin");
const serviceAccount = require("./toppanapplication-firebase-adminsdk-fbsvc-801bad97bc.json");

if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
}

module.exports = admin;