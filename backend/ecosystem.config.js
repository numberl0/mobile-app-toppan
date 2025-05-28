// ecosystem.config.js
const { gateWayConfig, ldapConfig, visitorConfig } = require('./shared/config');

module.exports = {
    apps: [
      // GateWay for test
      {
        name: 'apiGateway',
        script: 'service/gateway/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: false,
        env: {
          PORT: gateWayConfig.port, // API Gateway port
        },
        max_restarts: 2,
        min_uptime: 60000, //1 minute
      },

      // LDAP
      {
        name: 'auth',
        script: 'service/auth/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: false,
        env: {
          PORT: ldapConfig.port,  // API LDAP port
        },
        max_restarts: 2,
        min_uptime: 60000, //1 minute
      },

      // Visitor
      {
        name: 'visitor',
        script: 'service/visitor/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: false,
        env: {
          PORT: visitorConfig.port, // API VisitorApp port
        },
        max_restarts: 2,
        min_uptime: 60000, //1 minute
      },
    ],
  };