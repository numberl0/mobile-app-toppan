// ecosystem.config.js
const { gateWayConfig, ldapConfig, visitorConfig } = require('./config');

module.exports = {
    apps: [
      // GateWay for test
      // {
      //   name: 'apiGateway',
      //   script: 'apiGateway.js',
      //   instances: 1,
      //   exec_mode: 'fork',
      //   watch: true,
      //   env: {
      //     PORT: gateWayConfig.port, // API Gateway port
      //   },
      //   max_restarts: 1,
      //   min_uptime: 10000,
      // },

      // LDAP
      {
        name: 'auth',
        script: 'authService.js',
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
        script: './visitorService/server.js',
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