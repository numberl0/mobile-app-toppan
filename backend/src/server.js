//server.js
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const { visitorConfig } = require('./config/config');

const hrisRoutes = require('./routes/hris.routes');
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const logRoutes = require('./routes/log.routes');
const docRoutes = require('./routes/document.routes');
const uploadRoutes = require('./routes/upload.routes');
const cardRoutes = require('./routes/card.routes');
const otherRoutes = require('./routes/other.routes');
const apprRoutes = require('./routes/approved.routes');
const pdfRoutes = require('./routes/pdf.routes');
require('./cron/notify.cron');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

// middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

// routes
app.use('/hris', hrisRoutes);
app.use('/auth', authRoutes);
app.use('/user', userRoutes);
app.use('/log', logRoutes);
app.use('/document', docRoutes);
app.use('/upload', uploadRoutes);
app.use('/card', cardRoutes);
app.use('/other', otherRoutes);
app.use('/approval', apprRoutes);
app.use('/pdf', pdfRoutes);

// error handler
app.use(errorHandler);

// start server
const PORT = visitorConfig.port;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});