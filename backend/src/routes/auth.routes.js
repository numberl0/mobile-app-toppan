// routes/auth.routes.js
const express = require('express');
const { db } = require("../config/db");
const router = express.Router();
const {ldapConfig, jwtToken} = require('../config/config');
const { loadConfig } = require('../utils/configUtil');

const ldap = require('ldapjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// ================================================

// ---------- LOGIN (LDAP) ----------
router.post('/authentication', async (req, res) => {
  const { username, password, deviceId } = req.body;

  if (!username || !password || !deviceId) {
    return res.status(400).json({ message: 'username, password and deviceId are required'});
  }

  const client = ldap.createClient({
    url: `ldap://${ldapConfig.server}`,
  });

  client.on('error', (err) => {
    console.error('LDAP client error:', err);
  });

  const bindDn = `${username}@${ldapConfig.domain}`;

  client.bind(bindDn, password, (err) => {
    if (err) {
      client.unbind();
      return res.status(401).json({ message: 'Authentication failed' });
    }

    const baseDn = ldapConfig.domain
      .split('.')
      .map(p => `dc=${p}`)
      .join(',');

    const options = {
      filter: `(sAMAccountName=${username})`,
      scope: 'sub',
      attributes: ['displayName'],
    };

    client.search(baseDn, options,  (err, searchRes) =>  {
      if (err) {
        client.unbind();
        return res.status(500).json({ message: 'LDAP search failed' });
      }

      let displayName = null;

      searchRes.on('searchEntry', (entry) => {
        const attr = entry.attributes.find(a => a.type === 'displayName');
        if (attr?.values?.length) {
          displayName = attr.values[0];
        }
      });

      searchRes.on('error', (err) => {
        client.unbind();
        return res.status(500).json({ message: 'LDAP search error' });
      });

      searchRes.on('end', async () => {
        client.unbind();

        if (!displayName) {
          return res.status(404).json({ message: 'User not found' });
        }

        try {
          // ===== ACCESS TOKEN (สั้น) =====
          const accessToken = jwt.sign(
            {
              sub: username,
              type: 'access',
            },
            jwtToken.key,
            { expiresIn: '15m' }
          );

          // ===== REFRESH TOKEN (random) =====
          const refreshToken = crypto.randomBytes(64).toString('hex');

          const refreshTokenHash = crypto
            .createHash('sha256')
            .update(refreshToken)
            .digest('hex');

          
          const expireValue = await loadConfig('LoginExpire');
          const expireDays = parseInt(expireValue || '30', 10);

          // ===== SAVE / UPDATE TOKEN BY DEVICE =====
          const query = `
            INSERT INTO DEVICE_TOKEN (device_id, username, refresh_token, last_active, refresh_expires_at)
            VALUES (?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? DAY) )
            ON DUPLICATE KEY UPDATE
              username = VALUES(username),
              refresh_token = VALUES(refresh_token),
              last_active = NOW(),
              refresh_expires_at = DATE_ADD(NOW(), INTERVAL ? DAY)
          `;
          await db.query(query, [
            deviceId,
            username,
            refreshTokenHash,
            expireDays,  // สำหรับ INSERT
            expireDays   // สำหรับ UPDATE
          ]);

          return res.status(200).json({
            message: 'Authentication successful',
            data: {
              displayName,
              accessToken,
              refreshToken,
            },
          });
        } catch (dbErr) {
          console.error('Database error:', dbErr);
          return res.status(500).json({ message: 'Database error' });
        }
      });
    });
  });
});



// ---------- REFRESH TOKEN ----------
router.post('/refresh', async (req, res) => {
  const { refreshToken, deviceId } = req.body;

  if (!refreshToken || !deviceId) {
    return res.status(400).json({ message: 'refreshToken and deviceId are required' });
  }

  try {
    const refreshTokenHash = crypto
      .createHash('sha256')
      .update(refreshToken)
      .digest('hex');

      const [rows] = await db.query(
        `SELECT username, refresh_token, refresh_expires_at
         FROM DEVICE_TOKEN
         WHERE device_id = ?`,
        [deviceId]
      );

      if (!rows.length) {
        return res.status(401).json({ message: 'Invalid session' });
      }

      const record = rows[0];

      // ===== CHECK TOKEN MATCH =====
      if (record.refresh_token !== refreshTokenHash) {
        return res.status(401).json({ message: 'Invalid refresh token' });
      }

       // ===== CHECK EXPIRE =====
      if (new Date() > record.refresh_expires_at) {

        // ลบ session ทิ้ง
        await db.query(
          `DELETE FROM DEVICE_TOKEN WHERE device_id = ?`,
          [deviceId]
        );

        return res.status(401).json({
          message: 'Refresh token expired'
        });
      }

      const username = record.username;

      // ===== ออก accessToken ใหม่ =====
      const accessToken = jwt.sign(
        {
          sub: username,
          type: 'access',
        },
        jwtToken.key,
        { expiresIn: '15m' }
      );

      // ===== ROTATE refreshToken =====
      const newRefreshToken = crypto.randomBytes(64).toString('hex');
      const newRefreshTokenHash = crypto
        .createHash('sha256')
        .update(newRefreshToken)
        .digest('hex');

      // update token ใหม่ (ค่าใหม่ แต่ session เดิม)
      await db.query(
        `UPDATE DEVICE_TOKEN
        SET refresh_token = ?, last_active = NOW()
        WHERE device_id = ?`,
        [newRefreshTokenHash, deviceId]
      );

      return res.status(200).json({
        success: true,
        accessToken,
        refreshToken: newRefreshToken,
      });

  } catch (err) {
    console.error('Refresh token error:', err);
    return res.status(500).json({ message: 'Refresh token failed' });
  }
});

// ---------- LOGOUT ----------
router.post('/logout', async (req, res) => {
  const { deviceId } = req.body;

  if (!deviceId) {
    return res.status(400).json({ message: 'deviceId is required' });
  }

  try {
    await db.query(
      `DELETE FROM DEVICE_TOKEN WHERE device_id = ?`,
      [deviceId]
    );

    return res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (err) {
    console.error('Logout error:', err);
    return res.status(500).json({ message: 'Logout failed' });
  }
});


module.exports = router;