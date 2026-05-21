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

  let title = "🔔 มีใบคำร้องค้างอนุมัติ";
  let body = `ขณะนี้มีใบคำร้องที่ยังไม่ได้รับการอนุมัติ กรุณาตรวจสอบและดำเนินการตามขั้นตอนที่เกี่ยวข้อง\n`+
         `(ข้อความนี้เป็นการแจ้งเตือนอัตโนมัติ)`;

  const message = {
    notification: { title, body},
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

      const queryDocV = `SELECT tno_pass, building_card FROM PASS_REQ_V WHERE DATE(datetime_in) = ? AND appr_status = 0`;
      const queryDocE = `SELECT tno_pass, building_card FROM PASS_REQ_E WHERE DATE(datetime_out) = ? AND appr_status = 0`;
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



const notifyOnCreate = async (type, record) => {
  try {
    if (type === 'TEMPORARY' || !record) return;

    let fcm_tokens = [];
    
    // --- 1. ค้นหา Tokens ---
    if (type === 'PERMISSION') {
      const targetUser = record.responsible_user;
      if (!targetUser) return;
      const [result] = await db.query("SELECT fcm_token FROM DEVICE_TOKEN WHERE username = ?", [targetUser]);
      fcm_tokens = result.map(r => r.fcm_token).filter(Boolean);
    } else {
      const roleMapping = { 
        Y: ["Administrator", "CardManager"], 
        N: ["Administrator", "SecurityManager", "Manager"], 
        O: ["Administrator", "SecurityManager", "Manager", "CardManager"] 
      };
      const targetRoles = roleMapping[record.building_card];
      if (!targetRoles) return;

      const rolesCondition = targetRoles.map(r => `roles LIKE '%${r}%'`).join(" OR ");
      const [result] = await db.query(`SELECT fcm_token FROM DEVICE_TOKEN WHERE ${rolesCondition}`);
      fcm_tokens = result.map(r => r.fcm_token).filter(Boolean);
    }

    const uniqueTokens = [...new Set(fcm_tokens)];
    if (uniqueTokens.length === 0) return;

    // --- 2. กำหนด Title และ Body แยกตามประเภทเอกสาร ---
    let title = "";
    let body = "";
    const docNo = record.tno_pass || record.sequence_no || "-";
    const name = record.name || record.emp_name || "ไม่ระบุชื่อ";

    switch (type) {
      case 'VISITOR':
        title = "📝 มีคำร้องใบผ่านผู้มาติดต่อใหม่";
        body = `เลขที่: ${record.sequence_no}\n` +
               `บริษัท/บุคคล: ${record.company}\n` +
               `วัตถุประสงค์: ${record.objective}`;
        break;

      case 'EMPLOYEE':
        title = "📝 มีคำร้องขอออกนอกโรงงานใหม่";
        let peopleDetails = "-";
        if (Array.isArray(record.people) && record.people.length > 0) {
          peopleDetails = record.people.map(p => {
            const title = p.TitleName || "";
            const name = p.FullName || "ไม่ระบุชื่อ";
            const dept = p.Department ? `(${p.Department})` : "";
            return `👤 - ${title}${name} ${dept}`;
          }).join('\n');
        }
        body = `เลขที่: ${record.sequence_no}\n` +
                `ประเภท: ${record.obj_desc}\n` +
                `วัตถุประสงค์: ${record.objective}\n` +
                `ผู้ขอออก:\n${peopleDetails}`;
        break;

      case 'PERMISSION':
        title = "📝 มีคำร้องขอเบิกบัตรใหม่";
        body = `ชื่อ: ${record.emp_name}\n` +
               `แผนก: ${record.emp_dept}\n` +
               `บัตรที่ยืม: ${record.brw_card}\n` +
               `สาเหตุ: ${record.reason_desc}`;
        break;

      default:
        title = "📄 มีรายการใหม่รอตรวจสอบ";
        body = ``;
    }


    // --- 3. ส่ง Notification ---
    const message = {
      notification: { title, body },
      data: {
        type: type,
        doc_id: String(record.id || ""),
        tno_pass: String(docNo),
      },
      android: {
        notification: {
          sound: "default",
          channelId: "high_priority_channel",
          priority: "high",
        },
      },
      apns: { payload: { aps: { sound: "default" } } },
      tokens: uniqueTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    
    // --- 4. Cleanup Tokens ---
    if (response.failureCount > 0) {
      const badTokens = uniqueTokens.filter((_, i) => 
        !response.responses[i].success && 
        response.responses[i].error.code === "messaging/registration-token-not-registered"
      );
      if (badTokens.length > 0) {
        await db.query("DELETE FROM DEVICE_TOKEN WHERE fcm_token IN (?)", [badTokens]);
      }
    }
    console.log(`[Notification Sent] Type: ${type}, Tokens: ${uniqueTokens.length}`);
  } catch (error) {
    console.error(`[notifyOnCreate Error]:`, error);
  }
};

module.exports = {
  notifyOnCreate,
};