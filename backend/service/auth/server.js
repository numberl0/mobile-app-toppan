//authenticationService.js
const express = require('express');
const ldap = require('ldapjs');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');
const cors = require('cors');

const { gateWayConfig, ldapConfig, jwtToken } = require('../../shared/config');

//domain
const domain = gateWayConfig.domain;
// ldapConfig
const ldapDomain = ldapConfig.domain;
const ldapServer = ldapConfig.server;
const ldapPort = ldapConfig.port;

// jwtToken
const jwtSecret = jwtToken.key;

const app = express();

app.disable('x-powered-by');

const corsOptions = {
  origin: [domain ],
  methods: ['POST'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};

app.use(cors(corsOptions));
app.use(bodyParser.json());

// app.post(`/auth`, (req, res) => {
//     const { username, password } = req.body;

//     // LDAP authentication logic inside the route handler
//     const client = ldap.createClient({ url: `ldap://${ldapServer}` });
//     const bindDn = username + '@' + ldapDomain;

//     client.bind(bindDn, password, (err) => {
//         client.unbind();
//         if (err) {
//             client.unbind();
//             return res.status(401).json({ message: 'Authentication failed', error: err.message });
//         } else {
//             const payload = {
//                 username,
//             };
//             const token = jwt.sign(payload , jwtSecret, {expiresIn: '1y'});
//             return res.status(200).json({ 
//                 message: 'Authentication successful',
//                 data: {
//                     username,
//                     token,
//                 }
//             });
//         }
//     });
// });

app.post(`/auth`, (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ message: 'Username and password are required' });
    }

    const client = ldap.createClient({ url: `ldap://${ldapServer}` });
    const bindDn = `${username}@${ldapDomain}`;

    client.bind(bindDn, password, (err) => {
        if (err) {
            client.unbind();
            return res.status(401).json({ message: 'Authentication failed', error: err.message });
        }

        const ldapBaseDn = ldapDomain.split('.').map(part => `dc=${part}`).join(',');
        const searchOptions = {
            filter: `(sAMAccountName=${username})`,
            scope: 'sub',
            attributes: ['displayName']
        };

        client.search(ldapBaseDn, searchOptions, (err, searchRes) => {
            if (err) {
                client.unbind();
                return res.status(500).json({ message: 'LDAP search failed', error: err.message });
            }
            let displayName = null;
            searchRes.on('searchEntry', (entry) => {
                const attr = entry.attributes.find(a => a.type === 'displayName');
                if (attr && attr.values && attr.values.length > 0) {
                    displayName = attr.values[0];
                    console.log('Extracted displayName:', displayName);
                } else {
                    console.log('No displayName found:', entry.attributes);
                }
            });

            searchRes.on('error', (err) => {
                client.unbind();
                return res.status(500).json({ message: 'Search error', error: err.message });
            });

            searchRes.on('end', () => {
                client.unbind();

                if (!displayName) {
                    return res.status(404).json({ message: 'User not found or displayName not set in directory' });
                }

                const payload = { username };
                const token = jwt.sign(payload, jwtSecret, { expiresIn: '1y' });

                return res.status(200).json({
                    message: 'Authentication successful',
                    data: {
                        username,
                        displayName,
                        token
                    }
                });
            });
        });
    });
});




app.listen(ldapPort, () => {
    console.log(`Server is running on ${ldapPort}`);
});