
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/entity/employee_profile.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/visitorService/employee/employee_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

import '../../entity/department.dart';
import '../../entity/signature_section.dart';

class EmployeeController {

  EmployeeModel _module = EmployeeModel();

  CenterController _centerController = CenterController();

  bool flagUpdateForm = false;
  bool logBook = false;
  String tno_pass = '';

  String? formatSequenceRunning = null;

  DateTime? expectedDateTimeOut;

  TextEditingController vehicleLicenseController = TextEditingController();
  TextEditingController deptController = TextEditingController();
  //Objective Type
  TextEditingController objectiveController = TextEditingController();

  List<Employee> personList = [];

  List<Map<String, String>> listItem_In = [
    // 'item':
  ];
  List<Map<String, String>> listItem_Out = [
    // 'item':
  ];

  List<Department> deptList = [];
  
  bool outOnly = true;

  //Storage In / Out Items by Image
  List<File?> imageList_In = [];
  List<File?> imageList_Out = [];
  final ImagePicker imagePicker = ImagePicker();
  int limitImageDisplay = 4; //Limit Image Display

  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  Map<String, SignatureSection> signatureSection = {
    'Employee': SignatureSection(status: false, label: 'พนักงาน'),
    'Approved': SignatureSection(status: false, label: 'ผู้อนุมัติ'),
    'Media': SignatureSection(status: false, label: 'ผู้ตรวจสอบสื่อ'),
    'Security': SignatureSection(status: false, label: 'รปภ.'),
  };

  // Controllers Employee's Information
  TextEditingController empTitleController = TextEditingController();
  TextEditingController empNameController = TextEditingController();
  TextEditingController empIdController = TextEditingController();
  TextEditingController empDeptController = TextEditingController();

  //item
  TextEditingController itemNameController = TextEditingController();


  Map<int, String> typeObjectiveMapping = {
    3: 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกพื้นที่การผลิตเพื่อ',  // Production Transfer
    2: 'ขออนุญาตนำสินค้า/สิ่งของเข้า-ออกโรงงานเพื่อ',        // Factory Transfer
    1: 'ขออนุญาตออกนอกโรงงาน',                        // Off-site Permit
  };
  int objTypeSelection = 1;


  // Control Animation Dropdrow Objective Type
  bool isStrechedDropDown = false;

  //DropDown
  List<dynamic> buildingList = []; //Building
  //DropDown selection
  int? selectedBuilding; //Building Selected
  // other Building


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
      List<dynamic> rawListBuilding = await _module.getBuilding();
      buildingList = rawListBuilding
        .map((item) => Map<String, dynamic>.from(item))
        .where((building) {
          return building['building_name'] == 'อาคาร B' || building['building_name'] == 'อาคาร C';
        }).toList();
      this.selectedBuilding = this.buildingList[0]['id'];

      deptList = await _module.getDepartments();

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
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
      if(data['tno_ref'] != null){
        flagUpdateForm = false;
      } else{
        flagUpdateForm = true;
      }

      // logBook
      logBook = data['logBook'] == true;

      //tno
      tno_pass = data['tno_pass'];

      // Sequence Running Number
      formatSequenceRunning = data['sequence_no'] ?? null;

      final rawDateTime = data['datetime_out'];
      expectedDateTimeOut = rawDateTime != null &&
              rawDateTime.toString().isNotEmpty
          ? DateTime.tryParse(rawDateTime.toString())
          : null;

      // Building
      List<dynamic> rawListBuilding = await _module.getBuilding();
      buildingList = rawListBuilding
        .map((item) => Map<String, dynamic>.from(item))
        .where((building) {
          return building['building_name'] == 'อาคาร B' || building['building_name'] == 'อาคาร C';
        }).toList();
      var area = data['area'];
      if (area != null) {
        selectedBuilding = buildingList.firstWhere((b) => b['building_name'] == area)['id'];
      } else {
        selectedBuilding = buildingList[0]['id'];
      }

      //Map Data
      vehicleLicenseController.text = data['vehicle_no'] != null ? data['vehicle_no'] : '';

      outOnly = data['out_only'] == 1;

      //Map Data
      objTypeSelection = data['objective_type'];
      objectiveController.text = data['objective'] != null ? data['objective'] : '';

      List<Employee> copiedPeople = (data['people'] as List<dynamic>)
      .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
      .toList();
      personList = copiedPeople;

      //item_in
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
        'Employee': ['emp_sign', 'emp_at', 'emp_by'],
        'Approved': ['appr_sign', 'appr_at', 'appr_by'],
        'Media': ['media_sign', 'media_at', 'media_by'],
        'Security': ['guard_sign', 'guard_at', 'guard_by'],
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
          section.filePath = await _module.loadImageAsBytes(signValue);
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

      deptList = await _module.getDepartments();

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
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
       empInfo = await _module.getInfoByEmpId(empId);
      if (empInfo.isEmpty) {
        empInfo.clear();
        empNameController.clear();
        empDeptController.clear();
        return false;
      }
      empNameController.text = empInfo['FullName_Thai'] ?? '';
      empDeptController.text = empInfo['DepartmentName_Thai'] ?? '';
      empIdController.text = empId;

      status = true;
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      empInfo.clear();
      empNameController.clear();
      empDeptController.clear();
      empIdController.clear();
    }
    return status;
  }

  Future<String> validateUpload() async {
    final fields = {
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
    if (!signatureSection["Employee"]!.status) {
      return 'กรุณาลงลายเซ็น';
    }
    if (expectedDateTimeOut == null) {
      scrollToSection(inputSectionKey);
      return 'กรุณาเลือกวันที่และเวลาที่คาดว่าจะออก';
    }
    return '';
  }


  // ------------------------------------------------- Person ----------------------------------------------- //
  Future<void> addPersonInList() async {
    try {
      var uuid = Uuid();
      final newEmployee = Employee(
        id: uuid.v4(),
        department: empDeptController.text,
        titleName: empTitleController.text,
        fullName: empNameController.text,
        employeeId: empIdController.text,
        dateTime: AppDateTime.now(),
      );
      personList.add(newEmployee);
      await clearPersonController();
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }


  Future<void> editPersonInList(Employee entry) async {
    try {
      entry.department = empDeptController.text;
      entry.titleName = empTitleController.text;
      entry.fullName = empNameController.text;
      entry.employeeId = empIdController.text;

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

  Future<void> clearPersonController() async {
    empTitleController.clear();
    empNameController.clear();
    empIdController.clear();
    empDeptController.clear();
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
    }
  }

  void editItemTypeList(Map<String, String> entry) {
    entry['item'] = itemNameController.text;
  }

  void itemListClear() {
    listItem_In.clear();
    listItem_Out.clear();
    imageList_In.clear();
    imageList_Out.clear();
  }


  // -------------------------------------------------------------- Insert -------------------------------------------------------------- //
  Future<bool> insertRequestForm() async
  {
    bool status = false;
    try{
      //typForm
      String typeForm = 'EMPLOYEE';

      // ------------------------------ upload Image to server ------------------------------------- //
      final empDate  = (signatureSection['Employee']!.dateTime is DateTime)
          ? signatureSection['Employee']!.dateTime
          : AppDateTime.now();
      final flagDateDoc = DateFormat('yyyy-MM-dd').format(empDate!);
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'EMPLOYEE', flagDateDoc);

      // ------------------------------ Request ------------------------------------- //

      // Building selction
      Map<String, dynamic> buildingData = buildingList.firstWhere((building) => building['id'] == this.selectedBuilding);
          
      // Area
      String area = buildingData['building_name'];


      Map<String, dynamic> dataRequest = {
        'tno_pass': tno_pass,
        'request_type': typeForm,
        'sequence_no': formatSequenceRunning,
        'vehicle_no': vehicleLicenseController.text,
        'out_only': outOnly,
        'datetime_out': expectedDateTimeOut?.toIso8601String(),
        'objective_type': objTypeSelection,
        'obj_desc': typeObjectiveMapping[objTypeSelection] ?? 'ไม่ระบุประเภท',
        'objective': objectiveController.text,
        'building_card': buildingData['building_card'],
        'area': area,
        if (!flagUpdateForm) ...{
          'emp_status': signatureSection['Employee']!.status,
          'emp_sign': signatureSection['Employee']!.fileName,
          'emp_at': signatureSection['Employee']!.dateTime !=null? signatureSection['Employee']!.dateTime.toString(): null,
          'emp_by': signatureSection['Employee']!.by,
        },


        // 'appr_status': signatureSection['Approved']!.status,
        // 'appr_sign': signatureSection['Approved']!.fileName,
        // 'appr_at': signatureSection['Approved']!.dateTime !=null? signatureSection['Approved']!.dateTime.toString(): null,
        // 'appr_by': signatureSection['Approved']!.by,
        // 'media_status': signatureSection['Media']!.status,
        // 'media_sign': signatureSection['Media']!.fileName,
        // 'media_at': signatureSection['Media']!.dateTime !=null? signatureSection['Media']!.dateTime.toString(): null,
        // 'media_by': signatureSection['Media']!.by,
        // 'guard_status': signatureSection['Security']!.status,
        // 'guard_sign': signatureSection['Security']!.fileName,
        // 'guard_at': signatureSection['Security']!.dateTime !=null? signatureSection['Security']!.dateTime.toString(): null,
        // 'guard_by': signatureSection['Security']!.by,

      };

      // print("=========================================================");
      // print(const JsonEncoder.withIndent('  ').convert(dataRequest));
      // print("=========================================================");
      // ------------------------------ Form ------------------------------------- //

      // // Get List name
      var itemInFilenames = filenamesData?['item_in'];
      var itemOutFilenames = filenamesData?['item_out'];

      Map<String, dynamic> dataForm = {
        'tno_pass': tno_pass,
        'visitorType': 'E',
        'people': personList,
        'item_in': itemInFilenames,
        'item_out': itemOutFilenames,
      };
      
      // ------------------------------------------------------------------- //

      if(!flagUpdateForm) {
        status = await _module.insertRequestFormE( dataRequest, dataForm); // Insert
        await _centerController.insertActvityLog('Create employee form: ${tno_pass}');
      } else {
        status = await _module.updateRequestFormE(tno_pass ,dataRequest, dataForm); // Update
        await _centerController.insertActvityLog('Edit employee form: ${tno_pass}');
      }
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return status;
  }


    Future<Map<String, dynamic>?> uploadImageToServer(String tno_pass, String folderName, String date) async {
    Map<String, dynamic> data = {};
    try {

      // =========================
      // 2. Item images
      // =========================
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

      // =========================
      // 3. Approver (OBJECT VERSION)
      // =========================
      //Approver
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

      // =========================
      // 4. Upload payload
      // =========================
      Map<String, List<dynamic>?> dataFileImage = {
        // 'people': visitorSignatureFiles.isEmpty ? null : visitorSignatureFiles, //visitor signature
        'item_in': image_list_in.isEmpty ? null : image_list_in, //item in image
        'item_out': image_list_out.isEmpty ? null : image_list_out, //item out image
        'approver': signatureApprover.isEmpty ? null : signatureApprover, //approver signature
      };

      // Upload image to server
      await _module.uploadImageFiles(tno_pass, folderName, dataFileImage, date); //<---------------------------- upload image to server


      // =========================
      // 6. Item IN
      // =========================
      //prepare item filename
      //item in
      final itemsIN = listItem_In.map((e) => e['item'] as String?).where((item) => item != null && item.trim().isNotEmpty).cast<String>().toList();
      final imagesIN = image_list_in.where((file) => file != null && file.path != null).map((file) => basename(file.path)).toList();
      final Map<String, List<String>> item_In_Filenames = {
        "items": itemsIN,
        "images": imagesIN,
      };

      // =========================
      // 7. Item OUT
      // =========================
      //item out
      final itemsOUT = listItem_Out.map((e) => e['item'] as String?).where((item) => item != null && item.trim().isNotEmpty).cast<String>().toList();
      final imagesOUT = image_list_out.where((file) => file != null && file.path != null).map((file) => basename(file.path)).toList();
      final Map<String, List<String>> item_Out_Filenames = {
        "items": itemsOUT,
        "images": imagesOUT,
      };


      // =========================
      // 8. Approver filenames (OBJECT BASED)
      // =========================
      //prepare approver filename
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

      // =========================
      // 9. Final payload
      // =========================
      data = {
        'item_in': item_In_Filenames.isEmpty ? null : item_In_Filenames,
        'item_out': item_Out_Filenames.isEmpty ? null : item_Out_Filenames,
      };
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
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
