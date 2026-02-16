//utils/configUtil.js
const { db } = require("../config/db");

async function loadConfig(key) {
  const query = `SELECT Value FROM CONFIG WHERE KeyValue = ?`;
  const [rows] = await db.query(query, [key]);

  if (rows.length > 0) {
    return rows[0].Value;
  } else {
    return null;
  }
}
module.exports = { loadConfig };