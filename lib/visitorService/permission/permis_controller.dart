import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/visitorService/permission/permis_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

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

  List<dynamic> managerList = [];
  List<String> managerNames = [];

  // 1.name 2.department 3.empId
  Map<String,String> empInfo = {};

  //Signature
  //Signature, dateTime, thaiDisplay, SignaturesBy
  final Map<String, List<dynamic>> signatureSectionMap = {
    'Employee': [null, null, 'พนักงาน', null],
    'Approved': [null, null, 'หัวหน้ากะ/ผู้ช่วยผู้จัดการ/ผู้จีดการแผนก', null],
    'Security (In)': [null, null, 'รปภ. (ขาเข้า)', null],
    'Security (Out)': [null, null, 'รปภ. (ขาออก)', null],
  };
  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<void> initalNewPage(BuildContext context) async {

    try {
      _loadingDialog.show(context);

      cardList = await permisModel.getActiveCardByType('Permanent');
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

      for (var key in fieldMappings.keys) {
        // Signature 
        if (data[fieldMappings[key]![0]] != null && data[fieldMappings[key]![0]] is String) {
          Uint8List? signatureBytes = await permisModel.loadImageAsBytes(data[fieldMappings[key]![0]]);
          signatureSectionMap[key]![0] = signatureBytes;
        } else {
          signatureSectionMap[key]![0] = data[fieldMappings[key]![0]];
        }
        // Date
        signatureSectionMap[key]![1] = data[fieldMappings[key]![1]] != null ? DateTime.tryParse(data[fieldMappings[key]![1]])?.toLocal() : null;
        // Signed by
        signatureSectionMap[key]![3] = data[fieldMappings[key]![2]];
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
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
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'PERMISSION', formattedDate);

      // Get approver filenames signature
      var approverFilenames_Signature = filenamesData?['approver[]'][0];

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

      //Signature
      //[0]=status, [1]=signature filenames, [2]=date, [3]=signatures_by
      List<dynamic> empSign = await getDataSignatureMapping(signatureSectionMap, 'Employee', approverFilenames_Signature);
      List<dynamic> approvSign = await getDataSignatureMapping(signatureSectionMap, 'Approved', approverFilenames_Signature);
      List<dynamic> guardInSign = await getDataSignatureMapping(signatureSectionMap, 'Security (In)', approverFilenames_Signature);
      List<dynamic> guardOutSign = await getDataSignatureMapping(signatureSectionMap, 'Security (Out)', approverFilenames_Signature);
      Map<String,dynamic> data = {
        'tno_pass' : tno_pass,
        'request_type' : 'PERMISSION',
        'doc_date' : DateFormat('yyyy-MM-dd').format(docDate.value),
        'report_to' : reqDeptController.text,
        'emp_name' : reqTitleController.text + reqNameController.text,
        'emp_dept' : reqDeptController.text,
        'emp_id' : reqEmpIdController.text,
        'reason' : selectedReason.shortCode,
        'reason_desc' : otherReasonController.text,
        'until_date' : DateFormat('yyyy-MM-dd').format(untilDate.value!),
        'responsible_by' : responToController.text,
        'responsible_user' : responUser,
        'brw_card' : selectedCard,
        'sign_emp_status' : empSign[0],
        'sign_emp' : empSign[1],
        'sign_emp_by' : empSign[3],
        'sign_emp_at' : empSign[2] != null ? empSign[2].toString() : null,
        'sign_respon_status' : approvSign[0],
        'sign_respon' : approvSign[1],
        'sign_respon_by' : approvSign[3],
        'sign_respon_at' : approvSign[2] != null ? approvSign[2].toString() : null,
        'sign_guardI_status' : guardInSign[0],
        'sign_guardI' : guardInSign[1],
        'sign_guardI_by' : guardInSign[3],
        'sign_guardI_at' : guardInSign[2] != null ? guardInSign[2].toString() : null,
        'sign_guardO_status' : guardOutSign[0],
        'sign_guardO' : guardOutSign[1],
        'sign_guardO_by' : guardOutSign[3],
        'sign_guardO_at' : guardOutSign[2] != null ? guardOutSign[2].toString() : null,
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

  Future<List> getDataSignatureMapping(Map<String, List<dynamic>> signatureMap,String sectionKey, Map<String, dynamic> approverFilenames_Signature) async {
    List<dynamic> data = [];
    try {
      var signatureMapping = signatureSectionMap[sectionKey];
      //status, signature filenames, date, signatures_by
      if (signatureMapping![0] != null && signatureMapping[1] != null) {
        data = [
          1,
          approverFilenames_Signature[sectionKey],
          signatureMapping[1],
          signatureMapping[3]
        ];
      } else {
        data = [
          0,
          approverFilenames_Signature[sectionKey],
          signatureMapping[1],
          signatureMapping[3]
        ];
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return data;
  }

  // Upload Image to Server
  Future<Map<String, dynamic>?> uploadImageToServer(String tno_pass, String folderName, String date) async {
    Map<String, dynamic> data = {};
    try {
      //Approver
      List<File?> signatureApprover = [];
      for (var section in signatureSectionMap.keys) {
        Uint8List? signatureData = signatureSectionMap[section]?[0];
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
        'approver': signatureApprover.isEmpty
            ? null
            : signatureApprover, //approver signature
      };

      await permisModel.uploadImageFiles(tno_pass, folderName, dataFileImage, date);   // <------- Upload Image

      //prepare approver filename
      List<String?> approverFilenames = signatureApprover
          .map((file) => file != null ? basename(file.path) : null)
          .toList();
      Map<String, String?> approverMap = Map.fromIterable(
        signatureSectionMap.keys,
        key: (key) => key,
        value: (key) {
          int index = signatureSectionMap.keys.toList().indexOf(key);
          return approverFilenames.length > index
              ? approverFilenames[index]
              : null;
        },
      );

      data = {
        'approver[]': [approverMap],
      };
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      throw err;
    }
    return data;
  }


  bool hasSignature() {
    return signatureSectionMap['Employee']?[0] != null;
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
    switch (code) {
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

}