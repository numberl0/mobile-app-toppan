import '../utils/date_utils.dart';

class DisplayText {
  String left;
  String center;
  String right;
  DisplayText({this.left = '', this.center = '', this.right = ''});
}

DisplayText buildVisitor(Map<String, dynamic> entry) {
  final inDate = parseDate(entry['datetime_in']);
  final outDate = parseDate(entry['datetime_out']);

  return DisplayText(
    left: 'วันที่: ${formatDate(inDate)}',
    center: 'เวลาเข้า: ${formatTime(inDate)}',
    right: 'เวลาออก: ${formatTime(outDate)}',
  );
}

DisplayText buildEmployee(Map<String, dynamic> entry) {
  final outDate = parseDate(entry['datetime_out']);
  final inDate = parseDate(entry['datetime_in']);

  switch (entry['objective_type']) {
    case 3:
      return DisplayText(
        left: 'วันที่: ${formatDate(outDate)}',
        center: 'เวลาเข้า: ${formatTime(outDate)}',
        right: 'เวลาออก: ${formatTime(inDate)}',
      );

    case 2:
      return DisplayText(
        left: 'วันที่: ${formatDate(outDate)}',
        center: 'เวลา: ${formatTime(outDate)}',
      );

    case 1:
      if (entry['out_only'] == 0) {
        return DisplayText(
          left: 'วันที่: ${formatDate(outDate)}',
          center: 'เวลาออก: ${formatTime(outDate)}',
          right: 'เวลาเข้า: ${formatTime(inDate)}',
        );
      }
      return DisplayText(
        left: 'วันที่: ${formatDate(outDate)}',
        center: 'เวลา: ${formatTime(outDate)}',
      );

    default:
      return DisplayText();
  }
}