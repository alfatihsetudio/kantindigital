class StoreClosedStatus {
  final String title;
  final String message;
  final String statusBadge;
  final bool isPoliteApology;
  final String? contactPhone;

  const StoreClosedStatus({
    required this.title,
    required this.message,
    this.statusBadge = 'Katalog Menu',
    this.isPoliteApology = false,
    this.contactPhone,
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

  /// Ekstrak set hari yang aktif buka (1: Senin .. 7: Minggu) dari string jadwal
  static Set<int> getOpenDays(String value) {
    final schedule = _parse(value);
    if (schedule == null) return {1, 2, 3, 4, 5, 6, 7};
    final openDays = <int>{};
    for (var day = 1; day <= 7; day++) {
      if (schedule[day] != null) {
        openDays.add(day);
      }
    }
    return openDays;
  }

  /// Format jadwal fleksibel dari set hari buka dan jam buka-tutup
  static String formatScheduleFromOpenDays({
    required Set<int> openDays,
    required String openTime,
    required String closeTime,
  }) {
    if (openDays.isEmpty) {
      return 'Setiap hari Tutup';
    }
    if (openDays.length == 7) {
      return 'Setiap hari, $openTime - $closeTime';
    }

    const dayNames = <int, String>{
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };

    final offDays = {1, 2, 3, 4, 5, 6, 7}.difference(openDays);

    // Kasus 1 hari libur
    if (offDays.length == 1) {
      final off = offDays.first;
      switch (off) {
        case 7:
          return 'Senin - Sabtu, $openTime - $closeTime; Minggu Tutup';
        case 1:
          return 'Selasa - Minggu, $openTime - $closeTime; Senin Tutup';
        case 5:
          return 'Sabtu - Kamis, $openTime - $closeTime; Jumat Tutup';
        default:
          return '${_formatDayList(openDays, dayNames)}, $openTime - $closeTime; ${dayNames[off]} Tutup';
      }
    }

    // Kasus akhir pekan (Sabtu & Minggu libur)
    if (offDays.length == 2 && offDays.contains(6) && offDays.contains(7)) {
      return 'Senin - Jumat, $openTime - $closeTime; Sabtu - Minggu Tutup';
    }

    // Format umum untuk kombinasi hari bebas
    final openText = _formatDayList(openDays, dayNames);
    final offText = _formatDayList(offDays, dayNames);
    return '$openText, $openTime - $closeTime; $offText Tutup';
  }

  static String _formatDayList(Set<int> days, Map<int, String> dayNames) {
    if (days.isEmpty) return '';
    if (days.length == 7) return 'Setiap hari';
    final sorted = days.toList()..sort();
    return sorted.map((d) => dayNames[d]!).join(', ');
  }

  /// Menghasilkan status dan pesan penjelasan yang sopan & kontekstual saat toko belum buka/tutup
  static StoreClosedStatus getClosedStatus({
    required String openingHours,
    required bool scheduleOpen,
    required bool staffHasOpened,
    required DateTime utcInstant,
    String? contactPhone,
  }) {
    final hoursText = openingHours.trim().isNotEmpty
        ? openingHours.trim()
        : 'Sesuai jadwal operasional';

    // 1. Sedang dalam jam operasional tapi toko belum dibuka oleh pengelola
    //    (Permintaan maaf halus karena ada sesuatu hal / kendala)
    if (scheduleOpen && !staffHasOpened) {
      final contactText = (contactPhone != null && contactPhone.trim().isNotEmpty)
          ? ' Layanan Konsumen: ${contactPhone.trim()}.'
          : '';
      return StoreClosedStatus(
        title: 'Mohon Maaf, Toko Sedang Tutup',
        statusBadge: 'Katalog Menu',
        isPoliteApology: true,
        contactPhone: contactPhone,
        message:
            'Mohon Maaf karena suatu hal, saat ini kami sedang Tutup. Jam Operasional: $hoursText.$contactText Anda tetap dapat melihat menu & menambah ke keranjang terlebih dahulu.',
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
    var normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    // 1. Normalisasi waktu bertitik (contoh: 08.00 -> 08:00)
    normalized = normalized.replaceAllMapped(
      RegExp(r'(\b\d{1,2})\.(\d{2}\b)'),
      (m) => '${m[1]}:${m[2]}',
    );

    // 2. Normalisasi kata penghubung (s/d, sd, sampai, hingga -> -)
    normalized = normalized.replaceAll(
      RegExp(r'\b(s/d|sd|sampai|hingga)\b'),
      '-',
    );

    // 3. Normalisasi hari ini libur / tutup
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    const dayNames = <int, String>{
      1: 'senin',
      2: 'selasa',
      3: 'rabu',
      4: 'kamis',
      5: 'jumat',
      6: 'sabtu',
      7: 'minggu',
    };
    final todayName = dayNames[nowWib.weekday] ?? 'senin';
    normalized = normalized.replaceAll(
      RegExp(r'\b(hari ini libur|libur hari ini|tutup hari ini|hari ini tutup)\b'),
      '$todayName tutup',
    );

    // 4. Normalisasi kata libur/off/closed -> tutup
    normalized = normalized.replaceAll(RegExp(r'\b(libur|off|closed)\b'), 'tutup');

    // 5. Hapus kata "hari" sebelum nama hari
    normalized = normalized.replaceAllMapped(
      RegExp(r'\bhari\s+(senin|selasa|rabu|kamis|jumat|sabtu|minggu)\b'),
      (m) => m[1]!,
    );

    // 6. Ganti "kecuali" -> ";"
    normalized = normalized.replaceAll(RegExp(r'\bkecuali\b'), ';');

    // 7. Ubah koma SETELAH rentang jam yang memisahkan klausa hari tutup menjadi titik koma
    normalized = normalized.replaceAllMapped(
      RegExp(r'(?<=\d{2})\s*,\s*(?=[^;\n]*tutup)'),
      (_) => '; ',
    );

    // Kasus spesial jika seluruh nilai adalah "tutup"
    if (normalized == 'tutup' || normalized == 'setiap hari tutup') {
      return {for (var day = 1; day <= 7; day++) day: null};
    }

    // Kasus rentang jam setiap hari (misal: "08:00 - 22:00" atau "setiap hari, 08:00 - 22:00")
    final dailyRange = _parseRange(normalized);
    if (dailyRange != null) {
      return {for (var day = 1; day <= 7; day++) day: dailyRange};
    }

    final schedule = <int, (int, int)?>{};
    (int, int)? defaultRange;
    final clauses = normalized
        .split(RegExp(r'[;\n]+'))
        .map((clause) => clause.trim())
        .where((clause) => clause.isNotEmpty);
    if (clauses.isEmpty) return null;

    for (final clause in clauses) {
      final standaloneRange = _parseRange(clause);
      if (standaloneRange != null) {
        defaultRange = standaloneRange;
        continue;
      }

      final match = RegExp(
        r'^(.+?)\s*[,:]?\s+(tutup|(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2}))$',
      ).firstMatch(clause);
      if (match == null) return null;

      final days = _parseDays(match.group(1)!);
      if (days == null || days.isEmpty) return null;
      final isClosed = match.group(2) == 'tutup';
      final range = isClosed
          ? null
          : _parseRange('${match.group(3)}-${match.group(4)}');
      if (!isClosed && range == null) return null;

      if (!isClosed && defaultRange == null) {
        defaultRange = range;
      }

      for (final day in days) {
        if (schedule.containsKey(day)) return null;
        schedule[day] = range;
      }
    }

    if (schedule.isEmpty && defaultRange == null) return null;

    // Jika hanya hari tertentu yang disebutkan (misal hanya hari libur yang diatur),
    // isi hari-hari lainnya dengan defaultRange (atau 08:00 - 22:00)
    final fallback = defaultRange ?? const (480, 1320); // 08:00 - 22:00
    for (var day = 1; day <= 7; day++) {
      if (!schedule.containsKey(day)) {
        schedule[day] = fallback;
      }
    }

    return schedule;
  }

  static Set<int>? _parseDays(String value) {
    final expression = value.trim();
    if (expression == 'setiap hari' || expression == 'every day') {
      return {1, 2, 3, 4, 5, 6, 7};
    }

    final cleaned = expression
        .replaceAll(' dan ', ',')
        .replaceAll('&', ',');
    final segments = cleaned
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) return null;

    final days = <int>{};
    for (final seg in segments) {
      final parts = seg.split('-').map((part) => part.trim()).toList();
      if (parts.length > 2 || parts.isEmpty) return null;
      final start = _dayAliases[parts.first];
      final end = _dayAliases[parts.last];
      if (start == null || end == null) {
        final subwords = seg.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (subwords.length > 1) {
          var allValid = true;
          final subDays = <int>[];
          for (final w in subwords) {
            final alias = _dayAliases[w];
            if (alias == null) {
              allValid = false;
              break;
            }
            subDays.add(alias);
          }
          if (allValid) {
            days.addAll(subDays);
            continue;
          }
        }
        return null;
      }

      var day = start;
      while (true) {
        days.add(day);
        if (day == end) break;
        day = day == 7 ? 1 : day + 1;
      }
    }
    return days.isEmpty ? null : days;
  }

  static (int, int)? _parseRange(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'^(setiap hari|every day)[,:\s]*'), '');
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})$',
    ).firstMatch(cleaned);
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
