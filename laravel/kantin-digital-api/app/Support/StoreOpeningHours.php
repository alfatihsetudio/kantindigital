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

        $localTime = ($at ? \Carbon\Carbon::instance($at) : now())->setTimezone('Asia/Jakarta');
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

        $localTime = ($at ? \Carbon\Carbon::instance($at) : now())->setTimezone('Asia/Jakarta');
        $openedTime = \Carbon\Carbon::parse($openedAt)->setTimezone('Asia/Jakarta');
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

        $dailyRange = self::parseRange($normalized);
        if ($dailyRange !== null) {
            return array_fill(1, 7, $dailyRange);
        }

        $schedule = [];
        $clauses = preg_split('/[;\n]+/', $normalized) ?: [];
        foreach ($clauses as $clause) {
            $clause = trim(str_replace(',', ' ', $clause));
            if ($clause === '') {
                continue;
            }

            if (! preg_match('/^(.+?)\s+(tutup|closed|(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2}))$/u', $clause, $matches)) {
                return null;
            }

            $days = self::parseDays($matches[1]);
            if ($days === null || $days === []) {
                return null;
            }
            $isClosed = $matches[2] === 'tutup' || $matches[2] === 'closed';
            $range = $isClosed ? null : self::parseRange($matches[3].'-'.$matches[4]);
            if (! $isClosed && $range === null) {
                return null;
            }

            foreach ($days as $day) {
                if (array_key_exists($day, $schedule)) {
                    return null;
                }
                $schedule[$day] = $range;
            }
        }

        return $schedule === [] ? null : $schedule;
    }

    private static function parseDays(string $value): ?array
    {
        $expression = trim($value);
        if (in_array($expression, ['setiap hari', 'every day'], true)) {
            return [1, 2, 3, 4, 5, 6, 7];
        }

        $parts = array_map('trim', explode('-', $expression));
        if (count($parts) > 2) {
            return null;
        }
        $start = self::DAY_ALIASES[$parts[0]] ?? null;
        $end = self::DAY_ALIASES[$parts[count($parts) - 1]] ?? null;
        if ($start === null || $end === null) {
            return null;
        }
        if (count($parts) === 1) {
            return [$start];
        }

        $days = [];
        $day = $start;
        while (true) {
            $days[] = $day;
            if ($day === $end) {
                break;
            }
            $day = $day === 7 ? 1 : $day + 1;
        }
        return $days;
    }

    private static function parseRange(string $value): ?array
    {
        if (! preg_match('/^(\d{1,2}):(\d{2})\s*[-–]\s*(\d{1,2}):(\d{2})$/', trim($value), $matches)) {
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
