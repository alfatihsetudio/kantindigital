<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Category;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::all();
        return response()->json([
            'status' => true,
            'data' => $categories
        ]);
    }

    public function store(Request $request)
    {
        $request->validate(['name' => 'required']);
        $category = Category::create([
            'name' => $request->name,
            'is_active' => $request->has('is_active') ? (bool)$request->is_active : true,
        ]);
        return response()->json(['status' => true, 'message' => 'Created', 'data' => $category]);
    }

    public function update(Request $request, $id)
    {
        $category = Category::find($id);
        if (!$category) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $category->update($request->only(['name', 'is_active']));
        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $category]);
    }

    public function toggle($id)
    {
        $category = Category::find($id);
        if (!$category) return response()->json(['status' => false, 'message' => 'Not found'], 404);

        $category->is_active = !$category->is_active;
        $category->save();

        return response()->json([
            'status' => true,
            'message' => $category->is_active ? 'Kategori diaktifkan' : 'Kategori dinonaktifkan',
            'data' => $category
        ]);
    }

    public function destroy($id)
    {
        $category = Category::find($id);
        if (!$category) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $category->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }
}
