import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/clear_temporary.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitor/visitor_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

class VisitorFormController {
  VisitorModule _module = VisitorModule();

  CenterController _centerController = CenterController();

  UserEntity userEntity = UserEntity();
  Cleartemporary cleartemporary = Cleartemporary();

  bool flagUpdateForm = false;
  bool logBook = false;

  String tno_pass = '';
  String? tno_ref = null;

  String agreementEng = '';
  String agreementThai = '';

  String? formatSequenceRunning = null;

  TextEditingController companyController = TextEditingController();
  TextEditingController vehicleLicenseController = TextEditingController();

  // Date and time
  DateTime? flagDateIn;
  TextEditingController dateInController = TextEditingController();
  DateTime? flagDateOut;
  TextEditingController dateOutController = TextEditingController();
  TimeOfDay? flagTimeIn;
  TextEditingController timeInController = TextEditingController();
  TimeOfDay? flagTimeOut;
  TextEditingController timeOutController = TextEditingController();

  TextEditingController objectiveController = TextEditingController();
  TextEditingController otherBuildingController = TextEditingController();

  // List Storage In / Out Items by List
  List<Map<String, dynamic>> personList = [
    // 'TitleName' :
    // 'FullName' :
    // 'Card_id' :
    // 'Signature' :
    // 'DateTime' :
  ];
  List<Map<String, String>> listItem_In = [
    // 'item':
  ];
  List<Map<String, String>> listItem_Out = [
    // 'item':
  ];

  //Storage In / Out Items by Image
  List<File?> imageList_In = [
    // File?
  ];
  List<File?> imageList_Out = [
    // File?
  ];

  // Controllers Input Visitor Information
  TextEditingController titleNameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController cardIdController = TextEditingController();

  List<Map<String, dynamic>> cardList = [];
  List<Map<String, dynamic>> cardListFromDoc = [];
  List<Map<String, dynamic>> cardListFilter = [];

  // Controller Input Item Information
  TextEditingController itemNameController = TextEditingController();

  //DropDown
  List<dynamic> buildingList = []; //Building

  //DropDown selection
  int? selectedBuilding; //Building Selected

  // other Building
  bool isExpandedBuilding = false;

  //Sign Approve
  //Signature, dataTime, thaiDisplay, SignaturesBy
  final Map<String, List<dynamic>> signatureSectionMap = {
    'Approved': [null, null, 'ผู้อนุมัติ', null],
    'Media': [null, null, 'ผู้ตรวจสอบสื่อ', null],
    'Security': [null, null, 'รปภ.', null],
    'Production': [null, null, 'รปภ. การผลิต', null],
  };

  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  final ImagePicker imagePicker = ImagePicker();
  int limitImageDisplay = 4; //Limit Image Display

  // Controll Expanded Toggle
  bool isExpanded_listPerson = true; //Visitor List
  bool isExpanded_listItem = true; //Items List


  // Departments
  String selectDept = '';
  List<String> deptList = [];

  // Contacts
  TextEditingController contactControl = TextEditingController();
  List<String> contactList = [];

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<String> validateUpload() async {
    final fields = {
      "กรุณาเลือกวันเวลาเข้า": dateInController.text,
      "กรุณาเลือกวันเวลาออก": dateOutController.text,
      "กรุณาเลือกเวลาเข้า": timeInController.text,
      "กรุณาเลือกเวลาออก": timeOutController.text,
      "กรุณาใส่ข้อมูลประสานงาน": contactControl.text,
      "กรุณาระบุวัตถุประสงค์": objectiveController.text,
    };
    for (var entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        scrollToSection(inputSectionKey);
        return entry.key;
      }
    }
    if (!contactList.contains(contactControl.text)) {
      return 'รายชื่อผู้ประสานงานไม่ตรงกับระบบ';
    }
    if (personList.isEmpty) {
      scrollToSection(visitorSectionKey);
      return 'กรุณาเพิ่มรายชื่อลงในเอกสารอย่างน้อย 1 คน';
    }
    if (isExpandedBuilding && otherBuildingController.text.isEmpty) {
      scrollToSection(buildingSectionKey);
      return 'โปรระบุสถานที่';
    }
    return '';
  }

  // New form
  Future<void> prepareNewForm(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      // For inset recode
      flagUpdateForm = false;

      // Agreement Warning
      Map<String, dynamic> aggrementText = await _module.getAgreementText();
      agreementEng = aggrementText['content_eng'] != null? aggrementText['content_eng'] : '';
      agreementThai = aggrementText['content_thai'] != null? aggrementText['content_thai'] : '';

      // List Pass Card
      cardList = await _module.getActiveCardByType(['visitor']);
      cardListFilter = [...cardList];

      //tno
      DateTime now = AppDateTime.now();
      tno_pass =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}";

      // Departments
      deptList = await _module.getDepartments();
      selectDept = deptList[0];

      // Contact
      contactList = await _module.getContactByDept(selectDept);

      // Building
      buildingList = await _module.getBuilding();
      this.selectedBuilding = this.buildingList[0]['id'];

      // Date In
      flagDateIn = AppDateTime.now();    //new form set only date_in
      dateInController.text = DateFormat('yyyy-MM-dd').format(flagDateIn!);

      // Time
      flagTimeIn = TimeOfDay.now();
      String formatTime(TimeOfDay time) {
        String hour = time.hour.toString().padLeft(2, '0');
        String minute = time.minute.toString().padLeft(2, '0');
        return "$hour:$minute";
      }

      timeInController.text = formatTime(flagTimeIn!);

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  // Load form
  Future<void> prepareLoadForm(BuildContext context, Map<String, dynamic>? loadData) async {
    try {
      _loadingDialog.show(context);
      Map<String, dynamic> data = loadData!;

      // For update recode
      flagUpdateForm = data['tno_pass'] != null? true : false; //case pull in visitor normal

      // logBook
      logBook = data['logBook'] == true;

      // Agreement Warning
      Map<String, dynamic> aggrementText = await _module.getAgreementText();
      agreementEng = aggrementText['content_eng'] != null? aggrementText['content_eng'] : '';
      agreementThai = aggrementText['content_thai'] != null? aggrementText['content_thai'] : '';

      // List Pass Card
      cardList = await _module.getActiveCardByType(['visitor']);
      List<String> cardIdsInDoc = (data['people'] as List)
        .map((person) => person['Card_Id'].toString())
        .toList();
      cardListFromDoc = await _module.getInfoCardFromDoc(cardIdsInDoc);


      String generateTnoPass() {
        DateTime now = AppDateTime.now();
        return "${now.year}"
              "${now.month.toString().padLeft(2, '0')}"
              "${now.day.toString().padLeft(2, '0')}"
              "${now.hour.toString().padLeft(2, '0')}"
              "${now.minute.toString().padLeft(2, '0')}"
              "${now.second.toString().padLeft(2, '0')}"
              "${(now.millisecond).toString().padLeft(3, '0')}";
      }

      tno_pass = data['tno_pass'] ?? generateTnoPass();

      //tno
      // tno_pass = data['tno_pass'];
      tno_ref = data['tno_ref'] ?? null;

      // Sequence Running Number
      formatSequenceRunning = data['sequence_no'] ?? null;

      // Building
      buildingList = await _module.getBuilding();
      var area = data['area'];
      var card = data['building_card'];
      if (area != null) {
        if (card == 'O') {
          isExpandedBuilding = true;
          otherBuildingController.text = area;
          selectedBuilding = buildingList.firstWhere((b) => b['building_card'] == card)['id'];
        } else {
          selectedBuilding = buildingList.firstWhere((b) => b['building_name'] == area)['id'];
        }
      } else {
        selectedBuilding = buildingList[0]['id'];
      }

      //Map Data
      companyController.text = data['company'] != null ? data['company'] : '';
      vehicleLicenseController.text = data['vehicle_no'] != null ? data['vehicle_no'] : '';

      // Date
      if (data['date_in'] != null) {
        flagDateIn = DateTime.parse(data['date_in'].toString()).toLocal();
        dateInController.text = DateFormat('yyyy-MM-dd').format(flagDateIn!);
      }
      if (data['date_out'] != null) {
        flagDateOut = DateTime.parse(data['date_out'].toString()).toLocal();
        dateOutController.text = DateFormat('yyyy-MM-dd').format(flagDateOut!);
      }

      // Time
      TimeOfDay? parseTime(String? timeString) {
        if (timeString == null || timeString.isEmpty) return null;
        final parts = timeString.split(':');
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      String formatTime24(TimeOfDay? time) {
        if (time == null) return "";
        return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      }

      if (data['time_in'] != null) {
        flagTimeIn = parseTime(data['time_in']);
        timeInController.text = formatTime24(flagTimeIn);
      }
      if (data['time_out'] != null) {
        flagTimeOut = parseTime(data['time_out']);
        timeOutController.text = formatTime24(flagTimeOut);
      }

      // Departments
      deptList = await _module.getDepartments();
      selectDept = data['contact_dept'] != null ? data['contact_dept'] : deptList[0];

      // Contact
      contactList = await _module.getContactByDept(selectDept);
      contactControl.text = data['contact'] != null ? data['contact'] : '';

      // Objective
      objectiveController.text = data['objective'] != null ? data['objective'] : '';

      // personList
      List<Map<String, dynamic>> copiedPeople = (data['people'] as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
      
      var uuid = Uuid();
      for (var person in copiedPeople) {
        person.putIfAbsent('ID', () =>  uuid.v4() );
        person.putIfAbsent('Card_Id', () => null);
        person.putIfAbsent('DateTime', () => AppDateTime.now().toString());

        // Signature
        if (person['Signature'] != null && person['Signature'] is String) {
          Uint8List? signatureBytes = await _module.loadImageAsBytes(person['Signature']);
          person['Signature'] = signatureBytes;
        }else{
          person['Signature'] = null;
        }
      }
      personList = copiedPeople;

      // item_in
      if(data['item_in'] != null) {
        if (data['item_in']['images'] != null && data['item_in']['images'] is List) {
          for (String imageUrl in List<String>.from(data['item_in']['images'])) {
            File? file = await _module.loadImageToFile(imageUrl);
            if (file != null) {
              imageList_In.add(file);
            }
          }
        }
        // in case list
        if (data['item_in']['items'] != null) {
          listItem_In = List<Map<String, String>>.from(
              (data['item_in']['items'] as List)
                  .map((e) => {"item": e.toString()}));
        }
      }

      // item_out
      if(data['item_out'] != null) {
        if (data['item_out']['images'] != null && data['item_out']['images'] is List) {
          for (String imageUrl in List<String>.from(data['item_out']['images'])) {
            File? file = await _module.loadImageToFile(imageUrl);
            if (file != null) {
              imageList_Out.add(file);
            }
          }
        }
        if (data['item_out']['items'] != null) {
        listItem_Out = List<Map<String, String>>.from(
            (data['item_out']['items'] as List)
                .map((e) => {"item": e.toString()}));
       }
      }

      // Signature
      final Map<String, List<String>> fieldMappings = {
        'Approved': ['appr_sign', 'appr_at', 'appr_by'],
        'Media': ['media_sign', 'media_at', 'media_by'],
        'Security': ['guard_sign', 'guard_at', 'guard_by'],
        'Production': ['prod_sign', 'prod_at', 'prod_by'],
      };
      for (var key in fieldMappings.keys) {
        if (data[fieldMappings[key]![0]] != null &&
            data[fieldMappings[key]![0]] is String) {
          Uint8List? signatureBytes = await _module.loadImageAsBytes(data[fieldMappings[key]![0]]);
          signatureSectionMap[key]![0] = signatureBytes; // Signature Uint8ListR
        } else {
          signatureSectionMap[key]![0] = data[fieldMappings[key]![0]]; //null
        }
        signatureSectionMap[key]![1] = data[fieldMappings[key]![1]] != null
    ? DateTime.tryParse(data[fieldMappings[key]![1]])?.toLocal()
    : null; //DateTime
        signatureSectionMap[key]![3] =
            data[fieldMappings[key]![2]]; // Signed by
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  List<Map<String, dynamic>> getFilterCardList() {
    final selectedCardIds = personList
        .map((p) => p['Card_Id'])
        .where((id) => id != null)
        .cast<String>()
        .toList();

    return cardList
        .where((card) => !selectedCardIds.contains(card['card_id']))
        .toList();
  }

  Future<void> addPersonInList() async {
    try{
      var uuid = Uuid();
      final signatureImage = await signatureGlobalKey.currentState!.toImage();
      final byteData =
          await signatureImage.toByteData(format: ImageByteFormat.png);
      final signatureData = byteData!.buffer.asUint8List();
      personList.add({
        'ID': uuid.v4(), //generate id
        'TitleName': titleNameController.text,
        'FullName': fullNameController.text,
        'Card_Id': cardIdController.text,
        'Signature': signatureData,
        'DateTime': AppDateTime.now().toString(),
      });

      bool exists = cardListFilter.any( (item) => item['card_id'] == cardIdController.text);
      if (exists) {
        cardListFilter.removeWhere( (item) => item['card_id'] == cardIdController.text);
      }
      
      await expandedPerson();
      await clearPersonController();
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    
  }

  Future<void> expandedPerson() async {
    isExpanded_listPerson = !isExpanded_listPerson ? true : isExpanded_listPerson;
  }

  Future<void> clearPersonController() async {
    titleNameController.clear();
    fullNameController.clear();
    cardIdController.clear();
    signatureGlobalKey.currentState!.clear();
  }

  Future<void> editPersonInList(Map<String, dynamic> entry) async {
    try {
      var signatureData;
      if (signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
        final signatureImage = await signatureGlobalKey.currentState!.toImage();
        final byteData = await signatureImage.toByteData(format: ImageByteFormat.png);
        signatureData = byteData!.buffer.asUint8List();
      }
      entry['TitleName'] = titleNameController.text;
      entry['FullName'] = fullNameController.text;
      // card 
      if (cardIdController.text != entry['Card_Id']) {
        bool isAlreadyInList = cardList.any((item) => item['card_id'] == entry['Card_Id']);
        if(!isAlreadyInList) {
          var oldCardData = cardListFromDoc.firstWhere(
            (item) => item['card_id'] == entry['Card_Id'],
            orElse: () => {},
          );
          if (oldCardData.isNotEmpty) {
            cardList.add(oldCardData);
            cardList.sort((a, b) => a['card_id'].compareTo(b['card_id']));
          }
        }
      }
      entry['Card_Id'] = cardIdController.text;
      if (signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
        entry['Signature'] = signatureData;
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

  Future<void> addItemTypeList(String type) async {
    try{
      if (itemNameController.text.isNotEmpty) {
        Map<String, String> item = {
          'item': itemNameController.text,
        };
        if (type == 'in') {
          listItem_In.add(item); //add item in
        } else {
          listItem_Out.add(item); //add item out
        }
        itemNameController.clear();
        await expandedItemList();
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

  Future<void> editItemTypeList(Map<String, String> entry) async {
    if (itemNameController.text.isNotEmpty) {
      entry['item'] = itemNameController.text;
    }
  }

  Future<void> expandedItemList() async {
    isExpanded_listItem = !isExpanded_listItem ? true : isExpanded_listItem;
  }

  Future<void> itemListClear() async {
    listItem_In.clear();
    listItem_Out.clear();
    imageList_In.clear();
    imageList_Out.clear();
  }

  Future<void> checkBuildingOther() async {
    Map<String, dynamic> buildingData = buildingList
        .firstWhere((building) => building['id'] == this.selectedBuilding);
    if (buildingData['building_card'] == 'O') {
      this.isExpandedBuilding = true;
    } else {
      this.isExpandedBuilding = false;
    }
  }

  Future<bool> checkDateInFrist() async {
    try {
      final outDate = DateTime(flagDateOut!.year, flagDateOut!.month, flagDateOut!.day);
      final inDate = DateTime(flagDateIn!.year, flagDateIn!.month, flagDateIn!.day);
      return inDate.isBefore(outDate);
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      return false;
    }
  }

    Future<bool> checkTimeOutNotPastInSameDay() async {
      try {
        final sameDate = flagDateIn!.year == flagDateOut!.year &&
                     flagDateIn!.month == flagDateOut!.month &&
                     flagDateIn!.day == flagDateOut!.day;
        if (sameDate) {
          final date = DateTime(flagDateIn!.year, flagDateIn!.month, flagDateIn!.day);
          final dateTimeIn = DateTime(date.year, date.month, date.day, flagTimeIn!.hour, flagTimeIn!.minute);
          final dateTimeOut = DateTime(date.year, date.month, date.day, flagTimeOut!.hour, flagTimeOut!.minute);
          return !dateTimeOut.isBefore(dateTimeIn);
        }
    return false;
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      return false;
    }
  }

  Future<bool> checkDateTimeError() async {
    try {
      if(flagDateIn != null && flagDateOut != null && flagTimeIn != null && flagTimeOut != null){
        bool isDateValid = await checkDateInFrist();
        bool isTimeValid = await checkTimeOutNotPastInSameDay();
        if (!isDateValid && !isTimeValid) {
          return false;
        }
      }
      return true;
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      return false;
    }
  }

  // -------------------------------------------------------------- Insert  -------------------------------------------------------------- //
  Future<bool> insertRequestForm() async
  {
    bool status = false;
    try{
      //typForm
      String typeForm = 'VISITOR';

      // ------------------------------ upload Image to server ------------------------------------- //
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'VISITOR', dateInController.text);

      // ------------------------------ Request ------------------------------------- //
      // Date
      String formattedDateIn = DateFormat('yyyy-MM-dd').format(flagDateIn!);
      String formattedDateOut = DateFormat('yyyy-MM-dd').format(flagDateOut!);

      // Time
      String formatTime(TimeOfDay? time) {
        return '${time?.hour.toString().padLeft(2, '0')}:${time?.minute.toString().padLeft(2, '0')}';
      }

      String formattedTimeIn = formatTime(flagTimeIn);
      String formattedTimeOut = formatTime(flagTimeOut);

      // Building selction
      Map<String, dynamic> buildingData = buildingList
          .firstWhere((building) => building['id'] == this.selectedBuilding);

      // Area
      String area;
      if (isExpandedBuilding) {
        area = otherBuildingController.text;
      } else {
        area = buildingData['building_name'];
      }

      // Get approver filenames signature
      var approverFilenames_Signature = filenamesData?['approver[]'][0];

      //Signature
      //[0]=status, [1]=signature filenames, [2]=date, [3]=signatures_by
      List<dynamic> apprSign = getDataSignatureMapping(
          signatureSectionMap, 'Approved', approverFilenames_Signature);
      List<dynamic> mediaSign = getDataSignatureMapping(
          signatureSectionMap, 'Media', approverFilenames_Signature);
      List<dynamic> mainSign = getDataSignatureMapping(
          signatureSectionMap, 'Security', approverFilenames_Signature);
      List<dynamic> prodSign = getDataSignatureMapping(
          signatureSectionMap, 'Production', approverFilenames_Signature);

      Map<String, dynamic> dataRequest = {
        'tno_pass': tno_pass,
        'request_type': typeForm,
        'sequence_no': formatSequenceRunning,
        'company': companyController.text,
        'vehicle_no': vehicleLicenseController.text,
        'date_in': formattedDateIn,
        'time_in': formattedTimeIn,
        'date_out': formattedDateOut,
        'time_out': formattedTimeOut,
        'contact': contactControl.text,
        'contact_dept': selectDept,
        'objective': objectiveController.text,
        'building_card': buildingData['building_card'],
        'area': area,
        'appr_status': apprSign[0],
        'appr_sign': apprSign[1],
        'appr_at': apprSign[2] != null ? apprSign[2].toString() : null,
        'appr_by': apprSign[3],
        'media_status': mediaSign[0],
        'media_sign': mediaSign[1],
        'media_at': mediaSign[2] != null ? mediaSign[2].toString() : null,
        'media_by': mediaSign[3],
        'guard_status': mainSign[0],
        'guard_sign': mainSign[1],
        'guard_at': mainSign[2] != null ? mainSign[2].toString() : null,
        'guard_by': mainSign[3],
        'prod_status': prodSign[0],
        'prod_sign': prodSign[1],
        'prod_at': prodSign[2] != null ? prodSign[2].toString() : null,
        'prod_by': prodSign[3],
        'tno_ref': tno_ref,
      };
 
      // ------------------------------ Form ------------------------------------- //
      //initial
      List<Map<String, dynamic>> peopleList = [];

      // Get List name
      var visitorFilenames = filenamesData?['visitor'];
      var itemInFilenames = filenamesData?['item_in'];
      var itemOutFilenames = filenamesData?['item_out'];
      personList.asMap().forEach((index, person) {
        peopleList.add({
          "ID": person["ID"],
          "FullName": person["FullName"],
          "TitleName": person["TitleName"],
          "Card_Id": person["Card_Id"],
          "Signature": (visitorFilenames != null && index < visitorFilenames.length)? visitorFilenames[index] : null,
          "DateTime": person["DateTime"].toString()
        });
      });

      // Prepare all data
      Map<String, dynamic> dataForm = {
        'tno_pass': tno_pass,
        'visitorType': 'V',
        'people': peopleList,
        'item_in': itemInFilenames,
        'item_out': itemOutFilenames,
      };
      
      // ------------------------------------------------------------------- //

      if(!flagUpdateForm) {
        status = await _module.insertRequestFormV( dataRequest, dataForm); // Insert
        await _centerController.insertActvityLog('Insert VISITOR FORM [ ${tno_pass} ]');
      } else {
        status = await _module.updateRequestFormV(tno_pass ,dataRequest, dataForm); // Update
        await _centerController.insertActvityLog('Update VISITOR FORM [ ${tno_pass} ]');
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return status;
  }

  List<dynamic> getDataSignatureMapping(Map<String, List<dynamic>> signatureMap,
      String sectionKey, Map<String, dynamic> approverFilenames_Signature) {
    var signatureMapping = signatureSectionMap[sectionKey];
    List<dynamic> data = [];
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
    return data;
  }

  // Upload Image to Server
  Future<Map<String, dynamic>?> uploadImageToServer(String tno_pass, String folderName, String date) async {
    Map<String, dynamic> data = {};
    try {
      List<File?> visitorSignatureFiles = [];
      for (var person in personList) {
        Uint8List? signatureData = person['Signature'];
        if (signatureData != null) {
          List<String> partsId = person['ID'].split('-');
          String lastPart = partsId.last;
          final directory = await getTemporaryDirectory();
          String fileName = 'V_${lastPart}.png';
          final filePath = join(directory.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(signatureData);
          visitorSignatureFiles.add(file);
        } else {
          visitorSignatureFiles.add(null);
        }
      }

      //item
      List<File> image_list_in = [];
      List<File> image_list_out = [];
      Future<File> processImage(File imageFile, String newFileName) async {
        final bytes = await imageFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) throw Exception('Failed to decode image');

        final directory = await getTemporaryDirectory();
        final newPath = join(directory.path, '$newFileName.jpg'); // Force .jpg to avoid weird formats

        final encodedImage = img.encodeJpg(decodedImage, quality: 70);
        final newFile = File(newPath);
        await newFile.writeAsBytes(encodedImage);
        return newFile;
      }

      // item_in (image)
      for (int index = 0; index < imageList_In.length; index++) {
        final item = imageList_In[index];
        if (item != null) {
          final processed = await processImage(item, 'in_$index');
          image_list_in.add(processed);
        }
      }
      // item_out (image)
      for (int index = 0; index < imageList_Out.length; index++) {
        final item = imageList_Out[index];
        if (item != null) {
          final processed = await processImage(item, 'out_$index');
          image_list_out.add(processed);
        }
      }

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
        'people': visitorSignatureFiles.isEmpty
            ? null
            : visitorSignatureFiles, //visitor signature
        'item_in': image_list_in.isEmpty ? null : image_list_in, //item in image
        'item_out': image_list_out.isEmpty ? null : image_list_out, //item out image
        'approver': signatureApprover.isEmpty
            ? null
            : signatureApprover, //approver signature
      };

      // Upload image to server
      await _module.uploadImageFiles(tno_pass, folderName, dataFileImage, date); //<---------------------------- upload image to server

      // Prepare only filename
      List<String?> visitorFilenames = visitorSignatureFiles.map((file) => file != null ? basename(file.path) : null).toList();

      //prepare item filename
      //item in
      final itemsIN = listItem_In.map((e) => e['item'] as String?).where((item) => item != null && item.trim().isNotEmpty).cast<String>().toList();
      final imagesIN = image_list_in.where((file) => file != null && file.path != null).map((file) => basename(file.path)).toList();
      final Map<String, List<String>> item_In_Filenames = {
        "items": itemsIN,
        "images": imagesIN,
      };
      //item out
      final itemsOUT = listItem_Out.map((e) => e['item'] as String?).where((item) => item != null && item.trim().isNotEmpty).cast<String>().toList();
      final imagesOUT = image_list_out.where((file) => file != null && file.path != null).map((file) => basename(file.path)).toList();
      final Map<String, List<String>> item_Out_Filenames = {
        "items": itemsOUT,
        "images": imagesOUT,
      };

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
        'visitor': visitorFilenames.isEmpty ? null : visitorFilenames,
        'item_in': item_In_Filenames.isEmpty ? null : item_In_Filenames,
        'item_out': item_Out_Filenames.isEmpty ? null : item_Out_Filenames,
        'approver[]': [approverMap],
      };
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
    }
    return data;
  }

  Future<void> loadContactByDepartment(String dept) async{
    contactList = await _module.getContactByDept(dept);
    contactControl.clear();
  }

  // ------------------------------------------------- Jumper!! ----------------------------------------------- //
  final GlobalKey inputSectionKey = GlobalKey();
  final GlobalKey visitorSectionKey = GlobalKey();
  final GlobalKey buildingSectionKey = GlobalKey();
  void scrollToSection(GlobalKey section) {
    final context = section.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 500), // Smooth scrolling duration
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
    }
  }
}
