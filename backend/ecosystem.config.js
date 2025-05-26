// ecosystem.config.js
const { gateWayConfig, ldapConfig, visitorConfig } = require('./shared/config');

module.exports = {
    apps: [
      // GateWay for test
      {
        name: 'gateway',
        script: './service/gateway/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: true,
        env: {
          PORT: gateWayConfig.port, // API Gateway port
        },
        max_restarts: 1,
        min_uptime: 10000,
      },

      // LDAP
      {
        name: 'auth',
        script: './service/auth/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: true,
        env: {
          PORT: ldapConfig.port,  // API LDAP port
        },
        max_restarts: 1,
        min_uptime: 10000,
      },

      // Visitor
      {
        name: 'visitor',
        script: './service/visitor/server.js',
        instances: 1,
        exec_mode: 'fork',
        watch: true,
        env: {
          PORT: visitorConfig.port, // API VisitorApp port
        },
        max_restarts: 1,
        min_uptime: 10000,
      },
    ],
  };