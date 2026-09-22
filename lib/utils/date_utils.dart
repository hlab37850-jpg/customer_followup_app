import 'package:intl/intl.dart';

String formatArabicDate(DateTime date) {
  return DateFormat('yyyy/MM/dd', 'ar').format(date);
}

String formatArabicDateTime(DateTime date) {
  return DateFormat('yyyy/MM/dd - HH:mm', 'ar').format(date);
}
