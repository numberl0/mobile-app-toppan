// apiGateway.js
const express = require('express');
const httpProxy = require('http-proxy');
const cors = require('cors');
const app = express();
const proxy = httpProxy.createProxyServer();


// Enable CORS for all requests
app.use(cors());

const { gateWayConfig, ldapConfig, visitorConfig } = require('./config');

// Gatway
const gateIp = gateWayConfig.ip;
const gatePort = gateWayConfig.port;

// LdapConfig
const authPort = ldapConfig.port

// VisitorConfig
const visitorPort = visitorConfig.port

// Proxy Authentication Service
app.use(`/auth`, (req, res) => {
  proxy.web(req, res, { target: `http://${gateIp}:${authPort}` }); // authentication service (LDAP)
});

// Proxy Visitor App Service
app.use(`/visitor`, (req, res) => {
  proxy.web(req, res, { target: `http://${gateIp}:${visitorPort}` }); // visitor app service (MySQL)
});

// // Error handling for the proxy
// proxy.on('error', (err, req, res) => {
//   console.error(`Error in proxy for ${req.originalUrl}:`, err);
//   if (req.originalUrl.startsWith('/authenticate')) {
//     res.status(503).json({ error: 'Authentication Service is unavailable' });
//   } else if (req.originalUrl.startsWith('/visitorService')) {
//     res.status(503).json({ error: 'Visitor App Service is unavailable' });
//   } else {
//     res.status(503).json({ error: 'Unknown service is unavailable' });
//   }
// });


app.listen(gatePort, () => {
  console.log(`API Gateway listening at http://${gateIp}:${gatePort}`);
});
