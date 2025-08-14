// ecosystem.config.js
const { gateWayConfig, ldapConfig, visitorConfig } = require('./shared/config');

module.exports = {
    apps: [
      // // GateWay for test
      // {
      //   name: 'apiGateway',
      //   script: 'service/gateway/server.js',
      //   instances: 'max',
      //   exec_mode: 'cluster',
      //   watch: false,
      //   env: {
      //     PORT: gateWayConfig.port, // API Gateway port
      //   },
      //   max_restarts: 10,
      //   min_uptime: 60000,
      //   restart_delay: 5000,
      //   error_file: './logs-PM2/gateway-err.log',
      //   out_file: './logs-PM2/gateway-out.log',
      //   log_date_format: 'YYYY-MM-DD HH:mm Z',
      // },

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
        autorestart: true,
        max_restarts: 10,
        min_uptime: 60000,
        restart_delay: 5000,
        error_file: './logs-PM2/auth-err.log',
        out_file: './logs-PM2/auth-out.log',
        log_date_format: 'YYYY-MM-DD HH:mm Z',
      },

      // Visitor
      {
        name: 'visitor',
        script: 'service/visitor/server.js',
        instances: 'max',
        exec_mode: 'cluster',
        watch: false,
        env: {
          PORT: visitorConfig.port, // API VisitorApp port
        },
        autorestart: true,
        max_restarts: 10,
        min_uptime: 60000,
        restart_delay: 5000,
        error_file: './logs-PM2/visitor-err.log',
        out_file: './logs-PM2/visitor-out.log',
        log_date_format: 'YYYY-MM-DD HH:mm Z',
      },
    ],
  };