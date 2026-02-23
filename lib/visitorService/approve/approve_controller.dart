import 'package:flutter/material.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/approve/approve_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

enum RequestType { visitor, employee, permission}

class ApproveController {
  ApproveModel approveModel = ApproveModel();

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
  
  TextEditingController filterCompanyController = TextEditingController();
  TextEditingController filterEmployeeIdController = TextEditingController();
  TextEditingController filterNameController = TextEditingController();
  ValueNotifier<DateTime?> filteredDate = ValueNotifier(null);
  TextEditingController filteredCardNo = TextEditingController();

  final List<RequestType> typeOptions = RequestType.values;
  late RequestType? selectedType = RequestType.values.first;



  bool startAnimation = false;

  final LoadingDialog _loadingDialog = LoadingDialog();

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
      var result = await approveModel.getRequestForApproved(username,building_card);
      listV = result['visitor'] ?? [];
      listE = result['employee'] ?? [];
      listLC = result['permission'] ?? [];

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
    Map<String, dynamic> response = {
    'success': false,
    'message': 'เกิดข้อผิดพลาดโปรดลองใหม่ภายหลัง',
    };
    try {
      String dateStr;
      Map<String,dynamic> signInfo = {};
      String username = await userEntity.getUserPerfer(userEntity.username);
      String first_name = await approveModel.getFirstnameApprover(username);

      switch (entry['request_type'].toString().toUpperCase()) {
        case 'VISITOR':
          dateStr = entry['date_in'];
          signInfo = {
            'appr_status': 1,
            'appr_at': AppDateTime.now().toString(),
            'appr_by': first_name,
          };
          break;
        case 'EMPLOYEE':
          dateStr = entry['date_out'];
          signInfo = {
            'appr_status': 1,
            'appr_at': AppDateTime.now().toString(),
            'appr_by': first_name,
          };
          break;
        case 'PERMISSION':
          dateStr = entry['doc_date'];
          signInfo = {
            'sign_respon_status': 1,
            'sign_respon_at': AppDateTime.now().toString(),
            'sign_respon_by': first_name,
          };
          break;
        default:
          dateStr = "";
          signInfo = {};
      }
      var status = await approveModel.approvedDocument(entry['tno_pass'], entry['request_type'], dateStr, signInfo, username);
      if(status['success']) {
        await _centerController.insertActvityLog('Approved document: ${entry['tno_pass']}');
      }
      return status;
      } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
        await _centerController.logError(err.toString(), stack.toString());
        return response;
      }
  }

  Future<Map<String, dynamic>> approvedAllDocumentByList() async {
    Map<String, dynamic> response = {
    'success': false,
    'message': 'เกิดข้อผิดพลาดโปรดลองใหม่ภายหลัง',
    };
    try {
      List<dynamic> filteredList = [];
      String username = await userEntity.getUserPerfer(userEntity.username);
      String first_name = await approveModel.getFirstnameApprover(username);
      Map<String,dynamic> sign_info = {};
      switch (selectedType!) {
        case RequestType.visitor:
          filteredList = filteredVisiorList;
          sign_info = {
            'appr_status': 1,
            'appr_at': AppDateTime.now().toString(),
            'appr_by': first_name,
          };
          break;
        case RequestType.employee:
          filteredList = filteredEmployeeList;
          sign_info = {
            'appr_status': 1,
            'appr_at': AppDateTime.now().toString(),
            'appr_by': first_name,
          };
          break;
        case RequestType.permission:
          filteredList = filteredPermissionList;
          sign_info = {
            'sign_respon_status': 1,
            'sign_respon_at': AppDateTime.now().toString(),
            'sign_respon_by': first_name,
          };
          break;
        default:
            sign_info = {};
      }
      if (filteredList.length == 0) return {
        'success': false,
        'message': 'ไม่พบข้อมูลเอกสารสำหรับการอนุมัติ',
        };
      List<Map<String, dynamic>> tno_listMap = filteredList.map((item) {
        String dateStr;
        switch (item['request_type'].toString().toUpperCase()) {
          case 'VISITOR':
            dateStr = item['date_in'];
            break;
          case 'EMPLOYEE':
            dateStr = item['date_out'];
            break;
          case 'PERMISSION':
            dateStr = item['doc_date'];
            break;
          default:
            dateStr = "";
        }
        DateTime parsedDate = DateTime.parse(dateStr);
        String year = parsedDate.year.toString();
        String month = parsedDate.month.toString().padLeft(2, '0');

        return {
          'tno_pass': item['tno_pass'].toString(),
          'type': item['request_type'].toString(),
          'path': '${item['request_type'].toString()}/$year/$month/${item['tno_pass'].toString()}',
        };
      }).toList();

      var status = await approveModel.approvedList(selectedType!.name.toUpperCase(), tno_listMap, sign_info, username);
      if(status['success']) {
        await _centerController.insertActvityLog('Approved documents: [${tno_listMap.map((e) => e['tno_pass']).join(", ")}]');
      }
      return status;
      } catch (err, stack) {
       AppLogger.error('Error: $err\n$stack');
        await _centerController.logError(err.toString(), stack.toString());
        return response;
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