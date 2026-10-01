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

    public function toppings()
    {
        return $this->belongsToMany(Topping::class, 'menu_toppings')
                    ->withPivot('min', 'max')
                    ->withTimestamps();
    }
}
