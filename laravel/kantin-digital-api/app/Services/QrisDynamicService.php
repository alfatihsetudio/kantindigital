<?php

namespace App\Services;

class QrisDynamicService
{
    // Default base payload for Say Coffee (EMVCo QRIS format)
    protected string $defaultBasePayload = '00020101021126570011ID.DANA.WWW011893600915303557205402090355720540303UMI51440014ID.CO.QRIS.WWW0215ID10266058542500303UMI5204581253033605802ID5910Say Coffee6011Kab. Serang6105421176304AB0C';

    public function removeCrc(string $payload): string
    {
        $cleaned = trim($payload);
        $result = preg_replace('/6304[A-Fa-f0-9]{4}$/', '', $cleaned);
        return $result !== null ? $result : $cleaned;
    }

    public function removeExistingAmount(string $payload): string
    {
        $result = '';
        $len = strlen($payload);
        $i = 0;

        while ($i + 4 <= $len) {
            $tag = substr($payload, $i, 2);
            $valueLen = (int) substr($payload, $i + 2, 2);
            $segmentLen = 4 + $valueLen;

            if ($tag === '54') {
                $i += $segmentLen;
                continue;
            }

            $result .= substr($payload, $i, $segmentLen);
            $i += $segmentLen;
        }

        return $result;
    }

    public function injectAmount(string $payload, int $amount): string
    {
        $amountString = (string) $amount;
        $tag54 = '54' . str_pad((string) strlen($amountString), 2, '0', STR_PAD_LEFT) . $amountString;

        $payloadWithoutAmount = $this->removeExistingAmount($payload);

        $result = preg_replace('/5802ID/', $tag54 . '5802ID', $payloadWithoutAmount, 1);

        if ($result === null || strpos($result, '5802ID') === false) {
            throw new \RuntimeException('Payload QRIS tidak valid.');
        }

        return $result;
    }

    public function crc16(string $payload): string
    {
        $crc = 0xFFFF;
        $polynomial = 0x1021;

        for ($i = 0; $i < strlen($payload); $i++) {
            $crc ^= (ord($payload[$i]) << 8);
            for ($j = 0; $j < 8; $j++) {
                if ($crc & 0x8000) {
                    $crc = ($crc << 1) ^ $polynomial;
                } else {
                    $crc = ($crc << 1);
                }
                $crc &= 0xFFFF;
            }
        }

        return strtoupper(str_pad(dechex($crc), 4, '0', STR_PAD_LEFT));
    }

    public function generatePayload(?string $basePayload, int $amount): string
    {
        $base = !empty($basePayload) ? $basePayload : $this->defaultBasePayload;

        if ($amount < 1) {
            return $base;
        }

        $payloadWithoutCrc = $this->removeCrc($base);
        $payloadWithAmount = $this->injectAmount($payloadWithoutCrc, $amount);
        $crc = $this->crc16($payloadWithAmount . '6304');

        return $payloadWithAmount . '6304' . $crc;
    }
}
