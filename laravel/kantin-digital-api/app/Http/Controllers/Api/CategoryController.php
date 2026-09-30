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
        $category = Category::create($request->all());
        return response()->json(['status' => true, 'message' => 'Created', 'data' => $category]);
    }

    public function update(Request $request, $id)
    {
        $category = Category::find($id);
        if (!$category) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $category->update($request->all());
        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $category]);
    }

    public function destroy($id)
    {
        $category = Category::find($id);
        if (!$category) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $category->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }
}
