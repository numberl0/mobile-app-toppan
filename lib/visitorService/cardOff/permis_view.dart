import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/component/CustomDIalog.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/visitorService/cardOff/permis_controller.dart';

class CardOffForm {
  Widget CardOffFormWidget(Map<String, dynamic>? docData) {
    return CardOffFormPage(documentData: docData);
  }
}

class CardOffFormPage extends StatefulWidget {
  final Map<String, dynamic>? documentData;
  const CardOffFormPage({super.key, this.documentData});
  @override
  _CardOffFormPageState createState() => _CardOffFormPageState();
}

class _CardOffFormPageState extends State<CardOffFormPage>with SingleTickerProviderStateMixin {
  CardOffController _controller = CardOffController();

  Color? _cancelBtnColor = Colors.red;
  Color? _acceptBtnColor = Colors.blue;
  double _fontSize = ApiConfig.fontSize;
  bool isPhoneScale = false; 
  final FocusNode _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    prepare();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() {

    //   });
    // });
  }

   @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void prepare() async {
    if (widget.documentData != null) {
      final data = widget.documentData;
      await _controller.initalLoadPage(context, data);
    } else {
      await _controller.initalNewPage(context);
    }
    setState(() {});
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
            padding: const EdgeInsets.all(30.0),
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

                          Text("ข้อมูลผู้ขออนุญาต", style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold)),
                          SizedBox(height: 10,),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: dropDownTitleName(),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 8,
                                child: TextFormField(
                                  controller: _controller.reqNameController,
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'ชื่อ-นามสกุล ผู้ขออนุญาต...',
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
                                          return 'กรุณาระบุชื่อผู้ขออนุญาต';
                                        }
                                        return null;
                                      },
                                    ),
                              ),
                            ],
                          ),
                      
                          SizedBox(height: 20),
                      
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                        controller: _controller.reqDeptController,
                                        style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                        decoration: InputDecoration(
                                        hintText: 'แผนก...',
                                        hintStyle: TextStyle(
                                          fontSize: _fontSize-4,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        isDense: true, // ลด padding ด้านในให้ compact ขึ้น
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
                                          return 'กรุณาระบุแผนก';
                                        }
                                        return null;
                                      },
                                    ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                        controller: _controller.reqEmpIdController,
                                        style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                        decoration: InputDecoration(
                                        hintText: 'รหัสพนักงาน...',
                                        hintStyle: TextStyle(
                                          fontSize: _fontSize-4,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        isDense: true,
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.person_search, color: Colors.blue, size: _fontSize + 8),
                                          onPressed: () async {
                                            bool status = await _controller.searchInfoByPid(_controller.reqEmpIdController.text);
                                            if(!status){
                                              showTopSnackBar(
                                                Overlay.of(context),
                                                CustomSnackBar.error(
                                                  backgroundColor: Colors.red.shade700,
                                                  icon: Icon(Icons.sentiment_very_satisfied,
                                                      color: Colors.red.shade900, size: 120),
                                                  message: 'ไม่พบข้อมูลพนักงาน',
                                                ),
                                              );
                                            }
                                          },
                                        ),
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
                                          return 'กรุณาระบุรหัสพนักงาน';
                                        }
                                        return null;
                                      },
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20,),

                          Text('เรียน : ผู้จัดการ/ผู้ช่วยผู้จัดการแผนก', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),),
                          SizedBox(height: 5,),
                          TextFormField(
                                      controller: _controller.reqDeptController,
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'แผนก...',
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
                                          return 'กรุณาระบุข้อมูลผู้ติดต่อ';
                                        }
                                        return null;
                                      },
                                    ),
                                    
                      
                          SizedBox(height: 20,),
                      
                          ListTile(
                            title: Text("ทำบัตรประจำตัวพนักงานหาย", style: TextStyle(fontSize: _fontSize)),
                            leading: Transform.scale(
                              scale: 1.2, // ปรับขนาดใหญ่
                              child: Radio<CardReason>(
                                value: CardReason.lost,
                                groupValue: _controller.selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    _controller.selectRadioCardReason(value!);
                                    _formKey.currentState!.validate();
                                  });
                                },
                                fillColor: MaterialStateProperty.all(Colors.blue),
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text("ลืมบัตรประจำตัวพนักงานมา", style: TextStyle(fontSize: _fontSize)),
                            leading: Transform.scale(
                              scale: 1.2, // ปรับขนาดใหญ่
                              child: Radio<CardReason>(
                                value: CardReason.forgotten,
                                groupValue: _controller.selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    _controller.selectRadioCardReason(value!);
                                    _formKey.currentState!.validate();
                                  });
                                },
                                fillColor: MaterialStateProperty.all(Colors.blue),
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text("บัตรประจำตัวพนักงานชำรุด", style: TextStyle(fontSize: _fontSize)),
                            leading: Transform.scale(
                              scale: 1.2, // ปรับขนาดใหญ่
                              child: Radio<CardReason>(
                                value: CardReason.damaged,
                                groupValue: _controller.selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    _controller.selectRadioCardReason(value!);
                                    _formKey.currentState!.validate();
                                  });
                                },
                                fillColor: MaterialStateProperty.all(Colors.blue),
                              ),
                            ),
                          ),
                          
                          ListTile(
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text("อื่นๆ", style: TextStyle(fontSize: _fontSize)),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _controller.otherReasonController,
                                    style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                    enabled: _controller.selectedReason == CardReason.other,
                                    decoration: InputDecoration(
                                      hintText: 'โปรดระบุเหตุผล...',
                                      hintStyle: TextStyle(
                                          fontSize: _fontSize-4,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      border: OutlineInputBorder(),
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
                                        if ( (value == null || value.trim().isEmpty) && _controller.selectedReason == CardReason.other ) {
                                          return 'กรุณาระบุข้อมูลเพิ่มเติม';
                                        }
                                        return null;
                                      },
                                    onTap: () {
                                      if (_controller.selectedReason != CardReason.other) {
                                        setState(() {
                                          _controller.selectedReason = CardReason.other;
                                        });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              leading: Transform.scale(
                                scale: 1.2,
                                child: Radio<CardReason>(
                                  value: CardReason.other,
                                  groupValue: _controller.selectedReason,
                                  onChanged: (value) {
                                    setState(() {
                                      _controller.selectRadioCardReason(value!);
                                    });
                                  },
                                  fillColor: MaterialStateProperty.all(Colors.blue),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _controller.selectedReason = CardReason.other;
                                });
                              },
                            ),
                          SizedBox(height: 20,),
                        
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('จะดำเนินการให้แล้วเสร็จภายในวันที่ :', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),),
                              SizedBox(width: 5,),
                              
                              SizedBox(
                                width: isPhoneScale ? MediaQuery.of(context).size.width * 0.3 : MediaQuery.of(context).size.width * 0.25,
                                child: ValueListenableBuilder<DateTime?>(
                                  valueListenable: _controller.untilDate,
                                  builder: (context, date, _) {
                                    return TextFormField(
                                      readOnly: true,
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'วว/ดด/ปปปป',
                                        hintStyle: TextStyle(
                                          fontSize: _fontSize - 4,
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
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.calendar_month, color: Colors.blue, size: _fontSize + 8),
                                          onPressed: () => _datePicker(context, _controller.untilDate),
                                        ),
                                      ),
                                      controller: TextEditingController(
                                        text: date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
                                      ),
                                      onTap: () => _datePicker(context, _controller.untilDate),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'กรุณาเลือกวันที่';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                              ),
                      
                      
                            ],
                          ),
                          SizedBox(height: 20,),

                          Text('โดยแจ้งถึงหัวหน้ากะ/ผู้ช่วยผู้จัดการ/ผู้จัดการแผนก', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),),
                          SizedBox(height: 5,),

                          TextFormField(
                            controller: _controller.responToController,
                            style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                            decoration: InputDecoration(
                              hintText: 'ชื่อ-นามสกุล...',
                              hintStyle: TextStyle(
                                          fontSize: _fontSize-4,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              suffixIcon: PopupMenuButton<String>(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem<String>(
                                      // enabled = true เพื่อให้ Text สีปกติ
                                      child: SizedBox(
                                        height: 250, // ความสูง dropdown
                                        width: double.maxFinite,
                                        child: Scrollbar(
                                          thumbVisibility: true, // แสดง scrollbar
                                          child: ListView(
                                            padding: EdgeInsets.zero,
                                            children: _controller.managerNames.map((name) {
                                              return ListTile(
                                                title: Text(
                                                  name,
                                                  style: TextStyle(color: Colors.black), // บังคับสีตัวหนังสือ
                                                ),
                                                onTap: () {
                                                  _controller.responToController.text = name;
                                                  Navigator.pop(context); // ปิด dropdown
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                                onSelected: (_) {}, // ไม่ต้องใช้ onSelected เพราะ ListTile handle tap
                              ),
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
                                        if (value == null || value.isEmpty) {
                                          return 'กรุณาระบุบชื่อผู้รับเรื่อง';
                                        }
                                        return null;
                                      },
                            ),
                            
                          SizedBox(height: 20,),
                      
        
                          Text('หมายเลขบัตร PERMANENT', style: TextStyle( fontSize: _fontSize-2, fontWeight: FontWeight.bold),),
                          SizedBox(height: 5,),
                          dropDownPassCard(),
                          SizedBox(height: 25,),
                      
                          // Open Signature popup
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
                                    splashColor: Colors.grey.withOpacity(0.3),
                                    highlightColor: Colors.grey.withOpacity(0.1),
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
                          SizedBox(height: 25,),
                      
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                // Makes button take up full available width
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      if (_controller.signatureSectionMap['Employee']![0] != null) {
                                        bool insertSuccess = await _controller.insertForm();
                                        if (insertSuccess) {
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.success(
                                              backgroundColor: Colors.green.shade500,
                                              icon: Icon(Icons.sentiment_very_satisfied,
                                                  color: Colors.green.shade600,
                                                  size: 120),
                                              message: "ส่งคำร้องสำเร็จ",
                                            ),
                                          );
                                          Future.delayed(const Duration(seconds: 1), () {
                                            GoRouter.of(context).pushReplacement('/home');
                                          });
                                        }else{
                                          showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.error(
                                              backgroundColor: Colors.red.shade700,
                                              icon: Icon(Icons.sentiment_very_satisfied,
                                                  color: Colors.red.shade900, size: 120),
                                              message: "ส่งคำร้องไม่สำเร็จ",
                                            ),
                                          );
                                        }
                                      } else {
                                        showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.error(
                                              backgroundColor: Colors.red.shade700,
                                              icon: Icon(Icons.sentiment_very_satisfied,
                                                  color: Colors.red.shade900, size: 120),
                                              message: "กรุณาลงลายมือด้วย",
                                            ),
                                          );
                                      }
                                    } else {
                                      showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            backgroundColor: Colors.red.shade700,
                                            icon: Icon(Icons.sentiment_very_satisfied,
                                                color: Colors.red.shade900, size: 120),
                                            message: "กรุณากรอกข้อมูลให้ครบถ้วน",
                                          ),
                                        );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor:Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'ส่งคำร้อง',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget dropDownTitleName() {
    if (_controller.reqTitleController.text.isEmpty) {
      _controller.reqTitleController.text = _controller.titleNameList[0];
    }
    return DropdownButtonFormField<String>(
        value: _controller.reqTitleController.text,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.black),
        style: TextStyle(
          color: Colors.black,
          fontSize: _fontSize,
          height: 1.0,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        items: _controller.titleNameList.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _controller.reqTitleController.text = newValue!;
          });
        },
      );
  }


  Widget dropDownPassCard() {
  List<String> cardList = _controller.cardList
      .map<String>((item) => item['card_id'].toString())
      .toList();

  if (cardList.isNotEmpty && _controller.selectedCard.isEmpty) {
    _controller.selectedCard = cardList[0];
  }

  if (cardList.isEmpty) {
    return const Text(
      "ไม่พบบัตรให้เลือก",
      style: TextStyle(color: Colors.grey),
    );
  }

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: isPhoneScale ? MediaQuery.of(context).size.width * 0.3 : MediaQuery.of(context).size.width * 0.2,
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: PopupMenuButton<String>(
        onSelected: (String value) {
          setState(() {
            _controller.selectedCard = value;
          });
        },
        color: Colors.white,
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              enabled: false, // ปิดการเลือกของ PopupMenuItem หลัก
              child: SizedBox(
                height: 250, // ความสูง dropdown
                width: double.maxFinite,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: cardList.map((item) {
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: _fontSize-2,
                            color: Colors.black,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _controller.selectedCard = item;
                          });
                          Navigator.pop(context); // ปิด dropdown
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ];
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _controller.selectedCard,
              style: TextStyle(fontSize: _fontSize-2, color: Colors.black),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    ),
  );
}


  //Signature
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
    Future<void> stampSignatureApprove(DateTime dateTime, GlobalKey<SfSignaturePadState> signature) async {
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
                                  Colors.grey.shade600.withOpacity(0.3),
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
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                    SizedBox(height: 5),
                                    Flexible(
                                      child: Text(
                                        sectionLabel,
                                        style: TextStyle(
                                          fontSize: _fontSize,
                                          color: _isPressed
                                              ? Colors.black
                                              : Colors.grey,
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
            ignoring: false,
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
                                cursorColor: Colors.grey,
                                readOnly: signaturesByDisplay.text.isNotEmpty,
                                autofocus: false,
                                controller: signaturesByDisplay,
                                maxLines: null,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'ลงชื่อ...',
                                  hintStyle: TextStyle(
                                    fontSize: _fontSize-4,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(fontSize: _fontSize-2),
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
                                              AppDateTime.now(),
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
                                    Icon(Icons.save_as_rounded,
                                        color: Colors.white, size: _fontSize),
                                    SizedBox(width: 8),
                                    Text(
                                      'บันทึก',
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: dateTimeSignDisplay == null
                                        ? ''
                                        : DateFormat('HH:mm').format(dateTimeSignDisplay!),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'ชช:นน',
                                    hintStyle: TextStyle(
                                      fontSize: _fontSize - 2,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    suffixIcon: Icon(Icons.access_time_rounded, color: Colors.grey[600], size: _fontSize+8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: dateTimeSignDisplay == null
                                        ? ''
                                        : DateFormat('dd/MM/yyyy').format(dateTimeSignDisplay!),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'วว/ดด/ปปปป',
                                    hintStyle: TextStyle(
                                      fontSize: _fontSize - 2,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    suffixIcon: Icon(Icons.calendar_month, color: Colors.grey[600], size: _fontSize+8,),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  ),
                                ),
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
                size: isPhoneScale?47:50,
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
