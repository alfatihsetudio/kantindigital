<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class CreateSuperAdmin extends Command
{
    protected $signature = 'superadmin:create {email : Email untuk akun superadmin}';

    protected $description = 'Buat akun superadmin platform secara interaktif';

    public function handle(): int
    {
        $email = strtolower($this->argument('email'));
        $existingUser = User::withoutGlobalScopes()->where('email', $email)->first();
        if ($existingUser && ($existingUser->tenant_id !== null || $existingUser->role !== 'superadmin')) {
            $this->error('Email tersebut sudah digunakan oleh akun tenant.');

            return self::FAILURE;
        }

        $name = $this->ask('Nama superadmin', $existingUser?->name ?? 'Super Admin');
        $password = $this->secret('Password (minimal 12 karakter)');
        if (strlen((string) $password) < 12) {
            $this->error('Password harus minimal 12 karakter.');

            return self::FAILURE;
        }

        $confirmation = $this->secret('Ulangi password');
        if (! hash_equals((string) $password, (string) $confirmation)) {
            $this->error('Konfirmasi password tidak cocok.');

            return self::FAILURE;
        }

        $user = $existingUser ?? new User;
        $user->forceFill([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'role' => 'superadmin',
            'tenant_id' => null,
        ])->save();

        $this->info("Akun superadmin siap digunakan: {$user->email}");

        return self::SUCCESS;
    }
}
