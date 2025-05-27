

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/visitorService/employee/employee_model.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

class EmployeeController {

  EmployeeModel employeeModel = EmployeeModel();

  VisitorServiceCenterController _controllerServiceCenter = VisitorServiceCenterController();

  bool flagUpdateForm = false;
  String tno_pass = '';

  int sequenceRunning = 0;
  String formatSequenceRunning = '';

  TextEditingController vehicleLicenseController = TextEditingController();
  TextEditingController deptController = TextEditingController();
  //Objective Type
  TextEditingController objectiveController = TextEditingController();

 // Date and time
  DateTime? flagDateIn;
  TextEditingController dateInController = TextEditingController();
  DateTime? flagDateOut;
  TextEditingController dateOutController = TextEditingController();
  TimeOfDay? flagTimeIn;
  TextEditingController timeInController = TextEditingController();
  TimeOfDay? flagTimeOut;
  TextEditingController timeOutController = TextEditingController();

   // List Storage In / Out Items by List
  List<Map<String, dynamic>> personList = [
    // 'TitleName' :
    // 'FullName' :
    // 'Card_id' :
    // 'Signature' :
    // 'DateTime' :
  ];
  List<Map<String, String>> listItem_In = [
    // 'name':
  ];
  List<Map<String, String>> listItem_Out = [
    // 'name':
  ];
  
  bool outOnly = true;

  //Storage In / Out Items by Image
  List<File?> imageList_In = [];
  List<File?> imageList_Out = [];
  final ImagePicker imagePicker = ImagePicker();
  int limitImageDisplay = 4; //Limit Image Display

  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

   //Sign Approve
  //Signature, dataTime, thaiDisplay, SignaturesBy
  final Map<String, List<dynamic>> signatureSectionMap = {
    'Employee': [null, null, 'พนักงาน', null],
    'Approved': [null, null, 'ผู้อนุมัติ', null],
    'Media': [null, null, 'ผู้ตรวจสอบสื่อ', null],
    'Security': [null, null, 'รปภ. หน้าโรงงาน', null],
  };

  // Controllers Employee's Information
  TextEditingController titleNameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController cardIdController = TextEditingController();

  //item
  TextEditingController itemNameController = TextEditingController();

  // Controll Expanded Toggle
  bool isExpanded_listPerson = true; //Person List
  bool isExpanded_listItem = true; //Items List
  bool isSwitchImagePicker = false; //Items Image

  Map<String, String> typeObjectiveMapping = {
    'HSA': 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกพื้นที่การผลิตเพื่อ',
    'TOF': 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกโรงงานเพื่อ',
    'LF': 'ขออนุญาตออกนอกโรงงาน',
  };
  String objTypeSelection = 'LF';


  // Control Animation Dropdrow Objective Type
  bool isStrechedDropDown = false;


  //DropDown
  List<dynamic> buildingList = []; //Building
  //DropDown selection
  int? selectedBuilding; //Building Selected
  // other Building
  bool isExpandedBuilding = false;
  TextEditingController otherBuildingController = TextEditingController();

  final LoadingDialog _loadingDialog = LoadingDialog();

  // ------------------------------------------- New form ------------------------------------------- //
  Future<void> prepareNewForm(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      // For inset recode
      flagUpdateForm = false;

      //tno
      DateTime now = DateTime.now();
      tno_pass =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}";

      // Sequence Number
      Map<String, dynamic> sequenceData = await employeeModel.getSequeceRunning('EMPLOYEE');
      sequenceRunning = sequenceData['sequence'];
      sequenceRunning += 1;
      formatSequenceRunning = sequenceRunning.toString().padLeft(6, '0');

      // Building
      buildingList = await employeeModel.getBuilding();
      this.selectedBuilding = this.buildingList[0]['id'];

      // Date
      flagDateOut = DateTime.now();
      dateOutController.text = DateFormat('yyyy-MM-dd').format(flagDateOut!);
      flagDateIn = flagDateOut;
      dateInController.text = DateFormat('yyyy-MM-dd').format(flagDateIn!);

      // Time
      flagTimeOut = TimeOfDay.now();
      timeOutController.text = formatTime(flagTimeOut!);

      flagTimeIn = flagTimeOut;
      timeInController.text = formatTime(flagTimeIn!);

    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }


  // ------------------------------------------- Load form ------------------------------------------- //
  Future<void> prepareLoadForm(BuildContext context, Map<String, dynamic>? loadData) async {
    try {
      _loadingDialog.show(context);

      Map<String, dynamic> data = loadData!;

      // For update recode
      flagUpdateForm = true;

      //tno
      tno_pass = data['tno_pass'];

      // Sequence Running Number
      formatSequenceRunning = data['sequence_no'];
      sequenceRunning = int.tryParse(formatSequenceRunning) ?? 0;

      // Building
      buildingList = await employeeModel.getBuilding();
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
      vehicleLicenseController.text =
          data['vehicle_no'] != null ? data['vehicle_no'] : '';

      // Date
      if (data['date_out'] != null) {
        flagDateOut = DateTime.parse(data['date_out'].toString()).toLocal();
        dateOutController.text = DateFormat('yyyy-MM-dd').format(flagDateOut!);
      }
      if (data['date_in'] != null) {
        flagDateIn = DateTime.parse(data['date_in'].toString()).toLocal();
        dateInController.text = DateFormat('yyyy-MM-dd').format(flagDateIn!);
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

      if(flagTimeOut != flagTimeIn) {
        outOnly = false;
      }else{
        outOnly = true;
      }

      //Map Data
      objectiveController.text =
          data['objective'] != null ? data['objective'] : '';

      // personList
      for (var person in data['people']) {
        if (person['Signature'] != null && person['Signature'] is String) {
          Uint8List? signatureBytes =
              await employeeModel.loadImageAsBytes(person['Signature']);
          person['Signature'] = signatureBytes;
        }
      }
      personList = (data['people'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      //item_in / item_out
      if (data['item_in']['type'] == data['item_out']['type']) {
        if (data['item_in']['type'] == 'image' &&
            data['item_out']['type'] == 'image') {
          //in case image
          isSwitchImagePicker = true;
          if (data['item_in']['item'] != null &&
              data['item_in']['item'] is List) {
            for (String imageUrl
                in List<String>.from(data['item_in']['item'])) {
              File? file = await employeeModel.loadImageToFile(imageUrl);
              if (file != null) {
                imageList_In.add(file);
              }
            }
          }
          if (data['item_out']['item'] != null &&
              data['item_out']['item'] is List) {
            for (String imageUrl
                in List<String>.from(data['item_out']['item'])) {
              File? file = await employeeModel.loadImageToFile(imageUrl);
              if (file != null) {
                imageList_Out.add(file);
              }
            }
          }
        } else {
          // in case list
          if (data['item_in']['item'] != null) {
            listItem_In = List<Map<String, String>>.from(
                (data['item_in']['item'] as List)
                    .map((e) => {"name": e.toString()}));
          }
          if (data['item_out']['item'] != null) {
            listItem_Out = List<Map<String, String>>.from(
                (data['item_out']['item'] as List)
                    .map((e) => {"name": e.toString()}));
          }
        }
      }


      // Signature
      final Map<String, List<String>> fieldMappings = {
        'Employee': ['empSign_sign', 'empSign_datetime', 'empSign_by'],
        'Approved': ['approved_sign', 'approved_datetime', 'approved_by'],
        'Media': ['media_sign', 'media_datetime', 'media_by'],
        'Security': ['mainEn_sign', 'mainEn_datetime', 'mainEn_by'],
      };
      for (var key in fieldMappings.keys) {
        if (data[fieldMappings[key]![0]] != null &&
            data[fieldMappings[key]![0]] is String) {
          Uint8List? signatureBytes = await employeeModel
              .loadImageAsBytes(data[fieldMappings[key]![0]]);
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

    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }



  Future<String> validateUpload() async {
    final fields = {
      "กรุณาเลือกวันที่ออก": dateOutController.text,
      "กรุณาเพิ่มเวลาออก": timeOutController.text,
      "กรุณาระบุวัตถุประสงค์ในการเยี่ยมชม": objectiveController.text,
    };
    for (var entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        scrollToSection(inputSectionKey);
        return entry.key;
      }
    }
    if (personList.isEmpty) {
      scrollToSection(personSectionKey);
      return 'กรุณาเพิ่มรายชื่อลงในเอกสารอย่างน้อย 1 คน';
    }
    if (isExpandedBuilding && otherBuildingController.text.isEmpty) {
      scrollToSection(buildingSectionKey);
      return 'โปรระบุสถานที่';
    }
    if (!outOnly && (timeInController.text.isEmpty || dateInController.text.isEmpty)) {
      return 'ยังไม่ได้เลือกวันเวลาเข้า';
    }
    return '';
  }

  Future<bool> checkDateOutFrist() async {
    try {
      final outDate = DateTime(flagDateOut!.year, flagDateOut!.month, flagDateOut!.day);
      final inDate = DateTime(flagDateIn!.year, flagDateIn!.month, flagDateIn!.day);
      return !outDate.isAfter(inDate);
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
      return false;
    }
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

  // ------------------------------------------------- Person ----------------------------------------------- //

  Future<void> addPersonInList() async {
    try {
      var uuid = Uuid();
      final signatureImage = await signatureGlobalKey.currentState!.toImage();
      final byteData = await signatureImage.toByteData(format: ImageByteFormat.png);
      final signatureData = byteData!.buffer.asUint8List();
      personList.add({
          'ID': uuid.v4(),    //generate id
          'TitleName': titleNameController.text,
          'FullName': fullNameController.text,
          'Card_Id': cardIdController.text,
          'Signature': signatureData,
          'DateTime': DateTime.now().toString(),
      }); 
      expandedPerson();
      await clearPersonController();
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<void> editPersonInList(Map<String, dynamic> entry) async {
    try {
      var signatureData;
      if (signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
        final signatureImage = await signatureGlobalKey.currentState!.toImage();
        final byteData =
            await signatureImage.toByteData(format: ImageByteFormat.png);
        signatureData = byteData!.buffer.asUint8List();
      }
      entry['FullName'] = fullNameController.text;
      entry['Card_Id'] = cardIdController.text;

      if (signatureGlobalKey.currentState!
          .toPathList()
          .isNotEmpty) {
        entry['Signature'] = signatureData;
      }
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<void> clearPersonController() async {
    titleNameController.clear();
    fullNameController.clear();
    cardIdController.clear();
    signatureGlobalKey.currentState!.clear();
  }

  void expandedPerson() {
     isExpanded_listPerson = !isExpanded_listPerson ? true : isExpanded_listPerson;
  }




  // ------------------------------------------------- Item ----------------------------------------------- //
  Future<void> addItemTypeList(String type) async {
    if (itemNameController.text.isNotEmpty) {
      Map<String, String> item = {
        'name': itemNameController.text,
      };
      if (type == 'in') {
        listItem_In.add(item); //add item in
      } else {
        listItem_Out.add(item); //add item out
      }
      itemNameController.clear();
      expandedItemList();
    }
  }

  void editItemTypeList(Map<String, String> entry) {
    entry['name'] = itemNameController.text;
  }

  void itemListClear() {
    // Clear the lists
    listItem_In.clear();
    listItem_Out.clear();
    imageList_In.clear();
    imageList_Out.clear();
  }

  void expandedItemList() {
    isExpanded_listItem = !isExpanded_listItem? true:isExpanded_listItem;
  }

  // ------------------------------------------------- Upload!! ----------------------------------------------- //
  Future<bool> uploadForm() async {
    bool status = false;
    try {
      // Upload image client(mobile) to server
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'EMPLOYEE', dateOutController.text); //1st

      // Upload to PASS_REQUEST table
      bool uploadRequest =
          await uploadToPassRequest(tno_pass, filenamesData); //2nd
      if (!uploadRequest) {
        throw Exception('Error uploading to PASS_REQUEST');
      }

      // Upload in PASS_Form table
      bool uploadForm = await uploadToPassForm(tno_pass, filenamesData); //3rd
      if (!uploadForm) {
        throw Exception('Error uploading to PASS_FORM');
      }

      
      if(uploadForm && uploadRequest && !flagUpdateForm) {
        await _controllerServiceCenter.insertActvityLog('Insert EMPLOYEE FORM [ ${tno_pass} ] into PASS_FORM and PASS_REQUEST table');
        status = true;
      }else if (uploadForm && uploadRequest && flagUpdateForm) {
        await _controllerServiceCenter.insertActvityLog('Update EMPLOYEE FORM [ ${tno_pass} ] into PASS_FORM and PASS_REQUEST table');
        status = true;
      } else {

      }
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return status;
  }

  // -------------------------------------------------------------- Upload  -------------------------------------------------------------- //
  // Upload to PASS_REQUEST table 1st
  Future<bool> uploadToPassRequest(
      String tno_pass, Map<String, dynamic>? filenamesData) async {
    bool uploadStatus = false;
    try {
      //typForm
      String typeForm = 'EMPLOYEE';

      // Date in/out
      var formattedDateOut = flagDateOut != null? DateFormat('yyyy-MM-dd').format(flagDateOut!) : null;
      var formattedDateIn = flagDateIn != null? DateFormat('yyyy-MM-dd').format(flagDateIn!) : null;

      // Time
      String formatTime(TimeOfDay? time) {
        return '${time?.hour.toString().padLeft(2, '0')}:${time?.minute.toString().padLeft(2, '0')}';
      }
      var formattedTimeOut = flagTimeOut != null? formatTime(flagTimeOut) : null;
      var formattedTimeIn = flagTimeIn != null? formatTime(flagTimeIn) : null;

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
      List<dynamic> empSign =
          getDataSignatureMapping(signatureSectionMap, 'Employee', approverFilenames_Signature);
      List<dynamic> apprSign = getDataSignatureMapping(
          signatureSectionMap, 'Approved', approverFilenames_Signature);
      List<dynamic> mediaSign = getDataSignatureMapping(
          signatureSectionMap, 'Media', approverFilenames_Signature);
      List<dynamic> mainSign = getDataSignatureMapping(
          signatureSectionMap, 'Security', approverFilenames_Signature);

      int objTypeInt = 1;
      switch(objTypeSelection) {
        case 'LF':
          objTypeInt = 1; // Leave factory
          break;
        case 'TOF':
          objTypeInt = 2; // Take out Factory
          break;
        case 'HSA':
          objTypeInt = 3; // Take out HSA
          break;
      }

      Map<String, dynamic> data = {
        'tno_pass': tno_pass,
        'request_type': typeForm,
        'sequence_no': formatSequenceRunning,
        'company': 'Toppan edge (thailand) limited.',
        'vehicle_no': vehicleLicenseController.text,
        'date_in': formattedDateIn,
        'time_in': formattedTimeIn,
        'date_out': formattedDateOut,
        'time_out': formattedTimeOut,
        'contact': null,
        'dept': null,
        'objective_type': objTypeInt,
        'objective': objectiveController.text,
        'building_card': buildingData['building_card'],
        'area': area,
        'empSign_status': empSign[0],
        'empSign_sign': empSign[1],
        'empSign_datetime': empSign[2]!=null? empSign[2].toString(): null,
        'empSign_by': empSign[3],
        'approved_status': apprSign[0],
        'approved_sign': apprSign[1],
        'approved_datetime': apprSign[2]!=null? apprSign[2].toString(): null,
        'approved_by': apprSign[3],
        'media_status': mediaSign[0],
        'media_sign': mediaSign[1],
        'media_datetime': mediaSign[2]!=null? mediaSign[2].toString(): null,
        'media_by': mediaSign[3],
        'mainEn_status': mainSign[0],
        'mainEn_sign': mainSign[1],
        'mainEn_datetime': mainSign[2]!=null? mainSign[2].toString(): null,
        'mainEn_by': mainSign[3],
        'proArea_status': 0,  // because this is employee form
        'proArea_sign': null,
        'proArea_datetime': null,
        'proArea_by': null,
        'tno_ref': null,
      };

      if(!flagUpdateForm) {
        uploadStatus = await employeeModel.uploadPassRequest(data); //<-------------------------- upload Request Form
        if (uploadStatus) {
        await employeeModel.updateSequeceRunning(typeForm, sequenceRunning); //<-------------------------- update Sequece Running
      }
      } else {
        uploadStatus = await employeeModel.updatePassRequest(data); //<-------------------------- update Request Form
      }

    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return uploadStatus;
  }


  // Upload to PASS_FORM table 2nd
  Future<bool> uploadToPassForm(
      String tno_pass, Map<String, dynamic>? filenamesData) async {
    bool uploadStatus = false;
    try {
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
          "Signature": visitorFilenames![index],
          "DateTime": person["DateTime"].toString()
        });
      });

      //Item In/Out
      //Check item is image
      String typeItem = '';
      if (isSwitchImagePicker) {
        typeItem = 'image';
      } else {
        typeItem = 'list';
      }
      // Prepare item data
      Map<String, dynamic> itemIn_Json = {
        "type": typeItem,
        'item': itemInFilenames
      };
      Map<String, dynamic> itemOut_Json = {
        "type": typeItem,
        'item': itemOutFilenames
      };

      // Prepare all data
      Map<String, dynamic> data = {
        'tno_pass': tno_pass,
        'visitorType': 0,
        'people': peopleList,
        'item_in': itemIn_Json,
        'item_out': itemOut_Json,
      };
      // call api
      if(!flagUpdateForm) {
        uploadStatus = await employeeModel.uploadPassForm(data); //<------------- Upload Pass Form
      }else{
        uploadStatus = await employeeModel.updatePassForm(data); //<------------- Update Pass Form
      }

    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return uploadStatus;
  }


  List<dynamic> getDataSignatureMapping(Map<String, List<dynamic>> signatureMap,String sectionKey, Map<String, dynamic> approverFilenames_Signature) {
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
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return data;
  }


  // Upload Image to Server
  Future<Map<String, dynamic>?> uploadImageToServer(
      String tno_pass, String folderName, String date) async {
    Map<String, dynamic> data = {};
    try {
      List<File?> visitorSignatureFiles = [];
      for (var person in personList) {
        Uint8List? signatureData = person['Signature'];
        if (signatureData != null) {
          List<String> partsId = person['ID'].split('-');
          String lastPart = partsId.last;
          final directory = await getTemporaryDirectory();
          String fileName = 'E_${lastPart}.png';
          final filePath = join(directory.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(signatureData);
          visitorSignatureFiles.add(file);
        } else {
          visitorSignatureFiles.add(null);
        }
      }

      //item
      List<File> item_in = [];
      List<File> item_out = [];
      Future<File> processImage(File imageFile, String newFileName) async {
        final bytes = await imageFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage == null) throw Exception('Failed to decode image');

        final directory = await getTemporaryDirectory();
        final newPath = join(directory.path, '$newFileName.jpg'); // Force .jpg to avoid weird formats

        final encodedImage = img.encodeJpg(decodedImage, quality: 90);
        final newFile = File(newPath);
        await newFile.writeAsBytes(encodedImage);
        return newFile;
      }

      if (isSwitchImagePicker) {
        // item_in
        for (int index = 0; index < imageList_In.length; index++) {
          final item = imageList_In[index];
          if (item != null) {
            final processed = await processImage(item, 'in_$index');
            item_in.add(processed);
          }
        }

        // item_out
        for (int index = 0; index < imageList_Out.length; index++) {
          final item = imageList_Out[index];
          if (item != null) {
            final processed = await processImage(item, 'out_$index');
            item_out.add(processed);
          }
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
        'item_in': item_in.isEmpty ? null : item_in, //item in image
        'item_out': item_out.isEmpty ? null : item_out, //item out image
        'approver': signatureApprover.isEmpty
            ? null
            : signatureApprover, //approver signature
      };

      // Upload image to server
      await employeeModel.uploadImageFiles(tno_pass, folderName,
          dataFileImage, date); //<---------------------------- upload image to server

      // Prepare only filename
      List<String?> visitorFilenames = visitorSignatureFiles
          .map((file) => file != null ? basename(file.path) : null)
          .toList();
      //prepare item filename
      var item_In_Filenames;
      var item_Out_Filenames;
      if (isSwitchImagePicker) {
        item_In_Filenames = item_in.map((file) => basename(file.path)).toList();
        item_Out_Filenames =
            item_out.map((file) => basename(file.path)).toList();
      } else {
        //user name is not image
        item_In_Filenames =
            listItem_In.map((item) => item['name'] as String).toList();
        item_Out_Filenames =
            listItem_Out.map((item) => item['name'] as String).toList();
      }
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
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return data;
  }

   // ------------------------------------------------- Jumper!! ----------------------------------------------- //
  final GlobalKey inputSectionKey = GlobalKey();
  final GlobalKey personSectionKey = GlobalKey();
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