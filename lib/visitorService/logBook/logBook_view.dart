import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/main.dart';
import 'package:toppan_app/visitorService/logBook/logBook_controller.dart';

class LogBookView {
  Widget LogDocFormWidget(BuildContext context) {
    return LogBookPage();
  }
}

class LogBookPage extends StatefulWidget {
  @override
  _LogBookPageState createState() => _LogBookPageState();
}

class _LogBookPageState extends State<LogBookPage> with RouteAware {
  LogBookController _controller = LogBookController();
  double _fontSize = ApiConfig.fontSize;

  @override
  void initState() {
    super.initState();
    preparePage();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      setState(() {
        _controller.startAnimation = true;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      setState(() {
        if (screenWidth > 799) {
          _fontSize += 8.0;
        }
      });
    });
    // Clear Flutter's image cache
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void preparePage() async {
    _controller.selectedType = _controller.typeOptions[0];
    await _controller.preparePage(context);
    setState(() {
      _controller.filteredDocument = _controller.list_Request;
      filterDocuments();
    });
  }

  void filterDocuments() {
    setState(() {
      _controller.startAnimation = false;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _controller.startAnimation = true;
        _controller.filterRequestList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          children: [
            SizedBox(
              height: 5,
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SearchInputBar(),
            ),
            listForm(),
          ],
        ),
      ),
    );
  }

  Widget SearchInputBar() {
    final ScrollController controller = ScrollController();
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
            margin: EdgeInsets.all(
                MediaQuery.of(context).size.width > 799 ? 14 : 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
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
                        controller:
                            controller, // Use the controller for scrolling
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 5,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: InputField(
                                    title: "เริ่มต้น:",
                                    hint: "",
                                    controller: _controller.sDateControl,
                                    widget: IconButton(
                                      icon: Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () async {
                                        await _datePicker(context,
                                            _controller.startDate, 'start');
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: InputField(
                                    title: "สิ้นสุด:",
                                    hint: "",
                                    controller: _controller.eDateControl,
                                    widget: IconButton(
                                      icon: Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () async {
                                        await _datePicker(context,
                                            _controller.endDate, 'end');
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(
                              height: 20,
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  // Makes button take up full available width
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await _controller.searchDocByRangeDate();
                                      print(_controller.list_Request);
                                      filterDocuments();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'ค้นหา',
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(
                              height: 30,
                            ),

                            //Select Type Search (Dropdown)
                            DropdownButtonFormField<String>(
                              value: _controller.selectedType,
                              decoration: InputDecoration(
                                labelText: 'ประเภท (Employee/Visitor)',
                                labelStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: _fontSize + 2),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.blue),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black), // White border
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors
                                          .black), // White border on focus
                                ),
                              ),
                              items: _controller.typeOptions.map((String type) {
                                Icon icon;
                                switch (type) {
                                  case 'Employee':
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.orange);
                                    break;
                                  case 'Visitor':
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.green);
                                    break;
                                  default:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.blue);
                                }

                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      icon,
                                      SizedBox(width: 10),
                                      Text(
                                        type,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: _fontSize),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _controller.selectedType = newValue;
                                });
                                filterDocuments();
                              },
                              style: TextStyle(color: Colors.black),
                              iconEnabledColor: Colors.black,
                              iconDisabledColor: Colors.black,
                              dropdownColor: Colors.white.withOpacity(0.8),
                            ),

                            SizedBox(height: 20),

                            if(_controller.selectedType == "Employee")
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                        'บริเวณที่ออก:',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize),
                                      ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        child: Row(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Transform.scale(
                                              scale: 1.5,
                                              child: Checkbox(
                                                value: _controller.checkBF,
                                                activeColor: Colors.blue,
                                                onChanged: (value) {
                                                  setState(() {
                                                    if (value == false && !_controller.checkC) {
                                                      return;
                                                    }
                                                    _controller.checkBF = value!;
                                                    filterDocuments();
                                                  });
                                                },
                                              ),
                                            ),
                                            Text("BF",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize),),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 20,),
                                      Container(
                                        child: Row(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Transform.scale(
                                              scale: 1.5,
                                              child: Checkbox(
                                                value: _controller.checkC,
                                                activeColor: Colors.blue,
                                                onChanged: (value) {
                                                  setState(() {
                                                    if (value == false && !_controller.checkBF) {
                                                      return;
                                                    }
                                                    _controller.checkC = value!;
                                                    filterDocuments();
                                                  });
                                                },
                                              ),
                                            ),
                                            Text("Card",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize),),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                          ],
                        ))))));
  }

  Widget listForm() {
    final ScrollController controller = ScrollController();
    return Expanded(
      child: _controller.filteredDocument.isEmpty
          ? SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.4, // Adjust height dynamically
                child: Center(
                  child: Text(
                    '-------- ยังไม่มีรายการในตอนนี้ --------',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade300),
                  ),
                ),
              ),
            )
          : ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView.builder(
                controller: controller,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _controller.filteredDocument.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> entry =
                      _controller.filteredDocument[index];
                  return itemForm(index, entry);
                },
              ),
            ),
    );
  }

  void initializeDateThaiFormatting() async {
    await initializeDateFormatting('th_TH', null);
  }

  Widget itemForm(int index, Map<String, dynamic> entry) {
    // Color
    Color borderColor = Colors.black;
    String timeRanges = '';
    String formattedDate = '';
    // DateTime
    initializeDateThaiFormatting();
    final dateIn = DateTime.parse(entry['date_in']).toLocal();
    final dateOut = DateTime.parse(entry['date_out']).toLocal();

    final timeIn = entry['time_in'].substring(0, 5);
    final timeOut = entry['time_out'].substring(0, 5);


    final bool sameDate = dateIn.year == dateOut.year &&
      dateIn.month == dateOut.month &&
      dateIn.day == dateOut.day;
    final bool sameTime = timeIn == timeOut;

    // Set styles and display
    if (entry['request_type'] == 'VISITOR') {
      borderColor = Colors.green;

      formattedDate = DateFormat("d MMMM yyyy", "th_TH").format(dateIn);
      timeRanges = '$timeIn ถึง $timeOut';
    } else if (entry['request_type'] == 'EMPLOYEE') {
      borderColor = Colors.orange;

      formattedDate = DateFormat("d MMMM yyyy", "th_TH").format(dateOut);

      if (sameDate && sameTime) {
        timeRanges = '$timeOut';
      } else {
        timeRanges = '$timeOut ถึง $timeIn';
      }
    }

    double screenWidth = MediaQuery.of(context).size.width;
    return AnimatedContainer(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform: Matrix4.translationValues(
          _controller.startAnimation ? 0 : screenWidth, 0, 0),
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 5.0,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  // color: Colors.white,
                  color: borderColor,
                  offset: Offset(-5, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Slidable(
                  // startActionPane: ActionPane(motion: ScrollMotion(), children: [
                  //   CustomSlidableAction(
                  //     onPressed: (BuildContext context) {
                  //       notApproveDocument();
                  //     },
                  //     backgroundColor: Color(0xFFFE4A49),
                  //     foregroundColor: Colors.white,
                  //     child: Column(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(
                  //           Icons.delete,
                  //           size: 40,
                  //         ),
                  //         SizedBox(
                  //           height: 5,
                  //         ),
                  //         Text(
                  //           "Delete",
                  //           style:
                  //               TextStyle(fontSize: _fontSize, color: Colors.white),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ]),
                  // endActionPane: ActionPane(motion: ScrollMotion(), children: [
                  //   CustomSlidableAction(
                  //     onPressed: (BuildContext context) {
                  //       approveDocument();
                  //     },
                  //     backgroundColor: Colors.blue,
                  //     foregroundColor: Colors.white,
                  //     child: Column(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Icon(
                  //           Icons.library_add_check,
                  //           size: 40,
                  //         ),
                  //         SizedBox(
                  //           height: 5,
                  //         ),
                  //         Text(
                  //           "Approve",
                  //           style:
                  //               TextStyle(fontSize: _fontSize, color: Colors.white),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ]),
                  child: Material(
                // color: borderColor,
                color: const Color.fromARGB(185, 255, 255, 255),
                child: InkWell(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(color: borderColor, width: 3.0),
                                  shape: BoxShape.circle),
                              child: Icon(
                                Icons.feed,
                                color: borderColor,
                                size: 55,
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'องค์กร : ${entry['company']}',
                                    style: TextStyle(
                                      fontSize: _fontSize + 4,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: true,
                                  ),
                                  Divider(
                                    color: borderColor,
                                    thickness: 2,
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'ประเภท ${entry['request_type'][0] + entry['request_type'].substring(1).toLowerCase()}',
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: true,
                                  ),
                                  SizedBox(height: 5),
                                  if (MediaQuery.of(context).size.width > 799) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'วันที่: ${formattedDate}',
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        ),
                                        SizedBox(
                                          width: 30,
                                        ),
                                        Text(
                                          'เวลา: ${timeRanges}',
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        ),
                                      ],
                                    )
                                  ] else ...[
                                    Text(
                                      'วันที่: ${formattedDate}',
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: true,
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'เวลา: ${timeRanges}',
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      softWrap: true,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    popUpShowInformationForm(entry);
                  },
                ),
              )),
            ),
          ),

      if (entry['approved_status'] == 0)
        Positioned(
          top: 6,
          left: 23,
          child: Icon(
            Icons.turned_in,
            color: Colors.red,
            size: 50,
          ),
        ),
        ],
      ),
    );
  }

  void popUpShowInformationForm(Map<String, dynamic> entry) {
    final ScrollController dialogScrollController = ScrollController();

    // Color
    Color? _colorHeader;
    if (entry['request_type'] == 'VISITOR') {
      _colorHeader = Colors.green; // Green for visitors
    } else if (entry['request_type'] == 'EMPLOYEE') {
      _colorHeader = Colors.orange; // Orange for employees
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          double screenWidth = MediaQuery.of(context).size.width;

          return Dialog(
            insetPadding:
                screenWidth > 799 ? null : EdgeInsets.only(left: 16, right: 16),
            child: Container(
              width: screenWidth > 799 ? 600 : double.infinity,
              height: MediaQuery.of(context).size.height * (3 / 4),
              child: Stack(
                children: [
                  Positioned(
                    //Close
                    top: 3,
                    right: 5,
                    child: IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: Color(0xFFFE4A49),
                        size: 45,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 10, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 36,
                              color: _colorHeader,
                            ),
                            SizedBox(width: 10),
                            Text(
                              '${entry['request_type'][0] + entry['request_type'].substring(1).toLowerCase()}',
                              style: TextStyle(
                                  fontSize: _fontSize + 4,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: _colorHeader,
                        thickness: 1.5,
                        height: 10,
                      ),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                            scrollbars: false,
                          ),
                          child: SingleChildScrollView(
                            controller: dialogScrollController,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: contentViewOnlyDocument(
                                  setStateDialog, entry),
                            ),
                          ),
                        ),
                      ),
                      // Footer
                      Divider(
                        color: _colorHeader,
                        thickness: 1.5,
                        height: 10,
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colorHeader,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            entry['logBook'] = true; //check logBook
                            switch (entry['request_type']
                                .toString()
                                .toLowerCase()) {
                              case 'visitor':
                                await GoRouter.of(context).push(
                                    '/visitor?option=visitor',
                                    extra: entry);
                                break;
                              case 'employee':
                                await GoRouter.of(context).push(
                                    '/visitor?option=employee',
                                    extra: entry);
                                break;
                            }
                          },
                          child: Text(
                            "เอกสาร",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget contentViewOnlyDocument(
      StateSetter setStateDialog, Map<String, dynamic> entry) {
    String objectiveType = '';
    switch (entry['objective_type']) {
      case 1:
        objectiveType = 'ออกนอกโรงงาน';
        break;
      case 2:
        objectiveType = 'นำสินค้า/สิ่งของออกพื้นที่การผลิต';
        break;
      case 3:
        objectiveType = 'นำสินค้า/สิ่งของออกโรงงาน';
        break;
    }
    final dateOut = DateTime.parse(entry['date_out']).toLocal();
    final dateIn = DateTime.parse(entry['date_in']).toLocal();
    final formattedDateOut = DateFormat("d MMMM yyyy", "th_TH").format(dateOut);
    final formattedDateIn = DateFormat("d MMMM yyyy", "th_TH").format(dateIn);
    final timeOut = entry['time_out'].substring(0, 5);
    final timeIn = entry['time_in'].substring(0, 5);
    bool isDateSame = formattedDateOut == formattedDateIn;
    bool isTimeSame = timeOut == timeIn;
    bool isDateTime = isDateSame && isTimeSame;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          entry['request_type'] == 'EMPLOYEE'
              // Employee
              ? Column(
                  children: [
                    // add employee
                    SizedBox(height: 10),
                    InfoRow(
                        label: 'ขออนุญาต:',
                        value: objectiveType,
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'เวลาออก:',
                        value: '$formattedDateOut     $timeOut น.',
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    if (!isDateTime) ...[
                      InfoRow(
                          label: 'เวลากลับ:',
                          value: '$formattedDateIn     $timeIn น.',
                          fontSize: _fontSize),
                      SizedBox(height: 25),
                    ],
                    InfoRow(
                        label: 'วัตถุประสงค์:',
                        value: entry['objective'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                  ],
                )
              // Visitor
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    InfoRow(
                        label: 'องค์กร:',
                        value: entry['company'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'เวลาเข้า:',
                        value: DateFormat("d MMMM yyyy", "th_TH").format(
                                DateTime.parse(entry['date_in']).toLocal()) +
                            '     ' +
                            entry['time_in'].substring(0, 5) +
                            ' น.',
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'เวลาออก:',
                        value: DateFormat("d MMMM yyyy", "th_TH").format(
                                DateTime.parse(entry['date_out']).toLocal()) +
                            '     ' +
                            entry['time_out'].substring(0, 5) +
                            ' น.',
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'ติดต่อ:',
                        value: entry['contact'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'แผนก:',
                        value: entry['dept'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'วัตถุประสงค์:',
                        value: entry['objective'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                  ],
                ),

          // Show people in form
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                        child: Row(
                      children: [
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 36,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text("รายชื่อ",
                            style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                      ],
                    )),
                  ],
                ),
                generatePeopleList(entry['people']),

                // Show Item in/out
                contentItemDisplay(
                    entry['item_in'], entry['item_out'], entry['request_type']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget generatePeopleList(List<dynamic> personList) {
    return personList.isNotEmpty
        ? Column(
            children: personList.map((entry) {
              return Card(
                margin: EdgeInsets.symmetric(vertical: 5),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white,
                    width: 0.5,
                  ),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.person, color: Colors.black, size: 40),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              '${entry['TitleName']} ${entry['FullName']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _fontSize,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card,
                              color: Colors.black, size: 40),
                          SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              '${entry['Card_Id'] ?? ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _fontSize,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        : Container();
  }

  Widget contentItemDisplay(
    Map<String, dynamic>? item_in,
    Map<String, dynamic>? item_out,
    String docType,
  ) {
    final List<dynamic>? itemsIn = item_in?['items'] as List<dynamic>?;
    final List<dynamic>? imagesIn = item_in?['images'] as List<dynamic>?;

    final List<dynamic>? itemsOut = item_out?['items'] as List<dynamic>?;
    final List<dynamic>? imagesOut = item_out?['images'] as List<dynamic>?;

    bool isItemsInEmpty = itemsIn == null ||
        itemsIn.isEmpty ||
        itemsIn.every((item) => (item as String?)?.trim().isEmpty ?? true);
    bool isImagesInEmpty = imagesIn == null ||
        imagesIn.isEmpty ||
        imagesIn.every((img) => (img as String?)?.trim().isEmpty ?? true);

    bool isItemsOutEmpty = itemsOut == null ||
        itemsOut.isEmpty ||
        itemsOut.every((item) => (item as String?)?.trim().isEmpty ?? true);
    bool isImagesOutEmpty = imagesOut == null ||
        imagesOut.isEmpty ||
        imagesOut.every((img) => (img as String?)?.trim().isEmpty ?? true);

    bool isInDataEmpty = isItemsInEmpty && isImagesInEmpty;
    bool isOutDataEmpty = isItemsOutEmpty && isImagesOutEmpty;

    Widget buildSection(
        String title, List<dynamic>? images, List<dynamic>? items) {
      if ((images == null || images.isEmpty) &&
          (items == null || items.isEmpty)) {
        return SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: 5),
                    Expanded(child: Divider(color: Colors.black, thickness: 1)),
                    Icon(Icons.shopping_bag, color: Colors.black, size: 36),
                    SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _fontSize + 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(child: Divider(color: Colors.black, thickness: 1)),
                    SizedBox(width: 5),
                  ],
                ),
              ),
            ],
          ),
          generateItemImage(images ?? []),
          SizedBox(height: 15),
          generateItemList(items ?? []),
        ],
      );
    }

    final normalizedDocType = docType.toUpperCase();
    List<Widget> sections = [];
    if (normalizedDocType == 'VISITOR') {
      if (!isInDataEmpty)
        sections.add(buildSection("สิ่งของนำเข้า", imagesIn, itemsIn));
      if (!isOutDataEmpty)
        sections.add(buildSection("สิ่งของนำออก", imagesOut, itemsOut));
    } else if (normalizedDocType == 'EMPLOYEE') {
      if (!isOutDataEmpty)
        sections.add(buildSection("สิ่งของนำออก", imagesOut, itemsOut));
      if (!isInDataEmpty)
        sections.add(buildSection("สิ่งของนำเข้า", imagesIn, itemsIn));
    }

    if (sections.isEmpty) return Container();

    return Column(children: sections);
  }

  Widget generateItemList(List<dynamic> itemList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: itemList.map<Widget>((entry) {
        return Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 5),
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag, color: Colors.black, size: 40),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    entry,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _fontSize,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget generateItemImage(List<dynamic> imageList) {
    if (imageList.isEmpty) {
      return Container();
    }
    double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        if (screenWidth < 799) ...[
          Column(
            children: imageList.map((imageUrl) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                height: 200,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.broken_image, size: 50, color: Colors.red),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          if (imageList.length > 1)
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imageList.length,
              itemBuilder: (context, index) {
                return Container(
                  height: 200,
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.network(
                    imageList[index],
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image, size: 50, color: Colors.red),
                  ),
                );
              },
            )
          else
            Container(
              height: 200,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Image.network(
                imageList[0],
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.broken_image, size: 50, color: Colors.red),
              ),
            ),
        ],
      ],
    );
  }

  //Function Date Picker
  Future<void> _datePicker(BuildContext context, DateTime? _date, String type) async {
    DateTime initialDate = _date ?? DateTime.now();
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
                primaryColor: Colors.blue,
                colorScheme: ColorScheme.light(
                  primary: Colors.blue,
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
        if (type == 'end') {
          _controller.endDate = initialDate;
          _controller.eDateControl.text =
              DateFormat('yyyy-MM-dd').format(initialDate);
        } else if (type == 'start') {
          _controller.startDate = initialDate;
          _controller.sDateControl.text =
              DateFormat('yyyy-MM-dd').format(initialDate);
        }
      });

      if (_controller.startDate != null && _controller.endDate != null) {
        bool checkInFrist = await _controller.checkDateInFrist();
        if (!checkInFrist) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              backgroundColor: Colors.red.shade700,
              icon: Icon(Icons.sentiment_very_satisfied,
                  color: Colors.red.shade900, size: 120),
              message: "ระยะเวลาสิ้นสุดต้องมากกว่าเสมอ",
            ),
          );
          if (type == 'end') {
            _controller.endDate = null;
            _controller.eDateControl.text = '';
          } else if (type == 'start') {
            _controller.startDate = null;
            _controller.sDateControl.text = '';
          }
        }
      }
    }
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final double fontSize;
  final double labelWidth;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    required this.fontSize,
    this.labelWidth = 130.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(width: 10),
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            textAlign: TextAlign.left,
            softWrap: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            value ?? '-',
            style: TextStyle(fontSize: fontSize),
            softWrap: true,
          ),
        ),
        SizedBox(width: 10),
      ],
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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
