const express = require('express');
const router = express.Router();
const { db } = require("../config/db");
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const { transformFilenameToPath } = require('../utils/fileUntils');


router.get('/preview', async (req, res, next) => {
    try {
        let { docType, sDate, eDate } = req.query;
        if ( !docType || !sDate || !eDate) {
            return next(new ApiError(400, 'Missing parameter'));
        }

        let results = [];

        switch (docType) {
            case 'visitor':
                [results] = await db.query(
                    `SELECT pr.*, pf.visitorType, pf.people, pf.item_in, pf.item_out
                    FROM PASS_REQ_V pr
                    LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
                    WHERE DATE(pr.date_in) BETWEEN ? AND ?
                    ORDER BY pr.date_in ASC`,
                    [sDate, eDate]
                    );
                break;
            case 'employee':
                [results] = await db.query(
                    `SELECT pr.*, pf.visitorType, pf.people, pf.item_in, pf.item_out
                    FROM PASS_REQ_E pr
                    LEFT JOIN PASS_FORM pf ON pr.tno_pass = pf.tno_pass
                    WHERE DATE(pr.date_out) BETWEEN ? AND ?
                    ORDER BY pr.date_out ASC`,
                    [sDate, eDate]
                    );
                break;
            case 'permission':
                [results] = await db.query(
                    `SELECT * FROM PASS_REQ_P
                    WHERE DATE(doc_date) BETWEEN ? AND ?
                    ORDER BY doc_date ASC`,
                    [sDate, eDate]
                    );
                break;
            case 'temporary':
                [results] = await db.query(
                    `SELECT * FROM PASS_REQ_T
                    WHERE DATE(brw_at) BETWEEN ? AND ?
                    ORDER BY brw_at ASC`,
                    [sDate, eDate]
                    );
                break;
            default:
                return next(new ApiError(400, 'Unknown docType'));
        }
    

        if (!results || results.length === 0) {
            return res.status(404).json({
                success: false,
                message: `No ${docType} data found for the given date range`,
            });
        }

        const doc = new PDFDocument({
            size: 'A4',
            layout: 'landscape',
            margin: 30,
        });
        doc.lineWidth(0.5);

        // ====== สร้าง PDF ======
        let buffers = [];
        doc.on('data', (chunk) => buffers.push(chunk));
        doc.on('end', () => {
            const pdfData = Buffer.concat(buffers);
            const base64String = pdfData.toString('base64');
            
            res.status(200).json({
                success: true,
                pdfBase64: base64String 
            });
        });

        const fontPath = path.join(__dirname, '../fonts/angsau.ttf')
        doc.registerFont('ang', fontPath);
        doc.font('ang');

        switch (docType) {
            case 'visitor':
                await generateVisitorLogBook(doc, results);
                break;
            case 'employee':
                await generateEmployeeLogBook(doc, results);
                break;
            case 'permission':
                await generatePermissionLogBook(doc, results);
                break;
            case 'temporary':
                await generateTemporaryLogBook(doc, results);
                break;
            default:
            return next(new ApiError(400, 'Unknown docType'));
        }

        doc.end();
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


async function generateVisitorLogBook(doc, result) {
    try{
    let pageNo = 1;
    const rowHeight = 25;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;
        const bottomLimit = doc.page.height - doc.page.margins.bottom;

        let x = mLeft;
        
        let rowY = drawVisitorHeader(doc);
        drawPageNumberTopRight(doc, pageNo);

        const transformPath = transformFilenameToPath(result);
        let listDataV = [...transformPath];

        listDataV.forEach(item => {
            item.people.forEach(person => {
                const cells= [
                    { label: formatThaiDate(item.date_in), width: 50 },
                    { label: item.sequence_no, width: 40 },
                    { label: person.TitleName + person.FullName, width: 130, align: 'left' },
                    { label: person.Signature, width: 50 },
                    { label: item.company, width: 100, ellipsis: true, lineGap: -1.5, align: 'left' },
                    { label: item.objective, width: 100, ellipsis: true, lineGap: -1.5, align: 'left' },
                    { label: person.Card_Id, width: 45 },
                    { label: item.time_in.slice(0,5), width: 35 },
                    { label: item.time_out.slice(0,5), width: 35 },
                    { label: item.appr_by, width: 50 },
                    { label: item.appr_sign, width: 50 },
                    { label: item.guard_by, width: 50 },
                    { label: '', width: 45 },
                ];

                let textHeight = Math.max(
                    rowHeight,
                    ...cells.map(cell => {
                        if(
                            typeof cell.label === 'string' &&
                            (cell.label.endsWith('.png') || cell.label.endsWith('.jpg'))
                        ) {
                            return rowHeight;
                        }

                        return doc.heightOfString(String(cell.label || ''), {
                            width: cell.width,
                            lineGap: -1,
                        })
                    })
                );
                if (rowY + textHeight > bottomLimit) {
                    doc.addPage();
                    pageNo++;
                    rowY = drawVisitorHeader(doc);
                    drawPageNumberTopRight(doc, pageNo);
                }
                doc.fontSize(14);

                x = mLeft;
                valueY = rowY + (rowHeight - doc.currentLineHeight()) / 2;

                cells.forEach(cell => {
                    drawCell(doc, cell, x, rowY, textHeight, valueY);
                    x += cell.width;
                });
                doc.moveTo(pageWidth + mLeft, rowY).lineTo(pageWidth + mLeft, rowY + textHeight).stroke();
                doc.moveTo(mLeft, rowY + textHeight).lineTo( pageWidth + mLeft, rowY + textHeight).stroke();
                rowY += textHeight;
            });
        });

        } catch (err) {
        console.log(err);
    }
}

function drawCell(doc, cell, x, rowY, rowHeight, valueY) {
    const width = cell.width || 50;
    const label = cell.label || '';
    const paddingLeft = cell.paddingLeft ?? (
        cell.align === 'left' ? 3 : 0
    );
    const contentX = x + paddingLeft;
    const contentWidth = width - (paddingLeft*2);


    // === IMAGE ===
    if(typeof label === 'string' && (label.endsWith('.png') || label.endsWith('.jpg'))) {
        const imagePath = path.join(__dirname, '..', 'docImage', label);
        if (fs.existsSync(imagePath)) {
            doc.image(imagePath, contentX, rowY, { 
                width: contentWidth,
                height: 25,
                align: 'center'
            });
        }

    } 
    // === TEXT ===
    else {
        doc.fontSize(cell.fontSize || 12).text(String(label), contentX, valueY, {
            // width: contentWidth, 
            width: contentWidth, 
            align: cell.align || 'center', 
            ellipsis: cell.ellipsis || false, 
            // lineGap: cell.lineGap ?? -5,
            lineGap: -3,
        });
    }
    // === VERTICAL BORDERS ===
    doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
    // doc.moveTo(x + width, rowY).lineTo(x + width, rowY + rowHeight).stroke();
}

function drawPageNumberTopRight(doc, pageNo) {
    const top = doc.page.margins.top - 15;
    const right = doc.page.width - doc.page.margins.right;

    doc.fontSize(10)
       .text(`Page ${pageNo}`, right - 60, top, {
           width: 60,
           align: 'right'
       });
}

// ================== Header ==================
function drawVisitorHeader(doc) {
    const rowHeight = 25;
    const mLeft = doc.page.margins.left;
    const mRight = doc.page.margins.right;
    const pageWidth = doc.page.width - mLeft - mRight;

    let rowY = doc.y;

    // ====== Title ======
    doc.rect(mLeft, rowY, pageWidth, rowHeight).stroke();
    const titleTextY = rowY + (rowHeight - doc.currentLineHeight()) / 4;
    doc.fontSize(16).text('Visitor Logbook', mLeft, titleTextY, {
        width: pageWidth,
        align: 'center',
    });

    rowY += rowHeight;
    let x = mLeft;
    doc.fontSize(14);

    // ====== Header row 1 ======
    const header1 = [
        { text: 'Date', w: 50 },
        { text: 'เลขที่', w: 40 },
        { text: 'Visitor ข้อมูลผู้มาติดต่อ', w: 380 },
        { text: 'เลขบัตร', w: 45 },
        { text: 'ลงเวลา', w: 70 },
        { text: 'ผู้รับการติดต่อ', w: 100 },
    ];
    const valueY1 = rowY + (rowHeight - doc.currentLineHeight()) / 2;
    doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
    header1.forEach(h => {
        x += h.w;
        doc.text(h.text, x - h.w, valueY1, { width: h.w, align: 'center' });
        doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
    });
    doc.moveTo(mLeft, rowY + rowHeight).lineTo(x, rowY + rowHeight).stroke();

    // ====== Header row 2 ======
    rowY += rowHeight;
    x = mLeft;
    const valueY2 = rowY + (rowHeight - doc.currentLineHeight()) / 2;

    const headers = [
        { text: 'ว/ด/ป', w: 50 },
        { text: 'ใบผ่าน', w: 40 },
        { text: 'ชื่อ - นามสกุล', w: 130 },
        { text: 'ลายเซ็นต์', w: 50 },
        { text: 'บริษัท', w: 100 },
        { text: 'วัตถุประสงค์', w: 100 },
        { text: 'Visitor', w: 45 },
        { text: 'เข้า', w: 35 },
        { text: 'ออก', w: 35 },
        { text: 'ชื่อ', w: 50 },
        { text: 'ลายเซ็นต์', w: 50 },
    ];

    doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
    headers.forEach(h => {
        x += h.w;
        doc.text(h.text, x - h.w, valueY2, { width: h.w, align: 'center' });
        doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
    });

    x += 50;
    doc.text('รปภ.', x - 50, valueY2 - (rowHeight/2), { width: 50, align: 'center' });
    doc.moveTo(x, rowY - rowHeight).lineTo(x, rowY + rowHeight).stroke();

    x += 45;
    doc.fontSize(13).text('หมายเหตุ', x - 40, valueY2 - (rowHeight/2), { width:37, align: 'center' });

    doc.moveTo(pageWidth + mLeft, rowY - rowHeight).lineTo(pageWidth + mLeft, rowY + rowHeight).stroke();

    rowY += rowHeight
    doc.moveTo(mLeft, rowY).lineTo( pageWidth + mLeft, rowY).stroke();

    return rowY;
}

function drawEmployeeHeader(doc) {
    const rowHeight = 30;
        let rowY = doc.y;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;

        // ====== Title ======
        doc.rect(mLeft, rowY, pageWidth, rowHeight).stroke();
        const titleTextY = rowY + (rowHeight - doc.currentLineHeight()) / 4;
        doc.fontSize(16).text('Request form for employee logbook', mLeft, titleTextY, {
            width: pageWidth,
            align: 'center',
        });

        rowY += rowHeight;
        let x = mLeft;

        doc.fontSize(14);

    // ====== Header row 1 ======
    const header1 = [
        { text: 'เลขที่ใบผ่าน', w: 60 },
        { text: 'วันที่', w: 55 },
        { text: 'เวลาเบิก', w: 50 },
        { text: 'ชื่อ-นาสกุล', w: 190 },
        { text: 'แผนก', w: 130 },
        { text: 'วัตถุประสงค์', w: 110 },
        { text: 'เวลาคืน', w: 50 },
        { text: 'ลายเซ็น รปภ.', w: 73 },
        { text: 'หมายเหตุ', w: 63 },
    ];
    const valueY1 = rowY + (rowHeight - doc.currentLineHeight()) / 2;
    header1.forEach(h => {
        doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
        x += h.w;
        doc.text(h.text, x - h.w, valueY1, { width: h.w, align: 'center' });
    });
    doc.moveTo(pageWidth + mLeft, rowY - rowHeight).lineTo(pageWidth + mLeft, rowY + rowHeight).stroke();
    rowY += rowHeight
    doc.moveTo(mLeft, rowY).lineTo( pageWidth + mLeft, rowY).stroke();
    return rowY;
}

function drawPermissionHeader(doc) {
    const rowHeight = 40;
        let rowY = doc.y;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;

        // ====== Title ======
        doc.rect(mLeft, rowY, pageWidth, 25).stroke();
        const titleTextY = rowY + (25 - doc.currentLineHeight()) / 4;
        doc.fontSize(16).text('Employee Entry Permission logbook', mLeft, titleTextY, {
            width: pageWidth,
            align: 'center',
        });
        rowY += 25;
        let x = mLeft;

        doc.fontSize(14);

    // ====== Header ======
    const header1 = [
        { text: 'ว/ด/ป ที่ยืมบัตร', w: 55 , dh: true },
        { text: 'รหัสพนักงาน', w: 60 },
        { text: 'ชื่อ-นามสกุล ผู้ยืมบัตร', w: 160 },
        { text: 'แผนก', w: 120 },
        { text: 'บัตร PMNT NO.', w: 70 },
        { text: 'ลายมือชื่อ ผู้ยืมบัตร', w: 65 , dh: true},
        { text: 'ลายมือชื่อ รปภ.ผู้ให้ยืม', w: 65 , dh: true},
        { text: 'ลายมือชื่อ ผู้คืนบัตร', w: 65 , dh: true},
        { text: 'ลายมือชื่อ รปภ.ผู้รับคืน', w: 65 , dh: true},
        { text: 'หมายเหตุ', w: 55 },
    ];
    const valueY = rowY + (rowHeight - doc.currentLineHeight()) / 2;
    const valueYx2 = rowY + (rowHeight - doc.currentLineHeight()) / 4 - 1;
    header1.forEach(h => {
        doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
        x += h.w;
        if(h.dh === true) {
            doc.text(h.text, x - h.w, valueYx2, { width: h.w, align: 'center' });
        }else{
            doc.text(h.text, x - h.w, valueY, { width: h.w, align: 'center' });
        }
    });
    doc.moveTo(pageWidth + mLeft, rowY ).lineTo(pageWidth + mLeft, rowY + rowHeight).stroke();
    rowY += rowHeight
    doc.moveTo(mLeft, rowY).lineTo( pageWidth + mLeft, rowY).stroke();
    return rowY;
}


function formatThaiDate(dateStr) {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return '';
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0'); // เดือน 0-11
    const year = date.getFullYear() + 543; // เปลี่ยนเป็น พ.ศ.
    return `${day}/${month}/${year}`;
}

async function generateEmployeeLogBook(doc, data) {
    try {
        let pageNo = 1;
        let rowHeight = 30;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;
        const bottomLimit = doc.page.height - doc.page.margins.bottom;

        let rowY = drawEmployeeHeader(doc);
        drawPageNumberTopRight(doc, pageNo);

        const transformPath = transformFilenameToPath(data);
        let listDataE = [...transformPath];

        listDataE.forEach(item => {
            item.people.forEach(person => {
                const cells= [
                    { label: item.sequence_no, width: 60 },
                    { label: formatThaiDate(item.date_out), width: 55 },
                    { label: item.time_out.slice(0,5), width: 50 },
                    { label: person.TitleName + person.FullName, width: 190, align: 'left' },
                    { label: person.Department, width: 130},
                    { label: item.objective, width: 110, ellipsis: true, lineGap: -1.5, align: 'left' },
                    { label: item.time_in.slice(0,5), width: 50 },
                    { label: item.guard_by, width: 73 },
                    { label: '', width: 70 },
                ];

                let textHeight = Math.max(
                    rowHeight,
                    ...cells.map(cell => {
                        if(
                            typeof cell.label === 'string' &&
                            (cell.label.endsWith('.png') || cell.label.endsWith('.jpg'))
                        ) {
                            return rowHeight;
                        }

                        return doc.heightOfString(String(cell.label || ''), {
                            width: cell.width - 2,
                            lineGap: -1,
                        })
                    })
                );

                if (rowY + textHeight > bottomLimit) {
                    doc.addPage();
                    pageNo++;
                    rowY = drawEmployeeHeader(doc);
                    drawPageNumberTopRight(doc, pageNo);
                }
                doc.fontSize(14);

                x = mLeft;
                valueY = rowY + (rowHeight - doc.currentLineHeight()) / 2;

                cells.forEach(cell => {
                    drawCell(doc, cell, x, rowY, textHeight, valueY);
                    x += cell.width;
                });
                doc.moveTo(pageWidth + mLeft, rowY).lineTo(pageWidth + mLeft, rowY + textHeight).stroke();
                doc.moveTo(mLeft, rowY + textHeight).lineTo( pageWidth + mLeft, rowY + textHeight).stroke();
                rowY += textHeight;
            });
        });

    } catch (err) {
        console.log(err);
    }
}

async function generatePermissionLogBook(doc, data) {
     try {
        let pageNo = 1;
        let rowHeight = 25;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;
        const bottomLimit = doc.page.height - doc.page.margins.bottom;

        let rowY = drawPermissionHeader(doc);
        drawPageNumberTopRight(doc, pageNo);
        let x = mLeft;
        doc.fontSize(14);

        const transformPath = transformFilenameToPath(data);
        let listDataP = [...transformPath];

        listDataP.forEach(item => {
                const cells= [
                    { label: formatThaiDate(item.doc_date), width: 55 },
                    { label: item.emp_id, width: 60 },
                    { label: item.emp_name, width: 160, align: 'left' },
                    { label: item.emp_dept, width: 120},
                    { label: item.brw_card, width: 70},
                    { label: item.sign_emp, width: 65 },
                    { label: item.sign_respon, width: 65 },
                    { label: item.sign_guardI, width: 65 },
                    { label: item.sign_guardO, width: 65 },
                    { label: '', width: 53 },
                ];

                let textHeight = Math.max(
                    rowHeight,
                    ...cells.map(cell => {
                        if(
                            typeof cell.label === 'string' &&
                            (cell.label.endsWith('.png') || cell.label.endsWith('.jpg'))
                        ) {
                            return rowHeight;
                        }

                        return doc.heightOfString(String(cell.label || ''), {
                            width: cell.width,
                        })
                    })
                );

                if (rowY + textHeight > bottomLimit) {
                    doc.addPage();
                    pageNo++;
                    rowY = drawEmployeeHeader(doc);
                    drawPageNumberTopRight(doc, pageNo);
                }
                doc.fontSize(14);

                x = mLeft;
                valueY = rowY + (rowHeight - doc.currentLineHeight()) / 2;
                cells.forEach(cell => {
                    drawCell(doc, cell, x, rowY, textHeight, valueY);
                    x += cell.width;
                    
                });
                doc.moveTo(pageWidth + mLeft, rowY).lineTo(pageWidth + mLeft, rowY + textHeight).stroke();
                doc.moveTo(mLeft, rowY + textHeight).lineTo( pageWidth + mLeft, rowY + textHeight).stroke();
                rowY += textHeight;
        });
        } catch (err) {
            console.log(err);
    }
}

// ======================== Temporary ==============================
function drawTemporaryHeader(doc) {
    const rowHeight = 40;
        let rowY = doc.y;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;

        // ====== Title ======
        doc.rect(mLeft, rowY, pageWidth, 25).stroke();
        const titleTextY = rowY + (25 - doc.currentLineHeight()) / 4;
        doc.fontSize(16).text('TEMPORARY STAFF B, C / Nanny / Nurse', mLeft, titleTextY, {
            width: pageWidth,
            align: 'center',
        });

        rowY += 25;
        let x = mLeft;

        doc.fontSize(14);

    // ====== Header row 1 ======
    const header1 = [
        { text: 'ชื่อ-นามสกุล (ตัวบรรจง)', w: 210 },
        { text: 'เลขบัตรที่ได้รับ', w: 70 },
        { text: 'วันที่ยืม', w: 60 },
        { text: '  ลายมือชื่อ   ผู้ยืมบัตร', w: 80, dh: true  },
        { text: 'ลายมือชื่อ รปภ.ที่ให้ยืม', w: 80, dh: true  },
        { text: 'วันที่คืน', w: 60 },
        { text: 'ลายมือชื่อ รปภ.ผู้คืนบัตร', w: 80, dh: true  },
        { text: 'ลายมือชื่อ รปภ.ผู้รับคืน', w: 80, dh: true  },
        { text: 'หมายเหตุ', w: 62 },
    ];
    const valueY = rowY + (rowHeight - doc.currentLineHeight()) / 2;
    const valueYx2 = rowY + (rowHeight - doc.currentLineHeight()) / 4 - 1;
    header1.forEach(h => {
        doc.moveTo(x, rowY).lineTo(x, rowY + rowHeight).stroke();
        x += h.w;
         if(h.dh === true) {
            doc.text(h.text, x - h.w, valueYx2, { width: h.w, align: 'center' });
        }else{
            doc.text(h.text, x - h.w, valueY, { width: h.w, align: 'center' });
        }
    });
    doc.moveTo(pageWidth + mLeft, rowY).lineTo(pageWidth + mLeft, rowY + rowHeight).stroke();
    rowY += rowHeight
    doc.moveTo(mLeft, rowY).lineTo( pageWidth + mLeft, rowY).stroke();
    return rowY;
}

async function generateTemporaryLogBook(doc, data) {
    try {
        let pageNo = 1;
        let rowHeight = 30;
        const mLeft = doc.page.margins.left;
        const mRight = doc.page.margins.right;
        const pageWidth = doc.page.width - mLeft - mRight;
        const bottomLimit = doc.page.height - doc.page.margins.bottom;

        let rowY = drawTemporaryHeader(doc);
        drawPageNumberTopRight(doc, pageNo);
        let x = mLeft;
        doc.fontSize(14);

        const transformPath = transformFilenameToPath(data);
        let listDataT = [...transformPath];

           listDataT.forEach(item => {
                const cells= [
                    { label: item.name, width: 210, align: 'left' },
                    { label: item.card_no, width: 70 },
                    { label: formatThaiDate(item.brw_at), width: 60 },
                    { label: item.brw_sign_brw, width: 80 },
                    { label: item.brw_sign_guard, width: 80 },
                    { label: formatThaiDate(item.ret_at), width: 60 },
                    { label: item.ret_sign_brw, width: 80 },
                    { label: item.ret_sign_guard, width: 80 },
                    { label: item.remark, width: 62 },
                ];

                let textHeight = Math.max(
                    rowHeight,
                    ...cells.map(cell => {
                        if(
                            typeof cell.label === 'string' &&
                            (cell.label.endsWith('.png') || cell.label.endsWith('.jpg'))
                        ) {
                            return rowHeight;
                        }

                        return doc.heightOfString(String(cell.label || ''), {
                            width: cell.width,
                        })
                    })
                );

                if (rowY + textHeight > bottomLimit) {
                    doc.addPage();
                    pageNo++;
                    rowY = drawEmployeeHeader(doc);
                    drawPageNumberTopRight(doc, pageNo);
                }
                doc.fontSize(14);

                x = mLeft;
                valueY = rowY + (rowHeight - doc.currentLineHeight()) / 2;
                cells.forEach(cell => {
                    drawCell(doc, cell, x, rowY, textHeight, valueY);
                    x += cell.width;
                    
                });
                doc.moveTo(pageWidth + mLeft, rowY).lineTo(pageWidth + mLeft, rowY + textHeight).stroke();
                doc.moveTo(mLeft, rowY + textHeight).lineTo( pageWidth + mLeft, rowY + textHeight).stroke();
                rowY += textHeight;
        });
     
        } catch (err) {
            console.log(err);
    }
}

module.exports = router;