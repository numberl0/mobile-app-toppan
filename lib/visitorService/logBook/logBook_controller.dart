
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:toppan_app/app_logger.dart';
import 'package:toppan_app/component/AppDateTime.dart';
import 'package:toppan_app/loading_dialog.dart';
import 'package:toppan_app/userEntity.dart';
import 'package:toppan_app/visitorService/logBook/logBook_model.dart';
import 'package:toppan_app/visitorService/center_controller.dart';

class LogBookController {

  LogBookModel docLogModel = LogBookModel();

  CenterController _centerController = CenterController();

  UserEntity userEntity = UserEntity();

  bool startAnimation = false;

  List<dynamic> list_Request = [];
  List<dynamic> filteredDocument = [];
  final List<String> typeOptions = ['Visitor', 'Employee', 'Permission', 'Temporary'];
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

  Uint8List? pdfBytes;

  final LoadingDialog _loadingDialog = LoadingDialog();

  Future<void> preparePage(BuildContext context) async {
    try {
      _loadingDialog.show(context);

      startDate = AppDateTime.now();
      endDate  = AppDateTime.now();

      sDateControl.text = DateFormat('yyyy-MM-dd').format(AppDateTime.now());          // Example: 2025-03-14
      eDateControl.text = DateFormat('yyyy-MM-dd').format(AppDateTime.now());

    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    } finally {
      await Future.delayed(Duration(seconds: 1));
      _loadingDialog.hide();
    }
  }

  Future<String> searchLogBook() async {
    try {
      // Example: 2025-03-14
      String formatStartDate = DateFormat('yyyy-MM-dd').format(startDate!);
      String formatEndDate = DateFormat('yyyy-MM-dd').format(endDate!);
      pdfBytes = await docLogModel.getLogBook(selectedType!.toLowerCase(), formatStartDate, formatEndDate);
      String pdf_name = "LogBook_" + "${selectedType}_" + "${DateFormat('yyyy-MM-dd').format(startDate!)}" + "_to_" + "${DateFormat('yyyy-MM-dd').format(endDate!)}" + ".pdf";
      return pdf_name;
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      pdfBytes = null;
      await _centerController.logError(err.toString(), stack.toString());
      return '';
    }
  }

    Future<bool> checkDateInFrist() async {
    try {
      final outDate = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final inDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
      return !inDate.isAfter(outDate);
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
      return false;
    }
  }

  Future<void> filterRequestList() async {
    try {
      filteredDocument = list_Request.where((entry) {
        final String requestType = entry['request_type']?.toLowerCase() ?? '';

        final matchesType = selectedType == 'All' ||
            requestType.contains(selectedType!.toLowerCase());

        if (!matchesType) return false;

        if (selectedType == 'Employee') {
          final area = entry['area'] ?? '';
          if (checkBF && checkC) {
            return true;
          }
          else if (checkBF && !checkC) {
            return area == 'อาคาร B';
          }
          else if (!checkBF && checkC) {
            return area == 'อาคาร C';
          }
          else {
            return false;
          }
        }
        return true;
      }).toList();
    } catch (err, stack) {
      AppLogger.error('Error: $err\n$stack');
      await _centerController.logError(err.toString(), stack.toString());
    }
  }

}