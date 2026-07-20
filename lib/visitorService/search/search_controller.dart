
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/visitorService/search/search_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

import '../../entity/department.dart';



enum RequestType { visitor, employee, permission, temporary }
enum CardReason {lost, forgotten, damaged, other}
extension CardReasonExtension on CardReason {
  String get shortCode {
    switch (this) {
      case CardReason.lost:
        return 'L';
      case CardReason.forgotten:
        return 'F';
      case CardReason.damaged:
        return 'D';
      case CardReason.other:
        return 'O';
    }
  }
}

class SearchFormController {
  SearchModule _module = SearchModule();

  CenterController _centerController = CenterController();

  List<dynamic> listV = [];
  List<dynamic> listE = [];
  List<dynamic> listLC = [];
  List<dynamic> listT = [];
 
  List<dynamic> filteredVisiorList = [];
  List<dynamic> filteredEmployeeList = [];
  List<dynamic> filteredPermissionList = [];
  List<dynamic> filteredTemporaryList = [];

  List<Department> deptList = [];
  
  TextEditingController filterCompanyController = TextEditingController();
  TextEditingController filterEmployeeIdController = TextEditingController();
  TextEditingController filterNameController = TextEditingController();
  ValueNotifier<DateTime?> filteredDate = ValueNotifier(null);
  TextEditingController filteredCardNo = TextEditingController();

  final List<RequestType> typeOptions = RequestType.values;
  late RequestType? selectedType = RequestType.values.first;


  TextEditingController companyController = TextEditingController();
  TextEditingController empIdController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  bool startAnimation = false;

  final LoadingDialog _loadingDialog = LoadingDialog();

  //Temporary
  GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey<SfSignaturePadState>();
  TextEditingController remarkController = TextEditingController();

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
          byKey: "sign_guardO_by"),
    ],
    'TEMPORARY': [
      SignatureKeyField(
          label: 'ผู้ยืมบัตร',
          signKey: 'brw_sign_brw',
          filename: 'borrower_in'),
      SignatureKeyField(
          label: 'รปภ.ที่ให้ยืม',
          signKey: 'brw_sign_guard',
          filename: 'guard_in'),
      SignatureKeyField(
          label: 'ผู้คืนบัตร',
          signKey: 'ret_sign_brw',
          filename: 'borrower_out'),
      SignatureKeyField(
          label: 'รปภ.ที่รับคืน',
          signKey: 'ret_sign_guard',
          filename: 'guard_out'),
    ],
  };

  TextEditingController signatureByController = TextEditingController();

  Future<void> preparePage(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      String formatToDay = DateFormat('yyyy-MM-dd').format(AppDateTime.now());          // Example: 2025-03-14
      var result = await _module.getAllRequestForm(formatToDay);
      listV = result['visitor'] ?? [];
      listE = result['employee'] ?? [];
      listLC = result['permission'] ?? [];
      listT = result['temporary'] ?? [];
      filteredVisiorList = listV;
      filteredEmployeeList = listE;
      filteredPermissionList = listLC;
      filteredTemporaryList = listT;

      // Departments and Contact
      deptList = await _module.getDepartments();

    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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
      filteredDate.value = null;
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
        case RequestType.temporary:
          filteredTemporaryList = listT.where((entry) {
            final fullName = entry['name'].toString().toLowerCase();
            final cardNo = entry['card_no'].toString().toLowerCase();
            DateTime? entryDate;
            final dateStr = entry['brw_at']?.toString();
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

  Future<void> updateDatetimeReturn(Map<String, dynamic> entry) async {
    try {
      String pk = entry['tno_pass'];
      var now = AppDateTime.now().toIso8601String();
      Map<String, dynamic> data = { 'guard_ret_at' : now };
      await _module.updateDatetimeReturn(pk, data);
      await _centerController.insertActvityLog('[Return] | Employee : ${entry['sequence_no']}');
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }
 
  //temporrary
  Future<void> updateRemark(String id, String rawRemark) async {
    try {
      var remark = rawRemark.isEmpty ? null : rawRemark;
      Map<String, dynamic> data = { 'remark' : remark };
      bool isSucess = await _module.updateTemporaryField(id, data);
      if(isSucess) {
        final index = filteredTemporaryList.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          filteredTemporaryList[index]['remark'] = remark;
        }
        // await _centerController.insertActvityLog('Edited temporary ID: ${id}');
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }


  // Sign Function
  Future<bool> updateSignature(Map<String, dynamic> entry, String keyPoint, Uint8List signature) async {
    bool status = false;
    try {
      final docType = entry['request_type'];
      final list = signatureSection[docType] ?? [];
      final item = list.firstWhere( (e) => e.signKey ==  keyPoint );
      final fileName = '${item.filename.toLowerCase()}.png';
      final directory = await getTemporaryDirectory();
      final filePath = join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(signature);
      List<File?> signatureList = [file];
      Map<String, List<File?>> dataFileImage = {
        'approver': signatureList,
      };

      var pk;
      var datetime;
      switch (docType) {
        case 'VISITOR':
          pk = entry['tno_pass'];
          datetime = entry['datetime_in'];
          break;
        case 'EMPLOYEE':
          pk = entry['tno_pass'];
          datetime = entry['datetime_out'];
          break;
        case 'PERMISSION':
          pk = entry['tno_pass'];
          datetime = entry['sign_emp_at'];
          break;
        case 'TEMPORARY':
          pk = entry['id'];
          datetime = entry['brw_at'];
          break;
      }

      await _module.uploadImageFiles(pk, docType, dataFileImage, datetime.toString());        //<--------- Upload images to server
      String mockFilename = basename(file.path);

      // for display mock update ui
      switch (docType) {
        case 'VISITOR' :
          final index = filteredVisiorList.indexWhere((e) => e['tno_pass'] == pk);
          if (index != -1) {
            filteredVisiorList[index][keyPoint] = mockFilename;
          }
          break;
        case 'EMPLOYEE' :
          final index = filteredEmployeeList.indexWhere((e) => e['tno_pass'] == pk);
          if (index != -1) {
            filteredEmployeeList[index][keyPoint] = mockFilename;
          }
          break;
        case 'PERMISSION' :
          final index = filteredPermissionList.indexWhere((e) => e['tno_pass'] == pk);
          if (index != -1) {
            filteredPermissionList[index][keyPoint] = mockFilename;
          }
          break;
        case 'TEMPORARY' :
          final index = filteredTemporaryList.indexWhere((e) => e['id'] == pk);
          if (index != -1) {
            filteredTemporaryList[index][keyPoint] = mockFilename;
          }
          break;
      }

      Map<String, dynamic> data = {};
      if(docType=="TEMPORARY") {
        if (keyPoint == "ret_sign_brw") {
          data = {
            item.signKey : mockFilename,
            'ret_at' : AppDateTime.now().toIso8601String(),
          };
        }else{
          data = {
            item.signKey : mockFilename,
          };
        }
      } else {
        data = {
          item.statusKey! : true,
          item.signKey : mockFilename,
          item.byKey! : signatureByController.text,
          item.datetimeKey! : AppDateTime.now().toIso8601String(),
        };
      }
      // AppLogger.debug(const JsonEncoder.withIndent('  ').convert(data));
      status = await _module.updateSginatureField( docType, pk, data);
      await _centerController.insertActvityLog(
        'SIGN | Document: ${docType} | PK: ${pk} | field: ${item.filename}'
      );
      signatureByController.clear();
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return status;
  }

}

class SignatureKeyField{
  final String label;
  final String filename;
  final String? statusKey;
  final String signKey;
  final String? byKey;
  final String? datetimeKey;

  SignatureKeyField({
    required this.label,
    required this.filename,
    this.statusKey,
    required this.signKey,
    this.byKey,
    this.datetimeKey,
  });
}