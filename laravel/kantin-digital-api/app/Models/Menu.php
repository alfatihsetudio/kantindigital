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
        if (str_starts_with($value, 'http://') || str_starts_with($value, 'https://')) {
            $parsed = parse_url($value);
            if (!empty($parsed['path']) && str_starts_with($parsed['path'], '/uploads/')) {
                return url(ltrim($parsed['path'], '/'));
            }
            return $value;
        }
        return url(ltrim($value, '/'));
    }

    public function toppings()
    {
        return $this->belongsToMany(Topping::class, 'menu_toppings')
                    ->withPivot('min', 'max')
                    ->withTimestamps();
    }
}
