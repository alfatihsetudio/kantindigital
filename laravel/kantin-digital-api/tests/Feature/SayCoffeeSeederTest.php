<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Menu;
use App\Models\Tenant;
use Database\Seeders\SayCoffeeSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SayCoffeeSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_say_coffee_seeded_menus_have_images_and_existing_images_are_preserved(): void
    {
        $seeder = new SayCoffeeSeeder;
        $seeder->run();

        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        $menus = Menu::withoutGlobalScopes()
            ->where('tenant_id', $tenant->id)
            ->get();

        $this->assertCount(9, $menus);
        $this->assertTrue($menus->every(
            fn (Menu $menu) => is_string($menu->image_url) && $menu->image_url !== ''
        ));
        $this->assertCount(
            9,
            $menus->map(fn (Menu $menu) => basename(parse_url($menu->image_url, PHP_URL_PATH)))
                ->unique()
        );
        foreach ($menus as $menu) {
            $filename = basename(parse_url($menu->image_url, PHP_URL_PATH));
            $this->assertFileExists(
                public_path("uploads/{$filename}")
            );
        }
        $this->assertCount(
            2,
            Category::withoutGlobalScopes()->where('tenant_id', $tenant->id)->get()
        );

        $menu = $menus->firstWhere('name', 'SAY BUTTER BLISS');
        $menu->update(['image_url' => '/uploads/custom-butter.jpg']);

        $seeder->run();

        $this->assertStringEndsWith(
            '/uploads/custom-butter.jpg',
            Menu::withoutGlobalScopes()
                ->where('tenant_id', $tenant->id)
                ->where('name', 'SAY BUTTER BLISS')
                ->value('image_url')
        );
        $this->assertCount(
            2,
            Category::withoutGlobalScopes()->where('tenant_id', $tenant->id)->get()
        );
    }
}
