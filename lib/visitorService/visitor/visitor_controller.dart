import 'dart:convert';
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
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/visitor/visitor_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';
import 'package:uuid/uuid.dart';

import 'package:image/image.dart' as img;

import '../../entity/signature_section.dart';
import '../../entity/visitor_profile.dart';

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
  DateTime? datetime_in;

  TextEditingController objectiveController = TextEditingController();
  TextEditingController otherBuildingController = TextEditingController();

  List<Visitor> personList = [];

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

  Map<String, SignatureSection> signatureSection = {
    'Approved': SignatureSection(status: false, label: 'ผู้อนุมัติ'),
    'Media': SignatureSection(status: false, label: 'ผู้ตรวจสอบสื่อ'),
    'Security': SignatureSection(status: false, label: 'รปภ. ป้อมหน้า'),
    'Production': SignatureSection(status: false, label: 'รปภ. อาคาร'),
  };

  //Global SignPad
  final signatureGlobalKey = GlobalKey<SfSignaturePadState>();

  final ImagePicker imagePicker = ImagePicker();
  int limitImageDisplay = 4; //Limit Image Display

  // Departments
  String selectDept = '';
  List<String> deptList = [];

  // Contacts
  TextEditingController contactControl = TextEditingController();
  List<String> contactList = [];

  List<String> siteList = [];
  String? selectedSite;

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<String> validateUpload() async {
    final fields = {
      "กรุณากรอกชื่อบริษัท/นามบุคคล": companyController.text,
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
          .map((person) => person['Card_Id']?.toString()) // ใช้ ?. เพื่อกันเหนี่ยว
          .where((id) => id != null && id != 'null' && id.isNotEmpty) // กรองตัวที่เป็น null หรือคำว่า "null" ออก
          .cast<String>()
          .toList();
      if (cardIdsInDoc.isNotEmpty) {
        cardListFromDoc = await _module.getInfoCardFromDoc(cardIdsInDoc);
      }


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

 
      // Datetime
      if(data['datetime_in'] != null && flagUpdateForm) {
        datetime_in = DateTime.tryParse(data['datetime_in'])?.toLocal();
      }

      // Departments
      deptList = await _module.getDepartments();
      selectDept = data['contact_dept'] != null ? data['contact_dept'] : deptList[0];

      // Contact
      contactList = await _module.getContactByDept(selectDept);
      contactControl.text = data['contact'] != null ? data['contact'] : '';

      // Objective
      objectiveController.text = data['objective'] != null ? data['objective'] : '';

      var uuid = Uuid();
      List<Visitor> copiedPeople = (data['people'] as List<dynamic>)
          .map((e) => Visitor.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      for (var person in copiedPeople) {
        // ใส่ ID ถ้ายังไม่มี
        person.id ??= uuid.v4();
        // Card_Id default
        person.cardId ??= null;
        // DateTime default
        person.dateTime ??= null;

        // Signature convert (String -> Uint8List)
        if (person.signatureFilename != null && person.signatureFilename is String && person.signatureFilename!.isNotEmpty) {
          Uint8List? signatureBytes = await _module.loadImageAsBytes(person.signatureFilename!);
          person.signatureData = signatureBytes;
          person.signatureFilename = null;
        } else {
          person.signatureFilename = null;
          person.signatureData = null;
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
        section.dateTime = data[dateKey] != null ? DateTime.tryParse(data[dateKey])?.toLocal() : null;

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

  List<Map<String, dynamic>> getFilterCardList() {
    final selectedCardIds = personList
        .map((p) => p.cardId)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    return cardList
        .where((card) => !selectedCardIds.contains(card['card_id']))
        .toList();
  }


  Future<void> addPerson() async {
    try {
      var uuid = Uuid();
      final signatureImage = await signatureGlobalKey.currentState!.toImage();
      final byteData = await signatureImage.toByteData(format: ImageByteFormat.png);
      final signatureData = byteData!.buffer.asUint8List();
      final newVisitor = Visitor(
        id: uuid.v4(),
        titleName: titleNameController.text,
        fullName: fullNameController.text,
        cardId: cardIdController.text,
        signatureData: signatureData,
        dateTime: AppDateTime.now(),
      );
      personList.add(newVisitor);

      bool exists = cardListFilter.any( (item) => item['card_id'] == cardIdController.text);
      if (exists) {
        cardListFilter.removeWhere( (item) => item['card_id'] == cardIdController.text);
      }

      await clearPersonController();
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }


  Future<void> editPerson(Visitor entry) async {
    try {
      var signatureData;
      if (signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
        final signatureImage = await signatureGlobalKey.currentState!.toImage();
        final byteData = await signatureImage.toByteData(format: ImageByteFormat.png);
        signatureData = byteData!.buffer.asUint8List();
      }

      // card 
      if (cardIdController.text != entry.cardId) {
        bool isAlreadyInList = cardList.any((item) => item['card_id'] == entry.cardId);
        if(!isAlreadyInList) {
          var oldCardData = cardListFromDoc.firstWhere(
            (item) => item['card_id'] == entry.cardId,
            orElse: () => {},
          );
          if (oldCardData.isNotEmpty) {
            cardList.add(oldCardData);
            cardList.sort((a, b) => a['card_id'].compareTo(b['card_id']));
          }
        }
      }
      entry.cardId = cardIdController.text;
      if (signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
        entry.signatureData = signatureData;
      }

      entry.titleName = titleNameController.text;
      entry.fullName = fullNameController.text;
      entry.dateTime = AppDateTime.now();

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

  Future<void> clearPersonController() async {
    titleNameController.clear();
    fullNameController.clear();
    cardIdController.clear();
    signatureGlobalKey.currentState!.clear();
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


  Future<void> itemListClear() async {
    listItem_In.clear();
    listItem_Out.clear();
    imageList_In.clear();
    imageList_Out.clear();
  }

  Future<void> checkBuildingOther() async {
    Map<String, dynamic> buildingData = buildingList.firstWhere((building) => building['id'] == this.selectedBuilding);
    String type = buildingData['building_card'] ?? '';
    if (type == 'O') {
      this.isExpandedBuilding = true;
    } else {
      this.isExpandedBuilding = false;
    }
  }


  // -------------------------------------------------------------- Insert  -------------------------------------------------------------- //
  Future<bool> insertRequestForm() async
  {
    bool status = false;
    try{
      //typForm
      String typeForm = 'VISITOR';

      DateTime now = AppDateTime.now();
      final visDate  = datetime_in != null
          ? datetime_in
          : now;
      final flagDateDoc = DateFormat('yyyy-MM-dd').format(visDate!);

      // ------------------------------ upload Image to server ------------------------------------- //
      Map<String, dynamic>? filenamesData = await uploadImageToServer(tno_pass,'VISITOR', flagDateDoc);

      // ------------------------------ Request ------------------------------------- //
      // Building selction
      Map<String, dynamic> buildingData = buildingList.firstWhere((building) => building['id'] == this.selectedBuilding);

      // Area
      String area;
      if (isExpandedBuilding) {
        area = otherBuildingController.text;
      } else {
        area = buildingData['building_name'];
      }


      // DateTime
      if(!flagUpdateForm) {
        datetime_in = now;
      }


      Map<String, dynamic> dataRequest = {
        'tno_pass': tno_pass,
        'request_type': typeForm,
        'sequence_no': formatSequenceRunning,
        'company': companyController.text,
        'vehicle_no': vehicleLicenseController.text,
        'datetime_in': datetime_in.toString(),
        'datetime_out': signatureSection['Security']!.dateTime !=null? signatureSection['Security']!.dateTime.toString(): null,
        'contact': contactControl.text,
        'contact_dept': selectDept,
        'objective': objectiveController.text,
        'building_card': buildingData['building_card'],
        'area': area,

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
        // 'prod_status': signatureSection['Production']!.status,
        // 'prod_sign': signatureSection['Production']!.fileName,
        // 'prod_at': signatureSection['Production']!.dateTime !=null? signatureSection['Production']!.dateTime.toString(): null,
        // 'prod_by': signatureSection['Production']!.by,

        'tno_ref': tno_ref,
      };

      // print("=========================================================");
      // print(const JsonEncoder.withIndent('  ').convert(dataRequest));
      // print("=========================================================");
 
      // ------------------------------ Form ------------------------------------- //
      List<Map<String, dynamic>> peopleList = personList.map((e)=> e.toJson()).toList();
      var itemInFilenames = filenamesData?['item_in'];
      var itemOutFilenames = filenamesData?['item_out'];

      // Prepare data
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
        await _centerController.insertActvityLog('Create visitor form: ${tno_pass}');
      } else {
        status = await _module.updateRequestFormV(tno_pass ,dataRequest, dataForm); // Update
        await _centerController.insertActvityLog('Edit visitor form: ${tno_pass}');
      }

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
    return status;
  }

  // Upload Image to Server
  Future<Map<String, dynamic>?> uploadImageToServer(String tno_pass, String folderName, String date) async {
    Map<String, dynamic> data = {};
    try {
      List<File?> visitorSignatureFiles = [];
      for (var person in personList) {
        Uint8List? signatureData = person.signatureData;
        if (signatureData != null) {
          List<String> partsId = person.id!.split('-');
          String lastPart = partsId.last;
          final directory = await getTemporaryDirectory();
          String fileName = 'V_${lastPart}.png';
          person.signatureFilename = fileName;
          final filePath = join(directory.path, fileName);
          final file = File(filePath);
          await file.writeAsBytes(signatureData);
          visitorSignatureFiles.add(file);
        } else {
          visitorSignatureFiles.add(null);
        }
      }

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

      Map<String, List<dynamic>?> dataFileImage = {
        'people': visitorSignatureFiles.isEmpty ? null : visitorSignatureFiles, //visitor signature
        'item_in': image_list_in.isEmpty ? null : image_list_in, //item in image
        'item_out': image_list_out.isEmpty ? null : image_list_out, //item out image
        'approver': signatureApprover.isEmpty ? null : signatureApprover, //approver signature
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

      data = {
        'visitor': visitorFilenames.isEmpty ? null : visitorFilenames,
        'item_in': item_In_Filenames.isEmpty ? null : item_In_Filenames,
        'item_out': item_Out_Filenames.isEmpty ? null : item_Out_Filenames,
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
