<?php

namespace Tests\Feature;

use App\Models\Category;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class MenuImageUploadTest extends TestCase
{
    use RefreshDatabase;

    public function test_uploaded_menu_images_are_resized_and_compressed(): void
    {
        $this->withoutMiddleware();
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
}
