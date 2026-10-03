<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Menu extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id', 'category_id', 'code',
        'name', 'price', 'description', 'image_url', 'is_available',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function getImageUrlAttribute($value): ?string
    {
        if (empty($value)) {
            return null;
        }
        $path = parse_url($value, PHP_URL_PATH);
        if (! empty($path) && str_starts_with($path, '/uploads/')) {
            $host = request()->header('x-forwarded-host') ?? request()->header('host') ?? request()->getHost();
            $scheme = (request()->isSecure() || request()->header('x-forwarded-proto') === 'https' || ! app()->isLocal()) ? 'https' : 'http';

            return "{$scheme}://{$host}{$path}";
        }

        return $value;
    }

    public function toppings()
    {
        return $this->belongsToMany(Topping::class, 'menu_toppings')
            ->withPivot('min', 'max')
            ->withTimestamps();
    }
}
