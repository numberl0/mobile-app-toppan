import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/utils/AppDateTime.dart';
import 'package:toppan_app/utils/CustomDIalog.dart';
import 'package:toppan_app/config/api_config.dart';

import '../../utils/BaseScaffold.dart';
import '../../entity/signature_section.dart';
import 'permis_controller.dart';

class PermisPage extends StatelessWidget {
  final Map<String, dynamic>? documentData;

  const PermisPage({
    super.key,
    this.documentData,
  });

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'ใบคำร้องกรณีบัตรหายหรือชำรุด',
      child: PermisContent(
        documentData: documentData,
      ),
    );
  }
}

class PermisContent extends StatefulWidget {
  final Map<String, dynamic>? documentData;

  const PermisContent({
    super.key,
    this.documentData,
  });

  @override
  State<PermisContent> createState() => _PermisContentState();
}


class _PermisContentState extends State<PermisContent>with SingleTickerProviderStateMixin {
  PermisController _con = PermisController();

  Color? _acceptBtnColor = Colors.blue;
  double _fontSize = ApiConfig.fontSize;
  bool isPhoneScale = false; 
  final FocusNode _focusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

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
    if (widget.documentData != null) {
      final data = widget.documentData;
      await _con.initalLoadPage(context, data);
    } else {
      await _con.initalNewPage(context);
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
                              Text('วันที่ : ${DateFormat('dd/MM/yyyy').format(_con.docDate.value)}', style: TextStyle( fontSize: _fontSize, fontWeight: FontWeight.bold),)
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
                                  controller: _con.reqNameController,
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
                                        controller: _con.reqDeptController,
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
                                        controller: _con.reqEmpIdController,
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
                                            bool status = await _con.searchInfoByPid(_con.reqEmpIdController.text);
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
                                      controller: _con.reqDeptController,
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
                                groupValue: _con.selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    _con.selectRadioCardReason(value!);
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
                                groupValue: _con.selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    _con.selectRadioCardReason(value!);
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
                                groupValue: _con.selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    _con.selectRadioCardReason(value!);
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
                                    controller: _con.otherReasonController,
                                    style: TextStyle(
                                        fontSize: _fontSize,
                                        color: Colors.black,
                                      ),
                                    enabled: _con.selectedReason == CardReason.other,
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
                                        if ( (value == null || value.trim().isEmpty) && _con.selectedReason == CardReason.other ) {
                                          return 'กรุณาระบุข้อมูลเพิ่มเติม';
                                        }
                                        return null;
                                      },
                                    onTap: () {
                                      if (_con.selectedReason != CardReason.other) {
                                        setState(() {
                                          _con.selectedReason = CardReason.other;
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
                                  groupValue: _con.selectedReason,
                                  onChanged: (value) {
                                    setState(() {
                                      _con.selectRadioCardReason(value!);
                                    });
                                  },
                                  fillColor: MaterialStateProperty.all(Colors.blue),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _con.selectedReason = CardReason.other;
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
                                  valueListenable: _con.untilDate,
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
                                          onPressed: () => _datePicker(context, _con.untilDate),
                                        ),
                                      ),
                                      controller: TextEditingController(
                                        text: date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
                                      ),
                                      onTap: () => _datePicker(context, _con.untilDate),
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
                            controller: _con.responToController,
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
                                      child: SizedBox(
                                        height: 250,
                                        width: double.maxFinite,
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          child: ListView(
                                            padding: EdgeInsets.zero,
                                            children: _con.managerNames.map((name) {
                                              return ListTile(
                                                title: Text(
                                                  name,
                                                  style: TextStyle(color: Colors.black),
                                                ),
                                                onTap: () {
                                                  _con.responToController.text = name;
                                                  Navigator.pop(context);
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                                onSelected: (_) {},
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
                                          siteCheckboxes(),
                                        ],
                                      ),
                                    ),
                          SizedBox(height: 15,),
                          Text('หมายเลขบัตร PERMANENT', style: TextStyle( fontSize: _fontSize-2, fontWeight: FontWeight.bold),),
                          SizedBox(height: 5,),
                          dropDownPassCard(),
                          SizedBox(height: 25,),
                      
                          // Open Signature popup
                          if(!_con.flagUpdateForm) ...[
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
                                      splashColor: Colors.blue.withOpacity(0.3),
                                      highlightColor: Colors.blue.withOpacity(0.1),
                                      child: Container(
                                        padding: EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.blue,
                                          ),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.assignment_outlined,
                                              size: 50,
                                              color: Colors.blue,
                                            ),
                                            Text(
                                              "ลงชื่อ",
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
                              ],
                            ),
                          ],
                          
                          SizedBox(height: 25,),
                      
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                // Makes button take up full available width
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      if ( _con.hasSignature()  ) {
                                        bool insertSuccess = await _con.insertForm();
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
                                            if(!_con.flagUpdateForm) {
                                              GoRouter.of(context).pushReplacement('/home');
                                            } else {
                                              GoRouter.of(context)..pop()..pop()..pushReplacement('/search');
                                            }
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

  Widget siteCheckboxes() {
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          showCheckmark: false,
          selected: isSelected,
          selectedColor: Colors.blue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onSelected: (_) {
            setState(() {
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


  Widget dropDownTitleName() {
    if (_con.reqTitleController.text.isEmpty) {
      _con.reqTitleController.text = _con.titleNameList[0];
    }
    return DropdownButtonFormField<String>(
        value: _con.reqTitleController.text,
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
        items: _con.titleNameList.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _con.reqTitleController.text = newValue!;
          });
        },
      );
  }


  Widget dropDownPassCard() {
  List<String> cardList = _con.filterCardList
      .map<String>((item) => item['card_id'].toString())
      .toList();

  if (cardList.isNotEmpty && _con.selectedCard.isEmpty) {
    _con.selectedCard = cardList[0];
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
            _con.selectedCard = value;
          });
        },
        color: Colors.white,
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Container(
                // height: 200,
                // width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: 200,
                  
                ),
                width: double.maxFinite,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    shrinkWrap: true,
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
                            _con.selectedCard = item;
                          });
                          Navigator.pop(context);
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
              _con.selectedCard,
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
     List<String> sectionKeys = _con.signatureSection.keys.toList();
    final ScrollController controller = ScrollController();
    final FixedExtentScrollController menuRowController = FixedExtentScrollController();

    // initial value
    int currentIndex = 0;

    SignatureSection currentSection = _con.signatureSection[sectionKeys[currentIndex]]!;
    TextEditingController signaturesByDisplay = TextEditingController(text: currentSection.by ?? '');

    // Uint8List? signatureDisplay =
    //     _con.signatureSectionMap[sectionKeys[currentIndex]]?[0];
    // DateTime? dateTimeSignDisplay =
    //     _con.signatureSectionMap[sectionKeys[currentIndex]]?[1];
    // TextEditingController signaturesByDisplay = TextEditingController(
    //     text: _con.signatureSectionMap[sectionKeys[currentIndex]]?[3] ??
    //         '');

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
                                  sectionKeys[index],
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
            : Container(
                padding: EdgeInsets.only(bottom: 15),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  destinations:
                     filteredKeys.asMap().entries.map((entry) {
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
      final key = sectionKeys[currentIndex];
      return 
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
                          // =========================
                          // LABEL
                          // =========================
                          Text(
                           currentSection.label,
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

                                  Positioned(
                                    left: 10,
                                    bottom: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (hasSignature()) {
                                    warningDialog(
                                        'คุณต้องการจะลบลายเซ็น ${sectionKeys[currentIndex]} ใช่หรือไม่? การกระทำนี้จะไม่สามารถย้อนกลับมาแก้ไขได้',
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
                                    });
                                  } else if (_con.signatureGlobalKey.currentState!.toPathList().isNotEmpty) {
                                    _con.signatureGlobalKey.currentState!
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
                                  cursorColor: Colors.blue,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: currentSection.dateTime == null
                                        ? ''
                                        : DateFormat('HH:mm').format(currentSection.dateTime!),
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
                                    text: currentSection.dateTime == null
                                        ? ''
                                        : DateFormat('dd/MM/yyyy').format(currentSection.dateTime!),
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
          );
    }

    //show Dialog
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close dialog',
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
              FocusManager.instance.primaryFocus?.unfocus();
            } else {
              Navigator.of(context).pop();
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
                  builder: (BuildContext context, StateSetter setStateDialog) {
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
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
