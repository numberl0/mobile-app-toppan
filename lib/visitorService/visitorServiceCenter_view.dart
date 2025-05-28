import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toppan_app/visitorService/approve/approve_view.dart';
import 'package:toppan_app/visitorService/employee/employee_view.dart';
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
                fontSize: _fontSize, // Dynamic font size for the title
                fontWeight: FontWeight.bold, // Optional: Make it bold
                color: Colors.black, // Optional: Set text color
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
            // actions: [
            //   IconButton(
            //     icon: Icon(
            //       Icons.notifications,
            //       color: Colors.black87,
            //       size: 28, 
            //     ),
            //     onPressed: () {
                  
            //     },
            //   ),
            // ],
            leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: () {
              GoRouter.of(context).push('/home');
            },
          ),
          ),
          backgroundColor: Colors.transparent,
          body: _getPageContent(context),
        ),
    );
  }


// Simplify the title getter function
  String _getPageTitle(String selectedOption) {
    const titles = {
      'visitor': 'ใบผ่านผู้มาติดต่อ',
      'employee': 'ใบผ่านพนักงาน',
      'search': 'ค้นหาใบผ่าน',
      'approve': 'อนุมัติใบผ่าน',
    };
    return titles[selectedOption] ?? 'Unknown';
  }

  // Simplify page content function with a map for readability
  Widget _getPageContent(BuildContext context) {
    final Map<String, Widget Function(BuildContext)> formMap = {
      'visitor': (context) => _visitorForm.visitorFormWidget(documentData),
      'employee': (context) => _employeeForm.employeeFormWidget(documentData),
      'search': (context) => _searchForm.searchFormWidget(context),
      'approve': (context) => _approveForm.approveFormWidget(context),
    };

    // Return the correct widget based on the selected option
    return formMap[selectedOption]?.call(context) ?? Container();
  }

}