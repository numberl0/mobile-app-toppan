// apiGateway.js
const express = require('express');
const httpProxy = require('http-proxy');
const cors = require('cors');

const { gateWayConfig, ldapConfig, visitorConfig } = require('./config');

const app = express();
app.disable('x-powered-by');

// Gatway
const domain = gateWayConfig.domain;
const gateIp = gateWayConfig.ip;
const gatePort = gateWayConfig.port;
// LdapConfig
const authPort = ldapConfig.port
// VisitorConfig
const visitorPort = visitorConfig.port

const proxy = httpProxy.createProxyServer();

const corsOptions = {
  origin: [domain],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};
app.use(cors(corsOptions));

// Proxy Authentication Service
app.use(`/auth`, (req, res) => {
  proxy.web(req, res, { target: `http://${gateIp}:${authPort}` }); // authentication service (LDAP)
});

// Proxy Visitor App Service
app.use(`/visitor`, (req, res) => {
  proxy.web(req, res, { target: `http://${gateIp}:${visitorPort}` }); // visitor app service (MySQL)
});

app.listen(gatePort, () => {
  console.log(`API Gateway listening at http://${gateIp}:${gatePort}`);
});
