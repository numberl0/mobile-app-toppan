// ecosystem.config.js
const { gateWayConfig, ldapConfig, visitorConfig } = require('./config');

module.exports = {
    apps: [
      // GateWay
      {
        name: 'apiGateway',
        script: 'apiGateway.js',
        instances: 1,
        exec_mode: 'fork',
        watch: true,
        env: {
          PORT: gateWayConfig.port, // API Gateway port
        },
      },

      // LDAP
      {
        name: 'authentication',
        script: 'authenticationService.js',
        instances: 1,
        exec_mode: 'fork',
        watch: true,
        env: {
          PORT: ldapConfig.port,  // API LDAP port
        },
      },

      // Visitor
      {
        name: 'visitor',
        script: './visitorService/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: true,
        env: {
          PORT: visitorConfig.port, // API VisitorApp port
        },
      },
    ],
  };