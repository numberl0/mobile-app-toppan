
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/logBook/logBook_model.dart';
import 'package:toppan_app/visitorService/visitorServiceCenter_controller.dart';

class LogBookController {

  LogBookModel docLogModel = LogBookModel();

  VisitorServiceCenterController controllerServiceCenter = VisitorServiceCenterController();

  UserEntity userEntity = UserEntity();

  bool startAnimation = false;

  // List document
  List<dynamic> list_Request = [];

  List<dynamic> filteredDocument = [];
  final List<String> typeOptions = ['All', 'Employee', 'Visitor'];
  String? selectedType;

  bool checkBF = true;
  bool checkC = true;

  // Controller for search fields
  TextEditingController companyController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  // Date Search
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController sDateControl= TextEditingController();
  TextEditingController eDateControl= TextEditingController();

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<void> preparePage(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      startDate = DateTime.now();
      endDate  = DateTime.now();

      sDateControl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());          // Example: 2025-03-14
      eDateControl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      list_Request = await docLogModel.getLogBook(sDateControl.text, eDateControl.text);

    } catch (err, stackTrace) {
      await controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  Future<void> searchDocByRangeDate() async {
    try {
      // Example: 2025-03-14
      String formatStartDate = DateFormat('yyyy-MM-dd').format(startDate!);
      String formatEndDate = DateFormat('yyyy-MM-dd').format(endDate!);
      list_Request = await docLogModel.getLogBook(formatStartDate,formatEndDate);

    } catch (err, stackTrace) {
      await controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

    Future<bool> checkDateInFrist() async {
    try {
      final outDate = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final inDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
      return !inDate.isAfter(outDate);
    } catch (err, stackTrace) {
      await controllerServiceCenter.logError(err.toString(), stackTrace.toString());
      return false;
    }
  }

  Future<void> filterRequestList() async {
    try {
      filteredDocument = list_Request.where((entry) {
        final String requestType = entry['request_type']?.toLowerCase() ?? '';

        // Filter by type
        final matchesType = selectedType == 'All' ||
            requestType.contains(selectedType!.toLowerCase());

        // If not matching type, skip entry immediately
        if (!matchesType) return false;

        // If Employee, apply area filter
        if (selectedType == 'Employee') {
          final area = entry['area'] ?? '';

          // If both checkboxes checked, no area filter
          if (checkBF && checkC) {
            return true; // matchesType already true, so include
          }
          // Only BF checked
          else if (checkBF && !checkC) {
            return area == 'อาคาร B';
          }
          // Only C checked
          else if (!checkBF && checkC) {
            return area == 'อาคาร C';
          }
          // Neither checkbox checked - exclude all
          else {
            return false;
          }
        }

        // For non-Employee types, matchesType is already true
        return true;

        // return matchesType;
      }).toList();
    } catch (err, stackTrace) {
      await controllerServiceCenter.logError(err.toString(), stackTrace.toString());
    }
  }

}