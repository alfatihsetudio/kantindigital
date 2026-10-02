<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::withoutGlobalScopes()
            ->where('email', $request->email)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'status' => false,
                'message' => 'Email atau Password salah',
            ], 401);
        }

        if ($user->role === 'superadmin') {
            if ($user->tenant_id !== null || app()->has('tenant')) {
                return response()->json([
                    'status' => false,
                    'message' => 'Akun Superadmin hanya dapat login melalui domain utama platform.',
                ], 403);
            }
        } else {
            if (app()->has('tenant')) {
                if ((int) $user->tenant_id !== (int) app('tenant')->id) {
                    return response()->json([
                        'status' => false,
                        'message' => 'Akun Anda tidak terdaftar pada tenant ini.',
                    ], 403);
                }
            } else {
                // Login dari domain utama (ekasir.my.id)
                $user->load('tenant');
                if (! $user->tenant || ! $user->tenant->is_active) {
                    return response()->json([
                        'status' => false,
                        'message' => 'Tenant Anda tidak aktif atau ditangguhkan.',
                    ], 403);
                }
            }
        }

        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'status' => true,
            'message' => 'Login success',
            'data' => [
                'token' => $token,
                'user' => $user,
                'tenant' => $user->tenant,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => true,
            'message' => 'Logout success',
        ]);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|different:current_password',
        ]);

        $user = $request->user();

        if (! Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'status' => false,
                'message' => 'Password lama salah',
            ], 400);
        }

        $user->password = Hash::make($request->new_password);
        $user->must_change_password = false;
        $user->save();

        return response()->json([
            'status' => true,
            'message' => 'Password berhasil diubah',
        ]);
    }
}
