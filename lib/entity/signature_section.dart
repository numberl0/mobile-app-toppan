import 'dart:typed_data';

class SignatureSection {
  bool status;
  Uint8List? filePath;
  String? fileName;
  DateTime? dateTime;
  String? by;
  String label;

  SignatureSection({
    required this.status,
    this.filePath,
    this.fileName,
    this.dateTime,
    this.by,
    required this.label,
  });

  SignatureSection copy() => SignatureSection(
    status: status,
    filePath: filePath,
    fileName: fileName,
    dateTime: dateTime,
    by: by,
    label: label,
  );
}