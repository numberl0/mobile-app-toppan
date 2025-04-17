import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/clearTemporary.dart';
import 'package:toppan_app/loadingDialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitor/visitor_model.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';
import 'package:uuid/uuid.dart';

class VisitorFormController {
  VisitorformModule visitorformModule = VisitorformModule();

  VisitorServiceCenterController _controllerServiceCenter = VisitorServiceCenterController();

  UserEntity userEntity = UserEntity();
  Cleartemporary cleartemporary = Cleartemporary();

  bool flagUpdateForm = false;
  String tno_pass = '';
  String? tno_ref = null;

  String agreementEng = '';
  String agreementThai = '';

  int sequenceRunning = 0;
  String formatSequenceRunning = '';

  TextEditingController companyController = TextEditingController();
  TextEditingController vehicleLicenseController = TextEditingController();

  // Date and time
  DateTime? flagDate;
  TextEditingController dateController = TextEditingController();
  TimeOfDay? flagTimeIn;
  TextEditingController timeInController = TextEditingController();
  TimeOfDay? flagTimeOut;
  TextEditingController timeOutController = TextEditingController();

  TextEditingController contactController = TextEditingController();
  TextEditingController departmentController = TextEditingController();
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
    // 'name':
  ];
  List<Map<String, String>> listItem_Out = [
    // 'name':
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
    'Security': [null, null, 'รปภ. หน้าโรงงาน', null],
    'Production': [null, null, 'รปภ. card', null],
  };

  //is item image list
  bool isSwitchImagePicker = false;

  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  final ImagePicker imagePicker = ImagePicker();
  int limitImageDisplay = 4; //Limit Image Display

  // Controll Expanded Toggle
  bool isExpanded_listPerson = true; //Visitor List
  bool isExpanded_listItem = true; //Items List

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<String> validateUpload() async {
    final fields = {
      "กรุณาใส่ชื่อบริษัท": companyController.text,
      "กรุณาเลือกวันที่": dateController.text,
      "กรุณาเพิ่มเวลาเข้า": timeInController.text,
      "กรุณาเพิ่มเวลาออก": timeOutController.text,
      "กรุณาใส่ข้อมูลผู้ติดต่อ": contactController.text,
      "กรุณาใส่แผนกติดต่อ": departmentController.text,
      "กรุณาระบุวัตถุประสงค์ในการเยี่ยมชม": objectiveController.text,
    };
    for (var entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        scrollToSection(inputSectionKey);
        return entry.key;
      }
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
      Map<String, dynamic> aggrementText = await visitorformModule.getAgreementText();

      agreementEng = aggrementText['content_eng'] != null? aggrementText['content_eng'] : '';
      agreementThai = aggrementText['content_thai'] != null? aggrementText['content_thai'] : '';

      //tno
      DateTime now = DateTime.now();
      tno_pass =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}";

      // Sequence Number
      Map<String, dynamic> sequenceData = await visitorformModule.getSequeceRunning('VISITOR');
      sequenceRunning = sequenceData['sequence'];
      sequenceRunning += 1;
      formatSequenceRunning = sequenceRunning.toString().padLeft(6, '0');

      // Building
      buildingList = await visitorformModule.getBuilding();
      this.selectedBuilding = this.buildingList[0]['id'];

      // Date
      flagDate = DateTime.now();
      dateController.text = DateFormat('yyyy-MM-dd').format(flagDate!);

      // Time
      flagTimeIn = TimeOfDay.now();
      String formatTime(TimeOfDay time) {
        String hour = time.hour.toString().padLeft(2, '0');
        String minute = time.minute.toString().padLeft(2, '0');
        return "$hour:$minute";
      }

      timeInController.text = formatTime(flagTimeIn!);

    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
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
      flagUpdateForm = true;

      // Agreement Warning
      Map<String, dynamic> aggrementText = await visitorformModule.getAgreementText();
      agreementEng = aggrementText['content_eng'] != null? aggrementText['content_eng'] : '';
      agreementThai = aggrementText['content_thai'] != null? aggrementText['content_thai'] : '';

      //tno
      tno_pass = data['tno_pass'];
      tno_ref = data['tno_ref'] != null ? data['area'] : null;

      // Sequence Running Number
      formatSequenceRunning = data['sequence_no'];
      sequenceRunning = int.tryParse(formatSequenceRunning) ?? 0;

      // Building
      buildingList = await visitorformModule.getBuilding();
      if (data['area'] != null) {
        this.selectedBuilding = buildingList.firstWhere(
            (building) => building['building_name'] == data['area'])['id'];
        if (data['area'] == 'O') {
          otherBuildingController.text =
              data['area'] != null ? data['area'] : '';
        }
      } else {
        this.selectedBuilding = this.buildingList[0]['id'];
      }

      //Map Data
      companyController.text = data['company'] != null ? data['company'] : '';
      vehicleLicenseController.text =
          data['vehicle_no'] != null ? data['vehicle_no'] : '';

      // Date
      if (data['date'] != null) {
        flagDate = DateTime.parse(data['date'].toString()).toLocal();
        dateController.text = DateFormat('yyyy-MM-dd').format(flagDate!);
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

      //Map Data
      contactController.text = data['contact'] != null ? data['contact'] : '';
      departmentController.text = data['dept'] != null ? data['dept'] : '';
      objectiveController.text =
          data['objective'] != null ? data['objective'] : '';

      // personList
      for (var person in data['people']) {
        if (person['Signature'] != null && person['Signature'] is String) {
          Uint8List? signatureBytes =
              await visitorformModule.loadImageAsBytes(person['Signature']);
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
              File? file = await visitorformModule.loadImageToFile(imageUrl);
              if (file != null) {
                imageList_In.add(file);
              }
            }
          }
          if (data['item_out']['item'] != null &&
              data['item_out']['item'] is List) {
            for (String imageUrl
                in List<String>.from(data['item_out']['item'])) {
              File? file = await visitorformModule.loadImageToFile(imageUrl);
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
        'Approved': ['approved_sign', 'approved_datetime', 'approved_by'],
        'Media': ['media_sign', 'media_datetime', 'media_by'],
        'Security': ['mainEn_sign', 'mainEn_datetime', 'mainEn_by'],
        'Production': ['proArea_sign', 'proArea_datetime', 'proArea_by'],
      };
      for (var key in fieldMappings.keys) {
        if (data[fieldMappings[key]![0]] != null &&
            data[fieldMappings[key]![0]] is String) {
          Uint8List? signatureBytes = await visitorformModule
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

  Future<void> addPersonInList() async {
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
      'DateTime': DateTime.now().toString(),
    });
    await expandedPerson();
    await clearPersonController();
  }

  Future<void> expandedPerson() async {
    isExpanded_listPerson =
        !isExpanded_listPerson ? true : isExpanded_listPerson;
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
        final byteData =
            await signatureImage.toByteData(format: ImageByteFormat.png);
        signatureData = byteData!.buffer.asUint8List();
      }
      entry['TitleName'] = titleNameController.text;
      entry['FullName'] = fullNameController.text;
      entry['Card_Id'] = cardIdController.text;

      if (signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
        entry['Signature'] = signatureData;
      }
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

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
      await expandedItemList();
    }
  }

  Future<void> editItemTypeList(Map<String, String> entry) async {
    if (itemNameController.text.isNotEmpty) {
      entry['name'] = itemNameController.text;
    }
  }

  Future<void> expandedItemList() async {
    isExpanded_listItem = !isExpanded_listItem ? true : isExpanded_listItem;
  }

  Future<void> itemListClear() async {
    // Clear the lists
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

  //------------------------------ Upload Form --------------------------------------------//

  Future<bool> uploadVisitorForm() async {
    bool status = false;
    try {
      // Upload image client(mobile) to server
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'VISITOR'); //1st

        // Upload to Request_FORM table
      bool uploadRequest =
          await uploadToPassRequest(tno_pass, filenamesData); //2nd
      if (!uploadRequest) {
        throw Exception('Error uploading to PASS_REQUEST');
      }

       //Upload in PASS_Form table
      bool uploadForm = await uploadToPassForm(tno_pass, filenamesData); //3rd
      if (!uploadForm) {
        throw Exception('Error uploading to PASS_FORM');
      }

      
      if(uploadForm && uploadRequest && !flagUpdateForm) {
        await _controllerServiceCenter.insertActvityLog('Insert VISITOR FORM [ ${tno_pass} ] into PASS_FORM and PASS_REQUEST table');
        status = true;
      }else if (uploadForm && uploadRequest && flagUpdateForm) {
        await _controllerServiceCenter.insertActvityLog('Update VISITOR FORM [ ${tno_pass} ] into PASS_FORM and PASS_REQUEST table');
        status = true;
      } else {

      }
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return status;
  }

  // -------------------------------------------------------------- Upload  -------------------------------------------------------------- //

  // Upload to PASS_FORM table
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
        uploadStatus = await visitorformModule.uploadPassForm(data); //<------------- Upload Pass Form
      }else{
        uploadStatus = await visitorformModule.updatePassForm(data); //<------------- Update Pass Form
      }

    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return uploadStatus;
  }

  // Upload to PASS_REQUEST table
  Future<bool> uploadToPassRequest(
      String tno_pass, Map<String, dynamic>? filenamesData) async {
    bool uploadStatus = false;
    try {
      //typForm
      String typeForm = 'VISITOR';

      // Date
      String formattedDate = DateFormat('yyyy-MM-dd').format(flagDate!);

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

      Map<String, dynamic> data = {
        'tno_pass': tno_pass,
        'request_type': typeForm,
        'sequence_no': formatSequenceRunning,
        'company': companyController.text,
        'vehicle_no': vehicleLicenseController.text,
        'date': formattedDate,
        'time_in': formattedTimeIn,
        'time_out': formattedTimeOut,
        'contact': contactController.text,
        'dept': departmentController.text,
        'objective_type': 0, //visitor type = 0
        'objective': objectiveController.text,
        'building_card': buildingData['building_card'],
        'area': area,
        'empSign_status': 0, // because this is visitor form
        'empSign_sign': null,
        'empSign_datetime': null,
        'empSign_by': null,
        'approved_status': apprSign[0],
        'approved_sign': apprSign[1],
        'approved_datetime':
            apprSign[2] != null ? apprSign[2].toString() : null,
        'approved_by': apprSign[3],
        'media_status': mediaSign[0],
        'media_sign': mediaSign[1],
        'media_datetime': mediaSign[2] != null ? mediaSign[2].toString() : null,
        'media_by': mediaSign[3],
        'mainEn_status': mainSign[0],
        'mainEn_sign': mainSign[1],
        'mainEn_datetime': mainSign[2] != null ? mainSign[2].toString() : null,
        'mainEn_by': mainSign[3],
        'proArea_status': prodSign[0],
        'proArea_sign': prodSign[1],
        'proArea_datetime': prodSign[2] != null ? prodSign[2].toString() : null,
        'proArea_by': prodSign[3],
        'tno_ref': null,
      };

      if (!flagUpdateForm || (await visitorformModule.passRequestDoesNotExist(tno_pass))!) {
          uploadStatus = await visitorformModule.uploadPassRequest(data); // Upload Pass Request
          if (uploadStatus) {
              await visitorformModule.updateSequeceRunning('VISITOR', sequenceRunning); // Update Sequence Running
          }
      } else {
          uploadStatus = await visitorformModule.updatePassRequest(data); // Update Pass Request
      }


    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
    return uploadStatus;
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
  Future<Map<String, dynamic>?> uploadImageToServer(
      String tno_pass, String folderName) async {
    Map<String, dynamic> data = {};
    try {
      List<File?> visitorSignatureFiles = [];
      for (var person in personList) {
        Uint8List? signatureData = person['Signature'];
        if (signatureData != null) {
          List<String> partsId = person['ID'].split('-');
          String lastPart = partsId.last;
          final directory = await getTemporaryDirectory();
          String fileName = 'signature_Visitor_${lastPart}.png';
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
      if (isSwitchImagePicker) {
        //item in
        for (int index = 0; index < imageList_In.length; index++) {
          var item = imageList_In[index];
          if (item != null) {
            final directory = await getTemporaryDirectory();
            final fileExtension = extension(item.path);
            String newFileName = 'item_In_$index$fileExtension';
            final newFilePath = join(directory.path, newFileName);
            final renamedFile = await item.copy(newFilePath);
            item_in.add(renamedFile);
          }
        }
        // item out
        for (int index = 0; index < imageList_Out.length; index++) {
          var item = imageList_Out[index];
          if (item != null) {
            final directory = await getTemporaryDirectory();
            final fileExtension = extension(item.path);
            String newFileName = 'item_Out_$index$fileExtension';
            final newFilePath = join(directory.path, newFileName);
            final renamedFile = await item.copy(newFilePath);
            item_out.add(renamedFile);
          }
        }
      }

      //Approver
      List<File?> signatureApprover = [];
      for (var section in signatureSectionMap.keys) {
        Uint8List? signatureData = signatureSectionMap[section]?[0];
        if (signatureData != null) {
          final directory = await getTemporaryDirectory();
          String fileName = '${section.toLowerCase()}_Signature.png';
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
      await visitorformModule.uploadImageFiles(tno_pass, folderName,
          dataFileImage); //<---------------------------- upload image to server

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
