//visitorApp server.js
const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');

const cron = require("node-cron");    //  Runs scheduled tasks
const admin = require("../firebase/firebase");  // firebase service account

//path file
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const http = require("http");

// Import The Middleware
const authenticateToken = require('../authenticateToken');

const app = express();

app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors());

const { gateWayConfig, visitorDB, visitorConfig } = require('../config');

//  
const httpIp = gateWayConfig.http_ip;

// Pipeline
const pipe = visitorConfig.pipe;

// Connection database MYSQL-Front
const db = mysql.createConnection(visitorDB);

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
app.get(`${pipe}/getAgreement`, authenticateToken, (req, res) => {
  const { version } = req.query
  db.query('SELECT * FROM AGREEMENT WHERE version=?', version, (err, results) => {
      if (err) {
          console.error('Error in database query:', err.stack);
          return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
      }
      if (results.length === 0) {
          return res.status(401).json({ error: 'No found aggrement' });
      }
      res.status(200).json({ message: 'aggrement found', data: results });
  });
});

//Get role user
app.get(`${pipe}/getRoleByUser`, authenticateToken, (req, res) => {
  const { username } = req.query;
    if (!username) {
    return res.status(400).json({ error: "You don't have user in VisitorApp" });
    }
    db.query('SELECT role FROM USER WHERE username = ?', [username], (err, results) =>{
        if (err) {
            console.error('Error in database query:', err.stack);
            return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
        }
        if (results.length === 0) {
          return res.status(401).json({ error: 'No users found with this username' });
        }
        const roles = results.map(row => row.role);
        res.status(200).json({ message: 'Users found', data: roles });
    })
});

//Get role building
app.get(`${pipe}/getBuilding`, authenticateToken, (req, res) => {
  db.query('SELECT * FROM BUILDING', (err, results) => {
      if (err) {
          console.error('Error in database query:', err.stack);
          return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
      }
      if (results.length === 0) {
          return res.status(404).json({ error: 'No buildings found' });
      }
      res.status(200).json({ message: 'Building found', data: results });
  });
});

// Get role manage
app.get(`${pipe}/getManagerRole`, authenticateToken, (req, res) => {
  db.query('SELECT * FROM USER WHERE enable=? AND role NOT IN (?, ?)', [1,'administrator', 'guest'], (err, results) => {
      if (err) {
          console.error('Error in database query:', err.stack);
          return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
      }
      if (results.length === 0) {
          return res.status(401).json({ error: 'No roles found' });
      }

      const userMap = {};

      results.forEach(user => {
          const { id, username, email, sign_name, title_name, first_name, last_name, enable, session_token, role } = user;
          
          if (userMap[username]) {
              userMap[username].role.push(role);

            if (userMap[username].session_token === null && session_token !== null) {
              userMap[username].session_token = session_token;
            }
          } else {
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
                  role: [role]
              };
          }
      });

      const mergedResults = Object.keys(userMap).map(username => {
          const user = userMap[username];
          user.role = user.role.join(', ');

          return user;
      });

      res.status(200).json({ message: 'Roles found', data: mergedResults });
  });
});

//Get sequence running number
app.get(`${pipe}/getSequenceRunning`, authenticateToken, (req, res) => {
  const { type } = req.query
  db.query('SELECT * FROM SEQUENCE_RUNNING_FORM WHERE type=?', type, (err, results) => {
      if (err) {
          console.error('Error in database query:', err.stack);
          return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
      }
      if (results.length === 0) {
          return res.status(401).json({ error: 'No found sequence' });
      }
      res.status(200).json({ message: 'Sequence found', data: results });
  });
});

app.get(`${pipe}/getSignaturFilenameByUsername`, authenticateToken, async (req, res) => {
  try {
    const { username } = req.query;
    if(!username) {
      return res.status(400).json({ error: "Empty username" });
    }
    const query = `SELECT DISTINCT sign_name FROM USER WHERE username = ?`;
    const results = await dbQuery(query, [username])
    res.status(200).json({
      message: "Query Successful",
      data: results,
    });
  } catch (err) {
    console.error("Error fetching", err);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// Search by date : yyyy-MM-dd
app.get(`${pipe}/getRequestFormByDate`, authenticateToken, async (req, res) => {
  try {
    const {dateToDay} = req.query;
    if (!dateToDay) {
      return res.status(400).json({ error: "Date parameter is required (yyyy-MM-dd)" });
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
    WHERE DATE(pr.date) IN (?, ?);
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


    // Execute queries
    const [passResults, visitorResults] = await Promise.all([
      dbQuery(queryPassRequest, [dateToDay, datePrevDay]),
      dbQuery(queryVisitorNormal, [dateToDay, datePrevDay])
    ]);
    const formattedVisitorResults = visitorResults.map(entry => {
      return {
        'tno_pass': null,
        'request_type': 'VISITOR',
        'sequence_no': null,
        'company': entry['company']? entry['company']:null,
        'vehicle_no': null,
        'date': entry['date_visitor1'],
        'time_in': entry['timerang'] ? entry['timerang'].split(' ถึง ')[0] : null, 
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

    // Transform image filenames into URLs
    const transformInUrl = transformFilenameToUrl(passResults);
    let mergedData = [...transformInUrl, ...formattedVisitorResults];


    res.status(200).json({
      message: "Data found",
      data: mergedData,
    });
  } catch (err) {
    console.error("Error fetching pass requests:", err);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }

});

// Get Request Document By Role Approver
app.get(`${pipe}/getRequestApproved`, authenticateToken, async (req, res) => {
  try {
    let { building_card } = req.query;
    if (!building_card) {
      return res.status(400).json({ error: "Missing building_card parameter" });
    }
    if (!Array.isArray(building_card)) {
      building_card = [building_card]; // Convert single value to array
    }

    if (building_card.length === 0) {
      return res.status(400).json({ error: "Invalid or empty building_card list" });
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
    `;

    const results = await dbQuery(query, [building_card]);
    const transformResults = transformFilenameToUrl(results);

    res.status(200).json({
      message: "Query successful",
      data: transformResults,
    });
  } catch (err) {
    console.error("Error fetching", err);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// ---------------------------------------------- Checker ---------------------------------------------- //
app.get(`${pipe}/passRequestDoesNotExist`, authenticateToken, async (req, res) => {
  try {
    const { tno_pass } = req.query;

    if (!tno_pass) {
      return res.status(400).json({ error: "Missing tno_pass" });
    }

    const query = 'SELECT COUNT(*) AS count FROM PASS_REQUEST WHERE tno_pass = ?';
    const results = await dbQuery(query, [tno_pass]);

    const doesNotExist = results[0].count === 0;
    res.status(200).json({ doesNotExist });

  } catch (err) {
    console.error('Error in database query:', err.stack);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});


// ---------------------------------------------- Insert Table ---------------------------------------------- //
// Insert Pass Form 
app.post(`${pipe}/uploadPassForm`, authenticateToken, (req, res) => {
  const data = req.body;
  const structuredData = {
    tno_pass: data.tno_pass,
    visitorType: data.visitorType,
    people: JSON.stringify(data.people), 
    item_in: JSON.stringify(data.item_in),
    item_out: JSON.stringify(data.item_out),
  };
  const query = 'INSERT INTO PASS_FORM SET ?';
  db.query(query, structuredData, (err, results) => {
    if (err) {
      console.error('Error in database query:', err.stack);
      return res.status(500).json({ error: `Internal Server Error : ${err.message}`});
    }
    res.status(200).json({ message: 'Insert data successfully', tno_pass: data.tno_pass});
  });
});

// Insert Pass Request
app.post(`${pipe}/uploadPassRequest`, authenticateToken, (req, res) => {
  const data = req.body;
  const query = 'INSERT INTO PASS_REQUEST SET ?';
  db.query(query, data, (err, results) => {
    if (err) {
      console.error('Error in database query:', err.stack);
      return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
    }
    res.status(200).json({ message: 'Insert data successfully', tno_pass: data.tno_pass });
  });
});

// Insert Activity Log
app.post(`${pipe}/insertActivityLog`, authenticateToken, async (req, res) => {
  try {
    const data = req.body;

    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return res.status(400).json({ error: 'Invalid Data' });
    }

    const query = `INSERT INTO LOG_MOBILE_APP SET ?`;

    const result = await dbQuery(query, data);

    if (!result || result.affectedRows === 0) {
      return res.status(400).json({ error: 'Insert failed' });
    }

    res.status(200).json({ message: 'Insert activity successful' });
  } catch (err) {
    console.error(`[visitorService] DB Error: ${err.message}`);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// Insert FCM Token
app.post(`${pipe}/insertFCMToken`, authenticateToken, async (req, res) => {
  try {
    const data = req.body;

    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return res.status(400).json({ error: 'Invalid Data' });
    }

    const query = `INSERT INTO FCM_TOKEN SET ?`;

    const result = await dbQuery(query, data);

    if (!result || result.affectedRows === 0) {
      return res.status(400).json({ error: 'Insert failed' });
    }

    res.status(200).json({ message: 'Insert FCM Token successful' });
  } catch (err) {
    console.error(`[visitorService] DB Error: ${err.message}`);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// ---------------------------------------------- Update Table ---------------------------------------------- //
//Get sequence running number
app.post(`${pipe}/updateSequenceRunning`, authenticateToken, (req, res) => {
  const { type, sequence } = req.body;

  db.query(
    'UPDATE SEQUENCE_RUNNING_FORM SET sequence = ? WHERE type = ?',
    [sequence, type],
    (err, results) => {
      if (err) {
        console.error('Error in database query:', err.stack);
        return res.status(500).json({ error: `Internal Server Error : ${err.message}` });
      }

      if (results.affectedRows === 0) {
        return res.status(404).json({ error: 'Type not found, no update made' });
      }

      res.status(200).json({message: 'Sequence successfully updated'});
    }
  );
});

// Update Pass Form 
app.post(`${pipe}/updatePassForm`, authenticateToken, async (req, res) => {
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
      return res.status(404).json({ message: 'No record updated, tno_pass not found' });
    }

    res.status(200).json({ message: 'Update successful', updatedId: data.tno_pass });

  } catch (err) {
    console.error('Error in database query:', err.stack);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// Update Pass Request
app.post(`${pipe}/updatePassRequest`, authenticateToken, async (req, res) => {
  try {
    const {data} = req.body;
    const query = `UPDATE PASS_REQUEST SET ? WHERE tno_pass = ?`;
    const [results] = await Promise.all([dbQuery(query, [data, data.tno_pass]),]);
    if (results.affectedRows === 0) {
      return res.status(404).json({ message: 'No record updated, tno_pass not found' });
    }

    res.status(200).json({ message: 'Update successful', updatedId: data.tno_pass });

  } catch (err) {
    console.error('Error in database query:', err.message);
    res.status(500).json({ error: `Internal Server Error : ${err.message}`});
  }
});

//update approved document
app.post(`${pipe}/approvedDocument`, authenticateToken, async (req, res) => {
  try {
    const { tno, type, data } = req.body
    if(!tno || !type || !data) {
      return res.status(400).json({ error: "Invalid or missing data" });
    }

    const filename = await copySignatureFile(type, tno, data.approved_sign);
    if(!filename){
      return res.status(500).json({ error: "Failed to move signature file." });
    }
    data.approved_sign = filename; 

    const fields = Object.keys(data).map(key => `${key} = ?`).join(", ");
    const values = Object.values(data);
    values.push(tno);

    const query = `UPDATE PASS_REQUEST SET ${fields} WHERE tno_pass = ?`;
    await dbQuery(query, values);

    res.status(200).json({ message: "Update Approved Successful",});
  } catch (err) {
    console.error("Error fetching", err);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

//update approved document all
app.post(`${pipe}/approvedAll`, authenticateToken, async (req, res) => {
  try {
    const { tno_listMap, sign_info } = req.body

    // Check req
    if (!tno_listMap || !sign_info) {
      return res.status(400).json({ error: "Invalid or missing data" });
    }

    // Duplicate image to traget folder and change name
    let filename = '';
    for (const item of tno_listMap) {
      filename = await copySignatureFile(item.type, item.tno_pass, sign_info.approved_sign);
      if(!filename){
        return res.status(500).json({ error: "Failed to move signature file." });
      }
    }
    sign_info.approved_sign = filename;

    // Map query sign_info
    const fields = Object.keys(sign_info).map(key => `${key} = ?`).join(", ");
    const values = Object.values(sign_info);

    // Get tno_pass in list
    const tno_list = tno_listMap.map(item => item.tno_pass);
    if (tno_list.length === 0) {
      return res.status(400).json({ error: "Missing tno_pass values" });
    }

    // Query text by tno_pass list
    const tno_list_query = tno_list.map(() => '?').join(", ");
    values.push(...tno_list);

    const query = `UPDATE PASS_REQUEST SET ${fields} WHERE approved_status = 0 AND tno_pass IN (${tno_list_query})`;
    await dbQuery(query, values);

    res.status(200).json({ message: "Update Approved Successful",});
  } catch (err) {
    console.error("Error fetching", err);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// ---------------------------------------------- Delete ---------------------------------------------- //
app.delete(`${pipe}/deleteFCMToken`, authenticateToken, async (req, res) => {
  try {
    const { device_id} = req.body;

    if (!device_id) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const query = `DELETE FROM FCM_TOKEN WHERE device_id = ?`;
    const result = await dbQuery(query, [device_id]);

    if (result.affectedRows === 0) {
      console.error("[ERROR] FCM Token not found in database.");
      return res.status(404).json({ error: "FCM Token not found" });
    }

    res.status(200).json({ message: "FCM Token deleted successfully" });
  } catch (err) {
    console.error(`[FCMService] DB Error: ${err.message}`);
    res.status(500).json({ error: `Internal Server Error : ${err.message}` });
  }
});

// ---------------------------------------------- Additional Functions ---------------------------------------------- //

// Set up storage configuration for multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const { tno, typeForm} = req.body;

    const basePath = visitorConfig.pathImageDocuments;

    //type
    const typeFormFolder = `${basePath}/${typeForm}`;
    if (!fs.existsSync(typeFormFolder)) {
      fs.mkdirSync(typeFormFolder);
    }

    //tno
    const tnoFolder = `${typeFormFolder}/${tno}`;
    if (!fs.existsSync(tnoFolder)) {
      fs.mkdirSync(tnoFolder);
    }

    const personFolder = `${tnoFolder}/people`;
    const itemInFolder = `${tnoFolder}/item_in`;
    const itemOutFolder = `${tnoFolder}/item_out`;
    const signFolder = `${tnoFolder}/signatures`;

    if (!fs.existsSync(personFolder)) fs.mkdirSync(personFolder);
    if (!fs.existsSync(signFolder)) fs.mkdirSync(signFolder);

    if (file.fieldname === 'item_in[]' && !fs.existsSync(itemInFolder)) {
      fs.mkdirSync(itemInFolder);
    }
    if (file.fieldname === 'item_out[]' && !fs.existsSync(itemOutFolder)) {
      fs.mkdirSync(itemOutFolder);
    }

    const folderMap = {
      'people[]': 'people',
      'item_in[]': 'item_in',
      'item_out[]': 'item_out',
      'sign[]': 'signatures'
    };

    const fieldFolder = folderMap[file.fieldname];
    cb(null, `${tnoFolder}/${fieldFolder}`);
  },
  filename: (req, file, cb) => {
  const fileName = file.originalname;
    cb(null, fileName);
  }
});

// Initialize multer with storage settings
const upload = multer({ storage: storage });
app.post(`${pipe}/uploadImageFiles`, authenticateToken, upload.fields([
  { name: 'people[]'},
  { name: 'item_in[]'},
  { name: 'item_out[]'},
  { name: 'sign[]'}
]), (req, res) => {
  if (!req.files || Object.keys(req.files).length === 0) {
    return res.status(400).send('No files uploaded.');
  }
  res.status(200).send({
    message: 'Files uploaded successfully!',
    files: req.files
  });
});


function convertFilenameToUrl(filename, folder) {
  if (!filename) return null;
  return `${httpIp}/${pipe.isNotEmpty ? pipe : visitorConfig.harderIp}/loadImages/${folder}/${filename}`;    // This line is link to load image directory
}

const transformFilenameToUrl = (data) =>
  data.map(record => {
    const fields = ["empSign_sign", "approved_sign", "media_sign", "mainEn_sign", "proArea_sign"];
    fields.forEach(field => {
      if (record[field]) {
        record[field] = convertFilenameToUrl(record[field], `${record.request_type}/${record.tno_pass}/signatures`);
      }
    });

    if (record.people?.length) {
      record.people = record.people.map(person => ({
        ...person,
        Signature: person.Signature ? convertFilenameToUrl(person.Signature, `${record.request_type}/${record.tno_pass}/people`) : null,
      }));
    }

    ["item_in", "item_out"].forEach(type => {
      if (record[type]?.type === "image" && 
        Array.isArray(record[type]?.item) &&
        record[type].item.length > 0) 
        {
        record[type].item = record[type].item.map(filename =>
          convertFilenameToUrl(filename, `${record.request_type}/${record.tno_pass}/${type}`)
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
      const filenameTarget = `approved_Signature${fileExtension}`;
  
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
    const queryDoc = `SELECT tno_pass, building_card FROM PASS_REQUEST WHERE date = ? AND approved_status = 0`;;
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


// ---------------------------------------------- LoadImage ---------------------------------------------- //
// load image directory
app.use(`${pipe}/loadImages`, express.static(visitorConfig.pathImageDocuments));


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
app.post(`${pipe}/logError`, (req, res) => {
  const { message, stack, timestamp } = req.body;
  logError(message, stack, timestamp);
  res.status(200).send("Write error logged successfully");
});

// ---------------------------------------------- Listen Port ---------------------------------------------- //
// Set up server to listen
const PORT = visitorConfig.port;
app.listen(PORT, () => {
  console.log(`Server is running on ${PORT}`);
});