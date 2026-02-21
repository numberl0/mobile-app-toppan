// routes/approved.routes.js
const express = require('express');
const authenticateToken = require('../middlewares/authenticateToken');
const router = express.Router();
const { db } = require("../config/db");
const { copyApprovedFile, transformFilenameToUrlDoc } = require("../utils/fileUntils");

// ---------------------------------------------- Get ---------------------------------------------- //
router.get(`/requests`, authenticateToken, async (req, res, next) => {
  try {
    let { username, building_card } = req.query;
    if (!building_card) {
      return next(new ApiError(400, 'Missing parameter.'));
    }
    if (!Array.isArray(building_card)) {
      building_card = [building_card];
    }

    if (building_card.length === 0) {
      return next(new ApiError(400, 'Invalid or empty building_card list'));
    }

    const queryV = `
      SELECT 
        pr.*,
        pf.people,
        pf.item_in,
        pf.item_out
      FROM PASS_REQ_V pr 
      LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
      WHERE pr.appr_status = 0 AND pr.building_card IN (?)
      ORDER BY CONCAT(pr.date_in, ' ', pr.time_in) DESC
    `;

    const queryE = `
      SELECT 
        pr.*,
        pf.people,
        pf.item_in,
        pf.item_out
      FROM PASS_REQ_E pr 
      LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
      WHERE pr.appr_status = 0 AND pr.building_card IN (?)
      ORDER BY CONCAT(pr.date_out, ' ', pr.time_out) DESC
    `;

    const queryP = `
      SELECT * FROM PASS_REQ_P
      WHERE sign_respon_status != 1 AND responsible_user = ?
      ORDER BY doc_date DESC
    `;

     const [[passV], [passE], [passP]] = await Promise.all([
      db.query(queryV, [building_card]),
      db.query(queryE, [building_card]),
      db.query(queryP, [username]),
    ]);

    const resultV = transformFilenameToUrlDoc(passV);
    const resultE = transformFilenameToUrlDoc(passE);
    const resultP = transformFilenameToUrlDoc(passP);


    res.status(200).json({
      message: "Query successful",
      visitor: resultV,
      employee: resultE,
      permission: resultP,
    });
  } catch (err) {
    next(err);
  }
});



router.get(`/notify-request`, authenticateToken, async (req, res, next) => {
  try {
    let {username, roles} = req.query;

    if (!roles) roles = [];
    if (!Array.isArray(roles)) roles = [roles];

    let building_card = ['O'];

    for (const role of roles) {
      if (role === 'Administrator') {
        building_card = ['O', 'Y', 'N'];
        break;
      }

      switch (role) {
        case 'Manager':
        case 'SecurityManager':
          if (!building_card.includes('N')) {
            building_card.push('N');
          }
          break;

        case 'CardManager':
          if (!building_card.includes('Y')) {
            building_card.push('Y');
          }
          break;
      }
    }

    const today = new Date();
    const dateToDay = today.toISOString().split('T')[0];

    const prevDate = new Date(today);
    prevDate.setDate(prevDate.getDate() - 1);
    const datePrevDay = prevDate.toISOString().split('T')[0];

    const adminRoles = [
      'Administrator',
      'SecurityManager',
      'Manager',
      'CardManager'
    ];

    const isIntermediate = roles.includes('Intermediate');
    const isManager = adminRoles.some(r => roles.includes(r));

    if (!isIntermediate && !isManager) {
      return res.status(200).json({
        totalV: 0,
        totalE: 0,
        totalP: 0,
        totalT: 0,
        totalAll: 0
      });
    }

    const queries = [];

    if(isIntermediate) {
      queries.push(
      {
        key: 'V',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_V pr
          WHERE pr.appr_status = 0 AND pr.date_out BETWEEN ? AND ?
        `,
        params: [datePrevDay, dateToDay]
      },
      {
        key: 'E',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_E pr
          WHERE pr.appr_status = 0 AND pr.date_out BETWEEN ? AND ?
        `,
        params: [datePrevDay, dateToDay]
      },
      {
        key: 'P',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_P
          WHERE sign_respon_status != 1 
            AND (responsible_user IS NULL OR responsible_user = '')
        `,
        params: []
      },
      {
        key: 'T',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_T
          WHERE ret_status != 1 AND brw_at BETWEEN ? AND ?
        `,
        params: [datePrevDay, dateToDay]
      }
    );

    } else if(isManager) {
      queries.push(
      {
        key: 'V',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_V pr
          LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
          WHERE pr.appr_status = 0 AND pr.building_card IN (?)
        `,
        params: [building_card]
      },
      {
        key: 'E',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_E pr
          LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
          WHERE pr.appr_status = 0 AND pr.building_card IN (?)
        `,
        params: [building_card]
      },
      {
        key: 'P',
        sql: `
          SELECT COUNT(*) AS total
          FROM PASS_REQ_P
          WHERE sign_respon_status = 0 AND responsible_user = ?
        `,
        params: [username]
      }
    );

    } else {
      res.status(200).json({
        message: "Query successful",
      });
    }

    const results = await Promise.all(
      queries.map(q => db.query(q.sql, q.params))
    );
    
    let countV = 0;
    let countE = 0;
    let countP = 0;
    let countT = 0;

    results.forEach((r, i) => {
      const key = queries[i].key;
      const total = r?.[0]?.[0]?.total ?? 0;

      if (key === 'V') countV = total;
      if (key === 'E') countE = total;
      if (key === 'P') countP = total;
      if (key === 'T') countT = total;
    });

    const totalAll = countV + countE + countP + countT;

    res.status(200).json({
      hasNotification: totalAll > 0
    });

  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------- Update ---------------------------------------------- //
// update approved document
router.patch(`/document/:tno_pass`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();
    const { tno_pass } = req.params;
    const { type, date, sign_info, username} = req.body;

    if(!tno_pass || !type || !date || !sign_info || !username) {
      await connection.rollback();
      return next(new ApiError(400, 'Missing parameter.'));
    }

    // check user have signature file in account
    const [userRows] = await connection.query(`SELECT sign_name FROM USER WHERE username = ? AND sign_name IS NOT NULL AND sign_name != ''`,
      [username]
    );
    
    if (userRows.length === 0) {
      await connection.rollback();
      return res.status(200).json({
        message: "User does not have a signature file.",
        success: false,
        flag: 'no_signature',
      });
    }

    const documentMap = {
      VISITOR:  { table: 'PASS_REQ_V', checkField: 'appr_status', signatureField: 'appr_sign' },
      EMPLOYEE: { table: 'PASS_REQ_E', checkField: 'appr_status', signatureField: 'appr_sign' },
      PERMISSION: { table: 'PASS_REQ_P', checkField: 'sign_respon_status', signatureField: 'sign_respon' },
    };

    const docType = documentMap[type.toUpperCase()];
    if (!docType) {
      await connection.rollback();
      return next(new ApiError(400, 'Missing parameter.'));
    }

    const queryCheck = `SELECT tno_pass FROM ${docType.table} WHERE ${docType.checkField} = 0 AND tno_pass = ?`;
    const [pendingRequests] = await connection.query(queryCheck, [tno_pass]);
    if (pendingRequests.length === 0) {
      await connection.rollback();
      return res.status(200).json({
        message: 'This request has already been approved or does not exist.',
        success: false,
        flag: 'already_approved',
      });
    }

    const jsDate = new Date(date);
    const year = jsDate.getFullYear();
    const month = String(jsDate.getMonth() + 1).padStart(2, '0');

    const path = `${type.toUpperCase()}/${year}/${month}/${tno_pass}`;

    // copy signature move to visitor-mobile
    const filename = await copyApprovedFile(path, userRows[0].sign_name);
    if(!filename){
      await connection.rollback();
      return next(new ApiError(404, 'Failed to move signature file.'));
    }

    sign_info[docType.signatureField] = filename;

    // prepare date for update
    const fields = Object.keys(sign_info).map(key => `${key} = ?`).join(", ");
    const values = Object.values(sign_info);
    values.push(tno_pass);

    const queryUpdate = `UPDATE ${docType.table} SET ${fields} WHERE tno_pass = ?`;
    await connection.query(queryUpdate, values);

    await connection.commit();
     res.status(200).json({
      message: "Approved request successfully.",
      success: true,
      flag: 'approved',
    });
  } catch (err) {
    if (connection) {
      await connection.rollback();
    }
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

//update approved document all
router.patch(`/list_document`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection();
    await connection.beginTransaction();

    const { docType, tno_listMap, sign_info, username } = req.body

    if (!docType || !tno_listMap || !sign_info || !username) {
      return next(new ApiError(400, 'Missing parameter.'));
    }

    const [userRows] = await connection.query(`SELECT sign_name FROM USER WHERE username = ? AND sign_name IS NOT NULL AND sign_name != ''`,
      [username]
    );
    if (userRows.length === 0) {
      await connection.rollback();
      return res.status(200).json({
        message: "User does not have a signature file.",
        success: false,
        flag: 'no_signature',
      });
    }

    const tno_list = tno_listMap.map(item => item.tno_pass);
    if (tno_list.length === 0) {
      await connection.rollback();
      return next(new ApiError(400, 'Missing tno_pass values.'));
    }

    const documentMap = {
      VISITOR:  { table: 'PASS_REQ_V', checkField: 'appr_status', signatureField: 'appr_sign' },
      EMPLOYEE: { table: 'PASS_REQ_E', checkField: 'appr_status', signatureField: 'appr_sign' },
      PERMISSION: { table: 'PASS_REQ_P', checkField: 'sign_respon_status', signatureField: 'sign_respon' },
    };

    const docMapping = documentMap[docType.toUpperCase()];
    if (!docMapping) {
      await connection.rollback();
      return next(new ApiError(400, 'Invalid docType.'));
    }

    // เช็คก่อนว่ารายการไหน approved_status = 0 (ยังไม่อนุมัติ)
    const tnoPlaceholders = tno_list.map(() => '?').join(',');
     const [pendingRequests] = await connection.query(
      `SELECT tno_pass FROM ${docMapping.table} 
       WHERE ${docMapping.checkField} = 0 
       AND tno_pass IN (${tnoPlaceholders})`,
      tno_list
    );
    if (pendingRequests.length === 0) {
      await connection.rollback();
      return res.status(200).json({
        message: 'This request has already been approved or does not exist.',
        success: false,
        flag: 'already_approved',
      });
    }

    const pending_tnos = pendingRequests.map(row => row.tno_pass);

    let filenameForSignInfo = '';
    for (const item of tno_listMap) {
      if (pending_tnos.includes(item.tno_pass)) {
        const copiedFile  = await copyApprovedFile(
          item.path,
          userRows[0].sign_name
        );
        if (!copiedFile ) {
          await connection.rollback();
          return next(new ApiError(500, 'Failed to move signature file.'));
        }
        if (!filenameForSignInfo) {
          filenameForSignInfo = copiedFile;
        }
      }
    }
    sign_info[docMapping.signatureField] = filenameForSignInfo;

    const fields = Object.keys(sign_info).map(key => `${key} = ?`).join(", ");
    const values = Object.values(sign_info);
    values.push(...pending_tnos);
    const updateQuery = `UPDATE ${docMapping.table} SET ${fields} WHERE tno_pass IN (${pending_tnos.map(() => '?').join(", ")})`;
    await connection.query(updateQuery, values);
    await connection.commit();
     res.status(200).json({
      message: "Approved requests successfully.",
      success: true,
      flag: 'approved',
    });

  } catch (err) {
    if (connection) {
      await connection.rollback();
    }
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

module.exports = router;