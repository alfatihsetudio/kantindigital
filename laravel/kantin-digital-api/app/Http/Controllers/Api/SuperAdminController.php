<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Menu;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\MenuSeeder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;

class SuperAdminController extends Controller
{
    public function index()
    {
        $tenants = Tenant::query()
            ->withCount([
                'users' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'menus' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'orders' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
            ])
            ->orderBy('name')
            ->get();

        return response()->json([
            'status' => true,
            'data' => $tenants,
        ]);
    }

    public function store(Request $request)
    {
        foreach (['owner_email', 'manager_email', 'cashier_email', 'operations_email'] as $field) {
            $email = $request->input($field);
            if (is_string($email)) {
                $request->merge([$field => strtolower(trim($email))]);
            }
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'subdomain' => ['required', 'alpha_dash', 'max:63', 'unique:tenants,subdomain'],
            'plan' => ['required', Rule::in(['free', 'basic', 'pro'])],
            'is_active' => ['sometimes', 'boolean'],
            'expires_at' => ['nullable', 'date'],
            'primary_color' => ['nullable', 'regex:/^#[0-9a-fA-F]{6}$/'],
            'address' => ['nullable', 'string', 'max:1000'],
            'phone' => ['nullable', 'string', 'max:30'],
            'whatsapp' => ['nullable', 'string', 'max:30'],
            'owner_name' => ['required', 'string', 'max:255'],
            'owner_email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'manager_name' => ['required', 'string', 'max:255'],
            'manager_email' => ['required', 'email', 'max:255', 'unique:users,email', 'different:owner_email'],
            'cashier_name' => ['required', 'string', 'max:255'],
            'cashier_email' => ['required', 'email', 'max:255', 'unique:users,email', 'different:owner_email', 'different:manager_email'],
            'operations_name' => ['required', 'string', 'max:255'],
            'operations_email' => ['required', 'email', 'max:255', 'unique:users,email', 'different:owner_email', 'different:manager_email', 'different:cashier_email'],
        ]);

        $result = DB::transaction(function () use ($data) {
            $tenant = Tenant::create([
                'name' => $data['name'],
                'subdomain' => strtolower($data['subdomain']),
                'plan' => $data['plan'],
                'is_active' => $data['is_active'] ?? true,
                'expires_at' => $data['expires_at'] ?? null,
                'primary_color' => $data['primary_color'] ?? '#6F4E37',
                'address' => $data['address'] ?? null,
                'phone' => $data['phone'] ?? null,
                'whatsapp' => $data['whatsapp'] ?? null,
            ]);

            $categoriesByTemplateId = [];
            foreach (array_values((new CategorySeeder())->templates()) as $index => $categoryTemplate) {
                $category = Category::create([
                    'tenant_id' => $tenant->id,
                    'name' => $categoryTemplate['name'],
                    'is_active' => true,
                ]);
                $categoriesByTemplateId[$index + 1] = $category->id;
            }

            foreach ((new MenuSeeder())->templates() as $menuTemplate) {
                $sourceImage = basename(parse_url($menuTemplate['image_url'], PHP_URL_PATH));
                $templateImage = $sourceImage.'.jpg';
                $templateImagePath = public_path('uploads/menu-templates/'.$templateImage);
                if (! is_file($templateImagePath)) {
                    throw new \RuntimeException("Foto template menu tidak ditemukan: {$templateImage}");
                }

                Menu::create([
                    'tenant_id' => $tenant->id,
                    'category_id' => $categoriesByTemplateId[$menuTemplate['category_id']],
                    'name' => $menuTemplate['name'],
                    'price' => $menuTemplate['price'],
                    'description' => $menuTemplate['description'],
                    'image_url' => url('uploads/menu-templates/'.$templateImage),
                    'is_available' => false,
                ]);
            }

            $accounts = [
                ['name' => $data['owner_name'], 'email' => $data['owner_email'], 'role' => 'admin'],
                ['name' => $data['manager_name'], 'email' => $data['manager_email'], 'role' => 'manager'],
                ['name' => $data['cashier_name'], 'email' => $data['cashier_email'], 'role' => 'cashier'],
                ['name' => $data['operations_name'], 'email' => $data['operations_email'], 'role' => 'operations'],
            ];
            $credentials = [];

            foreach ($accounts as $account) {
                $temporaryPassword = Str::random(32);
                User::create([
                    'tenant_id' => $tenant->id,
                    'name' => $account['name'],
                    'email' => strtolower($account['email']),
                    'password' => $temporaryPassword,
                    'role' => $account['role'],
                    'must_change_password' => true,
                ]);
                $credentials[] = [
                    'name' => $account['name'],
                    'email' => strtolower($account['email']),
                    'role' => $account['role'],
                    'temporary_password' => $temporaryPassword,
                ];
            }

            return compact('tenant', 'credentials');
        });
        $tenant = $result['tenant'];

        return response()->json([
            'status' => true,
            'message' => 'Tenant beserta akun owner, manager, kasir, dan operasional berhasil dibuat.',
            'data' => $tenant->loadCount([
                'users' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'menus' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'orders' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
            ]),
            'initial_accounts' => $result['credentials'],
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        $tenant = Tenant::findOrFail($id);
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'subdomain' => [
                'sometimes',
                'required',
                'alpha_dash',
                'max:63',
                Rule::unique('tenants', 'subdomain')->ignore($tenant->id),
            ],
            'plan' => ['sometimes', 'required', Rule::in(['free', 'basic', 'pro'])],
            'is_active' => ['sometimes', 'boolean'],
            'expires_at' => ['nullable', 'date'],
            'primary_color' => ['nullable', 'regex:/^#[0-9a-fA-F]{6}$/'],
            'address' => ['nullable', 'string', 'max:1000'],
            'phone' => ['nullable', 'string', 'max:30'],
            'whatsapp' => ['nullable', 'string', 'max:30'],
        ]);

        if (isset($data['subdomain'])) {
            $data['subdomain'] = strtolower($data['subdomain']);
        }
        $tenant->update($data);

        return response()->json([
            'status' => true,
            'message' => 'Pengaturan tenant berhasil diperbarui.',
            'data' => $tenant->loadCount([
                'users' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'menus' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'orders' => fn ($query) => $query->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
            ]),
        ]);
    }
}
