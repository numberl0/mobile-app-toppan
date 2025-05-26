const admin = require("firebase-admin");
const serviceAccount = require("./toppanapplication-firebase-adminsdk-fbsvc-46a440bb70.json");

if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
}

module.exports = admin;