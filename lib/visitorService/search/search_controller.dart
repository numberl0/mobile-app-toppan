import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/visitorService/search/search_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';


enum RequestType { visitor, employee, permission, temporary }


enum Signer { borrowerIn, guardIn, borrowerOut, guardOut }
String getKeyFromSigner(Signer signer) {
  switch (signer) {
    case Signer.borrowerIn:
      return 'brw_sign_brw';
    case Signer.guardIn:
      return 'brw_sign_guard';
    case Signer.borrowerOut:
      return 'ret_sign_brw';
    case Signer.guardOut:
      return 'ret_sign_guard';
  }
}

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
  SearchModule searchModule = SearchModule();

  CenterController _centerController = CenterController();

  List<dynamic> listV = [];
  List<dynamic> listE = [];
  List<dynamic> listLC = [];
  List<dynamic> listT = [];
 
  List<dynamic> filteredVisiorList = [];
  List<dynamic> filteredEmployeeList = [];
  List<dynamic> filteredPermissionList = [];
  List<dynamic> filteredTemporaryList = [];
  
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
  final Map<Signer, dynamic> signatures = {
    Signer.borrowerIn: null,
    Signer.guardIn: null,
    Signer.borrowerOut: null,
    Signer.guardOut: null,
  };


  Future<void> preparePage(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      String formatToDay = DateFormat('yyyy-MM-dd').format(AppDateTime.now());          // Example: 2025-03-14
      var result = await searchModule.getAllRequestForm(formatToDay);
      listV = result['visitor'] ?? [];
      listE = result['employee'] ?? [];
      listLC = result['permission'] ?? [];
      listT = result['temporary'] ?? [];
      filteredVisiorList = listV;
      filteredEmployeeList = listE;
      filteredPermissionList = listLC;
      filteredTemporaryList = listT;
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
    }catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
    }
  }

 

  Future<void> updateRemark(String id, String rawRemark) async {
    try {
      var remark = rawRemark.isEmpty ? null : rawRemark;
      Map<String, dynamic> data = { 'remark' : remark };
      bool isSucess = await searchModule.updateTemporaryField(id, data);
      if(isSucess) {
        final index = filteredTemporaryList.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          filteredTemporaryList[index]['remark'] = remark;
        }
      }
    }catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<bool> updateSignature(Map<String, dynamic> entry, Signer signer) async {
    bool status = false;
    try {
      Uint8List signatureData = signatures[signer];
      final directory = await getTemporaryDirectory();
      String fileName = '${signer.name.toLowerCase()}.png';
      final filePath = join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(signatureData);
      List<File?> signatureList = [file];
      Map<String, List<File?>> dataFileImage = {
        'approver': signatureList,
      };

      await searchModule.uploadImageFiles(entry['id'], 'TEMPORARY', dataFileImage, entry['brw_at']);        //<--------- Upload images to server

      String filename = basename(file.path);
      

      // for display mock update ui
      final key = getKeyFromSigner(signer);
      final index = filteredTemporaryList.indexWhere((e) => e['id'] == entry['id']);
      if (index != -1) {
        filteredTemporaryList[index][key] = filename;
      }

      Map<String, dynamic> data = {};
      if(signer == Signer.borrowerOut){
        data = {
          'ret_at' : AppDateTime.now().toIso8601String(),
          key : filename,
        };
      }else{
        data = {
          key : filename,
        };
      }

      print(const JsonEncoder.withIndent('  ').convert(data));
      status = await searchModule.updateTemporaryField(entry['id'], data);
      signatures[signer] = null;
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
    }
    return status;
  }

}
