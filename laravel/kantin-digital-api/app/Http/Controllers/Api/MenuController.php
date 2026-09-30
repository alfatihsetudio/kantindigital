<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Menu;

class MenuController extends Controller
{
    public function index()
    {
        $menus = Menu::with('category')->get()->map(function ($menu) {
            return [
                'id' => $menu->id,
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
            'data' => $menus
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'category_id' => 'required|exists:categories,id',
            'price' => 'required|numeric',
        ]);

        $menu = Menu::create($request->all());
        return response()->json(['status' => true, 'message' => 'Created', 'data' => $menu]);
    }

    public function update(Request $request, $id)
    {
        $menu = Menu::find($id);
        if (!$menu) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $menu->update($request->all());
        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $menu]);
    }

    public function destroy($id)
    {
        $menu = Menu::find($id);
        if (!$menu) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $menu->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }
}
