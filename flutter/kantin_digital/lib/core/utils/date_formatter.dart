import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  static String dateTime(DateTime value) => _dateTime.format(value);
}

