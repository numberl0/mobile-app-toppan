import 'package:flutter/material.dart';
import 'package:toppan_app/visitorService/approve/approve_view.dart';
import 'package:toppan_app/visitorService/cardOff/permis_view.dart';
import 'package:toppan_app/visitorService/employee/employee_view.dart';
import 'package:toppan_app/visitorService/logBook/logBook_view.dart';
import 'package:toppan_app/visitorService/partTime/partTime_view.dart';
import 'package:toppan_app/visitorService/search/search_view.dart';
import 'package:toppan_app/visitorService/visitor/visitor_view.dart';

class VisitorPage extends StatelessWidget {
  final String selectedOption;
  final Map<String, dynamic>? documentData;
  VisitorPage({super.key, required this.selectedOption, this.documentData});

  final VisitorForm _visitorForm = VisitorForm();
  final EmployeeForm _employeeForm = EmployeeForm();
  final SearchForm _searchForm =   SearchForm();
  final ApproveView _approveForm = ApproveView();
  final LogBookView _logBookForm = LogBookView();
  final CardOffForm _cardOffForm = CardOffForm();
  final PartTimePage _partTimePage = PartTimePage();
  
  @override
  Widget build(BuildContext context) {
    double _fontSize = 24.0;
    return Container(
      decoration:  const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromARGB(255, 132, 194, 252),
              Color.fromARGB(255, 45, 152, 240),
              Color.fromARGB(255, 48, 114, 236),
              Color.fromARGB(255, 0, 93, 199),
            ],
          )
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(
              _getPageTitle(selectedOption),
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration:  const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color.fromARGB(255, 230, 230, 230),
                    Color.fromARGB(255, 255, 255, 255),
                  ],
                  transform: GradientRotation(90),
                ),
              ),
            ),
            leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ),
          backgroundColor: Colors.transparent,
          body: _getPageContent(context),
        ),
    );
  }

  String _getPageTitle(String selectedOption) {
    const titles = {
      'visitor': 'ใบผ่านบุคคลภายนอก',
      'employee': 'ใบผ่านพนักงาน',
      'search': 'ค้นหาใบผ่านและใบคำร้อง',
      'approve': 'อนุมัติคำร้อง',
      'logBook': 'ล็อกบุ๊ค',
      'cardOff': 'ใบคำร้องกรณีบัตรหายหรือชำรุด',
      'partTime': 'ล็อกบุ๊คพนักงานชั่วคราวและอื่นๆ',
    };
    return titles[selectedOption] ?? 'Unknown';
  }

  Widget _getPageContent(BuildContext context) {
    final Map<String, Widget Function(BuildContext)> formMap = {
      'visitor': (context) => _visitorForm.visitorFormWidget(documentData),
      'employee': (context) => _employeeForm.employeeFormWidget(documentData),
      'search': (context) => _searchForm.searchFormWidget(context),
      'approve': (context) => _approveForm.approveFormWidget(context),
      'logBook': (context) => _logBookForm.LogDocFormWidget(context),
      'cardOff': (context) => _cardOffForm.CardOffFormWidget(documentData),
      'partTime': (context) => _partTimePage.buildPartTimeForm(context),
    };
    return formMap[selectedOption]?.call(context) ?? Container();
  }

}