// routes/hris.routes.js
const express = require('express');
const mssql = require('mssql');
const { getHRIS } = require('../config/db');
const authenticateToken = require('../middlewares/authenticateToken');
const ApiError = require('../utils/apiError');

const router = express.Router();

// Get dept
router.get('/departments', authenticateToken, async (req, res, next) => {
  try {
    const dbHRIS = await getHRIS();
    const query = `
      SELECT DepartmentName_Thai
      FROM VIEW_EMPLOYEE_INFO
      WHERE DepartmentName_Thai IS NOT NULL
        AND DepartmentName_Thai != ''
        AND DepartmentName_Thai != 'บริษัท ปันสาร เอเชีย จำกัด'
        AND DepartmentName_Thai != 'Admin'
      GROUP BY DepartmentName_Thai
      HAVING SUM(CASE WHEN Status != 'N' THEN 1 ELSE 0 END) > 0
      ORDER BY DepartmentName_Thai;
    `;

    const results = await dbHRIS.request().query(query);

    if (results.recordset.length === 0) {
      return next(new ApiError(404, 'Departments Not Found'));
    }

    const departments = results.recordset.map(row => row.DepartmentName_Thai);
    res.status(200).json({ message: 'Departments Found', data: departments });
  } catch (err) {
    next(err);
  }
});


//Get Employee By dept
router.get('/emp-name', authenticateToken, async (req, res, next) => {
  try {
    const dbHRIS = await getHRIS();
    const { dept } = req.query
    if (!dept) {
      return res.status(400).json({ error: 'Department name (dept) is required' });
    }
    const query = `
      SELECT
          FirstName_Thai + ' ' + LastName_Thai AS FullName_Thai
        FROM VIEW_EMPLOYEE_INFO
        WHERE DepartmentName_Thai = @dept
          AND Status = 'Y';
      `;

    const request = dbHRIS.request();
    request.input('dept', mssql.VarChar, dept);
    const results = await request.query(query);

    if (results.recordset.length === 0) {
      return next(new ApiError(404, "Employee not found"));
    }

    const employees = results.recordset.map(row => row.FullName_Thai);
    res.status(200).json({ message: `Employee data for department: ${dept}.`, data: employees });
  } catch (err) {
    next(err);
  }
});


//Get  info employee
router.get('/emp_info', authenticateToken, async (req, res, next) => {
  try {
    const dbHRIS = await getHRIS();
    const { empId } = req.query
    if (!empId) {
      return res.status(400).json({ error: 'Employee ID (empId) is required' });
    }
    const query = `
      SELECT
        FirstName_Thai + ' ' + LastName_Thai AS FullName_Thai,
        DepartmentName_Thai
        FROM VIEW_EMPLOYEE_INFO
        WHERE PersonID = @empId;
      `;

    const request = dbHRIS.request();
    request.input('empId', mssql.VarChar, empId);
    const results = await request.query(query);

    const employee = results.recordset[0];
    res.status(200).json({ message: `Employee info`, data: employee });
  } catch (err) {
    next(err);
  }
});

module.exports = router;