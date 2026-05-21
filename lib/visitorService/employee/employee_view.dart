import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/config/api_config.dart';

import '../../utils/BaseScaffold.dart';
import '../../utils/CustomDIalog.dart';
import '../../entity/employee_profile.dart';
import '../../entity/signature_section.dart';
import 'employee_controller.dart';

class EmployeePage extends StatelessWidget {
  final Map<String, dynamic>? documentData;

  const EmployeePage({
    super.key,
    this.documentData,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'พนักงาน',
      child: EmployeeContent(
        documentData: documentData,
      ),
    );
  }
}

class EmployeeContent extends StatefulWidget {
  final Map<String, dynamic>? documentData;

  const EmployeeContent({
    super.key,
    this.documentData,
  });

  @override
  State<EmployeeContent> createState() => _EmployeeContentState();
}

class _EmployeeContentState extends State<EmployeeContent>
    with SingleTickerProviderStateMixin {
  EmployeeController _con = EmployeeController();

  Color? _cancelBtnColor = Colors.red;
  Color? _acceptBtnColor = Colors.blue;
  double _fontSize = ApiConfig.fontSize;
  bool _isPhoneScale = false;
  final FocusNode _focusNode = FocusNode();
  

  AnimationController? _animateController;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    prepareForm();
    prepareAnimations();
 
  }

  void prepareForm() async {
    if (widget.documentData != null) {
      final data = widget.documentData;
      await _con.prepareLoadForm(context, data);
    } else {
      await _con.prepareNewForm(context);
    }
    setState(() {});
  }

  void prepareAnimations() {
    _animateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
        parent: _animateController!, curve: Curves.fastOutSlowIn);
  }

  @override
  void dispose() {
    _animateController!.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _fontSize = ApiConfig.getFontSize(context);
    _isPhoneScale = ApiConfig.getPhoneScale(context);
    //Back ground
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.orange,
          Colors.orange,
        ],
      )),
      child: _getPageContent(context),
    );
  }

  Widget _getPageContent(BuildContext context) {
    final ScrollController controller = ScrollController();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        margin:
            EdgeInsets.all(MediaQuery.of(context).size.width > 799 ? 14 : 7),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
            scrollbars: false,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IgnorePointer(
                    ignoring: _con.logBook,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tno Display
                        if (_con.flagUpdateForm && (_con.formatSequenceRunning?.isNotEmpty ?? false)) ...[
                          Container(
                            key: _con.inputSectionKey,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('No.${_con.formatSequenceRunning}',
                                    style: TextStyle(
                                        fontSize: _fontSize + 4,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                        
                        SizedBox(
                            height: 10,
                          ),

                        //DropDown Type Objective
                        Text(
                          "ประเภทของวัตถุประสงค์ :",
                          style: TextStyle(
                              fontSize: _fontSize, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        dropDownTypeObjective(),
                        
                        SizedBox(
                          height: 30,
                        ),
                        
                        // Objective
                        InputField(
                          title: 'วัตถุประสงค์ :',
                          hint: '',
                          controller: _con.objectiveController,
                          descriptText: true,
                          maxLength: 400,
                        ),
                        
                        SizedBox(
                          height: 25,
                        ),
                        
                        FractionallySizedBox(
                          widthFactor: 0.4, // 40% width
                          alignment: Alignment.centerLeft,
                          child: InputField(
                            title: 'เลขทะเบียนรถ :',
                            hint: '*เช่น ทส1234',
                            controller: _con.vehicleLicenseController,
                            maxLength: 24,
                          ),
                        ),
                        
                      SizedBox(height: 15),

                      if(_con.objTypeSelection == 1) ...[
                        Column(
                          children: [
                            RadioListTile<bool>(
                              title: Text("ไปและกลับ", style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold)),
                              value: false,
                              groupValue: _con.outOnly,
                              activeColor: Colors.orange,
                              onChanged: (_) {
                                setState(() {
                                  _con.outOnly = false;
                                });
                              },
                            ),

                            RadioListTile<bool>(
                              title: Text("ไม่กลับ", style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold)),
                              value: true,
                              groupValue: _con.outOnly,
                              activeColor: Colors.orange,
                              onChanged: (_) {
                                setState(() {
                                  _con.outOnly = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 15),
                       Container(
                          key: _con.buildingSectionKey,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text('บริเวณ : ', style: TextStyle(color: Colors.black, fontSize: _fontSize, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 3,),
                              dropDownBuilding(_con.buildingList),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        //Employee
                        Container(
                          key: _con.personSectionKey,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.groups,
                                            color: Colors.black,
                                            size: 50,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "รายชื่อพนักงาน",
                                            style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(
                                  color: Colors.black,
                                  thickness: 1,
                                  height: 10,
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: popUpAddPerson,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 5,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.group_add,
                                              color: Colors.white, size: 24),
                                          SizedBox(width: 8),
                                          Text(
                                            "เพิ่ม", // Button text
                                            style: TextStyle(
                                              fontSize: _fontSize - 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "${_con.personList.length}",
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange),
                                    ),
                                  ],
                                ),
                        
                                SizedBox(height: 10),
                        
                                //Show Person List
                                personListGenerate2(),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(
                          height: 30,
                        ),
                       
                        //Item In/Out
                        Container(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_motion_rounded,
                                            color: Colors.black,
                                            size: 50,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            "นำสิ่งของ เข้า/ออก",
                                            style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                
                                _contentItemList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                          height: 15,
                        ),
                   if (!_con.flagUpdateForm) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                popUpSignatureApproved();
                              },
                              splashColor: Colors.orange.withOpacity(0.3),
                              highlightColor: Colors.orange.withOpacity(0.1),
                              child: Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.orange,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 50,
                                      color: Colors.orange,
                                    ),
                                    Text(
                                      "ลงชื่อ",
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 30),

                  if (!_con.logBook)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          // Makes button take up full available width
                          child: ElevatedButton(
                            onPressed: () async {
                              String valiMessage = await _con.validateUpload();
                              if (valiMessage.isNotEmpty) {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.error(
                                    backgroundColor: Colors.red.shade700,
                                    icon: Icon(Icons.sentiment_very_satisfied,
                                        color: Colors.red.shade900, size: 120),
                                    message: valiMessage,
                                  ),
                                );
                              } else {
                                bool uploadSuccess = await _con.insertRequestForm();
                                if (uploadSuccess) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.success(
                                      backgroundColor: Colors.green.shade500,
                                      icon: Icon(Icons.sentiment_very_satisfied,
                                          color: Colors.green.shade600,
                                          size: 120),
                                      message: "กรอกเอกสารสำเร็จ",
                                    ),
                                  );
                                  Future.delayed(const Duration(seconds: 1), () {
                                     if(!_con.flagUpdateForm) {
                                        GoRouter.of(context).pushReplacement('/home');
                                      } else {
                                        GoRouter.of(context)..pop()..pop()..pushReplacement('/search');
                                      }
                                  });
                                } else {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(
                                      backgroundColor: Colors.red.shade700,
                                      icon: Icon(Icons.sentiment_very_satisfied,
                                          color: Colors.red.shade900, size: 120),
                                      message: "ส่งเอกสารไม่สำเร็จ",
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 16),
                              backgroundColor:
                                  Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'ส่งเอกสาร',
                              style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void popUpSignatureApproved() {
    FocusScope.of(context).unfocus();
    List<String> sectionKeys = _con.signatureSection.keys.toList();
    final ScrollController controller = ScrollController();
    final FixedExtentScrollController menuRowController = FixedExtentScrollController();

    // initial value
    int currentIndex = 0;


    SignatureSection currentSection = _con.signatureSection[sectionKeys[currentIndex]]!;
    TextEditingController signaturesByDisplay = TextEditingController(text: currentSection.by ?? '');

    // =========================
    // LOCK
    // =========================
    Map<String, bool> signatureLockMap = {};
    for (var key in sectionKeys) {
      signatureLockMap[key] = _con.signatureSection[key]?.filePath != null;
    }

    // =========================
    // CLEAR UI ONLY
    // =========================
    void clearStateSignature() async {
      currentSection.status = false;
      currentSection.filePath = null;
      currentSection.dateTime = null;
      currentSection.by = null;

      signaturesByDisplay.clear();


      if (_con.signatureGlobalKey.currentState?.toPathList().isNotEmpty == true) {
        _con.signatureGlobalKey.currentState!.clear();
      }
    }

    // =========================
    // LOAD SECTION (RESET DRAFT)
    // =========================
    void setStateSignature() {
      final key = sectionKeys[currentIndex];
      currentSection = _con.signatureSection[key]!;

      signaturesByDisplay.text = currentSection.by ?? '';
    }

    // =========================
    // STAMP (DRAFT ONLY)
    // =========================
    Future<void> stampSignatureApprove(DateTime dateTime, GlobalKey<SfSignaturePadState> signature) async {
      final signatureImage = await signature.currentState!.toImage();
      final byteData = await signatureImage.toByteData(format: ImageByteFormat.png);
      final signatureData = byteData!.buffer.asUint8List();

      final key = sectionKeys[currentIndex];

      currentSection.status = true;
      currentSection.filePath = signatureData;
      currentSection.dateTime = dateTime;
      currentSection.by = signaturesByDisplay.text;

      setState(() {
        signatureLockMap[key] = true;
      });
    }


    // =========================
    // ARROW NAVIGATION
    // =========================
    void arrowController(String turn, StateSetter setStateDialog) {
       if (turn == 'R') {
          currentIndex = (currentIndex + 1) % sectionKeys.length;
        } else {
          currentIndex = (currentIndex - 1 + sectionKeys.length) % sectionKeys.length;
        }
        setStateSignature();
        setStateDialog(() {});
        menuRowController.animateToItem(currentIndex, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    }


    // =========================
    // CHECK SIGNATURE
    // =========================
    bool hasSignature() {
    return currentSection.filePath != null &&
          currentSection.dateTime != null &&
          currentSection.by != null;
}

    //HeaderMenu
    Widget _headerMenu(double screenWidth, StateSetter setStateDialog) {
      final filteredKeys = !_con.flagUpdateForm
            ? sectionKeys.where((e) => e.toLowerCase() == "employee").toList()
            : sectionKeys;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
            border: Border.all(
              color: Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
        ),
        child: screenWidth < 799
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    IconButton(
                      onPressed: () {
                        arrowController('L', setStateDialog);
                      },
                      icon: Icon(
                        Icons.arrow_left,
                        size: 40,
                      ),
                    ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 75.0,
                      ),
                      child: ListWheelScrollView.useDelegate(
                        controller: menuRowController,
                        itemExtent: 150.0,
                        physics: NeverScrollableScrollPhysics(),
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey<int>(index),
                                width: 150,
                                height: 50,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  filteredKeys[index],
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: _fontSize),
                                ),
                              ),
                            );
                          },
                          childCount: filteredKeys.length,
                        ),
                      ),
                    ),
                  ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_right,
                        size: 40,
                      ),
                      onPressed: () {
                        arrowController('R', setStateDialog);
                      },
                    ),
                ],
              )
            : 
            Container(
                padding: EdgeInsets.only(bottom: 15),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  destinations: filteredKeys.asMap().entries.map((entry) {
                    int index = entry.key;
                    String sectionLabel = entry.value;
                    BorderRadius borderRadius;
                    bool _isPressed = currentIndex == index;

                    // Define border radius for first and last items
                    if (index == 0) {
                      borderRadius = BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        bottomLeft: Radius.circular(20.0),
                      );
                    } else if (index ==
                        _con.signatureSection.length - 1) {
                      borderRadius = BorderRadius.only(
                        topRight: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      );
                    } else {
                      borderRadius = BorderRadius.zero;
                    }

                    return Container(
                      color: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          color: _isPressed
                              ? Colors.transparent
                              : Colors.transparent,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  currentIndex = index;
                                  setStateSignature();
                                  setStateDialog(() {});
                                });
                              },
                              onTapDown: (TapDownDetails details) {
                                setState(() {
                                  currentIndex = index;
                                });
                              },
                              onTapCancel: () {
                                setState(() {
                                  currentIndex = -1;
                                });
                              },
                              splashColor:
                                  Colors.orange.shade600.withOpacity(0.3),
                              highlightColor: Colors.transparent,
                              borderRadius: borderRadius,
                              child: Container(
                                constraints: BoxConstraints(maxHeight: 80),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.assignment_outlined,
                                      size: 40,
                                      color: _isPressed
                                          ? Colors.orange
                                          : Colors.black,
                                    ),
                                    SizedBox(height: 5),
                                    Flexible(
                                      child: Text(
                                        sectionLabel,
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          color: _isPressed
                                              ? Colors.orange
                                              : Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),


      );
    }

    Widget _signPad(StateSetter setStateDialog) {
      final key = sectionKeys[currentIndex];
      return 
          // Signature Card
          IgnorePointer(
            ignoring: _con.logBook,
            child: Container(
              width: double.infinity,
              child: Card(
                color: Colors.white,
                elevation: 6.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.black.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // =========================
                          // LABEL
                          // =========================
                          Text( currentSection.label,
                            style: TextStyle(
                              fontSize: _fontSize + 4,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // =========================
                      // SIGNATURE AREA
                      // =========================
                      Stack(
                                children: [
                                   // Signature Pad
                      Container(
                        constraints: BoxConstraints(maxHeight: 250),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: currentSection.filePath != null
                            ? Image.memory(currentSection.filePath!)
                            : SfSignaturePad(
                                key: _con.signatureGlobalKey,
                                backgroundColor: Colors.transparent,
                                strokeColor: Colors.black,
                                minimumStrokeWidth: 3.0,
                                maximumStrokeWidth: 6.0,
                              ),
                      ),

                                  // =========================
                                  // RESET BUTTON
                                  // =========================
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                       onTap: () {
                                          if (hasSignature()) {
                                          warningDialog('คุณต้องการจะลบลายเซ็น ${sectionKeys[currentIndex]} ใช่หรือไม่? การกระทำนี้จะไม่สามารถย้อนกลับมาแก้ไขได้',
                                              () {
                                            setState(() {
                                              currentSection.status = false;
                                              currentSection.filePath = null;
                                              currentSection.dateTime = null;
                                              currentSection.by = null;

                                              // ล้าง UI
                                              clearStateSignature();
                                              // unlock
                                              signatureLockMap[key] = false;

                                              Navigator.pop(context);
                                              setStateDialog(() {});
                                              });
                                            }
                                          );
                                          } else if (_con.signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
                                                _con.signatureGlobalKey.currentState!.clear();
                                          }
                                        },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.black.withOpacity(
                                            0.5),
                                        child: Icon(
                                          Icons.cached,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),


                      SizedBox(
                        height: 10,
                      ),
                      // =========================
                      // NAME FIELD
                      // =========================
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 52,
                                margin: const EdgeInsets.only(top: 2.5),
                                padding: const EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  onEditingComplete: () {
                                    FocusScope.of(context).unfocus();
                                  },
                                  cursorColor: Colors.orange,
                                  readOnly: signatureLockMap[sectionKeys[currentIndex]] ?? false,
                                  controller: signaturesByDisplay,
                                  maxLines: null,
                                  minLines: 1,
                                  decoration: const InputDecoration(
                                    hintText: 'ลงชื่อ*',
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(fontSize: _fontSize - 2),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),
                            // =========================
                            // SAVE BUTTON
                            // =========================
                            ElevatedButton(
                              onPressed: !hasSignature()
                                  ? () async {
                                      final pad = _con.signatureGlobalKey.currentState;
                                      if (pad != null && pad.toPathList().isNotEmpty && signaturesByDisplay.text.isNotEmpty) {
                                        await stampSignatureApprove(AppDateTime.now(), _con.signatureGlobalKey);
                                        setStateDialog(() {
                                          signatureLockMap[key] = true;
                                        });
                                      } else {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            backgroundColor: Colors.red.shade700,
                                            icon: Icon(
                                              Icons.sentiment_very_satisfied,
                                              color: Colors.red.shade900,
                                              size: 120,
                                            ),
                                            message: "กรุณากรอกข้อมูลให้ครบถ้วน",
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _acceptBtnColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.save_as_rounded,
                                    color: Colors.white,
                                    size: _fontSize,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'บันทึก',
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

            
                      SizedBox(height: 10),

                      // =========================
                      // DATE / TIME
                      // =========================
                      Row(
                        children: [
                          Expanded(
                            child: InputField(
                              title: 'เวลา',
                              hint: '',
                              controller: TextEditingController(
                                  text: currentSection.dateTime == null
                                      ? ''
                                      : DateFormat('HH:mm')
                                          .format(currentSection.dateTime!)),
                              widget: IgnorePointer(
                                ignoring: true,
                                child: MouseRegion(
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.access_time_rounded,
                                        color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: InputField(
                              title: 'วันที่',
                              hint: '',
                              controller: TextEditingController(
                                  text: currentSection.dateTime == null
                                      ? ''
                                      : DateFormat('yyyy-MM-dd')
                                          .format(currentSection.dateTime!)),
                              widget: IgnorePointer(
                                ignoring: true,
                                child: MouseRegion(
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.calendar_month,
                                        color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
    }

    //show Dialog
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (BuildContext context, Animation<double> animation1,
          Animation<double> animation2) {
        return Container();
      },
      transitionBuilder: (context, a1, a2, widget) {
        double screenWidth = MediaQuery.of(context).size.width;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final hasFocus = FocusManager.instance.primaryFocus?.hasFocus ?? false;
            final isTextFieldFocused = FocusManager.instance.primaryFocus is! FocusScopeNode;
            if (hasFocus && isTextFieldFocused) {
              FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
            } else {
              Navigator.of(context).pop(); // Close dialog 
            }
          },
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0).animate(a1),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.6, end: 1.0).animate(a1),
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.all(16.0),
                contentPadding: EdgeInsets.all(0),
                content: StatefulBuilder(
                  builder:
                      (BuildContext context, StateSetter setStateDialog) {
                    return Container(
                      width: double.maxFinite,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                          },
                          scrollbars: false,
                        ),
                        child: Padding(
                          padding: screenWidth > 799
                              ? const EdgeInsets.all(16.0)
                              : const EdgeInsets.all(10.0),
                          child: SingleChildScrollView(
                            controller: controller,
                            child: Column(
                              children: [
                                if (_con.flagUpdateForm) ...[
                                  _headerMenu(screenWidth, setStateDialog),
                                  SizedBox(height: 15),
                                ],
                                _signPad(setStateDialog),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  //Function to take photo with camera
  Future _pickImageFromCamera(int index, List<File?> _imageList) async {
    final pickedFile = await _con.imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        if (_imageList.length < _con.limitImageDisplay) {
          if (index < _imageList.length) {
            _imageList[index] = File(pickedFile.path);
          } else {
            _imageList.add(File(pickedFile.path));
          }
        } else {
          _imageList[index] = File(pickedFile.path);
        }
      });
    } else {
      AppLogger.debug("No Image Picked");
    }
  }

  void popUpEditItem(Map<String, String> entry) {
    _con.itemNameController.text = entry['item']!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
          },
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: EdgeInsets.zero),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              'แก้ไขข้อมูลสิ่งของ', // Title
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Ensures proper height
                        children: [
                          Text(
                            'ชื่อสิ่งของ:',
                            style: TextStyle(
                                fontSize: _fontSize,
                                fontWeight: FontWeight.bold),
                          ),
                          InputField(
                            title: '',
                            hint: 'แก้ไขชื่อสิ่งของ',
                            controller: _con.itemNameController,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _con.itemNameController.clear();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cancelBtnColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'ยกเลิก',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(width: 10), // Space between buttons
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_con
                                    .itemNameController.text.isEmpty) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(
                                      backgroundColor: Colors.red.shade700,
                                      icon: Icon(Icons.sentiment_very_satisfied,
                                          color: Colors.red.shade900,
                                          size: 120),
                                      message: 'กรุณากรอกชื่อสิ่งของ',
                                    ),
                                  );
                                } else {
                                  _con.editItemTypeList(entry);
                                  setState(() {});
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _acceptBtnColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'บันทึก',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _con.itemNameController.clear();
    });
  }

  //Item list generate by Widget
  Widget _itemListGenerate(List<Map<String, String>> itemList, String type) {
  return itemList.isNotEmpty
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: itemList.map((entry) {
            return Card(
              color: Colors.orange.shade50,
              margin: EdgeInsets.symmetric(vertical: 5),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Slidable(
                  key: ValueKey(entry['item']),
                  startActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.20,
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) => popUpEditItem(entry),
                        backgroundColor: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        child: Icon(
                              Icons.edit_document,
                              size: 30,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.20,
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) {
                          warningDialog(
                            'ต้องการลบรายการ ${entry['item']} ใช่หรือไม่?',
                            () {
                              setState(() {
                                if (type == 'in') {
                                  _con.listItem_In.remove(entry);
                                } else {
                                  _con.listItem_Out.remove(entry);
                                }
                              });
                              Navigator.pop(this.context);
                            },
                          );
                        },
                        backgroundColor: Colors.red,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: Icon(
                              Icons.delete,
                              size: 30,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          color: Colors.orange,
                          size: 40,
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            '${entry['item']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )
      : Container();
}


  //Function Delete Image
  void _deleteImage(int index, List<File?> _imageList) {
    setState(() {
      _imageList.removeAt(index);
    });
  }

  void popUpAddItem(String type) {
    String header = type == 'in' ? 'นำเข้า' : 'นำออก';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: EdgeInsets.zero),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              '$header', // Title
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Body Content
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ชื่อสิ่งของ:',
                            style: TextStyle(
                                fontSize: _fontSize,
                                fontWeight: FontWeight.bold),
                          ),
                          InputField(
                            title: '',
                            hint: '',
                            controller: _con.itemNameController,
                          ),
                        ],
                      ),
                    ),

                    // Full-Width "เพิ่ม" & "ยกเลิก" Buttons
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _con.itemNameController.clear();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cancelBtnColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'ยกเลิก',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_con
                                    .itemNameController.text.isEmpty) {
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(
                                      backgroundColor: Colors.red.shade700,
                                      icon: Icon(Icons.sentiment_very_satisfied,
                                          color: Colors.red.shade900,
                                          size: 120),
                                      message: 'กรุณากรอกชื่อสิ่งของ',
                                    ),
                                  );
                                } else {
                                  await _con.addItemTypeList(type);
                                  setState(() {});
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _acceptBtnColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'เพิ่ม',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //Function create content item in/out display by list
  Widget _contentItemList() {
    return Column(
      children: [
        Row(
          children: [
            Flexible(
              flex: 1,
              child: Column(
                children: [
                  Row(children: [Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),],),
                  // Button add Item IN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          ElevatedButton(
                        onPressed: () => popUpAddItem('out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                        ),
                        child: Icon(Icons.add_box_outlined,
                            color: Colors.white, size: 24),
                      ),
                      SizedBox(
                              width: 10,
                            ),
                            Text(
                              '-  นำออก',
                              style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      Text(
                        "${_con.listItem_Out.length} : ${_con.imageList_Out.length}",
                        style: TextStyle(
                            fontSize: _fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 10,
                  ),

                  
                  // Build the item list for "Items In"
                  _itemListGenerate(_con.listItem_Out, 'out'),
                  SizedBox(
                    height: 20,
                  ),
                  _contentItemImage(_con.imageList_Out),

                  SizedBox(
                    height: 10,
                  ),

                   Row(children: [Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),],),
                  
                  // Button add Item IN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(children: [
                        ElevatedButton(
                        onPressed: () => popUpAddItem('in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.all(0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                        ),
                        child: Icon(Icons.add_box_outlined,
                            color: Colors.white, size: 24),
                      ),
                      SizedBox(
                              width: 10,
                            ),
                            Text(
                              '-  นำเข้า',
                              style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.bold),
                            ),
                      ],),




                      Text(
                        "${_con.listItem_In.length} : ${_con.imageList_In.length}",
                        style: TextStyle(
                            fontSize: _fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 10,
                  ),
                  // Build the item list for "Items In"
                  _itemListGenerate(_con.listItem_In, 'in'),
                  SizedBox(
                    height: 20,
                  ),
                  _contentItemImage(_con.imageList_In),
                  
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  //Image Function
  // Function to pick image from gallery
  Future _pickImageFromGallery(int index, List<File?> _imageList) async {
    final pickedFile = await _con.imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        if (_imageList.length < _con.limitImageDisplay) {
          if (index < _imageList.length) {
            _imageList[index] = File(pickedFile.path);
          } else {
            _imageList.add(File(pickedFile.path));
          }
        } else {
          _imageList[index] = File(pickedFile.path);
        }
      });
    } else {
      AppLogger.debug("No Image Picked");
    }
  }

  //Function create frame for picker image by widget
  Widget _buildImagePicker(File? _image, int index, List<File?> _imageList) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              _pickImageFromGallery(index, _imageList);
            },
            child: Container(
                height: 200,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.hardEdge,
                child: _image != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        _image.absolute,
                        key: ValueKey(_image.absolute.path + AppDateTime.now().millisecondsSinceEpoch.toString()),
                        fit: BoxFit.cover,
                      ),
                    )
                    : Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 30,
                        ),
                      )),
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () => _pickImageFromCamera(index, _imageList),
                  icon: Icon(Icons.camera,
                      color: const Color.fromARGB(255, 44, 44, 44), size: 40)),
              SizedBox(
                width: 30,
              ),
              IconButton(
                  onPressed: () {
                    if(_imageList.isNotEmpty && _imageList[index] != null) {
                      warningDialog('คุณต้องการจะลบรูปภาพใช่หรือไม่?', () {
                                            setState(() {
                                              _deleteImage(index, _imageList);
                                              Navigator.of(context).pop();
                                            });
                                          });
                    }
                  },
                  icon: Icon(Icons.delete, color: _cancelBtnColor, size: 40)
                ),
            ],
          ),
        ],
      ),
    );
  }

  //Function create content item in/out display by image
  Widget _contentItemImage(List<File?> _imageList) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      child: Column(
        children: [
          Center(
            child: Text(
              "${_imageList.length}/${_con.limitImageDisplay}",
              style: TextStyle(
                  fontSize: _fontSize + 2, fontWeight: FontWeight.bold),
            ),
          ),
          if (_imageList.isEmpty) ...[
            Center(
              child: _buildImagePicker(null, 0, _imageList),
            ),
          ] else ...[
            if (screenWidth < 799) ...[
              Column(
                children: [
                  ..._imageList.asMap().entries.map((entry) {
                    int index = entry.key;
                    File? image = entry.value;
                    return _buildImagePicker(image, index, _imageList);
                  }).toList(),
                  if (_imageList.length < _con.limitImageDisplay) ...[
                    _buildImagePicker(null, _imageList.length + 1, _imageList),
                  ],
                ],
              ),
            ] else if (_imageList.length <= _con.limitImageDisplay) ...[
              GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _imageList.length < _con.limitImageDisplay
                      ? _imageList.length + 1
                      : _imageList.length,
                  itemBuilder: (context, index) {
                    File? image;
                    if (index < _imageList.length) {
                      image = _imageList[index];
                    } else {
                      image = null;
                    }
                    return _buildImagePicker(image, index, _imageList);
                  }),
            ],
          ],
        ],
      ),
    );
  }


  void _clearPersonInfoController() {
    _con.empNameController.clear();
    _con.empIdController.clear();
    _con.signatureGlobalKey.currentState!.clear();
  }

  void popUpEditPerson2(Employee  entry) {
    _con.empTitleController.text = entry.titleName;
    _con.empNameController.text = entry.fullName;
    _con.empIdController.text = entry.employeeId;
    _con.empDeptController.text = entry.department;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height *  (_isPhoneScale ? 0.55 : 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Section with Close Button
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors
                                .orange,
                            borderRadius: BorderRadius.vertical(
                                top:
                                    Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              'รายละเอียด', // Title
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Body Content with Scrollable View
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .onDrag, // Dismiss keyboard on scroll
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔹 คอลัมน์ซ้าย (Dropdown)
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'คำนำหน้า:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize,
                                          ),
                                        ),
                                        SizedBox(height: 2.5),
                                        dropDownTitleName(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),

                                  // 🔹 ช่องกรอกรหัสพนักงาน
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'รหัสพนักงาน:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize,
                                          ),
                                        ),
                                        SizedBox(height: 2.5),
                                        TextFormField(
                                          controller: _con.empIdController,
                                          decoration: InputDecoration(
                                            hintText: 'ค้นหา...',
                                            hintStyle: TextStyle(
                                              fontSize: _fontSize - 4,
                                              color: Colors.blue,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            isDense: true,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                Icons.person_search,
                                                color: Colors.blue,
                                                size: _fontSize + 8,
                                              ),
                                              onPressed: () async {
                                                bool status = await _con
                                                    .searchInfoByPid(_con.empIdController.text);
                                                if (!status) {
                                                  showTopSnackBar(
                                                    Overlay.of(context),
                                                    CustomSnackBar.error(
                                                      backgroundColor: Colors.red.shade700,
                                                      icon: Icon(
                                                        Icons.sentiment_very_satisfied,
                                                        color: Colors.red.shade900,
                                                        size: 120,
                                                      ),
                                                      message: 'ไม่พบข้อมูลพนักงาน',
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.red, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.red, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'กรุณาระบุรหัสพนักงาน';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Name
                              InputField(
                                title: 'ชื่อ-สกุล:',
                                hint: '',
                                controller: _con.empNameController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Employe ID
                              InputField(
                                title: 'แผนก:',
                                hint: '',
                                controller: _con.empDeptController,
                                // isRequired: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Full-Width "เพิ่ม" Button
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _con.clearPersonController();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cancelBtnColor,
                                padding: EdgeInsets.symmetric(
                                    vertical: 14), // Button height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'ยกเลิก',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          SizedBox(width: 10), // Space between buttons

                          // Add Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _con.editPersonInList(entry);
                                setState(() {});
                                Navigator.of(context).pop();
                                await _con.clearPersonController();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _acceptBtnColor,
                                padding: EdgeInsets.symmetric(
                                    vertical: 14), // Button height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'เพิ่ม',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


 Widget personListGenerate2() {
  return _con.personList.isNotEmpty
      ? Column(
          children: _con.personList.map((Employee entry) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 5),
              color: Colors.orange.shade50,
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Slidable(
                  key: ValueKey(entry.employeeId),
                  startActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.20,
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) => popUpEditPerson2(entry),
                        backgroundColor: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_document,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'แก้ไข',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  endActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.20,
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) {
                          warningDialog(
                            'ต้องการลบข้อมูลรายการของ ${entry.titleName} ${entry.fullName} ใช่หรือไม่?',
                            () {
                              setState(() {
                                _con.personList.remove(entry);
                              });
                              Navigator.pop(this.context);
                            },
                          );
                        },
                        backgroundColor: Colors.red,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_remove_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                            Text(
                              'ลบ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.orange,
                                ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.titleName} ${entry.fullName}',
                                      style: TextStyle(
                                        fontSize: _fontSize - 2,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: 8),
                                    if(!_isPhoneScale) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'รหัสพนักงาน : ${entry.employeeId}',
                                            style: TextStyle(
                                              fontSize: _fontSize - 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          if(entry.department
                                              .trim()
                                              .isNotEmpty) ...[
                                            Text(
                                            'แผนก : ${entry.department}',
                                              style: TextStyle(
                                                fontSize: _fontSize - 2,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                          Container(),
                                          Container(),
                                        ],
                                      ),
                                    ] else ...[
                                      Text(
                                          'รหัสพนักงาน : ${entry.employeeId}',
                                          style: TextStyle(
                                            fontSize: _fontSize - 2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        SizedBox(height: 5,),
                                         if(entry.department
                                          .trim()
                                          .isNotEmpty) ...[
                                          Text(
                                          'แผนก : ${entry.department}',
                                            style: TextStyle(
                                              fontSize: _fontSize - 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                    ],
                                    
                                  ],
                                ),
                              ),
                            ],
                          ),
                         
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        )
      : Container();
}




  void popUpAddPerson() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: EdgeInsets.zero),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height *  (_isPhoneScale ? 0.55 : 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.vertical(
                                top:
                                    Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              'รายละเอียด',
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .onDrag,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🔹 คอลัมน์ซ้าย (Dropdown)
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'คำนำหน้า:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize,
                                          ),
                                        ),
                                        SizedBox(height: 2.5),
                                        dropDownTitleName(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),

                                  // 🔹 ช่องกรอกรหัสพนักงาน
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'รหัสพนักงาน:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize,
                                          ),
                                        ),
                                        SizedBox(height: 2.5),
                                        TextFormField(
                                          controller: _con.empIdController,
                                          decoration: InputDecoration(
                                            hintText: 'ค้นหา...',
                                            hintStyle: TextStyle(
                                              fontSize: _fontSize - 4,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            isDense: true,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                Icons.person_search,
                                                color: Colors.blue,
                                                size: _fontSize + 8,
                                              ),
                                              onPressed: () async {
                                                bool status = await _con
                                                    .searchInfoByPid(_con.empIdController.text);
                                                if (!status) {
                                                  showTopSnackBar(
                                                    Overlay.of(context),
                                                    CustomSnackBar.error(
                                                      backgroundColor: Colors.red.shade700,
                                                      icon: Icon(
                                                        Icons.sentiment_very_satisfied,
                                                        color: Colors.red.shade900,
                                                        size: 120,
                                                      ),
                                                      message: 'ไม่พบข้อมูลพนักงาน',
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.red, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.red, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'กรุณาระบุรหัสพนักงาน';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Name
                              InputField(
                                title: 'ชื่อ-สกุล:',
                                hint: '',
                                controller: _con.empNameController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Employe ID
                              InputField(
                                title: 'แผนก:',
                                hint: '',
                                controller: _con.empDeptController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                          
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Full-Width "เพิ่ม" Button
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _con.clearPersonController();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cancelBtnColor,
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'ยกเลิก',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),

                          SizedBox(width: 10),

                          // Add Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_con.empNameController.text.isEmpty ||
                                    _con.empIdController.text.isEmpty) {
                                  setState(() {});
                                  showTopSnackBar(
                                    Overlay.of(context),
                                    CustomSnackBar.error(
                                      backgroundColor: Colors.red.shade700,
                                      icon: Icon(Icons.sentiment_very_satisfied,
                                          color: Colors.red.shade900,
                                          size: 120),
                                      message: "กรุณากรอกข้อมูลให้ครบถ้วน",
                                    ),
                                  );
                                } else {
                                  await _con.addPersonInList();
                                  setState(() {});
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _acceptBtnColor,
                                padding: EdgeInsets.symmetric(
                                    vertical: 14), // Button height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'เพิ่ม',
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget dropDownTypeObjective() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xffbbbbbb)),
                  borderRadius: BorderRadius.all(Radius.circular(27)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _con.isStrechedDropDown =
                              !_con.isStrechedDropDown;
                          if (_con.isStrechedDropDown) {
                            _animateController!.forward();
                          } else {
                            _animateController!.reverse();
                          }
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xffbbbbbb)),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _con.typeObjectiveMapping[_con.objTypeSelection] ?? "",
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: _fontSize),
                              ),
                            ),
                            Icon(_con.isStrechedDropDown
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizeTransition(
                      sizeFactor: _animation!,
                      axisAlignment: -1.0,
                      child: Container(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _con.typeObjectiveMapping.length,
                          itemBuilder: (context, index) {
                            int objectiveKey = _con.typeObjectiveMapping.keys.elementAt(index);
                            String objectiveValue = _con.typeObjectiveMapping.values.elementAt(index);
                            return RadioListTile<int>(
                              title: Text(
                                objectiveValue,
                                style: TextStyle(
                                    fontSize: _fontSize),
                              ),
                              value: objectiveKey,
                              groupValue: _con.objTypeSelection,
                              activeColor: Colors.orange,
                              onChanged: (int? val) {
                                setState(() {
                                  _con.objTypeSelection = val!;
                                  _con.isStrechedDropDown = false;
                                  _animateController!.reverse();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget dropDownBuilding(List<dynamic> _listBuilding) {
    return DropdownMenu(
      requestFocusOnTap: false,
      initialSelection: _con.selectedBuilding,
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: Colors.black,
      ),
      width: double.infinity,

      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.orange, width: 2),
        ),
      ),

      dropdownMenuEntries:
          _listBuilding.map<DropdownMenuEntry<dynamic>>((item) {
        return DropdownMenuEntry<dynamic>(
          value: item['id'],
          label: item['building_name'],
          style: ButtonStyle(
            textStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(
                color: Colors.black,
                fontSize: _fontSize,
                fontFamily: 'NotoSans')),
            backgroundColor:
                WidgetStatePropertyAll<Color>(Colors.white),
          ),
        );
      }).toList(),

      menuStyle: MenuStyle(
              backgroundColor: MaterialStateProperty.all(Colors.white),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

      onSelected: (value) {
        setState(() {
          _con.selectedBuilding = value;
        });
      },
    );
  }


  Widget dropDownTitleName() {
    List<String> titleNameList = ['คุณ', 'นาย', 'น.ส.', 'นาง', 'Mr.', 'Ms.', 'Mrs.'];
    if (_con.empTitleController.text.isEmpty) {
      _con.empTitleController.text = titleNameList[0];
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        value: _con.empTitleController.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 8),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        style: TextStyle(
          color: Colors.black,
          fontSize: _fontSize,
          height: 1.0,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        items: titleNameList.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _con.empTitleController.text = newValue!;
          });
        },
      ),
    );
  }

  void warningDialog(String description, VoidCallback action) {
    CustomDialog.show(
                      context: context,
                      title: 'คำเตือน',
                      message: description,
                      type: DialogType.warning,
                      onConfirm: action,
                      onCancel: () {
                        Navigator.pop(context);
                      },
                    );
  }
}

class InputField extends StatefulWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;
  final Widget? widget;
  final bool? descriptText;
  final bool isRequired;
  final int? maxLength;

  const InputField({
    Key? key,
    required this.title,
    required this.hint,
    this.controller,
    this.widget,
    this.descriptText,
    this.isRequired = false,
    this.maxLength,
  }) : super(key: key);

  @override
  _InputFieldState createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  bool _isError = false;
  double _fontSize = ApiConfig.fontSize;
  bool _isPhoneScale = false;

  @override
  void initState() {
    super.initState();
    _validateInput();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _fontSize = ApiConfig.getFontSize(context);
      });
    });
  }

  void _validateInput() {
    if (widget.isRequired) {
      setState(() {
        _isError = widget.controller?.text.isEmpty ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _fontSize = ApiConfig.getFontSize(context);
    _isPhoneScale = ApiConfig.getPhoneScale(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
          ),
          Container(
            height: widget.descriptText == true ? 52 * 2.5 : 52,
            margin: EdgeInsets.only(top: 2.5),
            padding: EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isError ? Colors.red.shade600 : Colors.grey,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(widget.maxLength ?? 100)
                    ],
                    onChanged: (value) => _validateInput(),
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    cursorColor: Colors.orange,
                    readOnly: widget.widget != null,
                    autofocus: false,
                    controller: widget.controller,
                    maxLines: widget.descriptText == true ? null : 1,
                    minLines: widget.descriptText == true ? null : 1,
                    expands: widget.descriptText == true,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: _fontSize-4,
                      ),
                    ),
                    style: TextStyle(fontSize: _fontSize),
                  ),
                ),
                widget.widget ?? Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
