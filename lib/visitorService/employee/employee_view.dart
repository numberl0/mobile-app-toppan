import 'dart:io';
import 'dart:typed_data';
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
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/visitorService/employee/employee_controller.dart';

import '../../component/CustomDIalog.dart';

class EmployeeForm {
  Widget employeeFormWidget(Map<String, dynamic>? docData) {
    return EmployeeFormPage(documentData: docData);
  }
}

class EmployeeFormPage extends StatefulWidget {
  final Map<String, dynamic>? documentData;
  const EmployeeFormPage({super.key, this.documentData});
  @override
  _EmployeeFormPageState createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage>
    with SingleTickerProviderStateMixin {
  EmployeeController _controller = EmployeeController();

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
    
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() {

    //   });
    // });
  }

  void prepareForm() async {
    if (widget.documentData != null) {
      final data = widget.documentData;
      await _controller.prepareLoadForm(context, data);
    } else {
      await _controller.prepareNewForm(context);
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
                    ignoring: _controller.logBook,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tno Display
                        if (_controller.flagUpdateForm && (_controller.formatSequenceRunning?.isNotEmpty ?? false)) ...[
                          Container(
                            key: _controller.inputSectionKey,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('No.${_controller.formatSequenceRunning}',
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
                          "ประเภทของวัตถุประสงค์:",
                          style: TextStyle(
                              fontSize: _fontSize, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        dropDownTypeObjective(),
                        
                        SizedBox(
                          height: 20,
                        ),
                        
                        // Objective
                        InputField(
                          title: 'วัตถุประสงค์:',
                          hint: '',
                          controller: _controller.objectiveController,
                          descriptText: true,
                          maxLength: 400,
                        ),
                        
                        SizedBox(
                          height: 20,
                        ),
                        
                        FractionallySizedBox(
                          widthFactor: 0.4, // 40% width
                          alignment: Alignment.centerLeft,
                          child: InputField(
                            title: 'เลขทะเบียนรถ:',
                            hint: '',
                            controller: _controller.vehicleLicenseController,
                            maxLength: 24,
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Switch(
                              value: _controller.outOnly,
                              activeColor: Colors.orange,
                              onChanged: (bool value) {
                                setState(() {
                                  _controller.outOnly = value;
                                  
                                  if(value){
                                    // Date In
                                    _controller.flagDateIn = _controller.flagDateOut;
                                    _controller.dateInController.text =  DateFormat('yyyy-MM-dd').format(_controller.flagDateIn!);
                        
                                    // Time In
                                    _controller.flagTimeIn = _controller.flagTimeOut;
                                    _controller.timeInController.text =  _controller.formatTime(_controller.flagTimeIn!);
                                  }else{
                                    // Date In
                                    _controller.flagDateIn = null;
                                    _controller.dateInController.text = '';
                                    // Time In
                                    _controller.flagTimeIn = null;
                                    _controller.timeInController.text = '';
                                  }
                                });
                              },
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              '-   ไปไม่กลับ?',
                              style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        
                        SizedBox(height: 15),
                        
                        //Time Out
                        Row(
                          children: [
                            Expanded(
                              child: InputField(
                                title: "เวลาออก:",
                                hint: "",
                                controller: _controller.timeOutController,
                                widget: IconButton(
                                  onPressed: () {
                                    _timePicker(
                                        context, _controller.flagTimeOut, 'out');
                                  },
                                  icon: Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: InputField(
                                title: "วันที่ออก:",
                                hint: "",
                                controller: _controller.dateOutController,
                                widget: IconButton(
                                  icon: Icon(
                                    Icons.calendar_month,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    await _datePicker(context, _controller.flagDateOut, 'out');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 15),
                        
                        AnimatedCrossFade(
                          crossFadeState: _controller.outOnly
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: Duration(milliseconds: 300),
                          firstChild: SizedBox.shrink(), // hidden state
                          secondChild: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InputField(
                                      title: "เวลากลับ:",
                                      hint: "",
                                      controller: _controller.timeInController,
                                      widget: IconButton(
                                        onPressed: () {
                                          _timePicker(
                                              context, _controller.flagTimeIn, 'in');
                                        },
                                        icon: Icon(
                                          Icons.access_time_rounded,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: InputField(
                                      title: "วันที่กลับ:",
                                      hint: "",
                                      controller: _controller.dateInController,
                                      widget: IconButton(
                                        icon: Icon(
                                          Icons.calendar_month,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          await _datePicker(context, _controller.flagDateIn, 'in');
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        //Employee
                        Container(
                          key: _controller.personSectionKey,
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
                                            "รายชื่อพนักงาน:",
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
                                      "${_controller.personList.length}",
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange),
                                    ),
                                  ],
                                ),
                        
                                SizedBox(height: 10),
                        
                                //Show Person List
                                AnimatedCrossFade(
                                  firstChild:
                                      Container(), // Empty container when collapsed
                                  secondChild:
                                      personListGenerate(), // Show list when expanded
                                  crossFadeState: _controller.isExpanded_listPerson
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: Duration(milliseconds: 300),
                                ),
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
                        
                        SizedBox(
                          height: 30,
                        ),
                        
                        Container(
                          key: _controller.buildingSectionKey,
                          child: Column(
                            children: [
                              dropDownBuilding(_controller.buildingList),
                              SizedBox(height: 10),
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                transitionBuilder: (widget, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    child: widget,
                                  ),
                                ),
                                child: _controller.isExpandedBuilding
                                    ? InputField(
                                        key: ValueKey('inputField'),
                                        title: 'บริเวณ*',
                                        hint: '',
                                        controller:
                                            _controller.otherBuildingController,
                                        isRequired: true,
                                        maxLength: 100,
                                      )
                                    : SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(
                          height: 20,
                        ),
                        
                      ],
                    ),
                  ),

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
                                  color: Colors.black,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 50,
                                    color: Colors.black,
                                  ),
                                  Text(
                                    "ลงชื่อ",
                                    style: TextStyle(
                                        fontSize: _fontSize,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  if (!_controller.logBook)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          // Makes button take up full available width
                          child: ElevatedButton(
                            onPressed: () async {
                              String valiMessage =
                                  await _controller.validateUpload();
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
                                bool uploadSuccess = await _controller.insertRequestForm();
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
                                    GoRouter.of(context).pushReplacement('/home');
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
                                  vertical: 16), // Increases button height
                              backgroundColor:
                                  Colors.orange, // Change color if needed
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12), // Rounded corners
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
    List<String> sectionKeys = _controller.signatureSectionMap.keys.toList();
    final ScrollController controller = ScrollController();
    final FixedExtentScrollController menuRowController =
        FixedExtentScrollController();

    // initial value
    int currentIndex = 0;
    Uint8List? signatureDisplay = _controller.signatureSectionMap[sectionKeys[currentIndex]]?[0];
    DateTime? dateTimeSignDisplay = _controller.signatureSectionMap[sectionKeys[currentIndex]]?[1];
    TextEditingController signaturesByDisplay = TextEditingController(
        text: _controller.signatureSectionMap[sectionKeys[currentIndex]]?[3] ??
            '');

    // clear display
    void clearStateSignature() async {
      signatureDisplay = null;
      dateTimeSignDisplay = null;
      if (_controller.signatureGlobalKey.currentState
              ?.toPathList()
              .isNotEmpty ==
          true) {
        _controller.signatureGlobalKey.currentState!.clear();
      }
      signaturesByDisplay.clear();
    }

    //setup display
    void setStateSignature() {
      clearStateSignature();
      signatureDisplay =
          _controller.signatureSectionMap[sectionKeys[currentIndex]]?[0];
      dateTimeSignDisplay =
          _controller.signatureSectionMap[sectionKeys[currentIndex]]?[1];
      signaturesByDisplay.text =
          _controller.signatureSectionMap[sectionKeys[currentIndex]]?[3] ?? '';
    }

    //stamp signature
    Future<void> stampSignatureApprove(
        DateTime dateTime, GlobalKey<SfSignaturePadState> signature) async {
      final signatureImage = await signature.currentState!.toImage();
      final byteData =
          await signatureImage.toByteData(format: ImageByteFormat.png);
      final signatureData = byteData!.buffer.asUint8List();
      _controller.signatureSectionMap[sectionKeys[currentIndex]] = [
        signatureData,
        dateTime,
        _controller.signatureSectionMap[sectionKeys[currentIndex]]
            ?[2], //same data in index 2
        signaturesByDisplay.text,
      ];
      setStateSignature();
    }

    //Function controller arrow for next menu by mobile scale
    void arrowController(String turn, StateSetter setStateDialog) {
      setState(() {
        if (turn == 'R') {
          if (currentIndex < _controller.signatureSectionMap.length - 1) {
            currentIndex++;
          } else {
            currentIndex = 0;
          }
        } else if (turn == 'L') {
          if (currentIndex > 0) {
            currentIndex--;
          } else {
            currentIndex = _controller.signatureSectionMap.length - 1;
          }
        }
        setStateSignature();
        setStateDialog(() {});
        menuRowController.animateToItem(currentIndex,
            duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      });
    }

    //HeaderMenu
    Widget _headerMenu(double screenWidth, StateSetter setStateDialog) {
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
                                  sectionKeys[index],
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: _fontSize),
                                ),
                              ),
                            );
                          },
                          childCount: _controller.signatureSectionMap.length,
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
            : Container(
                padding: EdgeInsets.only(bottom: 20),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  destinations:
                      _controller.signatureSectionMap.entries.map((entry) {
                    int index = _controller.signatureSectionMap.keys
                        .toList()
                        .indexOf(entry.key);
                    String sectionLabel = entry.key;
                    BorderRadius borderRadius;
                    bool _isPressed = currentIndex == index;

                    // Define border radius for first and last items
                    if (index == 0) {
                      borderRadius = BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        bottomLeft: Radius.circular(20.0),
                      );
                    } else if (index ==
                        _controller.signatureSectionMap.length - 1) {
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
      return Stack(
        children: [
          // Signature Card
          IgnorePointer(
            ignoring: _controller.logBook,
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
                          Text(
                            _controller.signatureSectionMap[
                                sectionKeys[currentIndex]]?[2],
                            style: TextStyle(
                              fontSize: _fontSize + 4,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      
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
                        child: _controller.signatureSectionMap[
                                        sectionKeys[currentIndex]]?[0] !=
                                    null &&
                                _controller.signatureSectionMap[
                                        sectionKeys[currentIndex]]?[1] !=
                                    null
                            ? Image.memory(signatureDisplay!)
                            : SfSignaturePad(
                                key: _controller.signatureGlobalKey,
                                backgroundColor: Colors.transparent,
                                strokeColor: Colors.black,
                                minimumStrokeWidth: 3.0,
                                maximumStrokeWidth: 6.0,
                              ),
                      ),

                                  // Reset Button (Positioned at Bottom-Left)
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        // _controller.signatureGlobalKey.currentState!.clear();
                                        if (_controller.signatureSectionMap[
                                              sectionKeys[currentIndex]]?[0] !=
                                          null &&
                                      _controller.signatureSectionMap[
                                              sectionKeys[currentIndex]]?[1] !=
                                          null &&
                                      _controller.signatureSectionMap[
                                              sectionKeys[currentIndex]]?[3] !=
                                          null) {
                                    warningDialog(
                                        'คุณต้องการจะลบลายเซ็น ${sectionKeys[currentIndex]} ใช่หรือไม่?',
                                        () {
                                      setState(() {
                                        _controller.signatureSectionMap[
                                                sectionKeys[currentIndex]]?[0] =
                                            null; // signatures
                                        _controller.signatureSectionMap[
                                                sectionKeys[currentIndex]]?[1] =
                                            null; // date
                                        _controller.signatureSectionMap[
                                                sectionKeys[currentIndex]]?[3] =
                                            null; // by
                                        clearStateSignature();
                                        Navigator.pop(context);
                                        setStateDialog(() {});
                                      });
                                    });
                                  } else if (_controller
                                      .signatureGlobalKey.currentState!
                                      .toPathList()
                                      .isNotEmpty) {
                                    _controller.signatureGlobalKey.currentState!
                                        .clear();
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
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            /// 🔹 ช่องกรอกชื่อ
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
                                  readOnly: signaturesByDisplay.text.isNotEmpty,
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

                            /// 🔹 ปุ่มบันทึก
                            ElevatedButton(
                              onPressed: _controller.signatureSectionMap[
                                              sectionKeys[currentIndex]]?[0] ==
                                          null &&
                                      _controller.signatureSectionMap[
                                              sectionKeys[currentIndex]]?[1] ==
                                          null &&
                                      _controller.signatureSectionMap[
                                              sectionKeys[currentIndex]]?[3] ==
                                          null
                                  ? () async {
                                      if (_controller
                                              .signatureGlobalKey.currentState!
                                              .toPathList()
                                              .isNotEmpty &&
                                          signaturesByDisplay.text.isNotEmpty) {

                                        await stampSignatureApprove(
                                          AppDateTime.now(),
                                          _controller.signatureGlobalKey,
                                        );

                                        setStateDialog(() {});
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
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
            
                      // Time and Date Fields
                      Row(
                        children: [
                          Expanded(
                            child: InputField(
                              title: 'เวลา',
                              hint: '',
                              controller: TextEditingController(
                                  text: dateTimeSignDisplay == null
                                      ? ''
                                      : DateFormat('HH:mm')
                                          .format(dateTimeSignDisplay!)),
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
                                  text: dateTimeSignDisplay == null
                                      ? ''
                                      : DateFormat('yyyy-MM-dd')
                                          .format(dateTimeSignDisplay!)),
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
          ),

          // Exit Button (Close)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.cancel_rounded,
                color: _cancelBtnColor,
                size: _isPhoneScale?47:50,
              ),
              tooltip: "Close",
            ),
          ),
        ],
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
        return Container(); // Required but not used
      },
      transitionBuilder: (context, a1, a2, widget) {
        double screenWidth = MediaQuery.of(context).size.width;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
            Navigator.of(context).pop(); // Close dialog 
          },
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0).animate(a1),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.6, end: 1.0).animate(a1),
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(viewInsets: EdgeInsets.zero), // Prevent movement
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
                                ? const EdgeInsets.only(
                                    left: 16.0,
                                    bottom: 16.0,
                                    right: 16.0,
                                    top: 16.0)
                                : const EdgeInsets.all(10.0),
                            child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                children: [
                                  _headerMenu(screenWidth, setStateDialog),
                                  SizedBox(height: 20),
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
          ),
        );
      },
    );
  }

  //Function to take photo with camera
  Future _pickImageFromCamera(int index, List<File?> _imageList) async {
    final pickedFile = await _controller.imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        if (_imageList.length < _controller.limitImageDisplay) {
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
      print("No Image Picked");
    }
  }

  void popUpEditItem(Map<String, String> entry) {
    _controller.itemNameController.text = entry['item']!;

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
                            controller: _controller.itemNameController,
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
                                _controller.itemNameController.clear();
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
                                if (_controller
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
                                  _controller.editItemTypeList(entry);
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
      _controller.itemNameController.clear();
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
                                  _controller.listItem_In.remove(entry);
                                } else {
                                  _controller.listItem_Out.remove(entry);
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
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
          },
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: EdgeInsets.zero), // Prevent UI shifting
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24), // Rounded dialog corners
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Fit to content size
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
                            hint: '',
                            controller: _controller.itemNameController,
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
                                _controller.itemNameController.clear();
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
                                if (_controller
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
                                  await _controller.addItemTypeList(type);
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
                        "${_controller.listItem_Out.length} : ${_controller.imageList_Out.length}",
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
                  _itemListGenerate(_controller.listItem_Out, 'out'),
                  SizedBox(
                    height: 20,
                  ),
                  _contentItemImage(_controller.imageList_Out),

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
                        "${_controller.listItem_In.length} : ${_controller.imageList_In.length}",
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
                  _itemListGenerate(_controller.listItem_In, 'in'),
                  SizedBox(
                    height: 20,
                  ),
                  _contentItemImage(_controller.imageList_In),
                  
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
    final pickedFile = await _controller.imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        if (_imageList.length < _controller.limitImageDisplay) {
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
      print("No Image Picked");
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
              "${_imageList.length}/${_controller.limitImageDisplay}",
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
                  if (_imageList.length < _controller.limitImageDisplay) ...[
                    _buildImagePicker(null, _imageList.length + 1, _imageList),
                  ],
                ],
              ),
            ] else if (_imageList.length <= _controller.limitImageDisplay) ...[
              GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _imageList.length < _controller.limitImageDisplay
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

  // Function toggle the visibility of the person list
  void _togglePersonList() {
    setState(() {
      _controller.isExpanded_listPerson = !_controller.isExpanded_listPerson;
    });
  }

  // Function toggle the visibility of the Item list
  void _toggleItemList() {
    setState(() {
      _controller.isExpanded_listItem = !_controller.isExpanded_listItem;
    });
  }

  //Function clear input controller Employee
  void _clearPersonInfoController() {
    _controller.empNameController.clear();
    _controller.empIdController.clear();
    _controller.signatureGlobalKey.currentState!.clear(); //signature
  }

  void popUpEditPerson(Map<String, dynamic> entry) {
    _controller.empTitleController.text = entry['TitleName']!;
    _controller.empNameController.text = entry['FullName']!;
    _controller.empIdController.text = entry['EmployeeId']!;
    _controller.empDeptController.text = entry['Department']!;
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
                .copyWith(viewInsets: EdgeInsets.zero), // Prevent UI movement
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
                                          controller: _controller.empIdController,
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
                                                color: Colors.yellow,
                                                size: _fontSize + 8,
                                              ),
                                              onPressed: () async {
                                                bool status = await _controller
                                                    .searchInfoByPid(_controller.empIdController.text);
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
                                controller: _controller.empNameController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Employe ID
                              InputField(
                                title: 'แผนก:',
                                hint: '',
                                controller: _controller.empDeptController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Signature Pad Section
                              Text('ลงชื่อ:',
                                  style: TextStyle(
                                      fontSize: _fontSize,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Stack(
                                children: [
                                  // Signature Pad Container with Rounded Corners
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 200),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(
                                          12), // Rounded corners
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          12), // Ensures child (Signature Pad) is clipped
                                      child: SfSignaturePad(
                                        key: _controller.signatureGlobalKey,
                                        backgroundColor: Colors
                                            .transparent, // Set background for better visibility
                                        strokeColor: Colors.black,
                                        minimumStrokeWidth: 3.0,
                                        maximumStrokeWidth: 6.0,
                                      ),
                                    ),
                                  ),

                                  // Reset Button (Positioned at Bottom-Left)
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        _controller
                                            .signatureGlobalKey.currentState!
                                            .clear(); // Clears signature pad
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.black.withOpacity(
                                            0.5), // Semi-transparent background
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
                          // Cancel Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _controller.clearPersonController();
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
                                await _controller.editPersonInList(entry);
                                setState(() {});
                                Navigator.of(context).pop();
                                await _controller.clearPersonController();
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

    Widget personListGenerate() {
  return _controller.personList.isNotEmpty
      ? Column(
          children: _controller.personList.map((entry) {
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
                  key: ValueKey(entry['EmployeeId']),
                  startActionPane: ActionPane(
                    motion: ScrollMotion(),
                    extentRatio: 0.20,
                    children: [
                      CustomSlidableAction(
                        onPressed: (context) => popUpEditPerson(entry),
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
                            'ต้องการลบข้อมูลรายการของ ${entry['TitleName']} ${entry['FullName']} ใช่หรือไม่?',
                            () {
                              setState(() {
                                _controller.personList.remove(entry);
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
                                      '${entry['TitleName']} ${entry['FullName']}',
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
                                            'รหัสพนักงาน : ${entry['EmployeeId']}',
                                            style: TextStyle(
                                              fontSize: _fontSize - 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          if(entry['Department'] != null && entry['Department'].toString().trim().isNotEmpty) ...[
                                            Text(
                                            'แผนก : ${entry['Department']}',
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
                                          'รหัสพนักงาน : ${entry['EmployeeId']}',
                                          style: TextStyle(
                                            fontSize: _fontSize - 2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        SizedBox(height: 5,),
                                         if(entry['Department'] != null && entry['Department'].toString().trim().isNotEmpty) ...[
                                          Text(
                                          'แผนก : ${entry['Department']}',
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
                                    
                                    // Row(
                                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    //   children: [
                                    //     Text(
                                    //       'รหัสพนักงาน : ${entry['EmployeeId']}',
                                    //       style: TextStyle(
                                    //         fontSize: _fontSize - 2,
                                    //         fontWeight: FontWeight.bold,
                                    //         color: Colors.black,
                                    //       ),
                                    //       overflow: TextOverflow.ellipsis,
                                    //       maxLines: 1,
                                    //     ),
                                    //     if(entry['Department'] != null && entry['Department'].toString().trim().isNotEmpty) ...[
                                    //       Text(
                                    //       'แผนก : ${entry['Department']}',
                                    //         style: TextStyle(
                                    //           fontSize: _fontSize - 2,
                                    //           fontWeight: FontWeight.bold,
                                    //           color: Colors.black,
                                    //         ),
                                    //         overflow: TextOverflow.ellipsis,
                                    //         maxLines: 1,
                                    //       ),
                                    //     ],
                                    //     Container(),
                                    //     Container(),
                                    //   ],
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.orange,
                            height: 10.0,
                            thickness: 1.0,
                          ),
                          SizedBox(height: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Center(
                                child: entry['Signature'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          entry['Signature'],
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Text(
                                        'No Signature Available',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                              ),
                              SizedBox(height: 10),
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
            FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
          },
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(viewInsets: EdgeInsets.zero), // Prevent UI movement
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
                  mainAxisSize: MainAxisSize.min, // Ensures dialog fits content
                  children: [
                    // Header Section with Close Button
                    Stack(
                      children: [
                        // Header Background
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
                                          controller: _controller.empIdController,
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
                                                bool status = await _controller
                                                    .searchInfoByPid(_controller.empIdController.text);
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
                                controller: _controller.empNameController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Employe ID
                              InputField(
                                title: 'แผนก:',
                                hint: '',
                                controller: _controller.empDeptController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Signature Pad Section
                              Text('ลงชื่อ:',
                                  style: TextStyle(
                                      fontSize: _fontSize,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Stack(
                                children: [
                                  // Signature Pad Container with Rounded Corners
                                  Container(
                                    constraints: BoxConstraints(maxHeight: 200),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(
                                          12), // Rounded corners
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          12), // Ensures child (Signature Pad) is clipped
                                      child: SfSignaturePad(
                                        key: _controller.signatureGlobalKey,
                                        backgroundColor: Colors
                                            .transparent, // Set background for better visibility
                                        strokeColor: Colors.black,
                                        minimumStrokeWidth: 3.0,
                                        maximumStrokeWidth: 6.0,
                                      ),
                                    ),
                                  ),

                                  // Reset Button (Positioned at Bottom-Left)
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        _controller
                                            .signatureGlobalKey.currentState!
                                            .clear(); // Clears signature pad
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.black.withOpacity(
                                            0.5), // Semi-transparent background
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
                          // Cancel Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _controller.clearPersonController();
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
                                if (_controller
                                        .empNameController.text.isEmpty ||
                                    _controller.empIdController.text.isEmpty ||
                                    _controller.signatureGlobalKey.currentState!
                                        .toPathList()
                                        .isEmpty) {
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
                                  await _controller.addPersonInList();
                                  setState(() {});
                                  Navigator.of(context).pop();
                                  await _controller.clearPersonController();
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
                          _controller.isStrechedDropDown =
                              !_controller.isStrechedDropDown;
                          if (_controller.isStrechedDropDown) {
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
                                _controller.typeObjectiveMapping[
                                        _controller.objTypeSelection] ??
                                    "",
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: _fontSize),
                              ),
                            ),
                            Icon(_controller.isStrechedDropDown
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
                          itemCount: _controller.typeObjectiveMapping.length,
                          itemBuilder: (context, index) {
                            String objectiveKey = _controller
                                .typeObjectiveMapping.keys
                                .elementAt(index);
                            String objectiveValue = _controller
                                .typeObjectiveMapping.values
                                .elementAt(index);
                            return RadioListTile(
                              title: Text(
                                objectiveValue,
                                style: TextStyle(
                                    fontSize: _fontSize), // Dynamic font size
                              ),
                              value: objectiveKey,
                              groupValue: _controller.objTypeSelection,
                              activeColor: Colors.orange,
                              onChanged: (val) {
                                setState(() {
                                  _controller.objTypeSelection = val.toString();
                                  _controller.isStrechedDropDown = false;
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
    if (_listBuilding.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return DropdownMenu(
      requestFocusOnTap: false,
      initialSelection: _controller.selectedBuilding,
      label: Text(
        'บริเวณ (Building):',
        style: TextStyle(
            color: Colors.black,
            fontSize: _fontSize + 6,
            fontWeight: FontWeight.bold),
      ),
      textStyle: TextStyle(
        fontSize: _fontSize,
        color: Colors.black,
      ),
      width: MediaQuery.of(context).size.width*0.85,
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
          _controller.selectedBuilding = value;
          _controller.checkBuildingOther();
        });
      },
    );
  }

  //Function TimePicker
  Future<void> _timePicker(
      BuildContext context, TimeOfDay? _time, String type) async {
    TimeOfDay initialTime = _time ?? TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(MediaQuery.of(context).size.width > 799 ? 1.5 : 1.0)),
          child: Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.orange,
              colorScheme: ColorScheme.light(
                primary: Colors.orange,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _time) {
      setState(() {
        initialTime = picked;
        if (type == 'in') {
          _controller.flagTimeIn = initialTime;
          _controller.timeInController.text = initialTime.format(context);
        } else if (type == 'out') {
          _controller.flagTimeOut = initialTime;
          _controller.timeOutController.text = initialTime.format(context);
        }
      });

      if(_controller.flagTimeOut != null && _controller.flagTimeIn != null) {
        bool checkOutFrist = await _controller.checkDateTimeError();
        if (!checkOutFrist) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              backgroundColor: Colors.red.shade700,
              icon: Icon(Icons.sentiment_very_satisfied,
                  color: Colors.red.shade900, size: 120),
              message: "วันที่เข้าต้องมากกว่าวันที่ออกเสมอ",
            ),
          );
          if(type == 'out'){
            _controller.flagTimeOut = null;
            _controller.timeOutController.text = '';
          }else if (type == 'in') {
            _controller.flagTimeIn = null;
            _controller.timeInController.text = '';
          }
        }
      }
    }
  }

  //Function Date Picker
  Future<void> _datePicker(BuildContext context, DateTime? _date, String type) async {
    DateTime initialDate = _date ?? AppDateTime.now();
    DateTime? _pickerDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(AppDateTime.now().year - 7),
        lastDate: DateTime(AppDateTime.now().year + 7),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                    MediaQuery.of(context).size.width > 799 ? 1.5 : 1.0)),
            child: Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.orange,
                colorScheme: ColorScheme.light(
                  primary: Colors.orange,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            ),
          );
        });
    if (_pickerDate != null) {
      initialDate = _pickerDate;
      setState(() {
        if(type == 'out'){
          _controller.flagDateOut = initialDate;
          _controller.dateOutController.text = DateFormat('yyyy-MM-dd').format(initialDate);
        }else if (type == 'in') {
          _controller.flagDateIn = initialDate;
          _controller.dateInController.text = DateFormat('yyyy-MM-dd').format(initialDate);
        }
      });
      
      if(_controller.flagDateOut != null && _controller.flagDateIn != null) {
        bool checkOutFrist = await _controller.checkDateTimeError();
        if (!checkOutFrist) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              backgroundColor: Colors.red.shade700,
              icon: Icon(Icons.sentiment_very_satisfied,
                  color: Colors.red.shade900, size: 120),
              message: "วันที่เข้าต้องมากกว่าวันที่ออกเสมอ",
            ),
          );
          if(type == 'out'){
            _controller.flagDateOut = null;
            _controller.dateOutController.text = '';
          }else if (type == 'in') {
            _controller.flagDateIn = null;
            _controller.dateInController.text = '';
          }
        }
      }
    }
  }

  Widget dropDownTitleName() {
    List<String> titleNameList = ['คุณ', 'นาย', 'น.ส.', 'นาง', 'Mr.', 'Ms.', 'Mrs.'];
    if (_controller.empTitleController.text.isEmpty) {
      _controller.empTitleController.text = titleNameList[0];
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        value: _controller.empTitleController.text,
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
            _controller.empTitleController.text = newValue!;
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
      behavior: HitTestBehavior.opaque, // Ensures taps outside are detected
      onTap: () {
        FocusScope.of(context).unfocus(); // Remove focus when tapping outside
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
