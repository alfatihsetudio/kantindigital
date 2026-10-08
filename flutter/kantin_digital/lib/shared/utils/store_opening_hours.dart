class StoreClosedStatus {
  final String title;
  final String message;
  final String statusBadge;
  final bool isPoliteApology;

  const StoreClosedStatus({
    required this.title,
    required this.message,
    this.statusBadge = 'Katalog Menu',
    this.isPoliteApology = false,
  });
}

class StoreOpeningHours {
  static const _dayAliases = <String, int>{
    'senin': 1,
    'sn': 1,
    'mon': 1,
    'monday': 1,
    'selasa': 2,
    'sl': 2,
    'tue': 2,
    'tues': 2,
    'tuesday': 2,
    'rabu': 3,
    'rb': 3,
    'wed': 3,
    'wednesday': 3,
    'kamis': 4,
    'km': 4,
    'thu': 4,
    'thur': 4,
    'thurs': 4,
    'thursday': 4,
    'jumat': 5,
    'jum': 5,
    'jum\'at': 5,
    'fri': 5,
    'friday': 5,
    'sabtu': 6,
    'sabt': 6,
    'sat': 6,
    'saturday': 6,
    'minggu': 7,
    'min': 7,
    'sun': 7,
    'sunday': 7,
  };

  static bool isValid(String value) => _parse(value) != null;

  /// [utcInstant] must be a UTC instant; store hours are evaluated in WIB.
  static bool? isOpenAt(String value, DateTime utcInstant) {
    final schedule = _parse(value);
    if (schedule == null) return null;

    final localTime = utcInstant.toUtc().add(const Duration(hours: 7));
    final weekday = localTime.weekday;
    final minutes = localTime.hour * 60 + localTime.minute;
    final interval = schedule[weekday];
    if (interval == null) return false;

    final (start, end) = interval;
    if (start < end) return minutes >= start && minutes < end;
    if (start > end) return minutes >= start || minutes < end;
    return false;
  }

  /// Cek apakah hari ini toko libur operasional
  static bool isTodayOffDay(String value, DateTime utcInstant) {
    final schedule = _parse(value);
    if (schedule == null) return false;

    final localTime = utcInstant.toUtc().add(const Duration(hours: 7));
    final weekday = localTime.weekday;
    return schedule[weekday] == null;
  }

  /// Ambil rentang jam buka & tutup hari ini (menit dari tengah malam WIB)
  static (int, int)? getTodayInterval(String value, DateTime utcInstant) {
    final schedule = _parse(value);
    if (schedule == null) return null;

    final localTime = utcInstant.toUtc().add(const Duration(hours: 7));
    return schedule[localTime.weekday];
  }

  /// Cek apakah hari ini buka, tapi saat ini masih sebelum jam buka
  static bool isBeforeOpeningToday(String value, DateTime utcInstant) {
    final interval = getTodayInterval(value, utcInstant);
    if (interval == null) return false;

    final localTime = utcInstant.toUtc().add(const Duration(hours: 7));
    final minutes = localTime.hour * 60 + localTime.minute;
    final (start, end) = interval;
    if (start < end) {
      return minutes < start;
    }
    return false;
  }

  /// Cek apakah hari ini buka, tapi saat ini sudah melewati jam tutup
  static bool isAfterClosingToday(String value, DateTime utcInstant) {
    final interval = getTodayInterval(value, utcInstant);
    if (interval == null) return false;

    final localTime = utcInstant.toUtc().add(const Duration(hours: 7));
    final minutes = localTime.hour * 60 + localTime.minute;
    final (start, end) = interval;
    if (start < end) {
      return minutes >= end;
    }
    return false;
  }

  /// Format menit ke string HH:mm (contoh: 600 -> "10:00")
  static String formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Menghasilkan status dan pesan penjelasan yang sopan & kontekstual saat toko belum buka/tutup
  static StoreClosedStatus getClosedStatus({
    required String openingHours,
    required bool scheduleOpen,
    required bool staffHasOpened,
    required DateTime utcInstant,
  }) {
    final hoursText = openingHours.trim().isNotEmpty
        ? openingHours.trim()
        : 'Sesuai jadwal operasional';

    // 1. Sedang dalam jam operasional tapi toko belum dibuka oleh pengelola
    //    (Permintaan maaf halus karena ada sesuatu hal / kendala)
    if (scheduleOpen && !staffHasOpened) {
      return StoreClosedStatus(
        title: 'Mohon Maaf, Toko Belum Buka',
        statusBadge: 'Katalog Menu',
        isPoliteApology: true,
        message:
            'Mohon maaf yang sebesar-besarnya atas ketidaknyamanannya. Saat ini kami belum dapat melayani pesanan sebagaimana mestinya karena ada kendala operasional yang sedang kami tangani. Jadwal operasional: $hoursText. Kami berupaya untuk segera buka kembali. Anda tetap dapat melihat menu & menambah ke keranjang terlebih dahulu.',
      );
    }

    // 2. Hari ini adalah hari libur toko
    if (isTodayOffDay(openingHours, utcInstant)) {
      return StoreClosedStatus(
        title: 'Toko Sedang Libur Hari Ini',
        statusBadge: 'Katalog Menu',
        message:
            'Hari ini toko kami sedang libur operasional (Jadwal: $hoursText). Anda tetap dapat melihat katalog menu & menyimpan ke keranjang, dan dapat checkout saat toko beroperasi kembali.',
      );
    }

    // 3. Hari operasional, namun saat ini masih sebelum jam buka
    if (isBeforeOpeningToday(openingHours, utcInstant)) {
      final interval = getTodayInterval(openingHours, utcInstant);
      final openTime = interval != null ? formatMinutes(interval.$1) : null;
      final openText = openTime != null ? 'pukul $openTime WIB' : 'sebentar lagi';
      return StoreClosedStatus(
        title: 'Toko Belum Buka',
        statusBadge: 'Katalog Menu',
        message:
            'Toko kami buka $openText (Jadwal operasional: $hoursText). Anda tetap dapat melihat katalog menu & menambah ke keranjang, dan dapat checkout saat toko sudah buka.',
      );
    }

    // 4. Hari operasional, namun sudah lewat jam tutup
    if (isAfterClosingToday(openingHours, utcInstant)) {
      return StoreClosedStatus(
        title: 'Toko Sudah Tutup',
        statusBadge: 'Katalog Menu',
        message:
            'Toko sudah tutup untuk hari ini. Buka kembali sesuai jadwal: $hoursText. Anda tetap dapat melihat menu & menambah ke keranjang untuk pesanan berikutnya.',
      );
    }

    // 5. Fallback di luar jam operasional
    return StoreClosedStatus(
      title: 'Toko Sedang Tutup',
      statusBadge: 'Katalog Menu',
      message:
          'Toko sedang di luar jam operasional. Buka: $hoursText. Anda tetap dapat melihat menu & menambah ke keranjang, namun belum bisa checkout hingga toko buka.',
    );
  }

  static Map<int, (int, int)?>? _parse(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final dailyRange = _parseRange(normalized);
    if (dailyRange != null) {
      return {for (var day = 1; day <= 7; day++) day: dailyRange};
    }

    final schedule = <int, (int, int)?>{};
    final clauses = normalized
        .split(RegExp(r'[;\n]+'))
        .map((clause) => clause.replaceAll(',', ' ').trim())
        .where((clause) => clause.isNotEmpty);
    if (clauses.isEmpty) return null;

    for (final clause in clauses) {
      final match = RegExp(
        r'^(.+?)\s+(tutup|closed|(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2}))$',
      ).firstMatch(clause);
      if (match == null) return null;

      final days = _parseDays(match.group(1)!);
      if (days == null || days.isEmpty) return null;
      final isClosed = match.group(2) == 'tutup' || match.group(2) == 'closed';
      final range = isClosed
          ? null
          : _parseRange('${match.group(3)}-${match.group(4)}');
      if (!isClosed && range == null) return null;

      for (final day in days) {
        if (schedule.containsKey(day)) return null;
        schedule[day] = range;
      }
    }
    return schedule;
  }

  static Set<int>? _parseDays(String value) {
    final expression = value.trim();
    if (expression == 'setiap hari' || expression == 'every day') {
      return {1, 2, 3, 4, 5, 6, 7};
    }

    final parts = expression.split('-').map((part) => part.trim()).toList();
    if (parts.length > 2) return null;
    final start = _dayAliases[parts.first];
    final end = _dayAliases[parts.last];
    if (start == null || end == null) return null;
    if (parts.length == 1) return {start};

    final days = <int>{};
    var day = start;
    while (true) {
      days.add(day);
      if (day == end) break;
      day = day == 7 ? 1 : day + 1;
    }
    return days;
  }

  static (int, int)? _parseRange(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})$',
    ).firstMatch(value.trim());
    if (match == null) return null;

    final startHour = int.parse(match.group(1)!);
    final startMinute = int.parse(match.group(2)!);
    final endHour = int.parse(match.group(3)!);
    final endMinute = int.parse(match.group(4)!);
    if (startHour > 23 || endHour > 23 || startMinute > 59 || endMinute > 59) {
      return null;
    }
    return (startHour * 60 + startMinute, endHour * 60 + endMinute);
  }
}
