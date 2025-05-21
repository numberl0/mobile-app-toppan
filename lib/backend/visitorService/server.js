//visitorApp server.js
const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');

const cron = require("node-cron");    //  Runs scheduled tasks
const admin = require("../firebase/firebase");  // firebase service account

// day
const dayjs = require('dayjs');
const utc = require('dayjs/plugin/utc');
const timezone = require('dayjs/plugin/timezone');
// Extend dayjs with plugins
dayjs.extend(utc);
dayjs.extend(timezone);

//untils
const ApiError = require('../utils/apiError');

//path file
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const http = require("http");

//middleware
const authenticateToken = require('../middlewares/authenticateToken');
const errorHandler = require('../middlewares/errorHandler');

const { gateWayConfig, visitorDB, visitorConfig } = require('../config');
// Domain
const domain = gateWayConfig.domain;
// Pipeline
const pipe = visitorConfig.pipe;
// Connection database MYSQL-Front
const db = mysql.createConnection(visitorDB);

const app = express();

app.disable('x-powered-by');

const corsOptions = {
  origin: [domain],
  methods: ['GET', 'POST', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};
app.use(cors(corsOptions));

app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(errorHandler);

// Test MySQL connection
db.connect(err => {
  if (err) {
    console.error('Error connecting to MySQL:', err.stack);
  } else {
    console.log('Connected to MySQL database');
  }
});

// ---------------------------------------------- Database Queries ---------------------------------------------- //
function dbQuery(query, params) {
  return new Promise((resolve, reject) => {
    db.query(query, params, (err, results) => {
      if (err) {
        reject(err);
      } else {
        resolve(results);
      }
    });
  });
}

// ---------------------------------------------- Get ---------------------------------------------- //
//Get sequence running number
app.get(`/getAgreement`, authenticateToken, async (req, res, next) => {
  try {
    const results = await dbQuery('SELECT * FROM AGREEMENT WHERE inUse=1', []);
    if (results.length === 0) {
      return next(new ApiError(404, 'Agreement Not Found'))
    }
    res.status(200).json({ message: 'Agreement Found', data: results });
  } catch (err) {
    next(err);
  }
});

//Get role user
app.get(`/getRoleByUser`, authenticateToken, async (req, res, next) => {
  try {
    const { username } = req.query;
    if (!username) {
      return next(new ApiError(400, "You don't have user in VisitorApp"))
    }
    const results = await dbQuery('SELECT role FROM USER WHERE username = ?', [username]);

    if (results.length === 0) {
      return next(new ApiError(404, 'User Not Found With This username'));
    }

    const roles = results.map(row => row.role);
    res.status(200).json({ message: 'Users Found', data: roles });

  } catch (err) {
    next(err);
  }
});

//Get role building
app.get(`/getBuilding`, authenticateToken, async (req, res, next) => {
  try {
    const results = await dbQuery('SELECT * FROM BUILDING', []);
    if (results.length === 0) {
      return next(new ApiError(404, 'No Buildings Found'));
    }
    res.status(200).json({ message: 'Building Found', data: results });
  } catch (err) {
    next(err);
  }
});

// Get role manage
app.get(`/getManagerRole`, authenticateToken, async (req, res, next) => {
  try {
    const results = await dbQuery('SELECT * FROM USER WHERE enable=? AND role NOT IN (?, ?)', [1, 'administrator', 'guest']);
    if (results.length === 0) {
      return next(new ApiError(401, 'No Roles Found'));
    }
    const userMap = {};
    results.forEach(user => {
      const { id, username, email, sign_name, title_name, first_name, last_name, enable, session_token, role } = user;

      // Check if the user is already in the map
      if (userMap[username]) {
        // Merge roles
        userMap[username].role.push(role);

        // If session_token is null, update it
        if (userMap[username].session_token === null && session_token !== null) {
          userMap[username].session_token = session_token;
        }
      } else {
        // Add the user to the map
        userMap[username] = {
          id,
          username,
          email,
          sign_name,
          title_name,
          first_name,
          last_name,
          enable,
          session_token: session_token || null,
          role: [role],
        };
      }
    });

    const mergedResults = Object.keys(userMap).map(username => {
      const user = userMap[username];
      user.role = user.role.join(', ');
      return user;
    });
    res.status(200).json({ message: 'Roles Found', data: mergedResults });
  } catch (err) {
    next(err);
  }
});

//Get sequence running number
app.get(`/getSequenceRunning`, authenticateToken, async (req, res, next) => {
  try {
    const { type } = req.query
    const results = await dbQuery('SELECT * FROM SEQUENCE_RUNNING_FORM WHERE type=?', [type]);
    if (results.length === 0) {
      return next(new ApiError(401, 'No Found Sequence'));
    }
    res.status(200).json({ message: 'Sequence Found', data: results });
  } catch (err) {
    next(err);
  }
});

app.get(`/getSignaturFilenameByUsername`, authenticateToken, async (req, res, next) => {
  try {
    const { username } = req.query;
    if(!username) {
      return next(new ApiError(400, 'username missing'));
    }
    const query = `SELECT DISTINCT sign_name FROM USER WHERE username = ?`;
    const results = await dbQuery(query, [username])
    res.status(200).json({
      message: "Query Successful",
      data: results,
    });
  } catch (err) {
    next(err);
  }
});

// Search by date : yyyy-MM-dd
app.get(`/getRequestFormByDate`, authenticateToken, async (req, res, next) => {
  try {
    const {dateToDay} = req.query;
    if (!dateToDay) {
      return next(new ApiError(400, 'Date parameter (yyyy-MM-dd) is missing'));
    }

    // Calculate the previous date
    const prevDate = new Date(dateToDay);
    prevDate.setDate(prevDate.getDate() - 1);
    const datePrevDay = prevDate.toISOString().split('T')[0];

    const queryPassRequest = `
    SELECT
        pr.*,
        pf.visitorType,
        pf.people,
        pf.item_in,
        pf.item_out
    FROM PASS_REQUEST pr
    LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
    WHERE (
        pr.request_type = 'VISITOR' AND DATE(pr.date_in) IN (?, ?)
    ) OR (
        pr.request_type = 'EMPLOYEE' AND DATE(pr.date_out) IN (?, ?)
    );
    `;
    const queryVisitorNormal = `
    SELECT 
      vn.*,
      vf.visitorType,
      vf.people
      FROM VISITOR_NORMAL vn
      LEFT JOIN VISITOR_FORM vf ON vn.tno = vf.tno
      LEFT JOIN PASS_REQUEST pr ON vn.tno = pr.tno_ref
      WHERE DATE(vn.date_visitor1) IN (?, ?)
      AND NOT EXISTS (SELECT 1 FROM PASS_REQUEST pr WHERE pr.tno_ref = vn.tno);
    `;

    const queryVisitorExpress = `
    SELECT 
      ve.*,
      vf.visitorType,
      vf.people
      FROM VISITOR_EXPRESS ve
      LEFT JOIN VISITOR_FORM vf ON ve.tno = vf.tno
      LEFT JOIN PASS_REQUEST pr ON ve.tno = pr.tno_ref
      WHERE DATE(ve.date_visitor) IN (?, ?)
      AND NOT EXISTS (SELECT 1 FROM PASS_REQUEST pr WHERE pr.tno_ref = ve.tno);
    `;

    // Execute queries
    const [passResults, normalResults, expressResults] = await Promise.all([
      dbQuery(queryPassRequest, [dateToDay, datePrevDay, dateToDay, datePrevDay]),
      dbQuery(queryVisitorNormal, [dateToDay, datePrevDay]),
      dbQuery(queryVisitorExpress, [dateToDay, datePrevDay])
    ]);

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
        'contact': null,
        'dept': null,
        'objective_type': 0,   // visitorType = 0
        'objective': entry['purpose']? entry['purpose']:null,
        'building_card': entry['building_card']? entry['building_card']:null,
        'area': entry['area']? entry['area']:null,
        'empSign_status': 0,
        'empSign_sign': null,
        'empSign_datetime': null,
        'empSign_by': null,
        'approved_status': 0,
        'approved_sign': null,
        'approved_datetime': null,
        'approved_by': null,
        'media_status': 0,
        'media_sign': null,
        'media_datetime': null,
        'media_by': null,
        'mainEn_status': 0,
        'mainEn_sign': null,
        'mainEn_datetime': null,
        'mainEn_by': null,
        'proArea_status': 0,
        'proArea_sign': null,
        'proArea_datetime': null,
        'proArea_by': null,
        'tno_ref': entry['tno']? entry['tno']:null,
        'visitorType': entry['visitorType']? entry['visitorType']:null,
        'people': entry['people']? entry['people']:null,
        'item_in': null,
        'item_out': null,
      };
    });


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
        'dept': entry['to_visit_dept']? entry['to_visit_dept']:null,
        'objective_type': 0,   // visitorType = 0
        'objective': entry['purpose']? entry['purpose']:null,
        'building_card': entry['building_card']? entry['building_card']:null,
        'area': entry['area']? entry['area']:null,
        'empSign_status': 0,
        'empSign_sign': null,
        'empSign_datetime': null,
        'empSign_by': null,
        'approved_status': 0,
        'approved_sign': null,
        'approved_datetime': null,
        'approved_by': null,
        'media_status': 0,
        'media_sign': null,
        'media_datetime': null,
        'media_by': null,
        'mainEn_status': 0,
        'mainEn_sign': null,
        'mainEn_datetime': null,
        'mainEn_by': null,
        'proArea_status': 0,
        'proArea_sign': null,
        'proArea_datetime': null,
        'proArea_by': null,
        'tno_ref': entry['tno']? entry['tno']:null,
        'visitorType': entry['visitorType']? entry['visitorType']:null,
        'people': entry['people']? entry['people']:null,
        'item_in': null,
        'item_out': null,
      };
    });

    // Transform image filenames into URLs
    const transformInUrl = transformFilenameToUrl(passResults);
    let mergedData = [...transformInUrl, ...formattedVNResults, ...formattedVEResults];

    // sort data by date / time
    mergedData.sort((a, b) => {
      const getDateTime = (item) => {
        const isEmployee = item.request_type === 'EMPLOYEE';
        let date = isEmployee ? item.date_out : item.date_in;
        let time = isEmployee ? item.time_out : item.time_in;
    
        // Default time if missing
        if (!time) time = '00:00';
    
        // If date is not a string or is already a Date object
        if (date instanceof Date) {
          return new Date(`${date.toISOString().split('T')[0]}T${time}`);
        }
    
        // If date is in format DD-MM-YYYY, convert it
        if (typeof date === 'string' && date.includes('-')) {
          const parts = date.split('-');
          if (parts[0].length === 2) {
            // Assuming format is DD-MM-YYYY
            const [day, month, year] = parts;
            date = `${year}-${month}-${day}`;
          }
        }
    
        // Final ISO string
        const isoDateTime = `${date}T${time}`;
        return new Date(isoDateTime);
      };
    
      const dateTimeA = getDateTime(a);
      const dateTimeB = getDateTime(b);
    
      return dateTimeA - dateTimeB;
    });
    

    const TIMEZONE = 'Asia/Bangkok';
    mergedData = mergedData.map(entry => ({
      ...entry,
      date_in: entry.date_in
        ? dayjs.utc(entry.date_in).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null,
      date_out: entry.date_out
        ? dayjs.utc(entry.date_out).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null,
      empSign_datetime: entry.empSign_datetime
        ? dayjs.utc(entry.empSign_datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null,
      approved_datetime: entry.approved_datetime
        ? dayjs.utc(entry.approved_datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null,
      media_datetime: entry.media_datetime
        ? dayjs.utc(entry.media_datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null,
      mainEn_datetime: entry.mainEn_datetime
        ? dayjs.utc(entry.mainEn_datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null,
      proArea_datetime: entry.proArea_datetime
        ? dayjs.utc(entry.proArea_datetime).tz(TIMEZONE).format('YYYY-MM-DD HH:mm:ss')
        : null
    }));

    res.status(200).json({
      message: "Data found",
      data: mergedData,
    });
  } catch (err) {
    next(err);
  }

});

// Get Request Document By Role Approver
app.get(`/getRequestApproved`, authenticateToken, async (req, res, next) => {
  try {
    let { building_card } = req.query;
    if (!building_card) {
      return next(new ApiError(400, 'Missing building_card parameter'));
    }
    if (!Array.isArray(building_card)) {
      building_card = [building_card]; // Convert single value to array
    }

    if (building_card.length === 0) {
      return next(new ApiError(400, 'Invalid or empty building_card list'));
    }

    const query = `
      SELECT 
        pr.*,
        pf.people,
        pf.item_in,
        pf.item_out
      FROM PASS_REQUEST pr 
      LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
      WHERE pr.approved_status = 0 AND pr.building_card IN (?)
      ORDER BY 
        CASE 
          WHEN pr.request_type = 'EMPLOYEE' THEN CONCAT(pr.date_out, ' ', pr.time_out)
          ELSE CONCAT(pr.date_in, ' ', pr.time_in)
        END ASC
    `;

    const results = await dbQuery(query, [building_card]);
    const transformResults = transformFilenameToUrl(results);

    

    res.status(200).json({
      message: "Query successful",
      data: transformResults,
    });
  } catch (err) {
    next(err);
  }
});

//
app.get(`/checkRecordFCM`, authenticateToken, async (req, res, next) => {
  try {
    const { device_id } = req.query;
    const results = await dbQuery('SELECT * FROM FCM_TOKEN WHERE device_id=?', [device_id]);
    if (results.length === 0) {
      res.status(200).json({ message: 'Device ID Not Found', data: false});
    }else{
      res.status(200).json({ message: 'Device ID Found', data: true});
    }
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------- Checker ---------------------------------------------- //
app.get(`/passRequestDoesNotExist`, authenticateToken, async (req, res, next) => {
  try {
    const { tno_pass } = req.query;

    if (!tno_pass) {
      return next(new ApiError(400, 'Missing tno_pass'));
    }

    const query = 'SELECT COUNT(*) AS count FROM PASS_REQUEST WHERE tno_pass = ?';
    const results = await dbQuery(query, [tno_pass]);

    const doesNotExist = results[0].count === 0;
    res.status(200).json({ doesNotExist });

  } catch (err) {
    next(err);
  }
});


// ---------------------------------------------- Insert Table ---------------------------------------------- //
// Insert Pass Form 
app.post(`/uploadPassForm`, authenticateToken, async (req, res, next) => {
  try {
    const data = req.body;
    const structuredData = {
      tno_pass: data.tno_pass,
      visitorType: data.visitorType,
      people: JSON.stringify(data.people), 
      item_in: JSON.stringify(data.item_in),
      item_out: JSON.stringify(data.item_out),
    };
    const query = 'INSERT INTO PASS_FORM SET ?';
    await dbQuery(query, [structuredData]);

    res.status(200).json({ message: 'Insert data successfully', tno_pass: data.tno_pass});
  } catch (err) {
    next(err);
  }
});

// Insert Pass Request
app.post(`/uploadPassRequest`, authenticateToken, async (req, res, next) => {
  try {
    const data = req.body;
    const query = 'INSERT INTO PASS_REQUEST SET ?';
    await dbQuery(query, data);
    res.status(200).json({ message: 'Insert data successfully', tno_pass: data.tno_pass });
  } catch (err) {
    next(err);
  }
});

// Insert Activity Log
app.post(`/insertActivityLog`, authenticateToken, async (req, res, next) => {
  try {
    const data = req.body;

    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return next(new ApiError(400, 'Invalid Data'));
    }

    const query = `INSERT INTO LOG_MOBILE_APP SET ?`;

    const result = await dbQuery(query, data);

    if (!result || result.affectedRows === 0) {
      return next(new ApiError(400, 'Insert failed'));
    }

    res.status(200).json({ message: 'Insert activity successful' });
  } catch (err) {
    next(err);
  }
});

// Insert FCM Token
app.post(`/insertFCMToken`, authenticateToken, async (req, res, next) => {
  try {
    const data = req.body;

    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return next(new ApiError(400, 'Invalid Data'));
    }

    const query = `INSERT INTO FCM_TOKEN SET ?`;

    const result = await dbQuery(query, data);

    if (!result || result.affectedRows === 0) {
      return next(new ApiError(400, 'Insert Failed'));
    }

    res.status(200).json({ message: 'Insert FCM Token successful' });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------- Update Table ---------------------------------------------- //
//Get sequence running number
app.post(`/updateSequenceRunning`, authenticateToken, async (req, res, next) => {
  try {
    const { type, sequence } = req.body;
    const query = `UPDATE SEQUENCE_RUNNING_FORM SET sequence = ? WHERE type = ?`;
    const result = await dbQuery(query, [sequence, type]);
    if (result.affectedRows === 0) {
      return next(new ApiError(400, 'Type not found, no update made'));
    }
    res.status(200).json({message: 'Sequence successfully updated'});
  } catch (err) {
    next(err);
  }
});

// Update Pass Form 
app.post(`/updatePassForm`, authenticateToken, async (req, res, next) => {
  try {
    const { data } = req.body;
    const structuredData = {
      tno_pass: data.tno_pass,
      visitorType: data.visitorType,
      people: JSON.stringify(data.people),
      item_in: JSON.stringify(data.item_in),
      item_out: JSON.stringify(data.item_out),
    };
    const query = `UPDATE PASS_FORM SET ? WHERE tno_pass = ?`;
    const [results] = await Promise.all([dbQuery(query, [structuredData, data.tno_pass]),]);

    if (results.affectedRows === 0) {
      return next(new ApiError(404, 'No record updated, tno_pass not found'));
    }

    res.status(200).json({ message: 'Update successful', updatedId: data.tno_pass });

  } catch (err) {
    next(err);
  }
});

// Update Pass Request
app.post(`/updatePassRequest`, authenticateToken, async (req, res, next) => {
  try {
    const {data} = req.body;
    const query = `UPDATE PASS_REQUEST SET ? WHERE tno_pass = ?`;
    const [results] = await Promise.all([dbQuery(query, [data, data.tno_pass]),]);
    if (results.affectedRows === 0) {
      return next(new ApiError(404, 'No record updated, tno_pass not found'));
    }

    res.status(200).json({ message: 'Update successful', updatedId: data.tno_pass });

  } catch (err) {
    next(err);
  }
});

//update approved document
app.post(`/approvedDocument`, authenticateToken, async (req, res, next) => {
  try {
    const { tno, type, data } = req.body
    if(!tno || !type || !data) {
      return next(new ApiError(400, 'Invalid or missing data'));
    }

    const filename = await copySignatureFile(type, tno, data.approved_sign);
    if(!filename){
      return next(new ApiError(404, 'Failed to move signature file.'));
    }
    data.approved_sign = filename; 

    const fields = Object.keys(data).map(key => `${key} = ?`).join(", ");
    const values = Object.values(data);
    values.push(tno);

    const query = `UPDATE PASS_REQUEST SET ${fields} WHERE tno_pass = ?`;
    await dbQuery(query, values);

    res.status(200).json({ message: "Update Approved Successful",});
  } catch (err) {
    next(err);
  }
});

//update approved document all
app.post(`/approvedAll`, authenticateToken, async (req, res, next) => {
  try {
    const { tno_listMap, sign_info } = req.body

    // Check req
    if (!tno_listMap || !sign_info) {
      return next(new ApiError(400, 'Invalid or missing data.'));
    }

    // Duplicate image to traget folder and change name
    let filename = '';
    for (const item of tno_listMap) {
      filename = await copySignatureFile(item.type, item.tno_pass, sign_info.approved_sign);
      if(!filename){
        return next(new ApiError(500, 'Failed to move signature file.'));
      }
    }
    sign_info.approved_sign = filename;

    // Map query sign_info
    const fields = Object.keys(sign_info).map(key => `${key} = ?`).join(", ");
    const values = Object.values(sign_info);

    // Get tno_pass in list
    const tno_list = tno_listMap.map(item => item.tno_pass);
    if (tno_list.length === 0) {
      return next(new ApiError(400, 'Missing tno_pass values.'));
    }

    // Query text by tno_pass list
    const tno_list_query = tno_list.map(() => '?').join(", ");
    values.push(...tno_list);

    const query = `UPDATE PASS_REQUEST SET ${fields} WHERE approved_status = 0 AND tno_pass IN (${tno_list_query})`;
    await dbQuery(query, values);

    res.status(200).json({ message: "Update Approved Successful",});
  } catch (err) {
    next(err);
  }
});

// Update last active FCM Token
app.post(`/updateActiveFCMToken`, authenticateToken, async (req, res, next) => {
  try {
    const {device_id, last_active} = req.body;

    // Basic validation
    if (!device_id || !last_active) {
      return next(new ApiError(400, 'Missing device_id or last_active'));
    }

    const query = `UPDATE FCM_TOKEN SET last_active = ? WHERE device_id = ?`;
    const result = await dbQuery(query, [last_active, device_id]);

    if (!result || result.affectedRows === 0) {
      return next(new ApiError(400, 'Update Failed'));
    }

    res.status(200).json({ message: 'FCM Token last_active updated successfully' });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------- Delete ---------------------------------------------- //
app.delete(`/deleteFCMToken`, authenticateToken, async (req, res, next) => {
  try {
    const { device_id} = req.body;

    if (!device_id) {
      return next(new ApiError(400, 'Missing required fields.'));
    }

    const query = `DELETE FROM FCM_TOKEN WHERE device_id = ?`;
    const result = await dbQuery(query, [device_id]);

    if (result.affectedRows === 0) {
      console.error("[ERROR] FCM Token not found in database.");
      return next(new ApiError(404, 'FCM Token not found.'));
    }

    res.status(200).json({ message: "FCM Token deleted successfully" });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------- Additional Functions ---------------------------------------------- //

// Set up storage configuration for multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const { tno, date, typeForm} = req.body;
    const basePath = visitorConfig.pathImageDocuments;

    // Extract year and month from date
    const parsedDate = new Date(date);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const tnoFolder = path.join(basePath, typeForm, `${year}`, `${month}`, tno);

    // Create base folder structure
    const foldersToCreate = [
      tnoFolder,
      path.join(tnoFolder, 'people'),
      path.join(tnoFolder, 'item_in'),
      path.join(tnoFolder, 'item_out'),
      path.join(tnoFolder, 'signatures')
    ];

    foldersToCreate.forEach(folder => {
      if (!fs.existsSync(folder)) {
        fs.mkdirSync(folder, { recursive: true });
      }
    });

    // Map fieldname to folder
    const folderMap = {
      'people[]': 'people',
      'item_in[]': 'item_in',
      'item_out[]': 'item_out',
      'sign[]': 'signatures'
    };

    const fieldFolder = folderMap[file.fieldname];
    const finalPath = path.join(tnoFolder, fieldFolder);

    cb(null, finalPath);
  },
  filename: (req, file, cb) => {
  const fileName = file.originalname;
    cb(null, fileName);
  }
});

// Initialize multer with storage settings
const upload = multer({ 
  storage: storage,  limits: {
  fileSize: 10 * 1024 * 1024 // 10 MB per file
  } 
});

function cleanUpFolder(folderPath, uploadedFilenames) {
  if (!fs.existsSync(folderPath)) return;
  const filesInFolder = fs.readdirSync(folderPath);
  filesInFolder.forEach(file => {
    if (!uploadedFilenames.includes(file)) {
      fs.unlinkSync(path.join(folderPath, file));
    }
  });
}

app.post(`/uploadImageFiles`, authenticateToken, upload.fields([
  { name: 'people[]'},
  { name: 'item_in[]'},
  { name: 'item_out[]'},
  { name: 'sign[]'}
]), (req, res) => {
  if (!req.files || Object.keys(req.files).length === 0) {
    return res.status(400).send('No files uploaded.');
  }

  try {
    const { tno, date, typeForm } = req.body;

    const parsedDate = new Date(date);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const basePath = visitorConfig.pathImageDocuments;
    const tnoFolder = path.join(basePath, typeForm, `${year}`, `${month}`, tno);

    const uploadedFiles = req.files;

    const folderMap = {
      'people[]': 'people',
      'item_in[]': 'item_in',
      'item_out[]': 'item_out',
      'sign[]': 'signatures'
    };
    for (const [key, folderName] of Object.entries(folderMap)) {
      const folderPath = path.join(tnoFolder, folderName);
      const uploadedFileNames = uploadedFiles[key] ? uploadedFiles[key].map(file => file.filename) : [];
      cleanUpFolder(folderPath, uploadedFileNames);
    }
    res.status(200).send({
      message: 'Files uploaded and cleaned up successfully!',
      files: req.files
    });
  } catch (error) {
    next(err);
  }

});


function convertFilenameToUrl(filename, folder) {
  if (!filename) return null;
  return `${domain}/${pipe}/loadImages/${folder}/${filename}`;    // This line is link to load image directory
}

const transformFilenameToUrl = (data) =>
  data.map(record => {
    var dateFolder;
    if(record.request_type == 'VISITOR'){
      dateFolder = record.date_in;
    }else{
      dateFolder = record.date_out
    }
    const parsedDate = new Date(dateFolder);
    const year = parsedDate.getFullYear();
    const month = String(parsedDate.getMonth() + 1).padStart(2, '0');
    const ymFolder = `${year}/${month}`

    const fields = ["empSign_sign", "approved_sign", "media_sign", "mainEn_sign", "proArea_sign"];
    fields.forEach(field => {
      if (record[field]) {
        record[field] = convertFilenameToUrl(record[field], `${record.request_type}/${ymFolder}/${record.tno_pass}/signatures`);
      }
    });

    if (record.people?.length) {
      record.people = record.people.map(person => ({
        ...person,
        Signature: person.Signature ? convertFilenameToUrl(person.Signature, `${record.request_type}/${ymFolder}/${record.tno_pass}/people`) : null,
      }));
    }

    ["item_in", "item_out"].forEach(type => {
      if (record[type]?.type === "image" && 
        Array.isArray(record[type]?.item) &&
        record[type].item.length > 0) 
        {
        record[type].item = record[type].item.map(filename =>
          convertFilenameToUrl(filename, `${record.request_type}/${ymFolder}/${record.tno_pass}/${type}`)
        );
      }
    });

    return record;
  });

  async function copySignatureFile(type, tno, filenameOld) {
    try {
      if (!filenameOld) {
        console.error("Filename is missing.");
        return null;
      }
  
      //Copy Image 
      const sourceUrl = `${visitorConfig.pathImageSignatureUser}/${filenameOld}`;
      const fileExtension = path.extname(filenameOld);
      const filenameTarget = `approved${fileExtension}`;
  
      //Paste Image
      const targetFolder = path.join(visitorConfig.pathImageDocuments, type, tno, "signatures");
      if (!fs.existsSync(targetFolder)) fs.mkdirSync(targetFolder);
  
      const targetPath = path.join(targetFolder, filenameTarget);
      return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(targetPath);
  
        http.get(sourceUrl, (response) => {
          if (response.statusCode !== 200) {
            reject(`Failed to download file: HTTP ${response.statusCode}`);
            return;
          }
  
          response.pipe(file);
          file.on("finish", () => {
            file.close();
            resolve(filenameTarget);
          });
        }).on("error", (err) => {
          fs.unlink(targetPath, () => {});
          reject(err);
        });
      });
    } catch (err) {
      console.error("Error copying file:", err);
      return null;
    }
  }

// ---------------------------------------------- Schedule  ---------------------------------------------- //
// Function to send FCM notifications
const sendNotification = async (fcm_tokens) => {
  if (!fcm_tokens || fcm_tokens.length === 0) return;

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
    tokens: fcm_tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log("Notification sent to:", response);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
};

// Cron job to check for unsigned forms every 30 minutes
cron.schedule(visitorConfig.notifyTime, async () => {
  try {
    const today = new Date().toISOString().split("T")[0];
    const queryDoc = `SELECT tno_pass, building_card FROM PASS_REQUEST WHERE date_in = ? AND approved_status = 0`;;
    const resultDoc = await dbQuery(queryDoc, [today]);

    if (resultDoc.length === 0) {
      console.log("No pending pass requests today.");
      return;
    }

    const buildingCardConditions = {
      Y: "CardManager",
      N: "Manager",
      O: "Manager,CardManager",
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

    const queryFCM = `SELECT fcm_token FROM FCM_TOKEN WHERE ${rolesCondition}`;
    const resultFCM = await dbQuery(queryFCM);

    const fcm_tokens = resultFCM.map((row) => row.fcm_token).filter(Boolean);

    if (fcm_tokens.length > 0) {
      sendNotification(fcm_tokens);
    } else {
      console.log("No devices found for the selected roles.");
    }
  } catch (err) {
    console.error(`[FCMService] DB Error: ${err.message}`);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});


// Clear FCM token when not active > 15 day
// Schedule to run once a day at 2:00 AM
cron.schedule(visitorConfig.clearFCMToken, async () => {
  try {
    const query = `
      DELETE FROM FCM_TOKEN
      WHERE last_active < NOW() - INTERVAL 15 DAY
    `;
    const result = await dbQuery(query);
    console.log(`Deleted ${result.rowCount || result.affectedRows} expired FCM tokens.`);
  } catch (error) {
    console.error('Error deleting old FCM tokens:', error);
  }
});


// ---------------------------------------------- LoadImage ---------------------------------------------- //
// load image directory
app.use(`/loadImages`, express.static(visitorConfig.pathImageDocuments));


// ---------------------------------------------- logError ---------------------------------------------- //
function logError(message, stack, timestamp) {
  const pathLogError = visitorConfig.path_logError;
  if (!fs.existsSync(pathLogError)) fs.mkdirSync(pathLogError, { recursive: true });
  const date = timestamp.split(" ")[0];
  const logFilePath = path.join(pathLogError, `logError_${date}.txt`);
  const logEntry = `\n[${timestamp}] \n[Error] ${message} \n[Stack Trace]\n${stack}\n-------------------`;

  fs.appendFileSync(logFilePath, logEntry);

  const logFiles = fs.readdirSync(pathLogError)
    .filter(file => file.startsWith("logError_") && file.endsWith(".txt"))
    .map(file => ({ name: file, time: fs.statSync(path.join(pathLogError, file)).ctime.getTime() }))
    .sort((a, b) => a.time - b.time);

  while (logFiles.length > visitorConfig.max_logError) {
    fs.unlinkSync(path.join(pathLogError, logFiles.shift().name));
  }
}

// API to handle incoming error logs
app.post(`/logError`, (req, res) => {
  const { message, stack, timestamp } = req.body;
  logError(message, stack, timestamp);
  res.status(200).send("Write error logged successfully");
});

// ---------------------------------------------- Handler Error ---------------------------------------------- //
// Global error handler – place last!
app.use(errorHandler);

// ---------------------------------------------- Listen Port ---------------------------------------------- //
// Set up server to listen
const PORT = visitorConfig.port;
app.listen(PORT, () => {
  console.log(`Server is running on ${PORT}`);
});