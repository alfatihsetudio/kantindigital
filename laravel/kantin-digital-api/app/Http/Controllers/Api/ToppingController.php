<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Topping;

class ToppingController extends Controller
{
    public function index(Request $request)
    {
        if ($request->has('menu_id')) {
            $menu = \App\Models\Menu::find($request->menu_id);
            if (!$menu) return response()->json(['status' => false, 'data' => []]);
            return response()->json(['status' => true, 'data' => $menu->toppings]);
        }

        $toppings = Topping::with('menus')->get();
        return response()->json(['status' => true, 'data' => $toppings]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required', 
            'price' => 'required|numeric',
            'menu_id' => 'required|exists:menus,id' // Wajib pilih menu saat buat topping
        ]);

        $topping = Topping::create($request->only(['name', 'price']));
        
        // Attach to menu
        $topping->menus()->attach($request->menu_id);

        return response()->json(['status' => true, 'message' => 'Created and assigned to menu', 'data' => $topping]);
    }

    public function update(Request $request, $id)
    {
        $topping = Topping::find($id);
        if (!$topping) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $topping->update($request->all());
        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $topping]);
    }

    public function destroy($id)
    {
        $topping = Topping::find($id);
        if (!$topping) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $topping->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }
}
