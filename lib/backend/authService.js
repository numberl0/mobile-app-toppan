//authenticationService.js
const express = require('express');
const ldap = require('ldapjs');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');
const cors = require('cors');

const { gateWayConfig, ldapConfig, jwtToken } = require('./config');

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

app.post(`/auth`, (req, res) => {
    const { username, password } = req.body;

    // LDAP authentication logic inside the route handler
    const client = ldap.createClient({ url: `ldap://${ldapServer}` });
    const bindDn = username + '@' + ldapDomain;

    client.bind(bindDn, password, (err) => {
        client.unbind();
        if (err) {
            return res.status(401).json({ message: 'Authentication failed', error: err.message });
        } else {
            const payload = {
                username,
            };
            const token = jwt.sign(payload , jwtSecret, {expiresIn: '1y'});
            return res.status(200).json({ 
                message: 'Authentication successful',
                data: {
                    username,
                    token,
                }
            });
        }
    });
});

app.listen(ldapPort, () => {
    console.log(`Server is running on ${ldapPort}`);
});