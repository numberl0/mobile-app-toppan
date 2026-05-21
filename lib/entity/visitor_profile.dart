import 'dart:typed_data';

import '../utils/AppDateTime.dart';

class Visitor {
  String? id;
  String? titleName;
  String? fullName;
  String? cardId;
  String? signatureFilename;
  Uint8List? signatureData;
  DateTime? dateTime;

  Visitor({
    this.id,
    this.titleName,
    this.fullName,
    this.cardId,
    this.signatureFilename,
    this.signatureData,
    this.dateTime,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['ID'] ?? null,
      titleName: json['TitleName'] ?? null,
      fullName: json['FullName'] ?? null,
      cardId: json['Card_Id'] ?? null,
      signatureFilename: json['Signature'] ?? null,
      dateTime: (json['DateTime'] != null && json['DateTime'].toString().isNotEmpty)? (DateTime.tryParse(json['DateTime'].toString())): AppDateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'TitleName': titleName,
      'FullName': fullName,
      'Card_Id': cardId,
      'Signature': signatureFilename,
      'DateTime': dateTime.toString(),
    };
  }
}
