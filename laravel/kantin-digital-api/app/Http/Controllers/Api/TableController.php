<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Table;

class TableController extends Controller
{
    public function index()
    {
        $tables = Table::all();
        return response()->json(['status' => true, 'data' => $tables]);
    }

    public function store(Request $request)
    {
        $request->validate(['code' => 'required|unique:tables,code']);
        $table = Table::create($request->all());
        return response()->json(['status' => true, 'message' => 'Created', 'data' => $table]);
    }

     public function update(Request $request, $id)
    {
        $table = Table::find($id);
        if (!$table) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $table->update($request->all());
        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $table]);
    }

    public function destroy($id)
    {
        $table = Table::find($id);
        if (!$table) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $table->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }
}
