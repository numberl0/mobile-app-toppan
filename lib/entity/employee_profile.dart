import '../utils/AppDateTime.dart';

class Employee {
  final String id;
  String department;
  String titleName;
  String fullName;
  String employeeId;
  DateTime dateTime;

  Employee({
    required this.id,
    required this.department,
    required this.titleName,
    required this.fullName,
    required this.employeeId,
    required this.dateTime,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['ID'] ?? null,
      department: json['Department'] ?? null,
      titleName: json['TitleName'] ?? null,
      fullName: json['FullName'] ?? null,
      employeeId: json['EmployeeId'] ?? null,
      dateTime: DateTime.tryParse(json['DateTime'] ?? null) ?? AppDateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Department': department,
      'TitleName': titleName,
      'FullName': fullName,
      'EmployeeId': employeeId,
      'DateTime': dateTime.toString(),
    };
  }
}