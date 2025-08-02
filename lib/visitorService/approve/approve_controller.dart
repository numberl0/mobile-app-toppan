import 'package:flutter/material.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/approve/approve_model.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';

class ApproveController {
  ApproveModel approveModel = ApproveModel();

  VisitorServiceCenterController _controllerServiceCenter = VisitorServiceCenterController();

  UserEntity userEntity = UserEntity();

  // List document
  List<dynamic> list_Request = [];

  List<dynamic> filteredDocument = [];
  final List<String> typeOptions = ['All', 'Employee', 'Visitor'];
  String? selectedType;

  // Controller for search fields
  TextEditingController companyController = TextEditingController();
  TextEditingController nameController = TextEditingController();

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
          break; // exit loop
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

      
      list_Request = await approveModel.getRequestApproved(building_card);
    } catch (err, stackTrace) {
      await _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  Future<void> filterRequestList() async {
    try {
      String searchCompany = companyController.text.toLowerCase();
      String searchName = nameController.text.toLowerCase();

      filteredDocument = list_Request.where((entry) {
        final String requestType = entry['request_type']?.toLowerCase() ?? '';
        final String companyName = entry['company']?.toLowerCase() ?? '';
        final List<dynamic>? peopleList = entry['people'];

        // Filter by type
        final matchesType = selectedType == 'All' ||
            requestType.contains(selectedType!.toLowerCase());

        // Filter by company name
        final matchesCompany =
            searchCompany.isEmpty || companyName.contains(searchCompany);

        // Filter by person's name inside "people" list
        final matchesPerson = searchName.isEmpty ||
            (peopleList != null &&
                peopleList.any((person) {
                  final String fullName =
                      person['FullName']?.toString().toLowerCase() ?? '';
                  return fullName.contains(searchName);
                }));

        return matchesType && matchesCompany && matchesPerson;
      }).toList();
    } catch (err, stackTrace) {
      await _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<bool> approvedDocument(Map<String,dynamic> entry) async {
    bool status = false;
    try {
      String dateStr;
      if(entry['request_type'].toLowerCase() == 'visitor'){
        dateStr = entry['date_in'];
      }else{
        dateStr = entry['date_out'];
      }
      DateTime parsedDate = DateTime.parse(dateStr);
      String year = parsedDate.year.toString();
      String month = parsedDate.month.toString().padLeft(2, '0');

      String approvedBy = await userEntity.getUserPerfer(userEntity.username);
      String signaturFilename = await approveModel.getSignatureFilenameByUsername(approvedBy);
      Map<String,dynamic> data = {
        'approved_status': 1,
        'approved_sign': signaturFilename,
        'approved_datetime': DateTime.now().toString(),
        'approved_by': approvedBy,
      };
      status = await approveModel.approvedDocument(entry['tno_pass'], entry['request_type'], year, month, data);
      if(status) {
        await _controllerServiceCenter.insertActvityLog('$approvedBy approved document TNO_PASS : ${entry['tno_pass']}');
      }

      } catch (err, stackTrace) {
        await _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
      }
    return status;
  }

  Future<bool> approvedAll() async {
    bool status = false;
    try {
      String approvedBy = await userEntity.getUserPerfer(userEntity.username);
      String signaturFilename = await approveModel.getSignatureFilenameByUsername(approvedBy);
      // List<Map<String, dynamic>> tno_listMap = filteredDocument.map((item) => {
      //   'tno_pass': item['tno_pass'].toString(),
      //   'type': item['request_type'].toString(),
      // }).toList();
      List<Map<String, dynamic>> tno_listMap = filteredDocument.map((item) {
        String dateStr;

        if (item['request_type'].toString().toLowerCase() == 'visitor') {
          dateStr = item['date_in'];
        } else {
          dateStr = item['date_out'];
        }

        DateTime parsedDate = DateTime.parse(dateStr);
        String year = parsedDate.year.toString();
        String month = parsedDate.month.toString().padLeft(2, '0');

        return {
          'tno_pass': item['tno_pass'].toString(),
          'type': item['request_type'].toString(),
          'year': year,
          'month': month,
        };
      }).toList();

      Map<String,dynamic> data = {
        'approved_status': 1,
        'approved_sign': signaturFilename,
        'approved_datetime': DateTime.now().toString(),
        'approved_by': approvedBy,
      };
      status = await approveModel.approvedAll(tno_listMap, data);
      if(status) {
        await _controllerServiceCenter.insertActvityLog('Approved documents : [${tno_listMap.map((e) => e['tno_pass']).join(", ")}]');
      }
      } catch (err, stackTrace) {
        await _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
      }
    return status;
  }

  Future<bool> isAdmin() async {
    try {
      List<String> roles = await userEntity.getUserPerfer(userEntity.roles_visitorService);
      return roles.contains('Administrator');
    } catch (err, stackTrace) {
      await _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
      return false;
    }
  }

}