import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/utils/CustomDIalog.dart';
import 'package:toppan_app/config/api_config.dart';

import '../../formatters/listview_formatter.dart';
import '../../utils/BaseScaffold.dart';
import '../../utils/color_utils.dart';
import '../../utils/date_utils.dart';
import 'partTime_controller.dart';

class PartTimePage extends StatelessWidget {
  const PartTimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseScaffold(
      title: 'ล็อกบุ๊คพนักงานชั่วคราวและอื่นๆ',
      child: PartTimeContent(),
    );
  }
}

class PartTimeContent extends StatefulWidget {
  const PartTimeContent({super.key});

  @override
  State<PartTimeContent> createState() => _PartTimeContentState();
}

class _PartTimeContentState  extends State<PartTimeContent>with SingleTickerProviderStateMixin {
  PartTimeController _con = PartTimeController();

  Color? _cancelBtnColor = Colors.red;
  Color? _acceptBtnColor = Colors.blue;
  double _fontSize = ApiConfig.fontSize;
  final FocusNode _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  Map<Signer, bool> isEditingMap = {};
  bool isPhoneScale = false; 

  @override
  void initState() {
    super.initState();
    prepare();
  }

   @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void prepare() async {
     await _con.initalPage(context);
     isEditingMap = {};
    setState(() {
      filterDocuments();
    });
  }

  void filterDocuments() {
    setState(() {
      _con.filterTemporaryList();
    });
  }

  @override
  Widget build(BuildContext context) {
    _fontSize = ApiConfig.getFontSize(context);
    isPhoneScale = ApiConfig.getPhoneScale(context);
    return _getPageContent(context);
  }

  Widget _getPageContent(BuildContext context) {
    final ScrollController controller = ScrollController();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Container(
        // margin:EdgeInsets.all(MediaQuery.of(context).size.width > 799 ? 34 : 7),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              // Color.fromARGB(255, 255, 255, 255),
              // Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(0, 255, 255, 255),
              Color.fromARGB(0, 255, 255, 255),
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
            padding: isPhoneScale ? EdgeInsets.all(5.0) : EdgeInsets.all(5.0),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IgnorePointer(
                    ignoring: false,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                
                          Container(
                            margin: isPhoneScale ? EdgeInsets.all(10.0) : EdgeInsets.all(15.0),
                            padding: isPhoneScale ? EdgeInsets.all(15.0) : EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            // padding: EdgeInsets.all(12),
                            child: Column(
                              children: [
                                  Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('วันที่ : ${DateFormat('dd/MM/yyyy').format(_con.docDate.value)}', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),)
                            ],
                          ),

                          SizedBox(height: 10,),

                          Row(
                            children: [
                              Expanded(
                                flex: isPhoneScale ? 2 : 3,
                                child: SizedBox(
                                  height: isPhoneScale ? 100 : 120,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => PopUpInsertTemporaryWidget(),
                                      splashColor: Colors.blue.withOpacity(0.3),
                                      highlightColor: Colors.blue.withOpacity(0.1),
                                      child: Container(
                                        padding: EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.edit_document, size: 30, color: Colors.blue),
                                            SizedBox(height: 5),
                                            Text(
                                              "ลงชื่อพนักงาน",
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20,),
                          

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _con.nameFilterController,
                                  cursorColor: Colors.black,
                                  style: TextStyle(
                                      color: Colors.black, fontSize: _fontSize),
                                  decoration: InputDecoration(
                                    labelText: 'ค้นหาชื่อพนักงาน...',
                                    labelStyle: TextStyle(
                                          fontSize: _fontSize-4,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic),
                                    prefixIcon:
                                        Icon(Icons.search, color: Colors.grey),
                                        isDense: true,
                                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey), // White border
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors
                                              .grey), // White border on focus
                                    ),
                                  ),
                                  onChanged: (_) => filterDocuments(),
                                ),
                              ),

                              SizedBox(width: 15,),

                              DropDownFilterSearchWidget(),

                            ],
                          ),
                           SizedBox(height: 5,),
                              ],
                            ),
                          ),

                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.end,
                          //   children: [
                          //     Text('วันที่ : ${DateFormat('dd/MM/yyyy').format(_con.docDate.value)}', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),)
                          //   ],
                          // ),

                          // SizedBox(height: 15,),

                          // Row(
                          //   children: [
                          //     Expanded(
                          //       flex: isPhoneScale ? 2 : 3,
                          //       child: SizedBox(
                          //         height: isPhoneScale ? 100 : 120,
                          //         child: Material(
                          //           color: Colors.transparent,
                          //           child: InkWell(
                          //             onTap: () => PopUpInsertTemporaryWidget(),
                          //             splashColor: Colors.blue.withOpacity(0.3),
                          //             highlightColor: Colors.blue.withOpacity(0.1),
                          //             child: Container(
                          //               padding: EdgeInsets.all(10.0),
                          //               decoration: BoxDecoration(
                          //                 border: Border.all(color: Colors.blue),
                          //                 borderRadius: BorderRadius.circular(15),
                          //               ),
                          //               child: Column(
                          //                 mainAxisAlignment: MainAxisAlignment.center,
                          //                 children: [
                          //                   Icon(Icons.edit_document, size: 30, color: Colors.blue),
                          //                   SizedBox(height: 5),
                          //                   Text(
                          //                     "ลงชื่อพนักงาน",
                          //                     style: TextStyle(
                          //                       fontSize: _fontSize,
                          //                       fontWeight: FontWeight.bold,
                          //                       color: Colors.blue,
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // SizedBox(height: 20,),
                          

                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: TextField(
                          //         controller: _con.nameFilterController,
                          //         cursorColor: Colors.black,
                          //         style: TextStyle(
                          //             color: Colors.black, fontSize: _fontSize),
                          //         decoration: InputDecoration(
                          //           labelText: 'ค้นหาชื่อพนักงาน...',
                          //           labelStyle: TextStyle(
                          //                 fontSize: _fontSize-4,
                          //                 color: Colors.grey,
                          //                 fontStyle: FontStyle.italic),
                          //           prefixIcon:
                          //               Icon(Icons.search, color: Colors.grey),
                          //               isDense: true,
                          //                   contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          //           border: OutlineInputBorder(
                          //             borderRadius: BorderRadius.circular(12),
                          //             borderSide: BorderSide(color: Colors.grey),
                          //           ),
                          //           enabledBorder: OutlineInputBorder(
                          //             borderRadius: BorderRadius.circular(12),
                          //             borderSide: BorderSide(
                          //                 color: Colors.grey), // White border
                          //           ),
                          //           focusedBorder: OutlineInputBorder(
                          //             borderRadius: BorderRadius.circular(12),
                          //             borderSide: BorderSide(
                          //                 color: Colors
                          //                     .grey), // White border on focus
                          //           ),
                          //         ),
                          //         onChanged: (_) => filterDocuments(),
                          //       ),
                          //     ),

                          //     SizedBox(width: 10,),

                          //     DropDownFilterSearchWidget(),

                          //   ],
                          // ),


                            SizedBox(height: 10,),

                            listForm(),



                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget dropDownTitleName() {
    List<String> titleNameList = ['นาย', 'นาง', 'นางสาว'];
    if (_con.titleController.text.isEmpty) {
      _con.titleController.text = titleNameList[0];
    }
    return DropdownButtonFormField<String>(
        value: _con.titleController.text,
        isDense: true,
        decoration: InputDecoration(
          isDense: true,
          border: OutlineInputBorder( // กรอบปกติ
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey, width: 1),
        ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 20,),
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
            _con.titleController.text = newValue!;
          });
        },
      );
  }

  Widget dropDownCardType([void Function(void Function())? setStateDialog]) {
  return IntrinsicWidth(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 6),
      child: DropdownButtonFormField<String>(
        value: _con.selectedCardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
        style: TextStyle(
          color: Colors.black,
          fontSize: _fontSize,
          height: 1.0,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        items: _con.cardTypeMap.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          final updater = setStateDialog ?? setState;
          updater(() {
            _con.selectedCardType = newValue!;
            _con.filterCardType();
          });
        },
      ),
    ),
  );
}

Widget siteCheckboxes([void Function(void Function())? setStateDialog]) {
  if (_con.siteList.length == 1 && _con.selectedSite != _con.siteList.first) {
    _con.selectedSite = _con.siteList.first;
    _con.filterBySite();
  }
  return Wrap(
    spacing: 8,
    children: _con.siteList.map((site) {
      final isSelected = _con.selectedSite == site;
      return ChoiceChip(
        label: Text(site),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: Colors.blue,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
        onSelected: (_) {
          final updater = setStateDialog ?? setState;
          updater(() {
              if (_con.selectedSite == site) {
                _con.selectedSite = null;
              } else {
                _con.selectedSite = site;
              }
              _con.filterBySite();
            });
        },
      );
    }).toList(),
  );
}

Widget dropDownPassCard([void Function(void Function())? setStateDialog]) {
    List<String> cardList = _con.filterCardList.map((e) => e['card_id'].toString()).toList();
    if (cardList.isNotEmpty && _con.selectedCard.isEmpty) {
      _con.selectedCard = cardList[0];
    }
    if (cardList.isEmpty) {
      return const Text("ไม่พบบัตรให้เลือก", style: TextStyle(color: Colors.grey));
    }
    return IntrinsicWidth(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey),
        ),
        padding: EdgeInsets.symmetric(vertical : 0, horizontal: 6),
        child: DropdownButtonFormField<String>(
          menuMaxHeight: 250.0,
          value: _con.selectedCard,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          ),
          icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 20,),
          style: TextStyle(
            color: Colors.black,
            fontSize: _fontSize,
            height: 1.0,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(15),
          items: cardList.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (String? newValue) {
            final updater = setStateDialog ?? setState;
            updater(() {
              _con.selectedCard = newValue!;
            });
          },
        ),
      ),
    );
  }


 Widget listForm() {
  final ScrollController controller = ScrollController();
  return Container(
    height: MediaQuery.of(context).size.height * 0.6, // กำหนดความสูงขั้นต่ำ
    child: _con.filteredTemporaryList.isEmpty
        ? Center(
            child: Text(
              '-------- ยังไม่มีรายการในตอนนี้ --------',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade300),
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
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _con.filteredTemporaryList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> entry = _con.filteredTemporaryList[index];
                // return itemForm(entry);
                return ItemRequest(index,entry);
              },
            ),
          ),
  );
}

  void initializeDateThaiFormatting() async {
    await initializeDateFormatting('th_TH', null);
  }

  Widget ItemRequest(int index, Map<String, dynamic> entry) {
    initializeDateThaiFormatting();
    final docType = entry['request_type'].toUpperCase();
    final docColor = getRequestColor(docType);
    final docBgColor = getBgColor(docType);
    String tagInfo = '';

    DisplayText display;
    switch (docType) {
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
      // transform: Matrix4.translationValues(_con.startAnimation ? 0 : MediaQuery.of(context).size.width, 0, 0),
      child: Container(
            margin: EdgeInsets.all(16),
            width: double.infinity,
            // height: isPhoneScale ? 105 : 180,
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
                              padding: isPhoneScale ? EdgeInsets.fromLTRB(16, 27, 16, 8) : EdgeInsets.fromLTRB(15, 35, 15, 7),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
              
                                        if (docType == "VISITOR") ...[
                                          Text(
                                            'บริษัท/นามบุคคล: ' + entry['company'],
                                            style: TextStyle(
                                              fontSize: _fontSize,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: true,
                                          ),
                                
                                          SizedBox(height: 7,),
                                          Text(
                                            'บริเวณที่มาติดต่อ: ' + entry['area'],
                                            style: TextStyle(
                                              fontSize: _fontSize,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: true,
                                          ),
                                        ] else if (docType == "EMPLOYEE") ...[
                                          Text(
                                            '${entry['people'][0]['TitleName'] ?? ''} ${entry['people'][0]['FullName'] ?? ''}'.trim(),
                                            style: TextStyle(
                                              fontSize: _fontSize + 2,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: true,
                                          ),
                                          SizedBox(height: 7,),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(text: 'ประเภท: ', style: TextStyle(color: Colors.black, fontSize: _fontSize-1, fontWeight: FontWeight.bold)),
                                                TextSpan(text: '${_con.eTypeObjectiveMapping[int.tryParse(entry['objective_type'].toString())] ?? '-'}', style: TextStyle(color: Colors.red, fontSize: _fontSize -1, fontWeight: FontWeight.bold)),
                                                WidgetSpan(
                                                  child: SizedBox(width: 5),
                                                ),
                                                if (entry['objective_type'] == 1) ...[
                                                  if(entry['out_only'] == 0) ...[
                                                    TextSpan(text: '(ไปและกลับ)', style: TextStyle(color: Colors.green, fontSize: _fontSize - 2, fontWeight: FontWeight.bold)),
                                                  ] else ...[
                                                    TextSpan(text: '(ไม่กลับ)', style: TextStyle(color: Colors.blue, fontSize: _fontSize- 2, fontWeight: FontWeight.bold)),
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
                                          SizedBox(height: 7,),
                                          Text(
                                            'ประเภท: ${convertReason(entry['reason'])}',
                                            style: TextStyle(
                                              fontSize: _fontSize -1,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            softWrap: true,
                                          ),
                                        ] else if (docType == "TEMPORARY") ...[
                                          Text('${entry['name']}',
                                          style: TextStyle(fontSize: _fontSize + 2, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 7,),
                                          Text('หมายเลขบัตร: ${entry['card_no']}',
                                              style: TextStyle(fontSize: _fontSize - 1)),
                                        ],
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
                        PopUpRemarkWidget(entry);
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
                            color: docType=='PERMISSION'?Colors.black:Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: isPhoneScale ? 40 : 90),
                        Text(
                          // 'เวลาเข้า: ${centerDate != null ? DateFormat('HH:mm').format(centerDate) : '-'}',
                          display.center,
                          style: TextStyle(
                            fontSize: _fontSize - 4,
                            color: docType=='PERMISSION'?Colors.black:Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: isPhoneScale ? 40 : 90),
                        Text(
                          // 'เวลาออก: ${rightDate != null ? DateFormat('HH:mm').format(rightDate) : '-'}',
                          display.right,
                          style: TextStyle(
                            fontSize: _fontSize - 4,
                            color: docType=='PERMISSION'?Colors.black:Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
                        Positioned(
                                top: isPhoneScale ? 25:35,
                                right: isPhoneScale ? 8:18,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: docBgColor,
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    tagInfo,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: _fontSize-4,
                                        fontWeight: FontWeight.bold),
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
            onPressed: isSigned ? null : () => signerPopup(key, label, entry),
            style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 5,),
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
                  fontSize: _fontSize -2,
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


void signerPopup(String key, String label, Map<String,dynamic> entry) {
  final docType = entry['request_type'];
  final docColor = getRequestColor(docType);
  final headerText = "ลายเซ็น $label";
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
                            color: docColor,
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

                            if(docType!="TEMPORARY") ...{
                              Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                          text: 'ชื่อ',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: _fontSize,
                                              fontWeight: FontWeight.bold)),
                                      WidgetSpan(
                                        child: SizedBox(width: 5),
                                      ),
                                      TextSpan(
                                          text: '(ไม่มีนามสกุล)',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: _fontSize - 4,
                                              fontWeight: FontWeight.bold)),
                                      WidgetSpan(
                                        child: SizedBox(width: 5),
                                      ),
                                      TextSpan(
                                          text: ':',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: _fontSize,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),


                            Flexible(
                              child: TextFormField(
                                controller: _con.signatureByController,
                                maxLines: 1,
                                style: TextStyle(fontSize: _fontSize),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
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
                              ),
                            ),
                            
                              SizedBox(height:20),
                              },
                              Text(
                                'ลายเซ็น:',
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
                                              key: _con.signatureGlobalKey,
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
                                        _con.signatureGlobalKey.currentState?.clear();
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
                                    _con.signatureByController.clear(),
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
                                    final padState = _con.signatureGlobalKey.currentState;
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
                                                setStateDialog(() { });
                                                var signature = bytes.buffer.asUint8List();
                                                await _con.updateSignature(entry, key, signature);
                                                _con.signatureByController.clear();
                                              }
                                              
                                              // clear signature
                                              setStateDialog(() {
                                                _con.signatureGlobalKey = GlobalKey<SfSignaturePadState>();
                                              });
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              setState(() { });
                                            },
                                          );
                                    }
                                    prepare();
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


Widget DropDownFilterSearchWidget() {
  return IntrinsicWidth(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        value: _con.selectedFilterCardType,
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
        items: _con.filterCardTypeList.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _con.selectedFilterCardType = newValue!;
            _con.filterTemporaryList();
          });
        },
      ),
    ),
  );
}


 void PopUpRemarkWidget(Map<String, dynamic> entry) {
  _con.remarkController.text = entry['remark'] ?? '';
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
                                  controller: _con.remarkController,
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
                                      _con.remarkController.clear();
                                     }),
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cancelBtnColor,
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
                                    await _con.updateRemark(entry['id'], _con.remarkController.text);
                                    _con.remarkController.clear();
                                    Navigator.of(context).pop();
                                    setState(() { });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _acceptBtnColor,
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

void PopUpInsertTemporaryWidget() {
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
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
              return Dialog(
                backgroundColor: Colors.white,
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
                              color: Colors.blue,
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
                                  .onDrag,
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
              
                                Text('ชื่อ-นามสกุล:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: _fontSize)),
                                SizedBox(height: 2.5),
                                TextFormField(
                                    controller: _con.nameController,
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'ชื่อ-นามสกุล ผู้ยืมบัตร...',
                                          hintStyle: TextStyle(
                                            fontSize: _fontSize-4,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                                            return 'กรุณาระบุชื่อผู้ยืม';
                                          }
                                          return null;
                                        },
                                      ),
                                SizedBox(height: 20),

                                SizedBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ประเภทบัตร :',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                            ),
                                          ),
                                          SizedBox(height: 2.5),
                                          dropDownCardType(setStateDialog),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    SizedBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'อาคาร :',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                            ),
                                          ),
                                          SizedBox(height: 2.5),
                                          siteCheckboxes(setStateDialog),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    SizedBox(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'หมายเลขบัตร :',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                            ),
                                          ),
                                          SizedBox(height: 2.5),
                                          dropDownPassCard(setStateDialog),
                                        ],
                                      ),
                                    ),

                                SizedBox(height: 25),
              
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
                                            12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            12),
                                        child: SfSignaturePad(
                                          key: _con.signatureGlobalKey,
                                          backgroundColor: Colors
                                              .transparent,
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
                                          _con
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
                                  _con.clearInputInsert();
                                  setState(() { });
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
                                  
                                  // action
                                  if (_con.signatureGlobalKey.currentState?.toPathList().isEmpty == true || _con.nameController.text.isEmpty) {
                                    showTopSnackBar(
                                      Overlay.of(context),
                                      CustomSnackBar.error(
                                        backgroundColor: Colors.red.shade700,
                                        icon: Icon(
                                            Icons.sentiment_very_satisfied,
                                            color: Colors.red.shade900,
                                            size: 120),
                                        message: "กรุณกรอกข้อมูลให้ครบถ้วน",
                                      ),
                                    );
                                  } else {
                                      await CustomDialog.show(
                                            context: context,
                                            title: 'คำเตือน',
                                            message: "คุณต้องการบันทึกข้อมูลใช่หรือไม่? การดำเนินการนี้จะไม่สามารถย้อนกลับมาแก้ไขได้",
                                            type: DialogType.info,
                                            onConfirm: () async {
                                              final padState = _con.signatureGlobalKey.currentState;
                                              final image = await padState?.toImage();
                                              final bytes = await image?.toByteData(format: ImageByteFormat.png);
                                              if (bytes != null) {
                                                setStateDialog(() {
                                                  _con.signatures[Signer.borrowerIn] = bytes.buffer.asUint8List();
                                                });
                                              }
                                              await _con.insertTemporaryPass();
                                              setStateDialog(() { // clear signature
                                                _con.signatures[Signer.borrowerIn] = null;
                                                _con.clearInputInsert();
                                                _con.signatureGlobalKey = GlobalKey<SfSignaturePadState>();
                                              });
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              setState(() { });
                                              prepare();
                                            },
                                          );
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
              );
              }
            ),
          ),
        );
      },
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

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        // etc.
      };
}
