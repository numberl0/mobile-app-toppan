import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/visitorService/partTime/partTime_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:uuid/uuid.dart';

import '../../loading_dialog.dart';
import '../search/search_controller.dart';

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

class PartTimeController {
  PartTimeModel _model = PartTimeModel();
  CenterController _centerController = CenterController();

  // Date
  ValueNotifier<DateTime> docDate = ValueNotifier(AppDateTime.now());
  ValueNotifier<DateTime?> retDate = ValueNotifier(null);

  TextEditingController titleController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  TextEditingController nameFilterController = TextEditingController();

  String selectedCard = '';
  final Map<String, String> cardTypeMap = {
    'Temp': 'พนักงานชั่วคราว',
    'Nanny': 'พี่เลี้ยง',
    'Nurse': 'พยาบาล',
  };
  late String selectedCardType = cardTypeMap.keys.first;
  List<Map<String, dynamic>> cardList = [];
  List<Map<String, dynamic>> filterCardList = [];

  List<String> siteList = [];
  String? selectedSite;

  List<Map<String, dynamic>> filteredTemporaryList = [];
  late Map<String, String> filterCardTypeList = {
    'ALL': 'ทั้งหมด',
    ...cardTypeMap,
  };
  late String selectedFilterCardType = filterCardTypeList.keys.first;

  GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  final Map<Signer, dynamic> signatures = {
    Signer.borrowerIn: null,
    Signer.guardIn: null,
    Signer.borrowerOut: null,
    Signer.guardOut: null,
  };

  List<Map<String, dynamic>> temporaryList = [];

  final LoadingDialog _loadingDialog = LoadingDialog();

  Map<String, List<SignatureKeyField>> signatureSection = {
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

  Map<int, String> eTypeObjectiveMapping = {
    3: 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกพื้นที่การผลิต',  // Production Transfer
    2: 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกโรงงาน',        // Factory Transfer
    1: 'ขออนุญาตออกนอกโรงงาน',                        // Off-site Permit
  };

  Future<void> initalPage(BuildContext context) async {
    try{
      _loadingDialog.show(context);

      await reloadCard();
      temporaryList = await _model.getTemporarySinceYesterday();
      filteredTemporaryList = temporaryList;
      nameController.clear();
      remarkController.clear();
      nameFilterController.clear();
      signatures.updateAll((key, value) => null);
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }


  Future<void> filterCardType() async {
    try {
      if (cardList.isEmpty) return;

      // filter by card_type
      final temp = cardList
          .where((card) => card['card_type'] == selectedCardType)
          .toList();

      filterCardList = temp;

      // extract unique site
      siteList = temp.map((e) => e['access_site'].toString()).toSet().toList();

      selectedSite = '';
      selectedCard = '';

      if (filterCardList.isNotEmpty) {
        selectedCard = filterCardList.first['card_id'];
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

void filterBySite() {
    if ((selectedSite ?? '').isEmpty) {

    filterCardList = cardList.where((card) {
      return card['card_type'] == selectedCardType;
    }).toList();
  } else {
    filterCardList = cardList.where((card) {
      return card['card_type'] == selectedCardType &&
             card['access_site'] == selectedSite;
    }).toList();
  }

  selectedCard = filterCardList.isNotEmpty
      ? filterCardList.first['card_id']
      : '';
  }

   Future<void> reloadCard() async {
    try {
      cardList = await _model.getActiveCardByType(cardTypeMap.keys.toList());
      filterCardList = cardList;
      filterCardType();
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      rethrow;
    }
  }

  void filterTemporaryList() {
    final query = nameFilterController.text.toLowerCase();
    final selectedCard = selectedFilterCardType;

    filteredTemporaryList = temporaryList.where((entry) {
      final nameMatch = query.isEmpty
          ? true
          : (entry['name'] as String).toLowerCase().contains(query);

      final cardMatch = selectedCard == 'ALL'
          ? true
          : (entry['card_type'] as String) == selectedCard;
      return nameMatch && cardMatch;
    }).toList();
  }

  void resetFilter() {
    nameFilterController.clear();
    filteredTemporaryList = List.from(temporaryList);
  }

  void clearInputInsert() {
    titleController.clear();
    nameController.clear();
    signatureGlobalKey.currentState?.clear();
    selectedCardType = cardTypeMap.keys.first;
    filterCardList = cardList.where((card) => card['card_type'] == selectedCardType).toList();
    selectedCard = filterCardList[0]['card_id'];
  }

  Future<bool> insertTemporaryPass() async {
    bool status = false;
    try {
      var uuid = Uuid();
      var recordId = uuid.v4();
      Map<String, dynamic>? filenamesData = await uploadImageToServer(recordId,'TEMPORARY', docDate.value.toString());
      var signFilenames = filenamesData?['approver[]'][0];

      int brwStatus = (signFilenames[Signer.borrowerIn.name] != null && signFilenames[Signer.guardIn.name] != null) ? 1: 0;
      String formatThaiDate(DateTime? date) {
        if (date == null) return '';
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = (date.year + 543) % 100; // พ.ศ. 2 หลัก
        return '$day/$month/$year';
      }

      Map<String,dynamic> data = {
        'id' : recordId,
        'request_type' : 'TEMPORARY',
        'name' : titleController.text + nameController.text,
        'card_type' : cardList.firstWhere((card) =>card['card_id'] == selectedCard)['card_type'],
        'card_no' : selectedCard,
        'brw_status' : brwStatus,
        'brw_at' : AppDateTime.now().toIso8601String(),
        'brw_sign_brw' : signFilenames[Signer.borrowerIn.name],
        'brw_sign_guard' : signFilenames[Signer.guardIn.name],
        'ret_status' : 0,
        'ret_at' : null,
        'ret_sign_brw' : null,
        'ret_sign_guard' : null,
        'remark' : null,
      };

      status = await _model.insertTemporaryPass(data);
      if(status) {
        await _centerController.insertActvityLog('Create temporary ID: ${recordId}');
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return status;
  }

  Future<void> updateRemark(String id, String rawRemark) async {
    try {
      var remark = rawRemark.isEmpty ? null : rawRemark;
      Map<String, dynamic> data = { 'remark' : remark };
      bool isSucess = await _model.updateTemporaryField(id, data);
      if(isSucess) {
        final index = filteredTemporaryList.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          filteredTemporaryList[index]['remark'] = remark;
        }
        await _centerController.insertActvityLog('Edited temporary ID: ${id}');
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
        case 'TEMPORARY':
          pk = entry['id'];
          datetime = entry['brw_at'];
          break;
      }

      await _model.uploadImageFiles(pk, docType, dataFileImage, datetime.toString());
      String mockFilename = basename(file.path);

      // for display mock update ui
      switch (docType) {
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

      status = await _model.updateSginatureField( docType, pk, data);
      await _centerController.insertActvityLog(
        'SIGN | Document: ${docType} | PK: ${pk} | field: ${item.filename}'
      );
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return status;
  }


  Future<List> getDataFilenameSignature(Map<Signer, dynamic> signatureMap, Signer key, Map<String, dynamic> filename) async {
    List<dynamic> data = [];
    try {
      var signatureMapping = signatures[key];
      if (signatureMapping![0] != null && signatureMapping[1] != null) {
        data = [
          filename[key],
        ];
      } else {
        data = [
          filename[key],
        ];
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      rethrow;
    }
    return data;
  }

  Future<Map<String, dynamic>?> uploadImageToServer(String tno_pass, String folderName, String date) async {
    Map<String, dynamic> data = {};
    try {
      List<File?> signatureList = [];
      for (var key in signatures.keys) {
        Uint8List? signatureData = signatures[key];
        if (signatureData != null) {
          final directory = await getTemporaryDirectory();
          String fileName = '${key.name.toLowerCase()}.png';
          final filePath = join(directory.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(signatureData);
          signatureList.add(file);
        } else {
          signatureList.add(null);
        }
      }

      Map<String, List<dynamic>?> dataFileImage = {
        'approver': signatureList.isEmpty ? null : signatureList,
      };

      await _model.uploadImageFiles(tno_pass, folderName, dataFileImage, date);        //<--------- Upload images to server

      List<String?> signatureFilenames = signatureList
          .map((file) => file != null ? basename(file.path) : null)
          .toList();
      Map<String, String?> approverMap = Map.fromIterable(
        signatures.keys,
        key: (key) => (key as Signer).name,
        value: (key) {
          int index = signatures.keys.toList().indexOf(key);
          return signatureFilenames.length > index ? signatureFilenames[index] : null;
        },
      );
      data = {'approver[]': [approverMap]};
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      rethrow;
    }
    return data;
  }
}