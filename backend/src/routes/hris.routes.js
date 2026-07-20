// routes/hris.routes.js
const express = require('express');
const mssql = require('mssql');
const { db, getHRIS } = require('../config/db');

const authenticateToken = require('../middlewares/authenticateToken');
const ApiError = require('../utils/apiError');

const router = express.Router();

// Get departments
router.get('/departments', authenticateToken, async (req, res, next) => {
  try {
    const dbHRIS = await getHRIS();

    // 1. ดึงแผนกที่ยังมีพนักงานใช้งานอยู่จาก HRIS
    const hrisQuery = `
      SELECT
        LTRIM(RTRIM(DepartmentName_Thai)) AS department_eng
      FROM VIEW_EMPLOYEE_INFO
      WHERE DepartmentName_Thai IS NOT NULL
        AND LTRIM(RTRIM(DepartmentName_Thai)) != ''
        AND DepartmentName_Thai != 'บริษัท ปันสาร เอเชีย จำกัด'
        AND DepartmentName_Thai != 'Admin'
      GROUP BY LTRIM(RTRIM(DepartmentName_Thai))
      HAVING SUM(
        CASE
          WHEN Status != 'N' THEN 1
          ELSE 0
        END
      ) > 0
      ORDER BY department_eng;
    `;

    const hrisResults = await dbHRIS.request().query(hrisQuery);

    if (hrisResults.recordset.length === 0) {
      return next(new ApiError(404, 'Departments Not Found'));
    }

    // 2. ดึงข้อมูล Mapping ภาษาไทยจาก Database ระบบ
    const [deptMapRows] = await db.query(`
      SELECT
        dept_eng,
        dept_thai,
        site
      FROM DEPT_MAP
    `);

    // 3. สร้าง Map สำหรับจับคู่
    // ใช้ lowercase ป้องกันปัญหาตัวพิมพ์เล็ก-ใหญ่ไม่ตรงกัน
    const deptMap = new Map(
      deptMapRows
        .filter(row => row.dept_eng)
        .map(row => {
          const deptEng = row.dept_eng.trim();

          return [
            deptEng.toLowerCase(),
            {
              deptThai: row.dept_thai?.trim() || deptEng,
              site: row.site?.trim().toLowerCase() || null,
            },
          ];
        })
    );

    // 4. จับคู่ข้อมูล HRIS กับ DEPT_MAP
    const departments = hrisResults.recordset
      .map(row => {
        const deptEng = row.department_eng?.trim();

        if (!deptEng) {
          return null;
        }

        const mapping = deptMap.get(deptEng.toLowerCase());

        // จับคู่ได้และเป็น Office: ไม่ส่งไป Mobile
        if (mapping?.site === 'office') {
          return null;
        }

        // จับคู่ได้และเป็น Factory: ใช้ชื่อไทยจาก DEPT_MAP
        if (mapping?.site === 'factory') {
          return {
            value: deptEng,
            label: mapping.deptThai,
          };
        }

        // จับคู่ไม่ได้:
        // ใช้ชื่อจาก HRIS เป็นทั้งอังกฤษและชื่อแสดง
        return {
          value: deptEng,
          label: deptEng,
        };
      })
      .filter(department => department !== null)
      .sort((a, b) => a.label.localeCompare(b.value, 'en'));

    if (departments.length === 0) {
      return next(
        new ApiError(404, 'Available Departments Not Found')
      );
    }

    return res.status(200).json({
      message: 'Departments Found',
      data: departments,
    });
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