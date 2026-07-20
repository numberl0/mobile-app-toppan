import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/approve/approve_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

import '../../entity/department.dart';
import '../search/search_controller.dart';

enum RequestType { visitor, employee, permission}

class ApproveController {
  ApproveModel _module = ApproveModel();

  CenterController _centerController = CenterController();

  UserEntity userEntity = UserEntity();

  // List document
  List<dynamic> list_Request = [];

  // List document
  List<dynamic> listV = [];
  List<dynamic> listE = [];
  List<dynamic> listLC = [];

  List<dynamic> filteredVisiorList = [];
  List<dynamic> filteredEmployeeList = [];
  List<dynamic> filteredPermissionList = [];

  List<Department> deptList = [];
  
  TextEditingController filterCompanyController = TextEditingController();
  TextEditingController filterEmployeeIdController = TextEditingController();
  TextEditingController filterNameController = TextEditingController();
  ValueNotifier<DateTime?> filteredDate = ValueNotifier(null);
  TextEditingController filteredCardNo = TextEditingController();

  final List<RequestType> typeOptions = RequestType.values;
  late RequestType? selectedType = RequestType.values.first;



  bool startAnimation = false;

  final LoadingDialog _loadingDialog = LoadingDialog();

  Map<int, String> eTypeObjectiveMapping = {
    3: 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกพื้นที่การผลิต',  // Production Transfer
    2: 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกโรงงาน',        // Factory Transfer
    1: 'ขออนุญาตออกนอกโรงงาน',                        // Off-site Permit
  };

  Map<String, List<SignatureKeyField>> signatureSection = {
    'VISITOR': [
      SignatureKeyField(
          label: 'ผู้อนุมัติ',
          signKey: 'appr_sign',
          filename: 'approved',
          statusKey: 'appr_status',
          datetimeKey: 'appr_at',
          byKey: "appr_by"),
      SignatureKeyField(
          label: 'ผู้ตรวจสอบสื่อ',
          signKey: 'media_sign',
          filename: 'media',
          statusKey: 'media_status',
          datetimeKey: 'media_at',
          byKey: "media_by"),
      SignatureKeyField(
          label: 'รปภ. ป้อมหน้า',
          signKey: 'guard_sign',
          filename: 'security',
          statusKey: 'guard_status',
          datetimeKey: 'guard_at',
          byKey: "guard_by"),
      SignatureKeyField(
          label: 'รปภ. อาคาร',
          signKey: 'prod_sign',
          filename: 'production',
          statusKey: 'prod_status',
          datetimeKey: 'prod_at',
          byKey: "prod_by"),
    ],
    'EMPLOYEE': [
      SignatureKeyField(
          label: 'พนักงาน',
          signKey: 'emp_sign',
          filename: 'employee',
          statusKey: 'emp_status',
          datetimeKey: 'emp_at',
          byKey: "emp_by"),
      SignatureKeyField(
          label: 'ผู้อนุมัติ',
          signKey: 'appr_sign',
          filename: 'approved',
          statusKey: 'appr_status',
          datetimeKey: 'appr_at',
          byKey: "appr_by"),
      SignatureKeyField(
          label: 'ผู้ตรวจสอบสื่อ',
          signKey: 'media_sign',
          filename: 'media',
          statusKey: 'media_status',
          datetimeKey: 'media_at',
          byKey: "media_by"),
      SignatureKeyField(
          label: 'รปภ.',
          signKey: 'guard_sign',
          filename: 'security',
          statusKey: 'guard_status',
          datetimeKey: 'guard_at',
          byKey: "guard_by"),
      // SignatureKeyField(label: 'รปภ.', key: 'guard_sign'),
    ],
    'PERMISSION': [
      SignatureKeyField(
          label: 'ผู้ยืมบัตร', 
          signKey: 'sign_emp', 
          filename: 'employee',
          statusKey: 'sign_emp_status',
          datetimeKey: 'sign_emp_at',
          byKey: "sign_emp_by"),
      SignatureKeyField(
          label: 'ผู้อนุมัติ',
          // label: 'ผู้อนุมัติ (หัวหน้ากะ/ผู้ช่วย/ผู้จัดการ)',
          signKey: 'sign_respon',
          filename: 'approved',
          statusKey: 'sign_respon_status',
          datetimeKey: 'sign_respon_at',
          byKey: "sign_respon_by"),
      SignatureKeyField(
          label: 'รปภ. ส่งมอบบัตร',
          signKey: 'sign_guardI',
          filename: 'security_In',
          statusKey: 'sign_guardI_status',
          datetimeKey: 'sign_guardI_at',
          byKey: "sign_guardI_by"),
      SignatureKeyField(
          label: 'รปภ. รับคืนบัตร',
          signKey: 'sign_guardO',
          filename: 'security_Out',
          statusKey: 'sign_guardO_status',
          datetimeKey: 'sign_guardO_at',
          byKey: "sign_guardO_status"),
    ],
  };

  Future<void> preparePage(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      List<String> roles =  await userEntity.getUserPerfer(userEntity.roles_visitorService);

      List<String> building_card = [];
      building_card.add('O');
      for (String role in roles) {
        if (role == 'Administrator') {
          building_card = ['O','Y','N'];
          break;
        }
        switch (role) {
          case 'Manager':
          case 'SecurityManager':
            if (!building_card.contains('N')) building_card.add('N');
            break;
          case 'CardManager':
            if (!building_card.contains('Y')) building_card.add('Y');
            break;
        }
      }

      await clearSearch();
      String username = await userEntity.getUserPerfer(userEntity.username);
      var result = await _module.getRequestForApproved(username,building_card);
      listV = result['visitor'] ?? [];
      listE = result['employee'] ?? [];
      listLC = result['permission'] ?? [];

      deptList = await _module.getDepartments();

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }
  

  Future<void> clearSearch() async {
    try{
      filterCompanyController.clear();
      filterEmployeeIdController.clear();
      filterNameController.clear();
      filteredCardNo.clear();
      filteredDate = ValueNotifier(null);
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

  Future<void> filterRequestList() async {
    try {
      final searchName = filterNameController.text.toLowerCase();
      final searchCompany = filterCompanyController.text.toLowerCase();
      final searchEmpId = filterEmployeeIdController.text.toLowerCase();
      final searchCard = filteredCardNo.text.toLowerCase();
      final searchDate = filteredDate.value;

      switch (selectedType) {
        case RequestType.visitor:
          filteredVisiorList = listV.where((entry) {
            final company = entry['company'].toString().toLowerCase();
            final List<dynamic>? personList = entry['people'];
            final matchesCompany = searchCompany.isEmpty || company.contains(searchCompany);
            final matchesPerson = searchName.isEmpty ||
                (personList != null &&
                    personList.any((person) {
                      final String fullName =
                          person['FullName']?.toString().toLowerCase() ?? '';
                      return fullName.contains(searchName);
                    }));
            return matchesCompany && matchesPerson;
          }).toList();
          break;
        case RequestType.employee:
          filteredEmployeeList = listE.where((entry) {
            final List<dynamic>? personList = entry['people'];
            // Employee Id
            final matchesEmployeeId = searchEmpId.isEmpty ||
                (personList != null &&
                    personList.any((person) {
                      final String employeeId =
                          person['EmployeeId']?.toString().toLowerCase() ?? '';
                      return employeeId.contains(searchEmpId);
                    }));
            // Name
            final matchesPerson = searchName.isEmpty ||
                (personList != null &&
                    personList.any((person) {
                      final String fullName =
                          person['FullName']?.toString().toLowerCase() ?? '';
                      return fullName.contains(searchName);
                    }));
            return matchesEmployeeId && matchesPerson;
          }).toList();
          break;
        case RequestType.permission:
           filteredPermissionList = listLC.where((entry) {
            final fullName = entry['emp_name'].toString().toLowerCase();
            final cardNo = entry['brw_card'].toString().toLowerCase();
            DateTime? entryDate;
            final dateStr = entry['doc_date']?.toString();
            if (dateStr != null && dateStr.isNotEmpty) {
              entryDate = DateTime.tryParse(dateStr)?.toLocal();
            }

            final matchesName =
                searchName.isEmpty || fullName.contains(searchName);
            final matchesCard =
                searchCard.isEmpty || cardNo.contains(searchCard);
            final matchesDate = searchDate == null ||
                (entryDate != null &&
                    entryDate.year == filteredDate.value!.year &&
                    entryDate.month == filteredDate.value!.month &&
                    entryDate.day == filteredDate.value!.day);
            return matchesName && matchesCard && matchesDate;
          }).toList();
          break;
        default:

     }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

  Future<Map<String, dynamic>> approvedDocument(Map<String,dynamic> entry) async {
    try {
      final String type = entry['request_type'].toString().toUpperCase();
      final String username = await userEntity.getUserPerfer(userEntity.username);
      final String firstName = await _module.getFirstnameApprover(username);
      final String now = AppDateTime.now().toString();

      const typeConfigs = {
        'VISITOR': ['datetime_in', 'appr_status', 'appr_at', 'appr_by'],
        'EMPLOYEE': ['datetime_out', 'appr_status', 'appr_at', 'appr_by'],
        'PERMISSION': ['doc_date', 'sign_respon_status', 'sign_respon_at', 'sign_respon_by'],
      };

      final config = typeConfigs[type];
      if (config == null) return {'success': false, 'message': 'Unknown docType'};

      final String dateStr = entry[config[0]] ?? "";
      final Map<String, dynamic> signInfo = {
        config[1]: 1,
        config[2]: now,
        config[3]: firstName,
      };

      var status = await _module.approvedDocument(
        entry['tno_pass'], 
        entry['request_type'], 
        dateStr, 
        signInfo, 
        username
      );
      if(status['success']) {
        await _centerController.insertActvityLog('Approved document: ${entry['tno_pass']}');
      }
      return status;
      } catch (err, stack) {
        AppLogger.error('Error: $err\n$stack');
        await _centerController.logError(err.toString(), stack.toString());
        return {'success': false, 'message': 'เกิดข้อผิดพลาดโปรดลองใหม่ภายหลัง'};
      }
  }

  Future<Map<String, dynamic>> approvedAllDocumentByList() async {
    try {
      final String username = await userEntity.getUserPerfer(userEntity.username);
      final String firstName = await _module.getFirstnameApprover(username);
      final String now = AppDateTime.now().toString();

      final configs = {
        RequestType.visitor: {
          'list': filteredVisiorList,
          'date_field': 'datetime_in',
          'sign': {'appr_status': 1, 'appr_at': now, 'appr_by': firstName}
        },
        RequestType.employee: {
          'list': filteredEmployeeList,
          'date_field': 'datetime_out',
          'sign': {'appr_status': 1, 'appr_at': now, 'appr_by': firstName}
        },
        RequestType.permission: {
          'list': filteredPermissionList,
          'date_field': 'doc_date',
          'sign': {'sign_respon_status': 1, 'sign_respon_at': now, 'sign_respon_by': firstName}
        },
      };

      final cfg = configs[selectedType];
      final List filteredList = (cfg?['list'] as List?) ?? [];

      if (filteredList.isEmpty) {
        return {'success': false, 'message': 'ไม่พบข้อมูลเอกสารสำหรับการอนุมัติ'};
      }

      final List<Map<String, dynamic>> tnoListMap = filteredList.map((item) {
        final mapItem = item as Map<String, dynamic>;
        final dateStr = mapItem[cfg!['date_field']] ?? "";

        final parsedDate = DateTime.parse(dateStr);
        final pathDate = "${parsedDate.year}/${parsedDate.month.toString().padLeft(2, '0')}";
        final tno = mapItem['tno_pass'].toString();
        final type = mapItem['request_type'].toString();

        return {
          'tno_pass': tno,
          'type': type,
          'path': '$type/$pathDate/$tno',
        };
      }).toList();

      final status = await _module.approvedList(
        selectedType!.name.toUpperCase(), 
        tnoListMap, 
        cfg!['sign'] as Map<String, dynamic>,
        username
      );

      if (status['success']) {
        final tnoJoin = tnoListMap.map((e) => e['tno_pass']).join(", ");
        await _centerController.insertActvityLog('Approved documents: [$tnoJoin]');
      }
        
      return status;

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      return {'success': false, 'message': 'เกิดข้อผิดพลาดโปรดลองใหม่ภายหลัง'};
    }
  }

  Future<bool> isAdmin() async {
    try {
      List<String> roles = await userEntity.getUserPerfer(userEntity.roles_visitorService);
      return roles.contains('Administrator');
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      return false;
    }
  }

}