import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/config/api_config.dart';
import 'package:toppan_app/main.dart';
import 'package:toppan_app/visitorService/logBook/logBook_controller.dart';

import '../../component/BaseScaffold.dart';

class LogBookPage extends StatelessWidget {
  const LogBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseScaffold(
      title: 'ล็อกบุ๊ค',
      child: LogBookContent(),
    );
  }
}

class LogBookContent extends StatefulWidget {
  const LogBookContent({super.key});

  @override
  State<LogBookContent> createState() => _LogBookContentState();
}

class _LogBookContentState  extends State<LogBookContent> with RouteAware {
  LogBookController _controller = LogBookController();
  double _fontSize = ApiConfig.fontSize;
  bool isPhoneScale = false;

  @override
  void initState() {
    super.initState();
    preparePage();
    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      setState(() {
        _controller.startAnimation = true;
      });
    });

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
      _fontSize = ApiConfig.getFontSize(context);
      isPhoneScale = ApiConfig.getPhoneScale(context);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          children: [
            const SizedBox(height: 5),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SearchInputBar(),
            ),
          ],
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
                                        Icons.calendar_month,
                                        color: Colors.blue,
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
                                        Icons.calendar_month,
                                        color: Colors.blue,
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
                              height: 25,
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
                                  case 'Permission':
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.yellow);
                                    break;
                                  case 'Temporary':
                                    icon = Icon(Icons.layers_rounded,
                                        color: Colors.blue);
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


                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  // Makes button take up full available width
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      String pdfname = await _controller.searchLogBook();
                                      if (_controller.pdfBytes != null) {
                                        await Printing.sharePdf(
                                          bytes: _controller.pdfBytes!,
                                          filename: pdfname,
                                        );
                                        setState(() { });
                                      } else {
                                         showTopSnackBar(
                                            Overlay.of(context),
                                            CustomSnackBar.error(
                                              backgroundColor: Colors.red.shade700,
                                              icon: Icon(Icons.sentiment_very_satisfied,
                                                  color: Colors.red.shade900, size: 120),
                                              message: "ไม่พบข้อมูล",
                                            ),
                                          );
                                      }

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

                          ],
                        ))))));
  }

  void initializeDateThaiFormatting() async {
    await initializeDateFormatting('th_TH', null);
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
