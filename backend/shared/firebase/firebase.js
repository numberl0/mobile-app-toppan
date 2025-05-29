const admin = require("firebase-admin");
const serviceAccount = require("./toppanapplication-firebase-adminsdk-fbsvc-9784ff8a9c.json");

if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
}

module.exports = admin;