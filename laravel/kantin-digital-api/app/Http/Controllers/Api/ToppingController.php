<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Topping;
use Illuminate\Validation\Rule;

class ToppingController extends Controller
{
    public function forMenu(int $menu)
    {
        $menu = \App\Models\Menu::with('toppings')->find($menu);
        if (! $menu) {
            return response()->json([
                'status' => false,
                'message' => 'Menu tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'status' => true,
            'data' => $menu->toppings->map(fn (Topping $topping) => [
                'id' => $topping->id,
                'name' => $topping->name,
                'price' => $topping->price,
                'min' => $topping->pivot->min,
                'max' => $topping->pivot->max,
            ])->values(),
        ]);
    }

    public function index(Request $request)
    {
        if ($request->has('menu_id')) {
            $menu = \App\Models\Menu::find($request->menu_id);
            if (!$menu) return response()->json(['status' => false, 'data' => []]);
            return response()->json(['status' => true, 'data' => $menu->toppings]);
        }

        $toppings = Topping::with('categories')
            ->when($request->filled('category_id'), function ($query) use ($request) {
                $query->whereHas('categories', function ($categoryQuery) use ($request) {
                    $categoryQuery->where('categories.id', $request->integer('category_id'));
                });
            })
            ->get()
            ->map(fn (Topping $topping) => $this->formatTopping($topping));

        return response()->json(['status' => true, 'data' => $toppings]);
    }

    public function store(Request $request)
    {
        $this->normalizeCategoryIds($request);
        $tenantId = app()->has('tenant') ? app('tenant')->id : null;
        $request->validate([
            'name' => 'required', 
            'price' => 'required|numeric',
            'menu_id' => 'nullable|exists:menus,id',
            'category_ids' => 'nullable|array|min:1',
            'category_ids.*' => [
                'integer',
                Rule::exists('categories', 'id')->where('tenant_id', $tenantId),
            ],
        ]);

        $topping = Topping::create($request->only(['name', 'price']));
        $topping->categories()->sync($request->input('category_ids', []));

        if ($request->filled('menu_id')) {
            $topping->menus()->syncWithoutDetaching([$request->menu_id => ['min' => 0, 'max' => 0]]);
        }

        return response()->json([
            'status' => true,
            'message' => 'Created',
            'data' => $this->formatTopping($topping->load('categories')),
        ]);
    }

    public function update(Request $request, $id)
    {
        $this->normalizeCategoryIds($request);
        $topping = Topping::find($id);
        if (!$topping) return response()->json(['status' => false, 'message' => 'Not found'], 404);

        $tenantId = app()->has('tenant') ? app('tenant')->id : null;
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'price' => 'sometimes|required|numeric',
            'menu_id' => 'nullable|exists:menus,id',
            'category_ids' => 'nullable|array',
            'category_ids.*' => [
                'integer',
                Rule::exists('categories', 'id')->where('tenant_id', $tenantId),
            ],
        ]);

        $topping->update($request->only(['name', 'price']));
        if ($request->has('category_ids')) {
            $topping->categories()->sync($request->input('category_ids', []));
        }
        if ($request->filled('menu_id')) {
            $topping->menus()->syncWithoutDetaching([$request->menu_id => ['min' => 0, 'max' => 0]]);
        }

        return response()->json([
            'status' => true,
            'message' => 'Updated',
            'data' => $this->formatTopping($topping->load('categories')),
        ]);
    }

    public function destroy($id)
    {
        $topping = Topping::find($id);
        if (!$topping) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $topping->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }

    private function normalizeCategoryIds(Request $request): void
    {
        $rawCategoryIds = $request->input('category_ids');
        if (is_string($rawCategoryIds)) {
            $decoded = json_decode($rawCategoryIds, true);
            if (is_array($decoded)) {
                $request->merge(['category_ids' => $decoded]);
            }
        }
    }

    private function formatTopping(Topping $topping): array
    {
        return [
            'id' => $topping->id,
            'name' => $topping->name,
            'price' => $topping->price,
            'category_ids' => $topping->categories->pluck('id')->values(),
            'category_names' => $topping->categories->pluck('name')->values(),
        ];
    }
}
