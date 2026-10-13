import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _date = DateFormat('dd MMMM yyyy', 'id_ID');

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());
  static String date(DateTime value) => _date.format(value.toLocal());

  /// Format string tanggal ISO / datetime / timestamp menjadi format Indonesia yang ramah (contoh: "12 Okt 2026, 17:00 WIB")
  static String formatFriendly(dynamic dateOrString) {
    if (dateOrString == null) return '-';
    DateTime? dt;
    if (dateOrString is DateTime) {
      dt = dateOrString;
    } else if (dateOrString is String) {
      if (dateOrString.trim().isEmpty) return '-';
      dt = DateTime.tryParse(dateOrString.trim());
    }
    if (dt == null) return dateOrString.toString();

    final local = dt.toLocal();
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(local);
    final timeStr = DateFormat('HH:mm', 'id_ID').format(local);
    // Jika jam tidak 00:00 atau string aslinya berisi jam
    if (dateOrString.toString().contains('T') || dateOrString.toString().contains(':')) {
      return '$dateStr, $timeStr WIB';
    }
    return dateStr;
  }
}

