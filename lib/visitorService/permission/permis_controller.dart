import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/visitorService/permission/permis_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

import '../../entity/signature_section.dart';
import '../../loading_dialog.dart';

class PermisController {

  PermisModel permisModel = PermisModel();

  CenterController _centerController = CenterController();

  bool flagUpdateForm = false;
  bool logBook = false;
  String tno_pass = '';

  // Date
  ValueNotifier<DateTime> docDate = ValueNotifier(AppDateTime.now());

  List<String> titleNameList = ['นาย', 'นาง', 'นางสาว'];
  TextEditingController reqTitleController = TextEditingController();
  TextEditingController reqNameController = TextEditingController();
  TextEditingController reqDeptController = TextEditingController();
  TextEditingController reqEmpIdController = TextEditingController();

  ValueNotifier<DateTime?> untilDate = ValueNotifier(null);

  TextEditingController responToController = TextEditingController();
  String selectedCard = '';
  TextEditingController cardId = TextEditingController();

  CardReason selectedReason = CardReason.lost;
  TextEditingController otherReasonController = TextEditingController();

  List<Map<String, dynamic>> cardList = [];
  List<Map<String, dynamic>> filterCardList = [];

  List<dynamic> managerList = [];
  List<String> managerNames = [];

  // 1.name 2.department 3.empId
  Map<String,String> empInfo = {};

  //Signature
  Map<String, SignatureSection> signatureSection = {
    'Employee': SignatureSection(status: false, label: 'พนักงาน'),
    'Approved': SignatureSection(status: false, label: 'หัวหน้ากะ/ผู้ช่วยผู้จัดการ/ผู้จีดการแผนก'),
    'Security (In)': SignatureSection(status: false, label: 'รปภ. (ขาเข้า)'),
    'Security (Out)': SignatureSection(status: false, label: 'รปภ. (ขาออก)'),
  };

  List<String> siteList = [];
  String? selectedSite;

  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<void> initalNewPage(BuildContext context) async {

    try {
      _loadingDialog.show(context);

      cardList = await permisModel.getActiveCardByType('Permanent');
      filterCardList = cardList;
      siteList = filterCardList.map((e) => e['access_site'].toString()).toSet().toList();

      managerList = await permisModel.getManagerRole();
      managerNames = getManagerNameList(managerList);

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  Future<void> initalLoadPage(BuildContext context,  Map<String, dynamic>? loadData) async {
    try {
      _loadingDialog.show(context);

      flagUpdateForm = true;
      logBook = loadData?['logBook'] == true;
      cardList = await permisModel.getActiveCardByType('Permanent');
      filterCardList = cardList;
      siteList = filterCardList.map((e) => e['access_site'].toString()).toSet().toList();
      managerList = await permisModel.getManagerRole();
      managerNames = getManagerNameList(managerList);

      Map<String, dynamic> data = loadData!;

      tno_pass = data['tno_pass']!;

      for (var t in titleNameList) {
        if (data['emp_name'].startsWith(t)) {
          reqTitleController.text = t;
          reqNameController.text = data['emp_name'].substring(t.length);
          break;
        }
      }

      reqDeptController.text = data['emp_dept']!;
      reqEmpIdController.text = data['emp_id']!;

      docDate.value = AppDateTime.from(DateTime.parse(data['doc_date']));
      untilDate.value = AppDateTime.from(DateTime.parse(data['until_date']));

      selectedReason = CardReasonExtension.fromShortCode(data['reason'])!;
      otherReasonController.text = data['reason_desc'] ?? '';

      responToController.text = data['responsible_by']!;
      selectedCard = data['brw_card']!;

    // Signature, datetime, by
      final Map<String, List<String>> fieldMappings = {
        'Employee': ['sign_emp', 'sign_emp_at', 'sign_emp_by'],
        'Approved': ['sign_respon', 'sign_respon_at', 'sign_respon_by'],
        'Security (In)': ['sign_guardI', 'sign_guardI_at', 'sign_guardI_by'],
        'Security (Out)': ['sign_guardO', 'sign_guardO_at', 'sign_guardO_by'],
      };

      for(var key in fieldMappings.keys) {
        final section = signatureSection[key]!;
        final fields = fieldMappings[key]!;

        final signKey = fields[0];
        final dateKey = fields[1];
        final byKey = fields[2];

        // -------------------------
        // 1. Signature (Uint8List)
        // -------------------------
        final signValue = data[signKey];

        if (signValue != null && signValue is String) {
          section.status = true;
          section.fileName = data[signKey];
          section.filePath = await permisModel.loadImageAsBytes(signValue);
        } else {
          section.status = false;
          section.fileName = null;
          section.filePath = null;
        }

        // -------------------------
        // 2. DateTime
        // -------------------------
        section.dateTime = data[dateKey] != null
            ? DateTime.tryParse(data[dateKey])?.toLocal()
            : null;

        // -------------------------
        // 3. By (string)
        // -------------------------
        section.by = data[byKey] ?? null;
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  void filterBySite() {
    if (selectedSite == null || selectedSite!.isEmpty) {
      filterCardList = cardList;
    } else {
      filterCardList = cardList.where((card) {
        return card['access_site'] == selectedSite;
      }).toList();
    }
    selectedCard = filterCardList.isNotEmpty
        ? filterCardList.first['card_id']
        : '';
    }

  List<String> getManagerNameList(List<dynamic> managerList) {
    return managerList.map((m) {
      return "${m['title_name']} ${m['first_name']} ${m['last_name']}";
    }).toList();
  }

  Future<void> selectRadioCardReason(CardReason value) async {
    this.selectedReason = value;
    if(value != CardReason.other){
      otherReasonController.clear();
    }
  }

  Future<bool> searchInfoByPid(String empId) async {
    bool status = false;
    try {
       empInfo = await permisModel.getInfoByEmpId(empId);
      if (empInfo.isEmpty) {
        empInfo.clear();
        reqNameController.clear();
        reqDeptController.clear();
        return false;
      }
      reqNameController.text = empInfo['FullName_Thai'] ?? '';
      reqDeptController.text = empInfo['DepartmentName_Thai'] ?? '';
      reqEmpIdController.text = empId;

      status = true;
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      empInfo.clear();
      reqNameController.clear();
      reqDeptController.clear();
      reqEmpIdController.clear();
    }
    return status;
  }

  Future<bool> insertForm() async {
    bool status = false;
    try{

      if(!flagUpdateForm) {
        //tno
        DateTime now = AppDateTime.now();
        tno_pass =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}";
      }

      //  // ------------------------------ upload Image to server ------------------------------------- //
      String formattedDate = DateFormat('yyyy-MM-dd').format(docDate.value);
      await uploadImageToServer(tno_pass,'PERMISSION', formattedDate);

      // Check responsible in manager role
      String? responUser;
      final parts = responToController.text.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final f = parts[1], l = parts[2];
        responUser = managerList
            .cast<Map<String, dynamic>>()
            .firstWhere(
              (m) => m["first_name"]?.trim() == f && m["last_name"]?.trim() == l,
              orElse: () => {},
            )["username"];
      } else {
        responUser = null;
      }

      Map<String,dynamic> data = {
        'tno_pass' : tno_pass,
        'request_type' : 'PERMISSION',
        'doc_date' : DateFormat('yyyy-MM-dd').format(docDate.value),
        'report_to' : reqDeptController.text,
        'emp_name' : reqTitleController.text + reqNameController.text,
        'emp_dept' : reqDeptController.text,
        'emp_id' : reqEmpIdController.text,
        'reason' : selectedReason.shortCode,
        'reason_desc': selectedReason == CardReason.other ? otherReasonController.text : selectedReason.description,
        'until_date' : DateFormat('yyyy-MM-dd').format(untilDate.value!),
        'responsible_by' : responToController.text,
        'responsible_user' : responUser,
        'brw_card' : selectedCard,

        if (!flagUpdateForm) ...{
          'sign_emp_status': signatureSection['Employee']!.status,
          'sign_emp': signatureSection['Employee']!.fileName,
          'sign_emp_by': signatureSection['Employee']!.by,
          'sign_emp_at': signatureSection['Employee']!.dateTime !=null? signatureSection['Employee']!.dateTime.toString(): null,
        }

        // 'sign_respon_status': signatureSection['Approved']!.status,
        // 'sign_respon': signatureSection['Approved']!.fileName,
        // 'sign_respon_by': signatureSection['Approved']!.by,
        // 'sign_respon_at': signatureSection['Approved']!.dateTime !=null? signatureSection['Approved']!.dateTime.toString(): null,
        // 'sign_guardI_status': signatureSection['Security (In)']!.status,
        // 'sign_guardI': signatureSection['Security (In)']!.fileName,
        // 'sign_guardI_by': signatureSection['Security (In)']!.by,
        // 'sign_guardI_at': signatureSection['Security (In)']!.dateTime !=null? signatureSection['Security (In)']!.dateTime.toString(): null,
        // 'sign_guardO_status': signatureSection['Security (Out)']!.status,
        // 'sign_guardO': signatureSection['Security (Out)']!.fileName,
        // 'sign_guardO_by': signatureSection['Security (Out)']!.by,
        // 'sign_guardO_at': signatureSection['Security (Out)']!.dateTime !=null? signatureSection['Security (Out)']!.dateTime.toString(): null,


      };
      
       if(!flagUpdateForm) {
        status = await permisModel.insertForm(data); // Insert
        await _centerController.insertActvityLog('Create permission form: ${tno_pass}');
      } else {
        status = await permisModel.updateForm(tno_pass, data); // Update
        await _centerController.insertActvityLog('Edit permission form: ${tno_pass}');
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      return status;
    }
    return status;
  }

  
  // Upload Image to Server
  Future<void> uploadImageToServer(String tno_pass, String folderName, String date) async {
    try {
      // =========================
      // Approver (OBJECT VERSION)
      // =========================
      List<File?> signatureApprover = [];
      for (var section in signatureSection.keys) {
        Uint8List? signatureData = signatureSection[section]!.filePath;
        if (signatureData != null) {
          final directory = await getTemporaryDirectory();
          String fileName = '${section.toLowerCase()}.png';
          final filePath = join(directory.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(signatureData);
          signatureApprover.add(file);
        } else {
          signatureApprover.add(null);
        }
      }


      Map<String, List<dynamic>?> dataFileImage = {
        'approver': signatureApprover.isEmpty? null : signatureApprover, //approver signature
      };

      await permisModel.uploadImageFiles(tno_pass, folderName, dataFileImage, date);   // <------- Upload Image

      // =========================
      //Approver filenames (OBJECT BASED)
      // =========================
      List<String?> approverFilenames = signatureApprover.map((file) => file != null ? basename(file.path) : null).toList();
      Map<String, String?> approverMap = {};
      final keys = signatureSection.keys.toList();
      for (var entry in approverFilenames.asMap().entries) {
        int index = entry.key;
        String? filename = entry.value;

        if (index < keys.length) {
          approverMap[keys[index]] = filename;
        }
      }
      for (var entry in approverMap.entries) {
        final key = entry.key;
        final fileName = entry.value;

        final section = signatureSection[key];
        section!.fileName = fileName;
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      throw err;
    }
  }


  bool hasSignature() {
    return signatureSection['Employee']?.status == true;
  }


}

enum CardReason {
  lost,
  forgotten,
  damaged,
  other,
}

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

  static CardReason? fromShortCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'L':
        return CardReason.lost;
      case 'F':
        return CardReason.forgotten;
      case 'D':
        return CardReason.damaged;
      case 'O':
        return CardReason.other;
      default:
        return null;
    }
  }

  String get description {
    switch (this) {
      case CardReason.lost:
        return 'ทำบัตรประจำตัวพนักงานหาย';
      case CardReason.forgotten:
        return 'ลืมบัตรประจำตัวพนักงานมา';
      case CardReason.damaged:
        return 'บัตรประจำตัวพนักงานชำรุด';
      case CardReason.other:
        return 'อื่นๆ';
    }
  }

}