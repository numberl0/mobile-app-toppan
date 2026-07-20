import 'dart:ui';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/config/api_config.dart';

import '../../formatters/listview_formatter.dart';
import '../../utils/BaseScaffold.dart';
import '../../utils/CustomDIalog.dart';
import '../../utils/color_utils.dart';
import '../../utils/date_utils.dart';
import 'approve_controller.dart';
import '../../utils/department_utils.dart';

class ApprovePage extends StatelessWidget {
  const ApprovePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseScaffold(
      title: 'อนุมัติคำร้อง',
      child: ApproveContent(),
    );
  }
}

class ApproveContent extends StatefulWidget {
  const ApproveContent({super.key});

  @override
  State<ApproveContent> createState() => _ApproveContentState();
}

class _ApproveContentState extends State<ApproveContent> {
  ApproveController _con = ApproveController();

  double _fontSize = ApiConfig.fontSize;
  bool isPhoneScale = false;

  @override
  void initState() {
    super.initState();
    preparePage();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      setState(() {
        _con.startAnimation = true;
      });
    });
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  void preparePage() async {
    await _con.preparePage(context);

    setState(() {
      filterDocuments();
    });
  }

  void filterDocuments() {
    setState(() {
      _con.startAnimation = false;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _con.startAnimation = true;
        _con.filterRequestList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _fontSize = ApiConfig.getFontSize(context);
    isPhoneScale = ApiConfig.getPhoneScale(context);

    return Column(
      children: [
        const SizedBox(height: 5),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: SearchInputBar(),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            padding: const EdgeInsets.all(16),
            child: listRequest(),
          ),
        ),
      ],
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
              borderRadius: BorderRadius.all(Radius.circular(36)),
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

                            //Select Option Search (Dropdown)
                            DropdownButtonFormField<RequestType>(
                              value: _con.selectedType,
                              decoration: InputDecoration(
                                labelText: 'ประเภทคำร้อง...',
                                labelStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: _fontSize - 2,
                                    fontStyle: FontStyle.italic),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.blue),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                              ),
                              items: _con.typeOptions.map((RequestType type) {
                                Icon icon;
                                String label = '';
                                switch (type) {
                                  case RequestType.visitor:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.green);
                                    label = 'Visitor';
                                    break;
                                  case RequestType.employee:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.orange);
                                    label = 'Employee';
                                    break;
                                  case RequestType.permission:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.yellow);
                                    label = 'Permission';
                                    break;
                                }

                                return DropdownMenuItem<RequestType>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      icon,
                                      SizedBox(width: 10),
                                      Text(
                                        label,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: _fontSize),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (RequestType? newValue) async {
                                setState(() {
                                  _con.selectedType = newValue;
                                });
                                await _con.clearSearch();
                                filterDocuments();
                              },
                              style: TextStyle(color: Colors.black),
                              iconEnabledColor: Colors.black,
                              iconDisabledColor: Colors.black,
                              dropdownColor: Colors.white.withOpacity(0.8),
                            ),

                            SizedBox(
                              height: 12,
                            ),

                            GetSearchTool(),

                            //button approve
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: SizedBox(
                                width: double
                                    .infinity, // Button expands to full width
                                child: ElevatedButton(
                                  onPressed: () {
                                    List<dynamic> listToApprove = [];
                                    switch (_con.selectedType!) {
                                      case RequestType.visitor:
                                        listToApprove = _con.filteredVisiorList;
                                        break;
                                      case RequestType.employee:
                                        listToApprove =
                                            _con.filteredEmployeeList;
                                        break;
                                      case RequestType.permission:
                                        listToApprove =
                                            _con.filteredPermissionList;
                                        break;
                                    }
                                    if (listToApprove.isEmpty) {
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.error(
                                          backgroundColor: Colors.red.shade700,
                                          icon: Icon(
                                              Icons.sentiment_very_satisfied,
                                              color: Colors.red.shade900,
                                              size: 120),
                                          message: 'ไม่มีรายการสำหรับอนุมัติ',
                                        ),
                                      );
                                    } else {
                                      CustomDialog.show(
                                        context: context,
                                        title: 'คำเตือน',
                                        message:
                                            'คุณต้องการอนุมัติคำร้อง ${_con.selectedType!.name} ทั้งหมดใช่หรือไม่',
                                        type: DialogType.info,
                                        onConfirm: () async {
                                          bool isAdmin = await _con.isAdmin();
                                          if (isAdmin) {
                                            showTopSnackBar(
                                              Overlay.of(context),
                                              CustomSnackBar.error(
                                                backgroundColor:
                                                    Colors.red.shade700,
                                                icon: Icon(
                                                    Icons
                                                        .sentiment_very_satisfied,
                                                    color: Colors.red.shade900,
                                                    size: 120),
                                                message:'ผู้ดูแลระบบไม่มีสิทธิ์อนุมัติเอกสาร',
                                              ),
                                            );
                                          } else {
                                            var response = await _con.approvedAllDocumentByList();
                                            if (!response['success']) {
                                              showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.error(
                                                  backgroundColor:
                                                      Colors.red.shade700,
                                                  icon: Icon(
                                                      Icons
                                                          .sentiment_very_satisfied,
                                                      color:
                                                          Colors.red.shade900,
                                                      size: 120),
                                                  message: 'อนุมัติไม่สำเร็จ',
                                                ),
                                              );
                                            } else {
                                              preparePage();
                                              showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.success(
                                                  backgroundColor:
                                                      Colors.green.shade500,
                                                  icon: Icon(
                                                      Icons
                                                          .sentiment_very_satisfied,
                                                      color:
                                                          Colors.green.shade600,
                                                      size: 120),
                                                  message: 'อนุมัติเรียบร้อย',
                                                ),
                                              );
                                              Navigator.pop(context);
                                            }
                                          }
                                        },
                                        onCancel: () {
                                          Navigator.pop(context);
                                        },
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.library_add_check,
                                          color: Colors.white, size: 24),
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
                          ],
                        ))))));
  }

  Widget GetSearchTool() {
    switch (_con.selectedType) {
      case RequestType.visitor:
        return SearchToolVisitor();
      case RequestType.employee:
        return SearchToolEmployee();
      case RequestType.permission:
        return SearchToolPermission();
      default:
        return SizedBox.shrink();
    }
  }

  Widget SearchToolVisitor() {
    return Column(
      children: [
        // Search company
        TextField(
          controller: _con.filterCompanyController,
          cursorColor: Colors.grey,
          style: TextStyle(color: Colors.black, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'ชื่อองค์กรหรือบริษัท...',
            labelStyle: TextStyle(
                fontSize: _fontSize - 2,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
            prefixIcon: Icon(Icons.business_rounded, color: Colors.blue),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),
        SizedBox(height: 12),

        // Search name
        TextField(
          controller: _con.filterNameController,
          cursorColor: Colors.grey,
          style: TextStyle(color: Colors.black, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'รายชื่อในเอกสาร...',
            labelStyle: TextStyle(
                fontSize: _fontSize - 2,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
            prefixIcon: Icon(Icons.person, color: Colors.blue),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),
      ],
    );
  }

  Widget SearchToolEmployee() {
    return Column(
      children: [
        // Search employeeId
        TextField(
          controller: _con.filterEmployeeIdController,
          cursorColor: Colors.grey,
          style: TextStyle(color: Colors.black, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'รหัสพนักงาน...',
            labelStyle: TextStyle(
                fontSize: _fontSize - 2,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
            prefixIcon: Icon(Icons.tag, color: Colors.blue),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),
        SizedBox(height: 12),
        // Search name
        TextField(
          controller: _con.filterNameController,
          cursorColor: Colors.grey,
          style: TextStyle(color: Colors.black, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'รายชื่อในเอกสาร...',
            labelStyle: TextStyle(
                fontSize: _fontSize - 2,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
            prefixIcon: Icon(Icons.person, color: Colors.blue),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),
      ],
    );
  }

  Widget SearchToolPermission() {
    return Column(
      children: [
        //Select Name Search
        TextField(
          controller: _con.filterNameController,
          cursorColor: Colors.grey,
          style: TextStyle(color: Colors.black, fontSize: _fontSize),
          decoration: InputDecoration(
            labelText: 'รายชื่อในเอกสาร...',
            labelStyle: TextStyle(
                fontSize: _fontSize - 2,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
            prefixIcon: Icon(Icons.person, color: Colors.blue),
            contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.grey), // White border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: Colors.grey), // White border on focus
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),

        SizedBox(
          height: 12,
        ),
        Row(
          children: [
            SizedBox(
              width: isPhoneScale
                  ? MediaQuery.of(context).size.width * 0.4
                  : MediaQuery.of(context).size.width * 0.22,
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: _con.filteredDate,
                builder: (context, date, _) {
                  return TextFormField(
                    readOnly: true,
                    style: TextStyle(
                      fontSize: _fontSize - 4,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'วว/ดด/ปปปป',
                      hintStyle: TextStyle(
                        fontSize: _fontSize - 2,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.date_range,
                            color: Colors.blue, size: _fontSize + 8),
                        onPressed: () =>
                            _datePicker(context, _con.filteredDate),
                      ),
                      suffixIcon: date != null
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.red, size: _fontSize + 8),
                              onPressed: () {
                                _con.filteredDate.value = null;
                                filterDocuments();
                              },
                            )
                          : null,
                    ),
                    controller: TextEditingController(
                      text: date != null
                          ? DateFormat('dd/MM/yyyy').format(date)
                          : '',
                    ),
                    onTap: () => _datePicker(context, _con.filteredDate),
                  );
                },
              ),
            ),

            SizedBox(width: 10),

            // หมายเลขบัตร
            Expanded(
              child: TextField(
                controller: _con.filteredCardNo,
                cursorColor: Colors.grey,
                style: TextStyle(color: Colors.black, fontSize: _fontSize),
                decoration: InputDecoration(
                  labelText: 'หมายเลขบัตร...',
                  labelStyle: TextStyle(
                    fontSize: _fontSize - 2,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  prefixIcon: Icon(Icons.credit_card, color: Colors.blue),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                onChanged: (_) => filterDocuments(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget listRequest() {
    final ScrollController controller = ScrollController();
    var filteredRequest;
    switch (_con.selectedType) {
      case RequestType.visitor:
        filteredRequest = _con.filteredVisiorList;
      case RequestType.employee:
        filteredRequest = _con.filteredEmployeeList;
      case RequestType.permission:
        filteredRequest = _con.filteredPermissionList;
      default:
        filteredRequest = [];
    }
    return filteredRequest.isEmpty
        ? SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
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
              itemCount: filteredRequest.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> entry = filteredRequest[index];
                return ItemRequest(index, entry);
              },
            ),
          );
  }

  Widget ItemRequest(int index, Map<String, dynamic> entry) {
    initializeDateThaiFormatting();
    final docType = entry['request_type'].toUpperCase();
    final docColor = getRequestColor(docType);
    final docBgColor = getBgColor(docType);
    String tagInfo = '';

    DisplayText display;
    switch (docType) {
      case "VISITOR":
        display = buildVisitor(entry);
        tagInfo = entry['sequence_no'] ?? '';
        break;

      case "EMPLOYEE":
        display = buildEmployee(entry);
        tagInfo = entry['sequence_no'] ?? '';
        break;

      case "PERMISSION":
        final signEmp = parseDate(entry['sign_emp_at']);
        final guardIn = parseDate(entry['sign_guardI_at']);
        final guardOut = parseDate(entry['sign_guardO_at']);

        display = DisplayText(
          left: 'วันที่: ${formatDate(signEmp)}',
          center: 'เวลารับบัตร: ${formatTime(guardIn)}',
          right: 'เวลาคืนบัตร: ${formatTime(guardOut)}',
        );

         tagInfo = entry['brw_card'] ?? '';
        break;

      case "TEMPORARY":
        final brw = parseDate(entry['brw_at']);
        final ret = parseDate(entry['ret_at']);

        display = DisplayText(
          left: 'วันที่: ${formatDate(brw)}',
          center: 'เวลารับบัตร: ${formatTime(brw)}',
          right: 'เวลาคืนบัตร: ${formatTime(ret)}',
        );
        break;

      default:
        display = DisplayText();
    }

    String convertReason(String? code) {
      switch (code) {
        case 'L':
          return 'ทำบัตรประจำตัวพนักงานหาย';
        case 'F':
          return 'ลืมบัตรประจำตัวพนักงานมา';
        case 'D':
          return 'บัตรประจำตัวพนักงานชำรุด';
        case 'O':
          return entry['reason_desc'];
        default:
          return '';
      }
    }

    return AnimatedContainer(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform: Matrix4.translationValues(_con.startAnimation ? 0 : MediaQuery.of(context).size.width, 0, 0),
      child: Container(
        margin: EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 5.0,
              offset: Offset(0, 5),
            ),
            BoxShadow(
              color: docColor,
              offset: Offset(-5, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Slidable(
            //  startActionPane: docType == "TEMPORARY"
            //   ? ActionPane(
            //       motion: ScrollMotion(),
            //       extentRatio: 0.2,
            //       children: [
            //         CustomSlidableAction(
            //           onPressed: (context) => PopUpRemarkWidget(entry),
            //           backgroundColor: Colors.blue,
            //           borderRadius: BorderRadius.zero,
            //           child: Column(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Icon(Icons.edit_document, color: Colors.white, size: 30),
            //               SizedBox(height: 4),
            //               if (!isPhoneScale)
            //                 Text(
            //                   'หมายเหตุ',
            //                   style: TextStyle(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.bold,
            //                   ),
            //                 ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     )
            //   : null,

            child: Stack(
              children: [
                Material(
                  color: docBgColor,
                  child: InkWell(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: isPhoneScale    ? EdgeInsets.fromLTRB(16, 31, 16, 5) : EdgeInsets.fromLTRB(15, 43, 15, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (docType == "VISITOR") ...[
                                        Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: 'ผู้ติดต่อ: ',
                                                  style: TextStyle(
                                                    fontSize: _fontSize-2,
                                                    fontWeight: FontWeight.normal,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: entry['company'],
                                                  style: TextStyle(
                                                    fontSize: _fontSize-1,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: true,
                                          ),
                                          SizedBox(height: 10,),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'บริเวณติดต่อ: ',
                                                style: TextStyle(
                                                  fontSize: _fontSize-2,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              TextSpan(
                                                text: entry['area'] ?? '-',
                                                style: TextStyle(
                                                  fontSize: _fontSize-1,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        )
                                      ] else if (docType == "EMPLOYEE") ...[
                                        Text(
                                          '${entry['people'][0]['TitleName'] ?? ''} ${entry['people'][0]['FullName'] ?? ''}'
                                              .trim(),
                                          style: TextStyle(
                                            fontSize: _fontSize + 2,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(text: 'ประเภท: ', style: TextStyle(color: Colors.grey[700], fontSize: _fontSize-2 )),
                                              TextSpan(text: '${_con.eTypeObjectiveMapping[int.tryParse(entry['objective_type'].toString())] ?? '-'}', style: TextStyle(color: Colors.red, fontSize: _fontSize -1, fontWeight: FontWeight.bold)),
                                              WidgetSpan(
                                                child: SizedBox(width: 5),
                                              ),
                                              if (entry['objective_type'] ==
                                                  1) ...[
                                                if (entry['out_only'] == 0) ...[
                                                  TextSpan(
                                                      text: '(ไปและกลับ)',
                                                      style: TextStyle(
                                                          color: Colors.green,
                                                          fontSize:
                                                              _fontSize - 2,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ] else ...[
                                                  TextSpan(
                                                      text: '(ไม่กลับ)',
                                                      style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize:
                                                              _fontSize - 2,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ]
                                              ],
                                            ],
                                          ),
                                        )
                                      ] else if (docType == "PERMISSION") ...[
                                        Text(
                                          '${entry['emp_name']}',
                                          style: TextStyle(
                                            fontSize: _fontSize + 2,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        ),
                                        SizedBox(height: 10,),
                                          Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'ประเภท: ',
                                                style: TextStyle(
                                                  fontSize: _fontSize-2,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              TextSpan(
                                                text: convertReason(entry['reason']),
                                                style: TextStyle(
                                                  fontSize: _fontSize-1,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          buildResponsiveGrid(entry, context),
                        ],
                      ),
                    ),
                    onTap: () {
                      showDialogDetailDocument(entry);
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          docColor,
                          docColor,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          //
                          display.left,
                          style: TextStyle(
                            fontSize: _fontSize - 4,
                            color: docType == 'PERMISSION'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: isPhoneScale ? 40 : 90),
                        Text(
                          // 'เวลาเข้า: ${centerDate != null ? DateFormat('HH:mm').format(centerDate) : '-'}',
                          display.center,
                          style: TextStyle(
                            fontSize: _fontSize - 4,
                            color: docType == 'PERMISSION'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: isPhoneScale ? 40 : 90),
                        Text(
                          // 'เวลาออก: ${rightDate != null ? DateFormat('HH:mm').format(rightDate) : '-'}',
                          display.right,
                          style: TextStyle(
                            fontSize: _fontSize - 4,
                            color: docType == 'PERMISSION'
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                 top: docType == "VISITOR"
                                  ? (isPhoneScale ? 58 : 76)
                                  : (isPhoneScale ? 29 : 40),
                  right: isPhoneScale ? 6:18,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: docBgColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: 
                     Text.rich(
                                    TextSpan(
                                      children: [
                                        
                                          TextSpan(
                                            text: docType == 'PERMISSION' ? 'เลขบัตร: ' : 'เลขเอกสาร: ',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: _fontSize - 4,
                                            ),
                                          ),
   
                                        TextSpan(
                                          text: tagInfo,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: _fontSize - 4,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),



                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildResponsiveGrid(Map<String, dynamic> entry, BuildContext context) {
    final docType = entry['request_type'];
    final docColor = getRequestColor(docType);
    final allButtons = _con.signatureSection[docType] ?? [];
    final buttons = allButtons.where((item) {
      if (docType == 'EMPLOYEE' && item.signKey == 'emp_sign') {
        return false;
      }
      if (docType == 'PERMISSION' && item.signKey == 'sign_emp') {
        return false;
      }
      if (docType == 'TEMPORARY' && item.signKey == 'brw_sign_brw') {
        return false;
      }
      return true;
    }).toList();

    // final buttons = allButtons;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons.map((btn) {
        final key = btn.signKey;
        final label = btn.label;
        final isSigned = entry[key] != null && entry[key].toString().isNotEmpty;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: ElevatedButton(
              // onPressed: isSigned ? null : () => signerPopup(key, label, entry),
              onPressed: null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 5,
                ),
                disabledBackgroundColor: Colors.grey.shade200,
                backgroundColor: Colors.white,
                foregroundColor: isSigned
                    ? Colors.grey
                    : (docType == 'PERMISSION' ? Colors.blue : docColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                  side: BorderSide(
                    color: docColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: _fontSize - 2,
                  // color: docType=='PERMISSION'?Colors.blue : docColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void showDialogDetailDocument(Map<String, dynamic> entry) {
    String HeaderTitle(String? code) {
      switch (code) {
        case 'VISITOR':
          return 'ใบคำร้องเข้า/ออก';
        case 'EMPLOYEE':
          return 'ใบคำร้องเข้า/ออก(พนักงาน)';
        case 'PERMISSION':
          return 'ใบคำร้องกรณีบัตรหายหรือชำรุด';
        default:
          return '';
      }
    }

    Widget ContentDetails() {
      switch (entry['request_type']) {
        case 'VISITOR':
          return ContentDetail(entry);

        case 'EMPLOYEE':
          return ContentDetail(entry);

        case 'PERMISSION':
          return ContentDetail(entry);

        default:
          return Text("ไม่พบข้อมูลประเภทเอกสาร",
              style: TextStyle(fontSize: _fontSize));
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          backgroundColor: Colors.transparent, // ขอบนอกโปร่ง
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: Colors.white, // สีขาวเต็ม popup
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      HeaderTitle(entry['request_type']),
                      style: TextStyle(
                        fontSize: _fontSize + 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Color.fromARGB(255, 132, 194, 252),
                            Color.fromARGB(255, 45, 152, 240),
                            Color.fromARGB(255, 48, 114, 236),
                            Color.fromARGB(255, 0, 93, 199),
                          ],
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(isPhoneScale ? 8 : 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Stack(
                          children: [
                            ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                },
                                scrollbars: false,
                              ),
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ContentDetails(),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * (isPhoneScale ? 0.225 : 0.12),
                                height: MediaQuery.of(context).size.height * 0.05,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await CustomDialog.show(
                                        context: context,
                                        title: 'คำเตือน',
                                        message:'คุณต้องการอนุมัติเอกสารใช่หรือไม่? การดำเนินการนี้จะไม่สามารถย้อนกลับมาแก้ไขได้',
                                        type: DialogType.info,
                                        onConfirm: () async {
                                          bool isAdmin = await _con.isAdmin();
                                          if (isAdmin) {
                                            showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.error(
                                                  backgroundColor:Colors.red.shade700,
                                                  icon: Icon(Icons.sentiment_very_satisfied,
                                                  color:Colors.red.shade900,
                                                  size: 120
                                                ),
                                                message: 'ผู้ดูแลระบบไม่มีสิทธิ์อนุมัติเอกสาร',
                                              ),
                                            );
                                          }else{
                                            var response = await _con.approvedDocument(entry);
                                            showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.success(
                                                  backgroundColor:
                                                      Colors.green.shade500,
                                                  icon: Icon(
                                                      Icons
                                                          .sentiment_very_satisfied,
                                                      color:
                                                          Colors.green.shade600,
                                                      size: 120),
                                                  message: response['message'] ?? '',
                                                ),
                                              );
                                            preparePage();
                                            Navigator.pop(context);
                                          }
                                          Navigator.pop(context);
                                        },
                                        onCancel: () {
                                          Navigator.pop(context);
                                        });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    elevation: 8,
                                    shadowColor: Colors.black,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 132, 194, 252),
                                          Color.fromARGB(255, 45, 152, 240),
                                          Color.fromARGB(255, 48, 114, 236),
                                          Color.fromARGB(255, 0, 93, 199),
                                        ],
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'อนุมัติ',
                                        style: TextStyle(
                                          fontSize: isPhoneScale
                                              ? _fontSize
                                              : _fontSize - 2,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget ContentDetail(Map<String, dynamic> entry) {
    double spaceLabel = MediaQuery.of(context).size.width * 0.22;
    double pddingLabel = MediaQuery.of(context).size.width * 0.01;

    final docType = entry['request_type'].toUpperCase();

    final startDateStr;
    final endDateStr;
    switch (docType) {
      case "VISITOR":
        startDateStr = entry['datetime_in'];
        endDateStr = entry['datetime_out'];
        break;
      case "EMPLOYEE":
        startDateStr = entry['datetime_out'];
        endDateStr = entry['datetime_in'];
        break;
      case "PERMISSION":
        startDateStr = entry['brw_sign_guard'];
        endDateStr = entry['ret_sign_guard'];
        break;
      default:
        startDateStr = null;
        endDateStr = null;
    }

    DateTime? parseDate(dynamic value) {
      return DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    }

    final startDate = parseDate(startDateStr);
    final endDate = parseDate(endDateStr);

    final timeEnd =
        endDate != null ? DateFormat("HH:mm", "th_TH").format(endDate) : '-';
    final timeStart = startDate != null
        ? DateFormat("HH:mm", "th_TH").format(startDate)
        : '-';
    final formattedDateEnd = endDate != null
        ? '${DateFormat("dd MMM yyyy", "th_TH").format(endDate)}    $timeEnd น.'
        : '-';
    final formattedDateStart = startDate != null
        ? '${DateFormat("dd MMM yyyy", "th_TH").format(startDate)}    $timeStart น.'
        : '-';

    final fieldSignature =
        _con.signatureSection[entry['request_type']?.toUpperCase()] ?? [];

    String convertReason(String? code) {
      switch (code) {
        case 'L':
          return 'ทำบัตรประจำตัวพนักงานหาย';
        case 'F':
          return 'ลืมบัตรประจำตัวพนักงานมา';
        case 'D':
          return 'บัตรประจำตัวพนักงานชำรุด';
        case 'O':
          return entry['reason_desc'];
        default:
          return '';
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        if (docType == "VISITOR") ...[
          buildLabelValueRow('องค์กร:', entry['company'] ?? '',
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          buildLabelValueRow('เวลาเข้า:', formattedDateStart,
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          buildLabelValueRow('เวลาออก:', formattedDateEnd,
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          buildLabelValueRow('ติดต่อ:', entry['contact'] ?? '',
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          buildLabelValueRow('แผนก:', getDepartmentDisplay(entry['contact_dept'] ?? '',_con.deptList),
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          buildLabelValueRow('วัตถุประสงค์:', entry['objective'] ?? '',
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 10),
        ] else if (docType == "EMPLOYEE") ...[
          buildLabelValueRow('ขออนุญาต:',
              '${_con.eTypeObjectiveMapping[int.tryParse(entry['objective_type'].toString())]}',
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          buildLabelValueRow('เวลาออก:', '$formattedDateStart',
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
          SizedBox(height: 25),
          if (entry['out_only'] == 0) ...[
            buildLabelValueRow('เวลากลับ:', '$formattedDateEnd',
                leftPadding: pddingLabel,
                labelWidth: spaceLabel,
                labelBold: true),
            SizedBox(height: 25),
          ],
          buildLabelValueRow('วัตถุประสงค์:', entry['objective'] ?? '',
              leftPadding: pddingLabel,
              labelWidth: spaceLabel,
              labelBold: true),
        ] else if (docType == "PERMISSION") ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'วันที่ : ${DateFormat('dd/MM/yyyy').format(DateTime.tryParse(entry['doc_date'])!.toLocal())}',
                    style: TextStyle(
                        fontSize: _fontSize - 2, fontWeight: FontWeight.bold),
                  )
                ],
              ),
              Text("ข้อมูลผู้ขออนุญาต",
                  style: TextStyle(
                      fontSize: _fontSize, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow('ชื่อ:', entry['emp_name'],
                  leftPadding: pddingLabel, labelWidth: spaceLabel),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow('แผนก:', getDepartmentDisplay(entry['emp_dept'] ?? '',_con.deptList),
                  leftPadding: pddingLabel, labelWidth: spaceLabel),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow('รหัสพนักงาน:', entry['emp_id'],
                  leftPadding: pddingLabel, labelWidth: spaceLabel),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 20,
              ),
              Text("รายละเอียด",
                  style: TextStyle(
                      fontSize: _fontSize, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: EdgeInsets.only(left: pddingLabel),
                child: Text('เรื่อง   ขออนุญาตเบิกบัตรใช้งานชั่วคราว',
                    style: TextStyle(fontSize: _fontSize)),
              ),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow('เหตุผล:', convertReason(entry['reason']),
                  leftPadding: pddingLabel, labelWidth: spaceLabel),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow('ผู้รับเรื่อง:', entry['responsible_by'],
                  leftPadding: pddingLabel, labelWidth: spaceLabel),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow('บัตรขอเบิก:', entry['brw_card'],
                  leftPadding: pddingLabel, labelWidth: spaceLabel),
              SizedBox(
                height: 10,
              ),
              buildLabelValueRow(
                  'วันคืนบัตร:',
                  DateFormat('dd/MM/yyyy').format(
                      DateTime.tryParse(entry['until_date'])!.toLocal()),
                  leftPadding: pddingLabel,
                  labelWidth: spaceLabel),
            ],
          ),
        ],
        SizedBox(height: 10),
        // Show people in form
        if (docType == 'VISITOR' || docType == 'EMPLOYEE') ...[
          Container(
            padding: EdgeInsets.all(5),
            child: Column(
              children: [
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
                generatePeopleList(docType, entry['people']),
                contentItemDisplay(
                    entry['item_in'], entry['item_out'], docType),
              ],
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.black,
                thickness: 1,
                endIndent: 10,
              ),
            ),
            Icon(
              Icons.draw_rounded,
              color: Colors.black,
              size: 36,
            ),
            Text("ลายเซ็น",
                style: TextStyle(
                    fontSize: _fontSize + 4, fontWeight: FontWeight.bold)),
            Expanded(
              child: Divider(
                color: Colors.black,
                thickness: 1,
                indent: 10,
              ),
            ),
          ],
        ),
        Column(
          children: fieldSignature.map((field) {
            return Column(
              children: [
                SizedBox(height: 10),
                buildSignCard(
                  field.label,
                  entry[field.signKey],
                  entry[field.datetimeKey],
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  void initializeDateThaiFormatting() async {
    await initializeDateFormatting('th_TH', null);
  }

  Widget buildLabelValueRow(String label, String value,
      {double leftPadding = 20, double labelWidth = 80, labelBold = false}) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: labelBold ? FontWeight.bold : FontWeight.normal,
                )),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: _fontSize)),
          ),
        ],
      ),
    );
  }

  Widget buildSignCard(
    String title,
    String? signUrl,
    String? signDate,
  ) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: Colors.blue,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Divider(color: Colors.blue, height: 20, thickness: 1),

            //Signature
            Center(
              child: signUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        signUrl,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Text(
                      'ยังไม่ได้มีการเซ็น',
                      style: TextStyle(color: Colors.grey),
                    ),
            ),

            Divider(color: Colors.blue, height: 20, thickness: 1),

            // Date
            Center(
              child: Text(
                signDate != null
                    ? DateFormat('dd/MM/yyyy HH:mm น.')
                        .format(DateTime.tryParse(signDate)!.toLocal())
                    : "",
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget generatePeopleList(String type, List<dynamic> personList) {
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
                      if (type.toUpperCase() == 'VISITOR') ...[
                        entry['Signature'] == null
                            ? Icon(Icons.check_box_outline_blank,
                                color: Colors.blue, size: 40)
                            : Icon(Icons.check_box_outlined,
                                color: Colors.blue, size: 40),
                      ] else if (type.toUpperCase() == 'EMPLOYEE') ...[
                        Icon(Icons.person, color: Colors.blue, size: 60),
                      ],
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry['TitleName']} ${entry['FullName']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: _fontSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (type.toUpperCase() == 'EMPLOYEE') ...[
                              Text(
                                'แผนก: ${getDepartmentDisplay(entry['Department'] ?? '',_con.deptList)}',
                                style: TextStyle(
                                  fontSize: _fontSize - 4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'รหัสพนักงาน: ${entry['EmployeeId']}',
                                style: TextStyle(
                                  fontSize: _fontSize - 4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
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
                    Icon(Icons.inventory_2, color: Colors.black, size: 36),
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
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.hardEdge,
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
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.hardEdge,
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
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.hardEdge,
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

  // ---------------- Tool ----------------
  //Function Date Picker
  Future<void> _datePicker(
    BuildContext context,
    ValueNotifier<DateTime?> _date,
  ) async {
    DateTime initial = _date.value ?? AppDateTime.now();
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(AppDateTime.now().year - 7),
        lastDate: DateTime(AppDateTime.now().year + 7),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                    MediaQuery.of(context).size.width > 799 ? 1.5 : 1.0)),
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
    if (picked != null) {
      _date.value = picked;
      await _con.filterRequestList();
    }
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
