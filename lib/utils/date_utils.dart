import 'package:intl/intl.dart';

DateTime? parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '')?.toLocal();

String formatDate(DateTime? dt) => dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '-';

String formatTime(DateTime? dt) => dt != null ? DateFormat('HH:mm').format(dt) : '-';