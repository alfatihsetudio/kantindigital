<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\QrisSetting;
use Illuminate\Http\Request;

class QrisSettingController extends Controller
{
    public function show()
    {
        $setting = QrisSetting::firstOrCreate([], [
            'merchant_name' => 'KANTIN DIGITAL',
            'merchant_city' => 'SERANG',
            'whatsapp_number' => '087771262100',
            'base_payload' => '00020101021126610014COM.GO-JEK.WWW01189360091439141276340210G9141276340303UMI51440014ID.CO.QRIS.WWW0215ID10265440704890303UMI5204829953033605802ID5914KANTIN DIGITAL6006SERANG61054217162070703A0163044CD7',
            'is_active' => true,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => $setting,
        ]);
    }

    public function update(Request $request)
    {
        $request->validate([
            'merchant_name' => ['required', 'string', 'max:255'],
            'merchant_city' => ['required', 'string', 'max:255'],
            'whatsapp_number' => ['nullable', 'string', 'max:20'],
            'base_payload' => ['required', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $setting = QrisSetting::firstOrCreate([], [
            'merchant_name' => 'KANTIN DIGITAL',
            'merchant_city' => 'SERANG',
            'whatsapp_number' => '087771262100',
            'base_payload' => '',
            'is_active' => true,
        ]);

        $setting->update([
            'merchant_name' => $request->merchant_name,
            'merchant_city' => $request->merchant_city,
            'whatsapp_number' => $request->whatsapp_number,
            'base_payload' => trim($request->base_payload),
            'is_active' => $request->has('is_active') ? $request->boolean('is_active') : true,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Pengaturan QRIS berhasil disimpan',
            'data' => $setting,
        ]);
    }
}
