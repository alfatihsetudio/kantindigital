<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

class MenuController extends Controller
{
    public function index()
    {
        $menus = Menu::with('category')
            ->whereHas('category', function ($q) {
                $q->where('is_active', true);
            })
            ->get()
            ->map(function ($menu) {
                return [
                    'id' => $menu->id,
                    'code' => $menu->code,
                    'name' => $menu->name,
                    'description' => $menu->description,
                    'price' => $menu->price,
                    'category_id' => $menu->category_id,
                    'category_name' => optional($menu->category)->name ?? 'Tanpa Kategori',
                    'image_url' => $menu->image_url,
                    'is_available' => $menu->is_available,
                ];
            });

        return response()->json([
            'status' => true,
            'data' => $menus,
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'code' => 'nullable|string|max:50',
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'price' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'is_available' => 'sometimes|boolean',
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp|max:8192',
        ]);

        $data = $request->only([
            'code', 'name', 'category_id', 'price', 'description', 'is_available',
        ]);
        if ($request->hasFile('image')) {
            $data['image_url'] = $this->storeCompressedImage($request->file('image'));
        }

        $menu = Menu::create($data);

        return response()->json(['status' => true, 'message' => 'Created', 'data' => $menu]);
    }

    public function update(Request $request, $id)
    {
        $menu = Menu::find($id);
        if (! $menu) {
            return response()->json(['status' => false, 'message' => 'Not found'], 404);
        }

        $request->validate([
            'code' => 'nullable|string|max:50',
            'name' => 'sometimes|required|string|max:255',
            'category_id' => 'sometimes|required|exists:categories,id',
            'price' => 'sometimes|required|numeric|min:0',
            'description' => 'nullable|string',
            'is_available' => 'sometimes|boolean',
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp|max:8192',
        ]);

        $data = $request->only([
            'code', 'name', 'category_id', 'price', 'description', 'is_available',
        ]);
        if ($request->hasFile('image')) {
            $previousImage = $menu->image_url;
            $data['image_url'] = $this->storeCompressedImage($request->file('image'));
        } else {
            $previousImage = null;
        }

        $menu->update($data);
        $this->deleteStoredImage($previousImage);

        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $menu]);
    }

    public function destroy($id)
    {
        $menu = Menu::find($id);
        if (! $menu) {
            return response()->json(['status' => false, 'message' => 'Not found'], 404);
        }

        $imageUrl = $menu->image_url;
        $menu->delete();
        $this->deleteStoredImage($imageUrl);

        return response()->json(['status' => true, 'message' => 'Deleted']);
    }

    private function storeCompressedImage(UploadedFile $image): string
    {
        if (! extension_loaded('gd') || ! function_exists('imagecreatefromstring')) {
            throw new \RuntimeException('Kompresi gambar tidak tersedia di server.');
        }

        $source = imagecreatefromstring(file_get_contents($image->getRealPath()));
        if ($source === false) {
            abort(422, 'File gambar tidak dapat diproses.');
        }

        $width = imagesx($source);
        $height = imagesy($source);
        $maxDimension = 1200;
        $scale = min(1, $maxDimension / max($width, $height));
        $targetWidth = max(1, (int) round($width * $scale));
        $targetHeight = max(1, (int) round($height * $scale));
        $compressed = imagecreatetruecolor($targetWidth, $targetHeight);
        $background = imagecolorallocate($compressed, 255, 255, 255);
        imagefill($compressed, 0, 0, $background);
        imagecopyresampled(
            $compressed,
            $source,
            0,
            0,
            0,
            0,
            $targetWidth,
            $targetHeight,
            $width,
            $height
        );

        $directory = public_path('uploads/menus');
        if (! is_dir($directory) && ! mkdir($directory, 0755, true) && ! is_dir($directory)) {
            imagedestroy($compressed);
            imagedestroy($source);
            throw new \RuntimeException('Folder upload gambar tidak dapat dibuat.');
        }

        $filename = 'menu_'.Str::uuid().'.jpg';
        $path = $directory.DIRECTORY_SEPARATOR.$filename;
        $saved = imagejpeg($compressed, $path, 78);
        imagedestroy($compressed);
        imagedestroy($source);

        if (! $saved) {
            throw new \RuntimeException('Gambar menu gagal disimpan.');
        }

        return url('uploads/menus/'.$filename);
    }

    private function deleteStoredImage(?string $imageUrl): void
    {
        if ($imageUrl === null) {
            return;
        }

        $path = parse_url($imageUrl, PHP_URL_PATH);
        if (! is_string($path) || ! preg_match('~(?:^|/)uploads/menus/[^/]+$~', $path)) {
            return;
        }

        $storedPath = public_path('uploads/menus/'.basename($path));
        if (is_file($storedPath)) {
            unlink($storedPath);
        }
    }
}
