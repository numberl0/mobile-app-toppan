import 'package:flutter/material.dart';

Color getRequestColor(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'VISITOR':
        return Colors.green;
      case 'EMPLOYEE':
        return Colors.orange;
      case 'PERMISSION':
        return Colors.yellow;
      case 'TEMPORARY':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

Color getBgColor(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'VISITOR':
        return const Color.fromARGB(255, 245, 255, 245);
      case 'EMPLOYEE':
        return const Color.fromARGB(255, 255, 250, 243);
      case 'PERMISSION':
        return const Color.fromARGB(255, 255, 255, 248);
      case 'TEMPORARY':
        return const Color.fromARGB(255, 245, 250, 255);
      default:
        return Colors.grey;
    }
  }