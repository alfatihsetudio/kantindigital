<?php

namespace App\Console\Commands;

use App\Models\Tenant;
use Illuminate\Console\Command;

class CreateTenant extends Command
{
    protected $signature = 'tenant:create
                            {subdomain : Subdomain unik, misal: saycoffee}
                            {name : Nama usaha, misal: "SAY COFFEE"}
                            {--color=#00AA13 : Warna primary (hex)}
                            {--phone= : Nomor HP pemilik}
                            {--wa= : Nomor WhatsApp (format: 628xxx)}
                            {--plan=free : Plan: free, basic, pro}';

    protected $description = 'Buat tenant (usaha/kantin) baru di platform kasirdigital';

    public function handle(): int
    {
        $subdomain = $this->argument('subdomain');
        $name      = $this->argument('name');

        if (Tenant::where('subdomain', $subdomain)->exists()) {
            $this->error("Subdomain '$subdomain' sudah digunakan!");
            return self::FAILURE;
        }

        $tenant = Tenant::create([
            'subdomain'     => $subdomain,
            'name'          => $name,
            'primary_color' => $this->option('color'),
            'phone'         => $this->option('phone'),
            'whatsapp'      => $this->option('wa'),
            'plan'          => $this->option('plan'),
            'is_active'     => true,
        ]);

        $this->info("✅ Tenant berhasil dibuat!");
        $this->table(
            ['Field', 'Value'],
            [
                ['ID', $tenant->id],
                ['Subdomain', $tenant->subdomain],
                ['Nama', $tenant->name],
                ['Warna', $tenant->primary_color],
                ['Plan', $tenant->plan],
                ['URL Lokal', "http://{$subdomain}.kasirdigital.test"],
                ['URL Produksi', "https://{$subdomain}.kasirdigital.my.id"],
            ]
        );

        $this->line('');
        $this->info('💡 Jangan lupa tambahkan subdomain ke hosts file (lokal):');
        $this->line("   127.0.0.1    {$subdomain}.kasirdigital.test");

        return self::SUCCESS;
    }
}
