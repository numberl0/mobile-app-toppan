import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/visitorService/partTime/partTime_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:uuid/uuid.dart';

import '../../loading_dialog.dart';

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
  PartTimeModel partTimeModel = PartTimeModel();
  CenterController _centerController = CenterController();

  // Date
  ValueNotifier<DateTime> docDate = ValueNotifier(AppDateTime.now());
  ValueNotifier<DateTime?> retDate = ValueNotifier(null);

  TextEditingController titleController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  TextEditingController nameFilterController = TextEditingController();

  // String selectedCardType = 'Temp';
  String selectedCard = '';
  final Map<String, String> cardTypeMap = {
    'Temp': 'พนักงานชั่วคราว',
    'Nanny': 'พี่เลี้ยง',
    'Nurse': 'พยาบาล',
  };
  late String selectedCardType = cardTypeMap.keys.first;
  List<Map<String, dynamic>> cardList = [];
  List<Map<String, dynamic>> filterCardList = [];

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

  Future<void> initalPage(BuildContext context) async {
    try{
      _loadingDialog.show(context);

      await reloadCard();
      temporaryList = await partTimeModel.getTemporarySinceYesterday();
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
    try{
      if (cardList.isEmpty) return;
      filterCardList = cardList.where((card) => card['card_type'] == selectedCardType).toList();

       if (filterCardList.isNotEmpty) {
          selectedCard = filterCardList[0]['card_id'];
        } else {
          selectedCard = '';
        }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

   Future<void> reloadCard() async {
    try {
      cardList = await partTimeModel.getActiveCardByType(cardTypeMap.keys.toList());
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

      status = await partTimeModel.insertTemporaryPass(data);
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
      bool isSucess = await partTimeModel.updateTemporaryField(id, data);
      if(isSucess) {
        final index = filteredTemporaryList.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          filteredTemporaryList[index]['remark'] = remark;
        }
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
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

      await partTimeModel.uploadImageFiles(entry['id'], 'TEMPORARY', dataFileImage, entry['brw_at']);        //<--------- Upload images to server

      String filename = basename(file.path);
      

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

      status = await partTimeModel.updateTemporaryField(entry['id'], data);
      signatures[signer] = null;
      await reloadCard();
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

      await partTimeModel.uploadImageFiles(tno_pass, folderName, dataFileImage, date);        //<--------- Upload images to server

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