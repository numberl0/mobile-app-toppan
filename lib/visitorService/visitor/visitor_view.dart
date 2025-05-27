import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/clear_temporary.dart';
import 'package:toppan_app/config/api_config.dart';

import 'visitor_controller.dart';

class VisitorForm {
  Widget visitorFormWidget(Map<String, dynamic>? docData) {
    return VisitorFormPage(documentData: docData);
  }
}

class VisitorFormPage extends StatefulWidget {
  final Map<String, dynamic>? documentData;
  const VisitorFormPage({super.key, this.documentData});
  @override
  _VisitorFormPageState createState() => _VisitorFormPageState();
}

class _VisitorFormPageState extends State<VisitorFormPage> {
  VisitorFormController _controller = VisitorFormController();
  Color? _cancelBtnColor = Colors.red[400];
  Color? _acceptBtnColor = Colors.blue[400];
  double _fontSize = ApiConfig.fontSize;

  @override
  void initState() {
    super.initState();
    prepareForm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        if (screenWidth > 799) {
          _fontSize += 8.0;
        }
      });
    });
  }

  void prepareForm() async {
    if (widget.documentData != null) {
      final data = widget.documentData;
      await _controller.prepareLoadForm(context, data);
    } else {
      await _controller.prepareNewForm(context);
    }
    _showAgreementWarning(context);
    setState(() {});
  }

  // Function to show the pop-up dialog PDPA
  Future<void> _showAgreementWarning(BuildContext context) async {
    ScrollController _scrollController = ScrollController();
    bool _isScrolledToEnd = false;
    String _selectedLanguage = 'Thai'; // Default language

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Check if scrolling is needed
              if (_scrollController.position.maxScrollExtent == 0) {
                setState(() {
                  _isScrolledToEnd = true;
                });
              }
            });

            // Listen to scroll changes
            _scrollController.addListener(() {
              if (_scrollController.offset >=
                  _scrollController.position.maxScrollExtent) {
                setState(() {
                  _isScrolledToEnd = true;
                });
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: _fontSize + 10,
                      color: Colors.amber.shade700,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'ข้อตกลงของบริษัท',
                      style: TextStyle(
                          fontSize: _fontSize + 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              content: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller:
                              _scrollController, // Attach scroll controller
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: _fontSize - 4),
                              children: [
                                TextSpan(
                                  text: _selectedLanguage == 'English'
                                      ? _controller.agreementEng
                                      : _controller.agreementThai,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          // Switch language
                          _selectedLanguage = _selectedLanguage == 'English'
                              ? 'Thai'
                              : 'English';

                          // Reset scrolling state
                          _isScrolledToEnd = false;

                          // Reset scroll to top
                          _scrollController.animateTo(
                            0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
                      icon: Icon(Icons.translate, size: _fontSize + 2),
                      label: Text(
                        _selectedLanguage == 'English'
                            ? 'Switch to Thai'
                            : 'Switch to English',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: _fontSize),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () {
                    GoRouter.of(context).go('/home');
                  },
                  child: Text(
                    'ยกเลิก',
                    style:
                        TextStyle(color: _cancelBtnColor, fontSize: _fontSize),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isScrolledToEnd ? _acceptBtnColor : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      _isScrolledToEnd ? () => Navigator.pop(context) : null,
                  child: Text(
                    'ยอมรับเงื่อนไข',
                    style: TextStyle(color: Colors.white, fontSize: _fontSize),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //Build Page
  @override
  Widget build(BuildContext context) {
    //Back ground
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color.fromARGB(255, 114, 230, 114),
          Color.fromARGB(255, 89, 226, 101),
          Color.fromARGB(255, 62, 212, 69),
          Color.fromARGB(255, 50, 199, 57),
          Color.fromARGB(255, 28, 172, 28),
        ],
      )),
      child: _getPageContent(context),
    );
  }

  //Page Content
  Widget _getPageContent(BuildContext context) {
    final ScrollController controller = ScrollController();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
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
              // Color.fromARGB(255, 236, 236, 236),
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
              controller: controller, // Use the controller for scrolling
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    key: _controller.inputSectionKey,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 36,
                          color: Colors.green,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text('No. ${_controller.formatSequenceRunning}',
                            style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 15,
                  ),

                  Divider(
                    color: Colors.black,
                    thickness: 0.5,
                    height: 0,
                  ),

                  SizedBox(
                    height: 15,
                  ),
                  // Company Name
                  InputField(
                    title: 'บริษัท:',
                    hint: '',
                    controller: _controller.companyController,
                    maxLength: 255,
                  ),
                  SizedBox(height: 15),

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
                  //Time In
                  Row(
                    children: [
                      Expanded(
                        child: InputField(
                          title: "เวลาเข้า:",
                          hint: "",
                          controller: _controller.timeInController,
                          widget: IconButton(
                            onPressed: () {
                              _timePicker(
                                  context, _controller.flagTimeIn, 'in');
                            },
                            icon: Icon(
                              Icons.access_time_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: InputField(
                          title: "วันที่เข้า:",
                          hint: "",
                          controller: _controller.dateInController,
                          widget: IconButton(
                            icon: Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              _datePicker(context, _controller.flagDateIn, 'in');
                            },
                          ),
                        ),
                      ),
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
                              color: Colors.grey,
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
                              Icons.calendar_today_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () async {
                              _datePicker(context, _controller.flagDateOut, 'out');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  // Contact
                  InputField(
                    title: 'ติดต่อ:',
                    hint: '',
                    controller: _controller.contactController,
                    maxLength: 255,
                  ),
                  SizedBox(height: 15),

                  // Department
                  InputField(
                    title: 'แผนก:',
                    hint: '',
                    controller: _controller.departmentController,
                    maxLength: 255,
                  ),
                  SizedBox(height: 15),

                  // Object/Visitor
                  InputField(
                    title: 'วัตถุประสงค์:',
                    hint: '',
                    controller: _controller.objectiveController,
                    descriptText: true,
                    maxLength: 400,
                  ),
                  SizedBox(height: 30),

                  // Visitor and follower's
                  Container(
                    key: _controller.visitorSectionKey,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                                      Icons.person,
                                      color: Colors.black,
                                      size: 50,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      "รายชื่อผู้มาติดต่อ:",
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _togglePersonList,
                                icon: Icon(
                                  _controller.isExpanded_listPerson
                                      ? Icons.keyboard_double_arrow_down
                                      : Icons.keyboard_double_arrow_up,
                                  size: 24,
                                ),
                              )
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
                                  backgroundColor: Colors.green.shade600,
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
                                        fontSize: _fontSize - 4,
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
                                    color: Colors.green.shade600),
                              ),
                            ],
                          ),

                          SizedBox(height: 10),

                          //Show Visitor List
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
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                                      Icons.shopping_bag,
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
                              SizedBox(
                                width: 20.0,
                              ),
                              IconButton(
                                onPressed: _toggleItemList,
                                icon: Icon(
                                  _controller.isExpanded_listItem
                                      ? Icons.keyboard_double_arrow_down
                                      : Icons.keyboard_double_arrow_up,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.black,
                            thickness: 1,
                            height: 10,
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              FlutterSwitch(
                                width: 70.0,
                                height: 40.0,
                                toggleSize: 70.0,
                                value: _controller.isSwitchImagePicker,
                                borderRadius: 30.0,
                                padding: 2.0,
                                activeToggleColor:
                                    Color.fromARGB(255, 255, 255, 255),
                                inactiveToggleColor:
                                    Color.fromARGB(255, 255, 255, 255),
                                activeSwitchBorder: Border.all(
                                  color: Color.fromARGB(255, 202, 202, 202),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                                inactiveSwitchBorder: Border.all(
                                  color: Color.fromARGB(255, 202, 202, 202),
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                                activeColor: Colors.green,
                                inactiveColor:
                                    Color.fromARGB(255, 255, 255, 255),
                                activeIcon: Icon(Icons.view_list),
                                inactiveIcon: Icon(Icons.camera_alt),
                                onToggle: (val) {
                                  AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.info,
                                    buttonsBorderRadius: const BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                    dismissOnTouchOutside: true,
                                    dismissOnBackKeyPress: false,
                                    // onDismissCallback: (type) {
                                    //   ScaffoldMessenger.of(context).showSnackBar(
                                    //     SnackBar(
                                    //       content: Text('Dismissed by $type'),
                                    //     ),
                                    //   );
                                    // },
                                    headerAnimationLoop: false,
                                    animType: AnimType.bottomSlide,
                                    title: 'คำเตือน',
                                    titleTextStyle: TextStyle(
                                        fontSize: _fontSize + 10,
                                        fontWeight: FontWeight.bold),
                                    desc:
                                        'ข้อมูลสิ่งของ เข้า/ออก จะสูญหาย ท่านต้องการเปลี่ยนการทำงานหรือไม่?',
                                    descTextStyle: TextStyle(
                                        fontSize: _fontSize,
                                        fontWeight: FontWeight.bold),
                                    showCloseIcon: true,
                                    btnOkText: 'ยืนยัน',
                                    btnOkColor: Colors.green.shade600,
                                    btnOkOnPress: () async {
                                      await _controller
                                          .itemListClear(); // Clear the lists
                                      setState(() {
                                        _controller.isSwitchImagePicker = val;
                                        if (!_controller.isExpanded_listItem) {
                                          _toggleItemList();
                                        }
                                      });
                                    },
                                    btnCancel: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _cancelBtnColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              30), // Circular shape
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 24),
                                        elevation:
                                            8, // Add elevation (shadow effect)
                                        shadowColor: Colors.black
                                            .withOpacity(1), // Shadow color
                                      ),
                                      child: Text(
                                        'ยกเลิก',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: _fontSize,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    btnOk: ElevatedButton(
                                      onPressed: () async {
                                        await _controller
                                            .itemListClear(); // Clear the lists
                                        setState(() {
                                          _controller.isSwitchImagePicker = val;
                                          if (!_controller
                                              .isExpanded_listItem) {
                                            _toggleItemList();
                                          }
                                        });
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _acceptBtnColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              30), // Circular shape
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 24),
                                        elevation:
                                            8, // Add elevation (shadow effect)
                                        shadowColor: Colors.black
                                            .withOpacity(1), // Shadow color
                                      ),
                                      child: Text(
                                        'ยืนยัน',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: _fontSize,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ).show();
                                },
                              ),
                              Text(
                                _controller.isSwitchImagePicker
                                    ? "${_controller.imageList_In.length} : ${_controller.imageList_Out.length}"
                                    : "${_controller.listItem_In.length} : ${_controller.listItem_Out.length}",
                                style: TextStyle(
                                    fontSize: _fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: Container(),
                            secondChild: _controller
                                    .isSwitchImagePicker //switchImagePicker
                                ? Column(
                                    children: [
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: Colors.black,
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Text(
                                              'นำเข้า', // "Items Out" text
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Colors.black,
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      _contentItemImage(
                                          _controller.imageList_In),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: Colors
                                                  .black, // Color of the line
                                              thickness:
                                                  1, // Thickness of the line
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    10), // Space around the text
                                            child: Text(
                                              'นำออก', // "Items Out" text
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Colors.black,
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      _contentItemImage(
                                          _controller.imageList_Out),
                                    ],
                                  )
                                : _contentItemList(),
                            crossFadeState: _controller.isExpanded_listItem
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: Duration(milliseconds: 300),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
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
                  SizedBox(height: 15),

                  // Divider(
                  //   color: Colors.black,
                  //   thickness: 0.5,
                  //   height: 10,
                  // ),
                  SizedBox(height: 10),

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
                            splashColor: Colors.green.withOpacity(0.3),
                            highlightColor: Colors.green.withOpacity(0.1),
                            child: Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                ),
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
                  SizedBox(height: 10),
                  // Divider(
                  //   color: Colors.black,
                  //   thickness: 0.5,
                  //   height: 10,
                  // ),
                  SizedBox(height: 20),
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
                              bool uploadSuccess =
                                  await _controller.uploadVisitorForm();
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
                                  GoRouter.of(context).push('/home');
                                });
                              } else {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.error(
                                    backgroundColor: Colors.red.shade700,
                                    icon: Icon(Icons.sentiment_very_satisfied,
                                        color: Colors.red.shade900, size: 120),
                                    message: "Upload Error",
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 16), // Increases button height
                            backgroundColor:
                                Colors.green, // Change color if needed
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
    // return
  }

  Widget dropDownBuilding(List<dynamic> _listBuilding) {
    if (_listBuilding.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    return DropdownMenu(
      requestFocusOnTap: false,
      initialSelection: _controller.selectedBuilding,
      label: Text(
        'บริเวณที่มาติดต่อ (Building):',
        style: TextStyle(
            color: Colors.black,
            fontSize: _fontSize + 6,
            fontWeight: FontWeight.bold),
      ),
      width: MediaQuery.of(context).size.width,
      textStyle: TextStyle(
        fontSize: _fontSize,
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
                WidgetStatePropertyAll<Color>(Colors.green.shade50),
          ),
        );
      }).toList(),
      onSelected: (value) {
        setState(() {
          _controller.selectedBuilding = value;
          _controller.checkBuildingOther();
        });
      },
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
    Uint8List? signatureDisplay =
        _controller.signatureSectionMap[sectionKeys[currentIndex]]?[0];
    DateTime? dateTimeSignDisplay =
        _controller.signatureSectionMap[sectionKeys[currentIndex]]?[1];
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
            border: Border.all(
              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(20.0)),
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
                                      color: Colors.black, fontSize: 24),
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
                margin: EdgeInsets.only(bottom: 15),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  destinations:
                      _controller.signatureSectionMap.entries.map((entry) {
                    int index = _controller.signatureSectionMap.keys
                        .toList()
                        .indexOf(entry.key);
                    String sectionLabel = entry.key;
                    // List<dynamic> signatureData = entry.value;

                    BorderRadius borderRadius = BorderRadius.zero;
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
                                  Colors.green.shade600.withOpacity(0.3),
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
                                          ? Colors.green
                                          : Colors.black,
                                    ),
                                    SizedBox(height: 5),
                                    Flexible(
                                      child: Text(
                                        sectionLabel,
                                        style: TextStyle(
                                          fontSize: _fontSize + 4,
                                          color: _isPressed
                                              ? Colors.green
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
          Container(
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
                            fontSize: _fontSize + 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Colors.black.withOpacity(0.5),
                      thickness: 1.0,
                      height: 10,
                    ),
                    SizedBox(height: 10),

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

                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      height: 52,
                      margin: EdgeInsets.only(top: 2.5),
                      padding: EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              onEditingComplete: () {
                                FocusScope.of(context)
                                    .unfocus(); // Also remove focus on enter
                              },
                              cursorColor: Colors.green.shade600,
                              readOnly: signaturesByDisplay.text.isNotEmpty,
                              autofocus: false,
                              controller: signaturesByDisplay,
                              maxLines: null,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: 'ลงชื่อ*',
                                border: InputBorder.none,
                              ),
                              style: TextStyle(fontSize: _fontSize + 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),

                    // Buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double screenWidth = constraints.maxWidth;
                        double buttonPadding = screenWidth < 799 ? 10.0 : 20.0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
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
                                      setStateDialog(() {});
                                      Navigator.of(context).pop();
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cancelBtnColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: buttonPadding, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cleaning_services_outlined,
                                      color: Colors.white, size: _fontSize),
                                  SizedBox(width: 8),
                                  Text(
                                    'ล้าง',
                                    style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
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
                                            DateTime.now(),
                                            _controller.signatureGlobalKey);
                                        setStateDialog(() {});
                                      } else {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            backgroundColor:
                                                Colors.red.shade700,
                                            icon: Icon(
                                                Icons.sentiment_very_satisfied,
                                                color: Colors.red.shade900,
                                                size: 120),
                                            message:
                                                "กรุณากรอกข้อมูลให้ครบถ้วน",
                                          ),
                                        );
                                      }
                                    }
                                  : null, // Disable button
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _acceptBtnColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: buttonPadding, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.save_alt_outlined,
                                      color: Colors.white, size: _fontSize),
                                  SizedBox(width: 8),
                                  Text(
                                    'ลงนาม',
                                    style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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

          // Exit Button (Close)
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.exit_to_app_rounded,
                color: _cancelBtnColor,
                size: 40,
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
      barrierDismissible: false,
      barrierLabel: '',
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
          },
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0).animate(a1),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.6, end: 1.0).animate(a1),
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(viewInsets: EdgeInsets.zero), // Prevent movement
                child: AlertDialog(
                  insetPadding: EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    side: BorderSide(color: Colors.white, width: 2.0),
                  ),
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
                                  SizedBox(height: 10),
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
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => popUpAddItem('in'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: EdgeInsets.all(0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 5,
                          ),
                          child: Icon(Icons.add_box_outlined,
                              color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'นำเข้า', // "Items Out" text
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                  ),
                  // Build the item list for "Items In"
                  _itemListGenerate(_controller.listItem_In, 'in'),

                  SizedBox(
                    height: 10,
                  ),

                  // "Items Out" Section with Line and Centered Text
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => popUpAddItem('out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: EdgeInsets.all(0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 5,
                          ),
                          child: Icon(Icons.add_box_outlined,
                              color: Colors.white, size: 24),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'นำออก', // "Items Out" text
                            style: TextStyle(
                              fontSize: _fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                  ),

                  // Build the item list for "Items Out"
                  _itemListGenerate(_controller.listItem_Out, 'out'),
                ],
              ),
            ),
          ],
        ),
      ],
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
          SizedBox(
            height: 10,
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
                ),
                child: _image != null
                    ? Image.file(
                        _image.absolute,
                        fit: BoxFit.fill,
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
                      color: const Color.fromARGB(255, 0, 0, 0), size: 40)),
              SizedBox(
                width: 30,
              ),
              IconButton(
                  // onPressed: () => _deleteImage(index, _imageList),
                  onPressed: () {
                    warningDialog('คุณต้องการจะลบรูปภาพใช่หรือไม่?', () {
                      setState(() {
                        _deleteImage(index, _imageList);
                        Navigator.of(context).pop();
                      });
                    });
                  },
                  icon: Icon(Icons.delete, color: _cancelBtnColor, size: 40)),
            ],
          ),
        ],
      ),
    );
  }

  // Function toggle the visibility of the visitor list
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
                .copyWith(viewInsets: EdgeInsets.zero), // Prevent UI movement
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24), // Rounded corners for the dialog
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                            color: Colors.green
                                .shade600, // Change this to any color you like
                            borderRadius: BorderRadius.vertical(
                                top:
                                    Radius.circular(24)), // Rounded top corners
                          ),
                          child: Center(
                            child: Text(
                              'รายละเอียด', // Title
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White text for contrast
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
                              // Dropdown
                              Text('คำนำหน้า:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: _fontSize)),
                              SizedBox(height: 2.5),
                              dropDownTitleName(),
                              SizedBox(height: 20),

                              // Name
                              InputField(
                                title: 'ชื่อ-สกุล:',
                                hint: '',
                                controller: _controller.fullNameController,
                                // isRequired: true,
                              ),
                              SizedBox(height: 20),

                              // Card ID
                              InputField(
                                title: 'หมายเลขบัตร:',
                                hint: '',
                                controller: _controller.cardIdController,
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
                                            .white, // Set background for better visibility
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
                                        .fullNameController.text.isEmpty ||
                                    _controller.cardIdController.text.isEmpty ||
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
                                  _controller.clearPersonController();
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

  void popUpEditPerson(Map<String, dynamic> entry) {
    _controller.titleNameController.text = entry['TitleName'] ?? '';
    _controller.fullNameController.text = entry['FullName'] ?? '';
    _controller.cardIdController.text = entry['Card_Id'] ?? '';
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
                .copyWith(viewInsets: EdgeInsets.zero), // Prevent UI movement
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24), // Rounded corners for the dialog
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                            color: Colors.green
                                .shade600, // Change this to any color you like
                            borderRadius: BorderRadius.vertical(
                                top:
                                    Radius.circular(24)), // Rounded top corners
                          ),
                          child: Center(
                            child: Text(
                              'รายละเอียด', // Title
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // White text for contrast
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
                              // Dropdown
                              Text('คำนำหน้า:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: _fontSize)),
                              SizedBox(height: 2.5),
                              dropDownTitleName(),
                              SizedBox(height: 20),

                              // Name
                              InputField(
                                  title: 'ชื่อ-สกุล:',
                                  hint: '',
                                  controller: _controller.fullNameController),
                              SizedBox(height: 20),

                              // Card ID
                              InputField(
                                  title: 'หมายเลขบัตร:',
                                  hint: '',
                                  controller: _controller.cardIdController),
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
                                            .white, // Set background for better visibility
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
                                _controller.clearPersonController();
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
                                'แก้ไข',
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

  Widget dropDownTitleName() {
    List<String> titleNameList = ['นาย', 'น.ส.', 'นาง', 'Mr.', 'Ms.', 'Mrs.'];
    if (_controller.titleNameController.text.isEmpty) {
      _controller.titleNameController.text = titleNameList[0];
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        value: _controller.titleNameController.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            _controller.titleNameController.text = newValue!;
          });
        },
      ),
    );
  }

  //visitor list generate by widget
  Widget personListGenerate() {
    return _controller.personList.isNotEmpty
        ? Column(
            children: _controller.personList.map((entry) {
              return Container(
                child: Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    color: Colors.green.shade50,
                    elevation: 4.0,
                    semanticContainer: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(
                                          12)), // Rounded top corners
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: 70,
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                          Text(
                                            'Card : ${entry['Card_Id'] ?? ''}',
                                            style: TextStyle(
                                              fontSize: _fontSize - 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                color: Colors.black,
                                height: 10.0,
                                thickness: 1.0,
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ลายเซ็น:',
                                    style: TextStyle(
                                        fontSize: _fontSize,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Center(
                                    child: entry['Signature'] != null
                                        ? Image.memory(
                                            entry['Signature'],
                                            fit: BoxFit.contain,
                                          )
                                        : Text(
                                            'No Signature Available',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 50,
                          bottom: 0,
                          child: IconButton(
                            icon: Icon(Icons.edit_document,
                                color: const Color.fromARGB(255, 0, 0, 0),
                                size: 40),
                            onPressed: () => popUpEditPerson(entry),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: Icon(Icons.group_remove,
                                color: _cancelBtnColor, size: 40),
                            onPressed: () => warningDialog(
                                'ต้องการลบข้อมูลรายชื่อของ ${entry['TitleName']} ${entry['FullName']} ใช่หรือไม่?',
                                () {
                              setState(() {
                                _controller.personList.remove(entry);
                                Navigator.of(context).pop();
                              });
                            }),
                          ),
                        ),
                      ],
                    )),
              );
            }).toList(),
          )
        : Container();
  }

  //Item list generate by Widget
  Widget _itemListGenerate(List<Map<String, String>> itemList, String type) {
    return itemList.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: itemList.map((entry) {
              return Card(
                color: Colors.green.shade50,
                margin: EdgeInsets.symmetric(vertical: 5),
                elevation: 2.0,
                semanticContainer: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // Left side: Item icon
                      Icon(Icons.shopping_bag, // Icon item
                          color: Colors.black,
                          size: 40),
                      SizedBox(width: 15),
                      Expanded(
                        // Name item
                        child: Text(
                          '${entry['name']}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: _fontSize),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // Right side: Item name
                      IconButton(
                        // Edit button
                        icon: Icon(Icons.edit_document),
                        onPressed: () => popUpEditItem(entry),
                      ),
                      IconButton(
                        //  Delete button
                        icon: Icon(
                          Icons.delete,
                          color: _cancelBtnColor,
                        ),
                        onPressed: () => warningDialog(
                            'ต้องการลบรายการ ${entry['name']} ใช่หรือไม่?', () {
                          setState(() {
                            if (type == 'in') {
                              _controller.listItem_In
                                  .remove(entry); // Remove item from 'In' list
                            } else {
                              _controller.listItem_Out
                                  .remove(entry); // Remove item from 'Out' list
                            }
                          });
                          Navigator.of(context).pop();
                        }),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        : Container();
  }

  void popUpEditItem(Map<String, String> entry) {
    _controller.itemNameController.text = entry['name']!;

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
                borderRadius: BorderRadius.circular(24),
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
                            color: Colors.green,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              'แก้ไขข้อมูลสิ่งของ',
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

                    // 🔹 Body Content
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
                          SizedBox(width: 10),
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
                                  await _controller.editItemTypeList(entry);
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
                                'แก้ไข',
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
            data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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
                            color: Colors.green.shade600,
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
                          SizedBox(width: 10),
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
            textScaler: TextScaler.linear(
                MediaQuery.of(context).size.width > 799 ? 1.5 : 1.0),
          ),
          child: Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.green,
              colorScheme: ColorScheme.light(
                primary: Colors.green,
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
    }
  }

  //Function Date Picker
  Future<void> _datePicker(BuildContext context, DateTime? _date, String type) async {
    DateTime initialDate = DateTime.now();
    DateTime? _pickerDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(DateTime.now().year - 7),
        lastDate: DateTime(DateTime.now().year + 7),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                  MediaQuery.of(context).size.width > 799 ? 1.5 : 1.0),
            ),
            child: Theme(
              data: ThemeData.light().copyWith(
                primaryColor: Colors.green,
                colorScheme: ColorScheme.light(
                  primary: Colors.green,
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
        bool checkInFrist = await _controller.checkDateInFrist();
        if (!checkInFrist) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              backgroundColor: Colors.red.shade700,
              icon: Icon(Icons.sentiment_very_satisfied,
                  color: Colors.red.shade900, size: 120),
              message: "วันที่ออกต้องมากกว่าวันที่เข้าเสมอ",
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

  //Function to take photo with camera
  Future _pickImageFromCamera(int index, List<File?> _imageList) async {
    try {
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
    } catch (err, stackTrace) {
      print("Error taking photo: $err");
      print(stackTrace);
    }
  }

  Cleartemporary cleartemporary = Cleartemporary();

  //Function Delete Image
  void _deleteImage(int index, List<File?> _imageList) async {
    if (_imageList[index] != null) {
      try {
        _imageList[index]!.deleteSync();
        _imageList.removeAt(index);
      } catch (err, stackTrace) {
        print("Error deleting file: $err");
        print("StackTrace: $stackTrace");
      }
    }
    setState(() {});
  }

  void warningDialog(String description, VoidCallback _callFunction) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      headerAnimationLoop: false,
      animType: AnimType.topSlide,
      showCloseIcon: true,
      title: 'แจ้งเตือน',
      titleTextStyle:
          TextStyle(fontSize: _fontSize + 10, fontWeight: FontWeight.bold),
      desc: description,
      descTextStyle:
          TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
      btnOk: ElevatedButton(
        onPressed: () async {
          _callFunction();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _acceptBtnColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Circular shape
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(1),
        ),
        child: Text(
          'ยืนยัน',
          style: TextStyle(
              color: Colors.white,
              fontSize: _fontSize,
              fontWeight: FontWeight.bold),
        ),
      ),
      btnCancel: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _cancelBtnColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Circular shape
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          elevation: 8, // Add elevation (shadow effect)
          shadowColor: Colors.black.withOpacity(1), // Shadow color
        ),
        child: Text(
          'ยกเลิก',
          style: TextStyle(
              color: Colors.white,
              fontSize: _fontSize,
              fontWeight: FontWeight.bold),
        ),
      ),
    ).show();
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

  @override
  void initState() {
    super.initState();
    _validateInput();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        if (screenWidth > 799) {
          _fontSize += 8.0;
        }
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
            style:
                TextStyle(fontSize: _fontSize + 2, fontWeight: FontWeight.bold),
          ),
          // SizedBox(height: 5),
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
                    inputFormatters: widget.maxLength != null
                    ? [LengthLimitingTextInputFormatter(widget.maxLength)]
                    : [LengthLimitingTextInputFormatter(100)],
                    onChanged: (value) => _validateInput(),
                    onEditingComplete: () => FocusScope.of(context).unfocus(),
                    cursorColor: Colors.green.shade600,
                    readOnly: widget.widget != null,
                    autofocus: false,
                    controller: widget.controller,
                    maxLines: null,
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

//Class for scroll by mouse and touch
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
