<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\QrisSetting;
use Illuminate\Http\Request;

class QrisSettingController extends Controller
{
    public function show()
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        $defaultMerchant = $tenant ? $tenant->name : 'Say Coffee';
        $defaultCity = 'Kab. Serang';
        $defaultWa = $tenant ? ($tenant->whatsapp ?? '087771262100') : '087771262100';

        $setting = QrisSetting::firstOrCreate([], [
            'merchant_name' => $defaultMerchant,
            'merchant_city' => $defaultCity,
            'whatsapp_number' => $defaultWa,
            'base_payload' => '00020101021126570011ID.DANA.WWW011893600915303557205402090355720540303UMI51440014ID.CO.QRIS.WWW0215ID10266058542500303UMI5204581253033605802ID5910Say Coffee6011Kab. Serang6105421176304AB0C',
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

        $tenant = app()->has('tenant') ? app('tenant') : null;
        $defaultMerchant = $tenant ? $tenant->name : 'Say Coffee';
        $defaultCity = 'Kab. Serang';
        $defaultWa = $tenant ? ($tenant->whatsapp ?? '087771262100') : '087771262100';

        $setting = QrisSetting::firstOrCreate([], [
            'merchant_name' => $defaultMerchant,
            'merchant_city' => $defaultCity,
            'whatsapp_number' => $defaultWa,
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
