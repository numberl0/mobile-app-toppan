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
    WHERE pr.request_type = 'VISITOR' AND DATE(pr.date_in) IN (?, ?)
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
    WHERE pr.request_type = 'EMPLOYEE' AND DATE(pr.date_out) IN (?, ?)
    `;

    const queryPassReqP = `
    SELECT * FROM PASS_REQ_P
    WHERE sign_emp_status != 1 OR sign_respon_status != 1 OR  sign_guardI_status != 1 OR  sign_guardO_status != 1
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
      return {
        'tno_pass': null,
        'request_type': 'VISITOR',
        'sequence_no': null,
        'company': entry['company']? entry['company']:null,
        'vehicle_no': null,
        'date_in': entry['date_visitor1'],
        'time_in': entry['timerang'] ? entry['timerang'].split(' ถึง ')[0] : null,
        'date_out': entry['date_visitor2'],
        'time_out': entry['timerang'] ? entry['timerang'].split(' ถึง ')[1] : null, 
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
      return {
        'tno_pass': null,
        'request_type': 'VISITOR',
        'sequence_no': null,
        'company': entry['company']? entry['company']:null,
        'vehicle_no': null,
        'date_in': entry['date_visitor'],
        'time_in': entry['timerang'] ? entry['timerang'].split(' ถึง ')[0] : null,
        'date_out': entry['date_visitor'],
        'time_out': entry['timerang'] ? entry['timerang'].split(' ถึง ')[1] : null, 
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
    let listDataE = [...transformInUrlE];
    let listDataP = [...transformInUrlP];

    // format date
    const TIMEZONE = 'Asia/Bangkok';
    const formatDateTime = (datetime) => datetime ? dayjs.utc(datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss') : null;
    listDataV = listDataV.map(entry => ({
      ...entry,
      date_in: formatDateTime(entry.date_in),
      date_out: formatDateTime(entry.date_out),
      approved_datetime: formatDateTime(entry.approved_datetime),
      media_datetime: formatDateTime(entry.media_datetime),
      mainEn_datetime: formatDateTime(entry.mainEn_datetime),
      proArea_datetime: formatDateTime(entry.proArea_datetime),
    }));

    listDataE = listDataE.map(entry => ({
      ...entry,
      date_in: formatDateTime(entry.date_in),
      date_out: formatDateTime(entry.date_out),
      empSign_datetime: formatDateTime(entry.empSign_datetime),
      approved_datetime: formatDateTime(entry.approved_datetime),
      media_datetime: formatDateTime(entry.media_datetime),
      mainEn_datetime: formatDateTime(entry.mainEn_datetime),
    }));

    // sort
    function getDateTime(date, time) {
      if (!time) time = '00:00';

      if (date instanceof Date) {
        return new Date(`${date.toISOString().split('T')[0]}T${time}`);
      }

      if (typeof date === 'string' && date.includes('-')) {
        const parts = date.split('-');
        if (parts[0].length === 2) {
          const [day, month, year] = parts;
          date = `${year}-${month}-${day}`;
        }
      }

      return new Date(`${date}T${time}`);
    }

    listDataV.sort((a, b) => {
      const dateTimeA = getDateTime(a.date_in, a.time_in);
      const dateTimeB = getDateTime(b.date_in, b.time_in);
      return dateTimeA - dateTimeB;
    });

    listDataE.sort((a, b) => {
      const dateTimeA = getDateTime(a.date_out, a.time_out);
      const dateTimeB = getDateTime(b.date_out, b.time_out);
      return dateTimeA - dateTimeB;
    });

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
  const filePath = path.join(__dirname, 'manual', filename);

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
router.put(`/request-form-v/:tno_pass`, authenticateToken, async (req, res, next) => {
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

    console.log('OLD:', oldCardIds);
    console.log('NEW:', newCardIds);
    console.log('BORROW:', cardsToBorrow);
    console.log('RETURN:', cardsToReturn);

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
router.put(`/request-form-e/:tno_pass`, authenticateToken, async (req, res, next) => {
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
router.put(`/pass-req-p/:tnoPass`, authenticateToken, async (req, res, next) => {
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

// Temporary
router.patch(`/temporary/:id`, authenticateToken, async (req, res, next) => {
  let connection;
  try {
    connection = await db.getConnection(); 
    await connection.beginTransaction(); 

    const dataToUpdate  = req.body;
    const { id } = req.params;
    if (!dataToUpdate || typeof dataToUpdate !== 'object') {
      throw new ApiError(400, 'Missing or invalid data in request body.');
    }

    if (!id) {
      throw new ApiError(400, 'Missing id parameter.');
    }

    const keys = Object.keys(dataToUpdate);
    const values = Object.values(dataToUpdate);


    if (keys.length === 0) {
      throw new ApiError(400, 'No fields to update.');
    }

    const setClause = keys.map(key => `${key} = ?`).join(', ');
    const sqlUpdate  = `UPDATE PASS_REQ_T SET ${setClause} WHERE id = ?`;
    const [result] = await connection.query(sqlUpdate, [...values, id]);
    if (result.affectedRows === 0) {
      throw new ApiError(404, `Temporary record with id ${id} not found.`);
    }

    // update brw_status and ret_status
    const sqlStatusUpdate = `
      UPDATE PASS_REQ_T SET
        brw_status = CASE
          WHEN brw_sign_brw IS NOT NULL AND brw_sign_brw != '' AND brw_sign_guard IS NOT NULL AND brw_sign_guard != '' THEN 1
          ELSE brw_status
        END,
        ret_status = CASE
          WHEN ret_sign_brw IS NOT NULL AND ret_sign_brw != '' AND ret_sign_guard IS NOT NULL AND ret_sign_guard != '' THEN 1
          ELSE ret_status
        END
      WHERE id = ?
    `;
    await connection.query(sqlStatusUpdate, [id]);

    // update passcard
    const [[rows]] = await connection.query(
      `
      SELECT brw_status, ret_status, card_no
      FROM PASS_REQ_T
      WHERE id = ?
      FOR UPDATE
      `,
      [id]
    );
    if (rows?.brw_status === 1 && rows?.ret_status === 1 && rows?.card_no) {
      await updateCardState({
        connection,
        actionType: 'RETURN',
        cardIds: [rows.card_no],
      });
    }

    await connection.commit();

    res.status(200).json({
      message: 'Temporary signature updated successfully.',
    });
  } catch (err) {
    if (connection) {
      await connection.rollback(); 
    }
    console.error('Temporary transaction error:', err.message);
    next(err);
  } finally {
    if (connection) connection.release();
  }
});


module.exports = router;