import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/component/CustomDIalog.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/visitorService/partTime/partTime_controller.dart';

class PartTimePage {
  Widget buildPartTimeForm(BuildContext context) {
    return PartTimeForm();
  }
}

class PartTimeForm extends StatefulWidget {
  @override
    _PartTimeFormState createState() => _PartTimeFormState ();
}

class _PartTimeFormState  extends State<PartTimeForm>with SingleTickerProviderStateMixin {
  PartTimeController _controller = PartTimeController();

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
     await _controller.initalPage(context);
     isEditingMap = {};
    setState(() {
      filterDocuments();
    });
  }

  void filterDocuments() {
    setState(() {
      _controller.filterTemporaryList();
    });
  }

   @override
  Widget build(BuildContext context) {
    _fontSize = ApiConfig.getFontSize(context);
    isPhoneScale = ApiConfig.getPhoneScale(context);
    //Back ground
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
            Color.fromARGB(255, 132, 194, 252),
            Color.fromARGB(255, 45, 152, 240),
            Color.fromARGB(255, 48, 114, 236),
            Color.fromARGB(255, 0, 93, 199),
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
        margin:EdgeInsets.all(MediaQuery.of(context).size.width > 799 ? 34 : 7),
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
            padding: isPhoneScale ? EdgeInsets.all(15.0) : EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IgnorePointer(
                    ignoring: false, // logbook
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                                
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('วันที่ : ${DateFormat('dd/MM/yyyy').format(_controller.docDate.value)}', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),)
                            ],
                          ),


                      
                          Text("ข้อมูลพนักงาน", style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5,),
                          if (!isPhoneScale) ... [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      dropDownTitleName(),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 7,
                                child: TextFormField(
                                  controller: _controller.nameController,
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
                              ),
                            ],
                          ),
                          SizedBox(height: 15,),

             

                   
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Text('ประเภทบัตร :', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),),
                                  SizedBox(width: 10,),
                                  dropDownCardType(),
                                ],
                              ),
                              SizedBox(width: 20),
                              Row(
                                children: [
                                  Text('หมายเลขบัตร :', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),),
                                  SizedBox(width: 10,),
                                  dropDownPassCard(),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 15),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: isPhoneScale ? 2 : 3,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        signerPopup(Signer.borrowerIn);
                                      },
                                      splashColor: Colors.blue.withOpacity(0.3),
                                      highlightColor: Colors.blue.withOpacity(0.1),
                                      child: Container(
                                        padding: EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: _controller.signatures[Signer.borrowerIn] != null
                                                  ? Colors.grey.shade600
                                                  : Colors.blue),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.edit_document,
                                              size: isPhoneScale ? 30 : 40,
                                              color: _controller.signatures[Signer.borrowerIn] != null
                                                  ? Colors.grey.shade600
                                                  : Colors.blue,
                                            ),
                                            
                                            SizedBox(height: 5),
                                            Text(
                                              "ลายเซ็นผู้ยืมบัตร",
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: _controller.signatures[Signer.borrowerIn] != null
                                                  ? Colors.grey.shade600
                                                  : Colors.blue
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(width: 10),


                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // action
                                      if(_controller.signatures[Signer.borrowerIn] != null && _controller.nameController.text.isNotEmpty) {
                                        await _controller.insertTemporaryPass();
                                        prepare();
                                      }else{
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            backgroundColor: Colors.red.shade700,
                                            icon: Icon(Icons.sentiment_very_satisfied,
                                                color: Colors.red.shade900, size: 120),
                                            message: "กรุณกรอกข้อมูลให้ครบถ้วน",
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'บันทึก',
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),

                          ]else ...[

                          Row(
                            children: [
                              Expanded(
                                  flex: isPhoneScale ? 2 : 3,
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
                                            Icon(Icons.edit_document,
                                              size: 30,
                                              color: Colors.blue,
                                            ),
                                            
                                            SizedBox(height: 5),
                                            Text(
                                              "ลงชื่อพนักงาน",
                                              style: TextStyle(
                                                fontSize: _fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue
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

                          SizedBox(height: 20,),
                          

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller.nameFilterController,
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

                              SizedBox(width: 10,),

                              DropDownFilterSearchWidget(),

                            ],
                          ),


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
    if (_controller.titleController.text.isEmpty) {
      _controller.titleController.text = titleNameList[0];
    }
    return DropdownButtonFormField<String>(
        value: _controller.titleController.text,
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
            _controller.titleController.text = newValue!;
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
        value: _controller.selectedCardType,
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
        items: _controller.cardTypeMap.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          final updater = setStateDialog ?? setState;
          updater(() {
            _controller.selectedCardType = newValue!;
            _controller.filterCardType();
          });
        },
      ),
    ),
  );
}

  Widget dropDownPassCard([void Function(void Function())? setStateDialog]) {
    List<String> cardList = _controller.filterCardList.map<String>((item) => item['card_id'].toString()).toList();
    if (cardList.isNotEmpty && _controller.selectedCard.isEmpty) {
      _controller.selectedCard = cardList[0];
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
          value: _controller.selectedCard,
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
              _controller.selectedCard = newValue!;
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
    child: _controller.filteredTemporaryList.isEmpty
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
              itemCount: _controller.filteredTemporaryList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> entry = _controller.filteredTemporaryList[index];
                return itemForm(entry);
              },
            ),
          ),
  );
}


  Widget itemForm(Map<String, dynamic> entry) {
  final allSigned = Signer.values
      .map((s) => getKeyFromSigner(s))
      .every((key) => entry[key] != null && entry[key].toString().isNotEmpty);

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
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
              padding: EdgeInsets.fromLTRB(16, 27, 16, 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 239, 248, 255),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 70,
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
                  // borderRadius: BorderRadius.only(
                  //   bottomRight: Radius.circular(8),
                  //   bottomLeft: Radius.circular(8),
                  // ),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['brw_at'])),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (entry['remark'] != null && entry['remark'].toString().isNotEmpty) ...[
              Positioned(
              top: 40,
              left: 70,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159), // พลิกแนวนอนถ้าต้องการ
                child: Icon(
                    Icons.comment,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
            ],
            
          ],
        ),
      ),
    ),
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


Widget DropDownFilterSearchWidget() {
  return IntrinsicWidth(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        value: _controller.selectedFilterCardType,
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
        items: _controller.filterCardTypeList.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _controller.selectedFilterCardType = newValue!;
            _controller.filterTemporaryList();
          });
        },
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
                                    _controller.updateRemark(entry['id'], _controller.remarkController.text);
                                    _controller.remarkController.clear();
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
                                    controller: _controller.nameController,
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
              
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.spaceAround,
                                  children: [
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
                                  ],
                                ),
                                // // Card ID
                                // Text('ประเภทบัตร :',
                                //     style: TextStyle(
                                //         fontWeight: FontWeight.bold,
                                //         fontSize: _fontSize)),
                                // SizedBox(height: 2.5),
                                // dropDownCardType(),
                                // SizedBox(height: 20),
              
                                // Text('หมายเลขบัตร :',
                                //     style: TextStyle(
                                //         fontWeight: FontWeight.bold,
                                //         fontSize: _fontSize)),
                                // SizedBox(height: 2.5),
                                // dropDownPassCard(),
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
                                            12),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            12),
                                        child: SfSignaturePad(
                                          key: _controller.signatureGlobalKey,
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
                                  _controller.clearInputInsert();
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
                                  if (_controller.signatureGlobalKey.currentState?.toPathList().isEmpty == true || _controller.nameController.text.isEmpty) {
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
                                              final padState = _controller.signatureGlobalKey.currentState;
                                              final image = await padState?.toImage();
                                              final bytes = await image?.toByteData(format: ImageByteFormat.png);
                                              if (bytes != null) {
                                                setStateDialog(() {
                                                  _controller.signatures[Signer.borrowerIn] = bytes.buffer.asUint8List();
                                                });
                                              }
                                              await _controller.insertTemporaryPass();
                                              setStateDialog(() { // clear signature
                                                _controller.signatures[Signer.borrowerIn] = null;
                                                _controller.clearInputInsert();
                                                _controller.signatureGlobalKey = GlobalKey<SfSignaturePadState>();
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



  void signerPopup(Signer signer, [Map<String,dynamic>? entry]) {
  bool isUpdate = entry != null;
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
            child: IntrinsicWidth( // ✅ ปรับให้ขนาดตาม content
              child: IntrinsicHeight(
                child: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    // อ่านข้อมูลลายเซ็นปัจจุบันจาก controller
                    Uint8List? signatureDisplay = _controller.signatures[signer];
                    bool currentEditing = isEditingMap[signer] ?? (signatureDisplay != null);
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
                                      child: !currentEditing
                                          ? SfSignaturePad(
                                              key: _controller.signatureGlobalKey,
                                              backgroundColor: Colors.transparent,
                                              strokeColor: Colors.black,
                                              minimumStrokeWidth: 3.0,
                                              maximumStrokeWidth: 6.0,
                                            )
                                          : Image.memory(signatureDisplay!),
                                    ),
                                  ),

                                  // ปุ่มเคลียร์ / แก้ไข
                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (currentEditing) {
                                          CustomDialog.show(
                                            context: context,
                                            title: 'คำเตือน',
                                            message: "คุณต้องการแก้ไขลายเซ็นใช่หรือไม่?",
                                            type: DialogType.warning,
                                            onConfirm: () async {
                                              Navigator.pop(context);
                                              setStateDialog(() {
                                                isEditingMap[signer] = false;
                                                _controller.signatures[signer] = null;
                                                _controller.signatureGlobalKey = GlobalKey<SfSignaturePadState>();
                                              });
                                            },
                                            onCancel: () => Navigator.pop(context),
                                          );
                                        } else {
                                          _controller.signatureGlobalKey.currentState?.clear();
                                        }
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
                                    if (currentEditing) {
                                      // มีลายเซ็นอยู่แล้ว
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.info(
                                          backgroundColor: Colors.blue.shade700,
                                          icon: Icon(
                                            Icons.info_outline,
                                            color: Colors.blue,
                                            size: 100,
                                          ),
                                          message: 'ลายเซ็นนี้ถูกบันทึกไปแล้ว',
                                        ),
                                      );
                                      return;
                                    }

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
                                    }

                                    // ถ้ามีการเซ็นแล้ว
                                    if(isUpdate) {
                                      await CustomDialog.show(
                                            context: context,
                                            title: 'คำเตือน',
                                            message: "คุณต้องการบันทึกลายเซ็นใช่หรือไม่? การดำเนินการนี้จะไม่สามารถย้อนกลับมาแก้ไขได้",
                                            type: DialogType.info,
                                            onConfirm: () async {
                                              if (!currentEditing) {
                                                final image = await padState.toImage();
                                                final bytes = await image.toByteData(format: ImageByteFormat.png);
                                                if (bytes != null) {
                                                  setStateDialog(() {
                                                    _controller.signatures[signer] = bytes.buffer.asUint8List();
                                                  });
                                                }
                                              }
                                              await _controller.updateSignature(entry, signer);

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
                                    }else{
                                      // For borrow in insert
                                      if (!currentEditing) {
                                        final image = await padState.toImage();
                                        final bytes = await image.toByteData(format: ImageByteFormat.png);
                                        if (bytes != null) {
                                          setStateDialog(() {
                                            _controller.signatures[signer] = bytes.buffer.asUint8List();
                                            isEditingMap[signer] = true;
                                          });
                                        }
                                      }
                                      Navigator.of(context).pop();
                                    }
                                    setState(() { });
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
                primaryColor: Colors.grey,
                colorScheme: ColorScheme.light(
                  primary: Colors.grey,
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
    }
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
