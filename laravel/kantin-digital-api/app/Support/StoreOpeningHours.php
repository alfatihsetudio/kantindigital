<?php

namespace App\Support;

use Carbon\CarbonInterface;

class StoreOpeningHours
{
    private const DAY_ALIASES = [
        'senin' => 1, 'sn' => 1, 'mon' => 1, 'monday' => 1,
        'selasa' => 2, 'sl' => 2, 'tue' => 2, 'tues' => 2, 'tuesday' => 2,
        'rabu' => 3, 'rb' => 3, 'wed' => 3, 'wednesday' => 3,
        'kamis' => 4, 'km' => 4, 'thu' => 4, 'thur' => 4, 'thurs' => 4, 'thursday' => 4,
        'jumat' => 5, 'jum' => 5, "jum'at" => 5, 'fri' => 5, 'friday' => 5,
        'sabtu' => 6, 'sabt' => 6, 'sat' => 6, 'saturday' => 6,
        'minggu' => 7, 'min' => 7, 'sun' => 7, 'sunday' => 7,
    ];

    public static function isValid(?string $value): bool
    {
        return $value !== null && self::parse($value) !== null;
    }

    public static function isOpen(?string $value, ?CarbonInterface $at = null): bool
    {
        $schedule = self::parse($value ?? '');
        if ($schedule === null) {
            return false;
        }

        $localTime = ($at ? \Carbon\Carbon::instance($at) : now('Asia/Jakarta'))
            ->setTimezone('Asia/Jakarta');
        $weekday = (int) $localTime->dayOfWeekIso;
        $minutes = ((int) $localTime->hour * 60) + (int) $localTime->minute;
        $interval = $schedule[$weekday] ?? null;
        if ($interval === null) {
            return false;
        }

        [$start, $end] = $interval;
        if ($start < $end) {
            return $minutes >= $start && $minutes < $end;
        }
        if ($start > $end) {
            return $minutes >= $start || $minutes < $end;
        }
        return false;
    }

    public static function isTodayClosed(?string $value, ?CarbonInterface $at = null): bool
    {
        $schedule = self::parse($value ?? '');
        if ($schedule === null) {
            return false;
        }

        $localTime = ($at ? \Carbon\Carbon::instance($at) : now('Asia/Jakarta'))
            ->setTimezone('Asia/Jakarta');
        $weekday = (int) $localTime->dayOfWeekIso;
        return ($schedule[$weekday] ?? null) === null;
    }

    public static function wasOpenedDuringCurrentWindow(
        ?string $value,
        ?string $openedAt,
        ?CarbonInterface $at = null
    ): bool {
        if ($openedAt === null) {
            return false;
        }

        $schedule = self::parse($value ?? '');
        if ($schedule === null) {
            return false;
        }

        $localTime = ($at ? \Carbon\Carbon::instance($at) : now('Asia/Jakarta'))
            ->setTimezone('Asia/Jakarta');
        $openedTime = \Carbon\Carbon::parse($openedAt, 'UTC')
            ->setTimezone('Asia/Jakarta');
        $weekday = (int) $localTime->dayOfWeekIso;
        $minutes = ((int) $localTime->hour * 60) + (int) $localTime->minute;
        $interval = $schedule[$weekday] ?? null;
        $windowStart = null;

        if ($interval !== null) {
            [$start, $end] = $interval;
            if ($start < $end && $minutes >= $start && $minutes < $end) {
                $windowStart = $localTime->copy()->startOfDay()->addMinutes($start);
            } elseif ($start > $end && $minutes >= $start) {
                $windowStart = $localTime->copy()->startOfDay()->addMinutes($start);
            }
        }

        if ($windowStart === null) {
            $previousWeekday = $weekday === 1 ? 7 : $weekday - 1;
            $previousInterval = $schedule[$previousWeekday] ?? null;
            if ($previousInterval !== null) {
                [$start, $end] = $previousInterval;
                if ($start > $end && $minutes < $end) {
                    $windowStart = $localTime->copy()->startOfDay()->subDay()->addMinutes($start);
                }
            }
        }

        return $windowStart !== null
            && $openedTime->greaterThanOrEqualTo($windowStart)
            && $openedTime->lessThanOrEqualTo($localTime);
    }

    private static function parse(string $value): ?array
    {
        $normalized = mb_strtolower(trim($value));
        if ($normalized === '') {
            return null;
        }

        // 1. Normalisasi waktu bertitik (contoh: 08.00 -> 08:00)
        $normalized = preg_replace('/(\b\d{1,2})\.(\d{2}\b)/', '$1:$2', $normalized);

        // 2. Normalisasi kata penghubung (s/d, sd, sampai, hingga -> -)
        $normalized = preg_replace('/\b(s\/d|sd|sampai|hingga)\b/u', '-', $normalized);

        // 3. Normalisasi hari ini libur / tutup
        $jakartaDays = [1 => 'senin', 2 => 'selasa', 3 => 'rabu', 4 => 'kamis', 5 => 'jumat', 6 => 'sabtu', 7 => 'minggu'];
        $todayName = $jakartaDays[(int) now('Asia/Jakarta')->dayOfWeekIso];
        $normalized = preg_replace('/\b(hari ini libur|libur hari ini|tutup hari ini|hari ini tutup)\b/u', "{$todayName} tutup", $normalized);

        // 4. Normalisasi kata libur/off/closed -> tutup
        $normalized = preg_replace('/\b(libur|off|closed)\b/u', 'tutup', $normalized);

        // 5. Hapus kata "hari" sebelum nama hari
        $normalized = preg_replace('/\bhari\s+(senin|selasa|rabu|kamis|jumat|sabtu|minggu)\b/u', '$1', $normalized);

        // 6. Ganti "kecuali" -> ";"
        $normalized = preg_replace('/\bkecuali\b/u', ';', $normalized);

        // 7. Ubah koma SETELAH rentang jam yang memisahkan klausa hari tutup menjadi titik koma
        // Contoh: "08:00 - 22:00, minggu tutup" -> "08:00 - 22:00; minggu tutup"
        $normalized = preg_replace('/(?<=\d{2})\s*,\s*(?=[^;\n]*tutup)/u', '; ', $normalized);

        // Kasus spesial jika seluruh nilai adalah "tutup"
        if ($normalized === 'tutup' || $normalized === 'setiap hari tutup') {
            return array_fill(1, 7, null);
        }

        // Kasus rentang jam setiap hari (misal: "08:00 - 22:00" atau "setiap hari, 08:00 - 22:00")
        $dailyRange = self::parseRange($normalized);
        if ($dailyRange !== null) {
            return array_fill(1, 7, $dailyRange);
        }

        $schedule = [];
        $defaultRange = null;
        $clauses = preg_split('/[;\n]+/', $normalized) ?: [];

        foreach ($clauses as $clause) {
            $clause = trim($clause);
            if ($clause === '') {
                continue;
            }

            // Cek apakah klausa ini adalah rentang jam tanpa nama hari (misal "08:00 - 22:00")
            $standaloneRange = self::parseRange($clause);
            if ($standaloneRange !== null) {
                $defaultRange = $standaloneRange;
                continue;
            }

            if (! preg_match('/^(.+?)\s*[,:]?\s+(tutup|(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2}))$/u', $clause, $matches)) {
                return null;
            }

            $days = self::parseDays($matches[1]);
            if ($days === null || $days === []) {
                return null;
            }
            $isClosed = $matches[2] === 'tutup';
            $range = $isClosed ? null : self::parseRange($matches[3].'-'.$matches[4]);
            if (! $isClosed && $range === null) {
                return null;
            }

            if (! $isClosed && $defaultRange === null) {
                $defaultRange = $range;
            }

            foreach ($days as $day) {
                if (array_key_exists($day, $schedule)) {
                    return null;
                }
                $schedule[$day] = $range;
            }
        }

        if (empty($schedule) && $defaultRange === null) {
            return null;
        }

        // Jika hanya hari tertentu yang disebutkan (misal hanya hari libur yang diatur),
        // isi hari-hari lainnya dengan defaultRange (atau 08:00 - 22:00)
        $fallback = $defaultRange ?? [480, 1320]; // 08:00 - 22:00
        for ($day = 1; $day <= 7; $day++) {
            if (! array_key_exists($day, $schedule)) {
                $schedule[$day] = $fallback;
            }
        }

        return $schedule;
    }

    private static function parseDays(string $value): ?array
    {
        $expression = trim($value);
        if (in_array($expression, ['setiap hari', 'every day'], true)) {
            return [1, 2, 3, 4, 5, 6, 7];
        }

        $expression = str_replace([' dan ', '&'], ',', $expression);
        $rawSegments = explode(',', $expression);
        $segments = [];
        foreach ($rawSegments as $seg) {
            $seg = trim($seg);
            if ($seg !== '') {
                $segments[] = $seg;
            }
        }
        if (empty($segments)) {
            return null;
        }

        $days = [];
        foreach ($segments as $seg) {
            $parts = array_values(array_filter(array_map('trim', explode('-', $seg)), fn ($p) => $p !== ''));
            if (count($parts) > 2 || empty($parts)) {
                return null;
            }
            $start = self::DAY_ALIASES[$parts[0]] ?? null;
            $end = self::DAY_ALIASES[$parts[count($parts) - 1]] ?? null;
            if ($start === null || $end === null) {
                $subwords = array_values(array_filter(explode(' ', $seg), fn ($w) => $w !== ''));
                if (count($subwords) > 1) {
                    $allValid = true;
                    $subDays = [];
                    foreach ($subwords as $w) {
                        if (! isset(self::DAY_ALIASES[$w])) {
                            $allValid = false;
                            break;
                        }
                        $subDays[] = self::DAY_ALIASES[$w];
                    }
                    if ($allValid) {
                        foreach ($subDays as $sd) {
                            $days[] = $sd;
                        }
                        continue;
                    }
                }
                return null;
            }

            $day = $start;
            while (true) {
                $days[] = $day;
                if ($day === $end) {
                    break;
                }
                $day = $day === 7 ? 1 : $day + 1;
            }
        }

        return empty($days) ? null : array_values(array_unique($days));
    }

    private static function parseRange(string $value): ?array
    {
        $cleaned = trim(preg_replace('/^(setiap hari|every day)[,:\s]*/u', '', trim($value)));
        if (! preg_match('/^(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})$/', $cleaned, $matches)) {
            return null;
        }

        $startHour = (int) $matches[1];
        $startMinute = (int) $matches[2];
        $endHour = (int) $matches[3];
        $endMinute = (int) $matches[4];
        if ($startHour > 23 || $endHour > 23 || $startMinute > 59 || $endMinute > 59) {
            return null;
        }

        return [($startHour * 60) + $startMinute, ($endHour * 60) + $endMinute];
    }
}
