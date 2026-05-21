// routes/document.routes.js
const express = require('express');
const authenticateToken = require('../middlewares/authenticateToken');
const router = express.Router();
const ApiError = require('../utils/apiError');
const path = require('path');
// day
const dayjs = require('dayjs');
const utc = require('dayjs/plugin/utc');
const timezone = require('dayjs/plugin/timezone');
dayjs.extend(utc);
dayjs.extend(timezone);

const { db } = require("../config/db");
const { transformFilenameToUrlDoc } = require('../utils/fileUntils');
const { updateCardState } = require('../utils/cardUtil');
const { notifyOnCreate } = require('../cron/notify.cron');
const { visitorConfig } = require('../config/config');

// ---------------------------------------------- Get Information ---------------------------------------------- //
// Search by date : yyyy-MM-dd
router.get(`/requests`, authenticateToken, async (req, res, next) => {
  try {
    const {dateToDay} = req.query;
    if (!dateToDay) {
      return next(new ApiError(400, 'Date parameter (yyyy-MM-dd) is missing'));
    }

    const prevDate = new Date(dateToDay);
    prevDate.setDate(prevDate.getDate() - 1);
    const datePrevDay = prevDate.toISOString().split('T')[0];

    const queryPassReqV = `
    SELECT
        pr.*,
        pf.visitorType,
        pf.people,
        pf.item_in,
        pf.item_out
    FROM PASS_REQ_V pr
    LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
    WHERE pr.request_type = 'VISITOR' AND DATE(pr.datetime_in) IN (?, ?)
    ORDER BY pr.datetime_in DESC
    `;

    const queryVisitorNormal = `
    SELECT 
      vn.*,
      vf.visitorType,
      vf.people
      FROM VISITOR_NORMAL vn
      LEFT JOIN VISITOR_FORM vf ON vn.tno = vf.tno
      LEFT JOIN PASS_REQ_V pr ON vn.tno = pr.tno_ref
      WHERE DATE(vn.date_visitor1) IN (?, ?)
      AND NOT EXISTS (SELECT 1 FROM PASS_REQ_V pr WHERE pr.tno_ref = vn.tno);
    `;

    const queryVisitorExpress = `
    SELECT 
      ve.*,
      vf.visitorType,
      vf.people
      FROM VISITOR_EXPRESS ve
      LEFT JOIN VISITOR_FORM vf ON ve.tno = vf.tno
      LEFT JOIN PASS_REQ_V pr ON ve.tno = pr.tno_ref
      WHERE DATE(ve.date_visitor) IN (?, ?)
      AND NOT EXISTS (SELECT 1 FROM PASS_REQ_V pr WHERE pr.tno_ref = ve.tno);
    `;

     const queryPassReqE = `
      SELECT
          pr.*,
          pf.visitorType,
          pf.people,
          pf.item_in,
          pf.item_out
      FROM PASS_REQ_E pr
      LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
      WHERE pr.request_type = 'EMPLOYEE' AND DATE(pr.datetime_out) IN (?, ?)
      ORDER BY pr.datetime_out DESC
    `;

    const queryPassReqP = `
    SELECT * FROM PASS_REQ_P
    WHERE sign_respon_status != 1 OR  sign_guardI_status != 1 OR  sign_guardO_status != 1
    `;
    
    const queryPassTemporary = `
    SELECT * FROM PASS_REQ_T
    WHERE ret_status != 1
    `;

    const [[passResV], [normalResults], [expressResults], [passResE], [passResP], [passTemp]] = await Promise.all([
      db.query(queryPassReqV, [dateToDay, datePrevDay]),
      db.query(queryVisitorNormal, [dateToDay, datePrevDay]),
      db.query(queryVisitorExpress, [dateToDay, datePrevDay]),

      db.query(queryPassReqE, [dateToDay, datePrevDay]),
      db.query(queryPassReqP),
      db.query(queryPassTemporary),
    ]);

    // convert like pass_req_v
    const formattedVNResults = normalResults.map(entry => {
      const date = entry['date_visitor1'];
      const time = entry['timerang'] ? entry['timerang'].split(' ถึง ')[0] : null;
      let datetimeIn = null;
      if (date && time) {
        const d = new Date(date);
        const [h, m] = time.split(':');
        d.setHours(parseInt(h), parseInt(m), 0, 0);
        datetimeIn = d;
      }
      return {
        'tno_pass': null,
        'request_type': 'VISITOR',
        'sequence_no': null,
        'company': entry['company']? entry['company']:null,
        'vehicle_no': null,
        'datetime_in' : datetimeIn,
        'datetime_out' : null,
        'contact': entry['response_name']? entry['response_name']:null,
        'contact_dept': entry['dept']? entry['dept']:null,
        'objective': entry['purpose']? entry['purpose']:null,
        'building_card': entry['building_card']? entry['building_card']:null,
        'area': entry['area']? entry['area']:null,
        'appr_status': 0,
        'appr_sign': null,
        'appr_at': null,
        'appr_by': null,
        'media_status': 0,
        'media_sign': null,
        'media_at': null,
        'media_by': null,
        'guard_status': 0,
        'guard_sign': null,
        'guard_at': null,
        'guard_by': null,
        'prod_status': 0,
        'prod_sign': null,
        'prod_at': null,
        'prod_by': null,
        'tno_ref': entry['tno']? entry['tno']:null,
        'visitorType': 'V',
        'people': entry['people']? entry['people']:null,
        'item_in': null,
        'item_out': null,
      };
    });

    // convert like pass_req_v
    const formattedVEResults = expressResults.map(entry => {
      const date = entry['date_visitor'];
      const time = entry['timerang'] ? entry['timerang'].split(' ถึง ')[0] : null;
      let datetimeIn = null;
      if (date && time) {
        const d = new Date(date);
        const [h, m] = time.split(':');
        d.setHours(parseInt(h), parseInt(m), 0, 0);
        datetimeIn = d;
      }
      return {
        'tno_pass': null,
        'request_type': 'VISITOR',
        'sequence_no': null,
        'company': entry['company']? entry['company']:null,
        'vehicle_no': null,
        'datetime_in' : datetimeIn,
        'datetime_out' : null,
        'contact': entry['to_visit_name']? entry['to_visit_name']:null,
        'contact_dept': entry['to_visit_dept']? entry['to_visit_dept']:null,
        'objective': entry['purpose']? entry['purpose']:null,
        'building_card': entry['building_card']? entry['building_card']:null,
        'area': entry['area']? entry['area']:null,
        'appr_status': 0,
        'appr_sign': null,
        'appr_at': null,
        'appr_by': null,
        'media_status': 0,
        'media_sign': null,
        'media_at': null,
        'media_by': null,
        'guard_status': 0,
        'guard_sign': null,
        'guard_at': null,
        'guard_by': null,
        'prod_status': 0,
        'prod_sign': null,
        'prod_at': null,
        'prod_by': null,
        'tno_ref': entry['tno']? entry['tno']:null,
        'visitorType': 'V',
        'people': entry['people']? entry['people']:null,
        'item_in': null,
        'item_out': null,
      };
    });

    // Transform image filenames into URLs
    const transformInUrlV = transformFilenameToUrlDoc(passResV);
    const transformInUrlE = transformFilenameToUrlDoc(passResE);
    const transformInUrlP = transformFilenameToUrlDoc(passResP);
    let listDataV = [...transformInUrlV, ...formattedVNResults, ...formattedVEResults];
    listDataV.sort((a, b) => {
      return new Date(b.datetime_in) - new Date(a.datetime_in);
    });
    let listDataE = [...transformInUrlE];
    let listDataP = [...transformInUrlP];


    // format date
    const TIMEZONE = 'Asia/Bangkok';
    const formatDateTime = (datetime) => datetime ? dayjs.utc(datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss') : null;
    listDataV = listDataV.map(entry => ({
      ...entry,
      datetime_in: formatDateTime(entry.datetime_in),
      datetime_out: formatDateTime(entry.datetime_out),
      approved_datetime: formatDateTime(entry.approved_datetime),
      media_datetime: formatDateTime(entry.media_datetime),
      mainEn_datetime: formatDateTime(entry.mainEn_datetime),
      proArea_datetime: formatDateTime(entry.proArea_datetime),
    }));

    listDataE = listDataE.map(entry => ({
      ...entry,
      datetime_in: formatDateTime(entry.datetime_in),
      datetime_out: formatDateTime(entry.datetime_out),
      empSign_datetime: formatDateTime(entry.empSign_datetime),
      approved_datetime: formatDateTime(entry.approved_datetime),
      media_datetime: formatDateTime(entry.media_datetime),
      mainEn_datetime: formatDateTime(entry.mainEn_datetime),
    }));

    res.status(200).json({
      message: "Data found",
      visitor: listDataV,
      employee: listDataE,
      permission: listDataP,
      temporary: passTemp,
    });
  } catch (err) {
    next(err);
  }

});

router.get(`/temporary-since-yesterday`, authenticateToken, async (req, res, next) => {
  try {
    const query = `
      SELECT * FROM PASS_REQ_T
      WHERE brw_at >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)
      ORDER BY brw_at DESC;
    `;

    const [results] = await db.query(query);

    res.status(200).json({
      message: 'Temporary records fetched successfully',
      data: results || []
    });
  } catch (err) {
    next(err);
  }
});

router.get(`/agreement`, authenticateToken, async (req, res, next) => {
  try {
    const [results] = await db.query('SELECT * FROM AGREEMENT WHERE inUse=1');
    if (results.length === 0) {
      return next(new ApiError(404, 'Agreement Not Found'))
    }
    res.status(200).json({ message: 'Agreement Found', data: results });
  } catch (err) {
    next(err);
  }
});

router.get(`/building`, authenticateToken, async (req, res, next) => {
  try {
    const [results] = await db.query('SELECT * FROM BUILDING');
    if (results.length === 0) {
      return next(new ApiError(404, 'No Buildings Found'));
    }
    res.status(200).json({ message: 'Building Found', data: results });
  } catch (err) {
    next(err);
  }
});

// download manual
router.get('/manual', (req, res) => {
  const role = req.query.role?.toLowerCase();

  // Validate role
  if (!['user', 'approver'].includes(role)) {
    return res.status(400).send('Invalid or missing role. Use ?role=user or ?role=approver');
  }

  const filename = `${visitorConfig.manualFilename}${role}.pdf`;
  const filePath = path.join(__dirname, '..' ,'manual', filename);

  console.log('Serving file:', filePath);

  res.download(filePath, filename, err => {
    if (err) {
      console.error('Error sending file:', err);
      if (!res.headersSent) {
        res.status(500).send('Failed to download file');
      }
    }
  });
});


// ---------------------------------------------- Insert Table ---------------------------------------------- //
// Visitor
router.post(`/request-form-v`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    let { requestRawData, formRawData } = req.body;

    const requestType = req.body.requestRawData['request_type'];
    if (!requestType) {
      throw new ApiError(400, 'Missing request_type in request body.');
    }
    
    // Update sequence
    await connection.query(
      `UPDATE SEQUENCE_RUNNING_FORM 
       SET sequence = LAST_INSERT_ID(sequence + 1)
       WHERE type = ?`,
      [requestType]
    );

    // Insert Request
    const [[{ sequence }]] = await connection.query('SELECT LAST_INSERT_ID() AS sequence');
    const seqPadded = sequence.toString().padStart(6, '0');
    requestRawData = { ...requestRawData , sequence_no: seqPadded };
    const ReqKeys = Object.keys(requestRawData);
    const ReqValues = Object.values(requestRawData);
    const setClauses = ReqKeys.map(key => `${key} = ?`).join(', ');
    const reqQuery = `INSERT INTO PASS_REQ_V SET ${setClauses}`;
    await connection.query(reqQuery, ReqValues);

    // Insert Form
    const formJsonData = {
      tno_pass: formRawData.tno_pass,
      visitorType: formRawData.visitorType,
      people: JSON.stringify(formRawData.people), 
      item_in: JSON.stringify(formRawData.item_in),
      item_out: JSON.stringify(formRawData.item_out),
    };
    const formKeys = Object.keys(formJsonData); 
    const formValues = Object.values(formJsonData); 
    const setClausesForm = formKeys.map(key => `\`${key}\` = ?`).join(', ');
    const formQuery = `INSERT INTO PASS_FORM SET ${setClausesForm}`;
    const [result] = await connection.query(formQuery, formValues);

    // passcard update
    const cardIds = (formRawData.people || []).map(p => p.Card_Id).filter(Boolean);
    updateCardState({
      connection,
      actionType: 'BORROW',
      cardIds
    });
    
    // Commit
    await connection.commit();

    notifyOnCreate('VISITOR', requestRawData);

    res.status(200).json({ 
        message: 'Insert RequestForm successfully', 
        tno_pass: requestRawData.tno_pass, 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('RequestForm Transaction Error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Employee
router.post(`/request-form-e`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    let { requestRawData, formRawData } = req.body;

    const requestType = req.body.requestRawData['request_type'];
    if (!requestType) {
      throw new ApiError(400, 'Missing request_type in request body.');
    }
    
    // Update sequence
    await connection.query(
      `UPDATE SEQUENCE_RUNNING_FORM 
       SET sequence = LAST_INSERT_ID(sequence + 1)
       WHERE type = ?`,
      [requestType]
    );

    // Insert Request
    const [[{ sequence }]] = await connection.query('SELECT LAST_INSERT_ID() AS sequence');
    const seqPadded = sequence.toString().padStart(6, '0');
    requestRawData = { ...requestRawData , sequence_no: seqPadded };
    const ReqKeys = Object.keys(requestRawData);
    const ReqValues = Object.values(requestRawData);
    const setClauses = ReqKeys.map(key => `${key} = ?`).join(', ');
    const reqQuery = `INSERT INTO PASS_REQ_E SET ${setClauses}`;
    await connection.query(reqQuery, ReqValues);

    // Insert Form
    const formJsonData = {
      tno_pass: formRawData.tno_pass,
      visitorType: formRawData.visitorType,
      people: JSON.stringify(formRawData.people), 
      item_in: JSON.stringify(formRawData.item_in),
      item_out: JSON.stringify(formRawData.item_out),
    };
    const formKeys = Object.keys(formJsonData); 
    const formValues = Object.values(formJsonData); 
    const setClausesForm = formKeys.map(key => `\`${key}\` = ?`).join(', ');
    const formQuery = `INSERT INTO PASS_FORM SET ${setClausesForm}`;
    const [result] = await connection.query(formQuery, formValues);
    
    // Commit
    await connection.commit();

    notifyOnCreate('EMPLOYEE', {...requestRawData, people: formRawData.people});

    res.status(200).json({ 
        message: 'Insert RequestForm successfully', 
        tno_pass: requestRawData.tno_pass, 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('RequestForm Transaction Error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Permission
router.post(`/request-form-p`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    let {docData} = req.body;
    const requestType = req.body.docData['request_type'];
    if (!requestType) {
      throw new ApiError(400, 'Missing request_type in request body.');
    }


    docData = { ...docData };
    const ReqKeys = Object.keys(docData);
    const ReqValues = Object.values(docData);
    const setClauses = ReqKeys.map(key => `${key} = ?`).join(', ');
    const reqQuery = `INSERT INTO PASS_REQ_P SET ${setClauses}`;
    await connection.query(reqQuery, ReqValues);
    
    // passcard update
    updateCardState({
      connection,
      actionType: 'BORROW',
      cardIds: [docData.brw_card],
    });
    
    // Commit
    await connection.commit();

    notifyOnCreate('PERMISSION', docData);

    res.status(200).json({ 
        message: 'Insert RequestForm successfully', 
        tno_pass: docData.tno_pass, 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('RequestForm Transaction Error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});



// Temporary
router.post(`/temporary`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const { requestData } = req.body;
    if (!req.body.requestData || typeof req.body.requestData !== 'object') {
      throw new ApiError(400, 'Missing or invalid requestData in request body.');
    }

    const { request_type } = requestData;
    if (!request_type) {
      throw new ApiError(400, 'Missing request_type in request body.');
    }

    const ReqKeys = Object.keys(requestData);
    const ReqValues = Object.values(requestData);
    const setClauses = ReqKeys.map(key => `${key} = ?`).join(', ');
    const reqQuery = `INSERT INTO PASS_REQ_T SET ${setClauses}`;
    await connection.query(reqQuery, ReqValues);
    
    // passcard update
    updateCardState({
      connection,
      actionType: 'BORROW',
      cardIds: [requestData.card_no],
    });
    
    // Commit
    await connection.commit(); 

    res.status(200).json({ 
        message: 'Temporary inserted successfully.', 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('Temporary transaction error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// ---------------------------------------------- Update Table ---------------------------------------------- //
// Visitor
router.patch(`/request-form-v/:tno_pass`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const { tno_pass } = req.params;
    if (!tno_pass) {
      return res.status(400).json({ message: 'Missing tno_pass in URL' });
    }

    let { requestRawData, formRawData } = req.body;

    const [rows] = await connection.query(
      'SELECT people FROM PASS_FORM WHERE tno_pass = ?',
      [tno_pass]
    );

    let oldPeople = [];
    if (rows.length > 0 && rows[0].people) {
      oldPeople =
        typeof rows[0].people === 'string'
          ? JSON.parse(rows[0].people)
          : rows[0].people;
    }

    const oldCardIds = oldPeople
      .map(p => p.Card_Id)
      .filter(Boolean);

    const newCardIds = (formRawData.people || [])
      .map(p => p.Card_Id)
      .filter(Boolean);

    const isDocumentComplete = requestRawData.appr_status === 1 && requestRawData.guard_status === 1;
    const cardsToBorrow = newCardIds.filter(id => !oldCardIds.includes(id));
    const cardsToReturn = oldCardIds.filter(id => !newCardIds.includes(id));

    if (isDocumentComplete) {
      await updateCardState({
          connection,
          actionType: 'RETURN',
          cardIds: oldCardIds,
        });
    } else {
      if (cardsToBorrow.length > 0) {
        await updateCardState({
          connection,
          actionType: 'BORROW',
          cardIds: cardsToBorrow,
        });
      }

      if (cardsToReturn.length > 0) {
        await updateCardState({
          connection,
          actionType: 'RETURN',
          cardIds: cardsToReturn,
        });
      }
    }

    if (!requestRawData.sequence_no) {
      const requestType = requestRawData['request_type'];
      if (!requestType) {
        throw new ApiError(400, 'Missing request_type in request body.');
      }

      // Update sequence
      await connection.query(
        `UPDATE SEQUENCE_RUNNING_FORM 
         SET sequence = LAST_INSERT_ID(sequence + 1)
         WHERE type = ?`,
        [requestType]
      );

      // Get new sequence and pad it
      const [[{ sequence }]] = await connection.query('SELECT LAST_INSERT_ID() AS sequence');
      const seqPadded = sequence.toString().padStart(6, '0');
      requestRawData.sequence_no = seqPadded;
    }

    // Update Request
    const ReqKeys = Object.keys(requestRawData).filter(key => key !== 'tno_pass');
    const ReqValues = ReqKeys.map(key => requestRawData[key]);
    const setClauses = ReqKeys.map(key => `${key} = ?`).join(', ');
    const reqQuery = `UPDATE PASS_REQ_V SET ${setClauses} WHERE tno_pass = ?`;
    await connection.query(reqQuery, [...ReqValues, tno_pass]);

    // Update Form
    const formJsonData = {
      tno_pass: formRawData.tno_pass,
      visitorType: formRawData.visitorType,
      people: JSON.stringify(formRawData.people), 
      item_in: JSON.stringify(formRawData.item_in),
      item_out: JSON.stringify(formRawData.item_out),
    };
    const formKeys = Object.keys(formJsonData).filter(key => key !== 'tno_pass');
    const formValues = formKeys.map(key => formJsonData[key]);
    const setClausesForm = formKeys.map(key => `\`${key}\` = ?`).join(', ');
    const formQuery = `UPDATE PASS_FORM SET ${setClausesForm} WHERE tno_pass = ?`;
    await connection.query(formQuery, [...formValues, tno_pass]);
    
    // Commit
    await connection.commit(); 

    res.status(200).json({ 
        message: 'Update RequestForm successfully', 
        tno_pass: tno_pass, 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('RequestForm Transaction Error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Employee
router.patch(`/request-form-e/:tno_pass`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const { tno_pass } = req.params;
    if (!tno_pass) {
      return res.status(400).json({ message: 'Missing tno_pass in URL' });
    }

    let { requestRawData, formRawData } = req.body;
    // check sequence_no in case null or undefined
    if (!requestRawData.sequence_no) {
      const requestType = requestRawData['request_type'];
      if (!requestType) {
        throw new ApiError(400, 'Missing request_type in request body.');
      }

      // Update sequence
      await connection.query(
        `UPDATE SEQUENCE_RUNNING_FORM 
         SET sequence = LAST_INSERT_ID(sequence + 1)
         WHERE type = ?`,
        [requestType]
      );

      // Get new sequence and pad it
      const [[{ sequence }]] = await connection.query('SELECT LAST_INSERT_ID() AS sequence');
      const seqPadded = sequence.toString().padStart(6, '0');
      requestRawData.sequence_no = seqPadded;
    }

    // Update Request
    const ReqKeys = Object.keys(requestRawData).filter(key => key !== 'tno_pass');
    const ReqValues = ReqKeys.map(key => requestRawData[key]);
    const setClauses = ReqKeys.map(key => `${key} = ?`).join(', ');
    const reqQuery = `UPDATE PASS_REQ_E SET ${setClauses} WHERE tno_pass = ?`;
    await connection.query(reqQuery, [...ReqValues, requestRawData.tno_pass]);

    // Update Form
    const formJsonData = {
      tno_pass: formRawData.tno_pass,
      visitorType: formRawData.visitorType,
      people: JSON.stringify(formRawData.people), 
      item_in: JSON.stringify(formRawData.item_in),
      item_out: JSON.stringify(formRawData.item_out),
    };
    const formKeys = Object.keys(formJsonData).filter(key => key !== 'tno_pass');
    const formValues = formKeys.map(key => formJsonData[key]);
    const setClausesForm = formKeys.map(key => `\`${key}\` = ?`).join(', ');
    const formQuery = `UPDATE PASS_FORM SET ${setClausesForm} WHERE tno_pass = ?`;
    await connection.query(formQuery, [...formValues, formJsonData.tno_pass]);
    
    // Commit
    await connection.commit(); 

    res.status(200).json({ 
        message: 'Update RequestForm successfully', 
        tno_pass: requestRawData.tno_pass, 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('RequestForm Transaction Error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Permission
router.patch(`/pass-req-p/:tnoPass`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const data  = req.body;
    const { tnoPass } = req.params;
    if (!data || typeof data !== 'object') {
      throw new ApiError(400, 'Missing or invalid data in request body.');
    }
    if (!tnoPass) {
      throw new ApiError(400, 'Missing tnoPass parameter.');
    }

    const keys = Object.keys(data);
    const values = Object.values(data);

    if (keys.length === 0) {
      throw new ApiError(400, 'No fields to update.');
    }

    const [oldRows] = await connection.query('SELECT brw_card FROM PASS_REQ_P WHERE tno_pass = ?', [data.tno_pass]);
    const oldCard = oldRows[0]?.brw_card;
    const newCard = data.brw_card;

    const setClause = keys.map(key => `${key} = ?`).join(', ');
    const sqlUpdate  = `UPDATE PASS_REQ_P SET ${setClause} WHERE tno_pass = ?`;
    const [result] = await connection.query(sqlUpdate, [...values, tnoPass]);

    if (result.affectedRows === 0) {
      throw new ApiError(404, `Permission record with tno_pass ${tnoPass} not found.`);
    }

    // passcard update
    const shouldReturnCard =
      data.sign_emp_status === 1 &&
      data.sign_respon_status === 1 &&
      data.sign_guardI_status === 1 &&
      data.sign_guardO_status === 1 &&
      data.brw_card;


    if(shouldReturnCard) {
      updateCardState({
        connection,
        actionType: 'RETURN',
        cardIds: [data.brw_card],
      });
    } else {
      if (newCard !== oldCard) {
        if (oldCard) {
            await updateCardState({
                connection,
                actionType: 'RETURN',
                cardIds: [oldCard],
            });
        }
        if (newCard) {
            await updateCardState({
                connection,
                actionType: 'BORROW',
                cardIds: [newCard],
            });
        }
      }
    }

    await connection.commit();

    res.status(200).json({ 
        message: 'Permission updated successfully.', 
        tno_pass: tnoPass, 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('Permission transaction error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Employee
router.patch(`/employee/:pk`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const data  = req.body;
    const { pk } = req.params;
    if (!data || typeof data !== 'object') {
      throw new ApiError(400, 'Missing or invalid data in request body.');
    }
    if (!pk) {
      throw new ApiError(400, 'Missing tnoPass parameter.');
    }

    const keys = Object.keys(data);
    const values = Object.values(data);

    if (keys.length === 0) {
      throw new ApiError(400, 'No fields to update.');
    }

    const setClause = keys.map(key => `${key} = ?`).join(', ');
    const sqlUpdate  = `UPDATE PASS_REQ_E SET ${setClause} WHERE tno_pass = ?`;
    const [result] = await connection.query(sqlUpdate, [...values, pk]);
    if (result.affectedRows === 0) {
      throw new ApiError(404, `Employee record with tno_pass ${pk} not found.`);
    }

    await connection.commit();

    res.status(200).json({ 
        message: 'Employee updated successfully.', 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('Employee transaction error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Temporary
router.patch(`/temporary/:id`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const data  = req.body;
    const { id } = req.params;
    if (!data || typeof data !== 'object') {
      throw new ApiError(400, 'Missing or invalid data in request body.');
    }
    if (!id) {
      throw new ApiError(400, 'Missing tnoPass parameter.');
    }

    const keys = Object.keys(data);
    const values = Object.values(data);

    if (keys.length === 0) {
      throw new ApiError(400, 'No fields to update.');
    }

    const setClause = keys.map(key => `${key} = ?`).join(', ');
    const sqlUpdate  = `UPDATE PASS_REQ_T SET ${setClause} WHERE id = ?`;
    const [result] = await connection.query(sqlUpdate, [...values, id]);
    if (result.affectedRows === 0) {
      throw new ApiError(404, `Permission record with tno_pass ${id} not found.`);
    }

    await connection.commit();

    res.status(200).json({ 
        message: 'Permission updated successfully.', 
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('Permission transaction error:', err.message);
    next(err);
  } finally {
    if (connection) {
      connection.release();
    }
  }
});

// Update signature field
router.patch(`/signature/:docType/:pk`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const dataToUpdate  = req.body;
    const { docType, pk } = req.params;

    if (!dataToUpdate || typeof dataToUpdate !== 'object') {
      throw new ApiError(400, 'Missing or invalid data in request body.');
    }

    if (!pk || !docType) {
      throw new ApiError(400, 'Missing id parameter.');
    }

    const keys = Object.keys(dataToUpdate);
    const values = Object.values(dataToUpdate);


    if (keys.length === 0) {
      throw new ApiError(400, 'No fields to update.');
    }

    // dynamic update ล้วน ๆ
    const setClause = keys.map(key => `${key} = ?`).join(', ');

    const config = {
      VISITOR:   { table: 'PASS_REQ_V', key: 'tno_pass' },
      EMPLOYEE:  { table: 'PASS_REQ_E', key: 'tno_pass' },
      PERMISSION:{ table: 'PASS_REQ_P', key: 'tno_pass' },
      TEMPORARY: { table: 'PASS_REQ_T', key: 'id' },
    };

    const cfg = config[docType];
    if (!cfg) throw new ApiError(400, `Invalid docType: ${docType}`);

    const sqlUpdate = `UPDATE ${cfg.table} SET ${setClause} WHERE ${cfg.key} = ?`;

    const [result] = await connection.query(sqlUpdate, [...values, pk]);

    if (result.affectedRows === 0) {
      throw new ApiError(404, `${docType} record ${pk} not found.`);
    }

    let sqlStatusUpdate = "";

    switch (docType) {
      case "VISITOR":
        sqlStatusUpdate = `
          UPDATE PASS_REQ_V
          SET 
            datetime_out = CASE
              WHEN guard_status = 1 
                AND appr_status = 1
              THEN guard_at
              ELSE datetime_out
            END,
            doc_status = CASE
              WHEN guard_status = 1 
                AND appr_status = 1 
              THEN 'Completed'
              ELSE doc_status
            END
          WHERE tno_pass = ?
        `;
        break;

      case "EMPLOYEE":
        sqlStatusUpdate = `
          UPDATE PASS_REQ_E
          SET 
            datetime_in = CASE
              WHEN guard_status = 1 
                AND emp_status = 1 
                AND appr_status = 1
              THEN guard_at
              ELSE datetime_in
            END,
            doc_status = CASE
              WHEN guard_status = 1 
                AND emp_status = 1 
                AND appr_status = 1
              THEN 'Completed'
              ELSE doc_status
            END
          WHERE tno_pass = ?
        `;
        break;

      case "PERMISSION":
        sqlStatusUpdate = `
          UPDATE PASS_REQ_P
          SET 
            doc_status = CASE
              WHEN sign_guardO_status = 1 
                AND sign_emp_status = 1 
                AND sign_respon_status = 1
                AND sign_guardI_status = 1
              THEN 'Completed'
              ELSE doc_status
            END
          WHERE tno_pass = ?
        `;
        break;

      case "TEMPORARY":
        sqlStatusUpdate = `
          UPDATE PASS_REQ_T SET
            brw_status = CASE
              WHEN brw_sign_brw IS NOT NULL AND brw_sign_brw != '' 
              AND brw_sign_guard IS NOT NULL AND brw_sign_guard != '' THEN 1
              ELSE brw_status
            END,
            ret_status = CASE
              WHEN ret_sign_brw IS NOT NULL AND ret_sign_brw != '' 
              AND ret_sign_guard IS NOT NULL AND ret_sign_guard != '' THEN 1
              ELSE ret_status
            END,
            doc_status = CASE
              WHEN brw_status = 1
              AND ret_status = 1
              THEN 'Completed'
              ELSE doc_status
            END
          WHERE id = ?
        `;
        break;

      default:
        throw new Error("Invalid docType");
    }

    //This 
    await connection.query(sqlStatusUpdate, [pk]);
    
    // ✅ Reset Card State
    let docStatus = '';
    let cardIds = [];

    // ===============================
    // VISITOR
    // ===============================
    if (docType === "VISITOR") {

      const [[req]] = await connection.query(
        `
        SELECT doc_status
        FROM PASS_REQ_V
        WHERE tno_pass = ?
        FOR UPDATE
        `,
        [pk]
      );

      const [[form]] = await connection.query(
        `
        SELECT people
        FROM PASS_FORM
        WHERE tno_pass = ?
        FOR UPDATE
        `,
        [pk]
      );

      docStatus = (req?.doc_status || '').toLowerCase();

      // const people = JSON.parse(form?.people || '[]');
      
      let people = [];
      if (form?.people) {
          if (typeof form.people === 'string') {
              people = JSON.parse(form.people);
          } else {
              people = form.people;
          }
      }

      cardIds = people
        .map(p => p.Card_Id)
        .filter(Boolean);

      // RESET (อยู่ใน block)
      if (docStatus === 'completed' && cardIds.length > 0) {
        await updateCardState({
          connection,
          actionType: 'RETURN',
          cardIds,
        });
      }
    }

    // ===============================
    // PERMISSION
    // ===============================
    else if (docType === "PERMISSION") {

      const [[row]] = await connection.query(
        `
        SELECT doc_status, brw_card
        FROM PASS_REQ_P
        WHERE tno_pass = ?
        FOR UPDATE
        `,
        [pk]
      );

      docStatus = (row?.doc_status || '').toLowerCase();

      if (row?.brw_card) {
        cardIds = [row.brw_card];
      }

      // RESET
      if (docStatus === 'completed' && cardIds.length > 0) {
        await updateCardState({
          connection,
          actionType: 'RETURN',
          cardIds,
        });
      }
    }

    // ===============================
    // TEMPORARY
    // ===============================
    else if (docType === "TEMPORARY") {

      const [[row]] = await connection.query(
        `
        SELECT doc_status, card_no
        FROM PASS_REQ_T
        WHERE id = ?
        FOR UPDATE
        `,
        [pk]
      );

      docStatus = (row?.doc_status || '').toLowerCase();

      if (row?.card_no) {
        cardIds = [row.card_no];
      }

      // RESET
      if (docStatus === 'completed' && cardIds.length > 0) {
        await updateCardState({
          connection,
          actionType: 'RETURN',
          cardIds,
        });
      }
    }



    await connection.commit();

    res.status(200).json({
      message: 'Signature updated successfully.',
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('Transaction error:', err.message);
    next(err);
  } finally {
    if (connection) connection.release();
  }
});


module.exports = router;