<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Rules\SafeImageRule;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class MenuController extends Controller
{
    public function index()
    {
        $menus = Menu::with(['category', 'toppings'])
            ->where(function ($query) {
                $query->whereHas('category', function ($q) {
                    $q->where('is_active', true);
                })->orWhereNull('category_id');
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
                    'note_options' => $menu->note_options ?? [],
                    'topping_ids' => $menu->toppings->pluck('id')->values(),
                ];
            });

        return response()->json([
            'status' => true,
            'data' => $menus,
        ]);
    }

    public function store(Request $request)
    {
        $this->normalizeNoteOptions($request);
        $tenantId = app()->has('tenant') ? app('tenant')->id : null;
        $request->validate([
            'code' => 'nullable|string|max:50',
            'name' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id',
            'price' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'is_available' => 'sometimes|boolean',
            'note_options' => 'nullable|array|max:20',
            'note_options.*' => 'required|string|max:80',
            'topping_ids' => 'nullable|array',
            'topping_ids.*' => [
                'integer',
                Rule::exists('toppings', 'id')->where('tenant_id', $tenantId),
            ],
            'image' => ['nullable', new SafeImageRule(8192)],
        ]);

        $data = $request->only([
            'code', 'name', 'category_id', 'price', 'description', 'is_available', 'note_options',
        ]);
        if ($request->hasFile('image')) {
            $data['image_url'] = $this->storeCompressedImage($request->file('image'));
        }

        $menu = Menu::create($data);
        $menu->toppings()->sync($this->toppingSyncPayload($request->input('topping_ids', [])));

        return response()->json(['status' => true, 'message' => 'Created', 'data' => $menu]);
    }

    public function update(Request $request, $id)
    {
        $this->normalizeNoteOptions($request);
        $menu = Menu::find($id);
        if (! $menu) {
            return response()->json(['status' => false, 'message' => 'Not found'], 404);
        }

        $tenantId = app()->has('tenant') ? app('tenant')->id : null;
        $request->validate([
            'code' => 'nullable|string|max:50',
            'name' => 'sometimes|required|string|max:255',
            'category_id' => 'sometimes|required|exists:categories,id',
            'price' => 'sometimes|required|numeric|min:0',
            'description' => 'nullable|string',
            'is_available' => 'sometimes|boolean',
            'note_options' => 'nullable|array|max:20',
            'note_options.*' => 'required|string|max:80',
            'topping_ids' => 'nullable|array',
            'topping_ids.*' => [
                'integer',
                Rule::exists('toppings', 'id')->where('tenant_id', $tenantId),
            ],
            'image' => ['nullable', new SafeImageRule(8192)],
        ]);

        $data = $request->only([
            'code', 'name', 'category_id', 'price', 'description', 'is_available', 'note_options',
        ]);
        if ($request->hasFile('image')) {
            $previousImage = $menu->image_url;
            $data['image_url'] = $this->storeCompressedImage($request->file('image'));
        } else {
            $previousImage = null;
        }

        $menu->update($data);
        if ($request->has('topping_ids')) {
            $menu->toppings()->sync($this->toppingSyncPayload($request->input('topping_ids', [])));
        }
        $this->deleteStoredImage($previousImage);

        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $menu]);
    }

    private function normalizeNoteOptions(Request $request): void
    {
        $rawOptions = $request->input('note_options');
        if (is_string($rawOptions)) {
            $decoded = json_decode($rawOptions, true);
            if (is_array($decoded)) {
                $request->merge(['note_options' => $decoded]);
            }
        }

        $rawToppingIds = $request->input('topping_ids');
        if (is_string($rawToppingIds)) {
            $decoded = json_decode($rawToppingIds, true);
            if (is_array($decoded)) {
                $request->merge(['topping_ids' => $decoded]);
            }
        }
    }

    private function toppingSyncPayload(array $toppingIds): array
    {
        return collect($toppingIds)
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->unique()
            ->mapWithKeys(fn ($id) => [$id => ['min' => 0, 'max' => 0]])
            ->all();
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
        $directory = public_path('uploads/menus');
        if (! is_dir($directory)) {
            @mkdir($directory, 0777, true);
            @chmod($directory, 0777);
        }

        if (! is_writable($directory)) {
            @chmod($directory, 0777);
        }

        $extension = strtolower($image->getClientOriginalExtension() ?: 'jpg');
        if ($extension === 'jpeg') {
            $extension = 'jpg';
        }
        if (! in_array($extension, ['jpg', 'png', 'webp'], true)) {
            $extension = 'jpg';
        }

        $canCompress = extension_loaded('gd') && function_exists('imagecreatefromstring');
        $realPath = $image->getRealPath();
        $source = ($canCompress && $realPath && file_exists($realPath))
            ? @imagecreatefromstring(file_get_contents($realPath))
            : false;
        if ($source === false) {
            $filename = 'menu_'.Str::uuid().'.'.$extension;
            $image->move($directory, $filename);
            @chmod($directory.DIRECTORY_SEPARATOR.$filename, 0666);

            return url('uploads/menus/'.$filename);
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

        $filename = 'menu_'.Str::uuid().'.jpg';
        $path = $directory.DIRECTORY_SEPARATOR.$filename;
        $saved = imagejpeg($compressed, $path, 78);
        @chmod($path, 0666);
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
