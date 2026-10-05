<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Menu;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class MenuImageUploadTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutMiddleware();
    }

    public function test_uploaded_menu_images_are_resized_and_compressed(): void
    {
        $category = Category::create(['name' => 'Minuman']);
        $image = UploadedFile::fake()->image('drink.png', 2400, 1800);

        $response = $this->post('/api/menus', [
            'name' => 'Es Kopi',
            'category_id' => $category->id,
            'price' => 15000,
            'image' => $image,
        ]);

        $response->assertOk();
        $imageUrl = $response->json('data.image_url');
        $filename = basename(parse_url($imageUrl, PHP_URL_PATH));
        $storedPath = public_path('uploads/menus/'.$filename);

        try {
            $this->assertFileExists($storedPath);
            $dimensions = getimagesize($storedPath);
            $this->assertLessThanOrEqual(1200, max($dimensions[0], $dimensions[1]));
            $this->assertSame(IMAGETYPE_JPEG, $dimensions[2]);
            $this->assertLessThanOrEqual(512 * 1024, filesize($storedPath));
        } finally {
            if (is_file($storedPath)) {
                unlink($storedPath);
            }
        }
    }

    public function test_menu_image_can_be_uploaded_to_existing_menu_using_post(): void
    {
        $category = Category::create(['name' => 'Minuman']);
        $menu = Menu::create([
            'category_id' => $category->id,
            'name' => 'Es Kopi',
            'price' => 15000,
        ]);
        $image = UploadedFile::fake()->image('drink.png', 800, 600);

        $response = $this->post('/api/menus/'.$menu->id, [
            'name' => 'Es Kopi Susu',
            'category_id' => $category->id,
            'price' => 18000,
            'image' => $image,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.name', 'Es Kopi Susu');
        $imageUrl = $response->json('data.image_url');
        $filename = basename(parse_url($imageUrl, PHP_URL_PATH));
        $storedPath = public_path('uploads/menus/'.$filename);

        try {
            $this->assertFileExists($storedPath);
            $this->assertDatabaseHas('menus', [
                'id' => $menu->id,
                'name' => 'Es Kopi Susu',
            ]);
            $this->assertSame(
                $filename,
                basename(parse_url($menu->fresh()->image_url, PHP_URL_PATH))
            );
        } finally {
            if (is_file($storedPath)) {
                unlink($storedPath);
            }
        }
    }
}
