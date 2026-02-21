
import 'dart:ui';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/clear_temporary.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/component/CustomDIalog.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/main.dart';

import '../../component/BaseScaffold.dart';
import 'search_controller.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseScaffold(
      title: 'ค้นหาใบผ่านและใบคำร้อง',
      child: SearchContent(),
    );
  }
}

class SearchContent extends StatefulWidget {
  const SearchContent({super.key});

  @override
  State<SearchContent> createState() => _SearchContentState();
}

class _SearchContentState extends State<SearchContent> with RouteAware {
  Cleartemporary cleartemporary = Cleartemporary();
  double _fontSize = ApiConfig.fontSize;
  bool isPhoneScale = false;

  SearchFormController _controller = SearchFormController();

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
      setState(() {
        _fontSize = ApiConfig.getFontSize(context);
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
    super.didPopNext();

    imageCache.clear();
    imageCache.clearLiveImages();

  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> preparePage() async {
    _controller.selectedType = _controller.typeOptions[0];
    await _controller.preparePage(context);
    setState(() {
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
    _fontSize = ApiConfig.getFontSize(context);
    isPhoneScale = ApiConfig.getPhoneScale(context);
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
              padding: EdgeInsets.all(12.0),
              child: SearchInputBar(),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.all(16),
                child: listRequest(),
              ),
            ),
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
                              value: _controller.selectedType,
                              decoration: InputDecoration(
                                labelText: 'ประเภทคำร้อง...',
                                labelStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: _fontSize -2,
                                    fontStyle: FontStyle.italic),
                                prefixIcon: Icon(Icons.search, color: Colors.blue),
                                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                              ),
                              items: _controller.typeOptions.map((RequestType type) {
                                Icon icon;
                                String label = '';
                                switch (type) {
                                  case RequestType.visitor:
                                    icon = Icon(Icons.layers_rounded,color: Colors.green);
                                    label = 'Visitor';
                                    break;
                                  case RequestType.employee:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.orange);
                                        label = 'Employee';
                                    break;
                                  case  RequestType.permission:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.yellow);
                                        label = 'Permission';
                                    break;
                                  case RequestType.temporary:
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.blue);
                                        label = 'Temporary';
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
                                  _controller.selectedType = newValue;
                                });
                                await _controller.clearSearch();
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
                          ],
                        ))))));
  }

  Widget GetSearchTool() {
    switch (_controller.selectedType) {
      case RequestType.visitor:
        return SearchToolVisitor();
      case RequestType.employee:
        return SearchToolEmployee();
      case RequestType.permission:
        return SearchToolPermission();
      case RequestType.temporary:
        return SearchToolTemporary();
      default:
        return SizedBox.shrink();
    }
  }

  Widget SearchToolVisitor() {
    return Column(
      children: [

        // Search company
        TextField(
          controller: _controller.filterCompanyController,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),
        SizedBox(height: 12),

        // Search name
        TextField(
          controller: _controller.filterNameController,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey),
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
          controller: _controller.filterEmployeeIdController,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),
        SizedBox(height: 12),
        // Search name
        TextField(
          controller: _controller.filterNameController,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey),
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
          controller: _controller.filterNameController,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey), // White border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey), // White border on focus
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),

        SizedBox(height: 12,),
        Row(
          children: [
            SizedBox(
              width: isPhoneScale
                  ? MediaQuery.of(context).size.width * 0.4
                  : MediaQuery.of(context).size.width * 0.22,
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: _controller.filteredDate,
                builder: (context, date, _) {
                  return TextFormField(
                    readOnly: true,
                    style: TextStyle(
                      fontSize: _fontSize -4,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.date_range,
                            color: Colors.blue, size: _fontSize + 8),
                        onPressed: () =>
                            _datePicker(context, _controller.filteredDate),
                      ),
                      suffixIcon: date != null
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.red, size: _fontSize + 8),
                              onPressed: () {
                                _controller.filteredDate.value = null;
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
                    onTap: () => _datePicker(context, _controller.filteredDate),
                  );
                },
              ),
            ),

            SizedBox(width: 10),

    // หมายเลขบัตร
    Expanded(
      child: TextField(
        controller: _controller.filteredCardNo,
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
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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

  Widget SearchToolTemporary() {
    return Column(
      children: [
        //Select Name Search
        TextField(
          controller: _controller.filterNameController,
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey), // White border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey), // White border on focus
            ),
          ),
          onChanged: (_) => filterDocuments(),
        ),

        SizedBox(height: 12,),
        Row(
          children: [
            SizedBox(
              width: isPhoneScale
                  ? MediaQuery.of(context).size.width * 0.4
                  : MediaQuery.of(context).size.width * 0.22,
              child: ValueListenableBuilder<DateTime?>(
                valueListenable: _controller.filteredDate,
                builder: (context, date, _) {
                  return TextFormField(
                    readOnly: true,
                    style: TextStyle(
                      fontSize: _fontSize -4,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      prefixIcon: IconButton(
                        icon: Icon(Icons.date_range,
                            color: Colors.blue, size: _fontSize + 8),
                        onPressed: () =>
                            _datePicker(context, _controller.filteredDate),
                      ),
                      suffixIcon: date != null
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.red, size: _fontSize + 8),
                              onPressed: () {
                                _controller.filteredDate.value = null;
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
                    onTap: () => _datePicker(context, _controller.filteredDate),
                  );
                },
              ),
            ),

            SizedBox(width: 10),

    // หมายเลขบัตร
    Expanded(
      child: TextField(
        controller: _controller.filteredCardNo,
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
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
    switch (_controller.selectedType) {
      case RequestType.visitor:
        filteredRequest = _controller.filteredVisiorList;
      case RequestType.employee:
        filteredRequest = _controller.filteredEmployeeList;
      case RequestType.permission:
        filteredRequest = _controller.filteredPermissionList;
      case RequestType.temporary:
        filteredRequest = _controller.filteredTemporaryList;
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
                switch (entry['request_type']) {
                  case 'VISITOR':
                    return ItemRequestVE(index, entry);
                  case 'EMPLOYEE':
                    return ItemRequestVE(index, entry);
                  case 'PERMISSION':
                    return ItemRequestPermission(index, entry);
                  case 'TEMPORARY':
                    return ItemRequestTemporary(index, entry);
                  default:
                    return SizedBox.shrink();
                }
              },
            ),
          );
  }

  Widget ItemRequestVE(int index, Map<String, dynamic> entry) {
    String timeRanges = '';
    String formattedDate = '';
    bool isFinish = false;
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
    if (entry['request_type'] == 'VISITOR') {
      formattedDate = DateFormat("d MMM yyyy", "th_TH").format(dateIn);
      timeRanges = '$timeIn น. - $timeOut น.';
      isFinish = entry['appr_status'] == 1 && entry['guard_status'] == 1;
    } else if (entry['request_type'] == 'EMPLOYEE') {
      formattedDate = DateFormat("d MMM yyyy", "th_TH").format(dateOut);
      if (sameDate && sameTime) {
        timeRanges = '$timeOut น.';
      } else {
        timeRanges = '$timeOut น. - $timeIn น.';
      }
      isFinish = entry['emp_status'] == 1 && entry['appr_status'] == 1 && entry['guard_status'] == 1;
    }
    bool isApproved = entry['appr_status'] == 1;


    return AnimatedContainer(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform: Matrix4.translationValues(_controller.startAnimation ? 0 : MediaQuery.of(context).size.width, 0, 0),
      child: Container(
            margin: EdgeInsets.all(16),
            width: double.infinity,
            height: isPhoneScale ? 105 : 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 5.0,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: isFinish ? Colors.green : Colors.grey,
                  offset: Offset(-5, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Slidable(
                  child: Stack(
                    children: [
                      Material(
                                      color: const Color.fromARGB(255, 237, 247, 255),
                                      child: InkWell(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    colors:isFinish
                                    ? const [
                                        Color(0xFF66BB6A),
                                        Color(0xFF43A047),
                                        Color(0xFF1B5E20),
                                      ]
                                    : const [
                                        Color(0xFFE0E0E0),
                                        Color(0xFFBDBDBD),
                                        Color(0xFF9E9E9E),
                                      ],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ).createShader(bounds);
                                },
                                child: Icon(
                                  Icons.description,
                                  size: isPhoneScale ? 50 : 90,
                                  color: Colors.white, // จะถูกแทนที่ด้วย gradient
                                ),
                              ),
                                SizedBox(
                                  width: isPhoneScale? 5 : 20,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry['request_type']?.toString().toUpperCase() == 'EMPLOYEE'
    ? (entry['people'] != null && entry['people'].isNotEmpty
        ? '${entry['people'][0]['TitleName'] ?? ''} ${entry['people'][0]['FullName'] ?? ''}'.trim()
        : '')
    : (entry['company'] ?? '')}',
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
                                        color: isFinish ? Colors.green : Colors.grey,
                                        thickness: 2,
                                        height: 4,
                                      ),
                                       
                                      SizedBox(height: isPhoneScale?7:10),
                                        Text(
                                          'ประเภท : ${entry['request_type'][0] + entry['request_type'].substring(1).toLowerCase()}',
                                          style: TextStyle(
                                            fontSize: _fontSize-4,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: true,
                                        ),
                                        SizedBox(height: 5),

                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  Icons.calendar_month,
                                                  size: isPhoneScale?18:30,
                                                  color: Colors.black,
                                                ),
                                                 SizedBox(width: isPhoneScale?3:10,),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: _fontSize - 2,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),

                                            SizedBox(width: isPhoneScale?10:30,),

                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: isPhoneScale?18:30,
                                                  color: Colors.black,
                                                ),
                                                SizedBox(width: isPhoneScale?3:10,),
                                                Text(
                                                  timeRanges,
                                                  style: TextStyle(
                                                    fontSize: _fontSize-2,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        showDialogDetailDocument(entry);
                      },
                                      ),
                                    ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isApproved ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              isApproved ? 'อนุมัติแล้ว' : 'ยังไม่ได้อนุมัติ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _fontSize-4,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  )),
            ),
          ),
    );
  }

  Widget ItemRequestPermission(int index, Map<String, dynamic> entry) {
    initializeDateThaiFormatting();
    final docDate = DateTime.parse(entry['doc_date']).toLocal();
    final untilDate = DateTime.parse(entry['until_date']).toLocal();

    final formattedDateStart = DateFormat("d MMM yyyy", "th_TH").format(docDate);
    final formattedDateUntil = DateFormat("d MMM yyyy", "th_TH").format(untilDate);

    final timeRanges = "$formattedDateStart  -  $formattedDateUntil";

    bool isApproved = entry['sign_respon_status'] == 1;

    return AnimatedContainer(
      margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform: Matrix4.translationValues(_controller.startAnimation ? 0 : MediaQuery.of(context).size.width, 0, 0),
      child: Container(
            margin: EdgeInsets.all(16),
            width: double.infinity,
            height: isPhoneScale ? 100 : 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 5.0,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(-5, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: Slidable(
                  child: Stack(
                    children: [
                      Material(
                                      color: const Color.fromARGB(255, 237, 247, 255),
                                      child: InkWell(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      colors: [
                                        // Color.fromARGB(255, 132, 194, 252),
                                        // Color.fromARGB(255, 45, 152, 240),
                                        // Color.fromARGB(255, 48, 114, 236),
                                        // Color.fromARGB(255, 0, 93, 199),

                                        Color(0xFFE0E0E0),
                                        Color(0xFFBDBDBD),
                                        Color(0xFF9E9E9E),

                                        // Color(0xFFEF5350),
                                        // Color(0xFFD32F2F),
                                        // Color(0xFF8E0000),
                                      ],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ).createShader(bounds);
                                  },
                                  child: Icon(
                                    Icons.description,
                                    size: isPhoneScale ? 50 : 90,
                                    color: Colors.white, // จะถูกแทนที่ด้วย gradient
                                  ),
                                ),
                                SizedBox(
                                  width: isPhoneScale? 5: 20,
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry['emp_name']}',
                                        style: TextStyle(
                                          fontSize: _fontSize + 4,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: true,
                                      ),
                                      Text(
                                        '${entry['report_to']}',
                                        style: TextStyle(
                                          fontSize: _fontSize - 6,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: true,
                                      ),
                                      Divider(
                                        color: Colors.grey,
                                        thickness: 2,
                                      ),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  Icons.calendar_month,
                                                  size: isPhoneScale ? 18 : 30,
                                                  color: Colors.black,
                                                ),
                                                SizedBox(width: isPhoneScale? 2 : 10,),
                                                Text(
                                                  timeRanges,
                                                  style: TextStyle(
                                                    fontSize: _fontSize - 2,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  softWrap: true,
                                                ),
                                              ],
                                            ),

                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        
                                      
                                 
                   
                       
                      ),
                      onTap: () async {
                        showDialogDetailDocument(entry);
                      },
                                      ),
                                    ),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isApproved ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              isApproved ? 'อนุมัติแล้ว' : 'ยังไม่ได้อนุมัติ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: _fontSize-4,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        // Positioned(
                        //   bottom: 0,
                        //   right: 0,
                        //   child: Container(
                        //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        //     decoration: BoxDecoration(
                        //       color: isApproved ? Colors.green : Colors.red,
                        //       borderRadius: BorderRadius.only(
                        //           topLeft: Radius.circular(16),
                        //       ),
                        //     ),
                        //     child: Text(
                        //       isApproved ? 'อนุมัติแล้ว' : 'ยังไม่ได้อนุมัติ',
                        //       style: TextStyle(
                        //           color: Colors.white,
                        //           fontSize: _fontSize-4,
                        //           fontWeight: FontWeight.bold),
                        //     ),
                        //   ),
                        // ),
                    ],
                  )),
            ),
          ),
    );
  }

  Widget ItemRequestTemporary(int index, Map<String, dynamic> entry) {
  initializeDateThaiFormatting();
  final allSigned = Signer.values
      .map((s) => getKeyFromSigner(s))
      .every((key) => entry[key] != null && entry[key].toString().isNotEmpty);
  return AnimatedContainer(
     margin: EdgeInsets.all(0),
      padding: EdgeInsets.all(0),
      curve: Curves.easeInOut,
      duration: Duration(milliseconds: 300 + (index * 200)),
      transform: Matrix4.translationValues( _controller.startAnimation ? 0 : MediaQuery.of(context).size.width, 0, 0),
    child: Container(
      decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],),
      margin: EdgeInsets.symmetric(horizontal: isPhoneScale? 7:25, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          startActionPane: ActionPane(
            motion: ScrollMotion(),
            extentRatio: 0.2,
            children: [
              CustomSlidableAction(
                onPressed: (context) => PopUpRemarkWidget(entry),
                backgroundColor: Colors.blue,
                borderRadius: BorderRadius.zero,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_document, color: Colors.white, size: 30),
                    SizedBox(height: 4),
                    if(!isPhoneScale) ...[
                      Text('หมายเหตุ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                padding: isPhoneScale ? EdgeInsets.fromLTRB(16, 27, 16, 8) : EdgeInsets.fromLTRB(30, 27, 30, 12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 239, 248, 255),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [
                                Color.fromARGB(255, 132, 194, 252),
                                Color.fromARGB(255, 45, 152, 240),
                                Color.fromARGB(255, 48, 114, 236),
                                Color.fromARGB(255, 0, 93, 199),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ).createShader(bounds);
                          },
                          child: Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white, // ต้องเป็นสีขาวเพื่อให้ ShaderMask ไล่สีได้
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ชื่อ:   ${entry['name']}',
                                style: TextStyle(fontSize: _fontSize - 1)),
                            SizedBox(height: 4),
                            Text('บัตร: ${entry['card_no']}',
                                style: TextStyle(fontSize: _fontSize - 1)),
                            SizedBox(height: 4),
                          ],
                        ))
                      ],
                    ),
                    buildResponsiveGrid(entry, context),
                  ],
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
                 
                        Color.fromARGB(255, 45, 152, 240),
                        Color.fromARGB(255, 48, 114, 236),
                        Color.fromARGB(255, 0, 93, 199),
                      ],
                    ),
                  ),
                  child: Text(
                    DateFormat("d MMM yyyy", "th_TH").format(DateTime.parse(entry['brw_at']).toLocal()),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
    
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: allSigned ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.only(
                      // topRight: Radius.circular(16),
                      // bottomLeft: Radius.circular(8),
                        topLeft: Radius.circular(16),
                        // bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    allSigned ? 'เสร็จสิ้น' : 'กำลังดำเนินการ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _fontSize -4,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
    
              if (entry['remark'] != null && entry['remark'].toString().isNotEmpty) ...[
                Positioned(
                  top: 40,
                  left: 85,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159), // พลิกแนวนอนถ้าต้องการ
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return LinearGradient(
                          colors: [
                            Color.fromARGB(255, 132, 194, 252),
                            Color.fromARGB(255, 45, 152, 240),
                            Color.fromARGB(255, 48, 114, 236),
                            Color.fromARGB(255, 0, 93, 199),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ).createShader(bounds);
                      },
                      child: Icon(
                        Icons.comment,
                        size: 24,
                        color: Colors.white, // ต้องเป็นสีขาวเพื่อให้ gradient ทำงาน
                      ),
                    ),
                  ),
                ),
              ],
              
            ],
          ),
        ),
      ),
    ),
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
        return ContentDetailVisitor(entry);

      case 'EMPLOYEE':
        return ContentDetailEmployee(entry);

      case 'PERMISSION':
        return ContentDetailPermission(entry);

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
                                  behavior: ScrollConfiguration.of(context).copyWith(
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
        switch (entry['request_type']
            .toString()
            .toLowerCase()) {

          case 'visitor':
            await context.push(
              '/visitor',
              extra: entry,
            );
            break;

          case 'employee':
            await context.push(
              '/employee',
              extra: entry,
            );
            break;

          case 'permission':
            await context.push(
              '/permis',
              extra: entry,
            );
            break;
        }
      },
      style: ElevatedButton.styleFrom(
        elevation: 8,
        shadowColor: Colors.black,
        padding: EdgeInsets.zero, // สำคัญสำหรับ gradient ครอบเต็ม
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
            'แก้ไข',
            style: TextStyle(
              fontSize: isPhoneScale ? _fontSize : _fontSize - 2,
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

  Widget buildLabelValueRow(String label, String value,
      {double leftPadding = 20, double labelWidth = 80, labelBold = false}) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label, style: TextStyle(fontSize: _fontSize, fontWeight: labelBold ? FontWeight.bold : FontWeight.normal,)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: _fontSize)),
          ),
        ],
      ),
    );
  }

  Widget ContentDetailVisitor(Map<String, dynamic> entry) {
    double spaceLabel = MediaQuery.of(context).size.width * 0.22;
    double pddingLabel = MediaQuery.of(context).size.width * 0.01;
    return Column(
      children: [
        SizedBox(
                      height: 10,
                    ),
                    buildLabelValueRow('องค์กร:', entry['company'] ?? '', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    buildLabelValueRow('เวลาเข้า:', DateFormat("d MMM yyyy", "th_TH").format(DateTime.parse(entry['date_in']).toLocal()) +'    ' +entry['time_in'].substring(0, 5) +' น.', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    buildLabelValueRow('เวลาออก:', DateFormat("d MMM yyyy", "th_TH").format(DateTime.parse(entry['date_out']).toLocal()) +'    ' +entry['time_out'].substring(0, 5) +' น.', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    buildLabelValueRow('ติดต่อ:', entry['contact'] ?? '', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    buildLabelValueRow('แผนก:', entry['contact_dept'] ?? '', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    buildLabelValueRow('วัตถุประสงค์:', entry['objective'] ?? '', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 10),

        // Show people in form
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
                generatePeopleList(entry['people']),

                // Show Item in/out
                contentItemDisplay(
                    entry['item_in'], entry['item_out'], entry['request_type']),
              ],
            ),
          ),


           SizedBox(
          height: 20,
        ),

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
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),
         SizedBox(
          height: 10,
        ),
        buildSignCard(
            'ผู้อนุมัติ', entry['appr_sign'], entry['appr_at']),
          SizedBox(
          height: 10,
        ),
        buildSignCard(
            'ผู้ตรวจสอบสื่อ', entry['media_sign'], entry['media_at']),
          SizedBox(
          height: 10,
        ),
          SizedBox(
          height: 10,
        ),
        buildSignCard(
            'รปภ. (ประตูหน้า)', entry['guard_sign'], entry['guard_at']),
          SizedBox(
          height: 10,
        ),
        buildSignCard(
            'รปภ. (การผลิต)', entry['prod_sign'], entry['prod_at']),
      ],
    );
  }

  Widget ContentDetailEmployee(Map<String, dynamic> entry) {
    double spaceLabel = MediaQuery.of(context).size.width * 0.22;
    double pddingLabel = MediaQuery.of(context).size.width * 0.01;
    String objectiveType = {
      1: 'ออกนอกโรงงาน',
      2: 'นำสินค้า/สิ่งของออกพื้นที่การผลิต',
      3: 'นำสินค้า/สิ่งของออกโรงงาน',
    }[entry['objective_type']] ?? 'ไม่พบข้อมูล';

    final dateOut = DateTime.parse(entry['date_out']).toLocal();
    final dateIn = DateTime.parse(entry['date_in']).toLocal();
    final formattedDateOut = DateFormat("d MMM yyyy", "th_TH").format(dateOut);
    final formattedDateIn = DateFormat("d MMM yyyy", "th_TH").format(dateIn);
    final timeOut = entry['time_out'].substring(0, 5);
    final timeIn = entry['time_in'].substring(0, 5);
    bool isDateSame = formattedDateOut == formattedDateIn;
    bool isTimeSame = timeOut == timeIn;
    bool isDateTime = isDateSame && isTimeSame;
    return Column(
      children: [
        SizedBox(height: 10),
        buildLabelValueRow('ขออนุญาต:', objectiveType, leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    buildLabelValueRow('เวลาออก:', '$formattedDateOut     $timeOut น.', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),
                    if (!isDateTime) ...[
                      buildLabelValueRow('เวลาออก:', '$formattedDateIn     $timeIn น.', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                      SizedBox(height: 25),
                    ],
                    buildLabelValueRow('วัตถุประสงค์:', entry['objective'] ?? '', leftPadding: pddingLabel, labelWidth: spaceLabel, labelBold: true),
                    SizedBox(height: 25),

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
                generatePeopleList(entry['people']),

                // Show Item in/out
                contentItemDisplay(
                    entry['item_in'], entry['item_out'], entry['request_type']),
              ],
            ),
          ),

          SizedBox(
          height: 20,
        ),

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
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),
         SizedBox(
          height: 10,
        ),
        buildSignCard(
            'พนักงาน', entry['emp_sign'], entry['emp_at']),
          SizedBox(
          height: 10,
        ),
        buildSignCard(
            'ผู้อนุมัติ', entry['appr_sign'], entry['appr_at']),
          SizedBox(
          height: 10,
        ),
          SizedBox(
          height: 10,
        ),
        buildSignCard(
            'ผู้ตรวจสอบสื่อ', entry['media_sign'], entry['media_at']),
          SizedBox(
          height: 10,
        ),
        buildSignCard(
            'รปภ. (ประตูหน้า)', entry['guard_sign'], entry['guard_at']),
      ],
    );
  }

  Widget ContentDetailPermission(Map<String, dynamic> entry) {
    double spaceLabel = MediaQuery.of(context).size.width * 0.22;
    double pddingLabel = MediaQuery.of(context).size.width * 0.025;
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
            style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 10,
        ),
        buildLabelValueRow('ชื่อ:', entry['emp_name'],
            leftPadding: pddingLabel, labelWidth: spaceLabel),
        SizedBox(
          height: 10,
        ),
        buildLabelValueRow('แผนก:', entry['emp_dept'],
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
            style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold)),
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
            DateFormat('dd/MM/yyyy')
                .format(DateTime.tryParse(entry['until_date'])!.toLocal()),
            leftPadding: pddingLabel,
            labelWidth: spaceLabel),
        SizedBox(
          height: 20,
        ),
        buildSignCard('พนักงาน', entry['sign_emp'], entry['sign_emp_at']),
        SizedBox(
          height: 10,
        ),
        buildSignCard(
            'ผู้รับเรื่อง', entry['sign_respon'], entry['sign_respon_at']),
        SizedBox(
          height: 10,
        ),
        buildSignCard(
            'รปภ. (ขาเข้า)', entry['sign_guardI'], entry['sign_guardI_at']),
        SizedBox(
          height: 10,
        ),
        buildSignCard(
            'รปภ. (ขาออก)', entry['sign_guardO'], entry['sign_guardO_at']),
      ],
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

void PopUpRemarkWidget(Map<String, dynamic> entry) {
  _controller.remarkController.text = entry['remark'] ?? '';
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
            child: IntrinsicWidth( // ✅ ปรับให้ขนาดตาม content
              child: IntrinsicHeight(
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              "หมายเหตุ",
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // ---------------- BODY ----------------
                        Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _controller.remarkController,
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'หมายเหตุ...',
                                    hintStyle: TextStyle(
                                      fontSize: _fontSize - 4,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                  ),

                                ),
                              ],
                            ),
                          ),

                        // ---------------- BUTTONS ----------------
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              // ยกเลิก
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => {
                                    Navigator.of(context).pop(),
                                    setState(() { 
                                      _controller.remarkController.clear();
                                     }),
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),

                              // บันทึก
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    _controller.updateRemark(entry['id'], _controller.remarkController.text);
                                    _controller.remarkController.clear();
                                    Navigator.of(context).pop();
                                    setState(() { });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'บันทึก',
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

Widget buildResponsiveGrid(Map<String, dynamic> entry, BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  int crossAxisCount = screenWidth > 799 ? 4 : 2;

  final buttons = [
    {'key': 'brw_sign_brw', 'label': 'ผู้ยืม', 'signer': Signer.borrowerIn, 'icon': Icons.person},
    {'key': 'brw_sign_guard', 'label': 'รปภ.ให้ยืม', 'signer': Signer.guardIn, 'icon': Icons.security_outlined},
    {'key': 'ret_sign_brw', 'label': 'ผู้คืน', 'signer': Signer.borrowerOut, 'icon': Icons.person},
    {'key': 'ret_sign_guard', 'label': 'รปภ.รับคืน', 'signer': Signer.guardOut, 'icon': Icons.security_outlined},
  ];

  return SizedBox(
    height: (buttons.length / crossAxisCount).ceil() * 50,
    child: GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isPhoneScale ? 3.5 : 3,
      ),
      itemCount: buttons.length,
      itemBuilder: (context, index) {
        final btn = buttons[index];
        final key = btn['key'] as String;
        final label = btn['label'] as String;
        final signer = btn['signer'] as Signer;
        final icon = btn['icon'] as IconData;
    
        final isSigned = entry[key] != null && entry[key].toString().isNotEmpty;
    
        return ElevatedButton(
          onPressed: isSigned ? null : () {
            signerPopup(signer, entry);
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5,),
            disabledBackgroundColor: Colors.grey.shade200,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSigned ? Colors.grey.shade500 : Colors.blue,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: isSigned ? Colors.grey.shade500 : Colors.blue),
              SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: isSigned ? Colors.grey.shade500 : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void signerPopup(Signer signer, [Map<String,dynamic>? entry]) {
  String headerText;
  switch (signer) {
    case Signer.borrowerIn:
      headerText = "ลายเซ็นผู้ยืมบัตร";
      break;
    case Signer.guardIn:
      headerText = "ลายเซ็น รปภ.ที่ให้ยืม";
      break;
    case Signer.borrowerOut:
      headerText = "ลายเซ็นผู้คืนบัตร";
      break;
    case Signer.guardOut:
      headerText = "ลายเซ็น รปภ.ที่รับคืน";
      break;
  }

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
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Center(
                            child: Text(
                              headerText,
                              style: TextStyle(
                                fontSize: _fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // ---------------- BODY ----------------
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ลงชื่อ:',
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Stack(
                                children: [
                                  Container(
                                    height: 200,
                                    width: MediaQuery.of(context).size.width * 0.65,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SfSignaturePad(
                                              key: _controller.signatureGlobalKey,
                                              backgroundColor: Colors.transparent,
                                              strokeColor: Colors.black,
                                              minimumStrokeWidth: 3.0,
                                              maximumStrokeWidth: 6.0,
                                            ),
                                    ),
                                  ),

                                  // ปุ่มเคลียร์ / แก้ไข
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        _controller.signatureGlobalKey.currentState?.clear();
                                      },
                                      child: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.black.withOpacity(0.5),
                                        child: Icon(Icons.cached, color: Colors.white, size: 24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ---------------- BUTTONS ----------------
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // ยกเลิก
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => {
                                    Navigator.of(context).pop(),
                                    setState(() { }),
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),

                              // บันทึก
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final padState = _controller.signatureGlobalKey.currentState;

                                    // ถ้ายังไม่มี signature pad หรือยังไม่ได้เซ็น
                                    if (padState == null || padState.toPathList().isEmpty) {
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.error(
                                          backgroundColor: Colors.red.shade700,
                                          icon: Icon(
                                            Icons.sentiment_very_dissatisfied,
                                            color: Colors.red,
                                            size: 100,
                                          ),
                                          message: 'กรุณาเซ็นก่อนบันทึกทุกครั้ง',
                                        ),
                                      );
                                      return;
                                    }else{
                                      await CustomDialog.show(
                                            context: context,
                                            title: 'คำเตือน',
                                            message: "คุณต้องการบันทึกลายเซ็นใช่หรือไม่? การดำเนินการนี้จะไม่สามารถย้อนกลับมาแก้ไขได้",
                                            type: DialogType.info,
                                            onConfirm: () async {
                                              final image = await padState.toImage();
                                              final bytes = await image.toByteData(format: ImageByteFormat.png);
                                              if (bytes != null) {
                                                setStateDialog(() {
                                                  _controller.signatures[signer] = bytes.buffer.asUint8List();
                                                });
                                              }
                                              await _controller.updateSignature(entry!, signer);
                                              
                                              // clear signature
                                              setStateDialog(() {
                                                _controller.signatures[signer] = null;
                                                _controller.signatureGlobalKey = GlobalKey<SfSignaturePadState>();
                                              });
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              setState(() { });
                                            },
                                          );
                                    }
                                    setState(() { });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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


  void initializeDateThaiFormatting() async {
    await initializeDateFormatting('th_TH', null);
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
                          ? Icon(Icons.check_box_outline_blank,
                              color: Colors.blue, size: 40)
                          : Icon(Icons.check_box_outlined,
                              color: Colors.blue, size: 40),
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
                    Expanded(child: Divider(color: Colors.black, thickness: 1, endIndent: 5,)),
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
                    Expanded(child: Divider(color: Colors.black, thickness: 1, indent: 5,)),
                    SizedBox(width: 5),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
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
                Icon(Icons.auto_awesome_mosaic_rounded, color: Colors.blue, size: 40),
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
  Future<void> _datePicker(BuildContext context, ValueNotifier<DateTime?> _date,) async {
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
      _controller.filterRequestList();
    }
  }
}


class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
