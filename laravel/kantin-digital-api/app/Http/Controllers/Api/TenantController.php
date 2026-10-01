<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TenantController extends Controller
{
    /**
     * Info tenant dari subdomain aktif (dipanggil Flutter saat startup)
     */
    public function info(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;

        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data' => [
                'id' => $tenant->id,
                'subdomain' => $tenant->subdomain,
                'name' => $tenant->name,
                'logo_url' => $tenant->logo_url,
                'primary_color' => $tenant->primary_color,
                'address' => $tenant->address,
                'phone' => $tenant->phone,
                'whatsapp' => $tenant->whatsapp,
                'plan' => $tenant->plan,
                'is_active' => $tenant->is_active,
            ],
        ]);
    }

    /**
     * Update profil tenant (nama kantin, logo, warna, whatsapp, dsb.)
     */
    public function update(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;

        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan',
            ], 404);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'primary_color' => 'nullable|string',
            'logo_url' => 'nullable|string',
            'logo' => 'nullable|image|max:2048',
            'logo_base64' => 'nullable|string',
            'address' => 'nullable|string',
            'phone' => 'nullable|string',
            'whatsapp' => 'nullable|string',
        ]);

        $data = $request->only(['name', 'logo_url', 'primary_color', 'address', 'phone', 'whatsapp']);

        if ($request->hasFile('logo')) {
            // Handle upload file multipart dari Flutter, lalu kompres sebelum disimpan.
            $file = $request->file('logo');
            $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
            $logoUrl = $this->storeCompressedLogo(
                $tenant,
                file_get_contents($file->getRealPath()),
                $extension
            );

            if ($logoUrl) {
                $data['logo_url'] = $logoUrl;
            }
        } elseif ($request->filled('logo_base64')) {
            // Backward compatible untuk client lama yang masih mengirim Base64.
            $base64String = $request->input('logo_base64');
            $extension = 'jpg';
            if (preg_match('/^data:image\/(\w+);base64,/', $base64String, $matches)) {
                $extension = strtolower($matches[1]);
                $base64String = substr($base64String, strpos($base64String, ',') + 1);
            }

            $binaryData = base64_decode($base64String);
            if ($binaryData !== false) {
                $logoUrl = $this->storeCompressedLogo($tenant, $binaryData, $extension);
                if ($logoUrl) {
                    $data['logo_url'] = $logoUrl;
                }
            }
        }

        $tenant->update($data);

        return response()->json([
            'status' => true,
            'message' => 'Profil kantin berhasil diperbarui',
            'data' => $tenant,
        ]);
    }

    private function storeCompressedLogo(Tenant $tenant, string $binaryData, string $extension): ?string
    {
        $extension = strtolower($extension);
        if ($extension === 'jpeg') {
            $extension = 'jpg';
        }

        $extension = in_array($extension, ['jpg', 'png'], true) ? $extension : 'jpg';
        $directory = public_path('uploads/logos');

        if (! is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        $filename = 'logo_'.$tenant->id.'_'.time().'.'.$extension;
        $targetPath = $directory.DIRECTORY_SEPARATOR.$filename;

        if (! extension_loaded('gd') || ! function_exists('imagecreatefromstring')) {
            file_put_contents($targetPath, $binaryData);

            return url('uploads/logos/'.$filename);
        }

        $src = @imagecreatefromstring($binaryData);
        if (! $src) {
            return null;
        }

        $width = imagesx($src);
        $height = imagesy($src);
        $maxDim = 400;

        if ($width > $maxDim || $height > $maxDim) {
            $ratio = min($maxDim / $width, $maxDim / $height);
            $newWidth = max(1, (int) round($width * $ratio));
            $newHeight = max(1, (int) round($height * $ratio));
        } else {
            $newWidth = $width;
            $newHeight = $height;
        }

        $dst = imagecreatetruecolor($newWidth, $newHeight);
        if ($extension === 'png') {
            imagealphablending($dst, false);
            imagesavealpha($dst, true);
        }

        imagecopyresampled($dst, $src, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);

        if ($extension === 'png') {
            imagepng($dst, $targetPath, 8);
        } else {
            imagejpeg($dst, $targetPath, 82);
        }

        imagedestroy($dst);
        imagedestroy($src);

        return url('uploads/logos/'.$filename);
    }
}
