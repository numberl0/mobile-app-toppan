

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/visitorService/employee/employee_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

class EmployeeController {

  EmployeeModel employeeModel = EmployeeModel();

  CenterController _centerController = CenterController();

  bool flagUpdateForm = false;
  bool logBook = false;
  String tno_pass = '';

  // int sequenceRunning = 0;
  String? formatSequenceRunning = null;

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
    // 'Department : '
    // 'FullName' :
    // 'EmployeeId' :
    // 'Signature' :
    // 'DateTime' :
  ];
  List<Map<String, String>> listItem_In = [
    // 'item':
  ];
  List<Map<String, String>> listItem_Out = [
    // 'item':
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
    'Security': [null, null, 'รปภ.', null],
  };

  // Controllers Employee's Information
  TextEditingController empTitleController = TextEditingController();
  TextEditingController empNameController = TextEditingController();
  TextEditingController empIdController = TextEditingController();
  TextEditingController empDeptController = TextEditingController();

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
      DateTime now = AppDateTime.now();
      tno_pass =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}"
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}"
          "${now.second.toString().padLeft(2, '0')}${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}";

      // Building
      List<dynamic> rawListBuilding = await employeeModel.getBuilding();
      buildingList = rawListBuilding
        .map((item) => Map<String, dynamic>.from(item))
        .where((building) {
          return building['building_name'] == 'อาคาร B' || building['building_name'] == 'อาคาร C';
        }).toList();
      this.selectedBuilding = this.buildingList[0]['id'];

      // Date
      flagDateOut = AppDateTime.now();
      dateOutController.text = DateFormat('yyyy-MM-dd').format(flagDateOut!);
      flagDateIn = flagDateOut;
      dateInController.text = DateFormat('yyyy-MM-dd').format(flagDateIn!);

      // Time
      flagTimeOut = TimeOfDay.now();
      timeOutController.text = formatTime(flagTimeOut!);

      flagTimeIn = flagTimeOut;
      timeInController.text = formatTime(flagTimeIn!);

    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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

      // logBook
      logBook = data['logBook'] == true;

      //tno
      tno_pass = data['tno_pass'];

      // Sequence Running Number
      formatSequenceRunning = data['sequence_no'] ?? null;

      // Building
      List<dynamic> rawListBuilding = await employeeModel.getBuilding();
      buildingList = rawListBuilding
        .map((item) => Map<String, dynamic>.from(item))
        .where((building) {
          return building['building_name'] == 'อาคาร B' || building['building_name'] == 'อาคาร C';
        }).toList();
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
      List<Map<String, dynamic>> copiedPeople = (data['people'] as List<dynamic>)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
      
      var uuid = Uuid();
      for (var person in copiedPeople) {    // only info same visitor form Id card and Datetime
        person.putIfAbsent('ID', () =>  uuid.v4() );
        person.putIfAbsent('EmployeeId', () => null);
        person.putIfAbsent('DateTime', () => AppDateTime.now().toString());

        // Signature
        if (person['Signature'] != null && person['Signature'] is String) {
          Uint8List? signatureBytes = await employeeModel.loadImageAsBytes(person['Signature']);
          person['Signature'] = signatureBytes;
        }else{
          person['Signature'] = null;
        }
      }
      personList = copiedPeople;

      //item_in
      if(data['item_in'] != null) {
        if (data['item_in']['images'] != null && data['item_in']['images'] is List) {
          for (String imageUrl in List<String>.from(data['item_in']['images'])) {
            File? file = await employeeModel.loadImageToFile(imageUrl);
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
            File? file = await employeeModel.loadImageToFile(imageUrl);
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
        'Employee': ['emp_sign', 'emp_at', 'emp_by'],
        'Approved': ['appr_sign', 'appr_at', 'appr_by'],
        'Media': ['media_sign', 'media_at', 'media_by'],
        'Security': ['guard_sign', 'guard_at', 'guard_by'],
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
      _centerController.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  Future<bool> searchInfoByPid(String empId) async {
    bool status = false;
    // 1.name 2.department 3.empId
    Map<String,String> empInfo = {};
    try {
       empInfo = await employeeModel.getInfoByEmpId(empId);
      if (empInfo == null || empInfo.isEmpty) {
        empInfo.clear();
        empNameController.clear();
        empDeptController.clear();
        return false;
      }
      empNameController.text = empInfo['FullName_Thai'] ?? '';
      empDeptController.text = empInfo['DepartmentName_Thai'] ?? '';
      empIdController.text = empId;

      status = true;
    } catch (err, stackTrace) {
      print("[Error] " + err.toString());
      print(stackTrace);
      empInfo.clear();
      empNameController.clear();
      empDeptController.clear();
      empIdController.clear();
    }
    return status;
  }

  Future<String> validateUpload() async {
    final fields = {
      "กรุณาเลือกวันเวลาออก": dateOutController.text,
      "กรุณาเพิ่มเวลาออก": timeOutController.text,
      "กรุณาระบุวัตถุประสงค์": objectiveController.text,
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
      return outDate.isBefore(inDate);
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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
          return !dateTimeIn.isBefore(dateTimeOut);
        }
    return false;
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
      return false;
    }
  }

  Future<bool> checkDateTimeError() async {
    try {
      if(flagDateIn != null && flagDateOut != null && flagTimeIn != null && flagTimeOut != null){
        bool isDateValid = await checkDateOutFrist();
        bool isTimeValid = await checkTimeOutNotPastInSameDay();
        if (!isDateValid && !isTimeValid && !outOnly ) {
          return false;
        }
      }
      return true;
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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
          'Department' : empDeptController.text, 
          'TitleName': empTitleController.text,
          'FullName': empNameController.text,
          'EmployeeId': empIdController.text,
          'Signature': signatureData,
          'DateTime': AppDateTime.now().toString(),
      }); 
      expandedPerson();
      await clearPersonController();
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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
      entry['Department'] = empDeptController.text;
      entry['TitleName'] = empTitleController.text;
      entry['FullName'] = empNameController.text;
      entry['EmployeeId'] = empIdController.text;

      if (signatureGlobalKey.currentState!
          .toPathList()
          .isNotEmpty) {
        entry['Signature'] = signatureData;
      }
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
    }
  }

  Future<void> clearPersonController() async {
    empTitleController.clear();
    empNameController.clear();
    empIdController.clear();
    signatureGlobalKey.currentState!.clear();
    empDeptController.clear();
  }

  void expandedPerson() {
     isExpanded_listPerson = !isExpanded_listPerson ? true : isExpanded_listPerson;
  }

  // ------------------------------------------------- Item ----------------------------------------------- //
  Future<void> addItemTypeList(String type) async {
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
      expandedItemList();
    }
  }

  void editItemTypeList(Map<String, String> entry) {
    entry['item'] = itemNameController.text;
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

  // -------------------------------------------------------------- Insert -------------------------------------------------------------- //
  Future<bool> insertRequestForm() async
  {
    bool status = false;
    try{
      //typForm
      String typeForm = 'EMPLOYEE';

      // ------------------------------ upload Image to server ------------------------------------- //
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'EMPLOYEE', dateOutController.text);

      // ------------------------------ Request ------------------------------------- //
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
      List<dynamic> empSign = await getDataSignatureMapping(signatureSectionMap, 'Employee', approverFilenames_Signature);
      List<dynamic> apprSign = await getDataSignatureMapping(signatureSectionMap, 'Approved', approverFilenames_Signature);
      List<dynamic> mediaSign = await getDataSignatureMapping(signatureSectionMap, 'Media', approverFilenames_Signature);
      List<dynamic> mainSign = await getDataSignatureMapping(signatureSectionMap, 'Security', approverFilenames_Signature);

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

      Map<String, dynamic> dataRequest = {
        'tno_pass': tno_pass,
        'request_type': typeForm,
        'sequence_no': formatSequenceRunning,
        'vehicle_no': vehicleLicenseController.text,
        'date_out': formattedDateOut,
        'time_out': formattedTimeOut,
        'date_in': formattedDateIn,
        'time_in': formattedTimeIn,
        'objective_type': objTypeInt,
        'objective': objectiveController.text,
        'building_card': buildingData['building_card'],
        'area': area,
        'emp_status': empSign[0],
        'emp_sign': empSign[1],
        'emp_at': empSign[2]!=null? empSign[2].toString(): null,
        'emp_by': empSign[3],
        'appr_status': apprSign[0],
        'appr_sign': apprSign[1],
        'appr_at': apprSign[2]!=null? apprSign[2].toString(): null,
        'appr_by': apprSign[3],
        'media_status': mediaSign[0],
        'media_sign': mediaSign[1],
        'media_at': mediaSign[2]!=null? mediaSign[2].toString(): null,
        'media_by': mediaSign[3],
        'guard_status': mainSign[0],
        'guard_sign': mainSign[1],
        'guard_at': mainSign[2]!=null? mainSign[2].toString(): null,
        'guard_by': mainSign[3],
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
          "Department": person["Department"],
          "FullName": person["FullName"],
          "TitleName": person["TitleName"],
          "EmployeeId": person["EmployeeId"],
          "Signature": (visitorFilenames != null && index < visitorFilenames.length)? visitorFilenames[index] : null,
          "DateTime": person["DateTime"].toString()
        });
      });

      Map<String, dynamic> dataForm = {
        'tno_pass': tno_pass,
        'visitorType': 'E',
        'people': peopleList,
        'item_in': itemInFilenames,
        'item_out': itemOutFilenames,
      };
      
      // ------------------------------------------------------------------- //

      if(!flagUpdateForm) {
        status = await employeeModel.insertRequestFormE( dataRequest, dataForm); // Insert
        await _centerController.insertActvityLog('Insert EMPLOYEE FORM [ ${tno_pass} ]');
      } else {
        status = await employeeModel.updateRequestFormE(tno_pass ,dataRequest, dataForm); // Update
        await _centerController.insertActvityLog('Update EMPLOYEE FORM [ ${tno_pass} ]');
      }
    }catch (err, stackTrace){
      print('Error: $err');
      await _centerController.logError(err.toString(), stackTrace.toString());
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
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
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
      await employeeModel.uploadImageFiles(tno_pass, folderName, dataFileImage, date); //<---------------------------- upload image to server

      // Prepare only filename
      List<String?> visitorFilenames = visitorSignatureFiles
          .map((file) => file != null ? basename(file.path) : null)
          .toList();

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
    } catch (err, stackTrace) {
      await _centerController.logError(err.toString(), stackTrace.toString());
      throw err;
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