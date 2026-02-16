// config/db.js
const mysql = require('mysql2/promise');
const mssql = require('mssql');
const { visitorDB, hrisDB } = require('./config');

const db = mysql.createPool(visitorDB);

let poolHRIS;
async function getHRIS() {
  if (!poolHRIS) {
    try {
      poolHRIS = await mssql.connect(hrisDB);
      console.log('Connected to HRIS database');
    } catch (err) {
      console.error('HRIS DB connection failed:', err);
      throw err;
    }
  }
  return poolHRIS;
}

module.exports = { db, getHRIS };