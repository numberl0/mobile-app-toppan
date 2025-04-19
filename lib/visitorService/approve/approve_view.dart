import 'dart:ui';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/visitorService/approve/approve_controller.dart';

class ApproveView {
  Widget approveFormWidget(BuildContext context) {
    return ApprovePage();
  }
}

class ApprovePage extends StatefulWidget {
  @override
  _ApprovePageState createState() => _ApprovePageState();
}

class _ApprovePageState extends State<ApprovePage> {

  ApproveController _controller = ApproveController();

  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    preparePage();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      setState(() {
        _controller.startAnimation = true;
      });
    });
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).size.width > 799) {
      setState(() {
        _fontSize = 20.0;
      });
    }else{
      setState(() {
        _fontSize = 16.0;
      });
    }
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
              SizedBox(height: 5,),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: SearchInputBar(),
              ),
              //button approve
              Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            width: double.infinity, // Button expands to full width
            child: ElevatedButton(
        onPressed: () {
          AwesomeDialog(
                                    context: context,
                                    dialogType: DialogType.info,
                                    buttonsBorderRadius: const BorderRadius.all(
                                      Radius.circular(2),
                                    ),
                                    dismissOnTouchOutside: true,
                                    dismissOnBackKeyPress: false,
                                    headerAnimationLoop: false,
                                    animType: AnimType.bottomSlide,
                                    title: 'คำเตือน',
                                    titleTextStyle: TextStyle(
                                        fontSize: _fontSize + 10,
                                        fontWeight: FontWeight.bold),
                                    desc:
                                        'คุณต้องการอนุมัติเอกสารทั้งหมดใช่หรือไม่?',
                                    descTextStyle: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold),
                                    showCloseIcon: true,
                                    btnCancelText: 'ยกเลิก',
                                    btnOkText: 'ยืนยัน',
                                    // btnCancelColor: Colors.red.shade600,
                                    btnCancel: ElevatedButton(
                                      onPressed: () { Navigator.pop(context); },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30), // Circular shape
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                        elevation: 8, // Add elevation (shadow effect)
                                        shadowColor: Colors.black.withOpacity(1), // Shadow color
                                      ),
                                      child: Text(
                                        'ยกเลิก',
                                        style: TextStyle(color: Colors.white, fontSize: _fontSize, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    btnOk: ElevatedButton(
                                      onPressed: () async { 
                                        if(_controller.filteredDocument.isNotEmpty) {
                                          bool status = await _controller.approvedAll();
                                          if(!status) {
                                          showTopSnackBar(
                                              Overlay.of(context),
                                              CustomSnackBar.error(
                                                backgroundColor: Colors.red.shade700,
                                                icon: Icon(Icons.sentiment_very_satisfied,
                                                color: Colors.red.shade900, size: 120),
                                                message: 'อนุมัติไม่สำเร็จ',
                                              ),
                                            );
                                        }else{
                                          setState(() {
                                            preparePage();
                                          });
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.success(
                                              backgroundColor: Colors.green.shade500,
                                              icon: Icon(Icons.sentiment_very_satisfied, color: Colors.green.shade600, size: 120),
                                              message: 'อนุมัติเรียบร้อย',
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                        }else{
                                          showTopSnackBar(
                                              Overlay.of(context),
                                              CustomSnackBar.error(
                                                backgroundColor: Colors.red.shade700,
                                                icon: Icon(Icons.sentiment_very_satisfied,
                                                color: Colors.red.shade900, size: 120),
                                                message: 'ไม่มีรายการคำร้อง',
                                              ),
                                            );
                                          Navigator.pop(context);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30), // Circular shape
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                        elevation: 8,
                                        shadowColor: Colors.black.withOpacity(1),
                                      ),
                                      child: Text(
                                        'อนุมัติ',
                                        style: TextStyle(color: Colors.white, fontSize: _fontSize, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ).show();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white, width: 1),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_add_check, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              "อนุมัติทั้งหมด",
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
            ),
          ),
        ),
              listForm(),
            ],
          ),
      ),
    );
  }

  Widget SearchInputBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        SizedBox(height: 5),

        //Select Type Search (Dropdown)
        DropdownButtonFormField<String>(
          value: _controller.selectedType,
          decoration: InputDecoration(
            labelText: 'ประเภท (Employee/Visitor)',
            labelStyle: TextStyle(color: Colors.white, fontSize: _fontSize + 2),
            prefixIcon: Icon(Icons.search, color: Colors.white),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          items: _controller.typeOptions.map((String type) {
            Icon icon;
            switch (type) {
              case 'Employee':
                icon = Icon(Icons.layers_rounded, color: Colors.orange);
                break;
              case 'Visitor':
                icon = Icon(Icons.layers_rounded, color: Colors.green);
                break;
              default:
                icon = Icon(Icons.layers_rounded, color:Colors.white);
            }
  
            return DropdownMenuItem<String>(
              value: type,
              child: Row(
                  children: [
                    icon,
                    SizedBox(width: 10),
                    Text(
                      type,
                      style: TextStyle(color: Colors.white, fontSize: _fontSize),
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
          style: TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          iconDisabledColor: Colors.white,
          dropdownColor: Colors.black.withOpacity(0.8),
          
        ),

        SizedBox(height: 10),

        //Select Company Search
        TextField(
          controller: _controller.companyController,
          cursorColor: Colors.white,
          style: TextStyle(color: Colors.white, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'บริษัท',
            labelStyle: TextStyle(color: Colors.white, fontSize: _fontSize + 2),
            prefixIcon: Icon(Icons.business_rounded, color: Colors.white),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white), // White border
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white), // White border on focus
            ),
          ),
          onChanged: (_) => filterDocuments(),
          
        ),
        
        SizedBox(height: 10),

        //Select Name Search
        TextField(
          controller: _controller.nameController,
          cursorColor: Colors.white,
          style: TextStyle(color: Colors.white, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'ชื่อ',
            labelStyle: TextStyle(color: Colors.white, fontSize: _fontSize + 2),
            prefixIcon: Icon(Icons.person, color: Colors.white),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white), // White border
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white), // White border on focus
            ),
          ),
          onChanged: (_) => filterDocuments(),
          
        ),
        
      ],
    );
  }

  Widget listForm() {
  final ScrollController controller = ScrollController();
  return Expanded(
    child: _controller.filteredDocument.isEmpty
        ? SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4, // Adjust height dynamically
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
                Map<String, dynamic> entry = _controller.filteredDocument[index];
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
    if (entry['request_type'] == 'VISITOR' ) {
      borderColor = Colors.green; // Green for visitors
    } else if (entry['request_type'] == 'EMPLOYEE') {
      borderColor = Colors.orange; // Orange for employees
    }
    // Time ranges
    String timeRanges = entry['time_in'].substring(0, 5) + ' ถึง ' + entry['time_out'].substring(0, 5);
    // DateTime
    initializeDateThaiFormatting();
    String formattedDate = DateFormat("d MMMM yyyy", "th_TH").format(DateTime.parse(entry['date']).toLocal());

    double screenWidth = MediaQuery.of(context).size.width;
    return AnimatedContainer(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform:
          Matrix4.translationValues(_controller.startAnimation ? 0 : screenWidth, 0, 0),
      child: Container(
        margin: EdgeInsets.all(16),
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 5.0,
              offset: Offset(0, 5),
            ),
            BoxShadow(
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
                color: const Color.fromARGB(185, 255, 255, 255),
                child: InkWell(
                  child: Container(
                    // padding: EdgeInsets.all(30.0),
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
                                  border: Border.all(
                                      color: borderColor, width: 3.0),
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
                                    'บริษัท : ${entry['company']}',
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
                                      fontWeight: FontWeight.bold,),
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
                                      fontWeight: FontWeight.bold,),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: true,
                                            ),
                                            SizedBox(width: 30,),
                                            Text(
                                              'เวลา: ${timeRanges}',
                                              style: TextStyle(
                                                  fontSize: _fontSize,
                                                  color: Colors.black,
                                      fontWeight: FontWeight.bold,),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: true,
                                            ),
                                        ],
                                      )
                                  ]else ...[
                                    Text(
                                      'วันที่: ${formattedDate}',
                                      style: TextStyle(
                                          fontSize: _fontSize,
                                          color: Colors.black,
                                      fontWeight: FontWeight.bold,),
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
                                      fontWeight: FontWeight.bold,),
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
    );
  }


  void notApproveDocument(){
    print("Not Approve");
  }

  void approveDocument() {
    print("Approve");
  }


  void popUpShowInformationForm(Map<String, dynamic> entry) {
  final ScrollController dialogScrollController = ScrollController();

  // Determine header color
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
            width: screenWidth > 799 ? 600 : double.infinity, // Responsive width
            height: MediaQuery.of(context).size.height * (3 / 4),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Color(0xFFFE4A49),
                      size: 32,
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
                    // Content with scroll
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
                            padding:
                                EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            child: contentViewOnlyDocument(setStateDialog, entry),
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
                          // Navigate to edit page using GoRouter
                          bool status = await _controller.approvedDocument(entry);
                          if(status) {
                            showTopSnackBar(
                              Overlay.of(context),
                              CustomSnackBar.success(
                                backgroundColor: Colors.green.shade500,
                                icon: Icon(Icons.sentiment_very_satisfied,
                                    color: Colors.green.shade600, size: 120),
                                message: 'อนุมัติเรียบร้อย',
                              ),
                            );
                            setState(() { preparePage(); });
                            Navigator.of(context).pop();
                          }else{ 
                          showTopSnackBar(
                                Overlay.of(context),
                                CustomSnackBar.error(
                                  backgroundColor: Colors.red.shade700,
                                  icon: Icon(Icons.sentiment_very_satisfied,
                                  color: Colors.red.shade900, size: 120),
                                  message: 'อนุมัติไม่สำเร็จ',
                                ),
                              );
                            }

                        },
                        child: Text(
                          "อนุมัติ",
                          style: TextStyle(fontSize: _fontSize, color: Colors.white),
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
    switch(entry['objective_type']) {
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
                        label: 'วันที่:',
                        value: DateFormat("d MMMM yyyy", "th_TH")
                            .format(DateTime.parse(entry['date']).toLocal()),
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'เพื่อ:',
                        value: entry['objective'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                  ],
                )
              // Visitor
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10),
                    InfoRow(
                        label: 'บริษัท:',
                        value: entry['company'],
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'วันที่:',
                        value: DateFormat("d MMMM yyyy", "th_TH")
                            .format(DateTime.parse(entry['date']).toLocal()),
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'เวลาเข้า:',
                        value: entry['time_in'].substring(0, 5) + ' น.',
                        fontSize: _fontSize),
                    SizedBox(height: 25),
                    InfoRow(
                        label: 'เวลาออก:',
                        value: entry['time_out'].substring(0, 5) + ' น.',
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
                SizedBox(height: 10,),
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

                
                contentItemDisplay(entry['item_in'], entry['item_out']),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    entry['Signature'] == null
                    ?Icon(Icons.check_box_outline_blank, color: Colors.black, size: 40)
                    :Icon(Icons.check_box_outlined, color: Colors.black, size: 40),
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
              ),
            );
          }).toList(),
        )
      : Container();
}


  Widget employeeDocument() {
    return Container(
      
    );
  }


  Widget contentItemDisplay(Map<String, dynamic>? list_in, Map<String, dynamic>? list_out) {
    bool _isImageItems = false;
    if(list_in?['type'] == 'image' || list_out?['type'] == 'image') {
       _isImageItems = true;
    }
    return Column(
      children: [
        (list_in == null || list_in['item'] == null)
            ? Container()
            : Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(width: 5),
                            Expanded(
                              child: Divider(
                                color: Colors.black,
                                thickness: 1,
                              ),
                            ),
                            Icon(
                              Icons.shopping_bag,
                              color: Colors.black,
                              size: 36,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "สิ่งของนำเข้า",
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: Divider(
                                color: Colors.black,
                                thickness: 1,
                              ),
                            ),
                            SizedBox(width: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Display the items
                  _isImageItems
                      ? generateItemImage(list_in['item'])
                      : generateItemList(list_in['item']),
                ],
              ),
        (list_out == null || list_out['item'] == null)
            ? Container()
            : Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(width: 5),
                            Expanded(
                              child: Divider(
                                color: Colors.black,
                                thickness: 1,
                              ),
                            ),
                            Icon(
                              Icons.shopping_bag,
                              color: Colors.black,
                              size: 36,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "สิ่งของนำออก",
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: Divider(
                                color: Colors.black,
                                thickness: 1,
                              ),
                            ),
                            SizedBox(width: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Display the items
                  _isImageItems
                      ? generateItemImage(list_out['item'])
                      : generateItemList(list_out['item']),
                ],
              ),
      ],
    );
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
                  entry, // No need for '$entry'
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _fontSize, // Using parameter fontSize
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
      return Container(); // Return empty container if no images are available
    }
    double screenWidth = MediaQuery.of(context).size.width;
  //   if (kIsWeb) {
  //   return Container(
  //     child: Center(
  //       child: Text('This feature is not available on the web'),
  //     ),
  //   );
  // }
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
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: Colors.red),
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
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: Colors.red),
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
              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 50, color: Colors.red),
            ),
          ),
      ],
    ],
  );
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
    this.labelWidth = 125.0,
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
            value?? '-',
            style: TextStyle(fontSize: fontSize),
            softWrap: true,
          ),
        ),
        SizedBox(width: 10),
      ],
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