import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/visitorService/search/search_model.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';

class SearchFormController {
  SearchModule searchModule = SearchModule();


  VisitorServiceCenterController _controllerServiceCenter = VisitorServiceCenterController();

  // List document
  List<dynamic> list_Request = [];

  List<dynamic> filteredDocument = [];
  final List<String> typeOptions = ['All', 'Employee', 'Visitor'];
  String? selectedType;

  // Controller for search fields
  TextEditingController companyController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  bool startAnimation = false;

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<void> preparePage(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      String formatToDay = DateFormat('yyyy-MM-dd').format(DateTime.now());          // Example: 2025-03-14
      list_Request = await searchModule.getRequestFormByDate(formatToDay);
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  Future<void> filterRequestList() async {
    try {
      String searchCompany = companyController.text.toLowerCase();
      String searchName = nameController.text.toLowerCase();

      filteredDocument = list_Request.where((entry) {
        final String requestType = entry['request_type']?.toLowerCase() ?? '';
        final String companyName = entry['company']?.toLowerCase() ?? '';
        final List<dynamic>? peopleList = entry['people'];

        // Filter by type
        final matchesType = selectedType == 'All' ||
            requestType.contains(selectedType!.toLowerCase());

        // Filter by company name
        final matchesCompany =
            searchCompany.isEmpty || companyName.contains(searchCompany);

        // Filter by person's name inside "people" list
        final matchesPerson = searchName.isEmpty ||
            (peopleList != null &&
                peopleList.any((person) {
                  final String fullName =
                      person['FullName']?.toString().toLowerCase() ?? '';
                  return fullName.contains(searchName);
                }));

        return matchesType && matchesCompany && matchesPerson;
      }).toList();
    } catch (err, stackTrace) {
      _controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }


}
