// routes/user.routes.js
const express = require('express');
const authenticateToken = require('../middlewares/authenticateToken');
const router = express.Router();
const ApiError = require('../utils/apiError');
const { db } = require("../config/db");

router.get(`/get-firstname`, authenticateToken, async (req, res, next) => {
  try {
    const { username } = req.query;

    if (!username) {
      return next(new ApiError(400, "Missing 'username' query parameter"))
    }

    const [rows] = await db.query('SELECT first_name FROM USER WHERE username = ?', [username]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'User Not Found' });
    }

    res.status(200).json({
      first_name: rows[0].first_name
    });

  } catch (err) {
    next(err);
  }
});

router.get(`/role-by-user`, authenticateToken, async (req, res, next) => {
  try {
    const { username } = req.query;
    if (!username) {
      return next(new ApiError(400, "Missing 'username' query parameter"))
    }
    const [results] = await db.query('SELECT role FROM USER WHERE username = ?', [username]);

    if (results.length === 0) {
      return next(new ApiError(404, 'User Not Found With This username'));
    }

    const roles = results.map(row => row.role);
    res.status(200).json({ message: 'Users Found', data: roles });

  } catch (err) {
    next(err);
  }
});


router.get(`/manager-role`, authenticateToken, async (req, res, next) => {
  try {
    const [results] = await db.query('SELECT * FROM USER WHERE enable=? AND role NOT IN (?, ?)', [1, 'administrator', 'guest']);
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

// Update FCM Token
router.patch(`/device-token/:device_id`, authenticateToken, async (req, res, next) => {
  try {
    const { device_id } = req.params;
    if (!device_id) {
      return res.status(400).json({ message: 'Missing device_id in URL' });
    }
    const data = req.body;
    if (!data || typeof data !== 'object' || Object.keys(data).length === 0) {
      return next(new ApiError(400, 'Invalid Data'));
    }
    const query = `UPDATE DEVICE_TOKEN SET ? WHERE device_id = ?`;
    const [result] = await db.query(query, [data, device_id]);

    if (!result || result.affectedRows === 0) {
      return next(new ApiError(400, 'Device not found'));
    }

    res.status(200).json({ message: 'Update FCM Token successful' });
  } catch (err) {
    next(err);
  }
});

// Update last active FCM Token
router.patch(`/active-token/:device_id`, authenticateToken, async (req, res, next) => {
  try {
    const { device_id } = req.params;
    if (!device_id) {
      return res.status(400).json({ message: 'Missing device_id in URL' });
    }


    const { last_active} = req.body;

    if (!device_id || !last_active) {
      return next(new ApiError(400, 'Missing device_id or last_active'));
    }

    const query = `UPDATE DEVICE_TOKEN SET last_active = ? WHERE device_id = ?`;
    const [result] = await db.query(query, [last_active, device_id]);

    if (!result || result.affectedRows === 0) {
      return next(new ApiError(400, 'Update Failed'));
    }

    res.status(200).json({ message: 'FCM Token last_active updated successfully' });
  } catch (err) {
    next(err);
  }
});

// // ---------------------------------------------- Delete ---------------------------------------------- //
// router.delete(`/fcm_token/:fcm_token`, authenticateToken, async (req, res, next) => {
//   try {
//     const { fcm_token } = req.params;

//     if (!fcm_token) {
//       return next(new ApiError(400, 'Missing fcm_token.'));
//     }

//     const selectQuery = `SELECT * FROM DEVICE_TOKEN WHERE fcm_token = ?`;
//     const [rows] = await db.query(selectQuery, [fcm_token]);

//     if (rows.length === 0) {
//       console.warn("[WARN] FCM Token not found in database.");
//       return res.status(200).json({ message: "FCM Token deleted successfully" });
//     }

//     // ถ้าเจอ token ให้ลบ
//     const deleteQuery = `DELETE FROM DEVICE_TOKEN WHERE fcm_token = ?`;
//     await db.query(deleteQuery, [fcm_token]);

//     res.status(200).json({ message: "Token deleted successfully" });
//   } catch (err) {
//     next(err);
//   }
// });

router.get(`/check-token`, authenticateToken, async (req, res, next) => {
  try {
    const { device_id } = req.query;
    const [results] = await db.query('SELECT * FROM DEVICE_TOKEN WHERE device_id=?', [device_id]);
    if (results.length === 0) {
      res.status(200).json({ message: 'Device ID Not Found', data: false});
    }else{
      res.status(200).json({ message: 'Device ID Found', data: true});
    }
  } catch (err) {
    next(err);
  }
});

module.exports = router;