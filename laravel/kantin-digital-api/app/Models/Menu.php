<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Menu extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'tenant_id', 'category_id',
        'name', 'price', 'description', 'image_url', 'is_available'
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function getImageUrlAttribute($value): ?string
    {
        if (empty($value)) return null;
        $path = parse_url($value, PHP_URL_PATH);
        if (!empty($path) && str_starts_with($path, '/uploads/')) {
            if (request()->hasHeader('host')) {
                return request()->getSchemeAndHttpHost() . $path;
            }
            return url(ltrim($path, '/'));
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
