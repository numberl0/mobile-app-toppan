const cron = require("node-cron");   
const admin = require("../firebase/firebase");
const { db } = require("../config/db");
const configUtil = require('../utils/configUtil');

// ---------------------------------------------- Schedule  ---------------------------------------------- //
// Function to send FCM notifications
const sendNotification = async (fcm_tokens) => {
  if (!fcm_tokens || fcm_tokens.length === 0) return;

  const uniqueTokens = [...new Set(fcm_tokens)];
  const removedTokens = new Set();

  const message = {
    notification: {
      title: "คำขออนุมัติ",
      body: "มีใบผ่าน เข้า/ออก โรงงานที่ต้องการให้คุณอนุมัติ!",
    },
    android: {
      notification: {
        sound: "default",
        channelId: "high_priority_channel",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
    tokens: uniqueTokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log("Notification sent to:", response);
    console.log(`Success: ${response.successCount}, Failure: ${response.failureCount}`);

    await Promise.all(
      response.responses.map(async (resp, index) => {
        if(!resp.success) {
          const token = uniqueTokens[index];
          console.error(`- Error for token [${token}]:`);
          console.error(`- Code: ${resp.error.code}`);
          console.error(`- Message: ${resp.error.message}`);

           if (resp.error.code === "messaging/registration-token-not-registered" && !removedTokens.has(token)) {
            await db.query("DELETE FROM DEVICE_TOKEN WHERE fcm_token = ?", [token]);
            removedTokens.add(token);
            console.log(`Removed invalid token: ${token}`);
          }
        }
      })
    );
  } catch (error) {
    console.error("Fatal error sending notification:", error);
  }
};

// Cron job to check for unsigned forms every 30 minutes
(async () => {
  const schedule = await configUtil.loadConfig("NotifyTime");
  if (!schedule) {
    console.error("Notify time config not found!");
    return;
  }

  cron.schedule(schedule, async () => {
    try {
      const today = new Date().toISOString().split("T")[0];

      const queryDocV = `SELECT tno_pass, building_card FROM PASS_REQ_V WHERE date_in = ? AND appr_status = 0`;
      const queryDocE = `SELECT tno_pass, building_card FROM PASS_REQ_E WHERE date_out = ? AND appr_status = 0`;
      const queryDocP = `SELECT tno_pass FROM PASS_REQ_P WHERE sign_respon_status = 0`;

      const [resultDocV] = await db.query(queryDocV, [today]);
      const [resultDocE] = await db.query(queryDocE, [today]);
      const [resultDocP] = await db.query(queryDocP, );

      const resultDoc = [...resultDocV, ...resultDocE, ...resultDocP];

      const buildingCardConditions = {
        Y: "Administrator,CardManager",
        N: "Administrator,SecurityManager,Manager",
        O: "Administrator,SecurityManager,Manager,CardManager",
      };

      const roleConditions = new Set();
      resultDoc.forEach((request) => {
        const roles = buildingCardConditions[request.building_card];
        if (roles) {
          roles.split(",").forEach((role) => roleConditions.add(role));
        }
      });

      if (roleConditions.size === 0) {
        console.log("No roles found for notification.");
        return;
      }

      const rolesCondition = [...roleConditions].map((role) => `roles LIKE '%${role}%'`).join(" OR ");

      const queryFCM = `SELECT fcm_token FROM DEVICE_TOKEN WHERE ${rolesCondition}`;
      const [resultFCM] = await db.query(queryFCM);

      const fcm_tokens = resultFCM.map((row) => row.fcm_token).filter(Boolean);

      if (fcm_tokens.length > 0) {
        sendNotification(fcm_tokens);
      } else {
        console.log("No devices found for the selected roles.");
      }
      if (fcm_tokens.length === 0) {
        console.log("No devices found for the selected roles.");
        return;
      } else {
        sendNotification(fcm_tokens);
      }
    } catch (err) {
      console.error(`[FCMService] DB Error: ${err.message}`);
    }
  });
  console.log(`✅ Setup cron job notify: ${schedule}`);
})();





(async () => {
  const schedule = await configUtil.loadConfig("ClearFCMToken");
  if (!schedule) {
    console.error("❌ ไม่พบค่า ClearFCMToken ใน Config");
    return;
  }
  cron.schedule(schedule, async () => {
    try {
      const query = `
        DELETE FROM DEVICE_TOKEN
        WHERE refresh_expires_at <= NOW()
      `;
      const [result] = await db.query(query);
      console.log(`✅ Deleted ${result.rowCount || result.affectedRows} expired FCM tokens.`);
    } catch (error) {
      console.error('❌ Error deleting old FCM tokens:', error);
    }
  });

  console.log(`✅ Setup cron job delete FCM: ${schedule}`);
})();