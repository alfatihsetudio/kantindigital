<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    private array $roles = ['admin', 'cashier', 'operations', 'manager'];

    public function index()
    {
        $users = User::all();
        return response()->json(['status' => true, 'data' => $users]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6',
            'role' => ['required', Rule::in($this->roles)],
        ]);

        $data = $request->only(['name', 'email', 'password', 'role']);
        $data['password'] = Hash::make($request->password);
        $data['must_change_password'] = true;
        if (app()->has('tenant')) {
            $data['tenant_id'] = app('tenant')->id;
        }

        $user = User::create($data);
        return response()->json(['status' => true, 'message' => 'Created', 'data' => $user]);
    }

    public function update(Request $request, $id)
    {
        $user = User::find($id);
        if (!$user) return response()->json(['status' => false, 'message' => 'Not found'], 404);

        $request->validate([
            'email' => ['required', 'email', Rule::unique('users')->ignore($user->id)],
            'role' => ['nullable', Rule::in($this->roles)],
        ]);
        
        $data = $request->only(['name', 'email', 'role']);
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
            $data['must_change_password'] = true;
        }

        $user->update($data);
        return response()->json(['status' => true, 'message' => 'Updated', 'data' => $user]);
    }

    public function destroy($id)
    {
        $user = User::find($id);
        if (!$user) return response()->json(['status' => false, 'message' => 'Not found'], 404);
        
        $user->delete();
        return response()->json(['status' => true, 'message' => 'Deleted']);
    }
}
