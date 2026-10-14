class DateFormatter {
  static const _monthsShort = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static const _monthsLong = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static String dateTime(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = _monthsShort[local.month];
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d $m $y, $h:$min WIB';
  }

  static String date(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = _monthsLong[local.month];
    final y = local.year;
    return '$d $m $y';
  }

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
    final d = local.day.toString().padLeft(2, '0');
    final m = _monthsShort[local.month];
    final y = local.year;
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');

    final str = dateOrString.toString();
    if (str.contains('T') || str.contains(':')) {
      return '$d $m $y, $h:$min WIB';
    }
    return '$d $m $y';
  }
}

