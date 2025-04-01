//authenticationService.js
const express = require('express');
const ldap = require('ldapjs');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();

app.use(bodyParser.json());
app.use(cors());


const { ldapConfig, jwtToken } = require('./config');

// ldapConfig
const ldapDomain = ldapConfig.domain;
const ldapServer = ldapConfig.server;
const pipe = ldapConfig.pipe;

// jwtToken
const jwtSecret = jwtToken.key;

app.post(`${pipe}/auth`, (req, res) => {
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

const PORT = ldapConfig.port;
app.listen(PORT, () => {
    console.log(`Server is running on ${PORT}`);
});